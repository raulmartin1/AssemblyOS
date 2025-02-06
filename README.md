# GarlicOS

**Versión:** 2.0  
**Plataforma:** Nintendo DS (NDS)  
**Descripción:** GarlicOS es un sistema operativo pedagógico diseñado para la NDS, capaz de gestionar múltiples procesos, manejar memoria dinámica y proveer una interfaz gráfica para la interacción con el usuario.

## 📌 Características Principales

- **Multiprocesamiento**: Capaz de ejecutar hasta 16 procesos concurrentemente.
- **Gestión de Memoria**: Soporte para carga dinámica de programas ELF con reubicación de direcciones.
- **Interfaz Gráfica**: 16 ventanas de texto con diferentes colores y soporte para escritura directa.
- **Interacción con el Usuario**: Entrada de datos mediante teclado virtual y botones de la NDS.
- **Planificación de Procesos**: Uso de Round Robin sin prioridad.
- **Gestión de Interrupciones**: Implementación propia para manejar IRQs de la NDS.

## 📂 Estructura del Proyecto

```
GarlicOS/
│── GARLIC_OS/               # Código fuente del sistema operativo
│   ├── source/              # Código fuente en C y ensamblador
│   ├── include/             # Archivos de cabecera
│   ├── nitrofiles/          # Recursos específicos para NDS
│   ├── obj_files/           # Ficheros objeto precompilados para roles faltantes
│   ├── Makefile             # Script de compilación
│── GARLIC_API/              # API del sistema operativo
│── GARLIC_Progs/            # Programas de usuario
│   ├── HOLA/                # Programa de prueba "Hello World"
│   ├── PRNT/                # Programa de testeo de impresión
│   ├── BORR/                # Borrar ventana
│   ├── CRON/                # Cronómetro
│   ├── DESC/                # Descomposición de números primos
│   ├── LABE/                # Recorrido de laberinto
│   ├── PONG/                # Simulación de rebote de una pelota
```

## 🛠️ Compilación e Instalación

### **Requisitos**
- DevkitPro + libnds
- Simulador DeSmuME o una NDS real con flashcard
- Git para gestionar versiones

### **Compilación**
```sh
cd GARLIC_OS
make
```

### **Ejecución**
En DeSmuME:
```sh
desmume garlic_os.nds
```
En una NDS real, copiar `garlic_os.nds` a una tarjeta de memoria compatible.

## 📛 API del Sistema Operativo

El sistema provee una API para que los programas puedan interactuar con el OS:

```c
extern int GARLIC_pid();            // Devuelve el PID del proceso actual
extern int GARLIC_random();         // Número aleatorio de 32 bits
extern int GARLIC_divmod();         // División con módulo
extern void GARLIC_printf();        // Escribir en la ventana del proceso actual
extern void GARLIC_delay();         // Retardar ejecución del proceso
extern void GARLIC_clear();         // Limpiar ventana
extern void GARLIC_printchar();     // Escribir un carácter en posición específica
extern void GARLIC_printmat();      // Escribir una matriz de caracteres
```

## 🛠️ Desarrollo y Contribución

### **Ramas de Trabajo**
El desarrollo del proyecto sigue una estructura basada en roles:
- **progP**: Gestión de procesos (multiprocesamiento, planificación, sincronización).
- **progM**: Gestión de memoria (carga de programas, asignación y liberación de memoria).
- **progG**: Gestión de gráficos (ventanas, colores, renderizado de texto).
- **progT**: Gestión del teclado (entrada de datos desde pantalla táctil).
