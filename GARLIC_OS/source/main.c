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
	intFunc hola;
	intFunc prnt;
	intFunc open;
	intFunc mmll;

	inicializarSistema();

	printf("********************************");
	printf("*                              *");
	printf("* Sistema Operativo GARLIC 1.0 *");
	printf("*                              *");
	printf("********************************");
	
	
	printf("*** Carga de programa HOLA.elf\n");
	hola = _gm_cargarPrograma("HOLA");
			
	printf("\n*** Carga de programa PRNT.elf\n");
	prnt = _gm_cargarPrograma("PRNT");
			
	printf("\n*** Carga de programa OPEN.elf\n");
	open = _gm_cargarPrograma("OPEN");
			
	printf("\n*** Carga de programa MMLL.elf\n");
	mmll = _gm_cargarPrograma("MMLL");


	
	_gp_crearProc(hola, 7, "HOLA", 1);
	_gp_crearProc(prnt, 14, "PRNT", 1);
	_gp_crearProc(open, 3, "OPEN", 1);
	_gp_crearProc(mmll, 4, "MMLL", 1);

	

	while(_gp_numProc()>1){
		_gp_WaitForVBlank();
		printf("***Test Garlic_OS!!!\n");
	}
	

	printf("*** Final fase 1\n");

	while (1)
	{
		_gp_WaitForVBlank();
	}							// parar el procesador en un bucle infinito
	return 0;
}