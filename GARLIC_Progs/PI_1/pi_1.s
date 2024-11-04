	.arch armv5te
	.eabi_attribute 23, 1
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"pi_1.c"
	.section	.rodata
	.align	2
.LC0:
	.ascii	"-- Programa PI_1  -  PID (%d) --\012\000"
	.text
	.align	2
	.global	_start
	.syntax unified
	.arm
	.fpu softvfp
	.type	_start, %function
_start:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #12
	str	r0, [sp, #4]
	bl	GARLIC_pid
	mov	r3, r0
	mov	r1, r3
	ldr	r0, .L3
	bl	GARLIC_printf
	mov	r0, #3
	bl	PI_1
	mov	r3, #0
	mov	r0, r3
	add	sp, sp, #12
	@ sp needed
	ldr	pc, [sp], #4
.L4:
	.align	2
.L3:
	.word	.LC0
	.size	_start, .-_start
	.section	.rodata
	.align	2
.LC1:
	.ascii	"\012-- Programa PI_1  -  PID (%d) --\012\000"
	.align	2
.LC2:
	.ascii	"(%d)\011No se ha podido Calcular Pi\012 Indica un a"
	.ascii	"rgumento positivo\012\000"
	.global	__aeabi_i2d
	.global	__aeabi_ddiv
	.global	__aeabi_dadd
	.global	__aeabi_dmul
	.global	__aeabi_d2ulz
	.global	__aeabi_ul2d
	.global	__aeabi_dsub
	.align	2
.LC3:
	.ascii	"PI Calculado es: %d.%d\012\000"
	.text
	.align	2
	.global	PI_1
	.syntax unified
	.arm
	.fpu softvfp
	.type	PI_1, %function
PI_1:
	@ args = 0, pretend = 0, frame = 56
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #60
	str	r0, [sp, #4]
	bl	GARLIC_pid
	mov	r3, r0
	mov	r1, r3
	ldr	r0, .L14
	bl	GARLIC_printf
	ldr	r3, [sp, #4]
	cmp	r3, #0
	bge	.L6
	bl	GARLIC_pid
	mov	r3, r0
	mov	r1, r3
	ldr	r0, .L14+4
	bl	GARLIC_printf
	mov	r3, #0
	b	.L7
.L6:
	mov	r2, #0
	mov	r3, #0
	strd	r2, [sp, #48]
	mov	r3, #1
	str	r3, [sp, #44]
	mov	r3, #0
	str	r3, [sp, #40]
	b	.L8
.L9:
	ldr	r3, [sp, #44]
	lsl	r3, r3, #1
	str	r3, [sp, #44]
	ldr	r3, [sp, #40]
	add	r3, r3, #1
	str	r3, [sp, #40]
.L8:
	ldr	r2, [sp, #40]
	ldr	r3, [sp, #4]
	cmp	r2, r3
	blt	.L9
	mov	r3, #0
	str	r3, [sp, #36]
	b	.L10
.L13:
	ldr	r3, [sp, #36]
	and	r3, r3, #1
	cmp	r3, #0
	bne	.L11
	ldr	r3, [sp, #36]
	lsl	r3, r3, #1
	add	r3, r3, #1
	mov	r0, r3
	bl	__aeabi_i2d
	mov	r2, r0
	mov	r3, r1
	mov	r0, #0
	ldr	r1, .L14+8
	bl	__aeabi_ddiv
	mov	r2, r0
	mov	r3, r1
	strd	r2, [sp, #24]
	b	.L12
.L11:
	ldr	r3, [sp, #36]
	lsl	r3, r3, #1
	add	r3, r3, #1
	mov	r0, r3
	bl	__aeabi_i2d
	mov	r2, r0
	mov	r3, r1
	mov	r0, #0
	ldr	r1, .L14+12
	bl	__aeabi_ddiv
	mov	r2, r0
	mov	r3, r1
	strd	r2, [sp, #24]
.L12:
	ldrd	r2, [sp, #24]
	ldrd	r0, [sp, #48]
	bl	__aeabi_dadd
	mov	r2, r0
	mov	r3, r1
	strd	r2, [sp, #48]
	ldr	r3, [sp, #36]
	add	r3, r3, #1
	str	r3, [sp, #36]
.L10:
	ldr	r2, [sp, #36]
	ldr	r3, [sp, #44]
	cmp	r2, r3
	blt	.L13
	mov	r2, #0
	ldr	r3, .L14+16
	ldrd	r0, [sp, #48]
	bl	__aeabi_dmul
	mov	r2, r0
	mov	r3, r1
	strd	r2, [sp, #48]
	ldrd	r0, [sp, #48]
	bl	__aeabi_d2ulz
	mov	r2, r0
	mov	r3, r1
	strd	r2, [sp, #16]
	ldrd	r0, [sp, #16]
	bl	__aeabi_ul2d
	mov	r2, r0
	mov	r3, r1
	ldrd	r0, [sp, #48]
	bl	__aeabi_dsub
	mov	r2, r0
	mov	r3, r1
	mov	r0, r2
	mov	r1, r3
	mov	r2, #0
	ldr	r3, .L14+20
	bl	__aeabi_dmul
	mov	r2, r0
	mov	r3, r1
	mov	r0, r2
	mov	r1, r3
	bl	__aeabi_d2ulz
	mov	r2, r0
	mov	r3, r1
	strd	r2, [sp, #8]
	ldr	r3, [sp, #16]
	ldr	r2, [sp, #8]
	mov	r1, r3
	ldr	r0, .L14+24
	bl	GARLIC_printf
	mov	r3, #0
.L7:
	mov	r0, r3
	add	sp, sp, #60
	@ sp needed
	ldr	pc, [sp], #4
.L15:
	.align	2
.L14:
	.word	.LC1
	.word	.LC2
	.word	1072693248
	.word	-1074790400
	.word	1074790400
	.word	1093567616
	.word	.LC3
	.size	PI_1, .-PI_1
	.ident	"GCC: (devkitARM release 46) 6.3.0"
