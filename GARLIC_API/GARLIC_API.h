/*------------------------------------------------------------------------------

	"GARLIC_API.h" : cabeceras de funciones del API (Application Program
					Interface) del sistema operativo GARLIC 1.0 (codigo fuente
					disponible en "GARLIC_API.s")

------------------------------------------------------------------------------*/
#ifndef _GARLIC_API_h_
#define _GARLIC_API_h_


	/* GARLIC_pid: devuelve el identificador del proceso actual */
extern int GARLIC_pid();


	/* GARLIC_random: devuelve un numero aleatorio de 32 bits */
extern int GARLIC_random();


	/* GARLIC_divmod: calcula la division num / den (numerador / denominador),
		almacenando el cociente y el resto en las posiciones de memoria indica-
		das por *quo y *mod, respectivamente (pasa resultados por referencia);
		la funcion devuelve 0 si la division es correcta, o diferente de 0
		si hay algun problema (division por cero).
		ATENCION: solo procesa numeros naturales de 32 bits SIN signo. */
extern int GARLIC_divmod(unsigned int num, unsigned int den,
							unsigned int * quo, unsigned int * mod);


	/* GARLIC_divmodL: calcula la division num / den (numerador / denominador),
		almacenando el cociente y el resto en las posiciones de memoria indica-
		das por *quo y *mod, respectivamente; los parametros y los resultados
		se pasan por referencia; el numerador y el cociente son de tipo
		long long (64 bits), mientras que el denominador y el resto son de tipo
		unsigned int (32 bits sin signo).
		la funcion devuelve 0 si la division es correcta, o diferente de 0
		si hay algun problema (division por cero). */
extern int GARLIC_divmodL(long long * num, unsigned int * den,
							long long * quo, unsigned int * mod);


	/* GARLIC_printf: escribe un string en la ventana del proceso actual,
		utilizando el string de formato 'format' que se pasa como primer
		parametro, insertando los valores que se pasan en los siguientes
		parametros (hasta 2) en la posicion y forma (tipo) que se especifique
		con los marcadores incrustados en el string de formato:
			%c	: inserta un caracter (segun codigo ASCII)
			%d	: inserta un natural (32 bits) en formato decimal
			%x	: inserta un natural (32 bits) en formato hexadecimal
			%s	: inserta un string
			%%	: inserta un caracter '%' literal
		Ademas, tambien procesa los metacaracteres '\t' (tabulador) y '\n'
		(salto de linia). */
extern void GARLIC_printf(char * format, ...);


	/*	GARLIC_wait: modifica el semaforo indicado por parametro
		para que bloquee el proceso que llama a la funcion. */
extern int GARLIC_wait(unsigned char);

	/*	GARLIC_wait: modifica el semaforo indicado por parametro
		para que desbloquee el proceso que lo esta usando. */
extern int GARLIC_signal(unsigned char);


#endif // _GARLIC_API_h_
