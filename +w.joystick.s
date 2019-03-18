**********************************************************
*	JOYSTICK / d1= # de port
**********************************************************
ClJoy:	tst.b	T_AMOSHere(a5)
	beq.s	JoyNo
	moveq	#6,d0			;# du bit de FEU
	add.w	d1,d0
	lea	Circuits,a0
	lsl.w	#1,d1
	move.w	10(a0,d1.w),d2
; Prend le bouton
	clr.w	d1
	btst	d0,CiaAPrA
	bne.s	Joy1
	bset	#4,d1
; Teste les directions
Joy1:	lea	JoyTab(pc),a0
	lsl.b	#6,d2
	lsr.w 	#6,d2
	and.w	#$000F,d2
	or.b	0(a0,d2.w),d1
Joy2	moveq	#0,d0
	rts
JoyNo	moveq	#0,d1
	bra.s	Joy2
JoyTab:	dc.b 	%0000,%0010,%1010,%1000,%0001,%0000,%0000,%1001
	dc.b 	%0101,%0000,%0000,%0000,%0100,%0110,%0000,%0000


