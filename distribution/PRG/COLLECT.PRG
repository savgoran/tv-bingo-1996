#include "sixcdx2.ch"
#include "machsix.ch"
#include "commands.ch"

FUNCTION GrabInfo()

LOCAL cTemp	:= "", ;
      nCentar	:= 0, ;
      cCenPath	:= ""

      USE Centar NEW VIA "SIXCDX"
      SET TAG TO broj
      GO TOP

      nCentar = ChCentar()

      IF nCentar > 0
	 Centar->( dbSeek( nCentar ) )
      ELSE
	 CLOSE ALL
	 RETURN NIL
      ENDIF

      IF !File( AllTrim(Centar->path) + "zastup.dbf" )
	 ErrBeep()
	 alert(AllTrim(Centar->path) + " ne postoji!", {" OK "})
	 CLOSE ALL
	 RETURN NIL
      ENDIF

      IniPtr()
      Prt1()
      Prt2()

      ? padc("PRIKUPLJANJE PODATAKA", 80, " ")
      ? padc("centar: " + AllTrim(Centar->naziv), 80, " ")
      ?
      ?

      ChkZas()
      ChkZaduz()
      ChkRazd()

      Prt3()

      CLOSE ALL

RETURN NIL

STATIC FUNCTION ChCentar()

LOCAL cOldScreen := "", ;
      nCentar	 := 0, ;
      aTemp	 := {}

      vstk_push()
      cOldScreen = win_save(0, 0, 24, 79)

      WinStyle(7, 28, 14, 51, "CENTAR")
      aTemp = GetLisCen()
      aDel(aTemp,1)
      ASize(aTemp, Len(aTemp)-1)

      nCentar = AChoice(9, 30, 13, 49, aTemp, , "AchUDF")

      win_rest(cOldScreen)
      vstk_pop()

      IF nCentar > 0
	 nCentar = Val( Left( aTemp[nCentar], 1 ) )
      ENDIF

RETURN nCentar

STATIC FUNCTION ChkZas()

LOCAL nOldSel := Select(), ;
      cPath   := AllTrim(Centar->path) + "zastup.dbf", ;
      nCnt    := 0

      ?
      ? Replicate("*", 80)
      ? "PROVERA ZASTUPNIKA"
      ? Replicate("*", 80)
      ?

      USE Zastup NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      USE (cPath) NEW VIA "SIXCDX" ALIAS CenZas
      SET TAG TO brzas
      GO TOP

      DO WHILE !CenZas->( Eof() )

	 Zastup->( dbSeek( CenZas->brzas ) )
	 IF !Zastup->( Found() )
	    AppRec( "cenzas", "zastup" )
	    * ? FMT0L(Str(Zastup->brzas),4) + " " + padr(Left(AllTrim(Zastup->prezime) + Space(1) + AllTrim(Zastup->ime), 25), 25, " ") + " " + Zastup->mesto
	    ++nCnt
	 ENDIF

	 CenZas->( dbSkip() )

      ENDDO

      ? "Ukupno novih zastupnika: " + Str(nCnt,5)

      CLOSE CenZas
      CLOSE Zastup

      Select(nOldSel)

RETURN NIL

STATIC FUNCTION ChkZaduz()

LOCAL nOldSel := Select(), ;
      cPath   := AllTrim(Centar->path) + "zaduz.dbf", ;
      nUkup   := 0

      ?
      ? Replicate("*", 80)
      ? "PROVERA ZADUZENJA"
      ? Replicate("*", 80)
      ?

      USE Zaduz NEW VIA "SIXCDX"
      SET TAG TO zsp
      GO TOP

      USE (cPath) NEW VIA "SIXCDX" ALIAS CenZaduz
      SET TAG TO brzas
      GO TOP

      DO WHILE !CenZaduz->( Eof() )

	 Zaduz->( dbSeek( FMT0L( Str(CenZaduz->zastup), 4 ) + FMT0L( Str(CenZaduz->serija),4) + FMT0L( Str(CenZaduz->prva_slob), 8 )  ) )
	 IF !Zaduz->( Found() )
	    AppRec( "cenzaduz", "zaduz" )
	    nUkup += Int( (( Zaduz->do - Zaduz->prva_slob ) + 1) / 5 )
	 ENDIF

	 CenZaduz->( dbSkip() )

      ENDDO

      ? "Ostalo kartica za zaduzenje: " + Str(nUkup, 8)

      CLOSE CenZaduz
      CLOSE Zaduz

      Select(nOldSel)

RETURN NIL

STATIC FUNCTION ChkRazd()

LOCAL nOldSel := Select(), ;
      cPath   := AllTrim(Centar->path) + "razd.dbf", ;
      nUkup   := 0

      ?
      ? Replicate("*", 80)
      ? "PROVERA RAZDUZENJA"
      ? Replicate("*", 80)
      ?

      USE Razd NEW VIA "SIXCDX"
      SET TAG TO zso
      GO TOP

      USE (cPath) NEW VIA "SIXCDX" ALIAS CenRazd
      SET TAG TO brzas
      GO TOP

      DO WHILE !CenRazd->( Eof() )

	 Razd->( dbSeek( FMT0L( Str(CenRazd->zastup), 4 ) + FMT0L( Str(CenRazd->serija),4) + FMT0L( Str(CenRazd->od), 8 )  ) )
	 IF !Razd->( Found() )
	    AppRec( "cenrazd", "razd" )
	    nUkup += Int( ( Razd->kart - Razd->od ) / 5 )
	 ENDIF

	 CenRazd->( dbSkip() )

      ENDDO

      ? "Ukupno razduzenih kartica: " + Str(nUkup, 8)

      CLOSE CenRazd
      CLOSE Razd

      Select(nOldSel)

RETURN NIL

FUNCTION RangCity()

 Local i     := 0
 Local nUkup := 0
 Local cTemp := 0
 Local aPage[80]
 Local nRow  := 1
 Local nCol  := 0
 Local nRedBr := 1

       IF al_box("Rang lista?", 2, {" DA "," NE "}, 2, 9, 25, 15, 55) == 2
	  RETURN NIL
       ENDIF

       dbCreate("RANG", {;
			 {"MESTO",        "C",    20,   0}, ;
			 {"UKUPNO",       "N",     6,   0}  ;
			}, "DBFNTX")

       USE Fond NEW VIA "SIXCDX"
       SET TAG TO kolo
       GO TOP
       GO BOTTOM

       USE Rang NEW VIA "DBFNTX"
       INDEX ON Descend(ukupno) TO rang
       SET INDEX TO rang
       GO TOP

       USE Opseg NEW VIA "DBFNTX"
       INDEX ON mesto TO mesto
       SET INDEX TO mesto
       GO TOP

       msg_start(9,25,15,55)
       msg("sacekajte...")

       DO WHILE !Opseg->(Eof())

	  cTemp = Opseg->mesto
	  DO WHILE Opseg->mesto == cTemp .AND. !Opseg->(Eof())

	     nUkup += ( ( Opseg->do - Opseg->od ) + 1 ) / 5

	     Opseg->( dbSkip() )

	  ENDDO

	  Rang->( dbAppend() )
	  REPLACE Rang->mesto	 WITH cTemp, ;
		  Rang->ukupno	 WITH nUkup

	  nUkup = 0

       ENDDO

       msg_end()

       nUkup = 0

       IniPtr()
       Prt1()
       Prt2()

       aPage = AFill( aPage, "" )

       ? FontS + padc("KENO - PRODAJA PO MESTIMA", 80, " ")
       ? padc( "kolo: " + AllTrim( Str( fond->kolo ) ), 80, " " )
       ?

       i := 1

       Rang->( dbGoTop() )
       DO WHILE !Rang->( Eof() )

	  aPage[nRow] += FMTBLL( Str( nRedBr ), 4 ) + ". " + Rang->mesto + Space( 2 ) + Str( Rang->ukupno, 7 ) + Space( 4 )
	  ++nRedBr
	  ++nRow

	  IF nRow == 80

	     nRow = 1
	     nCol += 1

	     IF nCol == 3

		nCol = 0
		OutPage( aPage )
		aPage = AFill( aPage, "" )

	     ENDIF

	  ENDIF

	  nUkup += Rang->ukupno

	  Rang->( dbSkip() )

       ENDDO

       IF !Empty( aPage[1] )
	  aPage[nRow + 1] += ""
	  aPage[nRow + 2] += "Ukupno                 " + Str( nUkup, 7 )
	  OutPage( aPage )
       ENDIF

       Prt3()

       CLOSE ALL

       DeleteFile("mesto.ntx")

RETURN NIL

STATIC FUNCTION OutPage( aPage )

 Local i := 0

      FOR i = 1 TO Len( aPage )
	  ? RTrim( aPage[i] )
      NEXT

RETURN NIL

FUNCTION RangProd()

 Local i     := 0
 Local nUkup := 0
 Local nTemp := 0
 Local aPage[80]
 Local nRow  := 1
 Local nCol  := 0
 Local nRedBr := 1

       IF al_box("Rang lista?", 2, {" DA "," NE "}, 2, 9, 25, 15, 55) == 2
	  RETURN NIL
       ENDIF

       dbCreate("RANGP", {;
			 {"BRZAS ",       "N",     4,   0}, ;
                         {"IME   ",       "C",    25,   0}, ;
			 {"UKUPNO",       "N",     6,   0}  ;
			 }, "DBFNTX")

       USE Fond NEW VIA "SIXCDX"
       SET TAG TO kolo
       GO TOP
       GO BOTTOM

       USE Zastup NEW VIA "SIXCDX"
       SET TAG TO brzas
       GO TOP

       USE RangP NEW VIA "DBFNTX"
       INDEX ON Descend(ukupno) TO rangp
       SET INDEX TO rangp
       GO TOP

       USE Opseg NEW VIA "DBFNTX"
       INDEX ON brzas TO brzas
       SET INDEX TO brzas
       GO TOP

       msg_start(9,25,15,55)
       msg("sacekajte...")

       DO WHILE !Opseg->(Eof())

	  nTemp = Opseg->brzas
	  Zastup->( dbSeek( nTemp ) )
	  DO WHILE Opseg->brzas == nTemp .AND. !Opseg->(Eof())

	     nUkup += ( ( Opseg->do - Opseg->od ) + 1 ) / 5

	     Opseg->( dbSkip() )

	  ENDDO

	  RangP->( dbAppend() )
	  REPLACE RangP->ime	  WITH padr(Left( AllTrim(Zastup->prezime) + " " + AllTrim(Zastup->ime), 20), 20, " "), ;
		  RangP->BRZAS	  WITH nTemp, ;
		  RangP->ukupno   WITH nUkup

	  nUkup = 0

       ENDDO

       msg_end()

       nUkup = 0

       IniPtr()
       Prt1()
       Prt2()

       aPage = AFill( aPage, "" )

       ? FontS + padc("KENO - RANG LISTA PRODAVACA", 80, " ")
       ? padc( "kolo: " + AllTrim( Str( fond->kolo ) ), 80, " " )
       ?

       i := 1

       RangP->( dbGoTop() )
       DO WHILE !RangP->( Eof() )

	  aPage[nRow] += FMTBLL( Str( nRedBr ), 4 ) + ". " + Str(RangP->brzas,4) + Space( 2 ) + RangP->ime + Space(2) + Str( RangP->ukupno, 7 ) + Space( 4 )
	  ++nRedBr
	  ++nRow

	  IF nRow == 80

	     nRow = 1
	     nCol += 1

	     IF nCol == 2

		nCol = 0
		OutPage( aPage )
		aPage = AFill( aPage, "" )

	     ENDIF

	  ENDIF

	  nUkup += RangP->ukupno

	  RangP->( dbSkip() )

       ENDDO

       IF !Empty( aPage[1] )
	  IF nRow < 78
	     aPage[nRow + 1] += ""
	     aPage[nRow + 2] += "Ukupno                 " + Str( nUkup, 7 )
	     OutPage( aPage )
	  ELSE
	  ENDIF
       ENDIF

       Prt3()

       CLOSE ALL

       DeleteFile("brzas.ntx")

RETURN NIL
