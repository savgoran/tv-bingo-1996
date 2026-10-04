#include "sixcdx.ch"
#include "machsix.ch"
#include "commands.ch"
#include "inkey.ch"

FUNCTION UnZas()

LOCAL cOldScreen := ""

PRIVATE aGet	  := {}, ;
	lAppend   := .F., ;
	t_brzas   := 0, ;
	t_prezime := Space(25), ;
	t_ime	  := Space(25), ;
	t_adresa  := Space(25), ;
	t_mesto   := Space(20), ;
	t_tel	  := Space(20)

      USE Centar NEW VIA "SIXCDX"
      SET TAG TO broj
      GO TOP

      USE Zastup NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(7, 21, 17, 59, "ZASTUPNIK")

      Mask()
      DO WHILE .T.

	 SetCursor(1)
	 READ
	 SetCursor(0)

	 IF LastKey() = K_ESC
	    EXIT
	 ENDIF

	 IF Empty(t_mesto)
	    ErrBeep()
	    al_box("Mesto nije uneto!", 1, {" OK "}, 1, 9, 25, 15, 55)
	    GetList = aGet
	    LOOP
	 ENDIF

	 StoreVal()

	 DoneBeep()

	 GetList = aGet

	 lAppend = .F.
	 ResetVar(.T.)

      ENDDO

      win_rest(cOldScreen)
      vstk_pop()

      CLOSE ALL

RETURN NIL

STATIC FUNCTION Mask()

      @  9, 23 SAY "Zastupnik broj:" GET t_brzas   PICTURE "9999" VALID ChkBrZas(t_brzas)
      @ 11, 23 SAY "Prezime:"        GET t_prezime PICTURE "@!XXXXXXXXXXXXXXXXXXXXXXXXX"
      @ 12, 23 SAY "Ime    :"        GET t_ime     PICTURE "@!XXXXXXXXXXXXXXXXXXXXXXXXX"
      @ 13, 23 SAY "Adresa :"        GET t_adresa  PICTURE "@!XXXXXXXXXXXXXXXXXXXXXXXXX"
      @ 14, 23 SAY "Mesto  :"        GET t_mesto   PICTURE "@!XXXXXXXXXXXXXXXXXXXX" VALID !Empty(t_mesto)
      @ 16, 23 SAY "Tel    :"        GET t_tel     PICTURE "@!XXXXXXXXXXXXXXXXXXXX"

      aGet = GetList

RETURN NIL

STATIC FUNCTION StoreVal()

      IF lAppend
	 lAppend = .F.
	 Zastup->(dbAppend())
      ENDIF

      REPLACE brzas	WITH t_brzas, ;
	      prezime	WITH t_prezime, ;
	      ime	WITH t_ime, ;
	      mesto	WITH t_mesto, ;
	      adresa	WITH t_adresa, ;
	      tel	WITH t_tel

RETURN NIL

STATIC FUNCTION ResetVar(opc)

LOCAL i := 0

      DEFAULT opc TO .F.

      IF opc
	 t_brzas   := 0
      ENDIF

      t_prezime := Space(25)
      t_ime	:= Space(25)
      t_adresa	:= Space(25)
      t_mesto	:= Space(20)
      t_tel	:= Space(20)

      FOR i = 1 TO Len(GetList)
	  GetList[i]:Display()
      NEXT

RETURN NIL

STATIC FUNCTION ChkBrZas(ttt)

LOCAL RetVal := .T., ;
      oGet   := GetActive(), ;
      i      := 0, ;
      nCentar:= 0

      IF Empty(ttt)
	 Zastup->(dbGoBottom())
	 oGet:buffer = Str(brzas+1,4)
	 oGet:Assign()
	 oGet:Display()
	 RETURN .F.
      ENDIF

/*
      nCentar = Val( Left( Str(ttt), 1 ) )
      IF !IsCentar( nCentar )
	 ErrBeep()
	 al_box("Centar br." + Str(nCentar,1) + " nije otvoren!", 1, {" OK "}, 1, 9, 25, 16, 55)
	 RETURN .F.
      ENDIF
*/

      Zastup->(dbSeek(ttt))
      IF !Zastup->(Found())

	 lAppend = .T.
	 ResetVar()

      ELSE

	 lAppend = .F.

	 t_prezime := prezime
	 t_ime	   := ime
	 t_adresa  := adresa
	 t_mesto   := mesto
	 t_tel	   := tel

	 FOR i = 2 TO Len(GetList)
	     GetList[i]:Display()
	 NEXT

      ENDIF

RETURN RetVal

FUNCTION PrZas()

LOCAL cOldScreen := "", ;
      aTemp	 := {}, ;
      nCentar	 := 0, ;
      cCentar	 := ""

      IF al_box("Pregled zastupnika?", 2, {" DA "," NE "}, 2, 9, 25, 15, 55) = 2
	 RETURN NIL
      ENDIF

      USE Centar NEW VIA "SIXCDX"
      SET TAG TO broj
      GO TOP

      USE Zastup NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      BEGIN SEQUENCE

      vstk_push()
      cOldScreen = win_save(0, 0, 24, 79)

      WinStyle(7, 28, 14, 51, "CENTAR")

      * aTemp = GetLisCen()

      * nCentar = AChoice(9, 30, 13, 49, aTemp)

      win_rest(cOldScreen)
      vstk_pop()

/*
      IF nCentar == 0
	 BREAK
      ENDIF

      cCentar = AllTrim( SubStr(aTemp[nCentar],3) )
      nCentar = Val( Left(aTemp[nCentar], 1) )
*/
      IniPtr()
      Prt1()
      Prt2()

      ? padc("PREGLED ZASTUPNIKA", 78, " ")
*      ? padc("centar: " + cCentar, 78, " ")

      ?

      ? Replicate("*", 78)
      ? "Br.  Prezime i ime            Mesto           Adresa              Telefon"
      ? Replicate("*", 78)

*	      xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx xxxxxxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxx xxxxxxxxxxxxxxx

      DO WHILE !Zastup->(Eof())

	 IF nCentar > 0
	    IF Left(Str(brzas), 1) != Str(nCentar, 1)
	       dbSkip()
	       LOOP
	    ENDIF
	 ENDIF

	 ? Str(brzas,4) + Space(1) + padr(Left(AllTrim(prezime) + Space(1) + AllTrim(ime), 25), 25, " ") +;
	   Left(Mesto, 15) + Space(1) + Left(Adresa, 19) + Space(1) + Left(tel,12)

	 Zastup->(dbSkip())

      ENDDO

      ? Replicate("*", 78)

      Prt3()

      END SEQUENCE

      CLOSE ALL

RETURN NIL

FUNCTION DelZas()

LOCAL cOldScreen := "", ;
      t_brzas	 := 0

      USE Zaduz NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      USE Zastup NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(9, 25, 12, 55, "BRISANJE ZASTUPNIKA")

      @ 11,27 SAY "Broj zastupnika:" GET t_brzas PICTURE "9999"

      SetCursor(1)
      READ
      SetCursor(0)

      win_rest(cOldScreen)
      vstk_pop()

      IF LastKey() == K_ESC
	 CLOSE ALL
	 RETURN NIL
      ENDIF

      Zastup->(dbSeek(t_brzas))
      IF !Zastup->(Found())
	 ErrBeep()
	 al_box("Zastupnik br. " + Str(t_brzas, 4) + "  ne postoji!", 1, {" OK "}, 1, 9, 20, 15, 60)
	 CLOSE ALL
	 RETURN NIL
      ENDIF

      Zaduz->(dbSeek( FMT0L(Str(t_brzas), 4) ))
      IF Zaduz->(Found())
	 ErrBeep()
	 al_box("Zastupnik br. " + Str(t_brzas, 4) + "  ima zaduzenje. Ne mozete ga obrisati!", 1, {" OK "}, 1, 9, 20, 16, 60)
	 CLOSE ALL
	 RETURN NIL
      ENDIF

      IF al_box("Brisete zastupnika br. " + Str(t_brzas,4) + " - " + AllTrim(Zastup->prezime) + " " + AllTrim(Zastup->ime) + "?", 2, {" DA "," NE "}, 2, 9, 20, 16, 60) = 1
	 Zastup->(dbDelete())
	 DoneBeep()
      ENDIF

      CLOSE ALL

RETURN NIL
