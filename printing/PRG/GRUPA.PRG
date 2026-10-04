#include "sixcdx2.ch"
#include "machsix.ch"
#include "inkey.ch"
#include "box.ch"
#include "memoedit.ch"
#include "commands.ch"
#include "fileio.ch"
#include "directry.ch"

FUNCTION Group()

LOCAL cOldScreen := "", ;
      cOldDir	 := ""

PRIVATE t_naziv := Space(30), ;
	t_datum := Date(), ;
	t_stdat := "N"

      USE Group NEW VIA "SIXCDX" SHARED
      SET TAG TO 0
      GO TOP

/*
      IF !NetUse("group")
	 RETURN NIL
      ELSE
	 SET TAG TO 0
	 GO TOP
      ENDIF
*/

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(9,17,14,63,"NOVA GRUPA")

      @ 11, 19 SAY "Naziv grupe:" GET t_naziv PICTURE "@!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" VALID ChkName(t_naziv)
      @ 12, 19 SAY "Datum      :" GET t_datum PICTURE "99/99/99"
      @ 13, 19 SAY "sa datumom :" GET t_stdat PICTURE "@!X" VALID t_stdat $ "D_N_"

      SetCursor(1)
      READ
      SetCursor(0)

      win_rest(cOldScreen)
      vstk_pop()

      IF LastKey() != 27

	 APPEND BLANK

	 REPLACE naziv	WITH t_naziv, ;
		 datum	WITH t_datum, ;
		 stdat	WITH iif(t_stdat="D",.T.,.F.), ;
		 kolo	WITH 0	    , ;
		 path	WITH DirName() + "\" + MakeDir()


	 cOldDir = DirName()
	 DirChange(Group->path)

	 dbCreate("kolo",    {;
			     {"kolo",        "N",  5,  0}, ;
			     {"datum",       "D",  8,  0}, ;
			     {"pocser",      "N",  8,  0}, ;
			     {"ukupno",      "N",  8,  0}, ;
			     {"prodato",     "N",  8,  0}, ;
			     {"path",        "C", 60,  0}  ;
			     }, "SIXCDX")

	 USE KOLO NEW VIA "SIXCDX"
	 INDEX ON kolo TAG kolo OF KOLO

	 DirChange(cOldDir)

      ENDIF

      CLOSE ALL

RETURN NIL

STATIC FUNCTION ChkName(ttt)

LOCAL RetVal := .T., ;
      oGet   := GetActive()

      IF Empty(ttt)
	 RETURN .F.
      ENDIF

      SET TAG TO NAZIV
      GO TOP

      SEEK ttt
      IF Found()
	 err_beep()
	 al_box("Grupa sa nazivom " + AllTrim(ttt) + " vec postoji!", 1, {" OK "}, 1, 9, 20, 16, 60)
	 oGet:buffer = Space(30)
	 oGet:Assign()
	 oGet:Display()
	 RetVal = .F.
      ENDIF

      SET TAG TO 0
      GO TOP

RETURN RetVal

STATIC FUNCTION MakeDir()

LOCAL aDir     := {}, ;
      aTemp    := {}, ;
      i        := 0, ;
      nUkupDir := 0, ;
      cTemp    := ""

      aTemp = Directory("GRP*.", "D")

      nUkupDir = iif(Len(aTemp)=0,1,Len(aTemp))
      cTemp = "GRP" + FMT0L(Str(nUkupDir,5),5)

      FOR i = 1 TO Len(aTemp)
	  aadd(aDir, aTemp[i,1])
      NEXT

      DO WHILE .T.

	 IF aScan(aDir, cTemp) = 0
	    DirMake(cTemp)
	    EXIT
	 ELSE
	    ++nUkupDir
	    cTemp = "GRP" + FMT0L(Str(nUkupDir,5),5)
	 ENDIF

      ENDDO

RETURN cTemp

FUNCTION PrgGroup()

LOCAL columns	 := {}, ;
      cOldScreen := ""

      USE Group NEW VIA "SIXCDX" SHARED
      SET TAG TO 0
      GO TOP

/*
      IF !NetUse("group")
	 RETURN NIL
      ELSE
	 SET TAG TO 0
	 GO TOP
      ENDIF
*/

      IF Bof() .AND. Eof()
	 err_beep()
	 al_box("Ne postoji ni jedna grupa!",1,{" OK "},1,9,20,15,60)
	 CLOSE ALL
	 RETURN NIL
      ENDIF

      aadd(columns, {"", "NAZIV", Select(), ""})

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(7,24,16,56,"IZBOR GRUPE")

      MyBrowse(8,24,16,56,columns,NIL,.T.,"grpudf()",.F.)

      win_rest(cOldScreen)
      vstk_pop()

      CLOSE ALL

RETURN NIL

FUNCTION grpudf()

LOCAL cOldDir	 := DirName(), ;
      cOldScreen := ""

PRIVATE lMore := .T.
      
      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      back()

      DirChange(Group->path)

      TEof = .F.
      TBof = .F.
      lKolo = .F.

      USE Kolo NEW VIA "SIXCDX" SHARED
      SET TAG TO kolo
      GO TOP

/*
      IF !NetUse("kolo")
	 RETURN NIL
      ELSE
	 SET TAG TO KOLO
	 GO TOP
      ENDIF
*/

      SetHeader( "BINGO (4+2) - " + AllTrim(Group->naziv) + iif( Group->stdat, " - " + DtoC( Group->datum ), "" ) )
      SetFuter({"ESC - Izlaz"})

      KEYBOARD Chr(K_ENTER)

      Group->( dbUnLock() )

      DO WHILE lMore

	 do_menu(Menu_Main1,,1)

      ENDDO

      DirChange( cOldDir )

      win_rest( cOldScreen )
      vstk_pop()

      CLOSE Kolo
      SELECT Group

      KEYBOARD Chr( K_ESC )

RETURN NIL
