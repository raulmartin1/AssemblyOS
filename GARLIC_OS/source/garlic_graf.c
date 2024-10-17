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

#define LOWER_16_BITS_MASK 0xFFFF //Mascara para obtener los 16 bits bajos de pControl

int bg2A, bg3A;

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
	int baseX = (v % PPART) * VCOLS;
	int baseY = (v / PPART) * VFILS;
	//calcula el desplazamiento vertical en el mapa de caracteres del fondo 3
	//que se usa para posicionar el marco de la ventana, independientemente
	//de la ventana que usemos, se colocara el dibujo en la posicion correcta
	u16* mapPtr = bgGetMapPtr(bg3A) + (baseY*VCOLS);
	
	//Marco de Arriba
	int posicion = baseY * PCOLS;	//posicion ventana
	for (int col = 1; col < VCOLS; col++) {
	mapPtr[posicion + baseX + col]=HArriba;
	}
	
	//Marco de Abajo
	posicion= (baseY + VFILS-1)* PCOLS;
	for (int col = 1; col < VCOLS; col++){
	mapPtr[posicion + baseX + col]=HAbajo;
	}
	
	//Marco Izquierda y Derecha
	for(int fila = 0; fila < VFILS; fila++){
		if(fila ==0) { //primera fila
			posicion = baseY * PCOLS;
			mapPtr[posicion + baseX]=ArribaIzq;
			mapPtr[posicion + (baseX + VCOLS - 1)]= ArribaDer;
		} else if (fila == VFILS -1) { //filas antes de la ultima
			posicion= (baseY + VFILS - 1) * PCOLS;
			mapPtr[posicion + baseX]= VIzq;
			mapPtr[posicion + (baseX + VCOLS - 1)] = VDer;
		} else {	//ultima fila
			posicion= (baseY + fila) * PCOLS;
			mapPtr[posicion + baseX]=AbajoIzq;
			mapPtr[posicion + (baseX + VCOLS - 1)] = AbajoDer;
		}
	}
 
}


/* _gg_iniGraf: inicializa el procesador gráfico A para GARLIC 1.0 */
void _gg_iniGrafA()
{
	videoSetMode(MODE_5_2D);
	vramSetBankA(VRAM_A_MAIN_BG_0x06000000);
	
	//Calcular ultimos dos valores del bgInit
	bg2A = bgInit(2, BgType_ExRotation , BgSize_ER_512x512, 0, 0);
	bg3A = bgInit(3, BgType_ExRotation , BgSize_ER_512x512, 0, 0);
	
	bgSetPriority(bg3A,0);
	bgSetPriority(bg2A,1);
	
	decompress(garlic_fontTiles, bgGetGfxPtr(bg3A) ,LZ77Vram);
	dmaCopy(garlic_fontPal, BG_PALETTE, sizeof(garlic_fontPal));
	
	for(int i=0; i<NVENT; i++) {
	_gg_generarMarco(i);
	}
	
	bgSetScale(2, 0.5, 0.5);
	bgSetScale(3, 0.5, 0.5);
	//bgSetScale(2, 128, 128);
	//bgSetScale(3, 128, 128);
	
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
	int index = 0;	//index aracteres de formato
	int vTranscrits=2; //inicialment encara no s'ha transcrit ningun dels 2
	char ValToString[11]; // unsigned int max es 4.294.967.295, 10 numeros mas '\0' de final de cadena 
	for (index = 0; formato[index] != '\0'; index++) {
		if(formato[index] == '%'){
		index++;	//avanzar al caracter on esta el tipus de format
		
		if (formato[index] == 'c' && vTranscrits > 0) { //si es un caracter
			if(vTranscrits ==2) {
				resultado[i] = (char) val1;
			}
			if(vTranscrits ==1) {
				resultado[i] = (char) val2;
			}
			i++;
			vTranscrits--;
		}
		
		if(formato[index] == 'd' && vTranscrits > 0) { //si es numero decimal
			size_t longitud = sizeof(ValToString);
			if(vTranscrits == 2) {
				_gs_num2str_dec(ValToString, longitud, val1);
			}
			if(vTranscrits == 1) {
				_gs_num2str_dec(ValToString, longitud, val2);
			}
		
			j=0;
			while(ValToString[j] != '\0') {
				resultado[i]=ValToString[j];
				i++; j++;
				}
				vTranscrits--;
		}
		
		if(formato[index] == 'x' && vTranscrits > 0) { //si es numero hexadecimal
		size_t longitud = sizeof(ValToString);
			if(vTranscrits == 2) {
				_gs_num2str_hex(ValToString, longitud, val1);
			}
			if(vTranscrits == 1) {
				_gs_num2str_hex(ValToString, longitud, val2);
			}
		
			j=0;
			while(ValToString[j] != '\0') {
				if(ValToString[j] != '0' ) { //saltar ceros al inicio del numero hexadecimal
					resultado[i]=ValToString[j];
				}
				i++; j++;
			}
			vTranscrits--;	
		}
		
		if(formato[index] == 's' && vTranscrits>0){ //si es un string i aun quedan valores por transcribir
		char *punteroString = NULL; 
			if(vTranscrits == 2){ //encara no s'ha transcrit ningun
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
			vTranscrits--;	//s'ha transcrit un valor
		}
		
		if(formato[index] == '%'){ // si es un % literal
			resultado[i]='%';
			i++;
		}
		if(vTranscrits == 0) {	//no quedan valors a transcriure
			resultado[i] = formato[index];	//coloquem el caracter literal
			i++;
		}
	
	}else {
		resultado[i] = formato[index]; //coloquem el caracter literal
		i++;
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
	int nChars, filaActual;
	char resultado[VCOLS*3]=""; //mensaje resultante,32 caracterees por linea, 3 lineas de texto (limitamos a 3 lineas  de texto)
	_gg_procesarFormato(formato, val1, val2, resultado);
	
	// 16 bits altos del pControl: número de línea (0..23)
	// 16 bits bajos del pControl: caracteres pendientes(0..32)
	//numero de caracteres de la ventana actual
	//obtenemos los 16 bits bajos de pControl
	nChars = _gd_wbfs[ventana].pControl & LOWER_16_BITS_MASK; //AND->Si los dos bits son 1 los pone a 1
	filaActual = _gd_wbfs[ventana].pControl >> 16; //Desplazamos 16 bits a la derecha, borrando asi los 16 menos significativos
	//Ahora los mas bajos serán los que antes eran los 16 altos, filaActual=16 bits mas altos de pControl

	char car;	//caracter actual
	for(int i =0; resultado[i] != '\0'; i++){
		car=resultado[i];

		if(car == '\t'){
		while(nChars < VCOLS && nChars % 4 != 0) {
		_gd_wbfs[ventana].pChars[nChars]=' '; //se añaden espacios hasta proxima columna con indice multiplo de 4
		nChars++;
		}
		}else if ( car != '\n' && nChars < VCOLS) { //No es tabulador, ni salto de linea y hay espacio -> añadir caracter al buffer de la ventana
		_gd_wbfs[ventana].pChars[nChars] = car; //se añade el caracter
		nChars++;
		}
		
		if(car == '\n' || nChars == VCOLS) {
		/* _gp_WaitForVBlank: sustituto de swiWaitForVBlank() para Garlic; */
		_gp_WaitForVBlank();
		if(filaActual==VFILS) {
		_gg_desplazar(ventana);
		filaActual--;
		}
		_gg_escribirLinea(ventana, filaActual, nChars);
		filaActual++;	//siguiente fila
		nChars=0;		//preparamos el numero de caracteres a 0 para la nueva fila
		}
		_gd_wbfs[ventana].pControl = (filaActual << 16); //coloquem el num de la fila actual als 16 primers bits(bits alts) de pControl
		_gd_wbfs[ventana].pControl += nChars; //coloca el numero de caracteres escrits en els 16 ultims bits(bits baixos)
		
}
}