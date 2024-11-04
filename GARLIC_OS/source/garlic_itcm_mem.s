@;==============================================================================
@;
@;	"garlic_itcm_mem.s":	código de rutinas de soporte a la carga de
@;							programas en memoria (version 1.0)
@;
@;==============================================================================

.section .itcm,"ax",%progbits

	.arm
	.align 2
	

	.global _gm_reubicar
	@; rutina para interpretar los 'relocs' de un fichero ELF y ajustar las
	@; direcciones de memoria correspondientes a las referencias de tipo
	@; R_ARM_ABS32, restando la dirección de inicio de segmento y sumando
	@; la dirección de destino en la memoria;
	@;Parámetros:
	@; R0: dirección inicial del buffer de fichero (char *fileBuf)
	@; R1: dirección de inicio de segmento (unsigned int pAddr)
	@; R2: dirección de destino en la memoria (unsigned int *dest)
	@;Resultado:
	@; cambio de las direcciones de memoria que se tienen que ajustar
_gm_reubicar:
	push {r0-r12, lr}
		
		ldr r4, [r0, #32]				@; Offset de la primera tabla de secciones (e_shoff)
		ldrh r5, [r0, #48]				@; Número total de tablas (e_shnum)
		ldrh r11, [r0, #46]				@; Tamaño de cada tabla de sección para calcular offsets
		sub r2, r1				
		add r4, r0						@; Sumo el offset al archivo ELF para la tabla de secciones
		
	.LSeccions:
		ldr r6, [r4, #4]				@; Tipo de sección sh_type 
		cmp r6, #9						@; Compara si es de tipo SHT_REL
		bne .LMasEntradas				@; Si no lo es entramos en el salto
		ldr r10, [r4, #16]				@; Offset del segmento (sh_offset)
		ldr r8, [r4, #20]				@; Tamaño de la sección (sh_size)
		ldr r9, [r4, #36]				@; Tamaño en bytes de cada reubicador (sh_entsize)
		add r10, r0						@; Calcula dirección de los reubicadores	
		
	.LReubicadors:
		ldr r12, [r10, #4]				@; Obtiene el offset de reubicación
		and r12, #0xFF					@; Extrae los 8 bits bajos para el código numérico
		cmp r12, #2						@; Compara con el tipo R_ARM_ABS32 
		bne .LMesReubicadors				@; Si no lo es entramos en el salto
		ldr r12, [r10]					@; Carga la dirección a ajustar
		add r12, r2						@; Ajusta con el desplazamiento calculado
		ldr r1, [r12]					@; Carga la dirección reubicada
		add r1, r2						@; Suma el desplazamiento
		str r1, [r12]					@; Guarda el valor reubicado
		
	.LMesReubicadors:
		sub r8, r9						@; Resta el tamaño del reubicador de la sección restante
		add r10, r9						@; Avanza al siguiente reubicador en la sección
		cmp r8, #0						@; Verifica si quedan reubicadores
		bne .LReubicadors				@; Si aun quedan se busca el siguiente
		
	.LMasEntradas:
		sub r5, #1						@; Resta una entrada 
		add r4, r11						@; Le añadimos al offset el tamaño de tabla de reubicación
		cmp r5, #0						@; Miramos si hay entrada en la tabla de segmentos
		bne .LSeccions					@;Si aun quedan se busca la siguiente
		
	pop {r0-r12, pc}

.end
