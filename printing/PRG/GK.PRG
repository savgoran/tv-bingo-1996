#include "sixcdx2.ch"
#include "machsix.ch"
#include "inkey.ch"
#include "box.ch"
#include "commands.ch"

FUNCTION GenKom()

LOCAL nCurrList := 1, ctt := 0

PRIVATE nBrList  := 0, ;		 && broj listova * 12 = broj kombinacija
	nBrKomb  := 0, ;
	nPocSer  := 1, ;
	cKolo	 := Space(7), ;
	lDodatak := .F.

	USE Maska NEW VIA "SIXCDX"

	USE Listic VIA "SIXCDX" PASSWORD "[REDACTED]" NEW
	SET TAG TO komb
	GO TOP

	BEGIN SEQUENCE

	IF Bof() .AND. Eof()
	ELSE
	    err_beep()
	    IF al_box("U bazi ima " + FMT0L(Str(LastRec()),7) + " kombinacija. Zelite li da generisete jos?",2,{" DA "," NE "},2,9,20,16,60) = 1
	       SET TAG TO SERIJA
	       GO TOP
               GO BOTTOM
	       nPocSer = serija + 1
	       cKolo = kolo
	       lDodatak = .T.
	       SET TAG TO KOMB
	       GO TOP
	    ELSE
	       BREAK
	    ENDIF
        ENDIF

	IF !GenKomOpc()
	   BREAK
	ENDIF

	IF lDodatak
	   IF al_box("Dodajete jos " + FMT0L(Str(nBrList),7) + " listova?",2,{" DA "," NE "},2,9,20,15,60) = 2
	      BREAK
	   ENDIF
	ELSE
	   IF al_box("Generisete " + FMT0L(Str(nBrList),7) + " listova?",2,{" DA "," NE "},2,9,20,15,60) = 2
	      BREAK
	   ENDIF
	ENDIF

	nBrKomb = nBrList * 12

	msg_start(9,20,16,60)

	cTime = TimeToSec()

	DO WHILE nCurrList <= nBrList

	   msg("Generise se " + FMT0L(Str(nCurrList),7) + " od " + FMT0L(Str(nBrList),7))

	   MakeOnePage()

	   ++ctt
	   IF ctt > 80
	      ctt = 0
	      Listic->(dbCommit())
	   ENDIF

	   ++nCurrList

	ENDDO

	msg_end()

	ceTime = SecToTime(TimeToSec() - cTime)

	al_box("Vreme: " + ceTime,1,{" OK "},1)

	END SEQUENCE

	CLOSE ALL

RETURN NIL

STATIC FUNCTION GenKomOpc()

LOCAL cOLdScreen := "", ;
      RetVal	 := .T.

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(8,17,17,64,"BROJ KOMBINACIJA")

      vstk_push()
      SetColor("n+/bg")
      @ 14,19 SAY "napomena:                                   "
      @ 15,19 SAY "na jednom listu ima 12 listica za tombolu   "
      @ 16,19 SAY "(npr. 100 listova = 1200 listica za tombolu)"
      vstk_pop()

      @ 10,19 SAY "Unesi broj listova:" GET nBrList PICTURE "9999999" VALID nBrList != 0
      @ 12,19 SAY "Pocetna serija    :" GET nPocSer PICTURE "9999999" WHEN !lDodatak VALID nPocSer != 0
      @ 12,50 SAY "Kolo:" GET cKolo PICTURE "@!XXXXXXX" WHEN !lDodatak VALID !Empty(cKolo)

      SetCursor(1)
      READ
      SetCursor(0)

      IF LastKey() == K_ESC
	 RetVal = .F.
      ENDIF

      win_rest(cOldScreen)
      vstk_pop()

RETURN RetVal

* izbor 36 maski iz baze MASKA

STATIC FUNCTION MakeOnePage()

LOCAL nCurrComb := 1, ;
      cComb	:= ""

PUBLIC aBrPoKol := {}, ;
	aMask	 := {}

      ChoiceMask()

      DO WHILE nCurrComb < 13

	 cComb = MakeOneKomb(nCurrComb)

	 Listic->(dbSeek(mmm(cComb)))

	 IF !Listic->(Found())

	    Listic->(dbAppend())
	    REPLACE Listic->sadrzaj WITH cComb	, ;
		    Listic->serija  WITH nPocSer, ;
		    Listic->kolo    WITH cKolo,   ;
		    Listic->status  WITH "N"

	    ++nPocSer
	    ++nCurrComb

	 ENDIF

      ENDDO

RETURN NIL

STATIC FUNCTION MakeOneKomb(nCurrComb)

LOCAL nCurrBr  := 0, ;
      nUkupIn1 := 0, ;
      nMagic   := 0, ;
      nCurrCol := 1, ;
      nCurrRow := 1, ;
      nUkupBr  := 0, ;
      aTemp    := {}, ;
      i        := 0, ;
      nOffset  := 0

PUBLIC	aBrRet := {}, ;
	aBrIn1 := {}

      IF nCurrComb = 1
	 nOffset = 1
      ELSE
	 nOffset = ((nCurrComb-1) * 3) + 1
      ENDIF

      DO WHILE nCurrCol < 10

	 DO CASE
	    CASE nCurrCol = 1
		 Generator(9,1,aBrPoKol[nCurrComb,1])
	    CASE nCurrCol = 2
		 Generator(10,10,aBrPoKol[nCurrComb,2])
	    CASE nCurrCol = 3
		 Generator(10,20,aBrPoKol[nCurrComb,3])
	    CASE nCurrCol = 4
		 Generator(10,30,aBrPoKol[nCurrComb,4])
	    CASE nCurrCol = 5
		 Generator(10,40,aBrPoKol[nCurrComb,5])
	    CASE nCurrCol = 6
		 Generator(10,50,aBrPoKol[nCurrComb,6])
	    CASE nCurrCol = 7
		 Generator(10,60,aBrPoKol[nCurrComb,7])
	    CASE nCurrCol = 8
		 Generator(10,70,aBrPoKol[nCurrComb,8])
	    CASE nCurrCol = 9
		 Generator(11,80,aBrPoKol[nCurrComb,9])
	 ENDCASE

	 * nUkupBr += aBrPoKol[nCurrComb, nCurrCol]
	 ++nCurrCol

      ENDDO

RETURN KombWithMask(aSort(aBrIn1), nOffset)

STATIC FUNCTION KombWithMask(aNiz, nOffset)

LOCAL cRet := "", ;
      i    := 0, ;
      st1row := aMask[nOffset], ;
      st2row := aMask[nOffset + 1], ;
      st3row := aMask[nOffset + 2], ;
      curr_br := 1

      FOR i = 9 TO 1 STEP -1

	  IF IsBit(st1row,i)
	      cRet += FMT0L(Str(aNiz[curr_br]),2)
	      ++curr_br
	  ELSE
	      cRet += "00"
	  ENDIF

	  IF IsBit(st2row,i)
	      cRet += FMT0L(Str(aNiz[curr_br]),2)
	      ++curr_br
	  ELSE
	      cRet += "00"
	  ENDIF

	  IF IsBit(st3row,i)
	      cRet += FMT0L(Str(aNiz[curr_br]),2)
	      ++curr_br
	  ELSE
	      cRet += "00"
	  ENDIF

      NEXT

RETURN cRet

STATIC FUNCTION Generator(max,min,nUkup)

LOCAL nSlBroj := 0, ;
      nUkupGen := 0

      DO WHILE nUkupGen < nUkup

	 * Rand(100001)

	 nSlBroj = Int(Random() % max) + min

	 IF Len(aBrIn1) > 0
	    IF AScan(aBrIn1, nSlBroj) = 0
	       aadd(aBrIn1, nSlBroj)
	       ++nUkupGen
	    ELSE
	       LOOP
	    ENDIF
	 ELSE
	    aadd(aBrIn1, nSlBroj)
	    ++nUkupGen
	 ENDIF

      ENDDO

RETURN

STATIC FUNCTION ChoiceMask()

LOCAL i     := 0, ;
      nBroj := 0, ;
      nUkup := 0, ;
      spbr  := 0

      aMask := {}

      DO WHILE nUkup < 36
	  ++spbr
	  IF spbr > 10
	     spbr = 0
	     nBroj = Int(Random() % 14) + 46
	  ELSE
	     nBroj = Int(Random() % 45) + 1
	  ENDIF
	  Maska->(dbGoTo(nBroj))
	  nBroj = Maska->broj
	  IF Len(aMask) > 0
	     IF AScan(aMask, nBroj) = 0
		Aadd(aMask, nBroj)
		++nUkup
	     ENDIF
	  ELSE
	     Aadd(aMask, nBroj)
	     ++nUkup
	  ENDIF
      ENDDO

      CntPoCol()

RETURN NIL

STATIC FUNCTION CntPoCol()

LOCAL curr_cmb	:= 1, ;
      curr_mask := 0, ;
      curr_lst	:= 1, ;
      nTemp	:= 0, ;
      ccc	:= 9, ;
      i 	:= 0

      aBrPoKol := {}

      FOR i = 1 TO 12
	  aadd(aBrPoKol,{0,0,0,0,0,0,0,0,0})
      NEXT

      DO WHILE curr_lst <= 12

	 nTemp := 0

	 FOR i = 1 TO 9

	     IF IsBit(aMask[curr_cmb], i)
		++nTemp
	     ENDIF

	     IF IsBit(aMask[curr_cmb+1], i)
		++nTemp
	     ENDIF

	     IF IsBit(aMask[curr_cmb+2], i)
		++nTemp
	     ENDIF

	     aBrPoKol[curr_lst, ccc] = nTemp
	     --ccc
	     nTemp = 0

	 NEXT

	 ccc = 9
	 curr_cmb += 3
	 ++curr_lst

      ENDDO

RETURN NIL

FUNCTION PregKomb()

LOCAL cOldScreen := "", ;
      cOldScr1	 := "", ;
      nod := 0, ;
      ndo := 0

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      BEGIN SEQUENCE

      vstk_push()
      cOldScr1 = win_save(0,0,24,79)

      WinStyle(9,20,14,60,"PREGLED LISTICA?")

      @ 11,22 SAY "serija od " GET nod PICTURE "999999" VALID nod > 0
      @ 12,22 SAY "serija do " GET ndo PICTURE "999999"

      SetCursor(1)
      READ
      SetCursor(0)

      IF LastKey() = K_ESC
	 win_rest(cOldScr1)
	 vstk_pop()
	 BREAK
      ENDIF

      IF ndo = 0
	 ndo = nod
      ENDIF

      win_rest(cOldScr1)
      vstk_pop()

      USE LISTIC NEW VIA "SIXCDX" PASSWORD "[REDACTED]"
      SET TAG TO SERIJA
      GO TOP

      IniPtr()
      Prt1()
      Prt2()

      SEEK nod
      DO WHILE serija <= ndo .AND. !Eof()

	 ? "Serija: " + FMT0L(str(serija),7) + Space(3) + iif(status="P","PRODAT","NEPRODAT") + Space(3) + "Kolo: " + Listic->kolo

	 ?

	 for i = 1 to 54 step 6
	     nn = substr(sadrzaj,i,2)
	     ?? iif(nn="00","--",nn) + "  "
	 next

	 ?

	 for i = 3 to 54 step 6
	     nn = substr(sadrzaj,i,2)
	     ?? iif(nn="00","--",nn) + "  "
	 next

	 ?

	 for i = 5 to 54 step 6
	     nn = substr(sadrzaj,i,2)
	     ?? iif(nn="00","--",nn) + "  "
	 next

	 ?

	 SKIP

      ENDDO

      Prt3()

      CLOSE ALL

      END SEQUENCE

      win_rest(cOldScreen)
      vstk_pop()

RETURN NIL

FUNCTION FinPreg()

LOCAL brojac := 0, ;
      br_prod := 0, ;
      br_nep  := 0, ;
      cKolo   := ""

      IF al_box("Pregled neprodatih listica?",2,{" DA "," NE "},2,9,20,15,60) = 2
	 RETURN
      ENDIF

      USE LISTIC NEW VIA "SIXCDX" PASSWORD "[REDACTED]"
      SET TAG TO SERIJA
      GO TOP

      cKolo = AllTrim(Listic->kolo)

      IniPtr()
      Prt1()
      Prt2()

      ? padc("SPISAK NEPRODATIH LISTICA ZA KOLO " + cKolo,80,' ')
      ?
      ?

      DO WHILE !Eof()

	 IF status != "P"

	    ++br_nep

	    IF brojac > 8
	       brojac = 0
	       ?  FMT0L(Str(serija),7) + "  "
	    ELSE
	       ?? FMT0L(Str(serija),7) + "  "
	    ENDIF

	    ++brojac

	 ELSE
	    ++br_prod
	 ENDIF

	 SKIP

      ENDDO

      ?
      ?
      ? "Ukupno prodatih     : " + FMT0L(Str(br_prod),7)
      ? "Ukupno neprodatih   : " + FMT0L(Str(br_nep),7)
      ? "Ukupno odstampanih  : " + FMT0L(Str(br_nep+br_prod),7)

      Prt3()

      CLOSE ALL

RETURN NIL

FUNCTION BrisPod()

LOCAL cOldScreen := "", ;
      cOldScr1	 := "", ;
      nod := 0, ;
      ndo := 0

      IF !servis
	 err_beep()
	 al_box("Dozvoljeno samo autoru!",1,{" OK "},1,9,20,15,60)
	 CLOSE ALL
	 RETURN NIL
      ENDIF

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      BEGIN SEQUENCE

      vstk_push()
      cOldScr1 = win_save(0,0,24,79)

      WinStyle(9,20,14,60,"BRISANJE LISTICA?")

      @ 11,22 SAY "serija od " GET nod PICTURE "999999" VALID nod > 0
      @ 12,22 SAY "serija do " GET ndo PICTURE "999999"

      SetCursor(1)
      READ
      SetCursor(0)

      IF LastKey() = K_ESC
	 win_rest(cOldScr1)
	 vstk_pop()
	 BREAK
      ENDIF

      IF al_box("Brisete serije od " + FMT0L(Str(nod),7) + " do " + FMT0L(Str(ndo),7) + "?",2,{" DA "," NE "},2,9,20,16,60) = 2
	 win_rest(cOldScr1)
	 vstk_pop()
	 BREAK
      ENDIF

      IF ndo = 0
	 ndo = nod
      ENDIF

      win_rest(cOldScr1)
      vstk_pop()

      USE LISTIC NEW VIA "SIXCDX" PASSWORD "[REDACTED]"
      SET TAG TO SERIJA
      GO TOP

      msg_start(9,25,15,55)

      SEEK nod
      DO WHILE serija <= ndo .AND. !Eof()

	 msg(FMT0L(Str(serija),7))

	 DELETE

	 SKIP

      ENDDO

      msg("packing...")

      PACK

      msg_end()

      CLOSE ALL

      END SEQUENCE

      win_rest(cOldScreen)
      vstk_pop()

RETURN NIL
