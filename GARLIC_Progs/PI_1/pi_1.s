	.arch armv5te
	.eabi_attribute 23, 1
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"PI_1.c"
	.section	.rodata
	.align	2
.LC0:
	.ascii	"\012-- Programa PI_1  -  PID (%d) --\012\000"
	.align	2
.LC1:
	.ascii	"%0Numero de fracciones: %d\012\000"
	.align	2
.LC2:
	.ascii	"%1Fraccio numero: %d es:\012\000"
	.align	2
.LC3:
	.ascii	"%3%d.%d\012\000"
	.align	2
.LC4:
	.ascii	"%2PI Calculado es: %d.%d\012\000"
	.text
	.align	2
	.global	_start
	.syntax unified
	.arm
	.fpu softvfp
	.type	_start, %function
_start:
	@ args = 0, pretend = 0, frame = 40
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #44
	str	r0, [sp, #4]
	bl	GARLIC_pid
	mov	r3, r0
	mov	r1, r3
	ldr	r0, .L11
	bl	GARLIC_printf
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
	mov	r3, #0
	str	r3, [sp, #36]
	mov	r3, #0
	str	r3, [sp, #32]
	mov	r3, #1
	str	r3, [sp, #28]
	mov	r3, #0
	str	r3, [sp, #24]
	b	.L4
.L5:
	ldr	r3, [sp, #28]
	lsl	r3, r3, #1
	str	r3, [sp, #28]
	ldr	r3, [sp, #24]
	add	r3, r3, #1
	str	r3, [sp, #24]
.L4:
	ldr	r2, [sp, #24]
	ldr	r3, [sp, #4]
	cmp	r2, r3
	blt	.L5
	ldr	r1, [sp, #28]
	ldr	r0, .L11+4
	bl	GARLIC_printf
	mov	r3, #0
	str	r3, [sp, #20]
	b	.L6
.L9:
	ldr	r3, [sp, #20]
	lsl	r3, r3, #1
	add	r3, r3, #1
	mov	r1, r3
	add	r3, sp, #8
	add	r2, sp, #12
	mov	r0, #1
	bl	GARLIC_divmod
	ldr	r3, [sp, #8]
	cmp	r3, #0
	bne	.L7
	mov	r3, #1
	str	r3, [sp, #16]
	b	.L8
.L7:
	mvn	r3, #0
	str	r3, [sp, #16]
.L8:
	ldr	r3, [sp, #16]
	ldr	r2, [sp, #12]
	mul	r3, r2, r3
	ldr	r2, [sp, #36]
	add	r3, r2, r3
	str	r3, [sp, #36]
	ldr	r3, [sp, #16]
	ldr	r2, [sp, #8]
	mul	r3, r2, r3
	ldr	r2, [sp, #32]
	add	r3, r2, r3
	str	r3, [sp, #32]
	ldr	r3, [sp, #20]
	add	r3, r3, #1
	mov	r1, r3
	ldr	r0, .L11+8
	bl	GARLIC_printf
	ldr	r2, [sp, #32]
	ldr	r1, [sp, #36]
	ldr	r0, .L11+12
	bl	GARLIC_printf
	ldr	r3, [sp, #20]
	add	r3, r3, #1
	str	r3, [sp, #20]
.L6:
	ldr	r2, [sp, #20]
	ldr	r3, [sp, #28]
	cmp	r2, r3
	blt	.L9
	ldr	r3, [sp, #36]
	lsl	r3, r3, #2
	str	r3, [sp, #36]
	ldr	r3, [sp, #32]
	lsl	r3, r3, #2
	str	r3, [sp, #32]
	ldr	r2, [sp, #32]
	ldr	r1, [sp, #36]
	ldr	r0, .L11+16
	bl	GARLIC_printf
	mov	r3, #0
	mov	r0, r3
	add	sp, sp, #44
	@ sp needed
	ldr	pc, [sp], #4
.L12:
	.align	2
.L11:
	.word	.LC0
	.word	.LC1
	.word	.LC2
	.word	.LC3
	.word	.LC4
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
