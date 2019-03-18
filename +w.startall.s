; Normal cold start: start default system
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
StartAll
	movem.l	a0-a6/d1-d7,-(sp)
	move.l	sp,T_GPile(a5)

	move.l	a2,-(sp)			Palette par defaut
	move.l	a0,-(sp)

; Attend que l'autre AMOS soit arrete! (si v2.0)
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	cmp.w	#$0200,T_WVersion(a5)
	bcs.s	.No20_a
	movem.l	a0-a3/d0-d3,-(sp)
	move.l	T_Stopped(a5),d0
	beq.s	.Wait2
	move.l	d0,a2
	move.w	#50*5,d3
.Wait1	move.l	T_GfxBase(a5),a6
	jsr	_LVOWaitTOF(a6)
	cmp.b	#"S",(a2)
	bne.s	.Wait2
	dbra	d3,.Wait1
.GoEnd	bra	GFatal
.Wait2	movem.l	(sp)+,a0-a3/d0-d3
.No20_a

; Sauve les flags du DMA
; ~~~~~~~~~~~~~~~~~~~~~~
	move.b	d0,T_AMOSHere(a5)
	move.w	Circuits+DmaConR,T_OldDma(a5)
	bset	#7,T_OldDma(a5)

; Amiga-A
; ~~~~~~~
	tst.l	d1
	bne.s	.Skip
	move.l	#$00406141,d1
.Skip	move.b	d1,T_AmigA_Ascii1(a5)
	lsr.l	#8,d1
	move.b	d1,T_AmigA_Ascii2(a5)
	lsr.w	#8,d1
	move.b	d1,T_AmigA_Shifts(a5)

; Mouse.Abk (si v2.0)
; ~~~~~~~~~~~~~~~~~~~
	cmp.w	#2,T_WVersion(a5)
	bcs.s	.No20_b
	move.l	a1,d0
	bne.s	.MSkip
	move.l	WDebut-4(pc),d0			Prend le HUNK suivant
	lsl.l	#2,d0
	move.l	d0,a1
	addq.l	#4,a1
.MSkip	cmp.l	#"AmSp",(a1)+
	;bne GFatal
	move.w	(a1)+,d1
	cmp.w	#4,d1
	;bcs GFatal
	move.l	a1,T_MouBank(a5)
; Pointe la palette pour l'ouverture des ecrans
	subq.w	#1,d1
.MLoop	move.w	(a1)+,d0
	mulu	(a1)+,d0
	mulu	(a1)+,d0
	lsl.l	#1,d0
	lea	4(a1,d0.l),a1
	dbra	d1,.MLoop
	move.w	#-1,(a1)		Stoppe la mouse.abk
	lea	16*2(a1),a1		Pointe couleurs 16-32
	lea	16*2(a2),a2		Couleurs 16-32 de default palette
	moveq	#15,d0
.PCopy	move.w	(a1)+,(a2)+
	dbra	d0,.PCopy
.No20_b

    bsr Init_Font

; Graphic library
; ~~~~~~~~~~~~~~~
	lea	GfxBase(pc),a1
	move.l	T_GfxBase(a5),a0
	move.l	a0,(a1)
	clr.b	T_WFlags(a5)			Flag AA
	btst	#2,236(a0)
	beq.s	.PaAA
	bset	#WFlag_AA,T_WFlags(a5)
	bset	#WFlag_LoadView,T_WFlags(a5)
.PaAA	move.l	$4.w,a0				Kickstart >= V39?
	cmp.w	#39,$14(a0)			Si oui, on fait un LoadView(0)
	bcs.s	.Pa39
	bset	#WFlag_LoadView,T_WFlags(a5)
.Pa39
	IFNE	Debug=2				Si debug
	bclr	#WFlag_LoadView,T_WFlags(a5)	AMIGA-A normal...
	ENDC


; Ma propre tache
; ~~~~~~~~~~~~~~~
	sub.l	a1,a1
	move.l	$4.w,a6
	jsr	_LVOFindTask(a6)
	move.l	d0,T_MyTask(a5)
	move.l	d0,a0

; Ouverture du layer.library
; ~~~~~~~~~~~~~~~~~~~~~~~~~~
	moveq	#0,d0
	lea	LayName(pc),a1
	move.l	$4.w,a6
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,T_LayBase(a5)
	beq	GFatal

    bsr InputInit

; Parametres par defaut des ecrans
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    move.l  (sp),a0
    move.w  #129,T_DefWX(a5)
    move.w  #129-16,T_DefWX2(a5)
    move.w  10(a0),T_DefWY(a5)
    move.w  10(a0),T_DefWY2(a5)
    subq.w  #8,T_DefWY2(a5)

	lea 	Circuits,a6
	move.l	(sp),a0
	move.l	16(a0),d0
	bsr	HsInit			Hard sprites
	move.l	(sp),a0
	move.w	8(a0),d0
	bsr	BbInit			Bobs
	bsr	RbInit			Retourneur de bobs
	move.l	(sp),a0
	move.l	12(a0),d0
	bsr	CpInit			Copper
	bsr	EcInit			Ecrans
	bsr	AMALInit                Animation Language
	bsr	VBLInit			Interruptions VBL
	bsr	WiInit			Windows

;	Si AA, change le vecteur LOADVIEW
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	btst	#WFlag_LoadView,T_WFlags(a5)	Si LoadView en route
	beq.s	.NoLoadView
	lea	AMOS_LoadView(pc),a0
	lea	T_AMOSHere(a5),a1		Adresse du test
	move.l	a1,2(a0)			>>> dans le source...
	move.l	a0,d0				Nouvelle fonction
	move.w	#_LVOLoadView,a0
	move.l	T_GfxBase(a5),a1		Librairie
	move.l	$4.w,a6
	jsr	_LVOSetFunction(a6)
	lea	Old_LoadView(pc),a0		Ancien vecteur
	move.l	d0,(a0)
	bsr	Sys_ClearCache			Nettoie les caches!
.NoLoadView

; 	Branche le requester
; ~~~~~~~~~~~~~~~~~~~~~~~~~~
	cmp.w	#$0200,T_WVersion(a5)
	bcs.s	.No20_c
	move.l	4(sp),a0			Palette par defaut
	bsr	WRequest_Start
; 	Fabrique la fonte par defaut
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	bsr	Wi_MakeFonte
	bne	GFatal

; 	Envoie le signal a l'AMOS Switcher
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l	T_MyTask(a5),a0
	move.l	a5,$58(a0)
	moveq	#Switcher_Signal,d3
	bsr	Send_Switcher
.No20_c

; 	Tout fini: AMOS to front ?
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	tst.b	T_AMOSHere(a5)
	beq.s	.Pafr
	clr.b	T_AMOSHere(a5)
	moveq	#1,d1
	bsr	TAMOSWb
.Pafr
; Pas d'erreur
; ~~~~~~~~~~~~
	moveq	#0,d0
	bra.s	GFini
; 	Error: ERASE ALL, and returns!
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
GFatal	bsr.s	EndAll
	moveq	#-1,d0
GFini	move.l	T_GPile(a5),a7
	movem.l	(sp)+,a0-a6/d1-d7
	rts

GfxBase	    ds.l    1
LayName		dc.b	"layers.library",0
    even
