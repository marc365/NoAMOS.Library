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

    IFNE    MOCK
; ~~~~

   lea      out_startup(pc),a1
   bsr      outmsg

; ~~~~
    ENDC

; Ma propre tache
; ~~~~~~~~~~~~~~~
   sub.l a1,a1
   move.l   $4.w,a6
   jsr   _LVOFindTask(a6)
   move.l   d0,T_MyTask(a5)
   move.l   d0,a0

   bsr   InputInit

   lea   Circuits,a6
   move.l   (sp),a0
   move.l   16(a0),d0
   bsr   HsInit         Hard sprites
   move.l   (sp),a0
   move.w   8(a0),d0
   bsr   BbInit         Bobs
   bsr   RbInit         Retourneur de bobs
   move.l   (sp),a0
   move.l   12(a0),d0
   bsr   CpInit         Copper
   bsr   EcInit         Ecrans
   bsr   AMALInit                Animation Language
   bsr   VBLInit        Interruptions VBL
   bsr   WiInit         Windows

   moveq #0,d0
	bra.s	GFini
; 	Error: ERASE ALL, and returns!
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
GFatal	bsr.s	EndAll
	moveq	#-1,d0
GFini	move.l	T_GPile(a5),a7
	movem.l	(sp)+,a0-a6/d1-d7
	rts
