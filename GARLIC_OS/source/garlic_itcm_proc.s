@;==============================================================================
@;
@;	"garlic_itcm_proc.s":	c�digo de las rutinas de control de procesos (1.0)
@;						(ver "garlic_system.h" para descripci�n de rutinas)
@;
@;==============================================================================

.section .itcm,"ax",%progbits

	.arm
	.align 2
	
	.global _gp_WaitForVBlank
	@; rutina para pausar el procesador mientras no se produzca una interrupci�n
	@; de retroceso vertical (VBL); es un sustituto de la "swi #5" que evita
	@; la necesidad de cambiar a modo supervisor en los procesos GARLIC;
_gp_WaitForVBlank:
	push {r0-r1, lr}
	ldr r0, =__irq_flags
.Lwait_espera:
	mcr p15, 0, lr, c7, c0, 4	@; HALT (suspender hasta nueva interrupci�n)
	ldr r1, [r0]			@; R1 = [__irq_flags]
	tst r1, #1				@; comprobar flag IRQ_VBL
	beq .Lwait_espera		@; repetir bucle mientras no exista IRQ_VBL
	bic r1, #1
	str r1, [r0]			@; poner a cero el flag IRQ_VBL
	pop {r0-r1, pc}


	.global _gp_IntrMain
	@; Manejador principal de interrupciones del sistema Garlic;
_gp_IntrMain:
	mov	r12, #0x4000000
	add	r12, r12, #0x208	@; R12 = base registros de control de interrupciones	
	ldr	r2, [r12, #0x08]	@; R2 = REG_IE (m�scara de bits con int. permitidas)
	ldr	r1, [r12, #0x0C]	@; R1 = REG_IF (m�scara de bits con int. activas)
	and r1, r1, r2			@; filtrar int. activas con int. permitidas
	ldr	r2, =irqTable
.Lintr_find:				@; buscar manejadores de interrupciones espec�ficos
	ldr r0, [r2, #4]		@; R0 = m�scara de int. del manejador indexado
	cmp	r0, #0				@; si m�scara = cero, fin de vector de manejadores
	beq	.Lintr_setflags		@; (abandonar bucle de b�squeda de manejador)
	ands r0, r0, r1			@; determinar si el manejador indexado atiende a una
	beq	.Lintr_cont1		@; de las interrupciones activas
	ldr	r3, [r2]			@; R3 = direcci�n de salto del manejador indexado
	cmp	r3, #0
	beq	.Lintr_ret			@; abandonar si direcci�n = 0
	mov r2, lr				@; guardar direcci�n de retorno
	blx	r3					@; invocar el manejador indexado
	mov lr, r2				@; recuperar direcci�n de retorno
	b .Lintr_ret			@; salir del bucle de b�squeda
.Lintr_cont1:	
	add	r2, r2, #8			@; pasar al siguiente �ndice del vector de
	b	.Lintr_find			@; manejadores de interrupciones espec�ficas
.Lintr_ret:
	mov r1, r0				@; indica qu� interrupci�n se ha servido
.Lintr_setflags:
	str	r1, [r12, #0x0C]	@; REG_IF = R1 (comunica interrupci�n servida)
	ldr	r0, =__irq_flags	@; R0 = direcci�n flags IRQ para gesti�n IntrWait
	ldr	r3, [r0]
	orr	r3, r3, r1			@; activar el flag correspondiente a la interrupci�n
	str	r3, [r0]			@; servida (todas si no se ha encontrado el maneja-
							@; dor correspondiente)
	mov	pc,lr				@; retornar al gestor de la excepci�n IRQ de la BIOS


	.global _gp_rsiVBL
	@; Manejador de interrupciones VBL (Vertical BLank) de Garlic:
	@; se encarga de actualizar los tics, intercambiar procesos, etc.;
_gp_rsiVBL:
	push {r4-r7, lr}

	@; Incrementar contador de tics general
	ldr r4, =_gd_tickCount		@; cargar direccion mem contador tics
	ldr r5, [r4]				@; obtener su valor
	add r5, #1					@; incrementar en 1
	str r5, [r4]				@; guardar nuevo valor
	@; Fin incrementar tics

	@; Detectar si quedan procesos en la cola RDY
	ldr r4, =_gd_nReady			@; cargar direccion mem num RDY
	ldr r5, [r4]				@; obtener su valor
	cmp r5, #0					@; comprobar si es 0
	beq .LendVBL				@; si lo es, acabar multiplexacion
								@; si no, continuar la multiplexacion
	@; Fin detectar si quedan procesos en la cola RDY

	@; Comprobar proceso actual para salvar y/o restaurar contextos
	ldr r4, =_gd_pidz			@; cargar direccion del proceso actual
	ldr r5, [r4]				@; obtener su valor
	cmp r5, #0					@; comprobar si es el SO
	moveq r7, #1				@; si lo es, guardar un 1 en R7 para luego decidir guardar el contexto
	beq .LcontextChange			@; y saltar a cambio de contexto
								@; si no, comprobar si ha acabado
	mov r5, r5, lsr #4			@; desplazar _gd_pidz 4 bits a la derecha para eliminar bits de zocalo
	cmp r5, #0					@; comprobar si PID = 0
	moveq r7, #2				@; si lo es, guardar un 2 en R7 para luego decidir restaurar el siguiente contexto
	beq .LcontextChange			@; y saltar a cambio de contexto
	mov r7, #1					@; si no lo es, guardar contexto primero

.LcontextChange:

	ldr r4, =_gd_nReady		@; guardar valores necesarios en los registros
	ldr r5, [r4]			@; antes de saltar al cambio de contexto
	ldr r6, =_gd_pidz
	cmp r7, #1				@; comprobar si hay que guardar el contexto o no
	bleq _gp_salvarProc		@; si R7=1, saltar a salvar el contexto
	blhi _gp_restaurarProc	@; si no, directamente restaurar el siguiente
	@; Fin comprobar proceso para salvar y/o restaurar contexto

.LendVBL:

	pop {r4-r7, pc}


	@; Rutina para salvar el estado del proceso interrumpido en la entrada
	@; correspondiente del vector _gd_pcbs[];
	@;Par�metros
	@; R4: direcci�n _gd_nReady
	@; R5: n�mero de procesos en READY
	@; R6: direcci�n _gd_pidz
	@;Resultado
	@; R5: nuevo n�mero de procesos en READY (+1)
_gp_salvarProc:
	push {r8-r11, lr}


	pop {r8-r11, pc}


	@; Rutina para restaurar el estado del siguiente proceso en la cola de READY;
	@;Par�metros
	@; R4: direcci�n _gd_nReady
	@; R5: n�mero de procesos en READY
	@; R6: direcci�n _gd_pidz
_gp_restaurarProc:
	push {r8-r11, lr}


	pop {r8-r11, pc}


	.global _gp_numProc
	@;Resultado
	@; R0: n�mero de procesos total
_gp_numProc:
	push {lr}

	ldr r0, =_gd_nReady
	ldr r0, [r0]
	add r0, #1

	pop {pc}


	.global _gp_crearProc
	@; prepara un proceso para ser ejecutado, creando su entorno de ejecuci�n y
	@; coloc�ndolo en la cola de READY;
	@;Par�metros
	@; R0: intFunc funcion
	@; R1: int zocalo
	@; R2: char *nombre
	@; R3: int arg
	@;Resultado
	@; R0: 0 si no hay problema, >0 si no se puede crear el proceso
_gp_crearProc:
	push {r4-r7, lr}

	@; Inicio comprobacion zocalo
	cmp r1, #0				@; comprobar si el zocalo es el del SO
	moveq r0, #1			@; si lo es, devolver R0 > 0
	beq .LbadProcess		@; y saltar al final sin crear proceso
	@; Fin comprobacion zocalo

	@; Inicio comprobacion PCB
	ldr r4, =_gd_pcbs		@; si no, cargar dir. base de los PCBs
	mov r5, #24				@; tamaño de un PCB
	mla r4, r5, r1, r4		@; obtener direccion del PCB del zocalo indicado (dir. base + tamaño PCB * zocalo)
	ldr r5, [r4]			@; cargar PID del PCB obtenido
	cmp r5, #0				@; comprobar si esta libre (PID = 0)
	movne r0, #1			@; si no lo esta, devolver R0 > 0
	bne .LbadProcess		@; y saltar al final sin crear proceso
	@; Fin comprobacion PCB

	@; Inicio creacion del proceso
		@; Guardar PID
	ldr r5, =_gd_pidCount	@; cargar direccion del contador de PIDs
	ldr r6, [r5]			@; obtener su valor
	add r6, #1				@; incrementarlo en 1
	str r6, [r5]			@; actualizar el valor en la variable
	str r6, [r4]			@; y guardarlo tambien en el PCB

		@; Guardar PC
	add r5, r0, #4			@; sumar 4 a la direccion de la rutina inicial para compensar el decremento del exception handler
	str r5, [r4, #4]		@; y guardarlo en el campo PC del PCB (offset 4 bytes de la direccion base)

		@; Guardar keyName (4 chars se pueden guardar de golpe con str)
	ldr r5, [r2]			@; obtener los cuatro caracteres del keyName
	str r5, [r4, #16]		@; y guardarlos todos en el campo keyName del PCB (offset 16 bytes)

		@; calcular direccion base de la pila del proceso
	ldr r5, =_gd_stacks		@; obtener direccion base del vector de pilas
	add r5, r1, lsl #9		@; obtener direccion base de la pila del zocalo deseado
							@; teniendo en cuenta que la primera pila del vector es la del zocalo 1
							@; y que cada pila ocupa 512 bytes (2^9)
		
		@; guardar valores iniciales en la pila del proceso
	ldr r6, =_gp_terminarProc	@; obtener direccion de la funcion _gp_terminarProc
	sub r5, #4				@; restar una posicion de pila para empezar a apilar con str
							@; (puntero indica el ultimo elemento apilado, no la siguiente posicion libre)
	str r6, [r5]			@; y guardar direccion de retorno del proceso (R14)
	mov r6, #0				@; movemos un 0 para guardarlo en la pila multiples veces
	mov r7, #12				@; guardar el 0 para los registros R12-R1 (12 registros)

.Lsave_regs:
	cmp r7, #0				@; comprobamos si el contador esta a 0
	beq .Lend_save_regs		@; si lo esta, ya hemos guardado todos los registros que son 0, si no:
	sub r5, #4				@; siguiente posicion de la pila
	str r6, [r5]			@; guardamos el 0
	sub r7, #1				@; decrementamos contador
	b .Lsave_regs			@; repetimos bucle
.Lend_save_regs:

	sub r5, #4				@; siguiente posicion de la pila
	str r3, [r5]			@; guardar argumento en la pila (R0)

		@; Guardar SP de la pila del proceso en el PCB
	str r5, [r4, #8]		@; guardar R5(SP) a la posicion SP del PCB (offset 8 bytes)

		@; Guardar el CPSR inicial del proceso
	mov r5, #0x1F			@; poner a 1 los bits del CPSR para moso SYS (resto de bits a 0)
	str r5, [r4, #12]		@; guardar el CPSR en el campo Status del PCB (offset 12 bytes)

		@; Inicializar campo workTicks
	str r6, [r4, #20]		@; guardar 0 en el campo workTicks del PCB (offset 20 bytes)
	@; Fin creacion del proceso

	@; Inicio añadir nuevo proceso a la cola RDY
	ldr r4, =_gd_qReady		@; cargar direccion de la cola RDY
	ldr r5, =_gd_nReady		@; cargar direccion de la variable nReady
	ldr r6, [r5]			@; obtener valor de la variable nReady
	strb r1, [r4, r6]		@; guardar numero de zocalo en la ultima posicion de la cola
	add r6, #1				@; incrementamos numero de procesos en la cola RDY en 1
	str r6, [r5]			@; y lo guardamos en la variable _gd_nReady
	@; Fin añadir nuevo proceso a la cola RDY

.LbadProcess:

	cmp r0, #1				@; comprobamos si R0 = 1, lo que significa que no se ha podido crear el proceso
	movne r0, #0			@; si no lo es, guardamos un 0 en R0 para indicar que el proceso se ha creado correctamente

	pop {r4-r7, pc}


	@; Rutina para terminar un proceso de usuario:
	@; pone a 0 el campo PID del PCB del z�calo actual, para indicar que esa
	@; entrada del vector _gd_pcbs[] est� libre; tambi�n pone a 0 el PID de la
	@; variable _gd_pidz (sin modificar el n�mero de z�calo), para que el c�digo
	@; de multiplexaci�n de procesos no salve el estado del proceso terminado.
_gp_terminarProc:
	ldr r0, =_gd_pidz
	ldr r1, [r0]			@; R1 = valor actual de PID + z�calo
	and r1, r1, #0xf		@; R1 = z�calo del proceso desbancado
	str r1, [r0]			@; guardar z�calo con PID = 0, para no salvar estado			
	ldr r2, =_gd_pcbs
	mov r10, #24
	mul r11, r1, r10
	add r2, r11				@; R2 = direcci�n base _gd_pcbs[zocalo]
	mov r3, #0
	str r3, [r2]			@; pone a 0 el campo PID del PCB del proceso
.LterminarProc_inf:
	bl _gp_WaitForVBlank	@; pausar procesador
	b .LterminarProc_inf	@; hasta asegurar el cambio de contexto
	
.end

