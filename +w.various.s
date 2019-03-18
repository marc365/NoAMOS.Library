;-----------------------------------------------------------------
; **** *** **** ****
; *     *  *  * *	******************************************
; ****  *  *  * ****	* Various
;    *  *  *  *    *	******************************************
; ****  *  **** ****
;-----------------------------------------------------------------

;-----> Wait mouse key
;WaitMK: bsr MBout
;	 cmp.w	 #2,d1
;	 bne.s	 WaitMk
;Att:	 bsr MBout
;	 cmp.w	 #0,d1
;	 bne.s	 Att
;	 rts

;-----> OWN BLITTER
OwnBlit:movem.l	d0/d1/a0/a1/a6,-(sp)
	move.l	GfxBase(pc),a6
	jsr	_LVOOwnBlitter(a6)
	movem.l	(sp)+,d0/d1/a0/a1/a6
;-----> Wait blitter fini
BlitWait
	move.l	a6,-(sp)
	move.l	GfxBase(pc),a6
	jsr	_LVOWaitBlit(a6)
	move.l	(sp)+,a6
	rts
;-----> DISOWN BLITTER
DOwnBlit
	movem.l	d0/d1/a0/a1/a6,-(sp)
	move.l	GfxBase(pc),a6
	jsr	_LVODisownBlitter(a6)
	movem.l	(sp)+,d0/d1/a0/a1/a6
	rts

;-----> Position du faisceau
;PosVbl: move.l  $004(a6),d0
;	 lsr.l 	 #8,d0
;	 and.w 	 #$1FF,d0
;	 rts

;	Clear CPU Caches
; ~~~~~~~~~~~~~~~~~~~~~~
Sys_ClearCache
	movem.l	a0-a1/a6/d0-d1,-(sp)
	move.l	$4.w,a6
	cmp.w	#37,$14(a6)			A partir de V37
	bcs.s	.Exit
	jsr	_LVOCacheClearU(a6)
.Exit	movem.l	(sp)+,a0-a1/a6/d0-d1
	rts

; RETOUR L'ETAT DU FLAG DISC
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
TGetDisc
	move.w	T_DiscIn(a5),d0
	ext.l	d0
	rts

;	Gestion cyclique hors interruptions
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WTest_Cyclique
