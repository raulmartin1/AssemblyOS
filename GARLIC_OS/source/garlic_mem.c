/*------------------------------------------------------------------------------

	"garlic_mem.c" : fase 1 / programador M

	Funciones de carga de un fichero ejecutable en formato ELF, para GARLIC 1.0

------------------------------------------------------------------------------*/
#include <nds.h>
#include <filesystem.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "garlic_system.h"	// definición de funciones y variables de sistema

#define INI_MEM 0x01002000		// dirección inicial de memoria para programas


typedef struct { 				/*Estructura de cada entrada de la taula de segments*/
	Elf32_Word p_type; 
	Elf32_Off p_offset; 
	Elf32_Addr p_vaddr; 
	Elf32_Addr p_paddr; 
	Elf32_Word p_filesz; 
	Elf32_Word p_memsz; 
	Elf32_Word p_flags; 
	Elf32_Word p_align; 
} Elf32_Phdr; 

typedef struct { 							/*Estructura de la capcelera dels archius ELF*/
	unsigned char e_ident[EI_NIDENT]; 
	Elf32_Half  e_type; 
	Elf32_Half  e_machine; 
	Elf32_Word  e_version; 
	Elf32_Addr  e_entry; 
	Elf32_Off   e_phoff; 
	Elf32_Off   e_shoff; 
	Elf32_Word  e_flags; 
	Elf32_Half  e_ehsize; 
	Elf32_Half  e_phentsize; 
	Elf32_Half  e_phnum; 
	Elf32_Half  e_shentsize; 
	Elf32_Half  e_shnum; 
	Elf32_Half  e_shstrndx; 
} Elf32_Ehdr; 


/* _gm_initFS: inicializa el sistema de ficheros, devolviendo un valor booleano
					para indiciar si dicha inicialización ha tenido éxito;
*/
int _gm_initFS()
{
	return nitroFSInit(NULL);	// inicializar sistema de ficheros NITRO
}


/* _gm_cargarPrograma: busca un fichero de nombre "(keyName).elf" dentro del
					directorio "/Programas/" del sistema de ficheros y carga
					los segmentos de programa a partir de una posición de
					memoria libre, efectuando la reubicación de las referencias
					a los símbolos del programa según el desplazamiento del
					código en la memoria destino;
	Parámetros:
		keyName ->	string de 4 caracteres con el nombre en clave del programa
	Resultado:
		!= 0	->	dirección de inicio del programa (intFunc)
		== 0	->	no se ha podido cargar el programa
*/
intFunc _gm_cargarPrograma(char *keyName)
{
	long midaF;
	char *buff;
	size_t correcte;
	char nom[19];
	
	sprintf(nom, "/Programas/%s.elf", keyName);
	FILE *ficher = fopen(nom, "rb");
	if (ficher==NULL)
	{
		printf("No se ha podido abrir el fichero. \n");
		return 1;
	}
	
	fseek(ficher, 0, SEEK_END);				/*Obtenim mida del ficher*/
	midaF = ftell (ficher);
	fseek(ficher, 0, SEEK_SET);
	
	buff = (char*) malloc (sizeof(char)*(midaF+1));			/*Reservem espai a memoria dinamica pel buffer*/
	if (buff == NULL)
	{
		printf("No s'ha pogut fer la assignacio de memoria. \n");
		fclose(ficher);
		return 1;
	}
	
	correcte = fread(buff, sizeof(char), midaF, ficher);	/*Carguem el ficher al buffer*/
	if (correcte =! midaF)
	{
		printf ("Error al copiar el fitxer al buffer. \n");
		fclose(ficher);
		return 1;
	}
	
	fseek(ficher, 0, SEEK_SET);								/*Coloquem be el punter al inici del ficher*/
	Elf32_Ehdr cabecera;
	fread(&cabecera, 1, sizeof(Elf32_Ehdr), ficher);		/*Llegim la capcelera del ficher ELF*/
	if (cabecera  != sizeof(Elf32_Ehdr))
	{
		printf ("Error al leer la cabecera ELF. \n")
		fclose(ficher);
		return 1;
	}
	
	Elf32_Off offset;
	Elf32_Half n_entrades;
	Elf32_Half t_entradas;
	
	offset = cabecera.e_phoff;								/*Guardem la posicio del offset de la taula de segments*/
	n_entradas = cabecera.e_phnum;							/*Guardem el numero de entradas de la taula de segments*/
	t_entradas = cabecera.e_phentsize;						/*Guardem la mida de cada entrada de la taula de segments*/
	
	
	fseek(ficher, offset, SEEK_SET);						/*Apuntem al program header del ficher (desplaçament de la taula de segments)*/
	Elf32_Phdr ent_segments;
	fread(&ent_segments, 1, sizeof(Elf32_Phdr), ficher);	/*Llegim la taula de segments*/
	
	Elf32_Addr mem_ini;
	Elf32_Off off_seg;
	Elf32_Word mida_seg;
	
	mem_ini = ent_segments.p_paddr;							/*Guardem la direccio de memoria inicial del segment a carregar*/
	off_seg = ent_segments.p_offset;						/*Guardem el desplaçament dins del ficher on comença el segment*/
	mida_seg = ent_segments.p_memsz;						/*Guardem la mida del segment dins de la memoria*/
	
	


	
	
	
}

