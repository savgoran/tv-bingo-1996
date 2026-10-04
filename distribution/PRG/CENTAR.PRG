#include "sixcdx2.ch"
#include "machsix.ch"
#include "commands.ch"

FUNCTION UnCentar()

LOCAL cOldScreen := ""

PRIVATE t_broj	   := 0, ;
	t_naziv    := Space(20), ;
	t_path	   := Space(60), ;
	lAppend    := .F.

      USE Centar NEW VIA "SIXCDX"
      SET TAG TO broj
      GO TOP

      BEGIN SEQUENCE

      vstk_push()
      cOldScreen = win_save(0, 0, 24, 79)

      WinStyle(7, 20, 12, 59, "UNOS CENTRA")

      @  9, 22 SAY "Broj:"  GET t_broj  PICTURE "9" VALID ChkBroj(t_broj)
      @  9, 31 SAY "Naziv:" GET t_naziv PICTURE "@!XXXXXXXXXXXXXXXXXXXX"
      @ 11, 22 SAY "Path:"  GET t_path  PICTURE "@!@S30" VALID !Empty(t_path)

      SetCursor(1)
      READ
      SetCursor(0)

      win_rest(cOldScreen)
      vstk_pop()

      IF LastKey() == 27
	 BREAK
      ENDIF

      IF lAppend
	 lAppend = .F.
	 Centar->( dbAppend() )
      ENDIF

      t_path = AllTrim(t_path)
      t_path += iif( Right(t_path,1) != "\", "\", "" )

      REPLACE Centar->broj  WITH t_broj , ;
	      Centar->naziv WITH t_naziv, ;
	      Centar->path  WITH t_path

      END SEQUENCE

      CLOSE ALL

RETURN NIL

STATIC FUNCTION ChkBroj(ttt)

LOCAL lRet := .T.

      IF Empty(ttt)
	 RETURN .F.
      ENDIF

      Centar->( dbSeek(ttt) )
      IF Centar->( Found() )
	 t_naziv = Centar->naziv
	 t_path  = Centar->path
	 lAppend = .F.
	 GetList[2]:Display()
	 GetList[3]:Display()
      ELSE
	 t_naziv = Space(20)
	 t_path  = Space(60)
	 lAppend = .T.
	 GetList[2]:Display()
	 GetList[3]:Display()
      ENDIF

RETURN lRet

FUNCTION IsCentar(nCentar)

      Centar->( dbSeek(nCentar) )

RETURN Centar->( Found() )

FUNCTION GetCentar(nCentar)

LOCAL cRet := Space(20)

      Centar->( dbSeek(nCentar) )
      IF Centar->( Found() )
	 cRet = Centar->naziv
      ENDIF

RETURN cRet

FUNCTION GetLisCen()

LOCAL aRet := {}

      aadd(aRet, "0 SVI CENTRI")

      Centar->( dbGoTop() )
      DO WHILE !Centar->( Eof() )
	 aadd(aRet, Str(Centar->broj,1) + " " + Centar->naziv)
	 Centar->( dbSkip() )
      ENDDO

RETURN aRet
