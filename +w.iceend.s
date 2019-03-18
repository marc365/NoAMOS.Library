; Fin d'access au fonctions systeme
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
IceEnd
; Relance l'ancien AMOS (si 2.0)
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	cmp.w	#$0200,T_WVersion(a5)
	bcs.s	.No20_a
	move.l	T_Stopped(a5),d0
	beq.s	.Skup
	move.l	d0,a0
	move.b	#" ",(a0)
; Remet son ancien nom
.Skup	move.l	T_MyTask(a5),d0
	beq.s	.Skiip
	move.l	d0,a0
	move.l	T_OldName(a5),10(a0)
.Skiip
.No20_a
; Enleve la gestion memoire si definie
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	bsr	WMemEnd			Plus de memory checking!
	rts



