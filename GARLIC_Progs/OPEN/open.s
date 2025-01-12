	.arch armv5te
	.eabi_attribute 23, 1
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"open.c"
	.section	.rodata
	.align	2
.LC0:
	.ascii	"rb\000"
	.align	2
.LC1:
	.ascii	"Datos/prov.txt\000"
	.align	2
.LC2:
	.ascii	"GARLIC_fopen llamado\000"
	.align	2
.LC3:
	.ascii	"Error en la lectura del fitxer prov.txt\000"
	.align	2
.LC4:
	.ascii	"\012Se han leido %d elementos\000"
	.align	2
.LC5:
	.ascii	"\012Text que hi ha: %s\012\000"
	.text
	.align	2
	.global	_start
	.syntax unified
	.arm
	.fpu softvfp
	.type	_start, %function
_start:
	@ args = 0, pretend = 0, frame = 48
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #52
	str	r0, [sp, #4]
	ldr	r1, .L5
	ldr	r0, .L5+4
	bl	GARLIC_fopen
	str	r0, [sp, #44]
	ldr	r0, .L5+8
	bl	GARLIC_printf
	ldr	r3, [sp, #44]
	cmp	r3, #0
	bne	.L2
	ldr	r0, .L5+12
	bl	GARLIC_printf
	mvn	r3, #0
	b	.L4
.L2:
	add	r0, sp, #8
	ldr	r3, [sp, #44]
	mov	r2, #20
	mov	r1, #1
	bl	GARLIC_fread
	str	r0, [sp, #40]
	ldr	r1, [sp, #40]
	ldr	r0, .L5+16
	bl	GARLIC_printf
	add	r3, sp, #8
	mov	r1, r3
	ldr	r0, .L5+20
	bl	GARLIC_printf
	ldr	r0, [sp, #44]
	bl	GARLIC_fclose
	mov	r3, #0
.L4:
	mov	r0, r3
	add	sp, sp, #52
	@ sp needed
	ldr	pc, [sp], #4
.L6:
	.align	2
.L5:
	.word	.LC0
	.word	.LC1
	.word	.LC2
	.word	.LC3
	.word	.LC4
	.word	.LC5
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
