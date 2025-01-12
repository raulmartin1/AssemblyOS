/*------------------------------------------------------------------------------

	"PRES.c" : programa de usuario para el sistema operativo GARLIC 1.0;

	Calcula el valor de las cuotas de un prestamo mostrando los pasos por
	una ventana de GARLIC, siendo el prestamo un valor aleatorio
	entre 1000 y (arg+1)*10000 euros, siendo arg un valor entre [0..3].

------------------------------------------------------------------------------*/

#include <GARLIC_API.h>			/* definici�n de las funciones API de GARLIC */

int _start(int arg)				/* funci�n de inicio : no se usa 'main' */
{
	unsigned int prestamo, cuotas, precio, mod, temp, retorno;

	//comprobar que argumento tiene un valor correcto
	if(arg < 0) arg = 0;
	else if(arg > 3) arg = 3;

	//titulo proceso
	GARLIC_printf("-- Programa PRES  -  PID (%d) --\n", GARLIC_pid());

	//informacion inicial
	GARLIC_printf("(%d)\tPrestamo calculado aleatorio, valor entre 1000 y %d\n", GARLIC_pid(), (arg+1)*10000);
	GARLIC_printf("(%d)\tCuotas calculadas aleatorias, valor entre 4 y 63\n", GARLIC_pid());

	prestamo = GARLIC_random() & (arg+1)*10000;		//limitar prestamo al maximo calculado
	prestamo |= 1000;		//asegurar que es de almenos 1000 euros

	//mostramos cual es el valor del prestamo aleatorio
	GARLIC_printf("(%d)\tValor pres.: %d euros.\n", GARLIC_pid(), prestamo);

	cuotas = (GARLIC_random() & 0x3F) | 0xC;	//limitar cuotas entre 12 y 63 (5 años aprox.)

	//mostramos el numero de cuotas aleatorias en las que hay que pagar el prestamo
	GARLIC_printf("(%d)\tCuotas a pagar: %d\n", GARLIC_pid(), cuotas);

	if(arg==2){
		retorno = GARLIC_wait(arg+1);
	}
	else{
		retorno = GARLIC_wait(arg);
	}

	GARLIC_printf("(%d)\tCalculamos valor prestamo en centimos entre cuotas, y obtenemos valor", GARLIC_pid());
	GARLIC_printf(" cuotas en centimos, con un error de menos de 1 centimo en cada cuota.\n");
	GARLIC_divmod(prestamo*100, cuotas, &temp, &mod);		//calcular valor mensual de cada cuota (en centimos)

	//mostrar el valor de las cuotas en centimos
	GARLIC_printf("(%d)\tValor cuotas en centimos:\n\t%d\n", GARLIC_pid(), temp);

	GARLIC_divmod(temp, 100, &precio, &mod);		//calcular valor mensual de cada cuota (en euros); mod = parte decimal de la cuota

	//mostrar cada parte de la cuota individualmente
	GARLIC_printf("(%d)\tValor en euros: %d\n", GARLIC_pid(), precio);
	GARLIC_printf("(%d)\tParte decimal: %d\n", GARLIC_pid(), mod);

	GARLIC_printf("(%d)\tSi la parte decimal no es multiplo de 10, se suma 1 a los centimos para que el banco no pierda dinero.\n", GARLIC_pid());
	GARLIC_divmod(mod, 10, &prestamo, &temp);		//comprobar si mod acaba en 0 (es decir, si no faltara ningun centimo en el pago total)
	if(temp != 0) mod++;		//si no lo es, sumamos 1 a los centimos para que el banco no pierda dinero

	//coste mensual final
	GARLIC_printf("(%d)\tCoste mensual: %d euros\n", GARLIC_pid(), precio);		//mostramos por pantalla el pago mensual que se debera hacer
	GARLIC_printf("(%d)\tcon %d centimos.\n", GARLIC_pid(), mod);

	//calcular de nuevo el precio con el ajuste de centimos y mostrar el coste total final
	GARLIC_divmod((precio*100+mod)*cuotas, 100, &precio, &mod);

	GARLIC_printf("(%d)\tCoste total: %d euros\n", GARLIC_pid(), precio);
	GARLIC_printf("(%d)\tcon %d centimos.\n", GARLIC_pid(), mod);

	GARLIC_printf("%2Retorno waitS: %d\n", retorno);

	return 0;
}
