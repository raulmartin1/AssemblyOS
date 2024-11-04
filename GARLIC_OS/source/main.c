/*------------------------------------------------------------------------------

PROGRAMA PRINCIPAL GARLIC OS

------------------------------------------------------------------------------*/
#include <nds.h>
#include <stdio.h>

#include "garlic_system.h"	// definicion de funciones y variables de sistema


extern int * punixTime;		// puntero a zona de memoria con el tiempo real


/* Inicializaciones generales del sistema Garlic */
//------------------------------------------------------------------------------
void inicializarSistema() {
//------------------------------------------------------------------------------

	consoleDemoInit();		// inicializar consola, solo para esta simulacion
	
	_gd_seed = *punixTime;	// inicializar semilla para numeros aleatorios con
	_gd_seed <<= 16;		// el valor de tiempo real UNIX, desplazado 16 bits
	
	irqInitHandler(_gp_IntrMain);	// instalar rutina principal interrupciones
	irqSet(IRQ_VBLANK, _gp_rsiVBL);	// instalar RSI de vertical Blank
	irqEnable(IRQ_VBLANK);			// activar interrupciones de vertical Blank
	REG_IME = IME_ENABLE;			// activar las interrupciones en general
	
	_gd_pcbs[0].keyName = 0x4C524147;	// "GARL"

	if (!_gm_initFS())
	{
		printf("ERROR: �no se puede inicializar el sistema de ficheros!");
		exit(0);
	}
}


//------------------------------------------------------------------------------
int main(int argc, char **argv) {
//------------------------------------------------------------------------------
	intFunc start;
	inicializarSistema();

	printf("********************************");
	printf("*                              *");
	printf("* Sistema Operativo GARLIC 1.0 *");
	printf("*                              *");
	printf("********************************");
	
	
	printf("*** Carga de programa HOLA.elf\n");
	start = _gm_cargarPrograma("hola");
	if (start)
	{
		printf("*** Direccion de arranque :\n\t\t%p\n", start);
		printf("*** Pulse tecla \'START\' ::\n\n");
		do
		{	swiWaitForVBlank();
			scanKeys();
		} while ((keysDown() & KEY_START) == 0);
		
		start(1);		// llamada al proceso HOLA con argumento 1
	}
	else
		printf("*** Programa \"HOLA\" NO cargado\n");

	printf("\n\n\n*** Carga de programa PRNT.elf\n");
	start = _gm_cargarPrograma("prnt");
	if (start)
	{
		printf("*** Direccion de arranque :\n\t\t%p\n", start);
		printf("*** Pulse tecla \'START\' ::\n\n");
		do
		{	swiWaitForVBlank();
			scanKeys();
		} while ((keysDown() & KEY_START) == 0);
		
		start(1);		// llamada al proceso PRNT con argumento 1
	}
	else
		printf("*** Programa \"PRNT\" NO cargado\n");
		
	printf("\n\n\n*** Carga de programa OPEN.elf\n");
	start = _gm_cargarPrograma("open");
	if (start)
	{
		printf("*** Direccion de arranque :\n\t\t%p\n", start);
		printf("*** Pulse tecla \'START\' ::\n\n");
		do
		{	swiWaitForVBlank();
			scanKeys();
		} while ((keysDown() & KEY_START) == 0);
		
		start(0);		// llamada al proceso OPEN con argumento 1
	}
	else
		printf("*** Programa \"OPEN\" NO cargado\n");
		
	printf("\n\n\n*** Carga de programa MMLL.elf\n");
	start = _gm_cargarPrograma("mmll");
	if (start)
	{
		printf("*** Direccion de arranque :\n\t\t%p\n", start);
		printf("*** Pulse tecla \'START\' ::\n\n");
		do
		{	swiWaitForVBlank();
			scanKeys();
		} while ((keysDown() & KEY_START) == 0);
		
		start(1);		// llamada al proceso MMLL con argumento 1
	}
	else
		printf("*** Programa \"MMLL\" NO cargado\n");

	printf("*** Final fase 1_M\n");

	while (1)
	{
		swiWaitForVBlank();
	}							// parar el procesador en un bucle infinito
	return 0;
}
