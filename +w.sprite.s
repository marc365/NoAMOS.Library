;    Table de retournement bobs
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

TRetour		ds.b	256

***********************************************************
*	COLLISIONS HARD

******* SET HARDCOL
*	D1= 	Sprites
*	D2=	Enable
*	D3=	Compare
HColSet	and.w	#$000F,d1
	lsl.w	#8,d1
	lsl.w	#4,d1
	and.w	#$003F,d2
	lsl.w	#6,d2
	and.w	#$003F,d3
	or.w	d2,d1
	or.w	d3,d1
	move.w	d1,Circuits+$98
	moveq	#0,d0
	rts
******* =HARDCOL
*	D1=	#Sprite / -1 Si bitplanes
HColGet	lea	T_TColl(a5),a0
	move.l	a0,a1
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	move.w	Circuits+$0E,d2
	tst.w	d1
	bmi.s	HCol3
* Sprites
	and.w	#$0006,d1
	lsl.w	#2,d1
	lea	HColT(pc),a0
	add.w	d1,a0
	moveq	#0,d3
	moveq	#%00000011,d4
	moveq	#0,d1
	move.b	(a0)+,d0
HCol1	bmi.s	HCol2
	btst	d0,d2
	beq.s	HCol2
	or.w	d4,d3
	cmp.w	#$0100,d3
	bcc.s	HCol2
	moveq	#-1,d1
HCol2	lsl.w	#2,d4
	move.b	(a0)+,d0
	bne.s	HCol1
* Ok!
	ror.w	#8,d3
	move.w	d3,(a1)
	moveq	#0,d0
	rts
******* Playfield / Playfield
HCol3	moveq	#0,d1
	btst	#0,d2
	beq.s	HCol4
	moveq	#-1,d1
HCol4	rts
******* Table des bits a tester!
HColT	dc.b	-1,9,10,11,1,5,0,0
	dc.b	9,-1,12,13,2,6,0,0
	dc.b	10,12,-1,14,3,7,0,0
	dc.b	11,13,14,-1,4,8,0,0

***********************************************************
*	COLLISIONS SOFT

******* Routine collision:
*	A3/A2= 	descripteur sprite concerne
*	D0/D1=	bob dest   DX/DY
*	D2=	Image!
*	D4/D5= 	bob source DX/DY
*	D6/D7=	bob source FX/FY
*	A4=	banque!
******* RETOUR: BNE-> Pas coll
*******		BEQ-> Coll
ColRout:
* Pointe le descripteur
	and.w	#$3FFF,d2
	beq	ColRF
	cmp.w	(a4),d2
	bhi	ColRF
	lsl.w	#3,d2
	lea	-8+2(a4,d2.w),a0
	move.l	4(a0),d2
	ble	ColRF
	move.l	d2,a1
	move.l	(a0),d2
	beq	ColRF
	move.l	d2,a0
* Prend les coordonnees
	move.w	6(a0),d2
	lsl.w	#2,d2
	asr.w	#2,d2
	sub.w	d2,d0
	sub.w	8(a0),d1
	move.w	(a0),d2
	lsl.w	#4,d2
	move.w	2(a0),d3
	add.w	d0,d2
	add.w	d1,d3
* Croisement?
	cmp.w	d4,d2
	ble	ColRF
	cmp.w	d6,d0
	bge	ColRF
	cmp.w	d5,d3
	ble	ColRF
	cmp.w	d7,d1
	bge	ColRF
* Verifie avec le blitter!
	movem.l	d4-d7/a2/a3,-(sp)
	cmp.w	d0,d4		* Met le plus a gauche en D0
	bge.s	ColR1
	exg.l	d0,d4
	exg.l	d1,d5
	exg.l	d2,d6
	exg.l	d3,d7
	exg.l	a1,a3
	exg.l	a0,a2
ColR1:	cmp.w	d5,d1
	bge.s	ColR5
	move.w	d5,-(sp)
	sub.w	d1,(sp)
	clr.w	-(sp)
ColR2:	cmp.w	d3,d7
	bge.s	ColR3
	move.w	d7,-(sp)
	bra.s	ColR4
ColR3:	move.w	d3,-(sp)
ColR4:	sub.w	d5,(sp)
	bra.s	ColR7a
ColR5:	clr.w	-(sp)
	move.w	d1,-(sp)
	sub.w	d5,(sp)
	cmp.w	d3,d7
	bge.s	ColR6
	move.w	d7,-(sp)
	bra.s	ColR7
ColR6:	move.w	d3,-(sp)
ColR7:	sub.w	d1,(sp)

ColR7a:	move.w	d4,d1
	sub.w	d0,d1
	cmp.w	d2,d6
	bge.s	ColR8
	move.w	d6,d3
	bra.s	ColR9
ColR8:	move.w	d2,d3
ColR9:	sub.w	d4,d3

	move.w	d1,d0
	lsl.w	#8,d0
	lsl.w	#4,d0
	move.w	d0,BltCon1(a6)
	move.w	#%0000110011000000,BltCon0(a6)
	lsr.w	#4,d3
	tst.w	d0
	beq.s	ColRA
	addq.w	#1,d3
ColRA:	move.w	d3,d4
	move.w	(sp)+,d0
	ble.s	ColRF0
	lsl.w	#6,d0
	or.w	d0,d4
	lsl.w	#1,d3
	move.w	(a0),d0
	lsl.w	#1,d0
;	addq.w	#2,d0
	move.w	d0,d6
	sub.w	d3,d0
	move.w	d0,BltModA(a6)
	move.w	(a2),d0
	lsl.w	#1,d0
;	addq.w	#2,d0
	move.w	d0,d5
	sub.w	d3,d0
	move.w	d0,BltModB(a6)

	mulu	(sp)+,d5
	lea	4(a3,d5.w),a3
	move.l	a3,BltAdB(a6)
	move.w	d1,d0
	lsr.w	#4,d0
	lsl.w	#1,d0
	mulu	(sp)+,d6
	add.w	d0,d6
	lea	4(a1,d6.w),a1
	move.l	a1,BltAdA(a6)
	move.w	#-1,BltMaskD(a6)
	and.w	#$000F,d1
	lsl.w	#1,d1
	lea	MCls(pc),a1
	move.w	0(a1,d1.w),BltMaskG(a6)

	move.w	d4,BltSize(a6)
	movem.l	(sp)+,d4-d7/a2/a3

ColRW:	bsr	BlitWait
	btst	#13,DmaConR(a6)
	rts
* Yapa collision!
ColRF:	moveq	#1,d0
	rts
* Yapa special!
ColRF0:	addq.l	#4,sp
ColRF1:	movem.l	(sp)+,d4-d7/a2/a3
	moveq	#1,d0
	rts

***********************************************************
*	BOB COLLIDE
*	D1= Numero du bob
*	D2= Debut a explorer (Bit 31===> TO SPRITE)
*	D3= Fin a explorer
BbColl:	movem.l	a2-a6/d2-d7,-(sp)
	lea	Circuits,a6
	bsr	OwnBlit
	lea	T_TColl(a5),a0
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	moveq	#0,d7
	move.l	T_SprBank(a5),d0
	beq	BbColX
	move.l	d0,a4
	bsr	BobAd
	bne	BbColX

* Coordonnees du bob a tester!
	move.l	a1,a2
	tst.b	BbAct(a2)
	bmi	BbColX
	move.w	d1,a0
	move.l	BbEc(a2),d1
	move.w	BbX(a2),d4
	move.w	BbY(a2),d5
	move.w	BbI(a2),d0
	and.w	#$3FFF,d0
	beq	BbColX
	cmp.w	(a4),d0
	bhi	BbColX
	lsl.w	#3,d0
	lea	-8+2(a4,d0.w),a2
	move.l	4(a2),d0
	ble	BbColX
	move.l	d0,a3
	move.l	(a2),d0
	beq	BbColX
	move.l	d0,a2
	move.w	6(a2),d0
	lsl.w	#2,d0
	asr.w	#2,d0
	sub.w	d0,d4
	sub.w	8(a2),d5
	move.w	d4,d6
	move.w	d5,d7
	move.w	(a2),d0
	lsl.w	#4,d0
	add.w	d0,d6
	add.w	2(a2),d7
	btst	#31,d2
	bne	GoToSp

	exg.l	a0,a5
	move.l	T_BbDeb(a0),d0
	lea	T_TColl(a0),a0
******* Explore la table des bobs!
BbCol1:	move.l	d0,a1
	move.w	BbNb(a1),d0
	cmp.w	d2,d0
	bcs.s	BbColN
	cmp.w	d3,d0
	bhi.s	BbColX
	cmp.w	a5,d0
	beq.s	BbColN
	cmp.l	BbEc(a1),d1
	bne.s	BbColN
	tst.b	BbAct(a1)
	bmi.s	BbColN
	movem.l	d0-d3/a0/a1,-(sp)
	move.w	BbX(a1),d0
	move.w	BbY(a1),d1
	move.w	BbI(a1),d2
	bsr	ColRout
	movem.l	(sp)+,d0-d3/a0/a1
	bne.s	BbColN
	swap	d2
	and.w	#$00FF,d0
	move.w	d0,d2
	lsr.w	#3,d0
	and.w	#$7,d2
	bset	d2,0(a0,d0.w)
	bset	#31,d7
	swap	d2
BbColN:	move.l	BbNext(a1),d0
	bne.s	BbCol1

******* Fini!
BbColX:	bsr	DOwnBlit
	btst	#31,d7
	bne.s	BbColT
	moveq	#0,d0
	bra.s	BbColXx
BbColT	moveq	#-1,d0
BbColXx	movem.l	(sp)+,a2-a6/d2-d7
	rts

******* Conversion---> HARD
GoToSp:	movem.w	d2-d3,-(sp)
	move.l	d1,a0
	sub.w	d4,d6
	sub.w	d5,d7
	move.w	d4,d1
	move.w	d5,d2
	bsr	CXyS
	move.w	d1,d4
	move.w	d2,d5
	add.w	d4,d6
	add.w	d5,d7
	movem.w	(sp)+,d2-d3
	moveq	#-1,d1
	bra	BbToSp

***********************************************************
*	SPRITE COLLIDE
*	D1= Numero du sprite
*	D2= Debut a explorer
*	D3= Fin a explorer
SpColl:	movem.l	a2-a6/d2-d7,-(sp)
	lea	Circuits,a6
	bsr	OwnBlit
	lea	T_TColl(a5),a0
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	moveq	#0,d7
	move.l	T_SprBank(a5),d0
	beq	BbColX
	move.l	d0,a4

* Coordonnees du sprite a tester!
	cmp.w	#64,d1
	bcc	BbColX
	lea	T_HsTAct(a5),a2
	move.w	d1,d0
	lsl.w	#3,d0
	add.w	d0,a2
	move.w	2(a2),d4
	move.w	4(a2),d5
	move.w	6(a2),d0
	and.w	#$3FFF,d0
	beq	BbColX
	cmp.w	(a4),d0
	bhi	BbColX
	lsl.w	#3,d0
	lea	-8+2(a4,d0.w),a2
	move.l	4(a2),d0
	ble	BbColX
	move.l	d0,a3
	move.l	(a2),d0
	beq	BbColX
	move.l	d0,a2
	move.w	6(a2),d0
	lsl.w	#2,d0
	asr.w	#2,d0
	sub.w	d0,d4
	sub.w	8(a2),d5
	move.w	d4,d6
	move.w	d5,d7
	move.w	(a2),d0
	lsl.w	#4,d0
	add.w	d0,d6
	add.w	2(a2),d7
	btst	#31,d2
	bne	SpToBb

BbToSp:	cmp.w	#64,d3
	bcc	BbColX
	cmp.w	d2,d3
	bcs	BbColX
	lea	T_TColl(a5),a0
	lea	T_HsTAct(a5),a1
	move.w	d2,d0
	lsl.w	#3,d2
	add.w	d2,a1
	move.w	d3,a5
******* Explore la table des sprites!
SpCol1:	cmp.w	d1,d0
	beq.s	SpColN
	tst.w	(a1)
	bmi.s	SpColN
	move.w	6(a1),d2
	ble.s	SpColN
	movem.l	d0/d1/a0/a1,-(sp)
	move.w	2(a1),d0
	move.w	4(a1),d1
	bsr	ColRout
	movem.l	(sp)+,d0/d1/a0/a1
	bne.s	SpColN
	move.w	d0,d2
	move.w	d0,d3
	lsr.w	#3,d2
	and.w	#$7,d3
	bset	d3,0(a0,d2.w)
	bset	#31,d7
SpColN:	addq.w	#1,d0
	addq.l	#8,a1
	cmp.w	a5,d0
	bls.s	SpCol1
	bra	BbColX

******* Fin de SPRITE/BOB
SpToBb:	move.l	T_BbDeb(a5),d0
	lea	T_TColl(a5),a5
SbCol1:	move.l	d0,a1
	move.w	BbNb(a1),d0
	cmp.w	d2,d0
	bcs	SbColN
	cmp.w	d3,d0
	bhi	BbColX
	tst.b	BbAct(a1)
	bmi	SbColN
	movem.l	d0/d2/d3/a1,-(sp)
	move.l	BbEc(a1),a0
	move.w	BbX(a1),d1
	move.w	BbY(a1),d2
	bsr	CXyS
	move.w	d1,d0
	move.w	d2,d1
	move.w	BbI(a1),d2
	bsr	ColRout
	movem.l	(sp)+,d0/d2/d3/a1
	bne.s	SbColN
	and.w	#$00FF,d0
	move.w	d0,d1
	lsr.w	#3,d0
	and.w	#$7,d1
	bset	d1,0(a5,d0.w)
	bset	#31,d7
SbColN:	move.l	BbNext(a1),d0
	bne.s	SbCol1
	bra	BbColX

***********************************************************
*	=COLL(n) ramene la collision d'un bob/sprite
GetCol:	lea	T_TColl(a5),a0
	tst.l	d1
	bmi.s	GetC2
	and.w	#$FF,d1
	move.w	d1,d0
	lsr.w	#3,d0
	and.w	#$7,d1
	btst	d1,0(a0,d0.w)
	bne.s	GetC1
GetC0:	moveq	#0,d0
	rts
GetC1:	moveq	#-1,d0
	rts
* Ramene le premier en collision
GetC2:	neg.l	d1
	cmp.l	#255,d1
	bcc.s	GetC0
	move.w	d1,d0
	lsr.w	#3,d0
	add.w	d0,a0
	move.l	d1,d0
	and.w	#7,d1
.loop	btst	d1,(a0)
	bne.s	.found
	addq.w	#1,d0
	addq.w	#1,d1
	cmp.w	#8,d1
	bcs.s	.loop
	moveq	#0,d1
	addq.l	#1,a0
	cmp.w	#256,d0
	bcs.s	.loop
	bra.s	GetC0
.found	rts

***********************************************************
*	HOT SPOT!
*	A2= descripteur
*	D1= Mode
*	D2= Dx
*	D3= Dy
SpotH:	move.l	(a2),d0
	beq.s	SpoE
	move.l	d0,a1
	tst.w	d1
	beq.s	Spo4
******* Mode FIXE!
	move.w	(a1),d2
	lsl.w	#4,d2
	move.w	2(a1),d3
	subq.w	#1,d1
* En X
	move.w	d1,d0
	lsr.w	#4,d0
	and.w	#3,d0
	subq.w	#1,d0
	bhi.s	Spo2
	beq.s	Spo1
	moveq	#0,d2
Spo1:	lsr.w	#1,d2
* En Y
Spo2:	and.w	#3,d1
	subq.w	#1,d1
	bhi.s	Spo4
	beq.s	Spo3
	moveq	#0,d3
Spo3:	lsr.w	#1,d3
* Poke, en respectant les FLAGS!
Spo4:	and.w	#$C000,6(a1)
	and.w	#$3FFF,d2
	or.w	d2,6(a1)
	move.w	d3,8(a1)
	moveq	#0,d0
	rts
SpoE:	moveq	#-1,d0
	rts

***********************************************************
*	GET BOB/BLOC
*	A1= Ecran
*	A2= descripteur
*	D2/D3= X1/Y1
*	D4/D5= TX/TY
*	D6=    X2
GetBob:	movem.l	d1-d7/a0-a6,-(sp)
	move.l	a1,a5
* Masque droite
	move.w	d4,d6
	and.w	#$000F,d6
	lsl.w	#1,d6
	move.w	d6,a4
* Taille en octets!
	move.w	EcNPlan(a5),d7
	add.w	#15,d4
	lsr.w	#4,d4
	move.w	d4,d6
	lsl.w	#1,d6
	move.w	d6,d1
	mulu	d5,d1
	mulu	d7,d1
******* Efface l'ancien???
	move.l	(a2),d0
	beq.s	GtBb1
	move.l	d0,a1			* Efface le bob
	move.w	(a1),d0
	lsl.w	#1,d0
	mulu	2(a1),d0
	mulu	4(a1),d0
	cmp.l	d0,d1
	beq.s	GtBb1
	add.l	#10,d0
	bsr	FreeMm
	clr.l	(a2)
GtBb1:	move.l	4(a2),d0
	ble.s	GtBb2
	move.l	d0,a1
	move.l	(a1),d0
	bsr	FreeMm
GtBb2	clr.l	4(a2)
******* Reserve le mouveau
	tst.l	(a2)
	bne.s	GtBb3
	move.l	d1,d0
	add.l	#10,d0
	bsr	ChipMm2
	beq	GtBbE
	move.l	d0,(a2)
******* Ca y est!
GtBb3:	move.l	(a2),a2
	move.w	d4,(a2)+
	move.w	d5,(a2)+
	move.w	d7,(a2)+
	clr.w	(a2)+
	clr.w	(a2)+
******* GETTE!
	lea	Circuits,a6
	bsr	OwnBlit
	subq.w	#1,d7
	move.w	d2,d0
	and.w	#$000F,d0
	bne.s	GtBc

******* Au mot!
	moveq	#-1,d1
	move.w	d1,BltMaskG(a6)
	move.w	a4,d0
	beq.s	GtBbM
	lea	MCls(pc),a0
	move.w	0(a0,d0.w),d1
	not.w	d1
GtBbM:	move.w	d1,BltMaskD(a6)
	move.w	EcTLigne(a5),d1
	mulu	d1,d3
	lsr.w	#4,d2
	lsl.w	#1,d2
	ext.l	d2
	add.l	d2,d3
	lea	EcCurrent(a5),a1
	sub.w	d6,d1
	move.w	d1,BltModA(a6)
	move.l	a2,BltAdD(a6)
	clr.w	BltModD(a6)
	lsl.w	#6,d5
	or.w	d5,d4
	move.w	#%0000100111110000,BltCon0(a6)
	clr.w	BltCon1(a6)
GtBb5:	move.l	(a1)+,a0
	add.l	d3,a0
	move.l	a0,BltAdA(a6)
	move.w	d4,BltSize(a6)
GtBb6:	bsr	BlitWait
	dbra	d7,GtBB5
	bra	GtBbX

******* Au pixel!
GtBc:	move.w	#%0000010111001100,BltCon0(a6)
	moveq	#16,d1
	sub.w	d0,d1
	moveq	#12,d0
	lsl.w	d0,d1
	move.w	d1,BltCon1(a6)
	move.w	EcTligne(a5),d1
	ext.l	d1
	mulu	d1,d3
	lsr.w	#4,d2
	lsl.w	#1,d2
	ext.l	d2
	add.l	d2,d3
	lea	EcCurrent(a5),a1
	subq.l	#2,a2
	addq.w	#1,d4
	or.w	#%0000000001000000,d4
	subq.w	#1,d5
	ext.l	d6
	move.w	a4,d2
	lea	MCls(pc),a0
	move.w	0(a0,d2.w),d2
	bmi.s	GtBc1
	not.w	d2
GtBc1:	move.l	(a1)+,a0
	add.l	d3,a0
	move.w	d5,d0
GtBc2:	move.l	a0,BltAdB(a6)
	move.w	(a2),a4
	move.l	a2,BltAdD(a6)
	move.w	d4,BltSize(a6)
	move.l	a2,a5
	add.l	d1,a0
	add.l	d6,a2
GtBc3:	bsr	BlitWait
	move.w	a4,(a5)
	and.w	d2,(a2)
	dbra	d0,GtBc2
	dbra	d7,GtBc1

******* FINI! Pas d'erreur
GtBbX:	bsr	DOwnBlit
	movem.l	(sp)+,d1-d7/a0-a6
	moveq	#0,d0
	rts
******* Out of mem
GtBbE:	movem.l	(sp)+,d1-d7/a0-a6
	moveq	#-1,d0
	rts

***********************************************************
*	INITIALISATION BOBS / D0= Nombre de bobs!
BbInit:
********
	clr.l	T_BbDeb(a5)
* Efface ce qui etait reserve
	move.w	d0,-(sp)
	bsr	BbEnd
	move.w	(sp)+,d1
* Reserve la memoire pour les tables priorites
	move.w	d1,T_BbMax(a5)
	ext.l	d1
	lsl.w	#2,d1
	move.l	d1,d0
	bsr	FastMm
	beq	GFatal
	move.l	d0,T_BbPrio(a5)
	move.l	d1,d0
	bsr	FastMm
	beq	GFatal
	move.l	d0,T_BbPrio2(a5)
	moveq	#0,d0
	rts

***********************************************************
*	FIN DES BOBS
BbEnd:
*******
	move.w	T_BbMax(a5),d1
	ext.l	d1
	lsl.l	#2,d1
	move.l	T_BbPrio(a5),d0
	beq.s	BOBE1
	move.l	d0,a1
	move.l	d1,d0
	bsr	FreeMm
BOBE1:	move.l	T_BbPrio2(a5),d0
	beq.s	BOBE2
	move.l	d0,a1
	move.l	d1,d0
	bsr	FreeMm
BOBE2:	moveq	#0,d0
	rts

***********************************************************
*	BOB X/Y
BobXY:	bsr	BobAd
	bne.s	BobxyE
	move.w	BbX(a1),d1
	move.w	BbY(a1),d2
	move.w	BbI(a1),d3
	moveq	#0,d0
BobxyE:	rts

***********************************************************
*	PATCH BOB / ICON
*	Dessine simplement un bob/icon
*	A1-	Buffer de calcul
*	A2-	Descripteur bob/icon
*	D1-	Image retournee???
*	D2/D3-	Coordonnees
*	D4-	Minterms (0 si rien)
*	D5-	APlan
TPatch
	movem.l	d1-d7/a0-a6,-(sp)
	move.l	a1,a4
* Va retourner le bob
	move.l	a2,a0
	move.w	d1,d0
	and.w	#$C000,d0
	bsr	Retourne
* Parametres de l'ecran courant
	move.l	T_EcCourant(a5),a0	* Calculssss
	move.w	EcClipX0(a0),d0
	and.w	#$FFF0,d0
	move.w	d0,BbLimG(a4)
	move.w	EcClipY0(a0),BbLimH(a4)
	move.w	EcClipX1(a0),d0
	add.w	#15,d0
	and.w	#$FFF0,d0
	move.w	d0,BbLimD(a4)
	move.w	EcClipY1(a0),BbLimB(a4)
	tst.w	d4
	beq.s	Patch1
	and.w	#$00FF,d4
	bset	#15,d4
Patch1	move.w	d4,BbACon(a4)
	move.w	d5,BbAPlan(a4)
	move.l	a0,BbEc(a4)
	exg.l	d3,d1
	bset	#31,d3			* Flag PAS POINT CHAUD!
	bsr	BobCalc
	bne.s	PatchO
* Gestion de l'autoback
	move.l	T_EcCourant(a5),a0
	tst.w	EcAuto(a0)
	beq.s	Patch2
	bsr	TAbk1
	bsr	PBobA
	bsr	TAbk2
	bsr	PBobA
	bsr	TAbk3
	bra.s	PatchO
Patch2	bsr	PBobA
* Fini!
PatchO	moveq	#0,d0
	movem.l	(sp)+,d1-d7/a0-a6
	rts
* Appelle la routine d'affichage
PBobA	lea	Circuits,a6
	bsr	OwnBlit
	move.w	BbASize(a4),d2
	move.w	BbTPlan(a4),d4
	ext.l	d4
	move.l	BbAData(a4),a0
	move.l	BbEc(a4),a3
	lea	EcCurrent(a3),a3
	move.w	BbAModD(a4),d0
	move.w	d0,BltModC(a6)
	move.w	d0,BltModD(a6)
	move.l	BbADraw(a4),a2
	move.l	BbAMask(a4),d5
	jsr	(a2)
	bsr	BlitWait
	bra	DOwnBlit

***********************************************************
*	CREATION / CHANGEMENT D'UN BOB
*	D1= Numero du CANAL
*	D2= X
*	D3= Y
*	D4= Image
*	D5= MODE DECOR
*	D6= Plans affiches
*	D7= Minterms
BobSet:
********
	cmp.w	T_BbMax(a5),d1
	bcc	CreBbS

******* Ecris sur l'ancienne - SI PRESENT -
	move.l	a1,a0
	move.l	T_BbDeb(a5),d0
	beq.s	CreBb1
CreBb0:	move.l	d0,a1
	cmp.w	BbNb(a1),d1
	beq.s	CreBb5
	bcs.s	CreBb2
	move.l	BbNext(a1),d0
	bne.s	CreBb0
* Met a la fin!
	bsr	ResBOB
	bne	CreBbE
	move.l	a1,BbPrev(a0)
	move.l	a0,BbNext(a1)
	move.l	a0,a1
	bra.s	CreBb5
* Au tout debut
CreBb1:	bsr	ResBOB
	bne	CreBbE
	move.l	a0,T_BbDeb(a5)
	move.l	a0,a1
	bra.s	CreBb5
* Insere la nouvelle
CreBb2:	bsr	ResBOB
	bne	CreBbE
	move.l	BbPrev(a1),d0
	move.l	a0,BbPrev(a1)
	move.l	d0,BbPrev(a0)
	bne.s	CreBb3
	move.l	T_BbDeb(a5),d1
	move.l	a0,T_BbDeb(a5)
	bra.s	CreBb4
CreBb3:	move.l	d0,a2
	move.l	BbNext(a2),d1
	move.l	a0,BbNext(a2)
CreBb4:	move.l	d1,BbNext(a0)
	move.l	a0,a1
* Poke les coordonnees
CreBb5:	move.l	#EntNul,d7
	move.b	BbAct(a1),d6
	bmi.s	CreBb9
	cmp.l	d7,d2
	beq.s	CreBb6
	move.w	d2,BbX(a1)
	bset	#1,d6
CreBb6:	cmp.l	d7,d3
	beq.s	CreBb7
	move.w	d3,BbY(a1)
	bset	#2,d6
CreBb7:	cmp.l	d7,d4
	beq.s	CreBb8
	move.w	d4,BbI(a1)
	bset	#0,d6
CreBb8:	move.b	d6,BbAct(a1)
* Doit actualiser les bob
CreBb9:	bset	#BitBobs,T_Actualise(a5)
	moveq	#0,d0
	rts
******* Erreur!
CreBbS:	moveq	#1,d0
CreBbE:	tst.w	d0
	rts

******* CREATION DE LA TABLE!
ResBOB:	move.l	#BbLong,d0
	bsr	FastMm
	beq.s	ResBErr
	move.l	d0,a0
	move.w	d1,BbNb(a0)
	move.l	T_EcCourant(a5),a2
	move.l	a2,BbEc(a0)
	move.w	EcTx(a2),BbLimD(a0)
	move.w	EcTy(a2),BbLimB(a0)
	move.w	d6,BbAPlan(a0)
	and.w	#$00FF,d7
	beq.s	ResBb0
	bset	#15,d7
ResBb0	move.w	d7,BbACon(a0)
	move.w	#$01,BbDecor(a0)
	btst	#BitDble,EcFlags(a2)
	beq.s	ResBb1
	addq.w	#1,BbDecor(a0)
	move.w	#Decor,BbDCur2(a0)
ResBb1:	tst.w	d5
	bpl.s	ResBb2
	clr.w	BbDecor(a0)
ResBb2:	move.w	d5,BbEff(a0)
	moveq	#0,d0
	rts
* Erreur memoire!
ResBErr	moveq	#-1,d0
	rts

***********************************************************
*	BOB OFF d1=#
BobOff:
*******
	move.l	T_BbDeb(a5),d0
	beq.s	DBb2
DBb1:	move.l	d0,a1
	cmp.w	BbNb(a1),d1
	beq.s	DBb3
	bcs.s	DBb2
	move.l	BbNext(a1),d0
	bne.s	DBb1
DBb2:	moveq	#1,d0
	rts
DBb3:	move.b	#-1,BbAct(a1)
	bset	#BitBobs,T_Actualise(a5)
	moveq	#0,d0
	rts
***********************************************************
*	ARRET TOUS LES BOBS
BobSOff:
*******
	movem.l	d0/a1/a2,-(sp)
	move.l	T_BbDeb(a5),d0
	beq.s	DBbs2
DBbs1:	move.l	d0,a1
	move.b	#-1,BbAct(a1)
	move.l	BbNext(a1),d0
	bne.s	DBbs1
DBbs2:	bset	#BitBobs,T_Actualise(a5)
	movem.l	(sp)+,d0/a1/a2
	moveq	#0,d0
	rts

***********************************************************
*	LIMIT BOB tous, Ecran courant!
*	D1= # ou -1, D2/D3->D4/D5
BobLim:
*******
	movem.l	d2-d7,-(sp)
	move.l	T_BbDeb(a5),d0
	beq	LBbX
* Verifie les coordonnees
	move.l	T_EcCourant(a5),d6
	move.l	d6,a0
	move.l	#EntNul,d7
	cmp.w	d7,d2
	bne.s	LBba
	clr.w	d2
LBba:	cmp.w	d7,d3
	bne.s	LBbb
	clr.w	d3
LBbb:	cmp.w	d7,d4
	bne.s	LBbc
	move.w	EcTx(a0),d4
LBbc:	cmp.w	d7,d5
	bne.s	LBbd
	move.w	EcTy(a0),d5
LBbd:	and.w	#$FFF0,d2
	and.w	#$FFF0,d4
	cmp.w	d2,d4
	bls.s	LbbE
	cmp.w	d2,d5
	bls.s	LbbE
	cmp.w	EcTx(a0),d4
	bhi.s	LbbE
	cmp.w	EcTy(a0),d5
	bhi.s	LbbE
* Change les bobs!
LBb1:	move.l	d0,a1
	tst.w	BbAct(a1)
	bmi.s	LBb3
	cmp.l	BbEc(a1),d6
	bne.s	LBb3
	tst.w	d1
	bmi.s	LBb2
	cmp.w	BbNb(a1),d1
	bhi.s	LBb3
	bcs.s	LBbX
LBb2:	move.w	d2,BbLimG(a1)
	move.w	d3,BbLimH(a1)
	move.w	d4,BbLimD(a1)
	move.w	d5,BbLimB(a1)
	bset	#0,BbAct(a1)			***Bug?
	bset	#BitBobs,T_Actualise(a5)
LBb3:	move.l	BbNext(a1),d0
	bne.s	LBb1
LBbX:	moveq	#0,d0
LBbXx	movem.l	(sp)+,d2-d7
	rts
LBbE:	moveq	#-1,d0
	bra.s	LBbXx

***********************************************************
*	PRIORITY ON/OFF
*	D1= on/off - Ecran courant (-1 indet)
*	D2= normal - reversed      (-1 indet)
TPrio	tst.l	d1
	bmi.s	TPri2
	beq.s	TPri1
	move.l	T_EcCourant(a5),d1
TPri1	move.l	d1,T_Priorite(a5)
TPri2	tst.l	d2
	bmi.s	TPri3
	move.w	d2,T_PriRev(a5)
TPri3	moveq	#0,d0
	rts

***********************************************************
*	ENLEVE LES BOBS D'UN ECRAN!
*	A0= Ecran
BbEcOff:
********
	movem.l	d1-d7/a0/a1,-(sp)
	move.l	a0,d7
	move.l	T_BbDeb(a5),d0
	beq.s	BbEO2
BbEO1:	move.l	d0,a1
	cmp.l	BbEc(a1),d7
	beq.s	BbEO3
	move.l	BbNext(a1),d0
	bne.s	BbEO1
BbEO2:	movem.l	(sp)+,d1-d7/a0/a1
	moveq	#0,d0
	rts
******* Enleve le bob!
BbEO3:	move.l	BbNext(a1),d0
	bsr	DelBob
* Encore?
	tst.l	d0
	bne.s	BbEO1
	bra.s	BbEO2

******* Efface la definition du bob (A1)
DelBob:	movem.l	d0-d7/a0-a2,-(sp)
	move.l	a1,a2

* Enleve les buffers de decor, s'il y en a!
	moveq	#0,d0
	move.w	BbDLBuf(a2),d0
	beq.s	DBo1
	lsl.l	#1,d0
	move.l	BbDABuf(a2),a1
	bsr	FreeMm
DBo1:	moveq	#0,d0
	move.w	BbDLBuf+Decor(a2),d0
	beq.s	DBo2
	lsl.l	#1,d0
	move.l	BbDABuf+Decor(a2),a1
	bsr	FreeMm
* Enleve le canal d'animation
DBo2:	lea	BbAct(a2),a0
	bsr	DAdAMAL
* Enleve le bob
	move.l	BbNext(a2),d3
	move.l	BbPrev(a2),d2
	beq.s	DBo3
	move.l	d2,a0
	move.l	d3,BbNext(a0)
	bra.s	DBo4
DBo3:	move.l	d3,T_BbDeb(a5)
DBo4:	tst.l	d3
	beq.s	DBo5
	move.l	d3,a0
	move.l	d2,BbPrev(a0)
DBo5:	move.l	a2,a1
	move.l	#BbLong,d0
	bsr	FreeMm

	movem.l	(sp)+,d0-d7/a0-a2
	rts

***********************************************************
*	ADRESSE D'UN BOB: D1= Numero!
BobAd:
*******
	move.l	T_BbDeb(a5),d0
	beq.s	AdBb1
AdBb0:	move.l	d0,a1
	cmp.w	BbNb(a1),d1
	beq.s	AdBb2
	bcs.s	AdBb1
	move.l	BbNext(a1),d0
	bne.s	AdBb0
AdBb1	moveq	#1,d0
AdBb2	rts

***********************************************************
*	PUT BOB n
BobPut:	bsr	BobAd
	bne.s	BbPx
	move.w	BbDecor(a1),BbECpt(a1)
	moveq	#0,d0
BbPx:	rts

***********************************************************
*	ACTUALISATION DES BOBS
*******
BobAct:	movem.l	d2-d7/a2-a6,-(sp)
	move.l	T_BbPrio(a5),a3
* Banque de sprites chargee?
	move.l	T_SprBank(a5),d0
	beq	BbSx
	move.l	d0,a6
******* Explore les bobs!
	move.l	T_BbDeb(a5),d0
	beq	BbSx
	clr.w	-(sp)
	move.l	T_Priorite(a5),-(sp)
	move.l	T_BbPrio2(a5),a5
BbS0:	move.l	d0,a4
* Flippe les decors!
	move.w	BbDCur2(a4),d4
	move.w	BbDCur1(a4),BbDCur2(a4)
	move.w	d4,BbDCur1(a4)
* Bob modifie?
	tst.w	BbECpt(a4)		* Si PUT BOB---> Pas d'act!
	bne.s	BbSDec
	tst.b	BbAct(a4)
	beq	BbSDec
	bmi	BbDel
	clr.b	BbAct(a4)
	move.w	BbI(a4),d2		* Pointe l'image
	moveq	#0,d3
	move.w	d2,d3
	and.w	#$C000,d3
	move.w	d3,BbRetour(a4)
	and.w	#$3FFF,d2
	beq	BbSort
	cmp.w	(a6),d2
	bhi	BbSort
	lsl.w	#3,d2
	lea	-8+2(a6,d2.w),a2
	tst.l	(a2)
	beq	BbSort
	move.l	a2,BbARetour(a4)
	move.w	BbX(a4),d2		* Coordonnees
	move.w	BbY(a4),d1
	move.l	BbEc(a4),a0		* Ecran
	bsr	BobCalc
	bne	BbSort

******* Sauvegarde du decor!
BbSDec:	move.w	BbDecor(a4),d0
	beq	BbSN
	move.w	BbESize(a4),d1
	beq	BbSort
* Stocke les parametres
	move.w	d0,BbDCpt(a4)
	move.w	BbDCur1(a4),d0
	lea	0(a4,d0.w),a2
	move.w	d1,BbDASize(a2)
	move.w	BbEMod(a4),BbDMod(a2)
	move.w	BbAPlan(a4),BbDAPlan(a2)
	move.w	BbEAEc(a4),BbDAEc(a2)
	move.w	BbNPlan(a4),d1
	move.w	d1,BbDNPlan(a2)
	tst.w	BbEff(a4)		* Effacement en couleurs?
	bne.s	BbSN
	addq.w	#1,d1
	mulu	BbETPlan(a4),d1		* Taille du buffer
	moveq	#0,d0
	move.w	BbDLBuf(a2),d0
	beq.s	BbD4
	lsl.l	#1,d0
	cmp.l	d0,d1			* Taille suffisante?
	bls.s	BbD5
* Efface l'ancien buffer?
	move.l	BbDABuf(a2),a1
	bsr	FreeMm
	clr.l	BbDABuf(a2)
	clr.w	BbDLbuf(a2)
* Reserve le nouveau!
BbD4:	move.l	d1,d0
	bsr	ChipMm
	beq.s	BbD5
	move.l	d0,BbDABuf(a2)
	lsr.l	#1,d1
	move.w	d1,BbDLBuf(a2)
* Ok!
BbD5:	bra	BbSN

******* BOB ARRETE
BbDel:	subq.w	#1,BbDecor(a4)		* Compte le nombre de REDRAW
	bhi.s	BbSort
* Efface!
	move.l	BbNext(a4),d0
	move.l	a4,a1
	move.l	a5,-(sp)
	move.l	W_Base(pc),a5
	bsr	DelBob
	move.l	(sp)+,a5
	tst.l	d0
	bne	BbS0
	bra.s	BbBug

******* Calcul des priorites
BbSN:	move.l	BbEc(a4),d0
	cmp.l	(sp),d0
	bne.s	BbPrX
* Priorite!
	move.l	a4,(a5)+
	addq.w	#1,4(sp)
	bra.s	BbSort
* Pas de priorite
BbPrX	move.l	a4,(a3)+
******* En dehors!
BbSort:	move.l	BbNext(a4),d0
	bne	BbS0
BbBug
******* Classe les bobs...
	move.l	W_Base(pc),a5
	addq.l	#4,sp
	move.w	(sp)+,d6
	beq.s	BbSx
	subq.w	#1,d6
* Recopie dans la liste
	move.l	a3,a4
	move.l	T_BbPrio2(a5),a0
	move.w	d6,d0
BbPr1	move.l	(a0)+,(a3)+
	dbra	d0,BbPr1
	subq.w	#1,d6
	bmi.s	BbSx
* Classe (a bulle!)
BbPr2	moveq	#0,d1
	move.w	d6,d2
	move.l	a4,a2
	move.l	(a2)+,a0
BbPr3	move.l	(a2)+,a1
	move.w	BbY(a0),d0		* Compare
	cmp.w	BbY(a1),d0
	blt.s	BbPr5
	bne.s	BbPr4
	move.w	BbX(a0),d0
	cmp.w	BbX(a1),d0
	ble.s	BbPr5
BbPr4	exg	a0,a1
	move.l	a0,-8(a2)
	move.l	a1,-4(a2)
	addq.w	#1,d1
BbPr5	move.l	a1,a0
	dbra	d2,BbPr3
	tst.w	d1
	bne.s	BbPr2
* Renverser la table???
BbSx:	clr.l	(a3)
	tst.w	T_PriRev(a5)
	beq.s	BbSxX
* Renverse la table!!!
	move.l	T_BbPrio(a5),a0
	cmp.l	a3,a0
	bcc.s	BbSxX
BbSRv	move.l	(a0),d0
	move.l	-(a3),(a0)+
	move.l	d0,(a3)
	cmp.l	a3,a0
	bcs.s	BbSRv
* Fini!
BbSxX	movem.l	(sp)+,d2-d7/a2-a6
	rts

******* ROUTINE DE CALCUL DES PARAMS AFFICHAGE BOB/BLOC
*	A0-> 	Ecran
*	A2-> 	Descripteur image
*	A4-> 	Buffer calcul
*	D2-> 	X
*	D1->	Y
* 	D3-> 	Flags retournement
BobCalc	move.l	(a2),a1
	tst.l	4(a2)
	bne.s	BbS1
* Va calculer le masque!
	bsr	Masque
	bne	BbSOut
* Point chaud retourne?
BbS1:	tst.l	d3
	bmi.s	BbHt3
	move.w	6(a1),d0
	move.w	d0,d4
	lsl.w	#2,d4
	asr.w	#2,d4
	move.w	8(a1),d5
	eor.w	d0,d3
* En Y?
	btst	#14,d3
	beq.s	BbHt1
	neg.w	d5
	add.w	2(a1),d5
* En X?
BbHt1	btst	#15,d3
	beq.s	BbHt2
	move.w	(a1),d0
	lsl.w	#4,d0
	sub.w	d4,d0
	move.w	d0,d4
BbHt2	sub.w	d5,d1
	sub.w	d4,d2
* Nombre de plans
BbHt3	move.w	4(a1),d0
	cmp.w	EcNPlan(a0),d0
	bls.s	BbS1a
	move.w	EcNPlan(a0),d0
BbS1a:	subq.w	#1,d0
	move.w	d0,BbNPlan(a4)
	clr.w	BbESize(a4)
* Mots de controle?
	tst.w	BbACon(a4)
	beq.s	BbS1b
	bpl.s	BbS1d
	move.w	BbACon(a4),d0		* MASQUER le minterm
	bclr	#15,d0
	or.w	#%0000111100000000,d0
	tst.l	4(a2)
	bpl.s	BbS1c
	and.w	#%0000011111111111,d0
	bra.s	BbS1c
BbS1b	move.w	#%0000111111001010,d0	* FAIRE le minterm
	tst.l	4(a2)
	bpl.s	BbS1c
	move.w	#%0000011111001010,d0
BbS1c	move.w	d0,BbACon(a4)
BbS1d	move.w	d2,d0
	and.w	#$F,d2
	beq	BbND

******* DECALES!
	lsl.w	#8,d2			* Registres de controle
	lsl.w	#4,d2
	move.w	d2,BbACon1(a4)
	or.w	BbACon(a4),d2
	move.w	d2,BbACon0(a4)

	move.w	(a1),d4			* Taille en X
	lsl.w	#1,d4
	move.w	d4,d3
	move.w	2(a1),d5		* Taille en Y
	move.w	d4,d2
	mulu	d5,d2
	move.w	d2,BbTPLan(a4)		* Taille plan!
	add.w	d5,d2
	add.w	d5,d2
	move.w	d2,BbETPlan(a4)		* Effacement: prend les bords!

	move.w	d5,d2
	add.w	d1,d2
	cmp.w	BbLimB(a4),d2		* Limite en BAS!
	ble	BbDe2
	sub.w	BbLimB(a4),d2
	sub.w	d2,d5
	bls	BbSOut
BbDe2:
	moveq	#0,d7
	cmp.w	BbLimH(a4),d1		* Teste la limite en HAUT!
	bge.s	BbDe1
	sub.w	BbLimH(a4),d1
	neg.w	d1
	sub.w	d1,d5
	bls	BbSOut
	move.w	d1,d7
	mulu	d4,d7
	move.w	BbLimH(a4),d1
BbDe1:
	move.w	EcTLigne(a0),d2
	move.w	d2,d6
	mulu	d1,d6

	lsl.w	#3,d4
	move.w	d4,d1
	add.w	d0,d1
	clr.w	BbAMaskD(a4)
	cmp.w	BbLimD(a4),d1		* Teste la limite a DROITE
	ble.s	BbDe4
	sub.w	BbLimD(a4),d1
	and.w	#$FFF0,d1
	add.w	#16,d1
	sub.w	d1,d4
	bmi	BbSOut
	move.w	d0,d1
	and.w	#$000F,d1
	lsl.w	#1,d1
	lea	MCls2(pc),a0
	move.w	0(a0,d1.w),d1
	not.w	d1
	move.w	d1,BbAMaskD(a4)
BbDe4:
	moveq	#-1,d1
	cmp.w	BbLimG(a4),d0		* Teste la limite a GAUCHE
	bge.s	BbDe3
	move.w	d0,d1
	sub.w	BbLimG(a4),d0
	neg.w	d0
	sub.w	d0,d4
	bls	BbSOut
	add.w	#16,d4
	lsr.w	#4,d0
	lsl.w	#1,d0
	add.w	d0,d7
	bset	#31,d7
	subq.l	#2,d6
	lea	MCls2(pc),a0		* Masque a gauche
	and.w	#$000F,d1
	lsl.w	#1,d1
	move.w	0(a0,d1.w),d1
	move.w	BbLimG(a4),d0
BbDe3:	move.w	d1,BbAMaskG(a4)
	add.w	#16,d4

	lsr.w	#4,d0			* Adresse ecran
	lsl.w	#1,d0
	ext.l	d0			BUG !
	add.l	d0,d6
	lsr.l	#1,d6
	move.w	d6,BbAAEc(a4)

	lsr.w	#4,d4			* Modulo ecran
	move.w	d4,d0
	lsl.w	#1,d4
	sub.w	d4,d3
	move.w	d3,BbAModO(a4)
	sub.w	d4,d2
	move.w	d2,BbAModD(a4)

	move.w	d0,d1
	lea	BbAP(pc),a0
	tst.l	d7
	bpl.s	BbDe5
	addq.w	#1,d6			Suite BUG !
	subq.w	#1,d1
	addq.w	#2,d2
	bne.s	BbDe5
	lea	BbAL(pc),a0
BbDe5:	lsl.w	#6,d5
	or.w	d5,d1
	move.w	d1,BbESize(a4)
	or.w	d5,d0
	move.w	d0,BbASize(a4)
	move.w	d2,BbEMod(a4)
	move.w	d6,BbEAEc(a4)
	move.l	a0,BbADraw(a4)

	move.l	4(a2),a2		* Adresses bob
	lea	4(a2,d7.w),a2
	move.l	a2,BbAMask(a4)
	lea	10(a1,d7.w),a2
	move.l	a2,BbAData(a4)

	moveq	#0,d0
	rts

* Sortie
BbSOut	moveq	#-1,d0
	rts

* NON DECALES: Teste limites en H G
BbND:	move.w	d0,d2
	move.w	d1,d3
	moveq	#0,d4
	moveq	#0,d5
	cmp.w	BbLimG(a4),d0
	bge.s	BbS2
	move.w	BbLimG(a4),d4
	sub.w	d0,d4
	lsr.w	#4,d4
	move.w	BbLimG(a4),d0
BbS2:	cmp.w	BbLimH(a4),d1
	bge.s	BbS3
	move.w	BbLimH(a4),d5
	sub.w	d1,d5
	move.w	BbLimH(a4),d1
BbS3:	lsr.w	#4,d0
	lsl.w	#1,d0
	ext.l	d0			BUG !
	mulu	EcTLigne(a0),d1
	add.l	d0,d1
	lsr.l	#1,d1
	move.w	d1,BbAAEc(a4)
	move.w	d1,BbEAEc(a4)
	move.w	(a1),d6
	move.w	2(a1),d7
	move.w	d6,d0
	lsl.w	#1,d0
	move.w	d0,d1
	mulu	d7,d1
	move.w	d1,BbTPlan(a4)
	move.w	d1,BbETPlan(a4)
	mulu	d5,d0
	add.w	d4,d0
	add.w	d4,d0
	move.l	4(a2),a2
	lea	4(a2,d0.w),a2
	move.l	a2,BbAMask(a4)
	lea	10(a1,d0.w),a2
	move.l	a2,BbAData(a4)

	move.w	BbACon(a4),BbACon0(a4)
	clr.w	BbACon1(a4)
	move.w	d6,d0
	lsl.w	#4,d0
	add.w	d0,d2
	add.w	d7,d3
	move.w	d6,d0
	move.w	d7,d1
	cmp.w	BbLimD(a4),d2
	ble.s	BbS4
	sub.w	BbLimD(a4),d2
	lsr.w	#4,d2
	sub.w	d2,d0
BbS4:	cmp.w	BbLimB(a4),d3
	ble.s	BbS5
	sub.w	BbLimB(a4),d3
	sub.w	d3,d1
BbS5:	sub.w	d4,d0
	ble	BbSOut
	sub.w	d5,d1
	ble	BbSout
	sub.w	d0,d6
	lsl.w	#1,d6
	move.w	d6,BbAModO(a4)
	move.w	EcTLigne(a0),d6
	sub.w	d0,d6
	sub.w	d0,d6
	move.w	d6,BbAModD(a4)
	move.w	d6,BbEMod(a4)
	lsl.w	#6,d1
	or.w	d1,d0
 	move.w	d0,BbASize(a4)
	move.w	d0,BbESize(a4)
	lea	BbA16(pc),a0
	move.l	a0,BbADraw(a4)
	moveq	#0,d0
	rts

***********************************************************
*	RETOURNEUR DE SPRITES!

******* Initialisation: fabrique la table
RbInit	lea	TRetour(pc),a0
        moveq 	#0,d0
IRet1:  moveq 	#7,d3
        move.b 	d0,d1
IRet2:  lsr.b 	#1,d1
        roxl.b 	#1,d2
        dbra 	d3,IRet2
        move.b 	d2,(a0)+
        addq.b 	#1,d0
        bne.s 	IRet1
	rts
******* Fin, libere la memoire
RbEnd	rts

******* Retourne un sprite, s'il faut.
*	A0---> Descripteur
*	D0---> Flags seuls
Retourne
	move.l	(a0),d1
	beq.s	RetBobX
	move.l	d1,a1
	move.w	6(a1),d1
	and.w	#$C000,d1
	eor.w	d0,d1
	beq.s	RetBobX
* En X?
	btst	#15,d1
	beq.s	RetBb1
	bsr	RBobX
* En Y?
RetBb1	btst	#14,d1
	beq.s	RetBb2
	bsr	RBobY
* Poke les flags
RetBb2	move.w	6(a1),d1
	and.w	#$3FFF,d1
	or.w	d0,d1
	move.w	d1,6(a1)
* Ca y est!
RetBobX	rts

******* Retourne le bob en X
RBobX	movem.l a0-a3/d0-d7,-(sp)
* Retourne le point chaud
	move.w	6(a1),d0
	lsl.w	#2,d0
	asr.w	#2,d0
	move.w	(a1),d6
	move.w	d6,d1
	lsl.w	#4,d1
	sub.w	d0,d1
	move.w	d1,6(a1)
* Retourne le dessin
	moveq	#0,d0
	moveq	#0,d1
	lea	TRetour(pc),a3
	move.w	2(a1),d7
	move.w	4(a1),d3
	lea	10(a1),a1
	move.l	a0,-(sp)
	bsr	RBbX
	move.l	(sp)+,a0
* Retourne le masque
	move.l	4(a0),d2
	ble.s	RBobXx
	move.l	d2,a1
	addq.l	#4,a1
	moveq	#0,d3
	bsr	RBBis
* Fini
RBobXx	movem.l (sp)+,a0-a3/d0-d7
	rts
******* Retourne le bob en Y
RBobY	movem.l a0-a2/d0-d7,-(sp)
* Retourne le point chaud
	move.w	2(a1),d7
	move.w	d7,d0
	sub.w	8(a1),d0
	move.w	d0,8(a1)
* Retourne le dessin
	move.w	(a1),d6
	move.w	4(a1),d5
	lea	10(a1),a1
	move.l	a0,-(sp)
	bsr	RBbY
	move.l	(sp)+,a0
* Retourne le masque
	move.l	4(a0),d0
	ble.s	RBobYx
	move.l	d0,a1
	addq.l	#4,a1
	moveq	#0,d5
	bsr	RBbY1
* Fini
RBobYx	movem.l (sp)+,a0-a2/d0-d7
	rts

************************
* Retourne en X
* A1-> Ad plan
* D7-> Ty
* D6-> Tx
* D3-> Nb plans
RBbX	subq.w	#1,d7		* Base cpt Y
	subq.w	#1,d3		* Cpt nombre de plans
	moveq	#0,d4
	move.w	d6,d4
	lsr.w	#1,d6
	subq.w	#1,d6
	move.w	d6,a2		* Base cpt en X
RBBis	btst	#0,d4
	bne.s	RBbI0
* Nombre PAIR de plans
RBbx0	move.w	d7,d5		* Cpt Y
RBbx1	add.l	d4,a1
	move.l	a1,a0
	move.w	a2,d6
RBbx2	move.b	-(a0),d0
	move.b 	(a1),d1
	move.b	0(a3,d1.w),(a0)
	move.b	0(a3,d0.w),(a1)+
	move.b 	-(a0),d0
	move.b	(a1),d1
	move.b	0(a3,d1.w),(a0)
	move.b	0(a3,d0.w),(a1)+
	dbra	d6,RBbx2
	dbra	d5,RBbX1
	dbra	d3,RBbX0
	rts
* Nombre IMPAIR de plans
RBbI0	move.w	d7,d5		* Cpt Y
RBbI1	add.l	d4,a1
	move.l	a1,a0
	move.b	-(a0),d0
	move.b 	(a1),d1
	move.b	0(a3,d1.w),(a0)
	move.b	0(a3,d0.w),(a1)+
	move.w	a2,d6
	bmi.s	RBbI3
RBbI2	move.b	-(a0),d0
	move.b 	(a1),d1
	move.b	0(a3,d1.w),(a0)
	move.b	0(a3,d0.w),(a1)+
	move.b 	-(a0),d0
	move.b	(a1),d1
	move.b	0(a3,d1.w),(a0)
	move.b	0(a3,d0.w),(a1)+
	dbra	d6,RBbI2
RBbI3	dbra	d5,RBbI1
	dbra	d3,RBbI0
	rts

************************
* Retournement VERTICAL
* D5= NPlan
* D6= TX
* D7= TY
RBbY   	move.w  d6,d4
        lsl.w   #1,d4
        ext.l   d4
        move.w  d7,d3
        lsr.w   #1,d3
        mulu    d4,d3
	move.l	d4,d2
        lsr.w   #1,d7
        bcc.s   RBbY0
	add.l	d4,d2
        add.l   d4,d3
RBbY0   neg.l	d2
	subq.w  #1,d7
        move.w  d7,a2
        subq.w  #1,d6
	subq.w	#1,d5
	lsl.w	#1,d4
* Boucle de retournement
RBbY1   add.w   d3,a1
        lea     0(a1,d2.w),a0
        move.w  a2,d7
RBbY2   move.w  d6,d1
RBbY3   move.w  (a1),d0
        move.w  (a0),(a1)+
        move.w  d0,(a0)+
        dbra    d1,RBbY3
        sub.l   d4,a0
        dbra    d7,RBbY2
        dbra    d5,RBbY1
        rts

***********************************************************
*	CALCUL DU MASQUE, 1 MOT BLANC A DROITE!
*	A2= descripteur
Masque:
*******
	movem.l	d1-d7/a0-a2,-(sp)
	move.l	(a2),a1
	move.w	(a1),d2
	lsl.w	#1,d2
	mulu	2(a1),d2		* D2= Taille plan
	move.l	d2,d3
	addq.l	#4,d3			* D3= Taille memoire
	move.w	4(a1),d4
	subq.w	#2,d4			* D4= Nb de plans
	move.w	d2,d5
	lsr.w	#1,d5
	subq.w	#1,d5
* Reserve la memoire pour le masque
	move.l	4(a2),d0
	bne.s	Mas0
MasM	move.l	d3,d0
	bsr	ChipMm2
	beq.s	MasErr
	move.l	d0,4(a2)
* Calcule le masque
Mas0:	bmi.s	MasM
	move.l	d0,a2			* Adresse du masque
	move.l	d3,(a2)+		* Taille du masque
	lea	10(a1),a1		* Pointe le premier plan
Mas2:	move.l	a1,a0
	move.w	(a0),d0
	move.w	d4,d3
	bmi.s	Mas4
Mas3:	add.l	d2,a0
	or.w	(a0),d0
	dbra	d3,Mas3
Mas4:	move.w	d0,(a2)+
	addq.l	#2,a1
	dbra	d5,Mas2
* Pas d'erreur
	movem.l	(sp)+,d1-d7/a0-a2
	moveq	#0,d0
	rts
* Erreur!
MasErr:	movem.l	(sp)+,d1-d7/a0-a2
	moveq	#-1,d0
	rts

********************************************************
*	EFFACEMENT DE TOUS LES BOBS DES ECRANS
********
BobEff:	movem.l	d2-d7/a2-a6,-(sp)
	lea	Circuits,a6
	move.l	T_BbDeb(a5),d0
	beq	BbExX

******* Initialise le blitter
	bsr	OwnBlit
	move.w	#0,BltModA(a6)
	move.w	#0,BltCon1(a6)
	moveq	#-1,d1
	move.w	d1,BltMaskG(a6)
	move.w	d1,BltMaskD(a6)

******* Explore la liste des bobs
BbE0:	move.l	d0,a5
	tst.w	BbECpt(a5)			* Compteur PUT BOB
	bne.s	BbE5
	move.l	BbEc(a5),a3
	lea	EcLogic(a3),a3
	move.w	BbDCur2(a5),d4
	lea	0(a5,d4.w),a4

	move.w	BbDASize(a4),d2			* D2= BltSize
	beq.s	BbE4
	move.w	BbDAEc(a4),d3			* D3= Decalage ecran
	ext.l	d3
	lsl.l	#1,d3
	move.w	BbEff(a5),d4
	bne.s	BbEFc

* Effacement NORMAL
	tst.l	BbDABuf(a4)
	beq.s	BbE4
	move.w	BbDAPlan(a4),d1
	move.w	BbDNPlan(a4),d0
	bsr	BlitWait
	move.w	BbDMod(a4),BltModD(a6)
	move.l	BbDABuf(a4),BltAdA(a6)		* Adresse buffer
	move.w	#%0000100111110000,BltCon0(a6)
BbE1:	lsr.w	#1,d1
	bcc.s	BbE3
	move.l	(a3),a2
	add.l	d3,a2
	bsr	BlitWait
	move.l	a2,BltAdD(a6)
	move.w	d2,BltSize(a6)
BbE3:	addq.l	#4,a3
	dbra	d0,BbE1
* Un autre?
BbE4:	move.l	BbNext(a5),d0
	bne.s	BbE0
	bra.s	BbEx
BbE5:	subq.w	#1,BbECpt(a5)
	bne.s	BbE4
	bra.s	BbE4

* Effacement COLORE!
BbEfC:	subq.w	#1,d4
	move.w	BbDAPlan(a4),d1
	move.w	BbDNPlan(a4),d0
	bsr	BlitWait
	move.w	BbDMod(a4),BltModD(a6)
	move.w	#%0000000111110000,BltCon0(a6)
	moveq	#0,d5
BbEfc1:
	lsr.w	#1,d4
	subx.w	d5,d5
	lsr.w	#1,d1
	bcc.s	BbEfc4
	move.l	(a3),a2
	add.l	d3,a2
	bsr	BlitWait
	move.w	d5,BltDatA(a6)
	move.l	a2,BltAdD(a6)
	move.w	d2,BltSize(a6)
BbEfc4:	addq.l	#4,a3
	moveq	#0,d5
	dbra	d0,BbEfc1
* Un autre?
	move.l	BbNext(a5),d0
	bne	BbE0

* FINI: remet le blitter
BbEx:	bsr	BlitWait
	bsr	DOwnBlit
BbExX:	movem.l	(sp)+,d2-d7/a2-a6
	rts

********************************************************
*	SAISIE  ET DESSIN DE TOUS LES BOBS
********
BobAff	movem.l	d2-d7/a2-a6,-(sp)
	lea	Circuits,a6
	bsr	OwnBlit

******* SAISIE
	move.l	T_BbDeb(a5),d0
	beq	BbGx
* Initialise le blitter
	move.w	#0,BltModD(a6)
	move.w	#%0000100111110000,BltCon0(a6)
	move.w	#0,BltCon1(a6)
	moveq	#-1,d1
	move.w	d1,BltMaskG(a6)
	move.w	d1,BltMaskD(a6)

* Explore les bobs
BbG0:	move.l	d0,a5
	tst.w	BbDCpt(a5)			* Nombre de saisies
	beq.s	BbG4
	tst.w	BbEff(a5)			* Decor colore?
	bne.s	BbG4

	move.l	BbEc(a5),a3			* Adresse ecran
	lea	EcLogic(a3),a3
	move.w	BbDCur1(a5),d4
	lea	0(a5,d4.w),a4
	tst.l	BbDABuf(a4)			* Adress buffer 0?
	beq.s	BbG4
	move.w	BbDASize(a4),d2			* D2= BltSize
	beq.s	BbG4
	subq.w	#1,BbDCpt(a5)			* Une saisie de moins

	move.w	BbDAEc(a4),d3			* D3= Decalage ecran
	ext.l	d3
	lsl.l	#1,d3
	move.w	BbDAPlan(a4),d1
	move.w	BbDNPlan(a4),d0

	bsr	BlitWait
	move.l	BbDABuf(a4),d7
	move.l	d7,BltAdD(a6)			* Adresse buffer
	move.w	BbDMod(a4),BltModA(a6)
BbG1:	lsr.w	#1,d1
	bcc.s	BbG3
	move.l	(a3),a2
	add.l	d3,a2
	bsr	BlitWait
	move.l	a2,BltAdA(a6)
	move.w	d2,BltSize(a6)
BbG3:	addq.l	#4,a3
	dbra	d0,BbG1

* Un autre?
BbG4:	move.l	BbNext(a5),d0
	bne.s	BbG0
BbGx:

*******	AFFICHAGE
	move.l	W_Base(pc),a5
	move.l	T_BbPrio(a5),a5
* Explore tous les bobs
	move.l	(a5)+,d0
	beq	BbAx
* Valeurs communes au 16 et autre
BbA0:	move.l	d0,a4
	move.w	BbASize(a4),d2
	beq.s	BbAn
* Va retourner le bob???
	move.w	BbRetour(a4),d0
	move.l	BbARetour(a4),a0
	bsr	Retourne
* Va dessiner
	moveq	#0,d4
	move.w	BbTPlan(a4),d4
	move.l	BbAData(a4),a0
	move.l	BbEc(a4),a3
	lea	EcLogic(a3),a3
	move.w	BbAModD(a4),d0
	move.l	BbADraw(a4),a1
	bsr	BlitWait
	move.w	d0,BltModC(a6)
	move.w	d0,BltModD(a6)
	move.l	BbAMask(a4),d5
	jsr	(a1)
* Un autre?
BbAn:	move.l	(a5)+,d0
	bne	BbA0
******* FINI: remet le blitter
BbAx:	bsr	BlitWait
	bsr	DOwnBlit
	movem.l	(sp)+,d2-d7/a2-a6
	rts

******* ROUTINE DESSIN au pixel
BbAp:	bmi	BMAp
	move.w	BbACon0(a4),BltCon0(a6)
	move.w	BbACon1(a4),BltCon1(a6)
	move.w	BbAAEc(a4),d3
	ext.l	d3
	lsl.l	#1,d3
	move.w	BbAModO(a4),d0
	move.w	d0,BltModA(a6)
	move.w	d0,BltModB(a6)
	move.w	BbAMaskG(a4),BltMaskG(a6)
	move.w	BbAMaskD(a4),BltMaskD(a6)
	move.w	#0,BltDatA(a6)
	move.w	BbAPlan(a4),d1
	move.w	BbNPlan(a4),d0
BbAp1:	lsr.w	#1,d1
	bcc.s	BbAp4
BbAp2:
	move.l	(a3),a2
	add.l	d3,a2
	bsr	BlitWait
	move.l	d5,BltAdA(a6)
	move.l	a0,BltAdB(a6)
	move.l	a2,BltAdC(a6)
	move.l	a2,BltAdD(a6)
	move.w	d2,BltSize(a6)
BbAp4:	add.l	d4,a0
	addq.l	#4,a3
	dbra	d0,BbAp1
	rts

******* ROUTINE DESSIN au pixel trop grand
BbAL:	bmi	BmAp
	move.w	d2,d6
	lsr.w	#6,d6
	and.w	#%0111111,d2
	or.w	#%1000000,d2
	move.w	BbACon0(a4),BltCon0(a6)
	move.w	BbACon1(a4),BltCon1(a6)
	move.w	BbAAEc(a4),d3
	ext.l	d3
	lsl.l	#1,d3
	move.w	BbAModO(a4),d0
	move.w	d0,BltModA(a6)
	move.w	d0,BltModB(a6)
	move.w	BbAMaskG(a4),BltMaskG(a6)
	move.w	BbAMaskD(a4),BltMaskD(a6)
	move.w	#0,BltDatA(a6)
	move.w	BbAPlan(a4),d1
	move.w	BbNPlan(a4),d0
BbAl1:	lsr.w	#1,d1
	bcc.s	BbAl5
BbAl2:
	move.l	(a3),a2
	add.l	d3,a2
	move.w	d6,d7
	bsr	BlitWait
	move.l	d5,BltAdA(a6)
	move.l	a0,BltAdB(a6)
	move.l	a2,BltAdC(a6)
	move.l	a2,BltAdD(a6)
BbAl3	bsr	BlitWait
	move.w	#0,BltDatA(a6)
	move.w	d2,BltSize(a6)
	subq.w	#1,d7
	bne.s	BbAl3
BbAl5:	add.l	d4,a0
	addq.l	#4,a3
	dbra	d0,BbAl1
	rts

******* ROUTINE DESSIN: Multiple de 16!
BbA16:	bmi	BMA16
	move.w	BbAAEc(a4),d3		* D3= Decalage ecran
	ext.l	d3
	lsl.l	#1,d3
	move.w	BbAModO(a4),d0		* Valeur MODULO
	move.w	d0,BltModA(a6)
	move.w	d0,BltModB(a6)
	move.w	BbACon0(a4),BltCon0(a6)	* Registres de controle
	move.w	#0,BltCon1(a6)
	moveq	#-1,d0
	move.w	d0,BltMaskG(a6)
	move.w	d0,BltMaskD(a6)
	move.w	BbAPlan(a4),d1
	move.w	BbNPlan(a4),d0
BbA1:	lsr.w	#1,d1
	bcc.s	BbA4
	move.l	(a3),a2
	add.l	d3,a2
	bsr	BlitWait
	move.l	d5,BltAdA(a6)
	move.l	a0,BltAdB(a6)
	move.l	a2,BltAdC(a6)
	move.l	a2,BltAdD(a6)
	move.w	d2,BltSize(a6)
BbA4:	add.l	d4,a0
	addq.l	#4,a3
	dbra	d0,BbA1
	rts

******* ROUTINE DESSIN SANS MASQUE, Multiple de 16!
BMA16:	move.w	BbAAEc(a4),d3
	ext.l	d3
	lsl.l	#1,d3
	move.w	BbAModO(a4),BltModB(a6)

	move.w	BbACon0(a4),d0		  *If minterm replace use
	cmp.b	#$CA,d0			  *fast blit , ideal for
	bne.s	Normal_BMA16		  *fast icon pasting in games!
	move.w	BbAModO(a4),BltModA(a6)	  *
	move.w	#%100111110000,BltCon0(a6)
	move.w	#0,BltCon1(a6)		  *
	moveq	#-1,d0			  *
	move.w	d0,BltMaskG(a6)		  *
	move.w	d0,BltMaskD(a6)		  *
	move.w	d0,BltDatB(a6)		  *
	move.w	d0,BltDatC(a6)		  *
	move.w	BbAPlan(a4),d1		  *
	move.w	BbNPlan(a4),d0		  *
BMA1f:	lsr.w	#1,d1			  *
	bcc.s	BMA3f			  *
	move.l	(a3),a2			  *
	add.l	d3,a2			  *
	bsr	BlitWait		  *
	move.l	a0,BltAdA(a6)		  *
	move.l	a2,BltAdD(a6)		  *
	move.w	d2,BltSize(a6)		  *
BMA3f:	add.l	d4,a0			  *
	addq.l	#4,a3			  *
	dbra	d0,BMA1f		  *
	rts				  *

Normal_BMA16:
	move.w	BbACon0(a4),BltCon0(a6)
	move.w	#0,BltCon1(a6)
	moveq	#-1,d0
	move.w	d0,BltMaskG(a6)
	move.w	d0,BltMaskD(a6)
	move.w	d0,BltDatA(a6)
	move.w	BbAPlan(a4),d1
	move.w	BbNPlan(a4),d0
BMA1:	lsr.w	#1,d1
	bcc.s	BMA3
	move.l	(a3),a2
	add.l	d3,a2
	bsr	BlitWait
	move.l	a0,BltAdB(a6)
	move.l	a2,BltAdC(a6)
	move.l	a2,BltAdD(a6)
	move.w	d2,BltSize(a6)
BMA3:	add.l	d4,a0
	addq.l	#4,a3
	dbra	d0,BMA1
	rts

******* ROUTINE DESSIN SANS MASQUE, Pixel!
BMAp:
	move.w	BbAAEc(a4),d3
	ext.l	d3
	lsl.l	#1,d3

	move.w	BbAModO(a4),BltModB(a6)
	move.w	BbACon0(a4),BltCon0(a6)
	move.w	BbACon1(a4),BltCon1(a6)
	move.w	BbAMaskG(a4),BltMaskG(a6)
	move.w	BbAMaskD(a4),BltMaskD(a6)
	move.w	#-1,BltDatA(a6)
	move.w	BbAPlan(a4),d1
	move.w	BbNPlan(a4),d0
BMAp1:	lsr.w	#1,d1
	bcc.s	BMAp4
	move.l	(a3),a2
	add.l	d3,a2
	bsr	BlitWait
	move.l	a0,BltAdB(a6)
	move.l	a2,BltAdC(a6)
	move.l	a2,BltAdD(a6)
	move.w	d2,BltSize(a6)
BMAp4:	add.l	d4,a0
	addq.l	#4,a3
	dbra	d0,BMAp1
	rts

******* ROUTINE DESSIN SANS MASQUE au pixel trop grand
BmAL:	move.w	d2,d6
	lsr.w	#6,d6
	and.w	#%0111111,d2
	or.w	#%1000000,d2
	move.w	BbACon0(a4),BltCon0(a6)
	move.w	BbACon1(a4),BltCon1(a6)

	move.w	BbAAEc(a4),d3
	ext.l	d3
	lsl.l	#1,d3

	move.w	BbAModO(a4),BltModB(a6)
	move.w	BbAMaskG(a4),BltMaskG(a6)
	move.w	BbAMaskD(a4),BltMaskD(a6)
	move.w	#0,BltDatA(a6)
	move.w	BbAPlan(a4),d1
	move.w	BbNPlan(a4),d0
BmAl1:	lsr.w	#1,d1
	bcc.s	Bmal7
	move.l	(a3),a2
	add.l	d3,a2
	move.w	d6,d7
	bsr	BlitWait
	move.l	a0,BltAdB(a6)
	move.l	a2,BltAdC(a6)
	move.l	a2,BltAdD(a6)
Bmal3:	bsr	BlitWait
	move.w	#-1,BltDatA(a6)
	move.w	d2,BltSize(a6)
	subq.w	#1,d7
	bne.s	Bmal3
Bmal7:	add.l	d4,a0
	addq.l	#4,a3
	dbra	d0,BmAl1
	rts


