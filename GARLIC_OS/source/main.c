/*------------------------------------------------------------------------------

PROGRAMA PRINCIPAL GARLIC OS

------------------------------------------------------------------------------*/
#include <nds.h>
#include "garlic_system.h"	// definicion de funciones y variables de sistema

extern int * punixTime;		// puntero a zona de memoria con el tiempo real

unsigned char baldosa[64];


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

	int v;

	_gg_iniGrafA();		// inicializar procesador grafico A
	for (v = 0; v < 4; v++)	// para todas las ventanas
	{
		_gd_wbfs[v].pControl = 0;		// inicializar los buffers de ventana
	}

	if (!_gm_initFS())
	{
		_gg_escribir("ERROR: no se puede inicializar el sistema de ficheros!", 0, 0, 0);
		exit(0);
	}

	/* Crear baldosa Cara */
    for (int i = 0; i < 64; i++) {
        baldosa[i] = 0xFF; // Establecer todo a blanco
    }

    // Ojos (pintar de negro)
    baldosa[9] = 0x00;
    baldosa[10] = 0x00; 

    baldosa[13] = 0x00; 
    baldosa[14] = 0x00; 

    baldosa[17] = 0x00;
    baldosa[18] = 0x00; 

    baldosa[21] = 0x00; 
    baldosa[22] = 0x00; 

    baldosa[41] = 0x00; 
    baldosa[46] = 0x00;
    baldosa[50] = 0x00; 
    baldosa[51] = 0x00;
    baldosa[52] = 0x00; 
    baldosa[53] = 0x00;

	_gg_setChar(128, baldosa);
}


//------------------------------------------------------------------------------
int main(int argc, char **argv) {
//------------------------------------------------------------------------------
	intFunc pres;
	intFunc pi_1;
	intFunc mmll;
	intFunc open;

	inicializarSistema();

	_gg_escribir("********************************", 0, 0, 0);
	_gg_escribir("*                              *", 0, 0, 0);
	_gg_escribir("* Sistema Operativo GARLIC 1.0 *", 0, 0, 0);
	_gg_escribir("*                              *", 0, 0, 0);
	_gg_escribir("********************************", 0, 0, 0);
	_gg_escribir("Inicio Fase 1", 0, 0, 0);


	
	_gg_escribir("*** Carga de programa PRES.elf\n", 0, 0, 0);
	pres = _gm_cargarPrograma("PRES");
			
	_gg_escribir("\n*** Carga de programa PI_1.elf\n", 0, 0, 0);
	pi_1 = _gm_cargarPrograma("PI_1");
			
	_gg_escribir("\n*** Carga de programa MMLL.elf\n", 0, 0, 0);
	mmll = _gm_cargarPrograma("MMLL");

	_gg_escribir("\n*** Carga de programa OPEN.elf\n", 0, 0, 0);
	open = _gm_cargarPrograma("OPEN");

	_gg_escribir("Inicio de los procesos.\n", 0, 0, 0);
	
	_gp_crearProc(pres, 1, "PRES", 2);
	_gp_crearProc(pi_1, 2, "PI_1", 2);
	_gp_crearProc(mmll, 3, "MMLL", 2);

	
	_gg_escribir("El SO se bloqueara hasta que acabe el programa de usuario PRES.\n", 0, 0, 0);
	_gp_waitS(0);
	_gg_escribir("El SO se ha desbloqueado!\n", 0, 0, 0);


	_gp_crearProc(open, 15, "OPEN", 2);

	while(_gp_numProc() > 1){
		_gp_WaitForVBlank();
	}


	_gg_escribir("\x80\x80\x80 Final fase 1 \x80\x80\x80\n", 0, 0, 0);

	while (1)
	{
		_gp_WaitForVBlank();
	}							// parar el procesador en un bucle infinito
	return 0;
}
