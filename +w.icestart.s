; Icestart: branch system functions only.
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
IceStart
	move.l	a6,-(sp)

	clr.w	T_WVersion(a5)		Par defaut
	cmp.l	#"V2.0",d0		Le magic
	bne.s	.Nomagic
	move.w	d1,T_WVersion(a5)	La version d'AMOS
.Nomagic

	lea	W_Base(pc),a0
	move.l	a5,(a0)
	lea	SyIn(pc),a0
	move.l	a0,T_SyVect(a5)
	bsr	WMemInit

; Recherche et stoppe les programmes AMOS lancés... (si AMOSPro V2.0)
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	cmp.w	#$0200,T_WVersion(a5)
	bcs.s	.No20
	move.l	$4.w,a6
	jsr	_LVOForbid(a6)
	lea	TaskName(pc),a1
	jsr	_LVOFindTask(a6)
	tst.l	d0
	beq.s	.skip
	move.l	d0,a0
	move.l	10(a0),a1
	move.b	#"S",(a1)		* STOP!!!
	move.l	a1,T_Stopped(a5)
.skip	jsr	_LVOPermit(a6)
; Change son propre nom...
	sub.l	a1,a1
	jsr	_LVOFindTask(a6)
	move.l	d0,a0
	move.l	d0,T_MyTask(a5)
	move.l	10(a0),T_OldName(a5)
	lea	TaskName(pc),a1
	move.l	a1,10(a0)
	move.l	a5,$58(a0)		Adresse des datas...
; Fini!
.No20	move.l	(sp)+,a6
	move.l	#"W2.0",d0		Retourne des magic
	move.w	#$0200,d1
	rts

TaskName	 dc.b	 " AMOS",0

