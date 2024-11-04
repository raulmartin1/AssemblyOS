/*------------------------------------------------------------------------------

	"garlic_graf.c" : fase 1 / programador G

	Funciones de gestión del entorno gráfico (ventanas de texto), para GARLIC 1.0

------------------------------------------------------------------------------*/
#include <nds.h>

#include "garlic_system.h"	// definición de funciones y variables de sistema
#include "garlic_font.h"	// definición gráfica de caracteres

/* definiciones para realizar cálculos relativos a la posición de los caracteres
	dentro de las ventanas gráficas, que pueden ser 4 o 16 */
#define NVENT	4				// número de ventanas totales
#define PPART	2				// número de ventanas horizontales o verticales
								// (particiones de pantalla)
#define VCOLS	32				// columnas y filas de cualquier ventana
#define VFILS	24
#define PCOLS	VCOLS * PPART	// número de columnas totales (en pantalla)
#define PFILS	VFILS * PPART	// número de filas totales (en pantalla)

#define LOWER_16_BITS_MASK 0xFFFF // Mascara para obtener los 16 bits bajos de pControl
#define TEXT_LIMIT (VCOLS*3)		// Limite de texto para el metodo _gg_escribir

int bg2A, bg3A;
int MapPtr2A;

/* _gg_generarMarco: dibuja el marco de la ventana que se indica por parámetro*/
void _gg_generarMarco(int v)
{	
	int VIzq=96;
	int HAbajo=97;
	int VDer=98;
	int HArriba=99;
	int AbajoIzq=100;
	int AbajoDer=101;
	int ArribaDer=102;
	int ArribaIzq=103;
	
	//elegimos en que ventana empezar
	//baseY = (v / PPART) * VFILS
	//baseX = (v % PPART) * VCOLS
	//calcula el desplazamiento vertical en el mapa de caracteres del fondo 3
	//que se usa para posicionar el marco de la ventana, independientemente
	//de la ventana que usemos, se colocara el dibujo en la posicion correcta
	u16* mapPtr = bgGetMapPtr(bg3A) + (((v)/PPART)*VFILS*PCOLS);
	if(v%PPART!=0){	//si es impar (se realiza desplazamiento para las ventanas de la derecha)
		mapPtr+=(v%PPART)*VCOLS;
	}
	
	for (int fila=0; fila<VFILS; fila++) { 
		for (int col=0; col<VCOLS;  col++) {
			if (fila==0) {	//primera fila
				if(col==0) mapPtr[col+fila*PCOLS]=ArribaIzq; //esquina superior izquierda
				else {
					if(col==VCOLS-1) mapPtr[col+fila*PCOLS]=ArribaDer; //esquina superior derecha
					else mapPtr[col+fila*PCOLS]=HArriba; //linea superior horizontal
				}
			}
			else if(fila!=VFILS-1){	//Filas intermedias
				if(col==0) mapPtr[col+fila*PCOLS]=VIzq; //vertical izquierda
				else if(col==VCOLS-1) mapPtr[col+fila*PCOLS]=VDer; //vertical derecho
			}
			else { //Ultima fila (VFILS-1)
				if(col==0) mapPtr[col+fila*PCOLS]= AbajoIzq; //esquina inferior izquierda
				else {
					if(col==VCOLS-1) mapPtr[col+fila*PCOLS]=AbajoDer; //esquina inferior derecha
					else mapPtr[col+fila*PCOLS]=HAbajo; //linea inferior horizontal
				}
			}	
		}
	}
	
}


/* _gg_iniGraf: inicializa el procesador gráfico A para GARLIC 1.0 */
void _gg_iniGrafA()
{
	videoSetMode(MODE_5_2D); // inicializar el procesador gráfico principal (A) en modo 5, con salida en la pantalla superior de la NDS
	vramSetBankA(VRAM_A_MAIN_BG_0x06000000); // reservar el banco de memoria de vídeo A
	
	//inicializar los fondos gráficos 2 y 3 en modo Extended Rotation, con un tamaño total de 512x512 píxeles
	bg2A = bgInit(2, BgType_ExRotation , BgSize_ER_512x512, 0, 3);
	bg3A = bgInit(3, BgType_ExRotation , BgSize_ER_512x512, 4, 3);
	
	MapPtr2A = (int) bgGetMapPtr(bg2A);
	
	//fijar el fondo 3 como más prioritario que el fondo 2
	bgSetPriority(bg3A,0);
	bgSetPriority(bg2A,1);
	
	decompress(garlic_fontTiles, bgGetGfxPtr(bg3A) ,LZ77Vram); //descomprimir el contenido de la fuente de letras sobre una zona adecuada de la memoria de vídeo
	dmaCopy(garlic_fontPal, BG_PALETTE, sizeof(garlic_fontPal)); //copiar la paleta de colores de la fuente de letras sobre la zona de memoria correspondiente
	
	//generar los marcos de las ventanas de texto en el fondo 3
	for(int i=0; i<NVENT; i++) {
	_gg_generarMarco(i);
	}
	
	//escalar los fondos 2 y 3 para que se ajusten exactamente a las dimensiones de una pantalla de la NDS (reducción al 50%)
	bgSetScale(bg2A, 512, 512);
	bgSetScale(bg3A, 512, 512);
	
	//Actualizar
	bgUpdate();
}


/* _gg_procesarFormato: copia los caracteres del string de formato sobre el
					  string resultante, pero identifica las marcas de formato
					  precedidas por '%' e inserta la representación ASCII de
					  los valores indicados por parámetro.
	Parámetros:
		formato	->	string con marcas de formato (ver descripción _gg_escribir);
		val1, val2	->	valores a transcribir, sean número de código ASCII (%c),
					un número natural (%d, %x) o un puntero a string (%s);
		resultado	->	mensaje resultante.
	Observación:
		Se asume que el string resultante tiene reservado espacio de memoria
		suficiente para albergar todo el mensaje, incluyendo los caracteres
		literales del formato y la transcripción en código ASCII de los valores.
*/
void _gg_procesarFormato(char *formato, unsigned int val1, unsigned int val2,
																char *resultado)
{	
	int i=0; //index del resultat
	int j=0; //index dels strings
	int index = 0;	//index caracteres de formato
	int vTranscrits=0; //inicialment encara no s'ha transcrit ningun dels 2
	char ValToString[11]; // unsigned int max es 4.294.967.295, 10 numeros mas '\0' de final de cadena 
	
	while(formato[index] != '\0') {
		if(formato[index] == '%' && vTranscrits < 2){
		index++;	//avanzar al caracter on esta el tipus de format
		
		if (formato[index] == 'c' && vTranscrits < 2) { //si es un caracter
			if(vTranscrits ==0) {
				resultado[i] = (char) val1;
			}
			if(vTranscrits ==1) {
				resultado[i] = (char) val2;
			}
			i++;
			vTranscrits++;
			index++;
		}
		
		else if(formato[index] == 'd' && vTranscrits < 2) { //si es numero decimal
			size_t longitud = sizeof(ValToString);
			if(vTranscrits == 0) {
				_gs_num2str_dec(ValToString, longitud, val1); //valor numeric a string(String en digits numerics)
			}
			if(vTranscrits == 1) {
				_gs_num2str_dec(ValToString, longitud, val2);
			}
			
			j=0;
			while(ValToString[j] != '\0') {
				if(ValToString[j] !=' ') {
				resultado[i]=ValToString[j];
				i++;}
				j++;
				}
				vTranscrits++;
				index++;
		}
		
		else if(formato[index] == 'x' && vTranscrits < 2) { //si es numero hexadecimal
		size_t longitud = sizeof(ValToString);
			if(vTranscrits == 0) {
				_gs_num2str_hex(ValToString, longitud, val1); 
			}
			if(vTranscrits == 1) {
				_gs_num2str_hex(ValToString, longitud, val2);
			}
		
			j=0;
			while(ValToString[j] != '\0') {
				if(ValToString[j] != '0' ) { //saltar ceros al inicio del numero hexadecimal
					resultado[i]=ValToString[j];
					i++;
				}
				j++;
			}
			index++;
			vTranscrits++;
		}
		
		else if(formato[index] == '%' || vTranscrits == 2){ // si es un % literal
			resultado[i] = '%';
		
			if(vTranscrits == 2) {	//no quedan valors a transcriure
			i++;
			resultado[i] = formato[index];	//coloquem el caracter literal
			}
			i++;
			index++;
		}	
		
		if(formato[index] == 's' && vTranscrits < 2){ //si es un string i aun quedan valores por transcribir
			char* punteroString = (char*)NULL; //puntero a array de caracteres
			//fem un casting, de unsignned int a char*
			if(vTranscrits == 0){ //encara no s'ha transcrit ningun
				punteroString = (char *) val1; 
			}
			if(vTranscrits == 1){ //queda un valor per ser transcrit
				punteroString = (char*) val2;
			}
			j=0;
			while(punteroString[j] != '\0'){
				resultado[i]=punteroString[j];
				i++; j++;
			}
			index++;
			vTranscrits++;	//s'ha transcrit un valor
		}
		
	}else {
		resultado[i] = formato[index]; //coloquem el caracter literal
		i++;
		index++;
	}
}	//analizamos sigueinte caracter de la variable formato
	
	resultado[i] = '\0'; //final del string
}
/* _gg_escribir: escribe una cadena de caracteres en la ventana indicada;
	Parámetros:
		formato	->	string de formato:
					admite '\n' (salto de línea), '\t' (tabulador, 4 espacios)
					y códigos entre 32 y 159 (los 32 últimos son caracteres
					gráficos), además de marcas de format %c, %d, %h y %s (máx.
					2 marcas por string)
		val1	->	valor a sustituir en la primera marca de formato, si existe
		val2	->	valor a sustituir en la segunda marca de formato, si existe
					- los valores pueden ser un código ASCII (%c), un valor
					  natural de 32 bits (%d, %x) o un puntero a string (%s)
		ventana	->	número de ventana (0..3)
*/
void _gg_escribir(char *formato, unsigned int val1, unsigned int val2, int ventana)
{
	char resultado[TEXT_LIMIT]=""; //mensaje resultante,32 caracterees por linea, 3 lineas de texto (limitamos a 3 lineas  de texto)
	_gg_procesarFormato(formato, val1, val2, resultado);
	
	// 16 bits altos del pControl: número de línea (0..23)
	// 16 bits bajos del pControl: caracteres pendientes(0..32)
	//numero de caracteres de la ventana actual
	//obtenemos los 16 bits bajos de pControl
	int nChars = _gd_wbfs[ventana].pControl & LOWER_16_BITS_MASK; //AND->Si los dos bits son 1 los pone a 1
	int filaActual = _gd_wbfs[ventana].pControl >> 16; //Desplazamos 16 bits a la derecha, borrando asi los 16 menos significativos
	//Ahora los mas bajos serán los que antes eran los 16 altos, filaActual=16 bits mas altos de pControl
	int i=0; 
	
	char car = resultado[i];	//caracter actual
	while(car != '\0'){
		if(car == '\t'){
			int espaciosRestantes = 4 - (nChars % 4); //Calculo de espacios que faltan
			while(espaciosRestantes > 0 && nChars < VCOLS) {
				_gd_wbfs[ventana].pChars[nChars]=' '; //se añaden espacios hasta proxima columna con indice multiplo de 4
				nChars++;
				espaciosRestantes--;
		}
		
		}
		/*
		else if ( car != '\n' && nChars < VCOLS) { //No es tabulador, ni salto de linea y hay espacio -> añadir caracter al buffer de la ventana
			_gd_wbfs[ventana].pChars[nChars] = car; //se añade el caracter
			nChars++;
		}
		*/
		else if(car == '\n' || nChars == VCOLS) {
			/* _gp_WaitForVBlank: sustituto de swiWaitForVBlank() para Garlic; */
			//_gp_WaitForVBlank();
			swiWaitForVBlank();
			if(filaActual==VFILS) {
				_gg_desplazar(ventana); //desplaçament dels codi de rajola (scroll)
				filaActual--;
			}
			_gg_escribirLinea(ventana, filaActual, nChars); //transfereix del buffer al mapa de rajoles 
			filaActual++;	//siguiente fila
			nChars=0;		//preparamos el numero de caracteres a 0 para la nueva fila
		}
		else if(car == '\\' && resultado[i+1]=='x') {
			unsigned char simbol;
			char v1 = resultado[i+2];
			char v2 = resultado[i+3];
			char s1=0;
			char s2=0;
			if(v1>= 0 && v1 <= 57){	// 0=48(ASCII) 9=57(ASCII)
				s1 = v1 - 48; 
			}
			else if(v1 >= 65 && v1 <= 70) {	// A=65(ASCII) F=70(ASCII)
				s1= v1 - 55; //convertir a numero
			}
			
			if(v2>= 0 && v2 <= 57) {
				s2 = v2 - 48; // 48 = a 0 en ASCII
			}
			else if(v2 >= 65 && v2 <= 70) {
				s2 = v2 - 55;
			}
			
			simbol = (s1<<4); // mueve 4 posiciones a la izquierda
			simbol += s2;	//añade el segundo valor
			
			if (simbol >= 128 && simbol <=255) {
				_gd_wbfs[ventana].pChars[nChars]=simbol;
				nChars++;
			
			}
			i=i+3;
		}
		else if ( car != '\n' && nChars < VCOLS) { //No es tabulador, ni salto de linea y hay espacio -> añadir caracter al buffer de la ventana
			_gd_wbfs[ventana].pChars[nChars] = car; //se añade el caracter
			nChars++;
		}
		
		i++;
		car=resultado[i];
		
		}
		_gd_wbfs[ventana].pControl = (filaActual << 16); //coloquem el num de la fila actual als 16 primers bits(bits alts) de pControl
		_gd_wbfs[ventana].pControl += nChars; //coloca el numero de caracteres escrits en els 16 ultims bits(bits baixos	
		
}

	void _gg_setChar(unsigned char n, unsigned char *buffer) {
	if(n>=128 && n<=255){
		int base = 0x06000000; 				
		//16KB * 3 = 48 KB -> 48*1024= 49152-> 0xC000
		base=base+0xC000;				//base donde acaban los 127 caracteres predeterminados
		int desplazamiento = base+(n*64); //64 bytes que ocupa un baldosa completa 8x8
		dmaCopy(buffer, (u16*)desplazamiento, 64); //copiamos la baldosa en la posicion de la memoria
		bgUpdate();
	}
	}

