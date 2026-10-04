********************
* 
* DATUM: 15. 2.1991. 
* 
* NAZIV: DEMO
* 
* OPIS:  Glavni program koji poziva kalkulator
* 
* 
********************

*CX=7                                            && Inicijalne koordinate
*CY=15
*Calc()                                          && Kalkulator
*QUIT

********************
* 
* DATUM: 13. 2.1991. 
* 
* NAZIV: Calc ()
* 
* OPIS:  Kalkulator na koordinati (CX,CY)
* 
* 
********************

PROCEDURE Calc

PRIVATE a,o,b,Arrows,KeyXY,Status,KeyMap,i      && Lokalne promenljive
PRIVATE Del,Ret,WAIT,INT,DEC,ZERO,M,Pass,Arg, ;
        Pom,ERROR

PRIVATE Tape[10], TapePtr, TapeVis              && Traka
TapePtr=0                                       && ..je prazna
TapeVis=.T.                                     && ..i vidljiva je

PRIVATE sh_sav, x_sav, y_sav, s_sav, SavC	&& Zapamti stanje sistema
PRIVATE Ch, OldC, Normal, Invert, Light, Blink
x_sav=Row()                                     && ..Kursor
y_sav=Col()
OldC=SetColor()                                 && ..Boja
s_sav=SaveScreen(0,CY,24,CY+16) 		&& ..Pozadina
ERROR="Error"                                   && ..Greska


SET DECIMALS TO 10                              && Tacnost : 10 decimala
SET EXACT ON                                    && Striktno se porede stringovi

KeyMap="0123456789/*-+."+Chr(13)                && Svi kontrolisani tasteri
Del=Chr(8)
Ret=Chr(13)
WAIT="W"                                        && Stanja automata
INT="I"
DEC="D"
ZERO="0"

Arrows=Chr(4)+Chr(19)+Chr(5)+Chr(24)            && Kursorski tasteri
IF col_onoff = "C"
Invert = "N/W,N/W,,,W/N"                        && Postavljanje boja
Normal = "N/W,N/W,,,N/W"
Light = "W+/R,N/G,,,N/G"
Blink = "N/W*,W/N,,,W/N"
else
Invert = "N/W,N/W,,,W/N"                        && Postavljanje boja
Normal = "W/N,N/W,,,N/W"
Light = "W+/N,N/W,,,N/W"
Blink = "N/W*,W/N,,,W/N"
endif

DECLARE KeyXY[9]                                && Koordinate tastera 1-9
KeyXY[1]= "91"
KeyXY[2]= "95"
KeyXY[3]= "99"
KeyXY[4]= "71"
KeyXY[5]= "75"
KeyXY[6]= "79"
KeyXY[7]= "51"
KeyXY[8]= "55"
KeyXY[9]= "59"

SetColor(Light)                                 && Crtanje okvira
@ CX+0,CY SAY  "ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»"
@ CX+1,CY SAY  "º               º"
@ CX+2,CY SAY  "ÌÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍ¹"
@ CX+3,CY SAY  "º   ³   ³   ³   º"
@ CX+4,CY SAY  "ÇÄÄÄÅÄÄÄÅÄÄÄÅÄÄÄ¶"
@ CX+5,CY SAY  "º   ³   ³   ³   º"
@ CX+6,CY SAY  "ÇÄÄÄÅÄÄÄÅÄÄÄ´   º"
@ CX+7,CY SAY  "º   ³   ³   ³   º"
@ CX+8,CY SAY  "ÇÄÄÄÅÄÄÄÅÄÄÄÅÄÄÄ¶"
@ CX+9,CY SAY  "º   ³   ³   ³   º"
@ CX+10,CY SAY "ÇÄÄÄÁÄÄÄÅÄÄÄ´   º"
@ CX+11,CY SAY "º       ³   ³   º"
@ CX+12,CY SAY "ÈÍÍÍÍÍÍÍÏÍÍÍÏÍÍÍ¼"
sh_sav = savescreen(cx, cy, cx+13, cy+17)
sha_shadow(cx, cy, cx+12, cy+16)
SetColor(Normal)

FOR i=1 TO 17                                   && Ispisi tastere
    DrawT(SubStr(KeyMap+"n",i,1),Invert)
NEXT

a=""                                            && Inicijalizacija
o=" "
b=""
M=ZERO
Arg=""
Status=WAIT                                     && Pocetno stanje automata
WrtDis(ZERO)                                    && Nula na ekran
Pass=0                                          && Faza I automata

DO WHILE .T.                
    Inkey(0)                                    && Cekaj na taster
    Ch=Chr(LastKey())                           

    IF Ch = Chr(27)                             && Kraj!
        EXIT

    ELSEIF Ch $ Arrows                          && Pomeranja kalkulatora
	SavC=SaveScreen(CX,CY,CX+12,CY+16)	&& Sacuvaj kalkulator
	RestScreen(CX,CY,CX+13,CY+17,sh_sav)
	RestScreen(0,CY,24,CY+16,s_sav) 	&& Vrati pozadinu

        DO CASE
            CASE Ch=Chr(4) .AND. CY<63          && Desno
                CY=CY+1
            CASE Ch=Chr(19) .AND. CY>0          && Levo
                CY=CY-1
            CASE Ch=Chr(5) .AND. CX>0           && Gore
                CX=CX-1
            CASE Ch=Chr(24) .AND. CX<12         && Dole
                CX=CX+1
        END CASE                                
	s_sav=SaveScreen(0,CY,24,CY+16) 	&& Sacuvaj pozadinu
	sh_sav = SaveScreen(CX,CY,CX+13,CY+17)
	RestScreen(CX,CY,CX+12,CY+16,SavC)	&& Vrati sliku kalkulatora
	sha_shadow(CX,CY,CX+12,CY+16)

    ELSEIF Ch $ "SRCEsrce"                      && Store,Recall,Clear,Exchange
*       Tone(1700,0)
        IF Ch $ "Ss"                            && Disp -> Mem
            M=Arg
            DrawT("n",Blink)
        ELSEIF Ch $ "Rr"                        && Mem -> Disp
            Arg=M
            WrtDis(Arg)
            IF AT(".",M)=0                      && xxxx
                Status=INT
            ELSE                                && xxx.xxx
                Status=DEC
            END IF

        ELSEIF Ch $ "Ee"                        && Mem <-> Disp
            Pom=M
            M=Arg
            DrawT("n",Blink)
            Arg=Pom
            WrtDis(Arg)
            IF AT(".",M)=0                      && xxxx
                Status=INT
            ELSE                                && xxx.xxx
                Status=DEC
            END IF
        ELSE                                    && 0 -> Mem
            M=ZERO
            DrawT("n",Invert)
        END IF

    ELSEIF Ch $ "Nn"                            && Neg
*       Tone(1700,0)
        IF Val(Arg)>0
            Arg="-"+AllTrim(Arg)
            WrtDis(Arg)
        ELSEIF Val(Arg)<0
            Arg=StrTran(Arg,"-")
            WrtDis(Arg)
        END IF
        IF Pass=0
            a=Arg
        ELSE
            b=Arg
        END IF

    ELSEIF Ch $ "Tt"                            && Vidljivost trake
*       Tone(1700,0)
        TapeVis=!TapeVis
        IF !TapeVis
            TapePtr=0
        END IF
        KEYBOARD Chr(5)+Chr(24)

    ELSEIF Ch $ KeyMap+Chr(8)                   && Ako je pritisnut reg.taster
        DrawT(Ch,Normal)
*       Tone(1700,0)
        DrawT(Ch,Invert)
        DO CASE 

            CASE Status=WAIT                    && WAIT
                DO CASE
		    CASE IsDigit1(Ch)
                        Arg=Ch
                        WrtDis(Arg)
                        Status=INT
                    CASE Ch="."
                        Arg="0."
                        WrtDis(Arg)
                        Status=DEC
                    CASE Ch=Del
                        Arg=""
                        IF Pass=1
                            Pass=0
                        END IF
                        STORE ZERO TO a,b
                        WrtTape("#")
                        WrtDis(ZERO)
                    CASE IsOpr(Ch)
                        IF Pass=0
                            Pass=1
                        END IF
                        a=Arg
                        o=Ch
                    CASE Ch=Ret 
                        Pass=0
                        WrtDis(a)
                        WrtTape(Replicate("-",13))
                        WrtTape(a)
                END CASE

            OTHERWISE                           && INT i DEC
                DO CASE
		    CASE IsDigit1(Ch) .AND. Len(Arg)<12
                        Arg=Arg+Ch
                        WrtDis(Arg)
                    CASE Ch=Del
                        Arg=""
                        WrtTape("#")
                        WrtDis(ZERO)
                        Status=WAIT
                    CASE IsOpr(Ch)
                        IF Status=DEC
                            Arg=Arg+ZERO
                        END IF
                        IF Pass=0
                            a=Arg
                            Pass=1
                            WrtTape(a)
                        ELSE
                            b=Arg
                            a=Compute()
                            IF Left(a,1)="*"
                                a=""
                                WrtDis(ERROR)
                            ELSE
                                WrtDis(a)
                                WrtTape(o+b)
                            END IF
                        END IF
                        o=Ch
                        Status=WAIT
                    CASE Ch=Ret
                        IF Status=DEC
                            Arg=Arg+ZERO
                        END IF
                        IF Pass=0
                            a=Arg
                            WrtTape(Replicate("-",13))
                            WrtTape(a)
                        ELSE
                            b=Arg+IF (Status=DEC, ZERO, "")
                            a=Compute()
                            IF Left(a,1)="*"
                                a=""
                                WrtDis(ERROR)
                                WrtTape(ERROR)
                            ELSE
                                WrtDis(a)
                                WrtTape(o+b)
                                WrtTape(Replicate("-",13))
                                WrtTape(a)
                            END IF
                            Pass=0
                        END IF
                        Arg=a
                        Status=WAIT
                    CASE Ch="." .AND. Status=INT
                        Arg=Arg+Ch
                        WrtDis(Arg)
                        Status=DEC
                END CASE

        END CASE
    ELSE
*       Tone(700,0)
    END IF
END DO

RestScreen(CX,CY,CX+13,CY+17,sh_sav)
RestScreen(0,CY,24,CY+16,s_sav)
@ x_sav, y_sav SAY ""
SetColor(OldC)

RETURN

********************
* 
* DATUM: 13. 2.1991. 
* 
* NAZIV: WrtDis(Ch)
* 
* OPIS:  Stampa CH na displej kalkulatora 
* 
* 
********************

PROCEDURE WrtDis

PARAMETERS Ch

@ CX+1,CY+2 SAY Right(Space(13)+Left(AllTrim(IF(Empty(Ch),ZERO,Ch)),13),13)

RETURN


********************
* 
* DATUM: 13. 2.1991. 
* 
* NAZIV: c=Compute()
* 
* OPIS:  Racuna C = A o B
* 
* 
********************

FUNCTION Compute

PRIVATE nc

IF o="/" .AND. Val(b)=0
    RETURN (Replicate("*",13))
ELSE
    nc=IF (a="", ZERO, a)+o+IF (b="", ZERO, b)
    c=Str(&nc)
    IF Abs(Val(c))>999999999999 .OR. Left(c,1)="*"
        RETURN (Replicate("*",13))
    ELSE
        RETURN c
    END IF
END IF

********************
* 
* DATUM: 13. 2.1991. 
* 
* NAZIV: DrawT (Tast, Attr)
* 
* OPIS:  Crta taster atributom Attr
* 
* 
********************

PROCEDURE DrawT
PARAMETERS Tast, Invert

SetColor(Invert)
DO CASE
    CASE Tast $ "123456789"
        @   CX+Val(Left(KeyXY[Asc(Tast)-48],1)), ;
            CY+Val(Right(KeyXY[Asc(Tast)-48],1))  ;
            SAY " "+Tast+" "
    CASE Tast = ZERO
        @ CX+11,CY+1 SAY "   0   "
    CASE Tast = "."
        @ CX+11,CY+9 SAY " . "
    CASE Tast = "+"
        @ CX+5,CY+13 SAY Space(3)
        @ CX+6,CY+13 SAY " + "
        @ CX+7,CY+13 SAY Space(3)
    CASE Tast = Chr(13)
        @ CX+9, CY+13 SAY Space(3)
        @ CX+10,CY+13 SAY " = "
        @ CX+11,CY+13 SAY Space(3)
    CASE Tast = "/"
        @ CX+3,CY+5 SAY " / "
    CASE Tast = "*"
        @ CX+3,CY+9 SAY " * "
    CASE Tast = "-"
        @ CX+3,CY+13 SAY " - "
    CASE Tast = "n"
        @ CX+3,CY+1 SAY " M "
END CASE
SetColor(Normal)
RETURN

********************
* 
* DATUM: 13. 2.1991. 
* 
* NAZIV: l=IsDigit1(Ch)
* 
* OPIS:  Da li je Ch cifra
* 
* 
********************

FUNCTION IsDigit1
PARAMETERS Ch
RETURN ZERO <= Ch .AND. Ch <= "9"


********************
* 
* DATUM: 13. 2.1991. 
* 
* NAZIV: l=IsOpr(Ch)
* 
* OPIS:  Da li je CH operator /*+-
* 
* 
********************

FUNCTION IsOpr
PARAMETERS Ch
RETURN Ch $ "/*+-"


********************
* 
* DATUM: 16. 2.1991. 
* 
* NAZIV: WrtTape(Ch)
* 
* OPIS:  Upisuje CH na traku i stampa je
* 
* 
********************

PROCEDURE WrtTape
PARAMETERS Ch

PRIVATE i, poz

IF TapeVis
    IF TapePtr<10
        TapePtr=TapePtr+1
    ELSE
        ADel(Tape,1)
    END IF
    Tape[TapePtr]=Right(Space(13)+Left(AllTrim(Ch),13),13)
    SetColor(Invert)
    poz=CX-1
    i=TapePtr
    DO WHILE  poz>=0 .AND. i>=1
        @ poz,CY+1 SAY " "+Tape[i]+" "
        i=i-1
        poz=poz-1
    END DO
    SetColor(Normal)
END IF
RETURN

