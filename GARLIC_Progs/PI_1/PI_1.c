/*------------------------------------------------------------------------------

	"PRNT.c" : programa de test de la funci�n de API GARLIC_printf();
				(versi�n 1.0)
	
	Imprime diversos mensajes por ventana, comprobando el funcionamiento de
	la inserci�n de valores con distintos formatos, con o sin traspaso del
	l�mite de la �ltima columna de la ventana.

------------------------------------------------------------------------------*/

#include <GARLIC_API.h>			/* definici�n de las funciones API de GARLIC */
#include <stdlib.h>
#include <time.h>
#include <stdio.h>

int PI_1(int arg);
int _start(int arg)	
{	

	GARLIC_printf("-- Programa PI_1  -  PID (%d) --\n", GARLIC_pid());

	PI_1(3);

	return 0;
}

int PI_1(int arg) {
	
	GARLIC_printf("\n-- Programa PI_1  -  PID (%d) --\n", GARLIC_pid());
	
	if (arg < 0) {
		GARLIC_printf("(%d)\tNo se ha podido Calcular Pi\n Indica un argumento positivo\n", GARLIC_pid());
		return 0;
	}
	
	double pi = 0.0;
	
	// se calcula el numero de fracciones 2^arg
	int fracciones = 1;					
	for (int i = 0; i < arg; i++) {		
		fracciones *= 2; 
	}
	 
	// calcula la suma de la serie
	for (int i = 0; i < fracciones; i++) { 
		double fraccion;
		if (i % 2 == 0) {
			fraccion = 1.0 / (2 * i + 1); 	// si es par, fraccion positiva 1/(2i+1)
		} else {
			fraccion = -1.0 / (2 * i + 1);	// si es impar, fraccion negativa -1/(2i+1)
		}
		pi += fraccion; 
	}
	pi *= 4;
	
	// Separar la parte entera y decimal de pi
	unsigned long long parte_entera = (unsigned long long)pi; // Parte entera
	unsigned long long parte_decimal = (unsigned long long)((pi - parte_entera) * 1000000); // 6 dígitos decimales

	// Mostrar el resultado en formato "entero.decimal"
	GARLIC_printf("PI Calculado es: %d.%d\n", (int)parte_entera, (int)parte_decimal); 

	return 0;
}