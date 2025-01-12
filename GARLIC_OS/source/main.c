/*------------------------------------------------------------------------------

	"main.c" : fase 2 / progP

	Version final de GARLIC 2.0
	(multiplexacion, retardar procesos, matar procesos)

------------------------------------------------------------------------------*/
#include <nds.h>
#include <stdlib.h>

#include "garlic_system.h"	// definicion de funciones y variables de sistema

extern int * punixTime;		// puntero a zona de memoria con el tiempo real

const short divFreq0 = -33513982/1024;		// frecuencia de TIMER0 = 1 Hz


/* funcion para escribir los porcentajes de uso de la CPU de los procesos de los
		cuatro primeros zocalos, en el caso que la RSI del TIMER0 haya realizado
		el calculo */
void porcentajeUso()
{
	if (_gd_sincMain & 1)			// verificar sincronismo de timer0
	{
		_gd_sincMain &= 0xFFFE;			// poner bit de sincronismo a cero
		_gg_escribir("***\t%d%%  %d%%", _gd_pcbs[0].workTicks >> 24,
										_gd_pcbs[1].workTicks >> 24, 0);
		_gg_escribir("  %d%%  %d%%\n", _gd_pcbs[2].workTicks >> 24,
										_gd_pcbs[3].workTicks >> 24, 0);
	}
}


/* Inicializaciones generales del sistema Garlic */
//------------------------------------------------------------------------------
void inicializarSistema() {
//------------------------------------------------------------------------------
	_gg_iniGrafA();			// inicializar procesadores graficos
	_gs_iniGrafB();
	_gs_dibujarTabla();

	_gd_seed = *punixTime;	// inicializar semilla para numeros aleatorios con
	_gd_seed <<= 16;		// el valor de tiempo real UNIX, desplazado 16 bits
	
	_gd_pcbs[0].keyName = 0x4C524147;		// "GARL"
	
	if (!_gm_initFS()) {
		_gg_escribir("ERROR: no se puede inicializar el sistema de ficheros!", 0, 0, 0);
		exit(0);
	}

	irqInitHandler(_gp_IntrMain);	// instalar rutina principal interrupciones
	irqSet(IRQ_VBLANK, _gp_rsiVBL);	// instalar RSI de vertical Blank
	irqEnable(IRQ_VBLANK);			// activar interrupciones de vertical Blank

	irqSet(IRQ_TIMER0, _gp_rsiTIMER0);
	irqEnable(IRQ_TIMER0);				// instalar la RSI para el TIMER0
	TIMER0_DATA = divFreq0; 
	TIMER0_CR = 0xC3;  	// Timer Start | IRQ Enabled | Prescaler 3 (F/1024)
	
	REG_IME = IME_ENABLE;			// activar las interrupciones en general
}


//------------------------------------------------------------------------------
int main(int argc, char **argv) {
//------------------------------------------------------------------------------
	intFunc start;

	inicializarSistema();
	
	_gg_escribir("********************************", 0, 0, 0);
	_gg_escribir("*                              *", 0, 0, 0);
	_gg_escribir("* Sistema Operativo GARLIC 2.0 *", 0, 0, 0);
	_gg_escribir("*                              *", 0, 0, 0);
	_gg_escribir("********************************", 0, 0, 0);
	_gg_escribir("*** Inicio fase 2_P\n", 0, 0, 0);
	

	_gg_escribir("*** Carga de programa HOLA.elf\n", 0, 0, 0);
	start = _gm_cargarPrograma("HOLA");
	if (start)
	{	
		// cargar tres procesos HOLA para probar funciones waitS y signalS
		_gp_crearProc(start, 1, "HOLA", 1);
		_gp_crearProc(start, 2, "HOLA", 2);
		_gp_crearProc(start, 3, "HOLA", 3);

		// esperar 1 segundo para dar tiempo que se inicien los procesos
		while (_gd_tickCount < 60)			// esperar 1 segundo
		{
			_gp_WaitForVBlank();
			porcentajeUso();
		}

		// mostrar cuantos procesos estan en RDY/DLY y cuantos en BLK
		// antes de bloquearse en los semaforos
		_gg_escribir("**Antes de bloquear procesos**\n", 0, 0, 0);
		_gg_escribir("Proc cola RDY - BLK: %d - %d\n", _gd_nReady + _gd_nDelay, _gd_nBlock, 0);
		
		// esperar 4 segundos para dejar tiempo que se bloqueen los procesos
		while (_gd_tickCount < 300)			// esperar 4 segundos
		{
			_gp_WaitForVBlank();
			porcentajeUso();
		}
		
		// mostrar cuantos procesos estan en RDY/DLY y cuantos en BLK
		// despues de bloquearse en los semaforos
		_gg_escribir("**Despues de bloquear procesos**\n", 0, 0, 0);
		_gg_escribir("Proc cola RDY - BLK: %d - %d\n", _gd_nReady + _gd_nDelay, _gd_nBlock, 0);

		// esperar 5 segundos mas para que se vayan ejecutando
		while (_gd_tickCount < 600)			// esperar 5 segundos
		{
			_gp_WaitForVBlank();
			porcentajeUso();
		}

		// hacer signalS a los tres semaforos
		int temp1 = _gp_signalS(1);
		int temp2 = _gp_signalS(2);
		int temp3 = _gp_signalS(3);

		// mostrar cuantos procesos estan en RDY/DLY y cuantos en BLK
		// despues de desbloquearse de los semaforos
		_gg_escribir("**Despues de desbloquear procesos**\n", 0, 0, 0);
		_gg_escribir("Proc cola RDY - BLK: %d - %d\n", _gd_nReady + _gd_nDelay, _gd_nBlock, 0);

		// mostrar tambien el valor de retorno de los tres signalS
		_gg_escribir("Retorno signalS(1): %d\n", temp1, 0, 0);
		_gg_escribir("Retorno signalS(2): %d\n", temp2, 0, 0);
		_gg_escribir("Retorno signalS(3): %d\n", temp3, 0, 0);

		// matar proceso en zocalo 1 para probar rutina _gp_matarProc
		_gp_matarProc(2);
		_gg_escribir("Proceso 2 eliminado!\n", 0, 0, 0);

		// esperar que acaben todos los procesos
		while(_gp_numProc() > 1){
			_gp_WaitForVBlank();
			porcentajeUso();
		}
	}
	else{
		_gg_escribir("Programa NO cargado!\n", 0, 0, 0);
	}



	int targetTicks = _gd_tickCount+960;

	start = _gm_cargarPrograma("PONG");
	if(start){

		// crear tres procesos PONG para probar rutinas GARLIC_delay
		_gp_crearProc(start, 1, "PONG", 1);
		_gp_crearProc(start, 2, "PONG", 2);
		_gp_crearProc(start, 3, "PONG", 3);

		// dejar que se ejecuten los procesos durante 16 segundos
		while(_gd_tickCount < targetTicks){
			_gp_WaitForVBlank();
			porcentajeUso();
		}

		// matar los tres procesos a la vez
		_gp_matarProc(1);
		_gp_matarProc(2);
		_gp_matarProc(3);
		_gg_escribir("Procesos 1-3 eliminados!\n", 0, 0, 0);

	}
	else{
		_gg_escribir("Programa NO cargado!\n", 0, 0, 0);
	}

	_gg_escribir("*** Final fase 2_P\n", 0, 0, 0);

	while(1) {
		_gp_WaitForVBlank();
	}							// parar el procesador en un bucle infinito
	return 0;
}
