/*
 * controle.asm
 *
 *  Created: 19/05/2023 17:29:51
 *   Author: romai
 */ 
 .dseg

 in_menu:		.byte 1

 mod_prescaler: .byte 1
 u_presc:		.byte 1

 detected:		.byte 1

 ;morse variables
 nb_empty:		.byte 1
 nb_dot:		.byte 1

 ;decoding flags
 flag_reg:		.byte 1
 current_smb:	.byte 1

 smb_buffer: .byte 1

 ;letter buffer
 s0: .byte 1
 s1: .byte 1
 s2: .byte 1
 s3: .byte 1

 ;word buffer
 l0: .byte 1
 l1: .byte 1
 l2: .byte 1
 l3: .byte 1
 l4: .byte 1
 l5: .byte 1
 l6: .byte 1
 l7: .byte 1
 l8: .byte 1
 l9: .byte 1

 tmpa0: .byte 1
