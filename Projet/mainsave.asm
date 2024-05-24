;
; Projet.asm
;
; Created: 19/05/2023 15:54:57
; Author : romai
;

 .include "macros.asm"
 .include "definitions.asm"

;=== definitions ===
.equ REFRESH_RATE = 93
.equ INIT_PRESCALER = 5
.equ EMPTYMAX = 224

.equ SHORT = 1
.equ LONG = 2

.equ NB_SHORT = 1
.equ NB_LONG = 3
.equ NB_NEXT_SYMBOL = 1
.equ NB_NEXT_LETTER = 3
.equ NB_NEXT_WORD = 7

.equ SHORTF		= 0
.equ LONGF		= 1
.equ NSMBF	= 2
.equ NLTRF	= 3
.equ NWRDF	= 4

.cseg
.org	0
	jmp reset
	
.org INT0addr
	jmp int0_isr

.org INT1addr
	jmp int1_isr

.org OVF0addr
	jmp tim0_ovf

.org ADCCaddr
	jmp ADCCaddr_sra

.org	0x30

int0_isr:
	in _sreg, SREG

	ser _w
	sts in_menu, _w

	out SREG, _sreg
	reti

int1_isr:
	in _sreg, SREG

	clr _w
	sts in_menu, _w

	out SREG, _sreg
	reti

tim0_ovf:
	in _sreg, SREG
	OUTI PORTB, 0x00
	lds _w, detected
	cpi _w, 0
	brne dot

	empty:
	lds _w, nb_empty
	cpi _w, 1
	brsh inc_nb_empty
	;analyse previous dots
	lds _w, nb_dot
	cpi _w, NB_LONG
	brsh set_long_flag
	cpi _w, NB_SHORT
	brsh set_short_flag
	rjmp nb_dot_reset

	set_long_flag:
	lds _w, flag_reg
	ori _w, (1<<LONGF)
	sts flag_reg, _w
	rjmp nb_dot_reset

	set_short_flag:
	lds _w, flag_reg
	ori _w, (1<<SHORTF)
	sts flag_reg, _w
	rjmp nb_dot_reset

	nb_dot_reset:
	clr _w
	sts nb_dot, _w

	inc_nb_empty:
	lds _w, nb_empty
	cpi _w, 7
	breq end_timer
	cpi _w, 3
	brne PC+7
	clr _w
	sts s0, _w
	sts s1, _w
	sts s2, _w
	sts s3, _w
	sts s4, _w
	lds _w, nb_empty
	inc _w
	sts nb_empty, _w
	rjmp end_timer

	dot:
	lds _w, nb_dot
	cpi _w, 1
	brsh inc_nb_dot
	;analyse previous spaces
	lds _w, nb_empty
	cpi _w, NB_NEXT_LETTER
	brsh set_nltr_flag
	cpi _w, NB_NEXT_SYMBOL
	brsh set_nsmb_flag
	rjmp nb_empty_reset
	
	set_nltr_flag:
	lds _w, flag_reg
	ori _w, (1<<NLTRF)
	sts flag_reg, _w
	rjmp nb_empty_reset

	set_nsmb_flag:
	lds _w, flag_reg
	ori _w, (1<<NSMBF)
	sts flag_reg, _w
	rjmp nb_empty_reset

	nb_empty_reset:
	clr _w
	sts nb_empty, _w

	inc_nb_dot:
	lds _w, nb_dot
	cpi _w, 3
	breq end_timer
	inc _w
	sts nb_dot, _w

	end_timer:
	clr _w
	sts detected, _w
	out SREG, _sreg
	reti

ADCCaddr_sra :
	ldi r23,0x01
	reti

 .include "encoder.asm"
 .include "sharp.asm"

reset :
	LDSP	RAMEND
	OUTI	DDRB,0xff
	OUTI	DDRE,0xff
	sei
	rcall	LCD_init
	;rcall	encoder_init
	OUTI	ADCSR,(1<<ADEN) + (1<<ADIE) + 6
	OUTI	ADMUX,3

	sei
	;config int0
	in w, EIMSK
	ori w, 0b00000001
	andi w, 0b11111101
	out EIMSK, w

	;config timer0 overflow
	OUTI ASSR,(1<<AS0)
	OUTI TCCR0, INIT_PRESCALER
	
	rcall LCD_clear
	rcall LCD_home

	ldi w, INIT_PRESCALER
	sts mod_prescaler, w
	
	ser w
	sts in_menu, w
	clr w
	sts flag_reg, w
	sts s0, w
	sts s1, w
	sts s2, w
	sts s3, w
	sts s4, w
	rjmp  menu

.include "lcd.asm"
.include "printf.asm"

clr_a:
	clr a0
	clr a1
	clr a2
	clr a3
	ret
clr_b:
	clr b0
	clr b1
	clr b2
	clr b3
	ret
clr_c:
	clr c0
	clr c1
	clr c2
	clr c3
	ret
clr_d:
	clr d0
	clr d1
	clr d2
	clr d3
	ret

menu:
	in w, TIMSK
	andi w, 0b11111110
	out TIMSK, w

	in w, EIMSK
	ori w, 0b00000010
	andi w, 0b11111110
	out EIMSK, w

	update_prescaler:
	/*Change prescaler*/
	//rcall encoder
	lds w, mod_prescaler
	out TCCR0, w

	rcall clr_a
	mov a0, w
	PRINTF LCD
	.db CR, CR, "prescaler: ", FDEC2, a, " ", 0

	WAIT_MS 10
	lds w, in_menu
	sbrc w, 0
	rjmp update_prescaler

	in w, EIMSK
	ori w, 0b00000001
	andi w, 0b11111101
	out EIMSK, w
	in w, TIMSK
	ori w,(1<<TOIE0)
	out TIMSK, w
	clr w
	sts nb_dot, w
	sts nb_empty, w
	sts flag_reg, w
	sts current_smb, w
	rjmp lecture

check_menu:
	;check menu control variable
	lds w, in_menu
	sbrc w, 0
	rjmp menu
	rjmp lecture

write_short:
	rcall clr_b
	ldi b0, SHORT
	
	lds w, current_smb
	cpi w, 0
	brne PC+3
	sts s0, b0
	rjmp clr_shortf
	cpi w, 1
	brne PC+3
	sts s1, b0
	rjmp clr_shortf
	cpi w, 2
	brne PC+3
	sts s2, b0
	rjmp clr_shortf
	cpi w, 3
	brne PC+3
	sts s3, b0
	rjmp clr_shortf
	cpi w, 4
	brne PC+2
	sts s4, b0
	
	clr_shortf:
	andi w, ~(1<<SHORTF)
	sts flag_reg, w
	rjmp print_decode

write_long:
	rcall clr_b
	ldi b0, LONG
	
	lds w, current_smb
	cpi w, 0
	brne PC+3
	sts s0, b0
	rjmp clr_longf
	cpi w, 1
	brne PC+3
	sts s1, b0
	rjmp clr_longf
	cpi w, 2
	brne PC+3
	sts s2, b0
	rjmp clr_longf
	cpi w, 3
	brne PC+3
	sts s3, b0
	rjmp clr_longf
	cpi w, 4
	brne PC+2
	sts s4, b0

	clr_longf:
	andi w, ~(1<<LONGF)
	sts flag_reg, w
	rjmp print_decode

next_symbol:
	rcall clr_b
	lds w, current_smb
	cpi w, 4
	breq nsmb_flag_reset
	inc w
	sts current_smb, w
	nsmb_flag_reset:
	andi w, ~(1<<NSMBF)
	sts flag_reg, w
	rjmp print_decode
	
next_letter:
	clr w
	sts current_smb, w
	sts s0, w
	sts s1, w
	sts s2, w
	sts s3, w
	sts s4, w
	andi w, ~(1<<NLTRF)
	sts flag_reg, w
	rjmp print_decode

next_word:
	andi w, ~(1<<NWRDF)
	sts flag_reg, w
	rjmp print_decode


lecture:
	READSHARP				; read distance sensor

	;decoding treatment
	lds w, flag_reg
	sbrc w, SHORTF
	rjmp write_short
	sbrc w, LONGF
	rjmp write_long
	sbrc w, NSMBF
	rjmp next_symbol
	sbrc w, NLTRF
	rjmp next_letter
	
	print_decode:
	lds w, flag_reg
	com w
	out PORTB, w
	rcall clr_a
	rcall clr_b
	rcall clr_c
	rcall clr_d
	lds a0, s0
	lds b0, s1
	lds c0, s2
	lds d0, s3

	rcall LCD_home
	PRINTF LCD
	.db CR, CR, FDEC2, a, FDEC2, b, FDEC2, c, FDEC2, d, "         ", 0

	;delay
	WAIT_MS 10
	rjmp check_menu
