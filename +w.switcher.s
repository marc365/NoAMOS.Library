Switcher	dc.b	"_Switcher AMOS_",0

NTx:		equ 480
NTy:		equ 12
NNp:		equ 1
NewScreen:	dc.w 0,0,NTx,NTy,NNp
		dc.b 1,0
		dc.w %0010000000000000,%00000110
		dc.l 0,0,0,0
		ds.b	16
		even
***********************************************************

; 	Patch on LOADVIEW if AMOS TO FRONT if AA
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
AMOS_LoadView
	tst.b	0.l			T_AMOSHere, modify during the patch...
	bne.s	.Wb
	move.l	Old_LoadView(pc),-(sp)
.Wb	rts
Old_LoadView	dc.l	0       Here and not elsewhere ...

; AMOS / WORKBENCH
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	D1=0	> 	Workbench
;	D1>0	>	AMOS
;	D1<0	>   Nothing (find value)
;	Retour D1= AMOS ici(-1), WB ici (0)
TAMOSWb
	tst.w	d1
	beq	.ToWB
	bmi	.Return

; 	Back to AMOS
; ~~~~~~~~~~~~~~~~~~
.ToAMOS	tst.b	T_AMOSHere(a5)
	bne	.Return
	move.b	#-1,T_AMOSHere+1(a5)        Code Prohibiting Requests

; Load View(0) + WaitTOF si AA
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	btst	#WFlag_LoadView,T_WFlags(a5)
	beq.s	.PaAA0
	movem.l	d0-d3/a0-a2/a6,-(sp)

	move.l	T_IntBase(a5),a6        Opens a LOWRES screen

	btst	#WFlag_WBClosed,T_WFlags(a5)	If WB closes, close it
	beq.s	.NoWB
	jsr	_LVOCloseWorkBench(a6)
.NoWB
	lea	NewScreen(pc),a0
	jsr	_LVOOpenScreen(a6)
	move.l	d0,T_IntScreen(a5)
	sub.l	a1,a1
	move.l	T_GfxBase(a5),a6
	jsr	_LVOLoadView(a6)
	jsr	_LVOWaitTOF(a6)
	move.w	$dff07c,d0
	cmp.b	#$f8,d0				AA Chipset?
	bne.s	.NoBug
	move.w	#0,$dff1fc			Sprite resolution
	move.w	#%0000110000000000,$dff106	Sprite width / DualPF palette
.NoBug

	movem.l	(sp)+,d0-d3/a0-a2/a6
.PaAA0
	lea	Circuits,a0         Reset the circuits
	move.w	#$8080,JoyTest(a0)
	move.l 	T_CopPhysic(a5),$80(a0)
	clr.w 	$88(a0)
	move.b	#-1,T_AMOSHere(a5)      AMOS in front!
	clr.b	T_AMOSHere+1(a5)        Flip ends!
	bra.s	.Return

; 	Goto workbench
; ~~~~~~~~~~~~~~~~~~~~
.ToWB	tst.b	T_AMOSHere(a5)
	beq.s	.Return
	clr.b	T_AMOSHere(a5)          AMOS in background
	move.b	#-1,T_AMOSHere+1(a5)        Code forbidding requesters

	move.w	T_OldDma(a5),$Dff096        Returns the chips
	move.l	T_GfxBase(a5),a0
	move.l 	38(a0),$dff080
	clr.w	$dff088

; Clear screen if AA
; ~~~~~~~~~~~~~~~~~~~~
	btst	#WFlag_LoadView,T_WFlags(a5)
	beq.s	.PaAA1
	movem.l	d0-d3/a0-a2/a6,-(sp)
	move.l	T_IntBase(a5),a6		Close Screen
	btst	#WFlag_WBClosed,T_WFlags(a5)    If WB closes, reopen it!
	beq.s	.NoBW
	jsr	_LVOOpenWorkBench(a6)
.NoBW
	move.l	T_IntScreen(a5),a0		Close screen
	jsr	_LVOCloseScreen(a6)
	move.l	T_GfxBase(a5),a6
	jsr	_LVOWaitTOF(a6)
	movem.l	(sp)+,d0-d3/a0-a2/a6
.PaAA1
	clr.b	T_AMOSHere+1(a5)		Flip Out!

; Returns the current state
; ~~~~~~~~~~~~~~~~~~~~~~
.Return	move.b	T_AMOSHere(a5),d1
	ext.w	d1
	ext.l	d1
	moveq	#0,d0
	rts

; Verify AMOS / WB if AA
; ~~~~~~~~~~~~~~~~~~~~~~~
	bclr	#WFlag_AmigaA,T_WFlags(a5)
	beq.s	.NoFlip
	moveq	#0,d1
	tst.b	T_AMOSHere(a5)
	bne.s	.Wb
	moveq	#1,d1
.Wb	bsr	TAMOSWb
.NoFlip
; Sending fake messages to the WB, in case of blank
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l	$4.w,a0
	cmp.w	#36,$14(a0)
	bcs.s	.Noev
	subq.w	#1,T_FakeEventCpt(a5)
	bpl.s	.Noev
	move.w	#50*2,T_FakeEventCpt(a5)
	tst.b	T_AMOSHere(a5)
	beq.s	.Noev
	bsr	WSend_FakeEvent
.Noev
; Verifies inhibition
; ~~~~~~~~~~~~~~~~~~~~
	move.l	T_MyTask(a5),a0
	move.l	10(a0),a0
	cmp.b	#"S",(a0)
	bne.s	.Skip
	bsr	AMOS_Stopped
.Skip	rts

;	This AMOS is inhibited by a first!
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
AMOS_Stopped
	movem.l	a0-a6/d0-d7,-(sp)
	move.l	a0,a4
; Returns the WB / Stop the interrupts
	move.w	#-1,T_Inhibit(a5)
	moveq	#-1,d1
	bsr	TAMOSWb
	move.w	d1,d7
	moveq	#0,d1
	bsr	TAMOSWb
; Stop interrupts
	bsr	Rem_VBL
; Stops sound
	move.w	#$000F,$Dff096
; Change le "S"top en "W"
	move.b	#"W",(a4)
; Wait until it turns back into " "
.Wait	move.l	T_GfxBase(a5),a6
	jsr	_LVOWaitTOF(a6)
	cmp.b	#"W",(a4)
	beq.s	.Wait
; Returns the program...
	bsr	Add_VBL
	tst.w	d7
	beq.s	.Skip
	moveq	#1,d1
	bsr	TAMOSWb
.Skip	clr.w	T_Inhibit(a5)
	movem.l	(sp)+,a0-a6/d0-d7
	rts

;   Sends a signal to AMOS_Switcher (D3 = signal)
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Send_Switcher
	lea	Switcher(pc),a1
	move.l	$4.w,a6
	jsr	_LVOFindTask(a6)
	tst.l	d0
	beq.s	.PaSwi
	move.l	d0,a1
	moveq	#0,d0
	bset	d3,d0
	jsr	_LVOSignal(a6)
.PaSwi	rts
