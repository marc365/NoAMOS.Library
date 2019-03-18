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
	bra	SliPour		;- PourSli

EcCree
    IFNE    MOCK
; ~~~~

	lea		out_screenopen(pc),a1
	bsr		outmsg

; ~~~~
    rts
    ENDC

EcDel
    IFNE    MOCK
; ~~~~

	lea		out_screenclose(pc),a1
	bsr		outmsg

; ~~~~
    rts
    ENDC

EcEnd
EcRaz
EcFirst
EcLast
EcMarch
EcView
EcOffs
EcDAll
EcLibre
EcAdres
EcGCol
EcSCol
EcSPal
EcSColB
EcHide
EvLibre
EcCClo
EcCrnt
EcDouble
ScSwap
ScSwapS
EcAndres
Duale
DualP
EcCls
TAbk1
TAbk2
TAbk3
TAbk4
WScCpy
TMaxRaw
TNTSC
   moveq #0,d0
   rts
