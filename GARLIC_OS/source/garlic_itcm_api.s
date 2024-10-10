@;==============================================================================
@;
@;	"garlic_itcm_api.s":	codigo de las rutinas del API de GARLIC 1.0
@;							(ver "GARLIC_API.h" para descripci�n de las
@;							 funciones correspondientes)
@;
@;==============================================================================

.section .itcm,"ax",%progbits

	.arm
	.align 2


	.global _ga_pid
	@;Resultado:
	@; R0 = identificador del proceso actual
_ga_pid:
	push {r1, lr}
	ldr r0, =_gd_pidz
	ldr r1, [r0]			@; R1 = valor actual de PID + z�calo
	mov r0, r1, lsr #0x4	@; R0 = PID del proceso actual
	pop {r1, pc}


	.global _ga_random
	@;Resultado:
	@; R0 = valor aleatorio de 32 bits
_ga_random:
	push {r1-r5, lr}
	ldr r0, =_gd_seed
	ldr r1, [r0]			@; R1 = valor de semilla de numeros aleatorios
	ldr r2, =0x0019660D
	ldr r3, =0x3C6EF35F
	umull r4, r5, r1, r2	@; R5:R4 = _gd_seed * 0x19660D
	add r4, r3				@; R4 += 0x3C6EF35F
	str r4, [r0]			@; guarda la nueva semilla (R4)
	mov r0, r5				@; devuelve por R0 el valor aleatorio (R5)
	pop {r1-r5, pc}


	.global _ga_divmod
	@;Parametros
	@; R0: unsigned int num
	@; R1: unsigned int den
	@; R2: unsigned int * quo
	@; R3: unsigned int * mod
	@;Resultado
	@; R0: 0 si no hay problema, !=0 si hay error en la division
_ga_divmod:
	push {r4-r7, lr}
	cmp r1, #0				@; verificar si se esta intentando dividir por cero
	bne .Ldiv_ini
	mov r0, #1				@; codigo de error
	b .Ldiv_fin2
.Ldiv_ini:
	mov r4, #0				@; R4 es el cociente (q)
	mov r5, #0				@; R5 es el resto (r)
	mov r6, #31				@; R6 es indice del bucle (de 31 a 0)
	mov r7, #0xff000000
.Ldiv_for1:
	tst r0, r7				@; comprobar si hay bits activos en una zona de 8
	bne .Ldiv_for2			@; bits del numerador, para evitar el rastreo bit a bit
	mov r7, r7, lsr #8
	sub r6, #8				@; 8 bits menos a buscar
	cmp r7, #0
	bne .Ldiv_for1
	b .Ldiv_fin1			@; caso especial (numerador = 0 -> q=0 y r=0)
.Ldiv_for2:
	mov r7, r0, lsr r6		@; R7 es variable de trabajo j;
	and r7, #1				@; j = bit i-esimo del numerador; 
	mov r5, r5, lsl #1		@; r = r << 1;
	orr r5, r7				@; r = r | j;
	mov r4, r4, lsl #1		@; q = q << 1;
	cmp r5, r1
	blo .Ldiv_cont			@; si (r >= divisor), activar bit en cociente
	sub r5, r1				@; r = r - divisor;
	orr r4, #1				@; q = q | 1;
 .Ldiv_cont:
	sub r6, #1				@; decrementar indice del bucle
	cmp r6, #0
	bge .Ldiv_for2			@; bucle for-2, mientras i >= 0
.Ldiv_fin1:
	str r4, [r2]
	str r5, [r3]			@; guardar resultados en memoria (por referencia)
	mov r0, #0				@; codigo de OK
.Ldiv_fin2:
	pop {r4-r7, pc}


	.global _ga_divmodL
	@;Parametros
	@; R0: long long * num
	@; R1: unsigned int * den
	@; R2: long long * quo
	@; R3: unsigned int * mod
	@;Resultado
	@; R0: 0 si no hay problema, !=0 si hay error en la division
_ga_divmodL:
	push {r4-r6, lr}
	ldr r4, [r1]			@; R4 = denominador
	cmp r4, #0				@; verificar si se esta intentando dividir por cero
	bne .LdivL_ini
	mov r0, #1				@; codigo de error
	b .LdivL_fin
.LdivL_ini:
	ldrd r0, [r0]			@; R1:R0 = numerador
	mov r5, r2				@; R5 apunta a quo
	mov r6, r3				@; R6 apunta a mod
	mov r2, r4
	mov r3, #0				@; R3:R2 = denominador
	bl __aeabi_ldivmod
	strd r0, [r5]
	str r2, [r6]			@; guardar resultados en memoria (por referencia)			
	mov r0, #0				@; codigo de OK
.LdivL_fin:
	pop {r4-r6, pc}


	.global _ga_printf
	@;Parametros
	@; R0: char * format
	@; R1: unsigned int val1 (opcional)
	@; R2: unsigned int val2 (opcional)
_ga_printf:
	push {r4, lr}
	ldr r4, =_gd_pidz		@; R4 = direccion _gd_pidz
	ldr r3, [r4]
	and r3, #0x3			@; R3 = ventana de salida (zocalo actual MOD 4)
	bl _gp_WaitForVBlank
	push {r12}
	bl printf				@; llamada de prueba
	pop {r12}
	pop {r4, pc}


	.global _ga_wait
	@;Parametros
	@; R0: unsigned char mutex
	@;Resultado
	@; R0: 1 si se ha bloqueado el proceso, 0 si no lo ha hecho
_ga_wait:
	push {r1-r2, lr}

	@; Comprobar que el semaforo existe
	cmp r0, #7				@; comprobamos que el semaforo indicado no pasa de 7 (rango es 0-7)
	movhi r0, #0			@; si se pasa, mover un 0 a R0
	bhi .LreturnWait		@; y salir de la rutina indicando que no se ha desbloqueado ningun proceso

	@; Obtener estado del semaforo
	ldr r1, =_gd_mutex		@; cargar direccion del vector de semaforos
	ldrb r2, [r1, r0]		@; obtener valor del semaforo indicado por parametro

	@; Comprobar su valor
	cmp r2, #0				@; comprobar si el semaforo es 0 (bloqueado)
	moveq r0, #0			@; mover un 0 a R0 para devolverlo como resultado
	beq .LreturnWait		@; acabar rutina indicando que el semaforo ya estaba bloqueado

	@; Bucle para bloquear proceso hasta que el semaforo se libere
	mov r2, #0				@; en caso de estar a 1 (libre), mover un 0 en R2
	strb r2, [r1, r0]		@; y guardarlo en el semaforo indicado por parametro
.LcheckLoop:
	ldrb r2, [r1, r0]		@; obtener valor del semaforo nuevamente
	cmp r2, #0				@; comprobar si sigue a 0 (bloqueado)
	movhi r0, #1			@; en caso de estar a 1 (libre), mover un 1 en R1
	bhi .LreturnWait		@; y acabar la rutina indicando que el proceso se ha bloqueado correctamente
	bl _gp_WaitForVBlank	@; si no, esperar retroceso vertical
	b .LcheckLoop			@; y volver a iterar el bucle

.LreturnWait:

	pop {r1-r2, pc}


.global _ga_signal
	@;Parametros
	@; R0: unsigned char mutex
	@;Resultado
	@; R0: 1 si ha desbloqueado un proceso, 0 si no lo ha hecho
_ga_signal:
	push {r1-r2, lr}

	@; Comprobar que el semaforo existe
	cmp r0, #7				@; comprobamos que el semaforo indicado no pasa de 7 (rango es 0-7)
	movhi r0, #0			@; si se pasa, mover un 0 a R0
	bhi .LreturnSignal		@; y salir de la rutina indicando que no se ha desbloqueado ningun proceso

	@; Obtener estado del semaforo
	ldr r1, =_gd_mutex		@; cargar direccion del vector de semaforos
	ldrb r2, [r1, r0]		@; obtener valor del semaforo indicado por parametro

	@; Comprobar su valor
	cmp r2, #0				@; comprobar si el semaforo es 0 (bloqueado)
	movhi r0, #0			@; en caso que no lo sea, mover un 0 a R0
	bhi .LreturnSignal		@; y salir de la rutina indicando que no se ha desbloqueado ningun proceso

	@; Desbloquear proceso (liberar semaforo)
	mov r2, #1				@; en caso que si, mover un 1 en R2
	strb r2, [r1, r0]		@; y guardarlo en el semaforo indicado por parametro
	mov r0, #1				@; mover un 1 a R0 para indicar que se ha desbloqueado un proceso

.LreturnSignal:

	pop {r1-r2, pc}

.end

