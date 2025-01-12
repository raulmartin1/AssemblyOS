@;==============================================================================
@;
@;	"garlic_dtcm.s":	zona de datos basicos del sistema GARLIC 2.0
@;						(ver "garlic_system.h" para descripcion de variables)
@;
@;==============================================================================

.section .dtcm,"wa",%progbits

	.align 2

	.global _gd_pidz			@; Identificador de proceso + zocalo actual
_gd_pidz:	.word 0

	.global _gd_pidCount		@; Contador global de PIDs
_gd_pidCount:	.word 0

	.global _gd_tickCount		@; Contador global de tics
_gd_tickCount:	.word 0

	.global _gd_sincMain		@; Sincronismos con programa principal
_gd_sincMain:	.word 0

	.global _gd_seed			@; Semilla para generacion de numeros aleatorios
_gd_seed:	.word 0xFFFFFFFF

	.global _gd_nReady			@; Numero de procesos en la cola de READY
_gd_nReady:	.word 0

	.global _gd_qReady			@; Cola de READY (procesos preparados)
_gd_qReady:	.space 16

	.global _gd_nDelay			@; Numero de procesos en la cola de DELAY
_gd_nDelay:	.word 0

	.global _gd_qDelay			@; Cola de DELAY (procesos retardados)
_gd_qDelay:	.space 16 * 4

	.global _gd_nBlock			@; Numero de procesos en la cola de BLOCK
_gd_nBlock: .word 0

	.global _gd_qBlock			@; Cola de BLOCK (procesos bloqueados)
_gd_qBlock: .word 0
			.word 0

	.global _gd_pcbs			@; Vector de PCBs de los procesos activos
_gd_pcbs:	.space 16 * 6 * 4

	.global _gd_wbfs			@; Vector de WBUFs de las ventanas disponibles
_gd_wbfs:	.space 16 * (4 + 64)

	.global _gd_stacks			@; Vector de pilas de los procesos de usuario
_gd_stacks:	.space 15 * 128 * 4

	.global _gd_mutex			@; Vector de semaforos de tipo mutex, inicialmente abiertos (1)
_gd_mutex:	.word 0x01010101
			.word 0x01010101

.end

