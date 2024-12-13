@;==============================================================================
@;
@;	"garlic_itcm_proc.s":	codigo de las rutinas de control de procesos (1.0)
@;						(ver "garlic_system.h" para descripcion de rutinas)
@;
@;==============================================================================

.section .itcm,"ax",%progbits

	.arm
	.align 2
	
	.global _gp_WaitForVBlank
	@; rutina para pausar el procesador mientras no se produzca una interrupcion
	@; de retroceso vertical (VBL); es un sustituto de la "swi #5" que evita
	@; la necesidad de cambiar a modo supervisor en los procesos GARLIC;
_gp_WaitForVBlank:
	push {r0-r1, lr}
	ldr r0, =__irq_flags
.Lwait_espera:
	mcr p15, 0, lr, c7, c0, 4	@; HALT (suspender hasta nueva interrupcion)
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
	ldr	r2, [r12, #0x08]	@; R2 = REG_IE (mascara de bits con int. permitidas)
	ldr	r1, [r12, #0x0C]	@; R1 = REG_IF (mascara de bits con int. activas)
	and r1, r1, r2			@; filtrar int. activas con int. permitidas
	ldr	r2, =irqTable
.Lintr_find:				@; buscar manejadores de interrupciones especificos
	ldr r0, [r2, #4]		@; R0 = mascara de int. del manejador indexado
	cmp	r0, #0				@; si mascara = cero, fin de vector de manejadores
	beq	.Lintr_setflags		@; (abandonar bucle de busqueda de manejador)
	ands r0, r0, r1			@; determinar si el manejador indexado atiende a una
	beq	.Lintr_cont1		@; de las interrupciones activas
	ldr	r3, [r2]			@; R3 = direccion de salto del manejador indexado
	cmp	r3, #0
	beq	.Lintr_ret			@; abandonar si direccion = 0
	mov r2, lr				@; guardar direccion de retorno
	blx	r3					@; invocar el manejador indexado
	mov lr, r2				@; recuperar direccion de retorno
	b .Lintr_ret			@; salir del bucle de busqueda
.Lintr_cont1:	
	add	r2, r2, #8			@; pasar al siguiente indice del vector de
	b	.Lintr_find			@; manejadores de interrupciones especificas
.Lintr_ret:
	mov r1, r0				@; indica que interrupcion se ha servido
.Lintr_setflags:
	str	r1, [r12, #0x0C]	@; REG_IF = R1 (comunica interrupcion servida)
	ldr	r0, =__irq_flags	@; R0 = direccion flags IRQ para gestion IntrWait
	ldr	r3, [r0]
	orr	r3, r3, r1			@; activar el flag correspondiente a la interrupcion
	str	r3, [r0]			@; servida (todas si no se ha encontrado el maneja-
							@; dor correspondiente)
	mov	pc,lr				@; retornar al gestor de la excepcion IRQ de la BIOS


	.global _gp_rsiVBL
	@; Manejador de interrupciones VBL (Vertical BLank) de Garlic:
	@; se encarga de actualizar los tics, intercambiar procesos, etc.;
_gp_rsiVBL:
	push {r4-r7, lr}

	@; Incrementar contador de tics general y especifico y actualizar contadores DLY
	ldr r4, =_gd_tickCount	@; cargar direccion del contador tics general
	ldr r5, [r4]			@; obtener su valor
	add r5, #1				@; incrementar en 1
	str r5, [r4]			@; guardar nuevo valor

	bl _gp_actualizarDelay	@; actualizar contadores de DLY

	ldr r4, =_gd_pcbs		@; cargar direccion de _gd_pcbs
	ldr r5, =_gd_pidz		@; cargar direccion de _gd_pidz
	ldr r5, [r5]			@; obtener su valor
	and r5, #0xF			@; mantener bits de zocalo
	mov r6, #24				@; inicializar tamaño de cada entrada del vector
	mla r4, r5, r6, r4		@; calcular direccion base de la entrada correspondiente al zocalo
	ldr r5, [r4, #20]		@; obtener valor de workTicks
	add r5, #1				@; sumarle 1
	str r5, [r4, #20]		@; y volver a guardarlo
	@; Fin incrementar tics y actualizar DLY

	@; Detectar si quedan procesos en la cola RDY
	ldr r4, =_gd_nReady		@; cargar direccion _gd_nReady
	ldr r5, [r4]			@; obtener su valor
	cmp r5, #0				@; comprobar si es 0
	beq .LendVBL			@; si lo es, acabar multiplexacion
							@; si no, continuar la multiplexacion
	@; Fin detectar si quedan procesos en la cola RDY

	@; Comprobar proceso actual para salvar y/o restaurar contextos
	ldr r4, =_gd_pidz		@; cargar direccion del proceso actual
	ldr r5, [r4]			@; obtener su valor
	bic r5, #0x80000000		@; poner a 0 el bit de mas peso para no interferir
	cmp r5, #0				@; comprobar si es el SO
	moveq r7, #1			@; si lo es, guardar un 1 en R7 para indicar que hay que guardar el contexto
	beq .LcontextChange		@; y saltar a cambio de contexto
							@; si no, comprobar si ha acabado
	mov r5, r5, lsr #4		@; desplazar _gd_pidz 4 bits a la derecha para eliminar bits de zocalo
	cmp r5, #0				@; comprobar si PID = 0
	moveq r7, #0			@; si lo es, guardar numero != 1 para indicar que no hace falta guardar contexto
	beq .LcontextChange		@; y saltar a cambio de contexto
	mov r7, #1				@; si no lo es, guardar contexto primero (R7 = 1)

.LcontextChange:

	ldr r4, =_gd_nReady		@; guardar valores necesarios en los registros
	ldr r5, [r4]			@; antes de saltar al cambio de contexto
	ldr r6, =_gd_pidz		@; para que las subrutinas los usen
	cmp r7, #1				@; comprobar si hay que guardar el contexto o no
	bleq _gp_salvarProc		@; si R7=1, saltar a salvar el contexto
	bl _gp_restaurarProc	@; si no, directamente restaurar el siguiente
	@; Fin comprobar proceso para salvar y/o restaurar contexto

.LendVBL:

	pop {r4-r7, pc}


	@; Rutina para salvar el estado del proceso interrumpido en la entrada
	@; correspondiente del vector _gd_pcbs[];
	@;Parametros
	@; R4: direccion _gd_nReady
	@; R5: numero de procesos en RDY
	@; R6: direccion _gd_pidz
	@;Resultado
	@; R5: nuevo numero de procesos en RDY (+1)
_gp_salvarProc:
	push {r8-r11, lr}

	@; Guardar zocalo del proceso a la cola de RDY
	ldr r8, [r6]			@; obtener valor de _gd_pidz
	tst r8, #0x80000000		@; ver si el bit de mas peso esta activo
	and r8, #0xF			@; quedarse con los 4 bits bajos (zocalo) para calcular direcciones de memoria
	bne .LnoSaveRDY			@; si el bit esta activo (flag Z = 0) no guardar proceso a la cola RDY
	
	ldr r9, =_gd_qReady		@; cargar direccion de la cola de RDY
	strb r8, [r9, r5]		@; guardar zocalo en la cola RDY
	@; Fin guardar zocalo en la cola RDY

	@; Incrementar variable nReady
	add r5, #1				@; sumar 1 al numero de procesos en RDY (servira tambien de retorno de la rutina)
	str r5, [r4]			@; guardar nuevo numero en memoria
	@; Fin incrementar variable nReady

.LnoSaveRDY:
	@; Guardar registros en el PCB y la pila
		@; Guardar R15(PC) en el PCB
	ldr r9, =_gd_pcbs		@; cargar direccion base e los PCBs
	mov r10, #24			@; tamaño de un PCB
	mla r9, r8, r10, r9		@; calcular direccion base del PCB segun el zocalo (dir. base + tamaño PCB * zocalo)
	ldr r10, [r13, #60]		@; obtener PC del proceso a desbancar (valor mas bajo de la pila IRQ)
							@; (segun la estructura propuesta, el valor es el SP_irq + 60)
	str r10, [r9, #4]		@; y guardarlo en la posicion correcta del PCB

		@; Guardar CPSR del proceso al PCB
	mrs r8, spsr			@; obtener valor del CPSR del proceso a desbancar (almacenado en el SPSR del modo IRQ)
	str r8, [r9, #12]		@; y guardarlo en el PCB

		@; Cambiar al modo de ejecucion del proceso interrumpido
	and r8, #0x1F			@; quedarse con los bits de modo del proceso a desbancar
	mrs r9, cpsr			@; obtener CPSR_irq para mantener los demas bits iguales
	bic r9, #0x1F			@; eliminar bits de modo del CPSR_irq obtenido
	orr r9, r8				@; juntar los demas bits del CPSR_irq con los bits de modo del proceso a desbancar
	mov r8, r13 			@; guardamos temporalmente el SP del modo IRQ
	msr cpsr, r9			@; y guardamos el nuevo modo en el cpsr para cambiar al modo del proceso a desbancar

		@; Inicio apilar registros desde la pila IRQ hasta la pila del proceso a desbancar
	ldr r9, [r8, #12]		@; guardamos R11_irq en R9
	add r8, #60				@; vamos a la ultima posicion de la pila irq
	ldmda r8, {r10, r11}	@; guardamos R15_irq->R11 y R12_irq->R10
	mov r11, lr				@; rectificamos valor de R11 (no era el LR/R14)
	stmdb r13!, {r9-r11}	@; apilamos R14_irq, R12_irq y R11_irq contenidos en R11, R10 y R9 respectivamente
							@; (actualizando el valor del SP tras la operacion usando r13!)

	sub r8, #52				@; vamos a la posicion de R10 a la pila irq
	ldmda r8, {r9-r11}		@; cargamos los siguientes 3 valores (R10, R9, R8)
	stmdb r13!, {r9-r11}	@; y los guardamos a la pila del proceso

	add r8, #24				@; vamos a la posicion de R7
	ldmda r8, {r9-r11}		@; guardamos R7, R6 y R5
	stmdb r13!, {r9-r11}	@; y los apilamos

	sub r8, #12				@; vamos a la posicion de R4
	ldr r11, [r8]			@; guardamos R4
	add r8, #32				@; vamos a la posicion de R3
	ldmda r8, {r9, r10}		@; guardamos R3 y R2
	stmdb r13!, {r9-r11}	@; y los apilamos

	sub r8, #8				@; vamos a la posicion de R1
	ldmda r8, {r10, r11}	@; guardamos R1 y R0
	stmdb r13!, {r10, r11}	@; y los apilamos

		@; Guardar nuevo SP en el PCB
	ldr r8, =_gd_pcbs		@; obtenemos direccion de garlicPCB
	mov r9, #24				@; guardamos el tamaño de un PCB
	ldr r10, [r6]			@; obtenemos datos del proceso actual
	and r10, #0xF			@; nos quedamos con el numero de zocalo
	mla r8, r10, r9, r8		@; vamos a su direccion correspondiente en el vector
	str r13, [r8, #8]		@; guardamos nuevo SP en el PCB

		@; Volver al modo IRQ
	mrs r8, cpsr			@; obtenemos CPSR actual
	bic r8, #0x1F			@; eliminamos los bits de modo
	orr r8, #0x12			@; cambiamos a 1 los bits necesarios para el modo IRQ
	msr cpsr, r8			@; y guardamos el nuevo modo en el CPSR
	@; Fin guardar registros en el PCB y la pila

	pop {r8-r11, pc}


	@; Rutina para restaurar el estado del siguiente proceso en la cola de RDY;
	@;Parametros
	@; R4: direccion _gd_nReady
	@; R5: numero de procesos en RDY
	@; R6: direccion _gd_pidz
_gp_restaurarProc:
	push {r8-r11, lr}

	@; Obtener zocalo del siguiente proceso a poner en RUN
	ldr r8, =_gd_qReady		@; cargar direccion de la cola de RDY
	ldrb r9, [r8]			@; y obtenemos el primer proceso (zocalo)
	
	@; Cola RDY -1 proceso
	sub r5, #1				@; restamos 1 al numero de procesos en cola RDY
	str r5, [r4]			@; guardar nuevo num. procesos RDY en memoria

	@; Desplazar el resto de procesos de la cola una posicion hacia adelante
.Lshift_rdy:
	cmp r5, #0				@; comprobamos si aun quedan procesos en la cola
	beq .Lend_shift			@; si ya no quedan, no hacer nada
	ldrb r11, [r8, #1]		@; en caso que si, cargamos direccion del segundo elemento de la cola (primero esta "vacio")
	strb r11, [r8]			@; y lo guardamos en el primero
	add r8, #1				@; avanzamos al siguiente elemento
	sub r5, #1				@; restamos 1 al contador de procesos RDY
	b .Lshift_rdy			@; y repetimos bucle
.Lend_shift:
	ldr r5, [r4]			@; restaurar el contenido de R5 (ya que no se guarda con push y podria ocasionar problemas)
	@; Fin desplazar procesos de qReady hacia delante una posicion

	@; Obtener PID de la estructura garlicPCB
	ldr r8, =_gd_pcbs		@; cargamos la direccion de garlicPCB
	mov r10, #24			@; movemos el tamaño de cada estructura en el vector
	mla r8, r9, r10, r8		@; nos desplazamos al elemento del zocalo que nos interesa
	ldr r10, [r8]			@; y cargamos el valor del primer campo (PID)

	@; Inicio restaurar contenido del PCB y de la pila del proceso a la pila IRQ
		@; Guardar PID y zocalo en _gd_pidz
	mov r10, r10, lsl #4	@; desplazamos pid a los 28 bits altos
	orr r10, r9				@; y añadimos el zocalo en los 4 bits bajos
	str r10, [r6]			@; y guardamos el nuevo identificador

		@; Restaurar PC
	ldr r9, [r8, #4]		@; obtenemos R15(PC) de garlicPCB
	str r9, [r13, #60]		@; y lo guardamos en su posicion en la pila del modo IRQ

		@; Recuperar CPSR del proceso a restaurar
	ldr r9, [r8, #12]		@; obtener CPSR del PCB del proceso
	msr spsr, r9			@; y lo guardamos en el SPSR_irq

		@; Cambiar al modo de ejecucion del proceso a restaurar
	and r9, #0x1F			@; quedarse con los bits de modo del proceso a restaurar
	mrs r10, cpsr			@; obtener CPSR_irq para mantener los demas bits iguales
	bic r10, #0x1F			@; eliminar bits de modo del CPSR_irq obtenido
	orr r9, r10				@; juntar los demas bits del CPSR_irq con los bits de modo del proceso a restaurar
	mov r11, r13			@; guardamos temporalmente el SP del modo IRQ
	msr cpsr, r9			@; y guardamos el nuevo modo en el CPSR para cambiar al modo del proceso a desbancar

		@; Inicio desapilar registros del modo del proceso al modo IRQ
	ldr r13, [r8, #8]		@; cargar el SP guardado en el PCB en el SP del modo del proceso

	ldmia r13!, {r8-r10}	@; desapilamos R0-R2 en R8-R10 respectivamente
	add r11, #48			@; vamos a la posicion de R2 en la pila
	stmda r11, {r8-r10}		@; y guardamos los registros

	ldmia r13!, {r8-r10}	@; desapilamos R3-R5
	str r8, [r11, #4]		@; guardamos R3
	sub r11, #24			@; vamos a la posicion de R5
	stmda r11, {r9, r10}	@; guardamos R4 y R5

	ldmia r13!, {r8-r10}	@; desapilamos R6-R8
	add r11, #8				@; vamos a la posicion de R7
	stmda r11, {r8, r9}		@; guardamos R6 y R7
	sub r11, #32			@; vamos a la posicion de R8
	str r10, [r11]			@; guardamos R8

	ldmia r13!, {r8-r10}	@; desapilamos R9-R11
	add r11, #12			@; vamos a la posicion de R11
	stmda r11, {r8-r10}		@; guardamos registros

	ldmia r13!, {r8, lr}	@; desapilamos R12, y R14 directamente en el LR
	add r11, #44			@; vamos a la posicion de R12
	str r8, [r11]			@; guardamos R12
		@; Fin desapilar registros del modo del proceso al modo IRQ

		@; Volver a modo IRQ
	mrs r8, cpsr			@; obtenemos CPSR actual
	bic r8, #0x1F			@; ponemos a 0 los bits de modo
	orr r8, #0x12			@; los cambiamos al modo IRQ
	msr cpsr, r8			@; y guardamos nuevo modo
	@; Fin restaurar contenido del PCB y de la pila del proceso a la pila IRQ

	pop {r8-r11, pc}


	.global _gp_waitS
_gp_waitS:
	push {r1-r2, lr}

	@; Comprobar que el semaforo existe
	cmp r0, #7				@; comprobamos que el semaforo indicado no pasa de 7 (rango es 0-7)
	movhi r0, #0			@; si se pasa, mover un 0 a R0
	bhi .LreturnWait		@; y salir de la rutina indicando que no se ha bloqueado ningun proceso

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

	pop {r1-r2, lr}


	.global _gp_signalS
_gp_signalS:
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


	@; Rutina para actualizar la cola de procesos retardados, poniendo en
	@; cola de RDY aquellos cuyo numero de tics de retardo sea 0
_gp_actualizarDelay:
	push {r0-r6, lr}

	@; comprobar si hay elementos en la cola de delay
	ldr r1, =_gd_nDelay		@; cargar direccion de _gd_nDelay
	ldr r1, [r1]			@; obtener su valor
	cmp r1, #0				@; comprobar si hay procesos en DLY
	beq .LemptyDelay		@; si no los hay, no hacer nada

	@; inicializar registros para recorrer la cola
	ldr r0, =_gd_qDelay		@; cargar direccion base de la cola DLY
	mov r2, #0				@; inicializar indice a 0 para recorrer la cola

	@; bucle para restar 1 al contador de ticks	
.LsubTime:
	ldr r3, [r0, r2, lsl #2]	@; obtener valor del elemento en indice R2*4 (r2, lsl #2)
	sub r3, #1				@; restarle 1
	str r3, [r0, r2, lsl #2]	@; guardar el nuevo valor
	add r2, #1				@; indice +1
	cmp r2, r1				@; comprobar si se han actualizado todos los contadores
	blo .LsubTime			@; si aun faltan, iterar de nuevo el bucle

	@; bucle para comprobar si hay algun contador a 0
	mov r2, #0				@; restauramos el indice a 0
.LcheckZero:
	cmp r2, r1				@; comprobar si se ha llegado al final
	beq .LemptyDelay		@; si se ha recorrido todo, salir del bucle
	ldr r3, [r0, r2, lsl #2]	@; obtener el valor del elemento de la cola
	mov r3, r3, lsl #16		@; quitar bits de zocalo
	cmp r3, #0				@; a pesar de estar en los bits altos, si el contador es >0 el salto se tomara igualmente
	addhi r2, #1			@; si contador >0, ir al siguiente elemento
	bhi .LcheckZero			@; e iterar de nuevo

	@; mover el proceso con contador a 0 a la cola RDY
	ldr r3, [r0, r2, lsl #2]	@; si no, cargar de nuevo el elemento pero el valor entero
	mov r3, r3, lsr #24		@; quedarse con los 8 bits altos (zocalo)
	ldr r4, =_gd_nReady		@; cargar direccion del numero de procesos en RDY
	ldr r5, =_gd_qReady		@; cargar direccion de la cola de RDY
	ldr r6, [r4]			@; obtener el valor del numero de procesos en RDY
	strb r3, [r5, r6]		@; guardar el zocalo del proceso en DLY a la cola de RDY
	add r6, #1				@; incrementar numero de procesos en RDY
	str r6, [r4]			@; guardarlo en memoria
	mov r3, r2				@; hacer una copia del indice actual

	@; desplazar los procesos restantes una posicion hacia adelante
.Lshift_delay:
	add r2, #1				@; sumar 1 al indice para ver si hay mas elementos
	cmp r2, r1				@; comparar indice con el numero de elementos que habia originalmente (R1)
	beq .Lcontinue			@; si no hay mas elementos, salir del bucle

	ldr r4, [r0, r2, lsl #2]	@; si los hay, cargar el valor del siguiente
	sub r2, #1				@; ir a la posicion anterior
	str r4, [r0, r2, lsl #2]	@; guardar la informacion en la nueva posicion
	add r2, #1				@; volver a la posicion actual
	b .Lshift_delay			@; volver a iterar el bucle

	@; continuar comprobando contador de los elementos
.Lcontinue:
	sub r1, #1				@; restar 1 al numero de elementos en la cola DLY
	ldr r4, =_gd_nDelay		@; obtener direccion del contador de procesos en Delay
	str r1, [r4]			@; actualizar su valor
	mov r2, r3				@; restablecer indice a su valor original (tras mover los elementos, ahora corresponde al siguiente elemento)
	b .LcheckZero			@; y saltar de nuevo a comprobar si hay mas procesos que han llegado a 0

	@; final de la rutina _gp_actualizarDelay
.LemptyDelay:

	pop {r0-r6, pc}




	.global _gp_numProc
	@;Resultado
	@; R0: numero de procesos total
_gp_numProc:
	push {r1-r2, lr}

	mov r0, #1				@; contar siempre 1 proceso en RUN
	ldr r1, =_gd_nReady
	ldr r2, [r1]			@; R2 = numero de procesos en cola de RDY
	add r0, r2				@; anadir procesos en RDY
	ldr r1, =_gd_nDelay
	ldr r2, [r1]			@; R2 = numero de procesos en cola de DLY
	add r0, r2				@; anadir procesos retardados
	ldr r1, =_gd_nBlock
	ldr r2, [r1]			@; R2 = numero de procesos en la cola de BLK
	add r0, r2				@; anadir procesos bloqueados

	pop {r1-r2, pc}


	.global _gp_crearProc
	@; prepara un proceso para ser ejecutado, creando su entorno de ejecucion y
	@; colocandolo en la cola de RDY;
	@;Parametros
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
	moveq r7, #1			@; si lo es, devolver R0 > 0 (comprobando R7 al final)
	beq .LbadProcess		@; y saltar al final sin crear proceso
	@; Fin comprobacion zocalo

	@; Inicio comprobacion PCB
	ldr r4, =_gd_pcbs		@; si no, cargar dir. base de los PCBs
	mov r5, #24				@; tamaño de un PCB
	mla r4, r5, r1, r4		@; obtener direccion del PCB del zocalo indicado (dir. base + tamaño PCB * zocalo)
	bl _gp_inhibirIRQs
	ldr r5, [r4]			@; cargar PID del PCB obtenido
	cmp r5, #0				@; comprobar si esta libre (PID = 0)
	movne r7, #1			@; si no lo esta, devolver R0 > 0 (comprobando R7 al final)
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
	bl _gp_desinhibirIRQs
	cmp r7, #1				@; comprobamos si R7 = 1, lo que significa que no se ha podido crear el proceso
	movne r0, #0			@; si no lo es, guardamos un 0 en R0 para indicar que el proceso se ha creado correctamente
	moveq r0, #1			@; si lo es, entonces guardar un 1

	pop {r4-r7, pc}


	@; Rutina para terminar un proceso de usuario:
	@; pone a 0 el campo PID del PCB del zocalo actual, para indicar que esa
	@; entrada del vector _gd_pcbs[] esta libre; tambien pone a 0 el PID de la
	@; variable _gd_pidz (sin modificar el numero de zocalo), para que el codigo
	@; de multiplexacion de procesos no salve el estado del proceso terminado.
_gp_terminarProc:
	ldr r0, =_gd_pidz
	ldr r1, [r0]			@; R1 = valor actual de PID + zocalo
	and r1, r1, #0xf		@; R1 = zocalo del proceso desbancado
	bl _gp_inhibirIRQs
	str r1, [r0]			@; guardar zocalo con PID = 0, para no salvar estado			
	ldr r2, =_gd_pcbs
	mov r10, #24
	mul r11, r1, r10
	add r2, r11				@; R2 = direccion base _gd_pcbs[zocalo]
	mov r3, #0
	str r3, [r2]			@; pone a 0 el campo PID del PCB del proceso
	str r3, [r2, #20]		@; borrar porcentaje de USO de la CPU
	ldr r0, =_gd_sincMain
	ldr r2, [r0]			@; R2 = valor actual de la variable de sincronismo
	mov r3, #1
	mov r3, r3, lsl r1		@; R3 = mascara con bit correspondiente al zocalo
	orr r2, r3
	str r2, [r0]			@; actualizar variable de sincronismo
	bl _gp_desinhibirIRQs
.LterminarProc_inf:
	bl _gp_WaitForVBlank	@; pausar procesador
	b .LterminarProc_inf	@; hasta asegurar el cambio de contexto



	.global _gp_matarProc
	@; Rutina para destruir un proceso de usuario:
	@; borra el PID del PCB del zocalo referenciado por parametro, para indicar
	@; que esa entrada del vector _gd_pcbs esta libre; elimina el indice de
	@; zocalo de la cola de RDY o de la cola de DLY, este donde este;
	@; Parametros:
	@;	R0:	zocalo del proceso a matar (entre 1 y 15).
_gp_matarProc:
	push {r1-r5, lr}

	@; poner campo PID a 0 de _gd_pcbs del zocalo indicado
	bl _gp_inhibirIRQs
	ldr r1, =_gd_pcbs		@; obtener direccion base de las PCBs
	mov r2, #24				@; tamaño de una PCB
	mla r1, r0, r2, r1		@; multiplicar el tamaño de una PCB por el zocalo (indice)
	mov r2, #0				@; inicializar un 0 en R2
	str r2, [r1]			@; y guardar el 0 en el campo PID (primer campo)
	bl _gp_desinhibirIRQs

	@; inicializar variables para buscar en la cola RDY
	ldr r1, =_gd_qReady		@; cargar direccion de la cola RDY para buscar el zocalo
	ldr r2, =_gd_nReady		@; cargar direccion de la variable _gd_nReady
	ldr r3, [r2]			@; obtener su valor
	mov r4, #0				@; inicializar indice a 0

	@; buscar zocalo en la cola RDY
.LfindProcRDY:
	cmp r4, r3				@; comprobar si ha llegado al final
	beq .LdelaySetup		@; si no lo ha encontrado, buscar en la cola DLY
	ldrb r5, [r1, r4]		@; obtener valor del zocalo
	cmp r5, r0				@; comprobar si es el mismo que el que queremos matar
	addne r4, #1			@; en caso que no, sumar 1 al indice
	bne .LfindProcRDY		@; y volver a iterar

	@; desplazar procesos hacia adelante de la cola RDY
	bl _gp_inhibirIRQs
.LshiftQueueRDY:
	add r4, #1				@; sumar 1 al indice para ver si hay mas elementos
	cmp r4, r3				@; comparar indice con el numero de elementos que habia originalmente (R3)
	beq .Lcleanup			@; y salir de la funcion si no hay mas
	ldrb r5, [r1, r4]		@; si los hay, cargar el valor del siguiente
	sub r4, #1				@; restar 1 al indice
	strb r5, [r1, r4]		@; y guardarlo en el sitio del que se ha sacado de la cola
	add r4, #1				@; incrementar indice en 1
	b .LshiftQueueRDY		@; y seguir iterando

	@; inicializar variables para buscar en la cola DLY
.LdelaySetup:
	ldr r1, =_gd_qDelay		@; cargar direccion de la cola DLY para buscar el zocalo
	ldr r2, =_gd_nDelay		@; cargar la direccion de la variable _gd_nDelay
	ldr r3, [r2]			@; obtener su valor
	mov r4, #0				@; inicializar indice a 0

	@; buscar zocalo en la cola DLY
.LfindProcDLY:
	cmp r4, r3				@; comprobar si se ha llegado al final
	beq .LblockSetup		@; si se ha recorrido todo, salir de la funcion
	ldr r5, [r1, r4, lsl #2]		@; si no, cargar el zocalo correspondiente de la cola
	mov r5, r5, lsr #24		@; quedarse con los 8 bits altos (zocalo)
	cmp r5, r0				@; comprobar si es igual al indicado
	addne r4, #1			@; en caso que no, sumar 1 al indice
	bne .LfindProcDLY		@; e iterar de nuevo

	@; desplazar procesos hacia adelante de la cola RDY
	bl _gp_inhibirIRQs
.LshiftQueueDLY:
	add r4, #1				@; sumar 1 al indice para ver si hay mas elementos
	cmp r4, r3				@; comparar indice con el numero de elementos que habia originalmente (R3)
	beq .Lcleanup			@; y salir de la funcion si no hay mas
	ldr r5, [r1, r4, lsl #2]		@; si los hay, cargar el valor del siguiente
	sub r4, #1				@; restar 1 al indice
	str r5, [r1, r4, lsl #2]		@; y guardarlo en el sitio del que se ha sacado de la cola
	add r4, #1				@; incrementar indice en 1
	b .LshiftQueueRDY		@; y seguir iterando

	@; inicializar las variables para buscar en la lista BLK
.LblockSetup:
	ldr r1, =_gd_qBlock		@; cargar direccion de la lista de procesos bloqueados
	ldr r2, =_gd_mutex		@; cargar direccion de la lista de semaforos
	mov r3, #8				@; inicializar R3 con un 8 porque solo hay 8 semaforos
	mov r4, #0				@; inicializar indice a 0

	@; buscar el proceso en la lista BLK
.LfindProcBLK:
	cmp r4, r3				@; comprobar si se ha llegado al final
	beq .LfinMatar			@; si se ha recorrido todo, salir de la funcion
	ldrb r5, [r1, r4]		@; si no, cargar zocalo
	cmp r5, r0				@; comprobar si es el que se quiere matar
	addne r4, #1			@; si no, ir al siguiente elemento
	bne .LfindProcBLK		@; y volver a iterar

	@; restaurar la entrada del proceso de la lista BLK a 0
	bl _gp_inhibirIRQs
	mov r5, #0				@; mover un 0 a R5
	strb r5, [r1, r4]		@; para guardarlo en el lugar del zocalo en la lista BLK
	mov r5, #1				@; mover un 1 a R5
	strb r5, [r2, r4]		@; para indicar que el semaforo que usaba el zocalo esta libre ahora
	ldr r1, =_gd_nBlock		@; cargar direccion del numero de procesos en BLK
	ldr r2, [r1]			@; obtener su valor
	sub r2, #1				@; restarle 1
	str r2, [r1]			@; y guardarlo de nuevo
	b .LfinMatar			@; acabar rutina

	@; cambios finales de matar el proceso
.Lcleanup:
	sub r3, #1				@; restar 1 al numero de elementos en la cola en la que se estaba iterando
	str r3, [r2]			@; y actualizar su valor

.LfinMatar:
	bl _gp_desinhibirIRQs

	pop {r1-r5, pc}

	
	.global _gp_retardarProc
	@; retarda la ejecucion de un proceso durante cierto numero de segundos,
	@; colocandolo en la cola de DLY
	@;Parametros
	@; R0: int nsec
_gp_retardarProc:
	push {r1-r4, lr}

	@; Calcular cuantos ticks corresponden al retardo
	mov r1, #60				@; R1 = 60 porque el programa tendra 60 retrocesos verticales por segundo
	mul r1, r0				@; multiplicar 60*nsec para obtener ticks

	@; Construir word con zocalo y bits retardo y poner bit de mas peso a 1 de _gd_pidz
	ldr r2, =_gd_pidz		@; cargar direccion de _gd_pidz
	ldr r3, [r2]			@; obtener su valor
	orr r3, #0x80000000		@; poner el bit de mas peso a 1
	str r3, [r2]			@; almacenar _gd_pidz modificado
	and r3, #0xF			@; quedarse con los 4 bits bajos (zocalo)
	mov r3, r3, lsl #24		@; desplazar zocalo a los 8 bits altos
	orr r1, r3				@; juntar bits de zocalo con el numero de ticks a retardar
	
	@; Poner el proceso actual a la cola DLY
	ldr r2, =_gd_nDelay		@; cargar direccion de _gd_nDelay
	ldr r3, [r2]			@; obtener su valor
	ldr r4, =_gd_qDelay		@; cargar la direccion de _gd_qDelay
	str r1, [r4, r3, lsl #2]		@; guardar word construido en la siguiente posicion libre
	add r3, #1				@; incrementar en 1 el numero de procesos en DLY
	str r3, [r2]			@; guardar el nuevo valor

	bl _gp_WaitForVBlank	@; forzar un cambio de contexto

	pop {r1-r4, pc}			@; no retornara hasta que se haya agotado el retardo


	.global _gp_inihibirIRQs
	@; pone el bit IME (Interrupt Master Enable) a 0, para inhibir todas
	@; las IRQs y evitar asi posibles problemas debidos al cambio de contexto
_gp_inhibirIRQs:
	push {r0-r1, lr}

	ldr r0, =0x04000208		@; cargar registro con la direccion de REG_IME
	ldrh r1, [r0]			@; cargar su contenido (halfword)
	bic r1, #0x01			@; poner bit 0 a 0
	strh r1, [r0]			@; y guardar el nuevo valor

	pop {r0-r1, pc}


	.global _gp_desinihibirIRQs
	@; pone el bit IME (Interrupt Master Enable) a 1, para desinhibir todas
	@; las IRQs
_gp_desinhibirIRQs:
	push {r0-r1, lr}

	ldr r0, =0x04000208		@; cargar registro con la direccion de REG_IME
	ldrh r1, [r0]			@; cargar su contenido (halfword)
	orr r1, #0x01			@; poner el bit 0 a 1
	strh r1, [r0]			@; y guardar el nuevo valor

	pop {r0-r1, pc}


	.global _gp_rsiTIMER0
	@; Rutina de Servicio de Interrupcion (RSI) para contabilizar los tics
	@; de trabajo de cada proceso: suma los tics de todos los procesos y calcula
	@; el porcentaje de uso de la CPU, que se guarda en los 8 bits altos de la
	@; entrada _gd_pcbs[z].workTicks de cada proceso (z) y, si el procesador
	@; grafico secundario esta correctamente configurado, se imprime en la
	@; columna correspondiente de la tabla de procesos.
_gp_rsiTIMER0:
	push {r0-r8, lr}

	@; primero sumar campo workTicks del proceso en RUN
	ldr r0, =_gd_pcbs		@; cargar direccion base de los PCBs
	ldr r1, =_gd_pidz		@; cargar direccion de _gd_pidz
	ldr r2, [r1]			@; obtener el valor del proceso activo actualmente
	and r2, #0xF			@; quedarse con los bits de zocalo
	mov r1, #24				@; tamaño de un PCB
	mla r3, r1, r2, r0		@; R3 = direccion base del PCB del zocalo
	ldr r4, [r3, #20]		@; R4 sera el contador total de tics

	@; preparar registros para sumar el resto de workTicks
	ldr r1, =_gd_qReady		@; cargar direccion base de la cola RDY
	ldr r2, =_gd_nReady		@; cargar direccion de la variable _gd_nReady
	ldr r2, [r2]			@; obtener su valor
	cmp r2, #0				@; si no hay procesos en la cola RDY
	beq .LskipRDY			@; saltar a la siguiente cola
	mov r3, #0				@; indice para recorrer las diferentes colas

	@; bucle para sumar workTicks de los procesos en RDY
.LcountRDY:
	ldrb r5, [r1, r3]		@; obtener zocalo del proceso
	mov r6, #24				@; guardar tamaño de un PCB
	mla r7, r5, r6, r0		@; obtener direccion base del PCB del zocalo obtenido
	ldr r6, [r7, #20]		@; obtener valor del campo workTicks
	bic r6, #0xFF000000		@; eliminar porcentaje anterior (por si no se ha reseteado)
	add r4, r6				@; sumar workTicks al contador total

	add r3, #1				@; sumar 1 al indice
	cmp r3, r2				@; comparamos si hemos visto todos los procesos
	blo .LcountRDY			@; si aun quedan, volver a iterar

.LskipRDY:
	@; preparar variables para hacer lo mismo en la cola DLY
	ldr r2, =_gd_nDelay		@; cargar la direccion de la variable _gd_nDelay
	ldr r2, [r2]			@; obtener su valor
	cmp r2, #0				@; comprobar si hay procesos en DLY
	beq .LskipDLY			@; si no los hay, saltarse el bucle
	ldr r1, =_gd_qDelay		@; cargar direccion de la cola DLY
	mov r3, #0				@; restablecer indice a 0

	@; bucle para sumar workTicks de los procesos en DLY
.LcountDLY:
	ldr r5, [r1, r3, lsl #2]		@; obtener valor del proceso en DLY
	mov r5, r5, lsr #24		@; desplazar los 8 bits altos a la derecha para obtener el zocalo
	mov r6, #24				@; guardar tamaño de un PCB
	mla r7, r5, r6, r0		@; obtener direccion base del PCB del zocalo obtenido
	ldr r6, [r7, #20]		@; obtener valor del campo workTicks
	bic r6, #0xFF000000		@; eliminar porcentaje anterior (por si no se ha reseteado)
	add r4, r6				@; sumar workTicks al contador total

	add r3, #1				@; sumar 1 al indice
	cmp r3, r2				@; comparamos si hemos visto todos los procesos
	blo .LcountDLY			@; si aun quedan, volver a iterar

	@; preparar variables para hacer lo mismo en la lista BLK
.LskipDLY:
	ldr r2, =_gd_nBlock		@; cargar la direccion de la variable _gd_nDelay
	ldr r2, [r2]			@; obtener su valor
	cmp r2, #0				@; comprobar si hay procesos en BLK
	beq .LskipBLK			@; si no los hay, saltarse el bucle
	mov r2, #8				@; mover un 8 a R2 porque solo hay 8 semaforos
	ldr r1, =_gd_qBlock		@; cargar direccion de la lista BLK
	mov r3, #0				@; restablecer indice a 0

	@; bucle para sumar workTicks de los procesos en DLY
.LcountBLK:
	ldrb r5, [r1, r3]		@; obtener zocalo del proceso
	cmp r5, #0				@; si es 0 (no hay ningun proceso bloqueado en este semaforo)
	beq .LskipMutex			@; pasar al siguiente semaforo
	mov r6, #24				@; guardar tamaño de un PCB
	mla r7, r5, r6, r0		@; obtener direccion base del PCB del zocalo obtenido
	ldr r6, [r7, #20]		@; obtener valor del campo workTicks
	bic r6, #0xFF000000		@; eliminar porcentaje anterior (por si no se ha reseteado)
	add r4, r6				@; sumar workTicks al contador total

.LskipMutex:
	add r3, #1				@; sumar 1 al indice
	cmp r3, r2				@; comparamos si hemos visto todos los semaforos
	blo .LcountBLK			@; si aun quedan, volver a iterar


.LskipBLK:

	mov r8, r4				@; ahora R8 contiene el numero total de workTicks
	
	@; calcular porcentaje uso del proceso en RUN
	ldr r1, =_gd_pidz
	ldr r2, [r1]
	and r2, #0xF
	mov r1, #24
	mla r3, r1, r2, r0
	ldr r6, [r3, #20]
	bic r6, #0xFF000000

	push {r0-r3}			@; salvar estado de los registros R0-R3
	sub sp, #8				@; guardar espacio en la pila para el cociente y el resto
	mov r0, r6				@; pasar el numerador
	mov r6, #100			@; mover un 100 a R6
	mul r0, r6				@; y multiplicar para hacer el calculo (100*workTicks/ticksTotales = %uso)
	mov r1, r8				@; pasar el denominador
	mov r2, sp				@; pasar direccion de memoria para el cociente
	add r3, sp, #4			@; pasar direccion de memoria para el resto
	bl _ga_divmod			@; hacer la división
	pop {r4-r5}				@; R4 = cociente y R5 = resto
	pop {r0-r3}				@; recuperar registros R0-R3 para seguir iterando el bucle
	mov r4, r4, lsl #24		@; desplazar porcentaje a los 8 bits altos
	str r4, [r3, #20]		@; guardar porcentaje en el campo workTicks

	@; calcular porcentaje de cada proceso y poner su campo workTicks a 0 (cola RDY)
	ldr r1, =_gd_qReady		@; cargar direccion base de la cola RDY
	ldr r2, =_gd_nReady		@; cargar direccion de la variable _gd_nReady
	ldr r2, [r2]			@; obtener su valor
	cmp r2, #0				@; comprobar si hay elementos en la cola
	beq .LnoreadRDY			@; saltarla si no hay elementos
	mov r3, #0				@; indice para recorrer las diferentes colas
	mov r4, #24				@; guardar tamaño de un PCB

.LreadRDY:
	ldrb r5, [r1, r3]		@; obtener zocalo del proceso			
	mla r7, r5, r4, r0		@; obtener direccion base del PCB del zocalo obtenido
	ldr r6, [r7, #20]		@; obtener valor del campo workTicks
	bic r6, #0xFF000000		@; eliminar porcentaje anterior (por si no se ha reseteado)

	@; calcular porcentaje de uso de cpu (aproximadamente, no es 100% preciso)
	push {r0-r3}			@; salvar estado de los registros R0-R3
	sub sp, #8				@; guardar espacio en la pila para el cociente y el resto
	mov r0, r6				@; pasar el numerador
	mov r6, #100			@; mover un 100 a R6
	mul r0, r6				@; y multiplicar para hacer el calculo (100*workTicks/ticksTotales = %uso)
	mov r1, r8				@; pasar el denominador
	mov r2, sp				@; pasar direccion de memoria para el cociente
	add r3, sp, #4			@; pasar direccion de memoria para el resto
	bl _ga_divmod			@; hacer la división
	pop {r4-r5}				@; R4 = cociente y R5 = resto
	pop {r0-r3}				@; recuperar registros R0-R3 para seguir iterando el bucle
	mov r4, r4, lsl #24		@; desplazar porcentaje a los 8 bits altos
	str r4, [r7, #20]		@; guardar porcentaje en el campo workTicks

	mov r4, #24				@; restablecer R4 al tamaño de un PCB
	add r3, #1				@; sumar 1 al indice
	cmp r3, r2				@; comparamos si hemos visto todos los procesos
	blo .LreadRDY			@; si aun quedan, volver a iterar

.LnoreadRDY:
	@; preparar variables para recorrer la cola DLY
	ldr r2, =_gd_nDelay		@; cargar la direccion de la variable _gd_nDelay
	ldr r2, [r2]			@; obtener su valor
	cmp r2, #0				@; comprobar si hay procesos en DLY
	beq .LnoreadDLY			@; si no los hay, saltarse el bucle
	ldr r1, =_gd_qDelay		@; cargar direccion de la cola DLY
	mov r3, #0				@; restablecer indice a 0

	@; calcular porcentaje de cada proceso y poner su campo workTicks a 0 (cola DLY)
.LreadDLY:
	ldr r5, [r1, r3, lsl #2]		@; obtener valor del proceso en DLY
	mov r5, r5, lsr #24		@; desplazar los 8 bits altos a la derecha para obtener el zocalo
	mla r7, r5, r4, r0		@; obtener direccion base del PCB del zocalo obtenido
	ldr r6, [r7, #20]		@; obtener valor del campo workTicks
	bic r6, #0xFF000000		@; eliminar porcentaje anterior (por si no se ha reseteado)
	
	@; calcular porcentaje de uso de cpu (aproximadamente, no es 100% preciso)
	push {r0-r3}			@; salvar estado de los registros R0-R3
	sub sp, #8				@; guardar espacio en la pila para el cociente y el resto
	mov r0, r6				@; pasar el numerador
	mov r6, #100			@; mover un 100 a R6
	mul r0, r6				@; y multiplicar para hacer el calculo (100*workTicks/ticksTotales = %uso)
	mov r1, r8				@; pasar el denominador
	mov r2, sp				@; pasar direccion de memoria para el cociente
	add r3, sp, #4			@; pasar direccion de memoria para el resto
	bl _ga_divmod			@; hacer la división
	pop {r4-r5}				@; R4 = cociente y R5 = resto
	pop {r0-r3}				@; recuperar registros R0-R3 para seguir iterando el bucle
	mov r4, r4, lsl #24		@; desplazar porcentaje a los 8 bits altos
	str r4, [r7, #20]		@; guardar porcentaje en el campo workTicks

	mov r4, #24				@; restablecer R4 al tamaño de un PCB
	add r3, #1				@; sumar 1 al indice
	cmp r3, r2				@; comparamos si hemos visto todos los procesos
	blo .LreadDLY			@; si aun quedan, volver a iterar

.LnoreadDLY:

	ldr r2, =_gd_nBlock		@; cargar la direccion de la variable _gd_nDelay
	ldr r2, [r2]			@; obtener su valor
	cmp r2, #0				@; comprobar si hay procesos en BLK
	beq .LnoreadBLK			@; si no los hay, saltarse el bucle
	mov r2, #8				@; mover un 8 a R2 porque solo hay 8 semaforos
	ldr r1, =_gd_qBlock		@; cargar direccion de la lista BLK
	mov r3, #0				@; restablecer indice a 0

	@; calcular porcentaje de cada proceso y poner su campo workTicks a 0 (cola BLK)
.LreadBLK:
	ldrb r5, [r1, r3]		@; obtener zocalo del proceso
	cmp r5, #0				@; si es 0 (no hay ningun proceso bloqueado en este semaforo)
	beq .LnextMutex			@; pasar al siguiente semaforo
	mla r7, r5, r4, r0		@; obtener direccion base del PCB del zocalo obtenido
	ldr r6, [r7, #20]		@; obtener valor del campo workTicks
	bic r6, #0xFF000000		@; eliminar porcentaje anterior (por si no se ha reseteado)

	@; calcular porcentaje de uso de cpu (aproximadamente, no es 100% preciso)
	push {r0-r3}			@; salvar estado de los registros R0-R3
	sub sp, #8				@; guardar espacio en la pila para el cociente y el resto
	mov r0, r6				@; pasar el numerador
	mov r6, #100			@; mover un 100 a R6
	mul r0, r6				@; y multiplicar para hacer el calculo (100*workTicks/ticksTotales = %uso)
	mov r1, r8				@; pasar el denominador
	mov r2, sp				@; pasar direccion de memoria para el cociente
	add r3, sp, #4			@; pasar direccion de memoria para el resto
	bl _ga_divmod			@; hacer la división
	pop {r4-r5}				@; R4 = cociente y R5 = resto
	pop {r0-r3}				@; recuperar registros R0-R3 para seguir iterando el bucle
	mov r4, r4, lsl #24		@; desplazar porcentaje a los 8 bits altos
	str r4, [r7, #20]		@; guardar porcentaje en el campo workTicks

.LnextMutex:
	mov r4, #24
	add r3, #1				@; sumar 1 al indice
	cmp r3, r2				@; comparamos si hemos visto todos los semaforos
	blo .LreadBLK			@; si aun quedan, volver a iterar

.LnoreadBLK:

@;	ldr r6, =_gp_msg
@;	add r6, #3
	@; escribir porcentaje de los procesos en la pantalla inferior
@;.LnextItem:
@;	mov r8, r0
@;	ldr r7, [r8, #20]
@;	cmp r7, #0
@;	addeq r8, #24
@;	beq .LnextItem

@;.LintToASCII:
@;	sub sp, #8				@; guardar espacio en la pila para el cociente y el resto
@;	mov r0, r7				@; pasar el numerador
@;	mov r1, #10				@; pasar el denominador
@;	mov r2, sp				@; pasar direccion de memoria para el cociente
@;	add r3, sp, #4			@; pasar direccion de memoria para el resto
@;	bl _ga_divmod			@; hacer la división
@;	pop {r4-r5}				@; R4 = cociente y R5 = resto

@;	add r5, #'0'			@; sumar valor ASCII del caracter '0' para obtener valor ASCII del resultado
@;	strb r5, [r6]
@;	sub r6, #1
@;	cmp r4, #0
@;	addeq r4, #'0'
@;	streqb r4, [r6]

	@; TODO next

	@; poner a 1 el bit 0 de _gd_sincMain para indicar al programa
	@; principal que dispone de los porcentajes de uso de CPU
	ldr r0, =_gd_sincMain	@; cargar direccion de _gd_sincMain
	ldr r1, [r0]			@; obtener su valor
	orr r1, #0x1			@; poner a 1 el bit 0
	str r1, [r0]			@; y guardarlo de nuevo

	pop {r0-r8, pc}

@;_gp_msg:
@;	.space 4

	
.end

