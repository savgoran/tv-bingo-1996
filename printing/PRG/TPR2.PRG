#include "sixcdx2.ch"
#include "machsix.ch"
#include "inkey.ch"
#include "box.ch"
#include "commands.ch"

/*

#define POC_TAB_X     251
#define POC_TAB_Y     326

#define POC_SER_X     41
#define POC_SER_Y     452

#define POC_KOL_X     41
#define POC_KOL_Y     335

#define HOR_DIST      1171
#define VER_DIST      567

*/

#define POC_TAB_X     241
#define POC_TAB_Y     315

#define POC_SER_X     31
#define POC_SER_Y     441

#define POC_KOL_X     31
#define POC_KOL_Y     324

#define HOR_DIST      1171
#define VER_DIST      567

#define PCL_V_POS(x,y)              Chr(27) + Chr(42) + Chr(112) + alltrim(Str(x)) + "x" + alltrim(str(y)) + Chr(89)
#define PCL_HMI(x)		    Chr(27) + Chr(38) + Chr(107) + alltrim(Str(x,10,2)) + Chr(72)
#define PCL_SET_FONT(x) 	    Chr(27) + Chr(40) + alltrim(Str(x)) + Chr(88)
#define PCL_EJECT		    Chr(12)
#define PCL_UND_DIS		    Chr(27) + Chr(38) + Chr(100) + Chr(64)

#define SEND_HEADER		    SendFile("heder.prn")
#define SEND_END		    SendFile("end.prn")

FUNCTION tombprint()

LOCAL cOldScreen := "", ;
      curr_page  := 1, ;
      tt_page	 := 0


PRIVATE t_od := 0, ;
	t_do := 0, ;
	cSendBuff := "", ;
	nUkupLis  := 0, ;
	nCurrUkup := 0, ;
	nPage	  := 0

      SET SOFTSEEK ON

      USE Stampa NEW VIA "SIXCDX"
      GO TOP

      USE Listic NEW VIA "SIXCDX" PASSWORD "[REDACTED]"
      SET TAG TO SERIJA
      GO TOP

      nUkupLis = LastRec()

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      BEGIN SEQUENCE

      PrSt()

      IF !tprnopc()
	 BREAK
      ENDIF

      IF al_box("Stampate serije od " + FMT0L(Str(t_od),6) + " do " + FMT0L(Str(t_do),6) + "?", 2, {" DA "," NE "},2,9,20,16,60) = 2
	 BREAK
      ENDIF

      DO WHILE !IsPrinter()
	 err_beep()
	 IF al_box("Stampac nije u redu!",2,{" PONOVI "," PREKID "},1,9,20,15,60) = 2
	    BREAK
	 ENDIF
      ENDDO

      SEEK t_od
      IF Listic->(Eof()) .OR. Listic->serija > t_do
	 err_beep()
	 al_box("Nema listica za unetu seriju!",1,{" OK "},1,9,20,15,60)
	 BREAK
      ENDIF

      err_beep()
      IF al_box("Da pocnem?",2,{" DA "," NE "},2) = 2
	 BREAK
      ENDIF

      msg_start(9,20,15,60)
      msg("stampanje u toku...")

      SET DEVICE TO PRINT
      SET PRINTER ON
      SET CONSOLE OFF

      SEND_HEADER

      s2p(PCL_UND_DIS)

      DO WHILE .T.

	 SendPage()
/*
	 IF LastKey() != 0
	    err_beep()
	    SET CONSOLE ON
	    SET DEVICE TO SCREEN
	    IF al_box("Prekid stampe!",2,{" DA "," NE "},2) = 1
	       SEND_END
	       SET DEVICE TO SCREEN
	       msg_end()
	       BREAK
	    ENDIF
	    SET DEVICE TO PRINT
	    SET CONSOLE OFF
	 ENDIF
*/
	 IF Listic->serija > t_do .OR. Listic->(Eof())
	    EXIT
	 ENDIF

      ENDDO

      SEND_END

      SET DEVICE TO SCREEN
      SET CONSOLE ON
      SET PRINTER OFF

      msg_end()

      Listic->(dbSkip(-1))

      Stampa->(dbAppend())
      REPLACE Stampa->odstr WITH t_od, ;
	      Stampa->dostr WITH Listic->serija
                 
      END SEQUENCE

      win_rest(cOldScreen)
      vstk_pop()

      CLOSE ALL

      SET SOFTSEEK OFF

RETURN NIL

FUNCTION tprnopc()

LOCAL cOldScreen := "", ;
      RetVal	 := .T.

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(8,24,12,56,"Stampanje listica za tombolu")

      @ 10,26 SAY "od serije :" GET t_od PICTURE "999999" VALID ChkBrSer(t_od)
      @ 11,26 SAY "do serije :" GET t_do PICTURE "999999"

      SetCursor(1)
      READ
      SetCursor(0)

      IF LastKey() = 27
	 RetVal = .F.
      ENDIF

      IF Empty(t_do) .AND. !Empty(t_od)
	 t_do = t_od
      ENDIF

      IF t_od > nUkupLis .OR. t_do > nUkupLis
	 err_beep()
	 al_box("Ima samo " + Str(nUkupLis,6) + " listova!",1,{" OK "},1,9,20,16,60)
	 RetVal = .F.
      ENDIF

      win_rest(cOldScreen)
      vstk_pop()

RETURN RetVal

STATIC FUNCTION SendFile(cFile)

LOCAL nHandle := 0, ;
      buffer  := Space(250), ;
      i       := 0, ;
      mm, ;
      kraj    := .T.

      nHandle = FOpen(cFile)

      IF nHandle = -1
	 RETURN .F.
      ENDIF

      DO WHILE kraj

	 mm = FRead(nHandle, @buffer, 250)
	 IF mm < 250
	    kraj = .F.
	 ENDIF

	 FOR i = 1 TO mm
	     s2p(SubStr(buffer,i,1))
	 NEXT

      ENDDO

      FClose(nHandle)

RETURN .T.

STATIC FUNCTION SendPage()

PRIVATE curr_ticket := 1

	DO WHILE curr_ticket < 13

	   SendTicket(curr_ticket)

	   Listic->(dbSkip())

	   IF Listic->(Eof())
	      EXIT
	   ENDIF

	   ++curr_ticket

	ENDDO

	s2p(PCL_EJECT)

RETURN NIL

STATIC FUNCTION SendTicket(ticket)

LOCAL x_off := 0, ;
      y_off := 0, ;
      x_off_ser := 0, ;
      y_off_ser := 0, ;
      x_off_kol := 0, ;
      y_off_kol := 0, ;
      i 	:= 0, ;
      p1, p2

PRIVATE aList := {}

      --ticket

      x_off = iif(ticket < 6, POC_TAB_X, POC_TAB_X + HOR_DIST)
      y_off = POC_TAB_Y + ( iif(ticket>5,ticket-6,ticket) * VER_DIST )

      p1 = x_off

      x_off_ser = iif(ticket < 6, POC_SER_X, POC_SER_X + HOR_DIST)
      y_off_ser = POC_SER_Y + ( iif(ticket>5,ticket-6,ticket) * VER_DIST )

      x_off_kol = iif(ticket < 6, POC_KOL_X, POC_KOL_X + HOR_DIST)
      y_off_kol = POC_KOL_Y + ( iif(ticket>5,ticket-6,ticket) * VER_DIST )

      * kolo
      s2p(PCL_SET_FONT(2))
      s2p(PCL_HMI(3.60))
      s2p(PCL_V_POS(x_off_kol, y_off_kol) + AllTrim(Listic->kolo))

      * serija
      s2p(PCL_SET_FONT(4))
      s2p(PCL_HMI(5.20))
      s2p(PCL_V_POS(x_off_ser, y_off_ser) + FMT0L(Str(Listic->serija),6))

      UzmiBr()

      * serija
      s2p(PCL_SET_FONT(3))

      FOR i = 1 TO 9

	  IF aList[i] = "00"
	     aList[i] = ""
	  ELSEIF Left(aList[i],1) = "0"
	     aList[i] = Right(aList[i],1)
	  ENDIF


	  IF aList[i] != ""
	     s2p(PCL_HMI(6.00))
	     s2p(PCL_V_POS(x_off,y_off) + aList[i])
	  ENDIF

	  IF i = 1
	     x_off += 86
	  ELSE
	     x_off += 102
	  ENDIF

      NEXT

      x_off = p1
      y_off += 106

      FOR i = 10 TO 18

	  IF aList[i] = "00"
	     aList[i] = ""
	  ELSEIF Left(aList[i],1) = "0"
	     aList[i] = Right(aList[i],1)
	  ENDIF


	  IF aList[i] != ""
	     s2p(PCL_HMI(6.00))
	     s2p(PCL_V_POS(x_off,y_off) + aList[i])
	  ENDIF

	  IF i = 10
	     x_off += 86
	  ELSE
	     x_off += 102
	  ENDIF

      NEXT

      x_off = p1
      y_off += 106

      FOR i = 19 TO 27

	  IF aList[i] = "00"
	     aList[i] = ""
	  ELSEIF Left(aList[i],1) = "0"
	     aList[i] = Right(aList[i],1)
	  ENDIF


	  IF aList[i] != ""
	     s2p(PCL_HMI(6.00))
	     s2p(PCL_V_POS(x_off,y_off) + aList[i])
	  ENDIF

	  IF i = 19
	     x_off += 86
	  ELSE
	     x_off += 102
	  ENDIF

      NEXT

RETURN NIL

STATIC FUNCTION UzmiBr()

LOCAL i := 0

       FOR i = 1 TO 54 STEP 6
	   aadd(aList, SubStr(Listic->sadrzaj,i,2))
       NEXT

       FOR i = 3 TO 54 STEP 6
	   aadd(aList, SubStr(Listic->sadrzaj,i,2))
       NEXT

       FOR i = 5 TO 54 STEP 6
	   aadd(aList, SubStr(Listic->sadrzaj,i,2))
       NEXT

RETURN NIL

STATIC FUNCTION S2P(cStr)

local i := 0

       cSendBuff += cStr

       IF PrintReady(1)

	  FOR i = 1 TO Len(cSendBuff)
	      DO WHILE !PrintReady(1)
	      ENDDO
	      PrintSend(SubStr(cSendBuff,i,1))
	  NEXT

	  cSendBuff := ""

       ELSE

	  IF Len(cSendBuff) > 1024
	     FOR i = 1 TO Len(cSendBuff)
		 DO WHILE !PrintReady(1)
		 ENDDO
		 PrintSend(SubStr(cSendBuff,i,1))
	     NEXT
	     cSendBuff := ""
	  ENDIF

       ENDIF

RETURN NIL

FUNCTION PrSt()

LOCAL red := 5, i

	 WinStyle(3,59,23,79,"STAMPA")

	 Stampa->(dbGoBottom())
	 Stampa->(dbSkip(-17))

	 FOR i = red TO 22
	     IF !Stampa->(Eof())
		@ red,61 SAY FMT0L(Str(Stampa->odstr),7) + " - " + FMT0L(Str(Stampa->dostr),7)
		++red
		Stampa->(dbSkip())
	     ENDIF
	 NEXT

RETURN NIL

STATIC FUNCTION ChkBrSer(ttt)

LOCAL RetVal := .T., ;
      oGet   := GetActive()

      IF Empty(ttt)
	 RETURN .F.
      ENDIF

      --ttt

      IF Int(ttt/12) != ttt/12
	 err_beep()
	 IF al_box("Serija " + FMT0L(Str(ttt+1),7) + " ne ide na vrh strane!",2,{" TAKO HOCU "," GRESKA "},2,9,20,16,60) = 2
	    oGet:buffer = Space(Len(oGet:buffer))
	    oGet:Assign()
	    oGet:Display()
	    RetVal = .F.
	 ENDIF
      ENDIF

RETURN RetVal

FUNCTION TestPrinter()

	 IF !PrintReady(1)
	    DO WHILE !PrintReady(1); ENDDO

	 ENDIF



RETURN NIL
