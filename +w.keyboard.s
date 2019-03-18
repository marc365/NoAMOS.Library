InputInit
; Branche l'input.device
; ~~~~~~~~~~~~~~~~~~~~~~
    bsr ClInit
; Open Console Device
; ~~~~~~~~~~~~~~~~~~~
    lea ConIo(pc),a1
    bsr OpConsole
; Branche le input_handler
; ~~~~~~~~~~~~~~~~~~~~~~~~
    lea T_IoDevice(a5),a1
    bsr OpInput
    lea T_Interrupt(a5),a0
    lea IoHandler(pc),a1
    move.l  a1,IS_CODE(a0)
    clr.l   IS_DATA(a0)
    move.b  #100,ln_pri(a0)
    lea T_IoDevice(a5),a1
    move.l  a0,io_Data(a1)
    move.w  #IND_ADDHANDLER,io_command(a1)
    jsr _LVODoIo(a6)
    move.w  #-1,T_DevHere(a5)
    rts

; OPEN CONSOLE.DEVICE
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
OpConsole
	lea	ConIo(pc),a1
	moveq	#(Lio+Lmsg)/2-1,d0
.Clean	clr.w	(a1)+
	dbra	d0,.Clean
	move.l	$4.w,a6
	lea	ConName(pc),a0
	lea	ConIo(pc),a1
	moveq	#-1,d0			Console #= -1
	moveq	#0,d1
	jsr	_LVOOpenDevice(a6)
	rts

; OPEN INPUT.DEVICE
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	A1-> 	pointeur sur zone libre!!!
OpInput
	move.l	a1,-(sp)
* Clean
	moveq	#(Lio+Lmsg)/2-1,d0
OpInp1	clr.w	(a1)+
	dbra	d0,OpInp1
* Creates port
	sub.l	a1,a1
	move.l	$4.w,a6
	jsr	_LVOFindTask(a6)
	move.l	(sp),a1
	lea	Lio(a1),a1
	move.l	d0,$10(a1)
	jsr	_LVOAddPort(a6)
* Open device
	lea	DevName(pc),a0
	move.l	(sp),a1
	moveq	#0,d0
	moveq	#0,d1
	jsr	_LVOOpenDevice(a6)
	move.l	(sp)+,a1
	lea	Lio(a1),a0
	move.l	a0,14(a1)
	rts

; CLOSE input.device
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ClInput	move.l	a1,-(sp)
; Close device
	move.l	$4.w,a6
	jsr	_LVOCloseDevice(a6)
; Close port
	move.l	(sp)+,a1
	lea	Lio(a1),a1
	jsr	_LVORemPort(a6)
	rts

; Input handler, branche sur la chaine des inputs.
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
IoHandler
	move.l	a5,-(sp)
	move.l	W_Base(pc),a5
; Si inhibe, laisse TOUT passer!
	tst.w	T_Inhibit(a5)
	bne.s	I_Inhibit
; Continue...
	move.b	T_AMOSHere(a5),d4		Si AMOS pas la,
	ext.w	d4
	bne.s	.Skip
	bset	#WFlag_Event,T_WFlags(a5)	Marque des faux events!
.Skip	move.l	a0,d0
	move.l	a0,d2
	moveq	#0,d3
IeLoop	move.b	Ie_Class(a0),d1
	cmp.b	#IeClass_RawMouse,d1
	beq.s	IeMous
	cmp.b	#IeClass_Rawkey,d1
	beq	IeKey
	cmp.b	#IeClass_DiskInserted,d1
	beq.s	IeDIn
	cmp.b	#IeClass_DiskRemoved,d1
	beq.s	IeDOut
IeLp1	move.l	d2,d3
	move.l	(a0),d2
IeLp2	move.l	d2,a0
	bne.s	IeLoop
IeLpX	move.l	(sp)+,a5
	rts
I_Inhibit
	move.l	(sp)+,a5
	move.l	a0,d0
	rts
; Disc inserted
IeDIn	bset	#WFlag_Event,T_WFlags(a5)
	move.w	#-1,T_DiscIn(a5)
	bra.s	IeLp1
; Disc removed
IeDOut	bset	#WFlag_Event,T_WFlags(a5)
	clr.w	T_DiscIn(a5)
	bra.s	IeLp1
; Evenement Mouse, fait le mouvement!
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
IeMous	tst.w	d4
	beq.s	IeLp1
	bset	#WFlag_Event,T_WFlags(a5)		Flag: un event!
	cmp.l	#Fake_Code,ie_X(a0)	Un faux evenement?
	beq.s	IeFake
IeNof	move.w	T_MouYOld(a5),d1	* Devenir des MOUSERAW
	and.w	#$0003,d1		* 0-> Normal
	beq.s	.norm			* 1-> Trash
	subq.w	#2,d1			* 2-> Tout passe
	bmi.s	IeTrash			* 3-> Mouvements seuls
	beq.s	IeLp1
; Mode key only>>> prend les touches, laisse passer les mouvements
	move.w	ie_Qualifier(a0),T_MouXOld(a5)
	and.w	#%1000111111111111,ie_Qualifier(a0)
	move.w	ie_Code(a0),d1
	and.w	#$7f,d1
	cmp.w	#IECODE_LBUTTON,d1
	beq.s	.ski1
	cmp.w	#IECODE_RBUTTON,d1
	bne.s	IeLp1
.ski1	move.w	#IECODE_NOBUTTON,ie_Code(a0)
	bra.s	IeLp1
; Mode normal>>> prend et met a la poubelle
.norm	move.w	ie_Qualifier(a0),d1
	move.w	d1,T_MouXOld(a5)
	btst	#IEQUALIFIERB_RELATIVEMOUSE,d1
	beq.s	IeTrash
	move.w	ie_X(a0),d1
	add.w	d1,T_MouseX(a5)
	move.w	ie_Y(a0),d1
	add.w	d1,T_MouseY(a5)
; Event to trash!
IeTrash	tst.l	d3
	beq.s	IeTr1
	move.l	d3,a1
	move.l	(a0),d2
	move.l	d2,(a1)
	bra	IeLp2
IeTr1	move.l	(a0),d0
	move.l	d0,a0
	bne	IeLoop
	move.l	(sp)+,a5
	rts
; Faux evenement clavier...
; ~~~~~~~~~~~~~~~~~~~~~~~~~
IeFake	cmp.w	#IEQUALIFIER_RELATIVEMOUSE,ie_Qualifier(a0)
	bne	IeNof
	clr.l	ie_X(a0)			Plus de decalage
	bra	IeLp1				On laisse passer
; Event clavier: prend le caractere au vol
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
IeKey	bset	#WFlag_Event,T_WFlags(a5)
	bsr	Cla_Event
	bne.s	.IeKy1
.IeKy0	tst.w	d4		Event to trash ou non
	bne.s	IeTrash
	bra	IeLp1
; AMIGA-A pressed
; ~~~~~~~~~~~~~~~
.IeKy1	tst.w	T_NoFlip(a5)
	bne.s	.IeKy0
	btst	#WFlag_LoadView,T_WFlags(a5)
	bne.s	.AA
; Appel de TAMOSWb, rapide...
	movem.l	a0-a1/d0-d1,-(sp)
	moveq	#0,d1
	tst.w	d4
	bne.s	.Ska
	moveq	#1,d1
.Ska	bsr	TAMOSWb
	movem.l	(sp)+,a0-a1/d0-d1
	bra	IeTrash
; Marque pour TESTS CYCLIQUES
.AA	bset	#WFlag_AmigaA,T_WFlags(a5)
	bra	IeTrash

; 	Gestion des evenements clavier
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	A0=	EVENT KEY
;	D4=	Flag AMOS / WB
Cla_Event
	movem.l	a0-a1/d0-d3,-(sp)
	move.w	Ie_Code(a0),d0
	bclr	#7,d0
	bne	.ClaI2
; Appui sur une touche
; ~~~~~~~~~~~~~~~~~~~~
	cmp.b	#$68,d0				Shifts>>> pas stockes
	bcc.s	.RawK
	cmp.b	#$40,d0
	bcs.s	.RawK
	cmp.b	#$60,d0
	bcc	.Cont
; Conversion a la main des codes speciaux
	lea	Cla_Special-$40(pc),a1
	move.b	0(a1,d0.w),d1
	bpl	.Rien
	cmp.b	#$FF,d1
	beq.s	.RawK
; Une touche de fonction AMOS?
	moveq	#0,d1				Ascii nul
	move.b	Ie_Qualifier+1(a0),d2		Les shifts
	btst	#6,d2
	beq.s	.FFk1
	lea	T_TFF1(a5),a1			Touches 1-10
	bra.s	.FFk2
.FFk1	btst	#7,d2				Pas AMIGA>>> Touche normale
	beq.s	.Rien
	lea	T_TFF2(a5),a1			Touches 11-20
.FFk2	move.w	d0,d2
	sub.w	#$50,d2
	mulu	#FFkLong,d2
	lea	0(a1,d2.w),a1
	tst.b	(a1)
	beq.s	.Rien
	bsr	ClPutK
	moveq	#0,d2
	bra	.ClaIX
; Appel de RAWKEYCONVERT et stockage si AMOS present
.RawK	move.b	Ie_Qualifier+1(a0),d2		Prend CONTROL
	and.b	#%11110111,Ie_Qualifier+1(a0)	Plus de CONTROL
	movem.l	a0/a2/a6,-(sp)
	lea	ConIo(pc),a6			Structure IO
	move.l	20(a6),a6			io_device
	lea	ConBuffer(pc),a1			Buffer de sortie
	sub.l	a2,a2				Current Keymap
	moveq	#LConBuffer,d1			Longueur du buffer
	jsr	_LVORawKeyConvert(a6)
	move.w	d0,d3
	movem.l	(sp)+,a0/a2/a6
	move.b	d2,Ie_Qualifier+1(a0)		Remet CONTROL
	move.w	Ie_Code(a0),d0
	moveq	#0,d1
	subq.w	#1,d3
	bmi.s	.Rien
	lea	ConBuffer(pc),a1			Une seule touche
	move.b	(a1),d1
.Rien	move.b	Ie_Qualifier+1(a0),d2		Les shifts!
; Amiga-A?
.A	move.b	d2,d3
	and.b	T_AmigA_Shifts(a5),d3
	cmp.b	T_AmigA_Shifts(a5),d3
	bne.s	.AAA
	cmp.b	T_AmigA_Ascii1(a5),d1
	beq.s	.AA
	cmp.b	T_AmigA_Ascii2(a5),d1
	bne.s	.AAA
.AA	moveq	#-1,d2
	bra.s	.ClaI1
; AMOS Not here: stop!
.AAA	tst.w	d4
	beq.s	.Cont
; Est-ce un CONTROL-C?
	btst	#3,d2
	beq.s	.Sto
	cmp.b	#"C",d1
	beq.s	.C
	cmp.b	#"c",d1
	bne.s	.Sto
.C	bset	#BitControl,T_Actualise(a5)
	bra.s	.Cont
; Stocke dans le buffer
.Sto	bsr	Cla_Stocke			On stocke!
; Change la table
.Cont	moveq	#0,d2
.ClaI1	move.w	d0,d1
	and.w	#$0007,d0
	lsr.w	#3,d1
	lea	T_ClTable(a5),a0
	bset	d0,0(a0,d1.w)
.ClaIX	tst.w	d2
	movem.l	(sp)+,a0-a1/d0-d3
	rts

; Relachement d'une touche
; ~~~~~~~~~~~~~~~~~~~~~~~~
.ClaI2	move.w	d0,d1
	and.w	#$0007,d0
	lsr.w	#3,d1
	lea	T_ClTable(a5),a1
	bclr	d0,0(a1,d1.w)
.ClaIF	moveq	#0,d0
	movem.l	(sp)+,a0-a1/d0-d3
	rts

; Table des touches $40->$5f
; ~~~~~~~~~~~~~~~~~~~~~~~~~~
Cla_Special
	dc.b	$ff,$08,$09,$0d,$0d,$1b,$00,$00		$40>$47
	dc.b	$00,$00,$ff,$00,$1e,$1f,$1c,$1d		$48>$4f
	dc.b	$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe		$50>$57
	dc.b	$fe,$fe,$ff,$ff,$ff,$ff,$ff,$00		$58>$5f

; Stocke D0/D1/D2 dans le buffer clavier
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	D0	Rawkey
;	D1	Ascii
;	D2	Shifts
Cla_Stocke
	movem.l	a0/d3,-(sp)
	lea	T_ClBuffer(a5),a0
	move.w	T_ClTete(a5),d3
	addq.w	#3,d3
	cmp.w	#ClLong,d3
	bcs.s	.ClS11
	clr.w	d3
.ClS11	cmp.w	T_ClQueue(a5),d3
	beq.s	.ClS12
	move.w	d3,T_ClTete(a5)
	move.b	d2,0(a0,d3.w)
	move.b	d0,1(a0,d3.w)
	move.b	d1,2(a0,d3.w)
.ClS12	move.b	d2,-4(a0)
	move.b	d0,-3(a0)
	move.b	d1,-1(a0)
.ClSFin	movem.l	(sp)+,a0/d3
	rts

; Initialisation / Vide du buffer clavier
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ClInit
ClVide	move.w	T_ClTete(a5),T_ClQueue(a5)
	clr.b	T_ClFlag(a5)
	moveq	#0,d0
	rts

; KEY WAIT, retourne BNE si des touches en attente
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ClKWait	moveq	#0,d0
	move.w	T_ClQueue(a5),d1
	cmp.w	T_ClTete(a5),d1
	rts

; INKEY: D1 haut: SHIFTS/SCANCODE - D1 bas: ASCII
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ClInky	moveq	#0,d1
	move.w	T_ClQueue(a5),d2
	cmp.w	T_ClTete(a5),d2
	beq.s	Ink2
	lea	T_ClBuffer(a5),a0
	addq.w	#3,d2
	cmp.w	#ClLong,d2
	bcs.s	Ink1
	moveq	#0,d2
Ink1:	move.b	0(a0,d2.w),d1
	lsl.w	#8,d1
	move.b	1(a0,d2.w),d1
	swap	d1
	move.b	2(a0,d2.w),d1
	move.w	d2,T_ClQueue(a5)
Ink2:	moveq	#0,d0
	rts

; Change KEY MAP A1
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ClKeyM	rts

***********************************************************
*	Set key speed D1,d2
*	A1---> Buffer libre!!!
***********************************************************
TKSpeed	movem.l	a3-a6,-(sp)
	move.l	a1,-(sp)
	movem.l	d1/d2,-(sp)
	bsr	OpInput
	move.l	(sp),d0
	bsr	CalRep
	move.w	#IND_SETTHRESH,io_command(a1)
	move.l	$4.w,a6
	jsr	_LVODoIO(a6)
	move.l	4(sp),d0
	move.l	8(sp),a1
	bsr	CalRep
	move.w	#IND_SETPERIOD,io_command(a1)
	move.l	$4.w,a6
	jsr	_LVODoIO(a6)
	move.l	8(sp),a1
	bsr	ClInput
	lea	12(sp),sp
	movem.l	(sp)+,a3-a6
	moveq	#0,d0
	rts
CalRep	ext.l	d0
	divu	#50,d0
	move.w	d0,d1
	swap	d0
	ext.l	d0
	mulu	#20000,d0
	move.l	d1,$20(a1)		tv_secs
	move.l	d0,$24(a1)		tv_micro
	rts

; Get shifts
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ClSh:	moveq	#0,d1
	move.b	T_ClShift(a5),d1
	moveq	#0,d0
	rts

; Instant key D1: 0=relache / -1= enfonce
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ClInst:	and.w	#$7F,d1
	move.w	d1,d0
	and.w	#$0007,d0
	lsr.w	#3,d1
	lea	T_ClTable(a5),a0
	lea	0(a0,d1.w),a0
	moveq	#0,d1
	btst	d0,(a0)
	beq.s	Inst
	moveq	#-1,d1
Inst:	moveq	#0,d0
	rts

; PUT KEY: stocke la chaine (A1) dans le buffer
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ClPutK:	move.l	a0,-(sp)
	movem.w	d0-d3,-(sp)
	lea	T_ClBuffer(a5),a0
ClPk0:	clr.b	d0
	clr.b	d1
	move.b	(a1)+,d2
	beq.s	ClPk4
	cmp.b	#"'",d2			* REM
	beq.s	ClPk5
	cmp.b	#1,d2			* ESC
	bne.s	ClPk1
	move.b	(a1)+,d0		* Puis SHF/SCAN/ASCI
	move.b	(a1)+,d1
	move.b	(a1)+,d2
; Stocke!
ClPk1:	move.w	T_ClTete(a5),d3
	addq.w	#3,d3
	cmp.w	#ClLong,d3
	bcs.s	ClPk2
	clr.w	d3
ClPk2:	cmp.w	T_ClQueue(a5),d3
	beq.s	ClPk4
	move.b	d0,0(a0,d3.w)
	move.b	d1,1(a0,d3.w)
	move.b	d2,2(a0,d3.w)
	move.w	d3,T_ClTete(a5)
ClPk3:	bra.s	ClPk0
ClPk5:	move.b	(a1)+,d2
	beq.s	ClPk4
	cmp.b	#"'",d2
	bne.s	ClPk5
	bra.s	ClPk0
ClPk4:	movem.w	(sp)+,d0-d3
	move.l	(sp)+,a0
	rts

; FUNC KEY: stocke la chaine (A1) en fonc D1
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ClFFk:	movem.l	d1-d2,-(sp)
	lea	T_TFF1(a5),a0
	mulu	#FFkLong,d1
	add.w	d1,a0
	clr.w	d0
ClF1:	clr.b	(a0)
	move.b	(a1)+,d2
	beq.s	ClFx
	cmp.b	#1,d2
	beq.s	ClF2
	cmp.b	#"`",d2
	beq.s	ClF3
	addq.w	#1,d0
	cmp.w	#FFkLong-1,d0
	bcc.s	ClF1
	move.b	d2,(a0)+
	bra.s	ClF1
ClFx:	movem.l	(sp)+,d1-d2
	move.l	a1,a0
	moveq	#0,d0
	rts
ClF2:	addq.w	#4,d0
	addq.l	#3,a1
	cmp.w	#FFkLong-1,d0
	bcc.s	ClF1
	move.b	d2,(a0)+
	move.b	-3(a1),(a0)+
	move.b	-2(a1),(a0)+
	move.b	-1(a1),(a0)+
	bra.s	ClF1
ClF3:	addq.w	#2,d0
	cmp.w	#FFkLong-1,d0
	bcc.s	ClF1
	move.b	#13,(a0)+
	move.b	#10,(a0)+
	bra.s	ClF1

; GET KEY: ramene la touche de fonction
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ClGFFk:	lea	T_TFF1(a5),a0
	move.w	d1,d0
	mulu	#FFkLong,d0
	add.w	d0,a0
	moveq	#0,d0
	rts

ConIo		 ds.b 	 32+8
LConBuffer	equ	64
ConBuffer	ds.b 	LConBuffer
ConEssai	ds.b	32
DevName		dc.b	"input.device",0
ConName		dc.b	"console.device",0
