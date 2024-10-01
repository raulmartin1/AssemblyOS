/*------------------------------------------------------------------------------

	"main.c" : fase 1 / programador P

	Programa de prueba de creacion y multiplexacion de procesos en GARLIC 1.0,
	pero sin cargar procesos en memoria ni utilizar llamadas a _gg_escribir().

------------------------------------------------------------------------------*/
#include <nds.h>
#include <stdio.h>

#include "garlic_system.h"	// definicion de funciones y variables de sistema

#include <GARLIC_API.h>		// inclusion del API para simular un proceso
int hola(int);				// funcion que simula la ejecucion del proceso

int pres(int);				// funcion que simula la ejecucion del proceso (programa de usuario)

int GARLIC_wait(unsigned char);
int GARLIC_signal(unsigned char);

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

	for(int i = 0; i < 8; i++){		// bucle para inicializar todos los semaforos a 1 (libres)
		_gd_mutex[i] = 1;
	}
}


//------------------------------------------------------------------------------
int main(int argc, char **argv) {
//------------------------------------------------------------------------------
	
	inicializarSistema();
	
	printf("********************************");
	printf("*                              *");
	printf("* Sistema Operativo GARLIC 1.0 *");
	printf("*                              *");
	printf("********************************");
	printf("*** Inicio fase 1_P\n");
	
	_gp_crearProc(hola, 7, "HOLA", 2);
	_gp_crearProc(pres, 14, "PRES", 2);

	while (_gp_numProc() > 1)
	{
		_gp_WaitForVBlank();
		printf("*** Test %d:%d\n", _gd_tickCount, _gp_numProc());
	}						// esperar a que terminen los procesos de usuario

	printf("*** Final fase 1_P\n");

	while (1)
	{
		_gp_WaitForVBlank();
	}							// parar el procesador en un bucle infinito
	return 0;
}


/* Proceso de prueba, con llamadas a las funciones del API del sistema Garlic */
//------------------------------------------------------------------------------
int hola(int arg) {
//------------------------------------------------------------------------------
	unsigned int i, j, iter;
	
	if (arg < 0) arg = 0;			// limitar valor maximo y 
	else if (arg > 3) arg = 3;		// valor minimo del argumento
	
									// esccribir mensaje inicial
	GARLIC_printf("-- Programa HOLA  -  PID (%d) --\n", GARLIC_pid());

	GARLIC_wait(0);	// bloquear el proceso usando el _gd_mutex[0]
	
	j = 1;							// j = calculo de 10 elevado a arg
	for (i = 0; i < arg; i++)
		j *= 10;
						// calculo aleatorio del numero de iteraciones 'iter'
	GARLIC_divmod(GARLIC_random(), j, &i, &iter);
	iter++;							// asegurar que hay al menos una iteracion
	
	for (i = 0; i < iter; i++)		// escribir mensajes
		GARLIC_printf("(%d)\t%d: Hello world!\n", GARLIC_pid(), i);

	return 0;
}

/* Proceso de usuario, con llamadas a las funciones API del sistema Garlic*/
int pres(int arg) {

	unsigned int prestamo, cuotas, precio, mod, temp;

	//comprobar que argumento tiene un valor correcto
	if(arg < 0) arg = 0;
	else if(arg > 3) arg = 3;

	//titulo proceso
	GARLIC_printf("-- Programa PRES  -  PID (%d) --\n", GARLIC_pid());

	//informacion inicial
	GARLIC_printf("(%d)\tPrestamo calculado aleatorio\n\tvalor entre 1000\n\ty %d\n", GARLIC_pid(), (arg+1)*10000);
	GARLIC_printf("(%d)\tCuotas calculadas aleatorias\n\tvalor entre 4 y 63\n", GARLIC_pid());

	prestamo = GARLIC_random() & (arg+1)*10000;		//limitar prestamo al maximo calculado
	prestamo |= 1000;		//asegurar que es de almenos 1000 euros

	//mostramos cual es el valor del prestamo aleatorio
	GARLIC_printf("(%d)\tValor pres.: %d euros.\n", GARLIC_pid(), prestamo);

	cuotas = (GARLIC_random() & 0x3F) | 0xC;	//limitar cuotas entre 12 y 63 (5 años aprox.)

	//mostramos el numero de cuotas aleatorias en las que hay que pagar el prestamo
	GARLIC_printf("(%d)\tCuotas a pagar: %d\n", GARLIC_pid(), cuotas);

	GARLIC_printf("(%d)\tCalculamos valor prestamo\n\ten centimos, entre cuotas\n\ty obtenemos valor cuotas\n\ten centimos, con un error\n\tde menos de 1 centimo\n\ten cada cuota.\n", GARLIC_pid());
	GARLIC_divmod(prestamo*100, cuotas, &temp, &mod);		//calcular valor mensual de cada cuota (en centimos)

	//mostrar el valor de las cuotas en centimos
	GARLIC_printf("(%d)\tValor cuotas en centimos:\n\t%d\n", GARLIC_pid(), temp);

	GARLIC_divmod(temp, 100, &precio, &mod);		//calcular valor mensual de cada cuota (en euros); mod = parte decimal de la cuota

	//mostrar cada parte de la cuota individualmente
	GARLIC_printf("(%d)\tValor en euros: %d\n", GARLIC_pid(), precio);
	GARLIC_printf("(%d)\tParte decimal: %d\n", GARLIC_pid(), mod);

	GARLIC_printf("(%d)\tSi la parte decimal\n\tno es multiplo de 10,\n\tse suma 1 a los centimos\n\tpara que el banco\n\tno pierda dinero.\n", GARLIC_pid());
	GARLIC_divmod(mod, 10, &prestamo, &temp);		//comprobar si mod acaba en 0 (es decir, si faltara ningun centimo en el pago total)
	if(temp != 0) mod++;		//si no lo es, sumamos 1 a los centimos para que el banco no pierda dinero

	//coste mensual final
	GARLIC_printf("\tCoste mensual: %d,%d euros.\n", precio, mod);		//mostramos por pantalla el pago mensual que se debera hacer

	//calcular de nuevo el precio con el ajuste de centimos y mostrar el coste total final
	GARLIC_divmod((precio*100+mod)*cuotas, 100, &precio, &mod);
	GARLIC_printf("\tCoste total: %d,%d euros.\n", precio, mod);

	GARLIC_signal(0);	// desbloquear proceso en _gd_mutex[0]

	return 0;
}

int GARLIC_wait(unsigned char mutex) {

	GARLIC_printf("Entrada en funcion GARLIC_wait()\n");

	if(_gd_mutex[mutex]) {	// si el mutex indicado esta libre
		_gd_mutex[mutex] = 0;

		while(!_gd_mutex[mutex]) {
			_gp_WaitForVBlank();
		}

		return 1;
	
	} else {	// si el mutex indicado no esta libre
		return 0;
	}
}

int GARLIC_signal(unsigned char mutex) {

	GARLIC_printf("Hecho GARLIC_signal()\n");

	if(_gd_mutex[mutex]) {	// si el mutex indicado esta libre
		return 0;
	} else {	// si el mutex indicado esta bloqueando un proceso
		_gd_mutex[mutex] = 1;
		return 1;
	}
}
