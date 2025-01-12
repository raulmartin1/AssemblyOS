	.arch armv5te
	.eabi_attribute 23, 1
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"pres.c"
	.section	.rodata
	.align	2
.LC0:
	.ascii	"-- Programa PRES  -  PID (%d) --\012\000"
	.align	2
.LC1:
	.ascii	"(%d)\011Prestamo calculado aleatorio, valor entre 1"
	.ascii	"000 y %d\012\000"
	.align	2
.LC2:
	.ascii	"(%d)\011Cuotas calculadas aleatorias, valor entre 4"
	.ascii	" y 63\012\000"
	.align	2
.LC3:
	.ascii	"(%d)\011Valor pres.: %d euros.\012\000"
	.align	2
.LC4:
	.ascii	"(%d)\011Cuotas a pagar: %d\012\000"
	.align	2
.LC5:
	.ascii	"(%d)\011Calculamos valor prestamo en centimos entre"
	.ascii	" cuotas, y obtenemos valor\000"
	.align	2
.LC6:
	.ascii	" cuotas en centimos, con un error de menos de 1 cen"
	.ascii	"timo en cada cuota.\012\000"
	.align	2
.LC7:
	.ascii	"(%d)\011Valor cuotas en centimos:\012\011%d\012\000"
	.align	2
.LC8:
	.ascii	"(%d)\011Valor en euros: %d\012\000"
	.align	2
.LC9:
	.ascii	"(%d)\011Parte decimal: %d\012\000"
	.align	2
.LC10:
	.ascii	"(%d)\011Si la parte decimal no es multiplo de 10, s"
	.ascii	"e suma 1 a los centimos para que el banco no pierda"
	.ascii	" dinero.\012\000"
	.align	2
.LC11:
	.ascii	"(%d)\011Coste mensual: %d euros\012\000"
	.align	2
.LC12:
	.ascii	"(%d)\011con %d centimos.\012\000"
	.align	2
.LC13:
	.ascii	"(%d)\011Coste total: %d euros\012\000"
	.text
	.align	2
	.global	_start
	.syntax unified
	.arm
	.fpu softvfp
	.type	_start, %function
_start:
	@ args = 0, pretend = 0, frame = 32
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #36
	str	r0, [sp, #4]
	ldr	r3, [sp, #4]
	cmp	r3, #0
	bge	.L2
	mov	r3, #0
	str	r3, [sp, #4]
	b	.L3
.L2:
	ldr	r3, [sp, #4]
	cmp	r3, #3
	ble	.L3
	mov	r3, #3
	str	r3, [sp, #4]
.L3:
	bl	GARLIC_pid
	mov	r3, r0
	mov	r1, r3
	ldr	r0, .L6
	bl	GARLIC_printf
	bl	GARLIC_pid
	mov	r1, r0
	ldr	r3, [sp, #4]
	add	r3, r3, #1
	ldr	r2, .L6+4
	mul	r3, r2, r3
	mov	r2, r3
	ldr	r0, .L6+8
	bl	GARLIC_printf
	bl	GARLIC_pid
	mov	r3, r0
	mov	r1, r3
	ldr	r0, .L6+12
	bl	GARLIC_printf
	bl	GARLIC_random
	mov	r1, r0
	ldr	r3, [sp, #4]
	add	r3, r3, #1
	ldr	r2, .L6+4
	mul	r3, r2, r3
	and	r3, r3, r1
	str	r3, [sp, #24]
	ldr	r3, [sp, #24]
	orr	r3, r3, #1000
	str	r3, [sp, #24]
	bl	GARLIC_pid
	mov	r1, r0
	ldr	r3, [sp, #24]
	mov	r2, r3
	ldr	r0, .L6+16
	bl	GARLIC_printf
	bl	GARLIC_random
	mov	r3, r0
	and	r3, r3, #51
	orr	r3, r3, #12
	str	r3, [sp, #28]
	bl	GARLIC_pid
	mov	r3, r0
	ldr	r2, [sp, #28]
	mov	r1, r3
	ldr	r0, .L6+20
	bl	GARLIC_printf
	mov	r0, #7
	bl	GARLIC_wait
	bl	GARLIC_pid
	mov	r3, r0
	mov	r1, r3
	ldr	r0, .L6+24
	bl	GARLIC_printf
	ldr	r0, .L6+28
	bl	GARLIC_printf
	ldr	r3, [sp, #24]
	mov	r2, #100
	mul	r0, r2, r3
	add	r3, sp, #16
	add	r2, sp, #12
	ldr	r1, [sp, #28]
	bl	GARLIC_divmod
	bl	GARLIC_pid
	mov	r1, r0
	ldr	r3, [sp, #12]
	mov	r2, r3
	ldr	r0, .L6+32
	bl	GARLIC_printf
	ldr	r0, [sp, #12]
	add	r3, sp, #16
	add	r2, sp, #20
	mov	r1, #100
	bl	GARLIC_divmod
	bl	GARLIC_pid
	mov	r1, r0
	ldr	r3, [sp, #20]
	mov	r2, r3
	ldr	r0, .L6+36
	bl	GARLIC_printf
	bl	GARLIC_pid
	mov	r1, r0
	ldr	r3, [sp, #16]
	mov	r2, r3
	ldr	r0, .L6+40
	bl	GARLIC_printf
	bl	GARLIC_pid
	mov	r3, r0
	mov	r1, r3
	ldr	r0, .L6+44
	bl	GARLIC_printf
	ldr	r0, [sp, #16]
	add	r3, sp, #12
	add	r2, sp, #24
	mov	r1, #10
	bl	GARLIC_divmod
	ldr	r3, [sp, #12]
	cmp	r3, #0
	beq	.L4
	ldr	r3, [sp, #16]
	add	r3, r3, #1
	str	r3, [sp, #16]
.L4:
	bl	GARLIC_pid
	mov	r1, r0
	ldr	r3, [sp, #20]
	mov	r2, r3
	ldr	r0, .L6+48
	bl	GARLIC_printf
	bl	GARLIC_pid
	mov	r1, r0
	ldr	r3, [sp, #16]
	mov	r2, r3
	ldr	r0, .L6+52
	bl	GARLIC_printf
	ldr	r3, [sp, #20]
	mov	r2, #100
	mul	r2, r3, r2
	ldr	r3, [sp, #16]
	add	r3, r2, r3
	ldr	r2, [sp, #28]
	mul	r0, r2, r3
	add	r3, sp, #16
	add	r2, sp, #20
	mov	r1, #100
	bl	GARLIC_divmod
	bl	GARLIC_pid
	mov	r1, r0
	ldr	r3, [sp, #20]
	mov	r2, r3
	ldr	r0, .L6+56
	bl	GARLIC_printf
	bl	GARLIC_pid
	mov	r1, r0
	ldr	r3, [sp, #16]
	mov	r2, r3
	ldr	r0, .L6+52
	bl	GARLIC_printf
	mov	r0, #0
	bl	GARLIC_signal
	mov	r3, #0
	mov	r0, r3
	add	sp, sp, #36
	@ sp needed
	ldr	pc, [sp], #4
.L7:
	.align	2
.L6:
	.word	.LC0
	.word	10000
	.word	.LC1
	.word	.LC2
	.word	.LC3
	.word	.LC4
	.word	.LC5
	.word	.LC6
	.word	.LC7
	.word	.LC8
	.word	.LC9
	.word	.LC10
	.word	.LC11
	.word	.LC12
	.word	.LC13
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
