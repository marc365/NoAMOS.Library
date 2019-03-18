******* SET PATTERN ecran courant!
SPat:	movem.l	d1-d7/a0-a6,-(sp)
* Efface l'ancien
	bsr	EffPat
* Met le nouveau
	tst.w	d1
	beq	SPatX
	bmi.s	SPat1
* Patterns charge avec la banque!
	move.l	T_MouBank(a5),a2
	moveq	#4,d2
	bsr	SoMouse
	bmi	SPatE
	subq.w	#1,d1
	beq.s	SPat2
	move.w	d1,d2
	bsr	SoMouse
	bmi	SPatE
	bra.s	SPat2
* Patterns dans la banque de sprites!
SPat1:	move.l	T_SprBank(a5),d0
	beq	SPatX
	move.l	d0,a2
	neg.w	d1
	cmp.w	(a2)+,d1
	bhi	SPatX
	lsl.w	#3,d1
	move.l	-8(a2,d1.w),d0
	beq	SPatX
	move.l	d0,a2
******* Change!
SPat2:	move.w	(a2)+,d4
	move.w	(a2)+,d5
	move.w	(a2)+,d6
	addq.l	#4,a2
	moveq	#1,d0
	moveq	#0,d3
SPat3:	cmp.w	d5,d0			* Cherche le multiple de 8 <= TY
	beq.s	SPat5
	bcc.s	SPat4
	lsl.w	#1,d0
	addq.w	#1,d3
	cmp.w	#8,d3
	bcs.s	SPat3
	bra.s	SPatE
SPat4:	subq.w	#1,d3
	beq.s	SPatE
	lsr.w	#1,d0
SPat5:	move.w	d0,d7
	cmp.w	#1,d6
	beq.s	SPat6
	neg.b	d3
SPat6:	lsl.w	#1,d0
	mulu	d6,d0
	move.w	d0,d1
	bsr	ChipMm
	beq	SPatE
	move.l	T_EcCourant(a5),a0	* Poke!
	move.l	d0,EcPat(a0)
	move.w	d1,EcPatL(a0)
	move.b	d3,EcPatY(a0)
	move.l	T_RastPort(a5),a0
	move.l	d0,8(a0)
	move.b	d3,29(a0)
* Copie le motif
	move.l	d0,a1
	subq.w	#1,d6
	lsl.w	#1,d2
	lsl.w	#1,d4
	mulu	d4,d5
	subq.w	#1,d7
SPat7:	move.w	d7,d3
	move.l	a2,a0
SPat8:	move.w	(a0),(a1)+
	add.w	d4,a0
	dbra	d3,SPat8
SPat9:	add.w	d5,a2
	dbra	d6,SPat7
* Pas d'erreur
SPatX:	moveq	#0,d0
SPatex:	movem.l	(sp)+,d1-d7/a0-a6
	rts
* Erreur quelconque
SPatE:	moveq	#1,d0
	bra.s	SPatex

******* Efface le pattern de l'ecran courant
EffPat:	movem.l	a0-a1/d0-d2,-(sp)
	move.l	T_EcCourant(a5),a0
	move.l	EcPat(a0),d0
	beq.s	EffPx
	move.l	d0,a1
	move.w	EcPatL(a0),d0
	ext.l	d0
	clr.l	EcPat(a0)
	clr.w	EcPatL(a0)
	clr.b	EcPatY(a0)
	bsr	FreeMm
EffPx:	move.l	T_RastPort(a5),a0
	clr.l	8(a0)
	clr.b	29(a0)
	movem.l	(sp)+,a0-a1/d0-d2
	rts

******* Routine
SoMouse	subq.w	#1,d2
Som0:	move.w	(a2)+,d0
	bmi.s	SomE
	mulu	(a2)+,d0
	mulu	(a2)+,d0
	lsl.w	#1,d0
	lea	4(a2,d0.w),a2
	dbra	d2,Som0
	moveq	#0,d0
	rts
SomE:	moveq	#-1,d0
	rts


