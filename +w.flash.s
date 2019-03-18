;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;         INITIALISATION DU FLASHEUR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FlInit: clr 	T_nbflash(a5)
        move 	#lflash*FlMax-1,d0
        lea	T_tflash(a5),a0
razfl1: clr.b 	(a0)+
        dbra 	d0,razfl1
        rts

; FLASH OFF: arrete les flash de l'ecran active
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FlStop:	move.l	T_EcCourant(a5),d0
	addq.b	#1,T_NbFlash+1(a5)	Inhibe les interruptions
	moveq	#FlMax-1,d1
	lea	T_TFlash(a5),a0
FlS1	tst.w	(a0)
	beq.s	FlS3
	cmp.l	4(a0),d0
	bne.s	FlS3
	clr.w	(a0)
FlS3	lea	LFlash(a0),a0
	dbra	d1,FlS1
FlSx	bsr	FlCalc			Nombre de flash reels
	subq.b	#1,T_NbFlash+1(a5)	Redemarre
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       FLASH X,A$     d1=numero de la couleur, a1=adresse de la chaine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FlStart	movem.l	a2-a6/d2-d7,-(sp)
	cmp.b	#FlMax,T_NbFlash(a5)
	bcc	FlToo
	addq.b	#1,T_NbFlash+1(a5)	;Arrete les flashes
        clr 	d5
; Trouve une position dans la table
        lea	T_tflash(a5),a0       	;trouve la position dans la table
	moveq	#FlMax-1,d0
        addq 	#1,d1
        lsl 	#1,d1
	move.l	T_EcCourant(a5),d2	;ecran ouvert!
flshi1: tst.w 	(a0)            	;premiere place libre
        beq.s 	flspoke
        cmp.w 	(a0),d1         	;Meme couleur Meme ecran
        bne.s	flshi0
	cmp.l	4(a0),d2
	beq.s	flspoke
flshi0: lea 	lflash(a0),a0
	dbra	d0,flshi1
        bra.s 	flsont          	;par securite
flsynt	clr.w 	(a0)          		;arrete la couleur
flsont	moveq 	#8,d0
flout	bsr	FlCalc			;Nombre de flash REEL
	subq.b	#1,T_NbFlash+1(a5)	;Deshinibe
	tst.w	d0
FlExit	movem.l	(sp)+,d2-d7/a2-a6
	rts
; Place trouvee: poke dans la table
flspoke	moveq 	#lflash-1,d0  		;nettoie la table
        move.l 	a0,a2
flshi3: clr.b 	(a2)+
        dbra 	d0,flshi3
        moveq	#0,d0
        tst.b 	(a1)          		;flash 1,"": arret de la couleur
        beq.s 	flout
	move.l	a0,a2
	move.w	d1,(a2)+		;Numero de la couleur
	move.w	#1,(a2)+		;Compteur
        move.l 	d2,(a2)+    		;Adresse de l'ecran
	clr.w	(a2)+			;Position
        moveq 	#-1,d4
flshi4: move.b	(a1)+,d0
        cmp.b 	#"(",d0
        bne 	flshi5
        addq.l 	#1,d4
        cmp 	#16,d4             	;16 couleurs autorisees!
        bcc 	flsynt
	moveq	#12,d2
	clr.l	d1
	bsr	GetHexa
	beq	FlSynt
	lsl.w	d2,d1
	lsl.l	#4,d1
	bsr	GetHexa
	beq	FlSynt
	lsl.w	d2,d1
	lsl.l	#4,d1
	bsr	GetHexa
	beq	FlSynt
	lsl.w	d2,d1
	lsl.l	#4,d1
	swap	d1
        move.w 	d1,2(a2)	  	;poke la couleur!
        cmp.b 	#",",(a1)+
        bne 	flsynt
        bsr 	dechexa
        bne 	flsynt
        tst 	d1
        beq 	flsynt
        move.w 	d1,(a2)		   	;poke la vitesse
	addq.l	#4,a2
        cmp.b 	#")",d0
        bne 	flsynt
        bra 	flshi4
flshi5: tst.b 	d0            		;la chaine doit etre finie!
        bne 	flsynt
        clr.l 	d0            		;pas d'erreur
        bra 	flout
; Erreurs flash
FlToo	moveq	#7,d0			* Too many flash
	bra	FlExit

; 	Calcule le nombre exact de flash
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FlCalc	movem.l	a0-a1/d0-d1,-(sp)
	addq.b	#1,T_NbFlash+1(a5)
	moveq	#0,d0
	moveq	#FlMax-1,d1
        lea	T_tflash(a5),a0       	;trouve la position dans la table
.Loop	tst.w	(a0)
	beq.s	.Next
	addq.w	#1,d0
.Next	lea	lflash(a0),a0
	dbra	d1,.Loop
	move.b	d0,T_NbFlash(a5)
	subq.b	#1,T_NbFlash+1(a5)
	movem.l	(sp)+,a0-a1/d0-d1
	rts

***********************************************************
*	START SHIFT
*	D1= 	Numero du shift
*	D2=	Vitesse
*	D3=	Col debut
*	D4=	Col fin
*	D5= 	Direction
*	D6= 	Rotation?
***********************************************************
ShStart	movem.l	a2/d3/d4,-(sp)
	move.l	T_EcCourant(a5),a0
	lea	T_TShift(a5),a1
	move.l	a1,a2
	clr.w	(a1)+
	move.w	d2,(a1)+
	move.l	a0,(a1)+
	and.w	#31,d3				*** 256 couleurs!
	and.w	#31,d4
	cmp.w	d3,d4
	bls.s	.Err
	lsl.w	#1,d3
	lsl.w	#1,d4
	move.w	d3,(a1)+
	move.w	d4,(a1)+
	move.b	d5,(a1)+
	move.b	d6,(a1)+
	move.w	#1,(a2)
	moveq	#0,d0
.Out	movem.l	(sp)+,a2/d3/d4
	rts
.Err:	moveq	#9,d0
	bra.s	.Out

***********************************************************
*	Initialisation de la table des shifts
***********************************************************
ShInit:	lea	T_TShift(a5),a0
	move.w	#LShift/2-1,d0
ShI:	clr.w	(a0)+
	dbra	d0,ShI
	rts

***********************************************************
*	Arret des shifts d'un ecran
***********************************************************
ShStop:	move.l	T_EcCourant(a5),d0
	lea	T_TShift(a5),a0
	tst.w	(a0)
	beq.s	ShStX
	cmp.l	4(a0),d0
	bne.s	ShStX
	clr.w	(a0)
ShStX:	moveq	#0,d0
	rts

***********************************************************
*	INTERRUPTIONS SHIFTER
***********************************************************
Shifter:lea	T_TShift(a5),a0
	tst.w	(a0)
	beq.s	ShfX
	subq.w	#1,(a0)
	bne.s	ShfX
* Shifte!
	move.w	2(a0),(a0)
	addq.l	#4,a0
	move.l	(a0)+,a1
	move.w	EcNumber(a1),d0
	lsl.w	#7,d0
	lea	0(a3,d0.w),a4
	lea	EcPal(a1),a1
	move.w	(a0)+,d0
	move.w	(a0)+,d1
	move.w	d0,d2
	move.w	d1,d3
	tst.b	(a0)+
	bne.s	Shf6
* En montant!
	move.w	0(a1,d3.w),d5
Shf5:	move.w	-2(a1,d3.w),0(a1,d3.w)
	subq.w	#2,d3
	cmp.w	d2,d3
	bne.s	Shf5
	bra.s	Shf8
* En descendant
Shf6:	move.w	0(a1,d2.w),d5
Shf7:	move.w	2(a1,d2.w),0(a1,d2.w)
	addq.w	#2,d2
	cmp.w	d2,d3
	bne.s	Shf7
* Poke dans les listes copper les couleurs D0-D1
Shf8:	tst.b	(a0)+			* Rotation???
	beq.s	Shf8a
	move.w	d5,0(a1,d2.w)
Shf8a:	move.w	d0,d2
	lsl.w	#1,d2
Shf9:	move.w	0(a1,d0.w),d3
	move.l	a4,a2
	cmp.w	#PalMax*2,d0
	bcs.s	ShfC
	lea	64(a2),a2
ShfC:	move.l	(a2)+,d4
	beq.s	ShfB
ShfA:	move.l	d4,a0
	move.w	d3,2(a0,d2.w)
	move.l	(a2)+,d4
	bne.s	ShfA
ShfB:	addq.w	#2,d0
	addq.w	#4,d2
	cmp.w	d1,d0
	bls.s	Shf9
* Fini!
ShfX	rts

***********************************************************
*	FADE OFF
FadeTOf	clr.w	T_FadeFlag(a5)
	moveq	#0,d0
	rts
***********************************************************
*	ARRETE LE FADE DE L'ECRAN COURANT!
FaStop	move.l	T_EcCourant(a5),a0
	lea	EcPal(a0),a0
	cmp.l	T_FadePal(a5),a0
	bne.s	FaStp
	clr.w	T_FadeFlag(a5)
FaStp	rts

***********************************************************
*	INSTRUCTION FADE
*	A1=	Nouvelle palette
*	D1=	Vitesse
FadeTOn	movem.l	d1-d7/a1-a3,-(sp)
	move.l	T_EcCourant(a5),a2
* Params
DoF1	clr.w	T_FadeFlag(a5)
	move.w	#1,T_FadeCpt(a5)
	move.w	d1,T_FadeVit(a5)
	move.w	EcNumber(a2),d0
	lsl.w	#7,d0
	lea	T_CopMark(a5),a3
	add.w	d0,a3
	move.l	a3,T_FadeCop(a5)
	lea	EcPal(a2),a2
	move.l	a2,T_FadePal(a5)
* Explore toutes la palette (marquee)
	moveq	#0,d7
	moveq	#0,d6
	lea	T_FadeCol(a5),a3
DoF2	move.w	(a1)+,d2
	bmi.s	DoF5
	move.w	d7,(a3)+
	moveq	#8,d4
	moveq	#0,d5
	move.w	0(a2,d7.w),d0
DoF3	move.w	d0,d1
	lsr.w	d4,d1
	and.w	#$000F,d1
	move.w	d2,d3
	lsr.w	d4,d3
	and.w	#$000F,d3
	move.b	d1,(a3)+
	move.b	d3,(a3)+
	cmp.b	d1,d3
	beq.s	DoF4
	or.w	#$1,d5
DoF4	subq.w	#4,d4
	bpl.s	DoF3
	add.w	d5,d6
	tst.w	d5
	bne.s	DoF5
	subq.l	#8,a3
DoF5	addq.w	#2,d7
	cmp.w	#32*2,d7
	bcs.s	DoF2
* Demarre -ou non!-
	move.w	d6,T_FadeFlag(a5)
	subq.w	#1,d6
	move.w	d6,T_FadeNb(a5)
DoFx	movem.l	(sp)+,d1-d7/a1-a3
	moveq	#0,d0
	rts
***********************************************************
*	INTERRUPTIONS FADEUR
*	Attention! Change A3!!!
***********************************************************
FadeI	tst.w	T_FadeFlag(a5)
	beq.s	FadX
	subq.w	#1,T_FadeCpt(a5)
	beq.s	Fad0
FadX	rts
* Fade!
Fad0	move.w	T_FadeVit(a5),T_FadeCpt(a5)
	move.l	T_FadePal(a5),a1
	move.l	T_FadeCop(a5),d3
	move.w	T_FadeNb(a5),d7
	lea	T_FadeCol(a5),a2
	moveq	#0,d6
* Boucle
Fad1	move.w	(a2)+,d5
	bmi.s	FadN0
	moveq	#0,d4
	moveq	#0,d0
	move.b	(a2)+,d0
	cmp.b	(a2)+,d0		* R
	beq.s	Fad4
	bhi.s	Fad2
	addq.w	#1,d0
	bra.s	Fad3
Fad2	subq.w	#1,d0
Fad3	addq.w	#1,d4
	move.b	d0,-2(a2)
Fad4	moveq	#0,d1
	move.b	(a2)+,d1
	cmp.b	(a2)+,d1		* G
	beq.s	Fad7
	bhi.s	Fad5
	addq.w	#1,d1
	bra.s	Fad6
Fad5	subq.w	#1,d1
Fad6	addq.w	#1,d4
	move.b	d1,-2(a2)
Fad7	moveq	#0,d2
	move.b	(a2)+,d2
	cmp.b	(a2)+,d2		* B
	beq.s	FadA
	bhi.s	Fad8
	addq.w	#1,d2
	bra.s	Fad9
Fad8	subq.w	#1,d2
Fad9	addq.w	#1,d4
	move.b	d2,-2(a2)
* Calcule la couleur
FadA	tst.w	d4
	beq.s	FadN1
	addq.w	#1,d6
	lsl.w	#4,d0
	or.w	d1,d0
	lsl.w	#4,d0
	or.w	d2,d0
* Poke dans l'ecran
	move.w	d0,0(a1,d5.w)
* Poke dans les listes copper
	lsl.w	#1,d5
	move.l	d3,a3
	cmp.w	#PalMax*4,d5
	bcs.s	FadC
	lea	64(a3),a3
FadC	move.l	(a3)+,d1
	beq.s	FadN
FadB	move.l	d1,a4
	move.w	d0,2(a4,d5.w)
	move.l	(a3)+,d1
	bne.s	FadB
* Couleur suivante
FadN	dbra	d7,Fad1
	move.w	d6,T_FadeFlag(a5)
	rts
* Rien dans cette couleur
FadN0	addq.l	#6,a2
	dbra	d7,Fad1
	move.w	d6,T_FadeFlag(a5)
	rts
* Plus rien maintenant
FadN1	move.w	#-1,-8(a2)
	bra.s	FadN


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       INTERRUPTIONS FLASHEUR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FlInt:  tst.b	T_NbFlash+1(a5)		Autorisee?
	bne.s	FlShXX
	move.b 	T_NbFlash(a5),d7	Nombre en route
	beq.s	FlShXX
	addq.b	#1,T_NbFlash+1(a5)	Inhibe!
        lea	T_tflash-lflash+2(a5),a0
FlShLL	lea	lflash-2(a0),a0
FlShL	move.w 	(a0)+,d0
        beq.s 	FlShLL
; Flashe!
	sub.w 	#1,(a0)			* Compteur
        bne.s 	FlShN
	lea	2(a0),a1
	move.l	(a1)+,a2		* Adresse de l'ecran
	add.w	(a1)+,a1		* Pointe
	move.w	(a1)+,(a0)
	bne.s	Flsh4
	lea	6(a0),a1
	clr.w	(a1)+
	move.w	(a1)+,(a0)
FlSh4:	addq.w	#4,6(a0)		* Pointe le suivant
	move.w	(a1),d2
	move.w	d2,EcPal-2(a2,d0.w)	* Change dans la definition
	lsl.w	#1,d0
	move.w	EcNumber(a2),d1
	lsl.w	#7,d1
	lea	0(a3,d1.w),a2
	cmp.w	#PalMax*4+4,d0
	bcs.s	FlSh5
	lea	64(a2),a2
FlSh5:	move.l	(a2)+,d1		* Change toutes les definitions
	beq.s	FlShN
FlSh6:	move.l	d1,a1
	move.w	d2,2-4(a1,d0.w)
	move.l	(a2)+,d1
	bne.s	FlSh6
; Encore un actif?
FlShN	subq.b	#1,d7
	bne.s	FlShLL
; Fini!
FlShX	subq.b	#1,T_NbFlash+1(a5)	Retabli les interruptions
FlShXX	rts

; Prend un chiffre hexa--> D1
Gethexa:clr.w	d1
	bsr	MiniGet
	beq.s	GhX
	move.b	d0,d1
	sub.b	#"0",d1
	cmp.b	#9,d1
	bls.s	Gh1
	sub.b	#7,d1
Gh1:	cmp.b	#15,d1
	bhi.s	GhX
	moveq	#1,d0
	rts
GhX:	moveq	#0,d0
	rts

;Conversion dec/hexa a1 -> chiffre en d1
dechexa:clr 	d1         	; derniere lettre en D0
        clr 	d2
        bsr 	miniget
        beq.s 	Mdh5
        bpl.s 	Mdh2
        cmp.b 	#"-",d0
        bne.s 	Mdh5
        moveq 	#1,d2
Mdh0:   bsr 	miniget
        beq.s 	Mdh3
        bmi.s 	Mdh3
Mdh2:   mulu 	#10,d1
        sub.b 	#48,d0
        and 	#$00ff,d0
        add 	d0,d1
        bra.s 	Mdh0
Mdh3:   tst 	d2
        beq.s 	Mdh4
        neg 	d1
Mdh4:   clr 	d2              ;beq: un chiffre
        rts
Mdh5:   moveq 	#1,d2         	;bne: pas de chiffre
        rts

; Mini CHRGET: (a1)--->d0
miniget:move.b	(a1)+,d0     ;beq: fini
        beq.s 	mini5           ;bmi: lettre
        cmp.b 	#32,d0        ;bne: chiffre
        beq.s 	miniget
        cmp.b 	#"0",d0
        blt.s 	mini2
        cmp.b 	#"9",d0
        bhi.s 	mini2
        moveq 	#1,d7
        rts
mini2:  cmp.b 	#"a",d0       ;transforme en majuscules
        bcs.s 	mini3
        sub.b 	#32,d0
mini3:  moveq 	#-1,d7
mini5:  rts
