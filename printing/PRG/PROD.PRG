#include "sixcdx2.ch"
#include "machsix.ch"
#include "inkey.ch"
#include "box.ch"
#include "fileio.ch"
#include "commands.ch"

#define TCK_LIMIT     450000

FUNCTION xProd1()

LOCAL cOldScreen := "", ;
      nOldSel	 := Select(), ;
      kraj	 := .F., ;
      cTemp	 := ""

PRIVATE aMyGet := {}, ;
	t_serija := Space(25), ;
	t_status := "N", ;
	t_check  := Space(1), ;
	s1	 := 0, ;
	s2	 := 0, ;
	nStep	 := 0, ;
	rUkup	 := 0, ;
	lRazIzBaz := .F., ;
	nHandle  := 0, ;
	nUkProd   := 0, ;
	nUkNeProd := 0, ;
	l16	  := .F.

	IF !lKolo
	   err_beep()
	   al_box("Nije izabrano ni jedno kolo!",1,{" OK "},1,9,20,15,60)
	   RETURN NIL
	ENDIF

	SET KEY K_F5 TO GStep()
	SET KEY K_F6 TO ResStep()
	SET KEY K_F7 TO GetUkup()
	SET KEY K_F8 TO Chg16()

	TBof = .F.
	TEof = .F.

	IF Kolo->ukupno > TCK_LIMIT
	   alert("SIXCDX ERROR: 2033", {" OK "})
	   CLS
	   QUIT
	ENDIF

	USE Prod NEW VIA "SIXCDX"
	GO TOP

/*
	IF !NetUse("prod")
	   RETURN NIL
	ELSE
	   GO TOP
	ENDIF
*/

	vstk_push()
	cOldScreen = win_save(0,0,24,79)

	SetFuter({"F5 - STEP","F6 - RESET STEP","F7 - UKUPNO","ESC - IZLAZ"})

	WinStyle(7,18,15,54,"RAZDUZIVANJE LISTICA")

	Maska()

	ResStep()

	DO WHILE .T.

	   SetCursor(1)
	   READ
	   SetCursor(0)

	   IF LastKey() = 27
	      EXIT
	   ENDIF

	   nalch = al_box("Menjate status listica sa serijom od " + FMT0L(Str(s1),6) + " do " + FMT0L(Str(s2),6) + " u " + iif(t_status="P","PRODAT","NEPRODAT"),2, {" DA "," PREKID "}, 2, 9, 20, 16, 60)

	   IF nalch = 1

	      IF SmartRaz(s1, s2, t_status)

		 Prod->(dbAppend())

		 REPLACE Prod->od WITH s1, ;
			 Prod->do WITH s2

		 IF t_status = "N"
		    rUkup += (s2-s1)+1
		 ENDIF

		 vstk_push()
		 SetColor("r/bg")
		 @ 11,20 SAY "Pret: " + FMT0L(Str(s1,7),7) + " - " + FMT0L(Str(s2,7),7) + " = " + Str((s2-s1)+1,7)
		 @ 12,20 SAY "Ukupno neprodatih       = " + Str(rUkup,7)
		 vstk_pop()

		 * dbUnLock()

	      ENDIF

	      done_beep()

	   ENDIF

	   t_check  := Space(1)

	   IF l16
	      t_serija = padr(AllTrim(Str(s1 + 16)), 20, " ")
	   ENDIF

	   s1 := 0
	   s2 := 0
	   t_status := "N"

	   GetList = aMyGet

	ENDDO

	win_rest(cOldScreen)
	vstk_pop()

	IF al_box("Kraj razduzivanja?",2,{" DA "," NE "},2,9,25,15,55) = 1

	   kraj = .T.

	   GetCodLis(Kolo->pocser, Kolo->ukupno)

	   nHandle = FOpen("cnlist.dat", FO_WRITE + FO_SHARED)

	   Prod->(dbGoTop())

	   nUkNeProd = 0

	   DO WHILE !Prod->(Eof())

	      s1 = Prod->od
	      s2 = Prod->do
	      nUkNeProd += (s2-s1) + 1
	      t_status = "N"
	      Razduz(.F.)
	      Prod->(dbSkip())

	   ENDDO

	   nUkProd = TLastRec() - nUkNeProd

	   PutBrLis()

	   FClose(nHandle)

	   FileCopy("cnlist.dat", cMainDir + "\izv\cnlist.dat")

	ENDIF

	CLOSE Prod
	Select(nOldSel)

* mozda ovo treba ispred close
* najveca greska od kada radim
/*
	IF !kraj
	   FClose(nHandle)
	ENDIF
*/

	IF alert("Obrisati NAGSER.DBF?", {" DA ", " NE "}) == 1

	dbCreate("nagser.dbf", {;
			       {"kolo",     "N",   4,   0}, ;
			       {"serija",   "N",   8,   0}, ;
			       {"nagrada",  "N",   2,   0}, ;
			       {"code",     "N",   1,   0}  ;
			       })

	cTemp = cMainDir + "\izv\nagser.dbf"
	COPY FILE nagser.dbf TO &(cTemp)

	ENDIF

	SET KEY K_F5 TO
	SET KEY K_F6 TO
	SET KEY K_F7 TO
	SET KEY K_F8 TO

RETURN NIL

STATIC FUNCTION Maska()

       @  9,20 SAY "Serija:"      GET t_serija PICTURE "@!@K XXXXXXXXXXXXXXXXXXXXXXXXX" VALID ParseSer(t_serija)
       @ 14,20 SAY "status     :" GET t_status PICTURE "@!X" VALID t_status $ "P_N_"
       @ 14,45 SAY "Step:"

       aMyGet = GetList

RETURN NIL

STATIC FUNCTION ParseSer(cSer)

LOCAL RetVal := .T., ;
      oGet   := GetActive(), ;
      nStop  := 0, ;
      p      := 0, ;
      nalch  := 0, ;
      lLine := .F.

      IF Empty(cSer)
	 RETURN .F.
      ENDIF

      s1 = 0
      s2 = 0

      cSer = DelAllBL(cSer)

      IF IsDigit(cSer)

	 s1 = Val(cSer)

      ELSE

	 IF Left(cSer,1) = "-"

	    s1 = 1
	    IF IsDigit( SubStr(cSer,at("-",cSer)+1,1) )
	       s2 = Val(SubStr(cSer,at("-",cSer)+1))
	    ELSE
	       s2 = Kolo->ukupno
	    ENDIF

	 ELSE

	    err_beep()
	    al_box("Neispravna sintaksa! (dozvoljeno je: ser.br., ser.br.-, ser.br.-ser.br.)",1,{" OK "},1,9,20,16,60)
	    oGet:buffer = Space(Len(oGet:buffer))
	    oGet:Assign()
	    oGet:Display()
	    RetVal = .F.

	 ENDIF

      ENDIF

      IF RetVal

	 IF at("-",cSer) != 0

	    IF IsDigit( SubStr(cSer,at("-",cSer)+1,1) )
	       s2 = Val(SubStr(cSer,at("-",cSer)+1))
	    ELSE
	       s2 = Kolo->ukupno
	    ENDIF

	 ELSE

	    IF nStep > 0
	       s2 = s1 + (nStep-1)
	    ENDIF
/*
	    IF at("#",cSer) != 0
	       IF IsDigit(SubStr(cSer,at("#",cSer)+1))
		  s2 = s1 + (Val(SubStr(cSer,at("#",cSer)+1))-1)
	       ENDIF
	    ENDIF
*/

	 ENDIF

	 IF s2 = 0

	    IF s1 != 0
	       s2 = s1
	    ENDIF

	 ELSEIF s1 != 0 .and. s2 != 0

	    IF s1 > s2
	       err_beep()
	       al_box("Prva serija veca od druge!",1,{" OK "},1)
	       RetVal = .F.
	    ENDIF

	 ENDIF

      ENDIF

RETURN RetVal

STATIC FUNCTION DelAllBL(cStr)

LOCAL i     := 0, ;
      cStr1 := "",;
      cChar := ""

      cStr = AllTrim(cStr)

      FOR i = 1 TO Len(cStr)
	  cChar = SubStr(cStr,i,1)
	  IF cChar != " "
	     cStr1 += cChar
	  ENDIF
      NEXT

RETURN cStr1

STATIC FUNCTION Razduz(opc)

LOCAL t_s1  := s1, ;
      cBuff := Space(12), ;
      nBr   := 0

      DEFAULT opc TO .T.

      FSeek( nHandle, 23 + ((s1 - 1) * 12) )

      msg_start(9,25,15,55)

      IF t_status = "N"

	 DO WHILE t_s1 <= s2

	    msg(Str(t_s1,8))

	    FWrite(nHandle, Chr(255) + Replicate(Chr(0),11), 12)

	    ++t_s1

	 ENDDO

      ELSEIF t_status = "P"

	 Listic->(TGoTo(s1))

	 DO WHILE TRecNo() <= s2

	    msg(Str(t_s1,8))

	    FWrite(nHandle, MakeCode(), 12)

	    TSkip()

	 ENDDO

      ENDIF

      msg_end()

      IF opc
	 done_beep()
      ENDIF

RETURN NIL

FUNCTION PregRaz()

LOCAL cOldScreen := "", ;
      columns	 := {}, ;
      nOldSel	 := Select(), ;
      nUkup	 := 0

      USE prod NEW VIA "SIXCDX"
      GO TOP

/*
      IF !NetUse("prod")
	 RETURN NIL
      ELSE
	 GO TOP
      ENDIF
*/

      DO WHILE !Eof()
	 nUkup += ((do-od)+1)
	 SKIP
      ENDDO

      GO TOP

      aadd(columns,{"RB",{|| Str(RecNo(),4)},Select(),""})
      aadd(columns,{"od","OD",Select(),""})
      aadd(columns,{"do","DO",Select(),""})
      aadd(columns,{"sum",{|| Str((do-od)+1,7) },Select(),""})

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(8,22,17,57,"BAZA RAZDUZENJA")

      vstk_push()
      SetColor("W+/B")
      @ 17,22 CLEAR TO 17,57
      @ 17,42 SAY "Ukupno: "
      @ 17,Col() SAY Str(nUkup,7) COLOR "gr+/b"
      vstk_pop()

      MyBrowse(9,22,16,57,columns,NIL,.T.,NIL,.T.)

      win_rest(cOldScreen)
      vstk_pop()

      CLOSE Prod
      Select(nOldSel)

RETURN NIL

FUNCTION StRaz()

LOCAL nUkup := 0, ;
      nOldSel := Select()

      IF al_box("Pregled razduzenja?",2,{" DA "," NE "},2) = 2
	 RETURN NIL
      ENDIF

      USE Prod NEW VIA "SIXCDX"
      GO TOP

/*
      IF !NetUse("prod")
	 RETURN NIL
      ELSE
	 GO TOP
      ENDIF
*/

      IniPtr()

      Prt1()
      Prt2()

      DO WHILE !Eof()

	 ? FMTBLL( Str(Prod->(Sx_KeyNo())), 5) + ". " + FMT0L(Str(od),7) + " - " + FMT0L(Str(do),7) + " = " + Str(do-od+1,7)

	 nUkup += (do-od)+1

	 SKIP

      ENDDO

      ?
      ? "Ukupno            : " + Str(nUkup,7)

      Prt3()

      CLOSE Prod
      Select(nOldSel)

RETURN NIL

FUNCTION MakeCode()

LOCAL cPatt	:= Replicate(Chr(0), 12), ;
      bajt_pos	:= 0, ;
      bit_pos	:= 0, ;
      nBroj	:= 0, ;
      pBroj	:= 0, ;
      nBrPat	:= 0, ;
      i 	:= 0

      FOR i = 1 TO 27
	  nBroj = Asc(SubStr(Listic->sadrzaj,i,1))
	  IF nBroj != 126
	     bajt_pos = Int(nBroj / 8) + 1
	     bit_pos = Int(nBroj % 8)
	     pBroj = 2 ** bit_pos
	     nBrPat = Asc(SubStr(cPatt,bajt_pos,1)) + pBroj
	     cPatt = Stuff(cPatt, bajt_pos, 1, Chr(nBrPat))
	  ENDIF
      NEXT

RETURN cPatt


FUNCTION GetBRLIS1()

LOCAL nOldPos := FSeek(nHandle,0,1), ;
      cBuff   := Space(4)

      FSeek(nHandle, 15)

      FRead(nHandle, @cBuff, 4)
      nUkProd = Bin2L(cBuff)
      FRead(nHandle, @cBuff, 4)
      nUkNeProd = Bin2L(cBuff)

      FSeek(nHandle, nOldPos)

RETURN NIL

FUNCTION PutBRLIS()

LOCAL nOldPos := FSeek(nHandle,0,1), ;
      cBuff   := Space(4)

      FSeek(nHandle, 15)

      FWrite(nHandle, L2Bin(nUkProd)  , 4)
      FWrite(nHandle, L2Bin(nUkNeProd), 4)

      FSeek(nOldPos)

RETURN NIL

* vraca status listica (.F. - neprodat, .T. - prodat)

FUNCTION GetStatLis(nBrLis)

LOCAL nOldPos := FSeek(nHandle,0,1), ;
      lRetVal := .F., ;
      cBuff   := Space(1)

      FSeek(nHandle, 23 + ((nBrLis - 1) * 12) )

      FRead(nHandle, @cBuff, 1)

      IF cBuff != Chr(255)
	 lRetVal = .T.
      ENDIF

      FSeek(nHandle, nOldPos)

RETURN lRetVal

FUNCTION SmartRaz(p1, p2, status)

LOCAL nOldRec := Prod->(RecNo()), ;
      n1      := 0, ;
      n2      := 0, ;
      lRetVal := .T., ;
      lPonovo := .F., ;
      pp1     := 0, ;
      pp2     := 0

      * RETURN .T.

      DO WHILE .T.

	 nChkRes = Chks1s2(p1, p2)

/*
	 IF nChkRes != 0
	    IF !Prod->(RLock())
	       err_beep()
	       IF al_box("Postoji konflikt ali je neko zakljucao slog. Sacekajte!",2,{" PONOVO "," PREKID "},1,9,20,16,60) = 2
		  RETURN .F.
	       ENDIF
	    ENDIF
	 ENDIF
*/

	 DO CASE

	    CASE nChkRes = 1

		 lRetVal = .F.

		 IF status = "P"

		    DO CASE

		       CASE p1 = Prod->od .AND. p2 = Prod->do
			    Prod->(dbDelete())

		       CASE p1 > Prod->od .AND. p2 < Prod->do
			    n1 = Prod->od
			    n2 = Prod->do
			    REPLACE Prod->do WITH (p1 - 1)
			    Prod->(dbAppend())
			    REPLACE Prod->od WITH (p2 + 1), ;
				    Prod->do WITH n2

		       CASE p1 = Prod->od .AND. p2 < Prod->do
			    REPLACE Prod->od WITH (p2 + 1)

		       CASE p1 > Prod->od .AND. p2 = Prod->do
			    REPLACE Prod->do WITH (p1 - 1)

		    ENDCASE

		 ELSE

		    err_beep()
		    al_box("U opsegu " + FMT0L(Str(p1),7) + " - " + FMT0L(Str(p2),7) + " vec ima razduzenih listica. Nadjeni slog ima opseg " + FMT0L(Str(Prod->od),7) + " - " + FMT0L(Str(Prod->do),7) + " i " + AllTrim(Str(Prod->(RecNo()))) + ". je po redu.", 1, {" OK "}, 1, 9, 15, 18, 65)
		    lRetVal = .F.
		    EXIT

		 ENDIF

	    CASE nChkRes = 2

		 lRetVal = .F.

		 IF status = "P"

		    DO CASE

		       CASE p1 = Prod->od .AND. p2 > Prod->do
			    n1 = Prod->od
			    n2 = Prod->do
			    Prod->(dbDelete())
			    p1 = n2 + 1

		       CASE p1 > Prod->od .AND. p1 < Prod->do .AND. p2 > Prod->do
			    n2 = Prod->do
			    REPLACE Prod->do WITH (p1 - 1)
			    p1 = n2 + 1

		       CASE p1 = Prod->do .AND. p2 > Prod->do
			    REPLACE Prod->do WITH (p1 - 1)

		    ENDCASE

		 ELSE

		    err_beep()
		    al_box("U opsegu " + FMT0L(Str(p1),7) + " - " + FMT0L(Str(p2),7) + " vec ima razduzenih listica. Nadjeni slog ima opseg " + FMT0L(Str(Prod->od),7) + " - " + FMT0L(Str(Prod->do),7) + " i " + AllTrim(Str(Prod->(RecNo()))) + ". je po redu.", 1, {" OK "}, 1, 9, 15, 18, 65)
		    lRetVal = .F.
		    EXIT

		 ENDIF

	    CASE nChkRes = 3

		 lRetVal = .F.

		 IF status = "P"

		    DO CASE

		       CASE p2 >= Prod->od .AND. p2 < Prod->do .AND. p1 < Prod->od
			    n1 = Prod->od
			    REPLACE Prod->od WITH (p2 + 1)
			    p2 = (n1 - 1)

		       CASE p2 = Prod->do .AND. p1 < Prod->od
			    n1 = Prod->od
			    Prod->(dbDelete())
			    p2 = (n1 - 1)

		    ENDCASE

		 ELSE

		    err_beep()
		    al_box("U opsegu " + FMT0L(Str(p1),7) + " - " + FMT0L(Str(p2),7) + " vec ima razduzenih listica. Nadjeni slog ima opseg " + FMT0L(Str(Prod->od),7) + " - " + FMT0L(Str(Prod->do),7) + " i " + AllTrim(Str(Prod->(RecNo()))) + ". je po redu.", 1, {" OK "}, 1, 9, 15, 18, 65)
		    lRetVal = .F.
		    EXIT

		 ENDIF

	    CASE nChkRes = 4

		 lRetVal = .F.

		 IF status = "P"

		    DO CASE

		       CASE p1 < Prod->od .AND. p2 > Prod->do
			    lPonovo = .T.
			    pp1 = Prod->do + 1
			    pp2 = p2
			    p2 = Prod->do

		    ENDCASE

		 ELSE

		    err_beep()
		    al_box("U opsegu " + FMT0L(Str(p1),7) + " - " + FMT0L(Str(p2),7) + " vec ima razduzenih listica. Nadjeni slog ima opseg " + FMT0L(Str(Prod->od),7) + " - " + FMT0L(Str(Prod->do),7) + " i " + AllTrim(Str(Prod->(RecNo()))) + ". je po redu.", 1, {" OK "}, 1, 9, 15, 18, 65)
		    lRetVal = .F.
		    EXIT

		 ENDIF

	    CASE nChkRes = 0

		 IF !lPonovo

		    IF t_status = "P"
		       lRetVal = .F.
		    ENDIF

		    EXIT

		 ELSE

		    lPonovo = .F.
		    p1 = pp1
		    p2 = pp2

		 ENDIF

	    OTHERWISE


	 ENDCASE

      ENDDO

      * dbUnLock()

RETURN lRetVal

FUNCTION Chks1s2(p1, p2)

LOCAL RetVal  := 0

      Prod->(dbGoTop())

      DO WHILE !Prod->(Eof())

	 * 10-20
	 * 10-20; 15-17; 10-13; 16-20

	 IF p1 >= Prod->od .AND. p2 <= Prod->do
	    RetVal = 1
	    EXIT
	 ENDIF

	 * 10-20
	 * 15-25; 20-25; 10-25

	 IF p1 >= Prod->od .AND. p1 <= Prod->do .AND. p2 > Prod->do
	    RetVal = 2
	    EXIT
	 ENDIF

	 IF p2 >= Prod->od .AND. p2 <= Prod->do .AND. p1 < Prod->od
	    RetVal = 3
	    EXIT
	 ENDIF

	 IF p1 < Prod->od .AND. p2 > Prod->do
	    RetVal = 4
	    EXIT
	 ENDIF

	 Prod->(dbSkip())

      ENDDO

RETURN RetVal

FUNCTION UzmiCod()

	 IF al_box("Get code?",2,{" DA "," NE "},2) = 2
	    RETURN NIL
	 ENDIF

	 GetCodLis(Kolo->pocser, Kolo->ukupno)

RETURN NIL

FUNCTION GStep()

LOCAL GetList := {}, ;
      nOldCur := 0

PRIVATE aa := nStep

      SET KEY K_F5 TO

      aadd( GetList, GetNew(14, 51, MemVarBlock("aa"),,"99") )

      nOldCur = SetCursor(1)
      ReadModal(GetList)
      SetCursor(nOldCur)

      nStep = aa

      done_beep()

      SET KEY K_F5 TO GStep()

RETURN NIL

FUNCTION ResStep()

      nStep = 0
      @ 14, 51 SAY " 0" COLOR "b/w"

      done_beep()

RETURN NIL

FUNCTION GetUkup()

LOCAL nRec  := Prod->(RecNo()), ;
      nUkup := 0

      SET KEY K_F7 TO

      Prod->(dbGoTop())

      DO WHILE !Prod->(Eof())

	 nUkup += ((Prod->do - Prod->od) + 1)

	 Prod->(dbSkip())

      ENDDO

      al_box("Ukupno " + AllTrim(Str(nUkup)) + " neprodatih listica.", 1, {" OK "}, 1, 9, 20, 16, 60)

      Prod->(dbGoTo(nRec))

      SET KEY K_F7 TO GetUkup()

RETURN NIL

FUNCTION BgFun()

LOCAL	 cMBpath    := AllTrim(MBname) + "listic.dbf", ;
	 nOldSel    := Select(), ;
	 bb	    := 0

PRIVATE t_status := "N", ;
	s1 := 0, ;
	nHandle    := 0, ;
	s2 := 0

      IF al_box("BG fun?", 2, {" DA ", " NE "},2,9,25,15,55) = 2
	 RETURN NIL
      ENDIF

      IF !NetUse(cMBpath, "MiRRoR")
	 RETURN NIL
      ENDIF

      TGoTop()

      IF !NetUse("prod")
	 RETURN NIL
      ELSE
	 GO TOP
      ENDIF

      GetCodLis(Kolo->pocser, Kolo->ukupno)

      nHandle = FOpen("cnlist.dat", FO_WRITE)

      t_status = "N"
      s1 = 1
      s2 = Kolo->ukupno
      Razduz(.F.)

      Prod->(dbGoTop())
      DO WHILE !Prod->(Eof())
	 t_status = "P"
	 s1 = Prod->od
	 s2 = Prod->do
	 Razduz(.F.)
	 Prod->(dbSkip())
      ENDDO

      FClose(nHandle)

      CLOSE Prod

      Sx_SetPass("")

      CLOSE Listic

      Select(nOldSel)
      dbGoTo(RecNo())

RETURN NIL

FUNCTION Chg16()

	 IF l16 = .F.
	    l16 = .T.
	 ELSE
	    l16 = .F.
	 ENDIF

RETURN NIL

FUNCTION Autom()

LOCAL GetList	 := {}, ;
      cOldScreen := "", ;
      prbr := 0, ;
      drbr := 0

      SET KEY K_F9 TO

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(9,25,15,55,"")

      @ 11,27 SAY "Prvi :" GET prbr PICTURE "9999999"
      @ 12,27 SAY "Drugi:" GET drbr PICTURE "9999999"

      SetCursor(1)
      READ
      SetCursor(0)

      win_rest(cOldScreen)
      vstk_pop()

      IF LastKey() != 27

	 DO WHILE prbr <= drbr

	    Prod->(dbAppend())
	    REPLACE Prod->od WITH prbr, ;
		    Prod->do WITH prbr + 1

	    prbr += 16

	 ENDDO

      ENDIF

      SET KEY K_F9 TO Autom()

RETURN NIL

