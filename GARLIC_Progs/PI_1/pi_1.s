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
	.align	2
.LC5:
	.ascii	"%0Caracteres personalizados:\012\000"
	.align	2
.LC6:
	.ascii	"%0\\x80 %1 \\x81 %2 \\x82 %3 \\x83 %0 \\x84 %1 \\x8"
	.ascii	"5 %2 \\x86 %3 \\x87\012\000"
	.text
	.align	2
	.global	_start
	.syntax unified
	.arm
	.fpu softvfp
	.type	_start, %function
_start:
	@ args = 0, pretend = 0, frame = 120
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #124
	str	r0, [sp, #4]
	bl	GARLIC_pid
	mov	r3, r0
	mov	r1, r3
	ldr	r0, .L38
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
	str	r3, [sp, #116]
	mov	r3, #0
	str	r3, [sp, #112]
	mov	r3, #1
	str	r3, [sp, #108]
	mov	r3, #0
	str	r3, [sp, #104]
	b	.L4
.L5:
	ldr	r3, [sp, #108]
	lsl	r3, r3, #1
	str	r3, [sp, #108]
	ldr	r3, [sp, #104]
	add	r3, r3, #1
	str	r3, [sp, #104]
.L4:
	ldr	r2, [sp, #104]
	ldr	r3, [sp, #4]
	cmp	r2, r3
	blt	.L5
	ldr	r1, [sp, #108]
	ldr	r0, .L38+4
	bl	GARLIC_printf
	mov	r3, #0
	str	r3, [sp, #100]
	b	.L6
.L9:
	ldr	r3, [sp, #100]
	lsl	r3, r3, #1
	add	r3, r3, #1
	mov	r1, r3
	add	r3, sp, #76
	add	r2, sp, #80
	mov	r0, #1
	bl	GARLIC_divmod
	ldr	r3, [sp, #76]
	cmp	r3, #0
	bne	.L7
	mov	r3, #1
	str	r3, [sp, #96]
	b	.L8
.L7:
	mvn	r3, #0
	str	r3, [sp, #96]
.L8:
	ldr	r3, [sp, #96]
	ldr	r2, [sp, #80]
	mul	r3, r2, r3
	ldr	r2, [sp, #116]
	add	r3, r2, r3
	str	r3, [sp, #116]
	ldr	r3, [sp, #96]
	ldr	r2, [sp, #76]
	mul	r3, r2, r3
	ldr	r2, [sp, #112]
	add	r3, r2, r3
	str	r3, [sp, #112]
	ldr	r3, [sp, #100]
	add	r3, r3, #1
	mov	r1, r3
	ldr	r0, .L38+8
	bl	GARLIC_printf
	ldr	r2, [sp, #112]
	ldr	r1, [sp, #116]
	ldr	r0, .L38+12
	bl	GARLIC_printf
	ldr	r3, [sp, #100]
	add	r3, r3, #1
	str	r3, [sp, #100]
.L6:
	ldr	r2, [sp, #100]
	ldr	r3, [sp, #108]
	cmp	r2, r3
	blt	.L9
	ldr	r3, [sp, #116]
	lsl	r3, r3, #2
	str	r3, [sp, #116]
	ldr	r3, [sp, #112]
	lsl	r3, r3, #2
	str	r3, [sp, #112]
	mov	r3, #0
	str	r3, [sp, #92]
	b	.L10
.L11:
	add	r2, sp, #12
	ldr	r3, [sp, #92]
	add	r3, r2, r3
	mvn	r2, #0
	strb	r2, [r3]
	ldr	r3, [sp, #92]
	add	r3, r3, #1
	str	r3, [sp, #92]
.L10:
	ldr	r3, [sp, #92]
	cmp	r3, #63
	ble	.L11
	mov	r3, #0
	strb	r3, [sp, #21]
	mov	r3, #0
	strb	r3, [sp, #22]
	mov	r3, #0
	strb	r3, [sp, #25]
	mov	r3, #0
	strb	r3, [sp, #26]
	mov	r3, #0
	strb	r3, [sp, #29]
	mov	r3, #0
	strb	r3, [sp, #30]
	mov	r3, #0
	strb	r3, [sp, #33]
	mov	r3, #0
	strb	r3, [sp, #34]
	mov	r3, #0
	strb	r3, [sp, #53]
	mov	r3, #0
	strb	r3, [sp, #58]
	mov	r3, #0
	strb	r3, [sp, #62]
	mov	r3, #0
	strb	r3, [sp, #63]
	mov	r3, #0
	strb	r3, [sp, #64]
	mov	r3, #0
	strb	r3, [sp, #65]
	ldr	r2, [sp, #112]
	ldr	r1, [sp, #116]
	ldr	r0, .L38+16
	bl	GARLIC_printf
	mov	r3, #0
	str	r3, [sp, #88]
	b	.L12
.L36:
	mov	r3, #0
	str	r3, [sp, #84]
	b	.L13
.L35:
	ldr	r3, [sp, #88]
	cmp	r3, #0
	bne	.L14
	add	r2, sp, #12
	ldr	r3, [sp, #84]
	add	r3, r2, r3
	mvn	r2, #85
	strb	r2, [r3]
	b	.L15
.L14:
	ldr	r3, [sp, #88]
	cmp	r3, #1
	bne	.L16
	add	r2, sp, #12
	ldr	r3, [sp, #84]
	add	r3, r2, r3
	mov	r2, #85
	strb	r2, [r3]
	b	.L15
.L16:
	ldr	r3, [sp, #88]
	cmp	r3, #2
	bne	.L17
	ldr	r3, [sp, #84]
	cmp	r3, #31
	bgt	.L18
	add	r2, sp, #12
	ldr	r3, [sp, #84]
	add	r3, r2, r3
	mvn	r2, #0
	strb	r2, [r3]
	b	.L15
.L18:
	add	r2, sp, #12
	ldr	r3, [sp, #84]
	add	r3, r2, r3
	mov	r2, #0
	strb	r2, [r3]
	b	.L15
.L17:
	ldr	r3, [sp, #88]
	cmp	r3, #3
	bne	.L20
	ldr	r2, [sp, #84]
	asr	r3, r2, #31
	lsr	r3, r3, #29
	add	r2, r2, r3
	and	r2, r2, #7
	sub	r3, r2, r3
	cmp	r3, #3
	bgt	.L21
	add	r2, sp, #12
	ldr	r3, [sp, #84]
	add	r3, r2, r3
	mvn	r2, #0
	strb	r2, [r3]
	b	.L15
.L21:
	add	r2, sp, #12
	ldr	r3, [sp, #84]
	add	r3, r2, r3
	mov	r2, #0
	strb	r2, [r3]
	b	.L15
.L20:
	ldr	r3, [sp, #88]
	cmp	r3, #4
	bne	.L23
	ldr	r3, [sp, #84]
	add	r2, r3, #7
	cmp	r3, #0
	movlt	r3, r2
	movge	r3, r3
	asr	r3, r3, #3
	and	r3, r3, #1
	cmp	r3, #0
	bne	.L24
	add	r2, sp, #12
	ldr	r3, [sp, #84]
	add	r3, r2, r3
	mvn	r2, #0
	strb	r2, [r3]
	b	.L15
.L24:
	add	r2, sp, #12
	ldr	r3, [sp, #84]
	add	r3, r2, r3
	mov	r2, #0
	strb	r2, [r3]
	b	.L15
.L23:
	ldr	r3, [sp, #88]
	cmp	r3, #5
	bne	.L26
	ldr	r2, [sp, #84]
	asr	r3, r2, #31
	lsr	r3, r3, #29
	add	r2, r2, r3
	and	r2, r2, #7
	sub	r3, r2, r3
	and	r3, r3, #1
	cmp	r3, #0
	bne	.L27
	add	r2, sp, #12
	ldr	r3, [sp, #84]
	add	r3, r2, r3
	mvn	r2, #0
	strb	r2, [r3]
	b	.L15
.L27:
	add	r2, sp, #12
	ldr	r3, [sp, #84]
	add	r3, r2, r3
	mov	r2, #0
	strb	r2, [r3]
	b	.L15
.L26:
	ldr	r3, [sp, #88]
	cmp	r3, #6
	bne	.L29
	ldr	r3, [sp, #84]
	sub	r3, r3, #24
	cmp	r3, #7
	bls	.L30
	ldr	r3, [sp, #84]
	sub	r3, r3, #32
	cmp	r3, #7
	bls	.L30
	ldr	r2, [sp, #84]
	asr	r3, r2, #31
	lsr	r3, r3, #29
	add	r2, r2, r3
	and	r2, r2, #7
	sub	r3, r2, r3
	cmp	r3, #3
	beq	.L30
	ldr	r2, [sp, #84]
	asr	r3, r2, #31
	lsr	r3, r3, #29
	add	r2, r2, r3
	and	r2, r2, #7
	sub	r3, r2, r3
	cmp	r3, #4
	bne	.L31
.L30:
	add	r2, sp, #12
	ldr	r3, [sp, #84]
	add	r3, r2, r3
	mov	r2, #0
	strb	r2, [r3]
	b	.L15
.L31:
	add	r2, sp, #12
	ldr	r3, [sp, #84]
	add	r3, r2, r3
	mvn	r2, #0
	strb	r2, [r3]
	b	.L15
.L29:
	ldr	r3, [sp, #88]
	cmp	r3, #7
	bne	.L15
	ldr	r3, [sp, #84]
	add	r3, r3, #7
	cmp	r3, #14
	bls	.L33
	ldr	r3, [sp, #84]
	sub	r3, r3, #56
	cmp	r3, #7
	bls	.L33
	ldr	r3, [sp, #84]
	and	r3, r3, #7
	cmp	r3, #0
	beq	.L33
	ldr	r2, [sp, #84]
	asr	r3, r2, #31
	lsr	r3, r3, #29
	add	r2, r2, r3
	and	r2, r2, #7
	sub	r3, r2, r3
	cmp	r3, #7
	bne	.L34
.L33:
	add	r2, sp, #12
	ldr	r3, [sp, #84]
	add	r3, r2, r3
	mov	r2, #0
	strb	r2, [r3]
	b	.L15
.L34:
	add	r2, sp, #12
	ldr	r3, [sp, #84]
	add	r3, r2, r3
	mvn	r2, #0
	strb	r2, [r3]
.L15:
	ldr	r3, [sp, #84]
	add	r3, r3, #1
	str	r3, [sp, #84]
.L13:
	ldr	r3, [sp, #84]
	cmp	r3, #63
	ble	.L35
	ldr	r3, [sp, #88]
	and	r3, r3, #255
	sub	r3, r3, #128
	and	r3, r3, #255
	add	r2, sp, #12
	mov	r1, r2
	mov	r0, r3
	bl	GARLIC_setChar
	ldr	r3, [sp, #88]
	add	r3, r3, #1
	str	r3, [sp, #88]
.L12:
	ldr	r3, [sp, #88]
	cmp	r3, #7
	ble	.L36
	ldr	r0, .L38+20
	bl	GARLIC_printf
	ldr	r0, .L38+24
	bl	GARLIC_printf
	mov	r3, #0
	mov	r0, r3
	add	sp, sp, #124
	@ sp needed
	ldr	pc, [sp], #4
.L39:
	.align	2
.L38:
	.word	.LC0
	.word	.LC1
	.word	.LC2
	.word	.LC3
	.word	.LC4
	.word	.LC5
	.word	.LC6
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
