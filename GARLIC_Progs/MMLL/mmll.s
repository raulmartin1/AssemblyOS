	.arch armv5te
	.eabi_attribute 23, 1
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"mmll.c"
	.section	.rodata
	.align	2
.LC0:
	.ascii	"Minimo: %x%x\012\000"
	.align	2
.LC1:
	.ascii	"Maximo: %x%x\012\000"
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
	mov	r3, #1
	str	r3, [sp, #44]
	mov	r3, #0
	str	r3, [sp, #40]
	b	.L2
.L3:
	ldr	r3, [sp, #44]
	mov	r2, #100
	mul	r3, r2, r3
	str	r3, [sp, #44]
	ldr	r3, [sp, #40]
	add	r3, r3, #1
	str	r3, [sp, #40]
.L2:
	ldr	r3, [sp, #4]
	add	r2, r3, #1
	ldr	r3, [sp, #40]
	cmp	r2, r3
	bgt	.L3
	mvn	r3, #0
	str	r3, [sp, #36]
	mvn	r3, #0
	str	r3, [sp, #32]
	mov	r3, #0
	str	r3, [sp, #28]
	mov	r3, #0
	str	r3, [sp, #24]
	mov	r3, #0
	str	r3, [sp, #20]
	b	.L4
.L9:
	bl	GARLIC_random
	mov	r3, r0
	str	r3, [sp, #16]
	bl	GARLIC_random
	mov	r3, r0
	str	r3, [sp, #12]
	ldr	r2, [sp, #16]
	ldr	r3, [sp, #36]
	cmp	r2, r3
	bcc	.L5
	ldr	r2, [sp, #16]
	ldr	r3, [sp, #36]
	cmp	r2, r3
	bne	.L6
	ldr	r2, [sp, #12]
	ldr	r3, [sp, #32]
	cmp	r2, r3
	bcs	.L6
.L5:
	ldr	r3, [sp, #16]
	str	r3, [sp, #36]
	ldr	r3, [sp, #12]
	str	r3, [sp, #32]
.L6:
	ldr	r2, [sp, #16]
	ldr	r3, [sp, #28]
	cmp	r2, r3
	bhi	.L7
	ldr	r2, [sp, #16]
	ldr	r3, [sp, #28]
	cmp	r2, r3
	bne	.L8
	ldr	r2, [sp, #12]
	ldr	r3, [sp, #24]
	cmp	r2, r3
	bls	.L8
.L7:
	ldr	r3, [sp, #16]
	str	r3, [sp, #28]
	ldr	r3, [sp, #12]
	str	r3, [sp, #24]
.L8:
	ldr	r3, [sp, #20]
	add	r3, r3, #1
	str	r3, [sp, #20]
.L4:
	ldr	r2, [sp, #20]
	ldr	r3, [sp, #44]
	cmp	r2, r3
	bcc	.L9
	ldr	r2, [sp, #32]
	ldr	r1, [sp, #36]
	ldr	r0, .L11
	bl	GARLIC_printf
	ldr	r2, [sp, #24]
	ldr	r1, [sp, #28]
	ldr	r0, .L11+4
	bl	GARLIC_printf
	mov	r0, #7
	bl	GARLIC_signal
	mov	r3, #0
	mov	r0, r3
	add	sp, sp, #52
	@ sp needed
	ldr	pc, [sp], #4
.L12:
	.align	2
.L11:
	.word	.LC0
	.word	.LC1
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
