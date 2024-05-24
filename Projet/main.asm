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

.equ DOT  = 46
.equ DASH = 95

.equ NB_SHORT = 1
.equ NB_DASH = 3
.equ NB_NEXT_SYMBOL = 1
.equ NB_NEXT_LETTER = 3
.equ NB_NEXT_WORD = 7

.equ SHORTF		= 0
.equ DASHF		= 1
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
	sts tmpa0, a0
	OUTI PORTB, 0x00
	lds _w, detected
	cpi _w, 0
	brne new_dot

	new_empty:
	clr _w
	sts nb_dot, _w			; clear nb_dot
	lds a0, smb_buffer		; load symbol buffer in a0
	lds _w, current_smb		; load current buffer in _w
	cpi _w, 0
	brne PC+3
	sts s0, a0
	rjmp inc_current_smb
	cpi _w, 1
	brne PC+3
	sts s1, a0
	rjmp inc_current_smb
	cpi _w, 2
	brne PC+3
	sts s2, a0
	rjmp inc_current_smb
	cpi _w, 3
	brne PC+3
	sts s3, a0
	rjmp inc_current_smb

	inc_current_smb:
	lds _w, current_smb
	cpi _w, 3
	breq PC+3
	inc _w
	sts current_smb, _w
	lds _w, nb_empty
	inc _w
	sts nb_empty, _w
	clr _w
	sts smb_buffer, _w
	rjmp end_timer

	new_dot:
	clr _w
	sts nb_empty, _w
	lds _w, nb_dot
	inc _w
	sts nb_dot, _w
	cpi _w, 3
	brsh PC+3
	ldi _w, DOT
	rjmp PC+2
	ldi _w, DASH
	sts smb_buffer, _w

	end_timer:
	clr _w
	sts detected, _w
	lds a0, tmpa0
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
	sts current_smb, w
	sts smb_buffer, w
	ldi w, SPACE
	sts s0, w
	sts s1, w
	sts s2, w
	sts s3, w
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
	rcall LCD_clear
	rcall LCD_home
	rjmp lecture

check_menu:
	;check menu control variable
	lds w, in_menu
	sbrc w, 0
	rjmp menu
	rjmp lecture

lecture:
	READSHARP				; read distance sensor
	OUTI PORTB, 0xff
	/*rcall clr_a
	lds a0, s0
	rcall clr_b
	lds b0, s1
	rcall clr_c
	lds c0, s2
	rcall clr_d
	lds d0, s3

	PRINTF LCD
	.db CR, CR, FCHAR, a, FCHAR, b, FCHAR, c, FCHAR, d, "         ", 0*/

	rcall clr_a
	lds a0, smb_buffer
	rcall clr_b
	lds b0, current_smb

	rcall LCD_clear
	rcall LCD_home
	PRINTF LCD
	.db CR, CR, "smbfr: ", FDEC2, a, "     ", LF

	;delay
	WAIT_MS 10
	rjmp check_menu
