;FlInit: clr 	 T_nbflash(a5)
;        move 	 #lflash*FlMax-1,d0
;        lea T_tflash(a5),a0
;razfl1: clr.b 	 (a0)+
;        dbra 	 d0,razfl1
;        rts
FlInit
FlStart
ShStart
FadeTOn
FadeTOf
FlStop
ShStop
FaStop
ShInit
Shifter
FlInt
FadeI
    moveq   #0,d0
    rts
