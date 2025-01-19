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

    
    unsigned char baldosa[64];

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

    // Mostrar el resultado en formato "entero.decimal"
    GARLIC_printf("%2PI Calculado es: %d.%d\n", pi, piDecimal);
    /*
    GARLIC_setChar(128, baldosa);
    GARLIC_setChar(129, baldosa);
    GARLIC_setChar(130, baldosa);
    GARLIC_printf("%2 cara: \\x80");
    GARLIC_printf("%2 cara: \x80"); 
    GARLIC_printf("%1 cara: \\x81"); 
    GARLIC_printf("%1 cara: \x81"); 
    */

    for (int t = 0; t <= 7; t++) { // Generar 8 baldosas
        for (int i = 0; i < 64; i++) {
            // Generar el patrón según el valor de t
            if (t == 0) {
                // Baldosa 0: Todo gris claro
                baldosa[i] = 0xAA;
            } else if (t == 1) {
                // Baldosa 1: Todo gris oscuro
                baldosa[i] = 0x55;
            } else if (t == 2) {
                // Baldosa 2: Mitad superior blanca, mitad inferior negra
                if (i < 32) {
                    baldosa[i] = 0xFF; // Mitad superior
                } else {
                    baldosa[i] = 0x00; // Mitad inferior
                }
            } else if (t == 3) {
                // Baldosa 3: Mitad izquierda blanca, mitad derecha negra
                if (i % 8 < 4) {
                    baldosa[i] = 0xFF; // Mitad izquierda
                } else {
                    baldosa[i] = 0x00; // Mitad derecha
                }
            } else if (t == 4) {
                // Baldosa 4: Líneas horizontales alternadas
                if ((i / 8) % 2 == 0) {
                    baldosa[i] = 0xFF; // Líneas blancas
                } else {
                    baldosa[i] = 0x00; // Líneas negras
                }
            } else if (t == 5) {
                // Baldosa 5: Líneas verticales alternadas
                if ((i % 8) % 2 == 0) {
                    baldosa[i] = 0xFF; // Líneas blancas
                } else {
                    baldosa[i] = 0x00; // Líneas negras
                }
            } else if (t == 6) {
                // Baldosa 6: Cruz en el centro
                if ((i / 8 == 3 || i / 8 == 4) || (i % 8 == 3 || i % 8 == 4)) {
                    baldosa[i] = 0x00; // Cruz negra
                } else {
                    baldosa[i] = 0xFF; // Fondo blanco
                }
            } else if (t == 7) {
                // Baldosa 7: Marco negro
                if (i / 8 == 0 || i / 8 == 7 || i % 8 == 0 || i % 8 == 7) {
                    baldosa[i] = 0x00; // Borde negro
                } else {
                    baldosa[i] = 0xFF; // Centro blanco
                }
            }
        }
        GARLIC_setChar(128 + t, baldosa); // Guardar la baldosa generada
    }
    
    GARLIC_printf("%0Caracteres personalizados:\n");
    GARLIC_printf("%0\\x80 %1 \\x81 %2 \\x82 %3 \\x83 %0 \\x84 %1 \\x85 %2 \\x86 %3 \\x87\n" );
   
    //GARLIC_printf("%0 \x80 %1 \x81 %2 \x82 %3 \x83 %0 \x84 %1 \x85 %2 \x86 %3 \x87" );
    return 0;
}
