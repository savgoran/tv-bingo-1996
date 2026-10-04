#include "sixcdx2.ch"
#include "machsix.ch"
#include "inkey.ch"
#include "box.ch"
#include "memoedit.ch"
#include "commands.ch"
#include "fileio.ch"
#include "directry.ch"

#define TCK_LIMIT     4000000
#define BR_KOMB       3

FUNCTION IzKolo()

LOCAL	cOldScreen := "", ;
	cOldDir    := "", ;
	columns    := {}, ;
	nRecNo	   := Kolo->(RecNo())

PRIVATE ttt := .F.

	IF Kolo->(Bof()) .AND. Kolo->(Eof())
	   err_beep()
	   al_box("Nije otvoreno ni jedno kolo!",1,{" OK "},1,9,20,16,60)
	   RETURN NIL
	ENDIF

	* Kolo->(dbGoTop())
	Kolo->(dbGoBottom())

	cOldDir = DirName()

	aadd(columns, {"Kolo"  ,"KOLO"  ,Select(),""})
	aadd(columns, {"Datum" ,"DATUM" ,Select(),""})
	aadd(columns, {"Ukupno","UKUPNO",Select(),""})

	vstk_push()
	cOldScreen = win_save(7,26,17,55)

	WinStyle( 7, 26, 16, 54, "IZBOR KOLA")

	MyBrowse( 8, 26, 16, 54, columns, NIL, .T., "izbudf()", .F. )

	win_rest(cOldScreen)
	vstk_pop()

	IF !ttt
	   Kolo->(dbGoTo(nRecNo))
	ENDIF

RETURN NIL

FUNCTION IzbUdf()

	TEof = .F.
	TBof = .F.
	lKolo = .T.
	nBrKolo = Kolo->(RecNo())

	DirChange(Group->path)
        DirChange(Kolo->path)

	SetHeader( "TOP VOLLEY (32BC) - " + AllTrim(Group->naziv) + iif( Group->stdat, " - " + DtoC(Kolo->datum), "" ) + ;
		   " - " + "KOLO" + AllTrim(Str(Kolo->kolo)) + " (" + FMT0L(Str(Kolo->ukupno),7) + ")" )

	ttt = .T.

	KEYBOARD Chr(K_ESC)

RETURN NIL

STATIC FUNCTION MakKoloUnq()

LOCAL aDir   := {}, ;
      cTemp  := {}, ;
      cRet   := "", ;
      nBrKol := 0, ;
      i      := 0

      aDir = Directory("kolo*.","D")

      FOR i = 1 TO Len(aDir)
	  aadd(aTemp, aDir[i,1])
      NEXT

      aDir = aTemp

      IF Len(aDir) = 0
	 nBrKol = 1
      ELSE
	 nBrKol = Len(aDir) + 1
      ENDIF

      cRet = "KOLO" + FMT0L(Str(nBrKol,4),4)

RETURN cRet

FUNCTION NewKolo()

LOCAL cOldScreen := "", ;
      t_kolo	 := 0, ;
      t_datum	 := CtoD("  /  /  "), ;
      t_ukupno	 := 0, ;
      t_pocser	 := 0, ;
      cOldDir	 := "", ;
      yyy := 0

      IF Kolo->(Bof()) .AND. Kolo->(Eof())
	 t_kolo = 0
      ELSE
	 Kolo->(dbGoBottom())
	 t_datum = Kolo->datum + 7
      ENDIF

      t_kolo   = Kolo->kolo + 1
      t_pocser = 1

/*
      DO WHILE .T.
	 t_pocser = Int(Random() % MBukup) + 1
	 yyy = t_pocser % 6
	 IF yyy != 0
	    t_pocser -= yyy
	    ++t_pocser
	 ELSE
            ++t_pocser
	 ENDIF
	 IF t_pocser != Kolo->pocser
	    EXIT
	 ENDIF
      ENDDO
*/

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(7,25,14,54,"NOVO KOLO")

      @  9, 27 SAY "Kolo br.        :" GET t_kolo   PICTURE "99999"
      @ 11, 27 SAY "Datum izvlacenja:" GET t_datum  PICTURE "99/99/99" WHEN Empty(t_datum)
      @ 13, 27 SAY "Ukupno listica  :" GET t_ukupno PICTURE "99999999" VALID ChkKoloBr(t_ukupno)

      SetCursor(1)
      READ
      SetCursor(0)

      win_rest(cOldScreen)
      vstk_pop()

      IF LastKey() != 27

	 SetHeader(AllTrim(Group->naziv))
	 DirChange(Group->path)

	 Kolo->(dbAppend())

	 DO WHILE .T.
	    IF NetErr()
	       err_beep()
	       al_box("Neko je zakljucao slog. Sacekajte!",1,{" OK "},1,9,20,15,60)
	    ELSE
	       EXIT
	    ENDIF
	 ENDDO

	 REPLACE Kolo->kolo    WITH t_kolo, ;
		 Kolo->datum   WITH t_datum, ;
		 Kolo->ukupno  WITH t_ukupno, ;
		 Kolo->pocser  WITH t_pocser, ;
		 Kolo->path    WITH "KOLO" + AllTrim(Str(t_kolo))

	 Kolo->(dbCommit())

	 cOldDir = DirName()
	 DirMake(Kolo->path)
	 DirChange(Kolo->path)

	 SetHeader( "TOP VOLLEY (32BC) - " + AllTrim(Group->naziv) + " - " + "KOLO" + AllTrim(Str(Kolo->kolo)) + " (" + FMT0L(Str(Kolo->ukupno),7) + ")" )

	 lKolo = .T.

	 done_beep()

      ENDIF

RETURN NIL

STATIC FUNCTION ChkKoloBr(ttt)

LOCAL RetVal := .T., ;
      oGet   := GetActive()

      IF Empty(ttt)
	 RETURN .F.
      ENDIF

      IF ttt > TCK_LIMIT
	 RETURN .F.
      ENDIF

      IF ttt > MBukup
	 err_beep()
	 al_box("Ima ukupno " + Str(MBukup,8) + " kombinacija!",1,{" OK "},1,9,20,16,60)
	 oGet:buffer = Str(0,8)
	 oGet:Assign()
	 oGet:Display()
	 RetVal = .F.
      ENDIF

RETURN RetVal

STATIC FUNCTION ChkKoloBr1(ttt)

LOCAL RetVal := .T., ;
      oGet   := GetActive()


      IF Kolo->ukupno + ttt > TCK_LIMIT
	 RETURN .F.
      ENDIF

      IF Kolo->ukupno + ttt > MBukup
	 err_beep()
	 al_box("Ima ukupno " + Str(MBukup,8) + " kombinacija!",1,{" OK "},1,9,20,16,60)
	 oGet:buffer = Str(0,8)
	 oGet:Assign()
	 oGet:Display()
	 RetVal = .F.
      ENDIF

RETURN RetVal

FUNCTION ChgKolo()

LOCAL cOldScreen := "", ;
      t_datum	 := Kolo->datum, ;
      t_ukupno	 := 0, ;
      cOldDir	 := ""

      IF !lKolo
	 err_beep()
	 al_box("Nije izabrano ni jedno kolo!",1,{" OK "},1,9,20,15,60)
	 RETURN NIL
      ENDIF

      IF !Kolo->(RLock())
	 err_beep()
	 al_box("Neko je zakljucao slog!",1,{" OK "},1,9,20,15,60)
	 RETURN NIL
      ENDIF

      vstk_push()
      cOldScreen = win_save(7,25,15,55)

      WinStyle(7,25,14,54,"IZMENA KOLA " + Str(Kolo->kolo,4))

      @  9, 27 SAY "Kolo br.        :" GET Kolo->kolo   PICTURE "99999" WHEN .F.
      @ 11, 27 SAY "Datum izvlacenja:" GET t_datum  PICTURE "99/99/99"
      @ 13, 27 SAY "Ukupno listica  :" GET t_ukupno PICTURE "99999999" VALID ChkKoloBr1(t_ukupno)

      SetCursor(1)
      READ
      SetCursor(0)

      win_rest(cOldScreen)
      vstk_pop()

      IF LastKey() != 27

	 IF t_ukupno > 0
	    err_beep()
	    IF al_box("Ukupno ima " + FMT0L(Str(Kolo->ukupno),8) + " kombinacija. Dodajete jos " + FMT0L(Str(t_ukupno),8) + "?",2,{" DA "," NE "},2,9,20,17,60) = 2
	       RETURN NIL
	    ENDIF
	 ENDIF

	 REPLACE Kolo->datum   WITH t_datum, ;
		 Kolo->ukupno  WITH Kolo->ukupno + t_ukupno

	 SetHeader( "TOP VOLLEY (32BC) - " + AllTrim(Group->naziv) + " - " + "KOLO" + AllTrim(Str(Kolo->kolo)) + " (" + FMT0L(Str(Kolo->ukupno),7) + ")" )
	 done_beep()

      ENDIF

      Kolo->(dbUnlock())

RETURN NIL

FUNCTION PrLis()

LOCAL cMBpath  := AllTrim(MBname) + "listic.dbf", ;
      cMBpath3 := AllTrim(MB3name) + "listic5.dbf", ;
      cOldScreen := "", ;
      cOldSel	 := Select(), ;
      nod	 := 0, ;
      ndo	 := 0, ;
      aTemp	 := {}

PRIVATE nHandle    := 0

      IF !lKolo
	 err_beep()
	 al_box("Nije izabrano ni jedno kolo!",1,{" OK "},1,9,20,15,60)
	 RETURN NIL
      ENDIF

	 DO WHILE .T.

	    IF !File(cMBpath)
	       err_beep()
	       IF al_box(cMBpath + " ne postoji!",2,{" PONOVI "," PREKID "},1,9,20,16,60) = 2
		  RETURN NIL
	       ENDIF
	    ELSE
	       EXIT
	    ENDIF

	 ENDDO

	 nHandle = FOpen("cnlist.dat", FO_READ + FO_SHARED)

	 IF !NetUse(cMBpath3, "MiRRoR")
	    FClose(nHandle)
	    RETURN NIL
	 ENDIF

	 IF !NetUse(cMBpath, "MiRRoR")
	    FClose(nHandle)
	    RETURN NIL
	 ENDIF

	 TGoTop()

	 vstk_push()
	 cOldScreen = win_save(0,0,24,79)

	 WinStyle(9,25,12,55,"PREGLED")

	 @ 11,26      SAY "od " GET nod
	 @ 11,Col()+1 SAY "do " GET ndo

	 SetCursor(1)
	 READ
	 SetCursor(0)

	 win_rest(cOldScreen)
	 vstk_pop()

	 IF LastKey() != 27

	 IniPtr()
	 Prt1()
	 Prt2()

	 IF Empty(ndo)
	    ndo = nod
	 ENDIF

	 LGoTo(nod)
	 DO WHILE LRecNo() <= ndo .AND. !TEof

	    ? "RBK: " + FMT0L(str(LRecNo()),7) + " " + "RecNo: " + Str( Listic->(RecNo()), 7)
	    aTemp := Get3od90( TRecNo() )
	    ? "5 od 36 (1): " + aTemp[1,1] + "-" + aTemp[1,2] + "-" + aTemp[1,3] + "-" + aTemp[1,4] + "-" + aTemp[1,5]
	    ? "5 od 36 (2): " + aTemp[2,1] + "-" + aTemp[2,2] + "-" + aTemp[2,3] + "-" + aTemp[2,4] + "-" + aTemp[2,5]
	    FOR i = 1 TO BR_KOMB
		GetKomb()
		TSkip()
	    NEXT

	 ENDDO

	 Prt3()

	 ENDIF

	 FClose(nHandle)

	 Sx_SetPass("")

	 CLOSE Listic
	 CLOSE Listic5
	 Select(cOldSel)

RETURN NIL

/*
FUNCTION PrLis1(nSer)

LOCAL cMBpath := AllTrim(MBname) + "listic.dbf", ;
      cOldScreen := "", ;
      cOldSel	 := Select(), ;
      nod	 := 0, ;
      ndo	 := 0, ;
      aTemp	 := {}

PRIVATE nHandle    := 0

      IF !lKolo
	 err_beep()
	 al_box("Nije izabrano ni jedno kolo!",1,{" OK "},1,9,20,15,60)
	 RETURN NIL
      ENDIF

	 DO WHILE .T.

	    IF !File(cMBpath)
	       err_beep()
	       IF al_box(cMBpath + " ne postoji!",2,{" PONOVI "," PREKID "},1,9,20,16,60) = 2
		  RETURN NIL
	       ENDIF
	    ELSE
	       EXIT
	    ENDIF

	 ENDDO

	 nHandle = FOpen("cnlist.dat", FO_READ + FO_SHARED)

	 IF !NetUse(cMBpath, "MiRRoR")
	    FClose(nHandle)
	    RETURN NIL
	 ENDIF

	 TGoTop()

	 * IniPtr()
	 * Prt1()
	 * Prt2()

	 nod = nSer

	 IF Empty(ndo)
	    ndo = nod
	 ENDIF

	 LGoTo(nod)
	 DO WHILE LRecNo() <= ndo .AND. !TEof

	    aTemp := Get3od90( TRecNo() )
	    ? "RBK: " + FMT0L(str(LRecNo()),7) + " " + "RecNo: " + Str( Listic->(RecNo()), 7)
	    ? "3 od 90 : " + aTemp[1] + "-" + aTemp[2] + "-" + aTemp[3]
	    FOR i = 1 TO BR_KOMB
		GetKomb()
		TSkip()
	    NEXT

	 ENDDO

	 * Prt3()

	 FClose(nHandle)

	 Sx_SetPass("")

	 CLOSE Listic
	 Select(cOldSel)

RETURN NIL
*/

FUNCTION GetKomb()

 Local cRet := "", ;
       i    := 0, ;
       nn   := 0

      ?

      for i = 1 to 27 step 3
	  nn = Asc(substr(sadrzaj,i,1))
	  ?? iif(nn=126,"--",FMT0L(Str(nn,2),2)) + "  "
      next

      ?

      for i = 2 to 27 step 3
	  nn = Asc(substr(sadrzaj,i,1))
	  ?? iif(nn=126,"--",FMT0L(Str(nn,2),2)) + "  "
      next

      ?

      for i = 3 to 27 step 3
	  nn = Asc(substr(sadrzaj,i,1))
	  ?? iif(nn=126,"--",FMT0L(Str(nn,2),2)) + "  "
      next

      ?

RETURN nil

FUNCTION Log2Phy(nZadSer)

LOCAL nRet := 0

      --nZadSer

      IF (Kolo->pocser + nZadSer) <= MBukup
	 nRet = Kolo->pocser + nZadSer
      ELSE
	 nRet = (Kolo->pocser + nZadSer) - MBukup
      ENDIF

RETURN nRet

FUNCTION Phy2Log(nPhy)

LOCAL nRet := 0

      IF nPhy >= Kolo->pocser
	 nRet = nPhy - Kolo->pocser
      ELSE
	 nRet = (MBukup - Kolo->pocser) + nPhy
      ENDIF

RETURN nRet+1

FUNCTION TRecNo()
RETURN Phy2Log(Listic->(RecNo()))

FUNCTION TGoTo(nRec)

      TEof = .F.
      TBof = .F.

      nRec = Abs(nRec)

      IF nRec <= Kolo->ukupno
	 Listic->(dbGoTo(Log2Phy(nRec)))
      ELSE
	 TGoBott()
      ENDIF

RETURN NIL

FUNCTION TGoTop()

      TEof = .F.
      TBof = .F.

      Listic->(dbGoTo(Log2Phy(Kolo->pocser)))

RETURN NIL

FUNCTION TGoBott()

      TEof = .F.
      TBof = .F.

      Listic->(dbGoTo(Log2Phy(Kolo->pocser+(Kolo->ukupno-1))))

RETURN NIL

FUNCTION TSkip(nSkip)

      DEFAULT nSkip TO 1

      IF nSkip > 0
	 TBof = .F.
	 IF (TRecNo() + nSkip) > Kolo->ukupno
	    TGoBott()
	    TEof = .T.
	 ELSE
	    TGoTo(TRecNo() + nSkip)
	 ENDIF
      ELSE
	 TEof = .F.
	 IF (TRecNo() + nSkip) < 1
	    TGoTop()
	    TBof = .T.
	 ELSE
	    TGoTo(TRecNo() + nSkip)
	 ENDIF
      ENDIF

RETURN NIL

FUNCTION TLastRec()
RETURN Kolo->ukupno

FUNCTION LGoTo( nLisBr )

      TGoTo( ( ( nLisBr - 1 ) * BR_KOMB ) + 1 )

RETURN NIL

FUNCTION LSkip( nSkip )

      DEFAULT nSkip TO 1

      TSkip( nSkip * BR_KOMB )

RETURN NIL

FUNCTION LRecNo()

 Local nRel    := 0

      nRel = Int( TRecNo() / BR_KOMB ) + 1

RETURN nRel

FUNCTION Odstamp()

LOCAL cOldScreen := "", ;
      nTemp	 := 0

      IF !lKolo
	 err_beep()
	 al_box("Nije izabrano ni jedno kolo!",1,{" OK "},1,9,20,15,60)
	 RETURN NIL
      ENDIF

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(9,30,15,50,"Broj stampanih?")

      @ 11,32 SAY "Odstampano:"
      @ 13,32 GET nTemp PICTURE "9999999" VALID nTemp > 0

      SetCursor(1)
      READ
      SetCursor(0)

      win_rest(cOldScreen)
      vstk_pop()

      IF LastKey() != 27

	 DO WHILE .T.
	    IF Kolo->(RLock())
	       EXIT
	    ELSE
	       err_beep()
	       al_box("Neko drugi menja ovaj slog. Sacekajte!",1,{" OK "},1,9,20,15,60)
	    ENDIF
	 ENDDO

	 REPLACE Kolo->ukupno WITH nTemp

	 Kolo->(dbUnLock())

	 SetHeader( AllTrim(Group->naziv) + " - " + "KOLO" + AllTrim(Str(Kolo->kolo)) + " (" + FMT0L(Str(Kolo->ukupno),7) + ")" )

	 done_beep()

      ENDIF

RETURN NIL
