;							Arret general
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EndAll
	lea	Circuits,a6

; 	Arret des toutes les fonctions AMOS
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	bsr	TFFonts
;	bsr	WiEnd			Rts!
	bsr	AMALEnd
	bsr	EcEnd
	bsr	RbEnd
	bsr	BbEnd
	bsr	HsEnd
	bsr	VBLEnd
	bsr	CpEnd

    IFNE    MOCK
; ~~~~

	lea		out_shutdown(pc),a1
	bsr		outmsg

; ~~~~
    ENDC

	moveq	#0,d0
	rts
