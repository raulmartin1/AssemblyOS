/*------------------------------------------------------------------------------

	"OPEN.c" : programa de test de la parte adicional progM 

------------------------------------------------------------------------------*/

#include <GARLIC_API.h>			/* definicion de las funciones API de GARLIC */

int _start(int arg)
{
    G_file *f = GARLIC_fopen("Datos/prov.txt", "rb");

	GARLIC_printf("GARLIC_fopen llamado");
	if (f == 0)
	{
		GARLIC_printf("Error en la lectura del fitxer prov.txt");
		return -1;
	}

	char par[32];
	int elements;
	
	elements = GARLIC_fread (par, 1, 20, f);				//fiquem de sobres
	
	GARLIC_printf("\nSe han leido %d elementos", elements);
	GARLIC_printf("\nText que hi ha: %s", par);
	GARLIC_fclose(f);
	
    return 0;
}