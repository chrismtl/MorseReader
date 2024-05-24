/*
 * ad_ssh.asm
 *
 *  Created: 19/05/2023 16:13:56
 *   Author: romai
 */

.macro READSHARP
	clr		r23
	sbi		ADCSR,ADSC
	WB0		r23,0
	in		a0,ADCL
	in		a1,ADCH
	cpi a1, 0
	breq read_end
	isthere:
	ldi w, 0x01
	sts detected, w
	rjmp read_end
	read_end:
	clr w
.endmacro

