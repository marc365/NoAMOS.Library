; 	Table des sauts aux affichages texte
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

TAdCol		dc.l CZero-TAdCol,CNorm-TAdCol
		dc.l CInv-TAdCol,CUn-TAdCol
		dc.l CNul-TAdCol

******************************************************************
*	Screen copy a0,d0,d1,d4,d5 to a1,d2,d3,d6
*
*	a0 Origin Bit Map Struc.   a1 Destination Bit Map Struc.
*	d0 Origin X (16 a factor!) d2 Destination X (16 a factor!)
*	d1 Origin Y		   d3 Destination Y
*		  	d4 Width  X (Must be multiple of 16!)
*			d5 height Y
*			d6 Minterm
*
*	If minterm is $CC and d0,d2,d4 are on word boundaries
*	then blit is done and result is 0 otherwise not done
*	and result is -1.
*
*	Uses only A and D channels for blit,
*	therefore twice as fast as normal screen copy!
*

WRastPort	ds.l	1

WScCpy:	cmp.b	#$CC,d6
	bne.s	NoWScCpy
	move.w	d0,d7
	and.w	#$f,d7
	bne.s	NoWScCpy
	move.w	d2,d7
	and.w	#$f,d7
	bne.s	NoWScCpy
	move.w	d4,d7
	and.w	#$f,d7
	bne.s	NoWScCpy
	bra.s	DoWScCpy
NoWScCpy:
	moveq.l	#-1,d7
	rts
DoWScCpy:
	moveq.l	#0,d7
	cmp.w	d1,d3
	blt.s	Ascending_Blit
	bgt.s	Descending_Blit
	cmp.w	d0,d2
	blt.s	Ascending_Blit
Descending_Blit:
	addq.l	#2,d7

	add.w	d4,d0
	sub.w	#16,d0
	add.w	d5,d1
	subq.w	#1,d1

	add.w	d4,d2
	sub.w	#16,d2
	add.w	d5,d3
	subq.w	#1,d3
Ascending_Blit:
	lsl.w	#6,d5
	lsr.w	#4,d0
	lsl.w	#1,d0

	lsr.w	#4,d2
	lsl.w	#1,d2

	lsr.w	#4,d4
	lsl.w	#1,d4
	move.w	(a0),d6
	mulu	d6,d1
	and.l	#$FFFF,d0
	add.l	d1,d0
	sub.w	d4,d6
	move.w	(a1),d1
	mulu	d1,d3
	and.l	#$FFFF,d2
	add.l	d3,d2
	sub.w	d4,d1
	lsr.w	#1,d4
	add.w	d4,d5
	moveq.l	#0,d4
	move.b	5(a0),d4
	moveq.l	#0,d3
	move.b	5(a1),d3
	lea	8(a0),a0
	lea	8(a1),a1
	lea	circuits,a6
	bsr	OwnBlit
	move.w	#%100111110000,BltCon0(a6)
	move.w	d7,BltCon1(a6)
	moveq.l	#-1,d7
	move.w	d7,BltDatB(a6)
	move.w	d7,BltDatC(a6)
	move.w	d7,BltMaskD(a6)
	move.w	d7,BltMaskG(a6)
	move.w	d6,BltModA(a6)
	move.w	d1,BltModD(a6)
	bra.s	Start_Blit
Blit_Loop:
	move.l	(a0)+,a2
	add.l	d0,a2
	move.l	(a1)+,a3
	add.l	d2,a3
	bsr	BlitWait
	move.l	a2,BltAdA(a6)
	move.l	a3,BltAdC(a6)
	move.l	a3,BltAdD(a6)
	move.w	d5,BltSize(a6)
Start_Blit:
	subq.w	#1,d4
	bmi.s	Blit_out
	dbra	d3,Blit_Loop
Blit_out:
	bsr	BlitWait
	bsr	DownBlit
	moveq.l	#0,d7
	rts

***********************************************************
*	Calcul de PEN/PAPER
***********************************************************
AdColor:move.w	WiNPlan(a5),d1

	move.w	WiPaper(a5),d2
	move.w	WiPen(a5),d3
	move.w	d2,d4
	move.w	d3,d5
	lea	TAdCol(pc),a0
	lea	WiColor(a5),a1
	lea	WiColFl(a5),a2

ACol:	moveq	#16,d0
	btst	d1,WiSys+1(a5)
	bne.s	ACol1
	clr.w	d0
	lsr.w	#1,d2
	roxl.w	#1,d0
	lsr.w	#1,d3
	roxl.w	#1,d0
	lsl.w	#2,d0
ACol1	move.l	0(a0,d0.w),d0
	add.l	a0,d0
	move.l	d0,(a1)+

	lsr.w	#1,d4
	subx.w	d0,d0
	move.w	d0,(a2)+
	lsr.w	#1,d5
	subx.w	d0,d0
	move.w	d0,(a2)+

	dbra	d1,ACol

	rts

;-----------------------------------------------------------------
; **** *** **** ****
; *     *  *  * *	******************************************
; ****  *  *  * ****	* SCREENS
;    *  *  *  *    *	******************************************
; ****  *  **** ****
;-----------------------------------------------------------------

***********************************************************
*	DEMARRAGE A FROID DES ECRANS
*	D0= taille memoire pour liste copper
***********************************************************
EcInit:
* Reserve la memoire pour liste copper ecrans
	move.l	#EcTCop,d0
	bsr	FastMm
	beq	GFatal
	move.l	d0,T_EcCop(a5)
* Petit buffer en CHIP pour les operations graphiques
	move.l	#256,d0
	bsr	ChipMm
	beq	GFatal
	move.l	d0,T_ChipBuf(a5)
* Taille affichage par defaut
	move.w	#311+EcYBase,T_EcYMax(a5)	PAL
	move.l	$4.w,a0
	cmp.b	#50,530(a0)			VBlankFrequency=50?
	beq.s	.NoNTSC
	move.w	#261+EcYBase,T_EcYMax(a5)	NTSC!
.NoNTSC
* Autre inits
	bsr	EcRaz
	bsr	EcCopper
	tst.b	T_AMOSHere(a5)
	beq.s	.Skip
	lea	Circuits,a6
	clr.w	CopJmp1(a6)
	move.w	#$82A0,DmaCon(a6)
.Skip
; Installe le vecteur
	lea	EcIn(pc),a0
	move.l	a0,T_EcVect(a5)
	moveq	#0,d0
	rts

**********************************************************
*	ARRET FINAL DES ECRANS
**********************************************************
EcEnd:	moveq	#0,d1
	moveq	#EcMax-1,d2
	bsr	EcDAll
	bsr	RazCBloc
	bsr	RazBloc
	moveq	#-1,d1
	bsr	TrDel
* Efface la memoire du buffer CHIP
	move.l	T_ChipBuf(a5),d0
	beq.s	.skip
	move.l	d0,a1
	move.l	#256,d0
	bsr	FreeMm
.skip
* Efface la memoire liste copper
	move.l	T_EcCop(a5),d0
	beq.s	EcEnd1
	move.l	d0,a1
	move.l	#EcTCop,d0
	bsr	FreeMm

EcEnd1:	rts


******* Jumps to screen functions
EcIn:	bra	EcRaz		;Raz:
	bra	EcCopper	;CopMake:
	bra	EcCopper	;*
	bra	EcCree		;Cree:
	bra	EcDel		;Del:
	bra	EcFirst		;First:
	bra	EcLast		;Last:
	bra	EcMarch		;Active:
	bra	EcForceCop	;CopForce:
	bra	EcView		;AView:
	bra	EcOffs		;OffSet:
	bra	EcEnd		;Visible:
	bra	EcDAll		;DelAll:
	bra	EcGCol		;GCol:
	bra	EcSCol		;SCol:
	bra	EcSPal		;SPal:
	bra	EcSColB		;SColB:
	bra	FlStop		;FlRaz:
	bra	FlStart		;Flash:
	bra	ShStop		;ShRaz:
	bra	ShStart		;Shift:
	bra	EcHide		;EHide:
	bra	MakeCBloc	;CBlGet:
	bra	DrawCBloc	;CBlPut:
	bra	FreeCBloc	;CBlDel:
	bra	RazCBloc	;CBlRaz:
	bra	EcLibre		;Libre:
	bra	EcCClo		;CCloEc:
	bra	EcCrnt		;Current:
	bra	EcDouble	;Double:
	bra	ScSwap		;SwapSc:
	bra	ScSwapS		;SwapScS:
	bra	EcAdres		;AdrEc:
	bra	Duale		;SetDual:
	bra	DualP		;PriDual:
	bra	EcCls		;ClsEc:
	bra	SPat		;Pattern:
	bra	TGFonts		;GFonts:
	bra	TFFonts		;FFonts:
	bra	TGFont		;GFont:
	bra	TSFont		;SFont:
	bra	TSClip		;SetClip:
	bra	MakeBloc	;- BlGet:		Routine blocs normaux
	bra	DelBloc		;-BlDel:
	bra	RazBloc		;-BlRaz:
	bra	DrawBloc	;-BlPut:
	bra	SliVer		;- VerSli:		Slider vertical
	bra	SliHor		;- HorSli:		Slider horizontal
	bra	SliSet		;- SetSli:		Set slider params
	bra	StaMn		;- MnStart:	Sauve l'ecran
	bra	StoMn		;- MnStop:		Remet l'ecran
	bra	TRDel		;- RainDel:	Delete RAINBOW
	bra	TRSet		;- RainSet:	Set RAINBOW
	bra	TRDo		;- RainDo:		Do RAINBOW
	bra	TRHide		;- RainHide:	Hide / Show RAINBOW
	bra	TRVar		;- RainVar:	Var RAINBOW
	bra	FadeTOn		;- FadeOn:		Fade
	bra	FadeTOf		;- FadeOf:		Fade Off
	bra	TCopOn		;- CopOnOff:	Copper ON/OFF
	bra	TCopRes		;- CopReset:	Copper RESET
	bra	TCopSw		;- CopSwap:	Copper SWAP
	bra	TCopWt		;- CopWait:	Copper WAIT
	bra	TCopMv		;- CopMove:	Copper MOVE
	bra	TCopMl		;- CopMoveL:	Copper MOVEL
	bra	TCopBs		;- CopBase:	Copper BASE ADDRESS
	bra	TAbk1		;- AutoBack1:	Autoback 1
	bra	TAbk2		;- AutoBack2:	Autoback 2
	bra	TAbk3		;- AutoBack3:	Autoback 3
	bra	TAbk4		;- AutoBack4:	Autoback 4
	bra	TPaint		;- SuPaint:	Super paint!
	bra	RevBloc		;- BlRev:		Retourne le bloc
	bra	RevTrap		;- DoRev:		Retourne dans la banque
	bra	TAmosWB		;- AMOS_WB		AMOS/WorkBench
	bra	WScCpy		;- ScCpyW		New_W_2.s
	bra	TMaxRaw		;- MaxRaw		Maximum raw number
	bra	TNTSC		;- NTSC		NTSC?
	bra	SliPour		;- PourSli		Calculs slider

***********************************************************
*	Instructions de gestion des ecrans
***********************************************************

******* MAX RAW
TMaxRaw	move.w	T_EcYMax(a5),d1
	sub.w	#EcYBase,d1
	ext.l	d1
	moveq	#0,d0
	rts
******* NTSC?
TNTSC	moveq	#0,d0
	moveq	#0,d1			PAL
	move.l	$4.w,a0
	cmp.b	#50,530(a0)		VBlankFrequency=50?
	beq.s	.NoNTSC
	moveq	#-1,d1			NTSC!
.NoNTSC	rts

******* SCREEN SWAP D1
ScSwap:	movem.l	d1-d7/a1-a6,-(sp)
	bsr	EcGet
	beq	EcE3
	move.l	d0,a4
	btst	#BitDble,EcFlags(a4)
	beq	EcOk
	move.w	EcNumber(a4),d0
	lea	T_SwapList(a5),a0
	tst.l	(a0)
	beq.s	ScSw2
ScSw1:	cmp.w	SwapL-2(a0),d0		* Screen already swapped!
	beq	EcOk
	lea	SwapL(a0),a0
	tst.l	(a0)
	bne.s	ScSw1
ScSw2:	move.w	d0,SwapL-2(a0)
	lsl.w	#6,d0
	add.w	#CopL1*EcMax,d0
	lea	T_CopMark(a5),a1	* Garde l'adresse pour la fin!
	add.w	d0,a1
	move.l	a0,a6
	addq.l	#4,a0
	move.w	EcNPlan(a4),d0		* Nombre de bit planes
	subq.w	#1,d0
	move.w	d0,(a0)+
	move.l	EcDEcran(a4),d2
	lea	EcLogic(a4),a2
	lea	EcPhysic(a4),a3
	move.w	d0,d3
ScSw3:	move.l	(a2),d1			* Screen swap!
	move.l	(a3),(a2)+
	move.l	d1,(a3)+
	add.l	d2,d1
	move.l	d1,(a0)+
	dbra	d3,ScSw3
	lea	EcLogic(a4),a0		* Update les outputs!
	lea	EcCurrent(a4),a2
	move.l	Ec_BitMap(a4),a3
	lea	bm_Planes(a3),a3
	move.w	d0,d3
ScSw4	move.l	(a0),(a2)+
	move.l	(a0)+,(a3)+
	dbra	d3,ScSw4
* Autorise le screen swap
	tst.w	T_CopON(a5)		* Pas si COPPER OFF!
	beq	EcOk
	btst	#2,EcCon0+1(a4)		* Interlace?
	bne	EcOk
	clr.l	SwapL(a6)		* Empeche le suivant
	move.l	a1,(a6)
	bra	EcOk

******* SCREEN SWAP DE TOUS LES ECRANS UTILISATEUR
ScSwapS	movem.l	d1-d7/a1-a6,-(sp)
	lea	T_EcAdr(a5),a1
	moveq	#8-1,d6
	lea	T_SwapList(a5),a0
	clr.l	(a0)
* Explore tous les ecrans
ScSwS0:	move.l	(a1)+,d0
	bne.s	ScSwS2
ScSwS1:	dbra	d6,ScSwS0
	bra	EcOk
* Swappe un ecran!
ScSwS2:	move.l	d0,a4
	btst	#BitDble,EcFlags(a4)
	beq.s	ScSwS1
	move.w	EcNumber(a4),d0
	move.w	d0,SwapL-2(a0)
	lsl.w	#6,d0
	add.w	#CopL1*EcMax,d0
	lea	T_CopMark(a5),a2	* Garde l'adresse pour la fin!
	add.w	d0,a2
	move.l	a2,d7
	move.l	a0,a6
	addq.l	#4,a0
	move.w	EcNPlan(a4),d0		* Nombre de bit planes
	subq.w	#1,d0
	move.w	d0,(a0)+
	move.l	EcDEcran(a4),d2
	lea	EcLogic(a4),a2
	lea	EcPhysic(a4),a3
	move.w	d0,d3
ScSwS3:	move.l	(a2),d1			* Screen swap!
	move.l	(a3),(a2)+
	move.l	d1,(a3)+
	add.l	d2,d1
	move.l	d1,(a0)+
	dbra	d3,ScSwS3
	lea	EcLogic(a4),a0		* Update les outputs!
	lea	EcCurrent(a4),a2
	move.l	Ec_BitMap(a4),a3
	lea	bm_Planes(a3),a3
	move.w	d0,d3
ScSwS4	move.l	(a0),(a2)+
	move.l	(a0)+,(a3)+
	dbra	d3,ScSwS4
* Autorise le screen swap
	lea	SwapL(a6),a0
	tst.w	T_CopON(a5)		* Si COPPER ON!
	beq	ScSwS1
	btst	#2,EcCon0+1(a4)		* Interlace?
	bne	ScSwS1
	clr.l	SwapL(a6)		* Empeche le suivant!
	move.l	d7,(a6)
	bra	ScSwS1

******* SCREEN CLONE N
EcCClo:	movem.l	d1-d7/a1-a6,-(sp)
	move.l	d1,-(sp)
	bsr	EcGet
	beq.s	EcCT0
	addq.l	#4,sp
	bra	EcE2
* Reserve la RAM / Verifie les parametres
EcCT0:	move.l	#EcLong,d0
	bsr	FastMm
	beq	EcE1
	move.l	d0,a4
	move.l	d0,a1
	move.w	#EcLong-1,d0
	move.l	T_EcCourant(a5),a0
EcCT1:	move.b	(a0)+,(a1)+
	dbra	d0,EcCT1
* Pas de zones
	clr.l	EcAZones(a4)
	clr.w	EcNZones(a4)
* Pas de fenetre!
	clr.l	EcWindow(a4)
* Pas de pattern
	clr.l	EcPat(a4)
* Pas de fonte
	clr.w	EcFontFlag(a4)
* Cree l'ecran dans les tables
	bset	#BitClone,EcFlags(a4)
	move.l	(sp)+,d1
	move.w	d1,EcNumber(a4)
* Entrelace?
	bsr	InterPlus
* Met dans la displaylist
	bsr	EcGet
	move.l	a4,(a0)
	bsr	EcFirst
	bra	EcTout

******* DOUBLE BUFFER: Passe en double buffer!
EcDouble:
	movem.l	d1-d7/a1-a6,-(sp)
	move.l	T_EcCourant(a5),a4
* Deja en double?
	btst	#BitDble,EcFlags(a4)
	bne	EcE25
* Reserve la RAM / Copie le contenu
	move.w	EcNplan(a4),d6
	subq.w	#1,d6
	lea	EcPhysic(a4),a2
	lea	EcLogic(a4),a3
	lea	EcCurrent(a4),a6
EcDb1:	move.l	EcTPlan(a4),d0		* Reserve!
	bsr	ChipMm
	beq	EcDbE
	move.l	d0,(a3)+
	move.l	d0,(a6)+
	move.l	d0,a1			* Copie!
	move.l	(a2)+,a0
	move.l	EcTPlan(a4),d0
	lsr.w	#4,d0
	subq.w	#1,d0
EcDb2:	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	dbra	d0,EcDb2
	dbra	d6,EcDb1
* Met le flag!
	bset	#BitDble,EcFlags(a4)
	move.w	#2,EcAuto(a4)
* Enleve le BUG!
	bsr	TAbk1
	bsr	TAbk2
	bsr	TAbk3
	bra	EcOk
* Erreur! Efface l'ecran entier
EcDbE	moveq	#0,d1
	move.w	EcNumber(a4),d1
	bsr	EcDel
	bra	EcE1

******* Dual Playfield D1,D2
*	D1= Ecran 1
*	D2= Ecran 2
Duale:	movem.l	d1-d7/a1-a6,-(sp)
	cmp.w	d1,d2
	beq	EcE26
	move.w	d2,d7
	addq.w	#1,d7
	exg	d1,d2
	bsr	EcGet
	beq	EcE3
	move.l	d0,a1
	move.w	d2,d1
	bsr	EcGet
	beq	EcE3
	move.l	d0,a0
	tst.w	EcDual(a0)		* Pas deja dual!
	bne	EcE26
	tst.w	EcDual(a1)
	bne	EcE26
	moveq	#3,d2
	move.w	EcCon0(a0),d0		* Meme resolution!
	bpl.s	EcDu1
	moveq	#2,d2
EcDu1:	and.w	#%1000111111111111,d0
	move.w	EcCon0(a1),d1
	and.w	#%1000111111111111,d1
	cmp.w	d0,d1
	bne	EcE26
	move.w	EcNPlan(a0),d3
	move.w	EcNPlan(a1),d4
	cmp.w	d2,d3
	bhi	EcE26
	cmp.w	d2,d4
	bhi	EcE26
	move.w	d3,d2			* Nombre total de plans
	add.w	d4,d2
	cmp.w	d3,d4			* Combinaisons autorisees?
	beq.s	EcDu2
	addq.w	#1,d4
	cmp.w	d3,d4
	bne	EcE26
EcDu2:	moveq	#12,d1
	lsl.w	d1,d2
	or.w	d2,d0
	bset	#10,d0			* Mode DUAL PLAYFIELD!
	move.w	d0,EcCon0(a0)
	move.w	EcCon2(a0),d0		* Priorites sprites-> 2 ieme plan!
	and.w	#%111,d0
	lsl.w	#3,d0
	or.w	d0,EcCon2(a0)
	and.w	#%111111,EcCon2(a0)
	bset	#BitHide,EcFlags(a1)	* Cache le deuxieme
	move.w	d7,EcDual(a0)		* Met les flags!
	neg.w	d7
	move.w	d7,EcDual(a1)
	bra	EcTout

******* DUAL PRIORITY n,m
DualP:	movem.l	d1-d7/a1-a6,-(sp)
	cmp.w	d1,d2
	beq	EcE27
	exg	d1,d2
	bsr	EcGet
	beq	EcE3
	move.l	d0,a1
	move.w	d2,d1
	bsr	EcGet
	beq	EcE3
	move.l	d0,a0
	moveq	#0,d0
	tst.w	EcDual(a0)
	beq	EcE27
	tst.w	EcDual(a1)
	beq	EcE27
	bmi.s	EcDup1
	move.l	a1,a0
	moveq	#-1,d0
EcDup1:	move.w	EcCon2(a0),d1
	bclr	#6,d1
	tst.w	d0
	beq.s	EcDup2
	bset	#6,d1
EcDup2:	move.w	d1,EcCon2(a0)
	bra	EcOtoV

******* Creation de l'ecran
*	D1= #
*	D2= TX
*	D3= TY
*	D4= NB PLANS
*	D5= MODE
*	D6= NB COULEURS
*	A1= PALETTE
EcCree:	movem.l	d1-d7/a1-a6,-(sp)

;	Verifie les parametres
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	and.l	#$FFFFFFF0,d2
	beq	EcE4
	cmp.l	#1024,d2
	bcc	EcE4
	tst.l	d3
	beq	EcE4
	cmp.l	#1024,d3
	bcc	EcE4
	tst.l	d4
	beq	EcE4
	cmp.l	#EcMaxPlans,d4
	bhi	EcE4

;	Ecran deja reserve?
; ~~~~~~~~~~~~~~~~~~~~~~~~~
ReEc:	move.l	d1,-(sp)
	bsr	EcGet
	beq.s	EcCr0
; Efface l'ecran deja r�serve
	move.l	(sp)+,d1
	bsr	EcDel
	bra.s	ReEc

;	Reserve la RAM pour la structure
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EcCr0:	move.l	#EcLong,d0
	bsr	FastMm
	beq	EcEE1
	move.l	d0,a4

; Couleurs
; ~~~~~~~~
	move.w	d6,EcNbCol(a4)
	moveq	#31,d0
	lea	EcPal(a4),a2
EcCr4:	move.w	(a1)+,(a2)+
	dbra	d0,EcCr4
; Taille de l'ecran
; ~~~~~~~~~~~~~~~~~
	move.w	d2,EcTx(a4)
	move.w	d2,EcTxM(a4)
	subq.w	#1,EcTxM(a4)
	move.w	d2,d7
	lsr.w	#3,d7
	move.w	d7,EcTLigne(a4)
	move.w	d3,EcTy(a4)
	move.w	d3,EcTyM(a4)
	subq.w	#1,EcTyM(a4)
	mulu	d3,d7
	move.l	d7,EcTPlan(a4)
	move.w	d4,EcNPlan(a4)

; 	Parametres d'affichage -1-
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l	T_GfxBase(a5),a0	EcCon0
	move.w	164(a0),d0
	and.w	#%0000001111111011,d0
	move.w	d4,d1
	lsl.w	#8,d1
	lsl.w	#4,d1
	or.w	d0,d1
	or.w	d1,d5
	move.w	d5,EcCon0(a4)
	move.w	#%00100100,EcCon2(a4)	EcCon2

;	Creation de la structure BitMap / Reservation des bitmaps
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	moveq	#40,d0				bm_SIZEOF
	bsr	FastMm
	beq	EcMdd
	move.l	d0,Ec_BitMap(a4)
	move.l	d0,a0
	move.w	EcNPlan(a4),d0			Creation de BitMap
	ext.l	d0
	move.w	EcTx(a4),d1
	ext.l	d1
	move.w	EcTy(a4),d2
	ext.l	d2
	move.l	T_GfxBase(a5),a6
	jsr	_LVOInitBitMap(a6)
; Reserve la RAM
; ~~~~~~~~~~~~~~
	move.w	d4,d6
	subq.w	#1,d6
	move.l	Ec_BitMap(a4),a1
	moveq	#0,d2
EcCra:	move.l	d7,d0
	bsr	ChipMm
	beq	EcMdd
	move.l	d0,bm_Planes(a1,d2.w)
	move.l	d0,EcCurrent(a4,d2.w)
	move.l	d0,EcLogic(a4,d2.w)
	move.l	d0,EcPhysic(a4,d2.w)
	addq.l	#4,d2
	dbra	d6,EcCra

;	Ouverture d'un rastport intuition REEL
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l	T_LayBase(a5),a6
	jsr	_LVONewLayerInfo(a6)		Creation de LayerInfo
	move.l	d0,Ec_LayerInfo(a4)
	beq	EcMdd
	move.l	d0,a0				Creation du layer
	move.l	Ec_BitMap(a4),a1
	moveq	#0,d0
	moveq	#0,d1
	move.w	EcTx(a4),d2
	subq.w	#1,d2
	ext.l	d2
	move.w	EcTy(a4),d3
	subq.w	#1,d3
	ext.l	d3
	moveq	#LAYERSIMPLE,d4
	sub.l	a2,a2
	jsr	_LVOCreateUpfrontLayer(a6)
	move.l	d0,Ec_Layer(a4)
	beq	EcMdd
	move.l	d0,a0				Rastport courant
	move.l	lr_rp(a0),Ec_RastPort(a4)

	bsr	BlitWait
	bsr	WVbl
	bsr	BlitWait

;	Zones
; ~~~~~~~~~~~
	clr.l	EcAZones(a4)
	clr.w	EcNZones(a4)

;	Additionne l'ecran dans les tables
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l	(sp),d1
	lea	Circuits,a6
	bsr	EcGet
	move.l	a4,(a0)			Branche
	move.w	d1,EcNumber(a4)		Un numero!
	move.l	a4,a0			Devient l'ecran courant
	bsr	Ec_Active
	move.l	(sp),d1
	bsr	EcFirst			Et devant les autres
	bsr	InterPlus		Si entrelace

; 	Parametres d'affichage -2-
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.w	T_DefWX(a5),d2		Affichage par defaut
	move.w	T_DefWY(a5),d3
	move.w	EcTx(a4),d4
	tst.w	EcCon0(a4)
	bpl.s	EcCr6
	lsr.w	#1,d4
EcCr6	move.w	EcTy(a4),d5
	cmp.w	#320+16,d4
	bcs.s	EcCr7
	move.w	T_DefWX2(a5),d2
EcCr7	cmp.w	#256,d5
	bcs.s	EcCr8
	btst	#2,EcCon0+1(a4)
	beq.s	EcCr7a
	cmp.w	#256*2,d5
	bcs.s	EcCr8
EcCr7a	move.w	T_DefWY2(a5),d3
EcCr8	ext.l	d2
	ext.l	d3
	ext.l	d4
	ext.l	d5
	move.l	(sp),d1
	bsr	EcView

; 	Cree la fenetre de texte plein ecran
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	clr.l	EcWindow(a4)
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
	move.w	EcTx(a4),d4
	lsr.w	#4,d4
	lsl.w	#1,d4
	move.w	EcTy(a4),d5
	lsr.w	#3,d5
	moveq	#1,d6
	moveq	#0,d7
	sub.l	a1,a1
	bsr	WOpen
	bne	EcM1

;	Initialisation des parametres graphiques
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l	EcWindow(a4),a0
	move.b	WiPen+1(a0),d1
	move.b	d1,EcInkA(a4)
	move.b	WiPaper+1(a0),d0
	move.b	d0,EcInkB(a4)
	move.b	d1,EcFInkC(a4)
	move.b	d1,EcIInkC(a4)
	move.b	d0,EcFInkA(a4)
	move.b	d0,EcFInkB(a4)
	move.b	d0,EcIInkA(a4)
	move.b	d0,EcIInkB(a4)
	move.w	#1,EcIPat(a4)
	move.w	#2,EcFPat(a4)
	move.b	#1,EcMode(a4)
	move.w	#-1,EcLine(a4)

	move.l	Ec_RastPort(a4),a1
	moveq	#0,d0
	move.b	EcInkA(a4),d0			Ink A
	GfxA5	_LVOSetAPen
	move.b	EcInkB(a4),d0			Ink B
	GfxA5	_LVOSetBPen
	move.b	EcMode(a4),d0			Draw Mode
	GfxA5	_LVOSetDrMd
;	move.w	EcCont(a4),32(a1)		Cont
	move.w	EcLine(a4),34(a1)		Line
	clr.w	36(a1)				X
	clr.w	38(a1)				Y

	move.l	T_DefaultFont(a5),a0		Fonte systeme
	GfxA5	_LVOSetFont

	clr.w	EcClipX0(a4)			Par default
	clr.w	EcClipY0(a4)
	move.w	EcTx(a4),EcClipX1(a4)
	move.w	EcTy(a4),EcClipY1(a4)

; Pas d'erreur
; ~~~~~~~~~~~~~
	addq.l	#4,sp
	move.l	T_EcCourant(a5),a0	* Ramene l'adresse definition
; Doit recalculer les ecrans
; ~~~~~~~~~~~~~~~~~~~~~~~~~~
EcTout:	addq.w	#1,T_EcYAct(a5)
; Doit actualiser ECRANS
; ~~~~~~~~~~~~~~~~~~~~~~
EcOtoV:	bset	#BitEcrans,T_Actualise(a5)
EcOk:	movem.l	(sp)+,d1-d7/a1-a6
	moveq	#0,d0
	rts

;	Erreur creation d'un ecran
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EcM1:	move.l	(sp),d1
	bsr	EcDel
	bra.s	EcEE1
EcMdd	bsr	EcDDel			* Efface la structure
EcEE1	addq.l	#4,sp
EcE1:	moveq	#1,d0
	bra.s	EcOut
EcE4:	moveq	#4,d0			* Sans effacement
	bra.s	EcOut
EcE3:	moveq	#3,d0			* 3 : SCREEN NOT OPENED
	bra.s	EcOut
EcE25:	moveq	#25,d0			* 25: Screen already double buffered
	bra.s	EcOut
EcE26:	moveq	#26,d0			* Can't set dual-playfield
	bra.s	EcOut
EcE27:	moveq	#27,d0			* Screen not dual playfield
	bra.s	EcOut
EcE2:	moveq	#2,d0			* 2 : SCREEN ALREADY OPENED
* Sortie erreur ecrans
EcOut:	movem.l	(sp)+,d1-d7/a1-a6
	tst.l	d0
	rts

******* Un ecran entrelace en plus!
InterPlus:
	btst	#2,EcCon0+1(a4)
	beq.s	IntPls
	movem.l	d0/a0/a1,-(sp)
	clr.w	T_InterBit(a5)
	lea	T_InterList(a5),a0
IntP0	tst.l	(a0)
	addq.l	#8,a0
	bne.s	IntP0
	clr.l	(a0)
	move.l	a4,-8(a0)
	move.w	EcNumber(a4),d0
	lsl.w	#6,d0
	add.w	#CopL1*EcMax,d0
	ext.l	d0
	lea	T_CopMark(a5),a1
	add.l	a1,d0
	move.l	d0,-4(a0)
	movem.l	(sp)+,d0/a0/a1
IntPls	rts

;	Sauve les contenu du rasport de l'ecran courant
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Ec_Push	movem.l	a0-a1/d0,-(sp)
	tst.w	T_PaPeek(a5)
	bne.s	.Pasave
	move.l	T_RastPort(a5),d0
	beq.s	.Pasave
	move.l	d0,a0
	lea	T_EcSave(a5),a1
	move.b	25(a0),(a1)+		0 EcInkA(a1)
	move.b	26(a0),(a1)+		1 EcInkB(a1)
	move.b	27(a0),(a1)+		2 EcOutL(a1)
	move.b	28(a0),(a1)+		3 EcMode(a1)
	move.w	32(a0),(a1)+		4 EcCont(a1)
	move.w	34(a0),(a1)+		6 EcLine(a1)
	move.w	36(a0),(a1)+		8 EcX(a1)
	move.w	38(a0),(a1)+		10 EcY(a1)
	move.l	8(a0),(a1)+		12 EcPat
	move.b	29(a0),(a1)+		16 EcPatY
	addq.l	#1,a1
	lea	52(a0),a0
	moveq	#14-1,d0		18 Fonte
.Loop	move.b	(a0)+,(a1)+
	dbra	d0,.Loop
; Sauve le clip rectangle
	move.l	T_EcCourant(a5),a0
	move.w	EcClipX0(a0),(a1)+	32
	move.w	EcClipY0(a0),(a1)+	34
	move.w	EcClipX1(a0),(a1)+	36
	move.w	EcClipY1(a0),(a1)+	38
.Pasave	movem.l	(sp)+,a0-a1/d0
	rts

;	Restore les modes graphiques de l'ecran courant
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Ec_Pull	movem.l	a0-a2/d0-d3,-(sp)
	tst.w	T_PaPeek(a5)
	bne.s	.Papull
	lea	T_EcSave(a5),a2
	move.l	T_RastPort(a5),d0
	beq.s	.Papull
	move.l	d0,a1
; Change le RASTPORT
; ~~~~~~~~~~~~~~~~~~
	moveq	#0,d0			Ink A
	move.b	(a2)+,d0
	GfxA5	_LVOSetAPen
 	moveq	#0,d0			Ink B
	move.b	(a2)+,d0
	GfxA5	_LVOSetBPen
	move.b	(a2)+,27(a1)		OutL
	moveq	#0,d0
	move.b	(a2)+,d0
	GfxA5	_LVOSetDrMd		Draw Mode
	move.w	(a2)+,32(a1)		Cont
	move.w	(a2)+,34(a1)		Line
	move.w	(a2)+,36(a1)		X
	move.w	(a2)+,38(a1)		Y
	move.l	(a2)+,8(a1)		EcPat
	move.b	(a2)+,29(a1)		EcPatY
	addq.l	#1,a2
	lea	52(a1),a1		Fonte
	moveq	#14-1,d0
.Loop	move.b 	(a2)+,(a1)+
	dbra	d0,.Loop
; Restore le clip rectangle
; ~~~~~~~~~~~~~~~~~~~~~~~~~
	move.w	(a2)+,d0
	move.w	(a2)+,d1
	move.w	(a2)+,d2
	move.w	(a2)+,d3
	bsr	Ec_SetClip
.Papull	movem.l	(sp)+,a0-a2/d0-d3
	rts

******* VIEW: change le point de vue d'un ecran
*	D1= #
*	D2= WX
*	D3= WY
*	D4= WTx
* 	D5= WTy
EcView:	movem.l	d1-d7/a1-a6,-(sp)
	bsr	EcGet
	beq	EcE3
	move.l	d0,a4
* WX
	cmp.l	#EntNul,d2
	beq.s	EcV2
	move.w	d2,EcAWX(a4)
	bset	#1,EcAW(a4)
* WTX
EcV2:	cmp.l	#EntNul,d4
	beq.s	EcV3
	move.w	d4,EcAWTx(a4)
	bset	#1,EcAWT(a4)
* WY
EcV3:	cmp.l	#EntNul,d3
	beq.s	EcV4
	move.w	d3,EcAWY(a4)
	bset	#2,EcAW(a4)
* WTy
EcV4:	cmp.l	#EntNul,d5
	beq	EcOtoV
	move.w	d5,EcAWTy(a4)
	bset	#2,EcAWT(a4)
	bra	EcOtoV

******* Fait passer l'ecran D1 en premier
EcFirst:movem.l	d1-d7/a1-a6,-(sp)
	bsr	EcGet
	beq	EcE3
	lea	T_EcPri(a5),a0
	move.l	a0,a1
	move.l	(a1),d1
	move.l	d0,(a0)
EcF1:	addq.l	#4,a0
EcF2:	addq.l	#4,a1
	move.l	d1,d2
	move.l	(a1),d1
	move.l	d2,(a0)
	bmi.s	EcF3
	beq.s	EcF2
	cmp.l	d2,d0
	beq.s	EcF2
	bne.s	EcF1
EcF3:	bra	EcTout

******* Fait passer l'ecran D1 en dernier
EcLast:	movem.l	d1-d7/a1-a6,-(sp)
	bsr	EcGet
	beq	EcE3
	lea	T_EcPri(a5),a0
	move.l	a0,a1
EcL1:	move.l	(a1)+,d1
	move.l	d1,(a0)
	bmi.s	EcL2
	beq.s	EcL1
	cmp.l	d1,d0
	beq.s	EcL1
	addq.l	#4,a0
	bra.s	EcL1
EcL2:	move.l	d0,(a0)+
	move.l	#-1,(a0)+
	bra	EcTout

;	 Arret ecran special creation!
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	A4= Adresse!
EcDDel	movem.l	d1-d7/a1-a6,-(sp)
	bra.s	EcDD

;	Arret d'un ecran D1
; ~~~~~~~~~~~~~~~~~~~~~~~~~
EcDel:	movem.l	d1-d7/a1-a6,-(sp)
	bsr	EcGet
	beq	EcE3
	move.l	d0,a4
	clr.l	(a0)			;Arrete dans la table
	lea	T_EcPri(a5),a0		;Arrete dans les priorites
	move.l	a0,a1
EcD1:	move.l	(a1)+,d0
	move.l	d0,(a0)
	bmi.s	EcD2
	beq.s	EcD1
	cmp.l	d0,a4
	beq.s	EcD1
	addq.l	#4,a0
	bra.s	EcD1
; Entrelace?
; ~~~~~~~~~~
EcD2	btst	#2,EcCon0+1(a4)
	beq.s	EcDit3
	clr.w	T_InterBit(a5)
	lea	T_InterList(a5),a0
	move.l	a0,a1
EcDit0	move.l	(a1),d0
	beq.s	EcDit2
	cmp.l	d0,a4
	beq.s	EcDit1
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	bra.s	EcDit0
EcDit1	lea	8(a1),a1
	bra.s	EcDit0
EcDit2	clr.l	(a0)
; Enleve les screen swaps!
; ~~~~~~~~~~~~~~~~~~~~~~~~
EcDit3	lea	T_SwapList(a5),a0
	clr.l	(a0)
; Recalcule la liste copper
; ~~~~~~~~~~~~~~~~~~~~~~~~~
	bsr	WVbl
	bset	#BitHide,EcFlags(a4)
	bsr	EcForceCop
	bsr	WVbl

; 	Entree sans recalcul des listes copper
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EcDD:	move.l	EcAZones(a4),d0		Les zones
	beq.s	.Nozone
	move.l	d0,a1
	move.w	EcNZones(a4),d0
	mulu	#8,d0
	bsr	FreeMm
.Nozone	lea	EcAW(a4),a0		Les animations
	bsr	DAdAMAL
	lea	EcAWT(a4),a0
	bsr	DAdAMAL
	lea	EcAV(a4),a0
	bsr	DAdAMAL
	move.l	a4,a0			Les bobs
	bsr	BbEcOff

	move.l	T_EcCourant(a5),d3
	move.l	a4,a0			Active l'ecran
	bsr	Ec_Active		Pour les effacements
	bsr	WiDelA			Toutes les fenetres
	bsr	FlStop			Animations de couleur
	bsr	ShStop
	bsr	FaStop
	bsr	EffPat			Le pattern
	bsr	CFont			La fonte

; Si ECRAN COURANT: met le + prioritaire pas clone, <8 si possible!
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	cmp.l	a4,d3
	bne.s	EcD3
	lea	T_EcPri(a5),a0		1ere boucle: <8
EcDc2:	move.l	(a0)+,d3
	bmi.s	EcDc3
	move.l	d3,a1
	btst	#BitClone,EcFlags(a1)
	bne.s	EcDc2
	cmp.w	#8,EcNumber(a1)
	bcc.s	EcDc2
	bra.s	EcD3
EcDc3	lea	T_EcPri(a5),a0		2ieme n'importe!
EcDc4	move.l	(a0)+,d3
	bmi.s	EcDc5
	move.l	d3,a1
	btst	#BitClone,EcFlags(a1)
	bne.s	EcDc4
	bra.s	EcD3
EcDc5	moveq	#0,d3
EcD3:	move.l	d3,a0
	bsr	Ec_Active

; 	Liberation des memoires, si pas clone...
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	btst	#BitClone,EcFlags(a4)		Si clone, rien a liberer...
	bne	PaClon
	move.l	a6,-(sp)

; Ferme le ClipRect
; ~~~~~~~~~~~~~~~~~
	tst.l	Ec_Region(a4)
	beq.s	.Paclip
	move.l	T_LayBase(a5),a6		Enleve le ClipRegion
	move.l	Ec_Layer(a4),a0
	sub.l	a1,a1
	jsr	_LVOInstallClipRegion(a6)
	move.l	Ec_Region(a4),a0		Enleve la region
	move.l	T_GfxBase(a5),a6
	jsr	_LVODisposeRegion(a6)
.Paclip
; Ferme le layer
; ~~~~~~~~~~~~~~
	move.l	T_LayBase(a5),a6
	move.l	Ec_Layer(a4),d0
	beq.s	.Nola1
	move.l	d0,a1
	sub.l	a0,a0
	move.l	T_LayBase(a5),a6
	jsr	_LVODeleteLayer(a6)		Enleve le layer
.Nola1	bsr	BlitWait			Blitter Wait!
	bsr	WVbl
	bsr	BlitWait
	move.l	Ec_LayerInfo(a4),d0		Enleve Layer Info
	beq.s	.Nola2
	move.l	d0,a0
	jsr	_LVODisposeLayerInfo(a6)	Enleve le layer info
.Nola2
; Liberation des bitmaps
; ~~~~~~~~~~~~~~~~~~~~~~
	bsr	BlitWait			Correction du bug dans les
	bsr	WVbl				layers...
	bsr	BlitWait
	moveq	#EcMaxPlans-1,d7
	lea	EcLogic(a4),a2
	lea	EcPhysic(a4),a3
EcFr0:	move.l	(a2),d2
	beq.s	EcFr1
	move.l	d2,a1
	move.l	EcTPlan(a4),d0
	bsr	FreeMm
EcFr1:	clr.l	(a2)+
	cmp.l	(a3)+,d2
	bne.s	EcFr2
	clr.l	-4(a3)
EcFr2:	dbra	d7,EcFr0
	moveq	#EcMaxPlans-1,d7
	lea	EcPhysic(a4),a2
EcFr3:	move.l	(a2),d0
	beq.s	EcFr4
	move.l	d0,a1
	move.l	EcTPlan(a4),d0
	bsr	FreeMm
EcFr4:	clr.l	(a2)+
	dbra	d7,EcFr3
	move.l	(sp)+,a6
; La structure Bitmap
; ~~~~~~~~~~~~~~~~~~~
	move.l	Ec_BitMap(a4),d0
	beq.s	.PaBM
	move.l	d0,a1
	moveq	#40,d0
	bsr	FreeMm
.PaBM

; 	Libere les structures
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~
PaClon	move.l	a4,a1				La structure AMOS
	move.l	#EcLong,d0
	bsr	FreeMm

	move.l	T_EcCourant(a5),a0

	bra	EcOk

******* Initialisation des ecrans
EcRaz:	lea	T_EcAdr(a5),a0
	moveq	#EcMax-1,d0
EcR1:	clr.l	(a0)+
	dbra	d0,EcR1
	move.l	#-1,T_EcPri(a5)
	lea	T_CopMark(a5),a0
	move.w	#CopML/4-1,d0
EcR2:	clr.l	(a0)+
	dbra	d0,EcR2
	move.w	#1,T_EcYAct(a5)
	moveq	#0,d0
	rts

******* Arret de tous les ecrans entre D1-D2
EcDAll:	bsr	EcDel
	addq.l	#1,d1
	cmp.l	d2,d1
	bls.s	EcDAll
	moveq	#0,d0
	rts

******* SCREEN OFFSET n,dx,dy
EcOffs:	bsr	EcGet
	beq	EcME
	move.l	d0,a0
	cmp.l	#EntNul,d2
	beq.s	EcO1
	move.w	d2,EcAVX(a0)
	bset	#1,EcAV(a0)
EcO1:	cmp.l	#EntNul,d3
	beq.s	EcO2
	move.w	d3,EcAVY(a0)
	bset	#2,EcAV(a0)
EcO2:	bra.s	EcTu

******* HIDE/SHOW ecran D1,d2
EcHide:	bsr	EcGet
	beq	EcME
	move.l	d0,a0
	tst.w	EcDual(a0)		* Pas DUAL PLAYFIELD
	bmi.s	EcTut
	bclr	#BitHide,EcFlags(a0)
	tst.w	d2
	beq.s	EcTut
	bset	#BitHide,EcFlags(a0)
EcTut:	addq.w	#1,T_EcYAct(a5)
EcTu:	bset	#BitEcrans,T_Actualise(a5)
	moveq	#0,d0
	rts

***********************************************************
*	GESTION DE L'AUTOBACK!
******* AUTOBACK 1
TAbk1:	movem.l	a3-a6,-(sp)
	move.l	W_Base(pc),a5
	move.l	T_EcCourant(a5),a0
	move.w	EcAuto(a0),d0
	subq.w	#1,d0
	ble.s	TAbk1X
	bsr	WVbl
	bsr	BobEff
TAbk1X:	movem.l	(sp)+,a3-a6
	rts
******* AUTOBACK 2
TAbk2	move.l	W_Base(pc),a1
	move.l	T_EcCourant(a1),a0
	move.w	EcAuto(a0),d0
	subq.w	#1,d0
	bmi.s	TAbk2X
	bne.s	TAbk2B
* Autoback simple---> change le rastport / current
	moveq	#EcMaxPlans-1,d0
	move.l	Ec_BitMap(a0),a1
	addq.l	#8,a1
	lea	EcCurrent(a0),a2
	lea	EcPhysic(a0),a0
TAbk2A	move.l	(a0),(a1)+
	move.l	(a0)+,(a2)+
	dbra	d0,TAbk2A
TAbk2X	rts
* Autoback total---> screen swap
TAbk2B	movem.l	a3-a6,-(sp)
	move.l	a1,a5
	bsr	BobAct
	bsr	BobAff
	bsr	ScSwapS
	bsr	WVbl
	bsr	BobEff
	movem.l	(sp)+,a3-a6
	rts
******* AUTOBACK 3
TAbk3	move.l	W_Base(pc),a1
	move.l	T_EcCourant(a1),a0
	move.w	EcAuto(a0),d0
	subq.w	#1,d0
	bmi.s	TAbk3X
	bne.s	TAbk3B
* Simple ---> remet le rasport / current
	moveq	#EcMaxPlans-1,d0
	move.l	Ec_BitMap(a0),a1
	addq.l	#8,a1
	lea	EcCurrent(a0),a2
	lea	EcLogic(a0),a0
TAbk3A	move.l	(a0),(a1)+
	move.l	(a0)+,(a2)+
	dbra	d0,TAbk3A
TAbk3X	rts
* Total ---> Re screen swap!
TAbk3B	movem.l	a3-a6,-(sp)
	move.l	a1,a5
	bsr	BobAct
	bsr	BobAff
	bsr	ScSwapS
	bsr	WVbl
	bclr	#BitBobs,T_Actualise(a5)
	movem.l	(sp)+,a3-a6
	rts
******* AUTOBACK 4 -> ecrans single buffer!
TAbk4:	movem.l	a3-a6,-(sp)
	move.l	W_Base(pc),a5
	move.l	T_EcCourant(a5),a0
	move.w	EcAuto(a0),d0
	subq.w	#1,d0
	ble.s	TAbk4X
	bsr	BobAct
	bsr	BobAff
TAbk4X:	movem.l	(sp)+,a3-a6
	rts

***********************************************************
*	CLS
*	D1= Couleur
*	D2= X
*	D3= Y
*	D4= X2
*	D5= Y2
EcCls:	movem.l	d1-d7/a0/a1/a5/a6,-(sp)
	move.l	T_EcCourant(a5),a5
	tst.w	d2
	bpl.s	Cls5b
	moveq	#0,d2
Cls5b:	cmp.w	EcTx(a5),d2
	bls.s	Cls5c
	move.w	EcTx(a5),d2
Cls5c:	tst.w	d3
	bpl.s	Cls5d
	moveq	#0,d3
Cls5d:	cmp.w	EcTy(a5),d3
	bls.s	Cls5e
	move.w	EcTy(a5),d3
Cls5e:	tst.w	d4
	bpl.s	Cls5f
	moveq	#0,d4
Cls5f:	cmp.w	EcTx(a5),d4
	bls.s	Cls5g
	move.w	EcTx(a5),d4
Cls5g:	tst.w	d5
	bpl.s	Cls5h
	moveq	#0,d5
Cls5h:	cmp.w	EcTy(a5),d5
	bls.s	Cls5i
	move.w	EcTy(a5),d5
Cls5i:	cmp.w	d2,d4
	bls	Cls5x
	sub.w	d3,d5
	bls	Cls5x
* Gestion de l'autoback!
	tst.w	EcAuto(a5)
	beq.s	Cls5W
	movem.l	d0-d7/a0-a2,-(sp)
	bsr	TAbk1
	movem.l	(sp),d0-d7/a0-a2
	bsr	ClsR
	bsr	TAbk2
	movem.l	(sp)+,d0-d7/a0-a2
	bsr	ClsR
	bsr	TAbk3
	bra.s	Cls5X
Cls5W	bsr	ClsR
Cls5X:	movem.l	(sp)+,d1-d7/a0/a1/a5/a6
	moveq	#0,d0
	rts

* Routine d'effacement!
ClsR:	lea	Circuits,a6
	bsr	OwnBlit
	lea	MCls(pc),a0		* Masques
	move.w	d2,d0
	and.w	#$000F,d0
	lsl.w	#1,d0
	move.w	0(a0,d0.w),BltMaskG(a6)
	moveq	#0,d6
	moveq	#-1,d7
	move.w	d4,d0
	and.w	#$000F,d0
	beq.s	Cls5j
	moveq	#1,d6
	lsl.w	#1,d0
	move.w	0(a0,d0.w),d7
	not.w	d7
Cls5j:	move.w	d7,BltMaskD(a6)
	lsr.w	#4,d2			* Taille en X
	lsr.w	#4,d4
	sub.w	d2,d4
	add.w	d6,d4
	lsl.w	#6,d5			* Taille blitter
	or.w	d4,d5
	move.w	EcTLigne(a5),d0		* Adresse ecran
	mulu	d0,d3
	lsl.w	#1,d2
	ext.l	d2
	add.l	d2,d3
	lsl.w	#1,d4			* Mod C et D
	sub.w	d4,d0
	move.w	d0,BltModC(a6)
	move.w	d0,BltModD(a6)
	lea	EcCurrent(a5),a0
	move.w	#%0000001111001010,BltCon0(a6)
	clr.w	BltCon1(a6)
	move.w	#-1,BltDatA(a6)
	move.w	EcNPlan(a5),d7
	subq.w	#1,d7
	moveq	#-1,d6

Cls5k:	moveq	#0,d0
	lsr.w	#1,d1
	subx.w	d0,d0
	move.w	d0,BltDatB(a6)
	move.l	(a0)+,a1
	lsr.w	#1,d6
	bcc.s	Cls5m
	add.l	d3,a1
	move.l	a1,BltAdC(a6)
	move.l	a1,BltAdD(a6)
	move.w	d5,BltSize(a6)
Cls5l:	bsr	BlitWait
Cls5m:	dbra	d7,Cls5k
* Remet le blitter et revient
	bra	DOwnBlit

******* Table des masques
MCls:	dc.w	%1111111111111111
	dc.w 	%0111111111111111
	dc.w 	%0011111111111111
	dc.w	%0001111111111111
	dc.w	%0000111111111111
	dc.w	%0000011111111111
	dc.w	%0000001111111111
	dc.w	%0000000111111111
	dc.w	%0000000011111111
	dc.w	%0000000001111111
	dc.w	%0000000000111111
	dc.w	%0000000000011111
	dc.w	%0000000000001111
	dc.w	%0000000000000111
	dc.w	%0000000000000011
	dc.w	%0000000000000001
MCls2:	dc.w	%0000000000000000
	dc.w	%0000000000000001
	dc.w	%0000000000000011
	dc.w	%0000000000000111
	dc.w	%0000000000001111
	dc.w	%0000000000011111
	dc.w	%0000000000111111
	dc.w	%0000000001111111
	dc.w	%0000000011111111
	dc.w	%0000000111111111
	dc.w	%0000001111111111
	dc.w	%0000011111111111
	dc.w	%0000111111111111
	dc.w	%0001111111111111
	dc.w 	%0011111111111111
	dc.w 	%0111111111111111

;	Active l'ecran D1 - si pas ecran CLONE!
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EcMarch	bsr	EcGet
	beq.s	EcME
	move.l	d0,a0
	btst	#BitClone,EcFlags(a0)
	bne.s	EcCl
	bsr	Ec_Active
EcMOk	moveq	#0,d0
	rts
EcME	moveq	#3,d0
	rts
EcCl	moveq	#4,d0
	rts

;	Routine d'activation de l'ecran A0
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Ec_Active
	move.l	a0,T_EcCourant(a5)
	move.l	a0,d0
	beq.s	.Skip
	move.l	Ec_RastPort(a0),T_RastPort(a5)
	move.l	a1,-(sp)
	lea	WRastPort(pc),a1
	move.l	Ec_RastPort(a0),(a1)
	move.l	(sp)+,a1
.Skip	rts

******* RETURNS CURRENT USERS SCREEN ADDRESS
EcCrnt	move.l	T_EcCourant(a5),a0
	move.w	EcNumber(a0),d0
	cmp.w	#8,d0
	bcs.s	EcCr
	moveq	#-1,d0
EcCr:	rts

******* ADRESSE ECRAN D1
EcAdres	cmp.w	#8,d1
	bcs	EcGet
	moveq	#0,d0
	rts

******* SET COLOUR D1,D2
EcSCol:	move.l	T_EcCourant(a5),a0
	and.w	#31,d1
	lsl.w	#1,d1
	and.w	#$FFF,d2
	move.w	d2,EcPal(a0,d1.w)
* Poke dans le copper
	lsl.w	#1,d1
	move.w	EcNumber(a0),d0
	lsl.w	#7,d0
	lea	T_CopMark(a5),a0
	add.w	d0,a0
	cmp.w	#PalMax*4,d1
	bcs.s	ECol0
	lea	64(a0),a0
ECol0:	move.l	(a0)+,d0
	beq.s	ECol1
	move.l	d0,a1
	move.w	d2,2(a1,d1.w)
	bra.s	ECol0
ECol1:	moveq	#0,d0
	rts

******* GET COLOUR D1
EcGCol:	move.l	T_EcCourant(a5),a0
	and.l	#31,d1
	lsl.w	#1,d1
	move.w	EcPal(a0,d1.w),d1
	moveq	#0,d0
	rts

******* SET PALETTE A1
EcSPal	movem.l	a2-a3/d2-d4,-(sp)
	move.l	T_EcCourant(a5),a0
	move.w	EcNumber(a0),d2
	lsl.l	#7,d2
	lea	T_CopMark(a5),a2
	add.w	d2,a2
	move.l	a2,d2
	lea	EcPal(a0),a0
	moveq	#0,d0
	moveq	#0,d1
	moveq	#31,d4
* Boucle de pokage
EcSP1	move.w	(a1)+,d1
	bmi.s	EcSP3
	and.w	#$FFF,d1
* Poke dans la table
	move.w	d1,(a0)
* Poke dans le copper
	move.l	d2,a2
	cmp.w	#PalMax*4,d0
	bcs.s	EcSP2
	lea	64(a2),a2
EcSP2:	move.l	(a2)+,d3
	beq.s	EcSP3
	move.l	d3,a3
	move.w	d1,2(a3,d0.w)
	bra.s	EcSP2
EcSP3:	addq.l	#2,a0
	addq.w	#4,d0
	dbra	d4,EcSP1
	movem.l	(sp)+,a2-a3/d2-d4
	moveq	#0,d0
	rts

******* COLOUR BACK D1
EcSColB	and.w	#$FFF,d1
	move.w	d1,T_EcFond(a5)
	moveq	#0,d0
	rts

***********************************************************
*-----*	Ss programme ---> adresse d'un ecran
EcGet:	move.w	d1,d0
	lsl.w	#2,d0
	lea	T_EcAdr(a5),a0
	add.w	d0,a0
	move.l	(a0),d0
	rts
EcGE:	moveq	#0,d0
	rts

******* Trouve le premier ecran libre
EcLibre:lea	T_EcAdr(a5),a0
	moveq	#-1,d1
EcL:	addq.l	#1,d1
	tst.l	(a0)+
	beq.s	EcGE
	cmp.w	#EcMax,d1
	bcs.s	EcL
	moveq	#-1,d0
	rts

