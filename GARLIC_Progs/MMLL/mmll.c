/*------------------------------------------------------------------------------

	"MMLL.c" : programa de usuario 
	
	Minimo y maximo de una lista de 100^(arg+1) num. aleatorios enteros largos (64bits)

------------------------------------------------------------------------------*/

#include <GARLIC_API.h>			/* definicion de las funciones API de GARLIC */

int _start(int arg) {                              /* funcion de inicio : no se usa 'main' */

    // Calcular el tamaño de la lista
    unsigned int n = 1;
    for (int i = 0; i < arg + 1; i++) {
        n *= 100;
    }

    // Inicializar el "mínimo" y "máximo" en 64 bits
    unsigned int min_high = 0xFFFFFFFF;
    unsigned int min_low = 0xFFFFFFFF;
    unsigned int max_high = 0;
    unsigned int max_low = 0;

    for (unsigned int i = 0; i < n; i++) {
        // Generamos dos números aleatorios de 32 bits y los tratamos como partes alta y baja
        unsigned int high = (unsigned int) GARLIC_random();
        unsigned int low = (unsigned int) GARLIC_random();

        // Actualizar mínimo
        if (high < min_high || (high == min_high && low < min_low)) {
            min_high = high;
            min_low = low;
        }

        // Actualizar máximo
        if (high > max_high || (high == max_high && low > max_low)) {
            max_high = high;
            max_low = low;
        }
    }

    // Mostrar resultados en hexadecimal
    GARLIC_printf("Minimo: %x%x\n", min_high, min_low);
    GARLIC_printf("Maximo: %x%x\n", max_high, max_low);

    return 0; // Retornar 0 para indicar que todo ha ido bien
}