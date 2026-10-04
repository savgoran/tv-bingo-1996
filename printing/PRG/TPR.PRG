#include "sixcdx2.ch"
#include "machsix.ch"
#include "inkey.ch"
#include "box.ch"
#include "commands.ch"

#define BR_KOMB       3
#define BR_KOMB536    2

#define PCL_RESET		    S2P("E")
#define PCL_INIT		    S2P("E(8U&l6d70P&l0E&l1X&l1H&lO&l0suZ*p0x75Y")
#define PCL_END 		    S2P("&lO(8U(sp10h12vsb3T&l6d3E&l1X")

#define PCL_LANDSCAPE		    Chr(27) + Chr(38) + Chr(108) + Chr(49) + Chr(79)
#define PCL_REVLANDS		    Chr(27) + Chr(38) + Chr(108) + Chr(51) + Chr(79)
#define PCL_A4			    Chr(27) + Chr(38) + Chr(108) + Chr(50) + Chr(54) + Chr(65)
#define PCL_LEGAL		    Chr(27) + Chr(38) + Chr(108) + Chr(51) + Chr(65)

#define PCL_V_POS(x,y)		    Chr(27) + Chr(42) + Chr(112) + alltrim(Str(x)) + "x" + alltrim(str(y)) + Chr(89)
#define PCL_HMI(x)		    Chr(27) + Chr(38) + Chr(107) + alltrim(Str(x,10,2)) + Chr(72)
#define PCL_SET_FONT(x) 	    Chr(27) + Chr(40) + alltrim(Str(x)) + Chr(88)
#define PCL_EJECT		    Chr(12)
#define PCL_UND_DIS		    Chr(27) + Chr(38) + Chr(100) + Chr(64)
#define PCL_SET_ID(x)		    Chr(27) + Chr(42) + Chr(99) + alltrim(Str(x)) + Chr(68)

#define SEND_HEADER		    SendFile(cMainDir+"\heder.prn")
#define SEND_END		    SendFile(cMainDir+"\end.prn")

FUNCTION tombprint()

LOCAL cOldScreen := "", ;
      curr_page  := 1,	;
      tt_page	 := 0,	;
      cMBpath	 := AllTrim(MBname) + "listic.dbf", ;
      cMBpath3	 := AllTrim(MB3name) + "listic5.dbf", ;
      cRimPath	 := cMainDir + "\rim.dbf", ;
      cFilePGSET := AllTrim(Group->path) + "\pgset.cfg", ;
      cOldSel	 := Select()

PRIVATE t_od := 0, ;
	t_do := 0, ;
	t_datum := CtoD("  /  /  "), ;
	cSendBuff := "", ;
	nUkupLis  := 0, ;
	nCurrUkup := 0, ;
	nPage	  := 0, ;
	aSpor	  := {}, ;
	nTekSN	  := 0

PRIVATE t_tab_x := 428, ;
	t_tab_y := 218, ;
	t_ser_x := 190, ;
	t_ser_y := 300, ;
	t_rbk_x := 177, ;
	t_rbk_y := 364, ;
	t_kb_x	:= 500, ;
	t_kb_y	:= 170, ;
	t_536_x := 177, ;
	t_536_y := 420, ;
	t_5361_x := 247, ;
	t_5361_y := 420, ;
	t_hor	:= 1174, ;
	t_ver	:= 567, ;
	t_bar_x   := 800,   ;
	t_bar_y   := 170,  ;
	t_red	  := 107, ;
	t_red5	  := 107, ;
	t_hor_d_1 := 86, ;
	t_hor_d_2 := 102, ;
	t_br_lis  := 12,   ;
	t_br_komb := 3,    ;
	t_vis_komb:= 1174, ;
	t_raz_komb:= 30,   ;
	t_fnt_komb:= Space(10), ;
	t_fnt_ser := Space(10), ;
	t_fnt_kolo:= Space(10), ;
	t_fnt_536 := Space(10), ;
	cDefPGS   := "", ;
	cDatum	  := ""

      IF !lKolo
	 err_beep()
	 al_box("Nije izabrano ni jedno kolo!",1,{" OK "},1,9,20,15,60)
	 RETURN NIL
      ENDIF

      IF !File(cMBpath)
	 err_beep()
	 al_box("LISTIC.DBF ne postoji!",1,{" OK "},1)
	 RETURN NIL
      ENDIF

      IF !Lozinka()
	 RETURN NIL
      ENDIF

      cDefPGS = curr_PGS

      IF File( AllTrim(Group->path) + "\" + cDefPGS )
	 RESTORE FROM (AllTrim(Group->path) + "\" + cDefPGS) ADDITIVE
      ELSE
	 err_beep()
	 al_box("Fajl koji sadrzi definiciju strane ne postoji. Uzimaju se preporucene koordinate.",1,{" OK "},1,9,20,17,60)
      ENDIF

      IF !NetUse(cMBpath3, "MiRRoR")
	 RETURN NIL
      ENDIF

      IF !NetUse(cMBpath, "MiRRoR")
	 RETURN NIL
      ENDIF

      TGoTop()

      nUkupLis = LastRec()

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      ShowDefPGS(cDefPGS)

      BEGIN SEQUENCE

      DO WHILE .T.

      PrSpor()

      IF !tprnopc()
	 BREAK
      ENDIF

      aSpor = {}

      IF al_box("Stampate serije od " + FMT0L(Str(t_od),6) + " do " + FMT0L(Str(t_do),6) + "?", 2, {" DA "," NE "},2,9,20,16,60) = 2
	 t_od = 0
	 t_do = 0
	 LOOP
      ENDIF

      DO WHILE !IsPrinter()
	 err_beep()
	 IF al_box("Stampac nije u redu!",2,{" PONOVI "," PREKID "},1,9,20,15,60) = 1
	    LOOP
	 ELSE
	    BREAK
	 ENDIF
      ENDDO

*izmena
      LGoTo( t_od )

      err_beep()
      IF al_box("Da pocnem?",2,{" DA "," NE "},2) = 2
	 LOOP
      ENDIF

      msg_start(9,20,16,60)
      msg("Stampanje serije od " + FMT0L(Str(t_od),7) + "-" + FMT0L(Str(t_do),7) + " " + FMT0L(Str(Kolo->kolo),2) + ". kola u toku...")

      * SEND_HEADER

      cDatum := ExDate( Kolo->datum )

      PCL_INIT
      s2p(PCL_LEGAL)

      SendFont()

      DO WHILE .T.

	 nTekSn = TRecNo()

	 IF nextkey() != 0
	    CLEAR TYPEAHEAD
	    IF al_box("Prekid stampe?",2,{" DA "," NE "},2) = 1
	       PCL_RESET
	       EXIT
	    ENDIF
	 ENDIF

	 TestPrinter()
	 SendPage()

	 IF LRecNo() > t_do .OR. TEof
	    EXIT
	 ENDIF

      ENDDO

      PCL_END

      msg_end()

      t_od = 0
      t_do = 0

      ENDDO

      END SEQUENCE

      win_rest(cOldScreen)
      vstk_pop()

      CLOSE Listic
      CLOSE Listic5
      Select(cOldSel)

RETURN NIL

FUNCTION tprnopc()

LOCAL cOldScreen := "", ;
      RetVal	 := .T.

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(8,24,12,56,"Stampanje listica za tombolu")

      @ 10,26 SAY "od serije :" GET t_od PICTURE "9999999" VALID ChkBrSer(t_od)
      @ 11,26 SAY "do serije :" GET t_do PICTURE "9999999"

      SetCursor(1)
      READ
      SetCursor(0)

      IF LastKey() = 27
	 RetVal = .F.
      ENDIF

      IF Empty(t_do) .AND. !Empty(t_od)
	 t_do = t_od
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

	s2p(PCL_UND_DIS)

	DO WHILE curr_ticket < (t_br_lis + 1)

	   SendTicket(curr_ticket)

	   TSkip()

	   IF TEof
	      EXIT
	   ENDIF

	   ++curr_ticket

	ENDDO

	s2p(PCL_EJECT)

RETURN NIL

STATIC FUNCTION SendTicket(ticket)

LOCAL x_off	:= 0, ;
      y_off	:= 0, ;
      x_off_ser := 0, ;
      y_off_ser := 0, ;
      x_off_rbk := 0, ;
      y_off_rbk := 0, ;
      x_off_kb	:= 0, ;
      y_off_kb	:= 0, ;
      x_off_536 := 0, ;
      y_off_536 := 0, ;
      x_off_5361 := 0, ;
      y_off_5361 := 0, ;
      x_off_bar := 0, ;
      y_off_bar := 0, ;
      i 	:= 0, ;
      p1	:= 0, ;
      p2	:= 0, ;
      nBrKomb	:= t_br_komb, ;
      nSlajfna	:= t_br_lis, ;
      suma	:= 0, ;
      prvi	:= 0

PRIVATE aList := {}

      --ticket

      x_off	= iif(ticket < nSlajfna, T_TAB_X, T_TAB_X + T_HOR)
      y_off	= T_TAB_Y + ( iif(ticket > (nSlajfna - 1), ticket - nSlajfna, ticket) * T_VER )

      p1 = x_off
      p2 = y_off

      x_off_ser = iif(ticket < nSlajfna, T_SER_X, T_SER_X + T_HOR)
      y_off_ser = T_SER_Y + ( iif(ticket > (nSlajfna - 1), ticket - nSlajfna, ticket) * T_VER )

      x_off_rbk = iif(ticket < nSlajfna, T_RBK_X, T_RBK_X + T_HOR)
      y_off_rbk = T_RBK_Y + ( iif(ticket > (nSlajfna - 1), ticket - nSlajfna, ticket) * T_VER )

      x_off_kb	= iif(ticket < nSlajfna, T_KB_X, T_KB_X + T_HOR)
      y_off_kb	= T_KB_Y + ( iif(ticket > (nSlajfna - 1), ticket - nSlajfna, ticket) * T_VER )

      x_off_536 = iif(ticket < nSlajfna, T_536_X, T_536_X + T_HOR)
      y_off_536 = T_536_Y + ( iif(ticket > (nSlajfna - 1), ticket - nSlajfna, ticket) * T_VER )

      x_off_5361 = iif(ticket < nSlajfna, T_5361_X, T_5361_X + T_HOR)
      y_off_5361 = T_5361_Y + ( iif(ticket > (nSlajfna - 1), ticket - nSlajfna, ticket) * T_VER )

      x_off_bar = iif(ticket < nSlajfna, T_BAR_X, T_BAR_X + T_HOR)
      y_off_bar = T_BAR_Y + ( iif(ticket > (nSlajfna - 1), ticket - nSlajfna, ticket) * T_VER )

      * serija
      s2p( PCL_SET_FONT( 2 ) )
      s2p( PCL_HMI( 5.20 ) )
      s2p( PCL_V_POS( x_off_ser, y_off_ser ) + FMT0L( AllTrim( Str( Kolo->kolo ) ), 3 ) )

      * rbk
      s2p( PCL_V_POS( x_off_rbk, y_off_rbk ) + padl( AllTrim( Str( LRecNo() ) ), 7, "*" ) )

      * 5 od 36
      IF (x_off_536 > 0) .and. (y_off_536 > 0)
	s2p( PCL_SET_FONT( 4 ) )
	s2p( PCL_HMI( 6.00 ) )
	Stamp536( x_off_536, y_off_536, Get3od90( TRecNo() )[1] )
	Stamp536( x_off_5361, y_off_5361, Get3od90( TRecNo() )[2] )
      ENDIF

/*    BAR-CODE SE STAMPA DOLE
      * bar code
      IF (t_bar_x > 0) .AND. (t_bar_y > 0)
	s2p( PCL_V_POS(x_off_bar, y_off_bar) )
	s2p( "@@BC822" +  FMT0L(Str(Kolo->kolo),3) + FMT0L(Str(LRecNo()),7) + "@@BE" )
      ENDIF
*/

      DO WHILE nBrKomb > 0

	 UzmiBr()

	 if prvi = 0
	   prvi := aList[7]
	 endif

	 * serija
	 s2p(PCL_SET_FONT(1))

	 FOR i = 1 TO 9

	     IF aList[i] != 126
		s2p( PCL_HMI( 6.00 ) )
		s2p( PCL_V_POS( x_off, y_off ) + AllTrim( Str( aList[i] ) ) )
	     ENDIF

	     IF i = 1
		x_off += t_hor_d_1
	     ELSE
		x_off += t_hor_d_2
	     ENDIF

	     suma += aList[i]

	 NEXT

	 x_off = p1
	 y_off += T_RED

	 FOR i = 10 TO 18

	     IF aList[i] != 126
		s2p( PCL_HMI( 6.00 ) )
		s2p( PCL_V_POS( x_off, y_off ) + AllTrim( Str( aList[i] ) ) )
	     ENDIF

	     IF i = 10
		x_off += t_hor_d_1
	     ELSE
		x_off += t_hor_d_2
	     ENDIF

	     suma += aList[i]

	 NEXT

	 x_off = p1
	 y_off += T_RED + 1

	 FOR i = 19 TO 27

	     IF aList[i] != 126
		s2p( PCL_HMI( 6.00 ) )
		s2p( PCL_V_POS( x_off, y_off ) + AllTrim( Str( aList[i] ) ) )
	     ENDIF

	     IF i = 19
		x_off += t_hor_d_1
	     ELSE
		x_off += t_hor_d_2
	     ENDIF

	     suma += aList[i]

	 NEXT

	 * bar code
	 IF (t_bar_x > 0) .AND. (t_bar_y > 0)
	   s2p( PCL_V_POS(x_off_bar, y_off_bar) )
	   s2p( "@@BC822" +  FMT0L(Str(Kolo->kolo),3) + FMT0L(Str(LRecNo()),7) + "@@BE" )
	 ENDIF

	 --nBrKomb

	 IF nBrKomb > 0

	    TSkip()

	    x_off = p1
	    y_off = p2 + t_vis_komb + t_raz_komb
	    p2 = y_off

	    y_off_ser += t_vis_komb + t_raz_komb

	    aList := {}

	 ENDIF

      ENDDO

      * serija
      s2p( PCL_SET_FONT( 2 ) )
      s2p( PCL_HMI( 5.20 ) )

      * kb
      IF (x_off_kb > 0) .and. (y_off_kb > 0)
	s2p( PCL_V_POS( x_off_kb, y_off_kb ) + Right( FMT0L( Str(Suma * prvi), 7 ), 3 ) )
      ENDIF

RETURN NIL

STATIC FUNCTION UzmiBr()

LOCAL i := 0

       FOR i = 1 TO 27 STEP 3
	   aadd( aList, Asc( SubStr( Listic->sadrzaj, i, 1 ) ) )
       NEXT

       FOR i = 2 TO 27 STEP 3
	   aadd( aList, Asc( SubStr( Listic->sadrzaj, i, 1 ) ) )
       NEXT

       FOR i = 3 TO 27 STEP 3
	   aadd( aList, Asc( SubStr( Listic->sadrzaj, i, 2 ) ) )
       NEXT

RETURN NIL

STATIC FUNCTION S2P(cStr)

local i := 0, cntsnd := 0, cchar := "", lPrvi := .F.

      cntsnd = PrintSend(cStr)

      IF cntsnd != 0

	 IF !lPrvi
	    lPrvi = .T.
	    IF AScan(aSpor, nTekSN) = 0
	       aadd(aSpor,nTekSN)
	    ENDIF
	 ENDIF

	 DO WHILE cntsnd != 0
	    cStr = Right(cStr, cntsnd)
	    TestPrinter()
	    cntsnd = PrintSend(cStr)
	 ENDDO

      ENDIF

RETURN NIL

STATIC FUNCTION ChkBrSer(ttt)

LOCAL RetVal := .T., ;
      oGet   := GetActive()

      IF Empty(ttt)
	 RETURN .F.
      ENDIF

      --ttt

      IF Int( ttt / (t_br_lis / 2) ) != ttt / (t_br_lis / 2)
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
	    MilliSec(1000)
	    DO WHILE !PrintReady(1); ENDDO
	 ENDIF

RETURN NIL

FUNCTION Lozinka()

LOCAL cOldScreen := "", ;
      cLozinka	 := Space(20), ;
      pokusaj	 := 0, ;
      RetVal	 := .T.

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(9,25,15,55,"PASSWORD")

      DO WHILE pokusaj < 3

	 @ 11,27 SAY "Unesi lozinku?"
	 @ 13,27 GET cLozinka PICTURE "XXXXXXXXXXXXXXXXXXXX" COLOR "b/b,b/b"

	 SetCursor(1)
	 READ
	 SetCursor(0)

	 IF LastKey() == 27
	    RetVal = .F.
	    EXIT
	 ENDIF

	 IF AllTrim(cLozinka) != Lozinka
	    err_beep()
	    al_box("Pogresna lozinka!",1,{" OK "},1,9,20,15,60)
	    cLozinka = Space(20)
	    ++pokusaj
	 ELSE
	    pokusaj = 0
	    RetVal = .T.
	    EXIT
	 ENDIF

      ENDDO

      IF pokusaj = 3
	 RetVal = .F.
      ENDIF

      win_rest(cOldScreen)
      vstk_pop()

RETURN RetVal

FUNCTION SendFont()

local cc := cMainDir + "\font\" + AllTrim(t_fnt_komb) + ".SFP"

	 S2P(PCL_SET_ID(1))
	 SendFile(cMainDir + "\font\" + AllTrim(t_fnt_komb) + ".SFP")

	 S2P(PCL_SET_ID(2))
	 SendFile(cMainDir + "\font\" + AllTrim(t_fnt_ser) + ".SFP")

	 S2P(PCL_SET_ID(3))
	 SendFile(cMainDir + "\font\" + AllTrim(t_fnt_kolo) + ".SFP")

	 S2P(PCL_SET_ID(4))
	 SendFile(cMainDir + "\font\" + AllTrim(t_fnt_536) + ".SFP")

RETURN NIL

FUNCTION PrSpor()

LOCAL cOldScreen := ""

      IF Len(aSpor) = 0
	 RETURN
      ENDIF

      vstk_push()
      cOldScreen = win_save(5,5,15,20)

      AChoice(6,6,14,19,aSpor)

      win_rest(cOldScreen)
      vstk_pop()

RETURN NIL

FUNCTION Get3od90( nRecNo )

 Local cRet   := "", ;
       aTemp  := {}, ;
       aTemp1 := {}, ;
       i      := 0,  ;
       brkart := 0

      brkart := Int( ( nRecNo - 1 ) / BR_KOMB ) + 1
      // Listic5->( dbGoTo( ( ( brkart - 1 ) * 2 ) + 1 ) )
      Listic5->( dbGoTo( Set536( nRecNo, BR_KOMB536 ) ) )

      FOR i = 1 TO 5
	  aadd( aTemp, FMT0L( Str( Asc( SubStr( Listic5->sadrzaj, i, 1 ) ) ), 2 ) )
      NEXT
      aadd(aTemp1, aTemp)
      aTemp := {}

      Listic5->( dbSkip() )

      FOR i = 1 TO 5
	  aadd( aTemp, FMT0L( Str( Asc( SubStr( Listic5->sadrzaj, i, 1 ) ) ), 2 ) )
      NEXT
      aadd(aTemp1, aTemp)

RETURN aTemp1

* vraca datum u obliku ( Petak, 01.01.98 )
FUNCTION ExDate( dDate )

 Local cRet := "", ;
       aDan := { "Nedelja", "Ponedeljak", "Utorak", "Sreda", "^etvrtak", "Petak", "Subota" }

       cRet := aDan[ Dow( dDate ) ] + " " + DtoC( dDate )

RETURN cRet

FUNCTION Stamp536( x, y, aKomb536 )

 Local i     := 0

    for i = 1 to 5
	s2p( PCL_V_POS( x, y ) + aKomb536[i] )
	x += T_RED5
    next

RETURN NIL
