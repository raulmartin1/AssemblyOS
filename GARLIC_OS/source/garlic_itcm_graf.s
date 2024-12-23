@;==============================================================================
@;
@;	"garlic_itcm_graf.s":	código de rutinas de soporte a la gestión de
@;							ventanas gráficas (versión 2.0)
@;
@;==============================================================================

NVENT	= 16				@; número de ventanas totales
PPART	= 4					@; número de ventanas horizontales
							@; (particiones de pantalla)
L2_PPART = 2				@; log base 2 de PPART

VCOLS	= 32				@; columnas y filas de cualquier ventana
VFILS	= 24
PCOLS	= VCOLS * PPART		@; número de columnas totales (en pantalla)
PFILS	= VFILS * PPART		@; número de filas totales (en pantalla)

WBUFS_LEN = 68				@; longitud de cada buffer de ventana (64+4)


.section .itcm,"ax",%progbits

	.arm
	.align 2


	.global _gg_escribirLinea
	@; Rutina para escribir toda una l�nea de caracteres almacenada en el
	@; buffer de la ventana especificada;
	@;Par�metros:
	@;	R0: ventana a actualizar (int v)
	@;	R1: fila actual (int f)
	@;	R2: n�mero de caracteres a escribir (int n)
_gg_escribirLinea:
	push {r3- r12, lr}
		@; Calculo de la posicion inicial de columna de la ventana
		mov r5, #PPART
		sub r5, #1				@; mascara 3(0011)extrae los 2 ultimos bits
		and r3, r0, r5			@; r3 = v % PPART -> ventana % 4
		mov r4, #VCOLS
		mul r5, r3, r4			@; r5 = (v%PPART) * VCOLS
		mov r3, r5				@; r3 = (v%PPART) * VCOLS
		@; Calculo de la posicion inicial de fila de la ventana
		lsr r4, r0, #L2_PPART	@; r4 = v / L2_PPART
		mov r5, #VFILS
		mul r6, r4, r5			@; r6 = (v/PPART) * VFILS
		mov r4, r6				@; r4 = (v/PPART) * VFILS
		
		@; Calculo desplazamiento total mapPtr = ((v/PPART) * VFILS) * PCOLS + ((v%PPART) * VCOLS) + (f * VCOLS)
		mov r6 ,#PCOLS 
		mul r8, r4, r6			@; r8 = ((v/PPART) * VFILS) * PCOLS
		add r7, r8, r3			@; r7 = (((v/PPART) * VFILS) * PCOLS) + ((v%PPART) * VCOLS)
		
		mul r8, r1, r6			@; r8 = f * PCOLS
		add r5, r8, r7			@; r5 = (f * PCOLS) + (((v/PPART) * VFILS) * PCOLS) + ((v%PPART) * VCOLS)	
		
		@;r5= desplazamiento posicio actual donde escribir
		@; adaptamos el desplazamiento a bytes (cada baldosa ocupa 2bytes en memoria) 
		lsl r5, r5, #1			@; desplazamos el valor de r5 una pos a la izquierda(multiplicar por 2)
		@; Cargamos inicio mapa bg2A
		ldr r6,=MapPtr2A
		ldr r6, [r6]			@; cargamos la direccion base de MapPtr2A

		add r6, r6, r5			@; direccion base mapa + desplazamiento = direccion donde se escribe
		
		@; vector de ventanas
		mov r8, #WBUFS_LEN		@; tama�o ventana en memoria (en bytes)
		ldr r4, =_gd_wbfs		@; cargamos direccion de inicio del vector de ventanas
		mul r9, r0, r8			@; v * WBUFS_LEN = desplazamiento inicio de la ventana en _gd_wbfs 
		add r4, r4, r9			@; desplazamiento para la posicion de la ventana en el vector
		add r4, r4, #4			@; saltamos 4 bytes = 16bits (de pControl) y ubicarnos en pChars
		
		mov r10, #0				@; nChars=0
		.LescribirChar:
			ldrh r9, [r4, r10]	@; r9=_gd_wbfs[ventana].pChars[nChars] ahora son los 16 bits bajos (halfwords)
			cmp r9 , #128		@; Comprobar si es un caracter personalizado (no hace falta ajustar el valor)
			bhs .LsetChar
			sub r9, r9, #32		@; valor ASCII -> codigo baldosa, las baldosas empiezan en 0 y los ASCII en 32 al 127
			strh r9, [r6]		@; baldosa ocupa 2bytes->halfword, guardamos el codigo en el mapa de fondo
			b .LsaltarSetChar
			
			.LsetChar:
			strh r9, [r6]		@; baldosa personalizada
			
			.LsaltarSetChar:
			add r6, r6, #2		@; avanzamos siguiente posicion del mapa (2 bytes pro baldosa)
			add r10, r10, #1	@; nChars++
			cmp r10, r2 		@; mientras nChars < num total de caracteres a escribir
		blo .LescribirChar
	pop {r3-r12, pc}


	.global _gg_desplazar
	@; Rutina para desplazar una posici�n hacia arriba todas las filas de la
	@; ventana (v) y borrar el contenido de la �ltima fila;
	@;Par�metros:
	@;	R0: ventana a desplazar (int v)
_gg_desplazar:
	push {r1-r12, lr}
		@; Calculo de la posicion inicial de columna de la ventana
		mov r5, #PPART
		sub r5, #1
		and r3, r0, r5			@; r3 = v % PPART -> ventana % 4
		mov r4, #VCOLS
		mul r5, r3, r4			@; r5 = (v%PPART) * VCOLS
		mov r3, r5				@; r3 = (v%PPART) * VCOLS
		@; Calculo de la posicion inicial de fila de la ventana
		lsr r4, r0, #L2_PPART	@; r4 = v / L2_PPART
		mov r5, #VFILS
		mul r6, r4, r5			@; r6 = (v/PPART) * VFILS
		mov r4, r6				@; r4 = (v/PPART) * VFILS
		
		@; Calculo desplazamiento total mapPtr = ((v/PPART) * VFILS) * PCOLS + ((v%PPART) * VCOLS) + (f * VCOLS)
		mov r6 ,#PCOLS 
		mul r8, r4, r6			@; r8 = ((v/PPART) * VFILS) * PCOLS
		add r7, r8, r3			@; r7 = (((v/PPART) * VFILS) * PCOLS) + ((v%PPART) * VCOLS)
		mov r5, r7
		@; r5= desplazamiento total
		@; adaptamos el desplazamiento a bytes (cada baldosa ocupa 2bytes en memoria) 
		lsl r5, r5, #1			@; desplazamos el valor de r5 una pos a la izquierda(multiplicar por 2)
		@; Cargamos inicio mapa bg2A
		ldr r6,=MapPtr2A
		ldr r6, [r6]			@; cargamos la direccion base de bg2A

		add r6, r6, r5			@; direccion base mapa + desplazamiento
		mov r7, r6
		mov r8, #PCOLS
		lsl r8, r8, #1			@; r8 = despl. para sumar fila
		add r7, r8				@; encontramos posicion de la siguiente
		
		mov r2, r6				@; r2 = posicion de escritura actual
		mov r3, r7				@; r3 = sera la siguiente posicion
		
		mov r9, #0				@; r9 = filas a desplazar
		.LdesplazarFilas:		@; desplazar filas hacia arriba	
			mov r6, #0			@; r6 = columnas a recorrer (contador)
			mov r5, #0			@; col = 0 (posicio)
		.LcopiarFilas:			@; copiar valores de cada fila 
			ldrh r7, [r3, r5] 	@; valor de la fila siguiente en la col=r5
			strh r7, [r2, r5] 	@; subimos de posicion la fila siguiente a la actual 
			add r5, r5, #2		@; col++, avanzamos 2bytes de cada baldosa 
			add r6, r6, #1		@; contador de columaas++ hasta que sea igual a #VCOLS
		cmp r6, #VCOLS
		blo .LcopiarFilas		@; si columnas recorridas<=VCOLS saltar a .LcopiarFilas
			add r2, r8			@; se suma una fila
			add r3, r8
			
			add r9, r9, #1		@; sumamos una fila
		cmp r9, #VFILS-1
		ble  .LdesplazarFilas	@; si filas tratadas<=VFILS-1 salta a .LdesplazarFilas
			@; cuando se han acabado las filas
			sub r2, r8				@; se resta una fila
			sub r3, r8
			mov r3, #0				@; r3=ponemos espacios en la ultima fila
			mov r6, #0				@; contador de columnas recorridas
			mov r5, #0				@; col = 0 (posicio)		
			.Lespacios:				@; ponemos espacios vacios hasta que se acaben las columnas
				strh r3, [r2, r5]	@; guardamos los espacios en la ultima fila
				add r5, r5, #2
				add r6, r6, #1
				cmp r6, #VCOLS
			blo .Lespacios		@; mientras no se acabe la fila seguir poniendo espacios
			
	pop {r1-r12, pc}

	.global _gg_escribirLineaTabla
	@; escribe los campos básicos de una linea de la tabla correspondiente al
	@; zócalo indicado por parámetro con el color especificado; los campos
	@; son: número de zócalo, PID, keyName y dirección inicial
	@;Parámetros:
	@;	R0 (z)		->	número de zócalo
	@;	R1 (color)	->	número de color (0..3)
_gg_escribirLineaTabla:
	push {lr}


	pop {pc}



	.global _gg_escribirCar
	@; escribe un carácter (baldosa) en la posición de la ventana indicada,
	@; con un color concreto;
	@;Parámetros:
	@;	R0 (vx)		->	coordenada x de ventana (0..31)
	@;	R1 (vy)		->	coordenada y de ventana (0..23)
	@;	R2 (car)	->	código del carácter, como número de baldosa (0..127)
	@;	R3 (color)	->	número de color del texto (0..3)
	@; pila (vent)	->	número de ventana (0..15)
_gg_escribirCar:
	push {r4-r9, lr}
		ldr r4, [sp, #24]	@; Accedemos al valor 24 bytes a partir de la pila sp ( 5 regs * 4 bytes + 4 bytes de este quinto registro) = 24 bytes
		@; Calculo de la posicion inicial de columna de la ventana
		mov r5, #PPART
		sub r5, #1
		and r6, r4, r5			@; r6 = v % PPART-1 -> ventana % 4
		mov r9, #VCOLS
		mul r5, r6, r9			@; r5 = (v%PPART) * VCOLS
		mov r7, r5				@; r7 = (v%PPART) * VCOLS
		@; Calculo de la posicion inicial de fila de la ventana
		lsr r6, r0, #L2_PPART	@; r6 = v / PPART
		mov r9, #VFILS
		mul r8, r6, r9			@; r8 = (v/PPART) * VFILS
		
		@; Calculo desplazamiento total mapPtr = ((v/PPART) * VFILS) * PCOLS + ((v%PPART) * VCOLS) + (f * VCOLS)
		mov r6 ,#PCOLS 
		mul r9, r8, r6			@; r9 = ((v/PPART) * VFILS) * PCOLS
		add r9, r7				@; r9 = (((v/PPART) * VFILS) * PCOLS) + ((v%PPART) * VCOLS)
		
		@; Deplazamiento de coordenada
		mul r5, r4, r1			@; r5 = PCOLS * vy
		add r5, r9				@; r5 = (PCOLS* vy) + desplazamiento a la ventana
		add r5, r0				@; r5 = ((PCOLS*vy) + desplazamiento vent) + vx
		
		@; r5= desplazamiento total (coordenadas)
		@; adaptamos el desplazamiento a bytes (cada baldosa ocupa 2bytes en memoria) 
		lsl r5, r5, #1			@; desplazamos el valor de r5 una pos a la izquierda(multiplicar por 2)
		
		ldr r6, =MapPtr2A
		ldr r6, [r6]
		add r6, r6, r5
		
		@; 2^7=128 baldosas por cada paleta de colores
		mov r5, r3, lsl #7		@; r5 = color * 128
		add r5, r2				@; r5 = caracter + color*128
		strh r5, [r6]
		
	pop {r4-r9, pc}



	.global _gg_escribirMat
	@; escribe una matriz de 8x8 carácteres a partir de una posición de la
	@; ventana indicada, con un color concreto;
	@;Parámetros:
	@;	R0 (vx)		->	coordenada x inicial de ventana (0..31)
	@;	R1 (vy)		->	coordenada y inicial de ventana (0..23)
	@;	R2 (m)		->	puntero a matriz 8x8 de códigos ASCII (dirección)
	@;	R3 (color)	->	número de color del texto (0..3)
	@; pila	(vent)	->	número de ventana (0..15)
_gg_escribirMat:
	push {r0-r9, lr}
		ldr r4, [sp, #24]	@; Accedemos al valor 24 bytes a partir de la pila sp ( 5 regs * 4 bytes + 4 bytes de este quinto registro) = 24 bytes
		@; Calculo de la posicion inicial de columna de la ventana
		mov r5, #PPART
		sub r5, #1
		and r6, r4, r5			@; r6 = v % PPART-1 -> ventana % 4
		mov r9, #VCOLS
		mul r5, r6, r9			@; r5 = (v%PPART) * VCOLS
		mov r7, r5				@; r7 = (v%PPART) * VCOLS
		@; Calculo de la posicion inicial de fila de la ventana
		lsr r6, r0, #L2_PPART	@; r6 = v / PPART
		mov r9, #VFILS
		mul r8, r6, r9			@; r8 = (v/PPART) * VFILS
		
		@; Calculo desplazamiento total mapPtr = ((v/PPART) * VFILS) * PCOLS + ((v%PPART) * VCOLS) + (f * VCOLS)
		mov r6 ,#PCOLS 
		mul r9, r8, r6			@; r9 = ((v/PPART) * VFILS) * PCOLS
		add r9, r7				@; r9 = (((v/PPART) * VFILS) * PCOLS) + ((v%PPART) * VCOLS)
		
		@; Deplazamiento de coordenada
		mul r5, r4, r1			@; r5 = PCOLS * vy
		add r5, r9				@; r5 = (PCOLS* vy) + desplazamiento a la ventana
		add r5, r0				@; r5 = ((PCOLS*vy) + desplazamiento vent) + vx
		
		@; r5= desplazamiento total (coordenadas)
		@; adaptamos el desplazamiento a bytes (cada baldosa ocupa 2bytes en memoria) 
		lsl r5, r5, #1			@; desplazamos el valor de r5 una pos a la izquierda(multiplicar por 2)
		
		ldr r6, =MapPtr2A
		ldr r6, [r6]
		add r6, r6, r5
		
		lsl r3, r3, #7		@; color = color*128
		mov r0, #0			@; i=0, para avanzar en la matriz
		mov r1, #0			@; fila=0
		mov r8, #PCOLS		@; valor para avanzar a la siguiente fila
		lsl r8, #1			@; se multiplica por 2 ya que son 2 bytes
		.LrecorrerFilas:
			cmp r1, #8
			beq .LfinalMatriz 
			mov r5, #0		@; columna = 0 (para escribir)
			.LrecorrerColumnas:
				cmp r5, #16			@;  comprovar si llega al final de la fila
				beq .LsaltarFila
				ldrb r7, [r2, r0]		@; 	r7 = matriu[i]
				cmp r7, #0				@; si null
				beq .LseguentPos
				
				sub r7, #32				@; ajustar codigo ASCII
				add r7, r3				@; ajustar color al caracter
				strh r7, [r6, r5]		@; escribir en la posicion
				
			.LseguentPos:
				add r0, #1				@; seguent pos matriz
				add r5, #2				@; seguent pos col(2 bytes per accedir al mapa)
				b .LrecorrerColumnas	@; seguent col
		.LsaltarFila:
			add r4,r8			@; seguent fila
			add r1, #1			@; fila++
			b .LrecorrerFilas
		.LfinalMatriz:
		
	pop {r0-r9, pc}



	.global _gg_rsiTIMER2
	@; Rutina de Servicio de Interrupción (RSI) para actualizar la representa-
	@; ción del PC actual.
_gg_rsiTIMER2:
	push {lr}


	pop {pc}


.end

