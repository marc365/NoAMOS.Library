******* Branch to interrupts
VblInit:
* Init couleurs
	bsr	FlInit
	bsr	ShInit
* Init mouse
	move.l	T_MouBank(a5),a0
	move.l	a0,T_MouDes(a5)
	move.w	2(a0),T_MouTY(a5)
	clr.w	T_MouXOld(a5)
	clr.w	T_MouYOld(a5)
	move.w	#-1,T_MouShow(a5)
* Branch to interrupts!
	bsr	Add_VBL
	rts

******* Branch CLEANLY VBL interrupts...
Add_VBL
	move.l	a6,-(sp)
	lea	T_VBL_Is(a5),a1
	move.b	#NT_INTERRUPT,Ln_Type(a1)
	move.b	#100,Ln_Pri(a1)
	clr.l	Ln_Name(a1)
	move.l	a5,IS_DATA(a1)
	lea	VBLIn(pc),a0
	move.l	a0,IS_CODE(a1)
	move.l	$4.w,a6
	move.l	#INTB_VERTB,d0
	jsr	_LVOAddIntServer(a6)
	move.l	(sp)+,a6
	rts

******* Delete CLEANLY VBL interrupts...
Rem_VBL
VBLEnd
	move.l	a6,-(sp)
	lea	T_VBL_Is(a5),a1
	tst.l	IS_CODE(a1)
	beq.s	.skip
	move.l	$4.w,a6
	move.l	#INTB_VERTB,d0
	jsr	_LVORemIntServer(a6)
.skip	move.l	(sp)+,a6
	rts

******* Entree des interruptions
VblIn:	movem.l	d2-d7/a2-a4,-(sp)
	lea	Circuits,a6
	move.l	a1,a5
* Makes interlace switches
	tst.w	T_InterBit(a5)
	beq.s	SIntX2
	lea	T_InterList(a5),a5
	move.l	(a5)+,d0
	beq.s	SIntX
	move.w	$4(a6),d6
SInt0	move.l	d0,a4			* Adresse ecran
	move.l	(a5)+,a3		* Adresse marqueur
	move.w	EcNPlan(a4),d5		* D5 Nb de plans
	subq.w	#1,d5
	move.l	(a3)+,d2
	beq.s	SInt4
SInt1	move.l	(a3)+,a0
	tst.w	d6
	bmi.s	SInt2
	move.w	EcTx(a4),d0
	lsr.w	#3,d0
	add.w	d0,a0
SInt2	move.w	d5,d1
	move.l	d2,a2
	lea	EcPhysic(a4),a1
SInt3	move.l	(a1)+,d0
	add.l	a0,d0
	move.w	d0,6(a2)
	swap	d0
	move.w	d0,2(a2)
	addq.l	#8,a2
	dbra	d1,SInt3
	move.l	(a3)+,d2
	bne.s	SInt1
SInt4	move.l	(a5)+,d0
	bne.s	SInt0
SIntX	move.l	W_Base(pc),a5
SIntX2

* Make the screen swaps
	lea	T_SwapList(a5),a0
	move.l	(a0),d0
	beq.s	SSwpX
	clr.l	(a0)+
SSwp1:	move.l	a0,a1
	move.l	d0,a4
	move.w	(a1)+,d1		* Nb de plans
	move.l	(a4)+,d0
	beq.s	SSwp4
SSwp2:	move.l	(a4)+,d3		* Decalage
	move.l	d0,a3
	move.l	a1,a2
	move.w	d1,d2
SSwp3:	move.l	(a2)+,d0
	add.l	d3,d0
	move.w	d0,6(a3)
	swap	d0
	move.w	d0,2(a3)
	addq.l	#8,a3
	dbra	d2,SSwp3
	move.l	(a4)+,d0
	bne.s	SSwp2
SSwp4:	lea	SwapL-4(a0),a0
	move.l	(a0)+,d0
	bne.s	SSwp1
SSwpX:

* Change the addresses of hard sprites
	move.l	T_HsChange(a5),d0
	beq.s	VblPaHs
	clr.l	T_HsChange(a5)
	bsr	HsPCop
VblPaHs:

* Mark the VBL
	addq.l	#1,T_VBLCount(a5)
	addq.l	#1,T_VBLTimer(a5)
	subq.w	#1,T_EveCpt(a5)
	bset	#BitVBL,T_Actualise(a5)

* Calls other routines
	lea	VblRout(a5),a4
	move.l	(a4)+,d0
	beq.s	VblPaCa
VblCall	move.l	d0,a0
	jsr	(a0)
	move.l	(a4)+,d0
	bne.s	VblCall
VblPaCa

* Display the mouse
	bsr	MousInt

* Colours
	lea	T_CopMark(a5),a3
	bsr	Shifter
	bsr	FlInt
	bsr	FadeI

* Animations
	move.w	T_SyncOff(a5),d0
	bne.s	PaSync
	bsr	Animeur
PaSync:
	movem.l	(sp)+,d2-d7/a2-a4
	lea	$DFF000,a0
	moveq	#0,d0
	rts

******* WAIT VBL D0, multitache
WVbl_D0	movem.l	d0-d1/a0-a1/a6,-(sp)
	move.w	d0,-(sp)
.Lp	move.l	T_GfxBase(a5),a6
	jsr	_LVOWaitTOF(a6)
	subq.w	#1,(sp)
	bne.s	.Lp
	addq.l	#2,sp
	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts

******* WAIT VBL
WVbl:	move.l	T_VblCount(a5),d0
WVbl1:	cmp.l	T_VblCount(a5),d0
	beq.s	WVbl1
	moveq	#0,d0
	rts

