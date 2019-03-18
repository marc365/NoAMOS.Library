IceStart
	move.l	a6,-(sp)
	move.w	d1,T_WVersion(a5)	La version d'AMOS

	lea	W_Base(pc),a0
	move.l	a5,(a0)
	lea	SyIn(pc),a0
	move.l	a0,T_SyVect(a5)
	bsr	WMemInit

	move.l  (sp)+,a6
	move.l	#"W2.0",d0		Retourne des magic
	move.w	#$0200,d1
    rts
