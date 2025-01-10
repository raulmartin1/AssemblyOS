/*------------------------------------------------------------------------------

	"PI_1.c" : programa de test de la funci�n de API GARLIC_printf();
				(versi�n 1.0)
	
	Imprime diversos mensajes por ventana, comprobando el funcionamiento de
	la inserci�n de valores con distintos formatos, con o sin traspaso del
	l�mite de la �ltima columna de la ventana.

------------------------------------------------------------------------------*/

#include <GARLIC_API.h>			/* definici�n de las funciones API de GARLIC */


int _start(int arg) {
	
    GARLIC_printf("\n-- Programa PI_1  -  PID (%d) --\n", GARLIC_pid());

    if (arg < 0) arg = 0;            // limitar valor m?ximo y 
    else if (arg > 3) arg = 3;        // valor m?nimo del argumento

    unsigned int result, mod;

    unsigned int pi = 0;
    unsigned int piDecimal = 0;

    // se calcula el numero de fracciones 2^arg
    int fracciones = 1;
    for (int i = 0; i < arg; i++) {
        fracciones *= 2; 
    }

    GARLIC_printf("%0Numero de fracciones: %d\n", fracciones);
    // calcula la suma de la serie
    
    for (int i = 0; i < fracciones; i++) { 
        GARLIC_divmod(1, (2*i+1), &result, &mod);       //Calculem 1/(2i+1)
        int signo;
        if (mod == 0) {
            //pi += result;
			signo = 1;     // si es par, fraccion positiva 1/(2i+1)
        } else {
            //pi -= result;
			signo = -1;    // si es impar, fraccion negativa -1/(2i+1)
        }
		
        pi += signo * result;      
        piDecimal += signo*mod;
		
        GARLIC_printf("%1Fraccio numero: %d es:\n", i+1);
		GARLIC_printf("%3%d.%d\n", pi, piDecimal);
    }
    pi*= 4;
    piDecimal*= 4;

    // Mostrar el resultado en formato "entero.decimal"
    GARLIC_printf("%2PI Calculado es: %d.%d\n", pi, piDecimal); 

    return 0;
}