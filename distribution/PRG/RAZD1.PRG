#include "sixcdx2.ch"
#include "machsix.ch"
#include "inkey.ch"
#include "commands.ch"

FUNCTION RazdX()

LOCAL i          := 0, ;
      cOldScreen := "", ;
      nAlch	 := 0

PRIVATE t_kart := Space(16), ;
	aMyGet := {}, ;
	nSer   := 0, ;
	nRBK   := 0, ;
	t_zastup := 0, ;
        t_ime  := Space(25), ;
	t_ser  := 0, ;
	t_od   := 0, ;
	t_do   := 0, ;
	t_ukup := 0, ;
	aLast5 := Array(5), ;
	cLast5 := "", ;
	nUkupKar := 0

	aLast5 = AFill(aLast5, "")

      USE Zastup NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      USE Zaduz NEW VIA "SIXCDX"
      SET TAG TO serod
      GO TOP

      USE Razd NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      nUkupKar = Ukup()

      vstk_push()
      cOldScreen = win_save(0, 0, 24, 79)

      WinStyle(7, 8, 18, 72, "RAZDUZIVANJE KARTICA")

      Maska()
      DO WHILE .T.

	 SetCursor(1)
	 READ
	 SetCursor(0)

	 IF LastKey() == 27
	    EXIT
	 ENDIF

	 nAlch = al_box("Zastupnik " + FMT0L(Str(Zaduz->zastup),4) + " prodao kartice " + ;
			"Ser: " + FMT0L(Str(nSer),3) + " " + FMT0L(Str(Zaduz->prva_slob),7) + "-" + FMT0L(Str(nRBK - 1),7) + " ukupno: " +;
			FMT0L(Str(nRBK - Zaduz->prva_slob), 7), 4, {" PREBACI "," PRODAO ZADNJU "," OK "," PREKID "}, 3, 9, 20, 17, 60)

	 DO CASE

	   CASE nAlch == 1	    && PREBACI

		Prebaci()
		Maska()
		KEYBOARD t_kart + Chr(13)
		LOOP

           CASE nAlch == 2          && PRODAO ZADNJU

		Razd->( dbAppend() )
		REPLACE Razd->zastup WITH Zaduz->zastup, ;
			Razd->serija WITH Zaduz->serija, ;
			Razd->kart   WITH nRBK + 1, ;
			Razd->od     WITH Zaduz->prva_slob, ;
			Razd->lps    WITH .F., ;
			Razd->obrada WITH .F.

		REPLACE Zaduz->prva_slob WITH nRBK + 1

		IF Zaduz->prva_slob >= Zaduz->do
		   REPLACE Zaduz->prva_slob WITH Zaduz->do, ;
			   Zaduz->status    WITH .F.
		ENDIF

		++t_ukup

		DoneBeep()

	   CASE nAlch == 3	    && OK

		Razd->( dbAppend() )
		REPLACE Razd->zastup WITH Zaduz->zastup, ;
			Razd->serija WITH Zaduz->serija, ;
			Razd->kart   WITH nRBK, ;
			Razd->od     WITH Zaduz->prva_slob, ;
			Razd->lps    WITH .T., ;
			Razd->obrada WITH .F.

		REPLACE Zaduz->prva_slob WITH nRBK + 1

		IF Zaduz->prva_slob >= Zaduz->do
		   REPLACE Zaduz->prva_slob WITH Zaduz->do, ;
			   Zaduz->status    WITH .F.
		ENDIF

		DoneBeep()

	   CASE nAlch == 4

	 ENDCASE

	 IF nAlch != 4
	    nUkupKar += t_ukup
	    cLast5 += " " + FMT0L(Str(t_ukup), 8)
	    DispLast5( cLast5 )
	 ENDIF

	 t_kart = Space(16)

	 GetList = aMyGet

      ENDDO

      win_rest(cOldScreen)
      vstk_pop()

      CLOSE ALL

RETURN NIL

STATIC FUNCTION Maska()

      @  9, 55 SAY "Ukupno:"
      @ 10, 55 SAY "Zastup:"
      @ 12, 10 SAY "Zast Ime                       ser       od       do   Ukupno"

      @  9, 10 SAY "Kartica:" GET t_kart PICTURE "999-9999999" VALID ChkKar(t_kart)

      aMyGet = GetList

RETURN NIL

STATIC FUNCTION ChkKar(ttt)

LOCAL lRetVal := .T.

      nSer = Val(ttt)
      nRBK = Val( SubStr(ttt, 5) )

      Zaduz->( dbSeek( FMT0L( Str(nSer), 4) + FMT0L( Str(nRBK), 8), .T. ) )

      IF !Zaduz->(Found())
	 Zaduz->( dbSkip(-1) )
      ENDIF

      IF ( nRBK >= Zaduz->prva_slob ) .AND. ( nRBK <= Zaduz->do )

	 Zastup->( dbSeek( Zaduz->zastup ) )

	 t_zastup = Zaduz->zastup
	 t_ime	  = padr( Left( AllTrim(Zastup->prezime) + " " + AllTrim(Zastup->ime), 25 ), 25, " ")
	 t_ser	  = Zaduz->serija
	 t_od	  = Zaduz->prva_slob
	 t_do	  = nRBK
	 t_ukup   = ( t_do - t_od )

	 cLast5 = Str(t_zastup, 4) + " " + t_ime + " " + FMT0L(Str(t_ser), 3) + " " +;
		  FMT0L(Str(t_od),8) + " " + FMT0L(Str(t_do),8)          && + " " + FMT0L(Str(t_ukup), 8)

	 FOR i = 1 TO Len(GetList)
	     GetList[i]:Display()
	 NEXT

      ELSE

	 alert("Karticu " + Left(ttt, 12) + " nije niko zaduzio!", {" OK "})
	 ErrBeep()
	 lRetVal = .F.

      ENDIF

RETURN lRetVal

FUNCTION DispLast5( cText )

LOCAL i   := 0, ;
      red := 13

      AIns( aLast5, 1 )

      ALast5[1] = cText

      vstk_push()
      SetColor("b/w")

      @  9, 63 SAY Str(nUkupKar, 8)
      @ 10, 63 SAY Str(GetZasUkup(Razd->zastup), 8)

      FOR i = 1 TO Len( aLast5 )
	  @ red, 10 SAY aLast5[i]
	  ++red
      NEXT

      vstk_pop()

RETURN NIL

FUNCTION PregRazd()

LOCAL i 	 := 0, ;
      t_ukup	 := 0, ;
      t_ukup_zas := 0, ;
      t_ukup_all := 0, ;
      lPrvi	 := .F., ;
      cOldScreen := "", ;
      t_od	 := 0, ;
      t_do	 := 0, ;
      ttt	 := 0, ;
      t_fakt	 := "N", ;
      nCntZas	 := 0, ;
      t_redbr	 := 1, ;
      nUkupPS	 := 0, ;
      nTempPS	 := 0

      USE Fond NEW VIA "SIXCDX"
      SET TAG TO BROJ
      GO TOP
      GO BOTTOM

      USE Zastup NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      USE Razd NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      IF Razd->(Bof()) .AND. Razd->(Eof())
	 alert("Baza razduzenja prazna!", {" OK "})
	 CLOSE ALL
	 RETURN NIL
      ENDIF

      vstk_push()
      cOldScreen = win_save(0, 0, 24, 79)

      WinStyle(7, 26, 12, 54, "PREGLED PRODATIH KARTICA")

      @  9, 28 SAY "Zastupnik od" GET t_od   PICTURE "9999"
      @  9, 46 SAY "do"           GET t_do   PICTURE "9999"
      @ 11, 28 SAY "Faktura:"     GET t_fakt PICTURE "@!X" VALID t_fakt $ "D_N"

      SetCursor(1)
      READ
      SetCursor(0)

      win_rest(cOldScreen)
      vstk_pop()

      IF LastKey() == 27
	 CLOSE ALL
	 RETURN NIL
      ENDIF

      IF Empty( t_od ) .AND. Empty( t_do )
	 t_od = 1
	 t_do = 9999
      ELSEIF Empty( t_od ) .AND. !Empty( t_do )
	 t_od = 1
      ELSEIF !Empty( t_od ) .AND. Empty( t_do )
	 t_do = t_od
      ENDIF

      Razd->( dbSeek( t_od, .T. ) )
      IF Razd->( Eof() ) .OR. Razd->zastup > t_do
	 ErrBeep()
	 alert("Nema podataka za unet broj zastupnika!", {" OK "})
	 CLOSE ALL
	 RETURN NIL
      ENDIF

      IniPtr()
      Prt1()
      Prt2()

      IF t_fakt = "N"
	 RazdHed(Fond->kolo)
      ENDIF

      DO WHILE Razd->zastup <= t_do .AND. !Razd->( Eof() )

	 IF t_fakt = "D"
	    RazdHed(Fond->kolo)
	 ENDIF

	 Zastup->( dbSeek( Razd->zastup ) )

	 ttt = Razd->zastup

	 ? Str(t_redbr,3) + "." + Space(1) + BoldON + Str( ttt, 4 ) + " " + padr( Left( AllTrim(Zastup->prezime) + " " + AllTrim(Zastup->ime), 25 ), 15, " " ) + BoldOFF
	 ++ t_redbr

	 t_ukup_zas = 0

	 lPrvi = .T.

	 DO WHILE Razd->zastup == ttt .AND. !Razd->( Eof() )

	    t_ukup = Razd->kart - Razd->od

	    IF lPrvi
	       lPrvi = .F.
	       ?? Space(1)
	    ELSE
	       ? Space(26)
	    ENDIF

	    ?? Str( Razd->serija, 3 ) + " " + Str( Razd->od, 8 ) + " " + ;
	       Str( Razd->kart - 1, 8 ) + " " + iif(Razd->lps, " 1", " 0") + " " + Str( Fond->cena, 4, 2 ) + " " + Str( t_ukup, 8 ) + "  " + ;
	       Str( t_ukup * Fond->Cena, 14, 2 )

	    t_ukup_zas += t_ukup

	    IF Razd->lps
	       ++nTempPS
	    ENDIF

	    Razd->( dbSkip() )

	 ENDDO

	 IF t_fakt == "D"
	    ? "********************************************************************************"
	    ? BoldON + Space(46) + Str(nTempPS,4) + Space(6) + Str( t_ukup_zas, 8 ) + "  " + Str( t_ukup_zas * nCena, 14, 2 ) + BoldOFF
	    ?
            ?
            ?
            ?

	    ++nCntZas
	    IF nCntZas % 4 == 0
	       ? NewPage
	    ENDIF

	 ENDIF

	 IF t_fakt == "N"
	    ? BoldON + Space(46) + Str(nTempPS, 4) + Space(6) + Str( t_ukup_zas, 8 ) + "  " + Str( t_ukup_zas * nCena, 14, 2 ) + BoldOFF
	 ENDIF

	 t_ukup_all += t_ukup_zas
	 nUkupPS += nTempPS
         nTempPS = 0

      ENDDO

      IF t_fakt = "N"
	 ? "********************************************************************************"
	 ? BoldON + Space(46) + Str(nUkupPS,4) + Space(6) + Str( t_ukup_all, 8 ) + "  " + Str( t_ukup_all * nCena, 14, 2 ) + BoldOFF
	 ?
	 ? "Ukupno presecnih kartica: " + BoldON + Str(nUkupPS, 5) + BoldOFF
      ENDIF

      Prt3()

      CLOSE ALL

RETURN NIL

FUNCTION PregRazdHis()

LOCAL i 	 := 0, ;
      t_ukup	 := 0, ;
      t_ukup_zas := 0, ;
      t_ukup_all := 0, ;
      lPrvi	 := .F., ;
      cOldScreen := "", ;
      t_od	 := 0, ;
      t_do	 := 0, ;
      ttt	 := 0, ;
      t_kolo	 := 0, ;
      nCntZas	 := 0, ;
      t_redbr	 := 1, ;
      nUkupPS	 := 0, ;
      nTempPS	 := 0

      USE Fond NEW VIA "SIXCDX"
      SET TAG TO BROJ
      GO TOP
      GO BOTTOM

      USE Zastup NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      USE RazdHis NEW VIA "SIXCDX" ALIAS Razd
      SET TAG TO kolo
      GO TOP

      IF Razd->(Bof()) .AND. Razd->(Eof())
	 alert("Baza razduzenja prazna!", {" OK "})
	 CLOSE ALL
	 RETURN NIL
      ENDIF

      vstk_push()
      cOldScreen = win_save(0, 0, 24, 79)

      WinStyle(7, 26, 12, 54, "PREGLED PRODATIH KARTICA")

      @  9, 28 SAY "Zastupnik od" GET t_od   PICTURE "9999"
      @  9, 46 SAY "do"           GET t_do   PICTURE "9999"
      @ 11, 28 SAY "Kolo:"     GET t_kolo PICTURE "9999"

      SetCursor(1)
      READ
      SetCursor(0)

      win_rest(cOldScreen)
      vstk_pop()

      IF LastKey() == 27
	 CLOSE ALL
	 RETURN NIL
      ENDIF

      IF Empty( t_od ) .AND. Empty( t_do )
	 t_od = 1
	 t_do = 9999
      ELSEIF Empty( t_od ) .AND. !Empty( t_do )
	 t_od = 1
      ELSEIF !Empty( t_od ) .AND. Empty( t_do )
	 t_do = t_od
      ENDIF

      Razd->( dbSeek( FMT0L( Str(t_kolo), 4), .T. ) )
      IF Razd->( Eof() )
	 ErrBeep()
	 alert("Nema podataka za trazeno kolo!", {" OK "})
	 CLOSE ALL
	 RETURN NIL
      ENDIF

      IniPtr()
      Prt1()
      Prt2()

      RazdHedHis(t_kolo)

      DO WHILE (Razd->kolo == t_kolo) .AND. (Razd->zastup <= t_do) .AND. (!Razd->( Eof() ))

	 Zastup->( dbSeek( Razd->zastup ) )

	 ttt = Razd->zastup

	 ? Str(t_redbr,3) + "." + Space(1) + BoldON + Str( ttt, 4 ) + " " + padr( Left( AllTrim(Zastup->prezime) + " " + AllTrim(Zastup->ime), 25 ), 15, " " ) + BoldOFF
	 ++ t_redbr

	 t_ukup_zas = 0

	 lPrvi = .T.

	 DO WHILE Razd->zastup == ttt .AND. !Razd->( Eof() )

	    t_ukup = Razd->kart - Razd->od

	    IF lPrvi
	       lPrvi = .F.
	       ?? Space(1)
	    ELSE
	       ? Space(26)
	    ENDIF

	    ?? Str( Razd->serija, 3 ) + " " + Str( Razd->od, 8 ) + " " + ;
	       Str( Razd->kart - 1, 8 ) + Space(2) + Str( t_ukup, 8 )

	    t_ukup_zas += t_ukup

	    /*
	    IF Razd->lps
	       ++nTempPS
	    ENDIF
	    */

	    Razd->( dbSkip() )

	 ENDDO

	 ? BoldON + Space(49) + Str( t_ukup_zas, 8 ) + BoldOFF

	 t_ukup_all += t_ukup_zas
	 nUkupPS += nTempPS
         nTempPS = 0

      ENDDO

      ? "********************************************************************************"
      ? BoldON + Space(49) + Str( t_ukup_all, 8 ) + BoldOFF

      Prt3()

      CLOSE ALL

RETURN NIL

STATIC FUNCTION RazdHed(nKolo)

      ? FontB + padl(DtoC( Date() ), 80, " ")
      ?
      ?
      ? BoldON + padc( "IZVESTAJ O PRODATIM KARTICAMA", 80, " " ) + BoldOFF
      ? padc("kolo: " + AllTrim(Str(nKolo)), 80, " ")
      ?
      ?
      ?
      ?

      ? "********************************************************************************"
      ? "Red  Zast Ime             Ser                   PS Cena   Ukupno          Ukupno"
      ? "br                                  od       do     din  kartica          dinara"
      ? "********************************************************************************"
      *  9999 9999 XXXXXXXXXXXXXXX 999 99999999 99999999 99 9999 99999999  99999999999.99


RETURN NIL

STATIC FUNCTION RazdHedHis(nKolo)

      ? FontB + padl(DtoC( Date() ), 80, " ")
      ?
      ?
      ? BoldON + padc( "IZVESTAJ O PRODATIM KARTICAMA", 80, " " ) + BoldOFF
      ? padc("kolo: " + AllTrim(Str(nKolo)), 80, " ")
      ?
      ?
      ?
      ?

      ? "*********************************************************"
      ? "Red  Zast Ime             Ser                      Ukupno"
      ? "br                                  od       do   kartica"
      ? "*********************************************************"
      * 9999 9999 XXXXXXXXXXXXXXX 999 99999999 99999999  99999999


RETURN NIL

FUNCTION RazdPrnX()

LOCAL i 	 := 0, ;
      nUkup	 := 0, ;
      nUkup1	 := 0

      IF al_box("Pregled nerazduzenih zaduzenja?", 2, {" DA "," NE "}, 2, 9, 20, 15, 60) == 2
	 RETURN NIL
      ENDIF

      USE Zastup NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      USE Razd	 NEW VIA "SIXCDX"
      SET TAG TO serod
      GO TOP

      IF Razd->(Bof()) .AND. Razd->(Eof())
	 alert("Baza razduzenja prazna!", {" OK "})
	 CLOSE ALL
	 RETURN NIL
      ENDIF

      USE Zaduz  NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      IniPtr()
      Prt1()
      Prt2()

      ? FontB + padl(DtoC( Date() ), 80, " ")
      ?
      ?
      ? BoldON + padc("NERAZDUZENA ZADUZENJA", 80, " ") + BoldOFF
      * ? padc("podcentar: " + AllTrim(IMECENTAR), 80, " ")
      ? padc("kolo: " + AllTrim(P_BRKOLO), 80, " ")
      ?
      ?

      ? "********************************************************************************"
      ? "Zast Ime               Mesto          Tel          ser       od       do  Ukupno"
      ? "********************************************************************************"
      * 9999 XXXXXXXXXXXXXXXXXXXX XXXXXXXXXXXXXXX XXXXXXXXXXXXXXX 999 99999999 99999999 9999999

      DO WHILE !Zaduz->( Eof() )

	 Zastup->( dbSeek( Zaduz->zastup ) )

	 IF Zaduz->status


	    Razd->( dbSeek( FMT0L( Str(Zaduz->serija), 4 ) + FMT0L( Str(Zaduz->prva_slob), 8 ), .T. ) )
	    IF !Razd->( Found() )

	       Razd->( dbSkip(-1) )
	       IF ( Razd->serija == Zaduz->serija ) .AND. ( Razd->od >= Zaduz->od );
		  .AND. ( Razd->kart <= Zaduz->do )
	       ELSE

		  nUkup = Int( ( ( Zaduz->do - Zaduz->prva_slob ) + 1 ) )

		  ? FMT0L( Str(Zaduz->zastup), 4 ) + " " + padr( Left( AllTrim(Zastup->prezime) + " " + AllTrim(Zastup->ime), 17 ), 17, " " ) + " " +;
		    Left( Zastup->mesto, 14 ) + " " + Left( Zastup->tel, 12 ) + " " + ;
		    FMT0L( Str(Zaduz->serija), 3 ) + " " + FMT0L(Str(Zaduz->prva_slob),8) + " " + ;
		    FMT0L(Str(Zaduz->do),8) + Space(1) + Str(nUkup, 7, 0)

		  nUkup1 += nUkup

	       ENDIF

	    ENDIF

	 ENDIF

	 Zaduz->( dbSkip() )

      ENDDO

      ? "********************************************************************************"
      ? Space(72) + Str(nUkup1, 8, 0)

      Prt3()

      CLOSE ALL

RETURN NIL

FUNCTION ChgRazd()

LOCAL cOldScreen := ""

PRIVATE t_brzas := 0, ;
	t_ime	:= Space(28), ;
	aRazd	:= {}, ;
	aRec	:= {}, ;
	aMyGet	:= {}

      USE Zastup NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      USE Zaduz NEW VIA "SIXCDX"
      SET TAG TO serod
      GO TOP

      USE Razd NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      vstk_push()
      cOldScreen = win_save( 0, 0, 24, 79 )

      WinStyle( 6, 22, 20, 58, "PONISTAVANJE RAZDUZENJA" )

      BEGIN SEQUENCE

      Maska1()
      DO WHILE .T.

	 SetCursor(1)
	 READ
	 SetCursor(0)

	 IF LastKey() == 27
	    BREAK
	 ENDIF

	 nChoice = AChoice( 15, 24, 19, 56, aRazd )

	 IF nChoice != 0

	    Razd->( dbGoTo( aRec[ nChoice ] ) )

	    * izmena razduzenja
	    Zaduz->( dbSeek( FMT0L(Str(Razd->serija),4) + FMT0L(Str(Razd->od),8), .T. ) )

	    IF !Zaduz->( Found() )
	       Zaduz->( dbSkip(-1) )
	    ENDIF

	    IF Zaduz->serija == Razd->serija .AND. ( Razd->od >= Zaduz->od .AND. Razd->od <= Zaduz->do )

	       REPLACE Zaduz->prva_slob WITH Razd->od

	       IF Zaduz->prva_slob < Zaduz->do
		  REPLACE Zaduz->status WITH .T.
	       ENDIF

	    ELSE

	       Zaduz->( dbAppend() )

* Zaduz->do	   WITH Razd->kart - 1, ;

	       REPLACE Zaduz->zastup	WITH Razd->zastup, ;
		       Zaduz->serija	WITH Razd->serija, ;
		       Zaduz->od	WITH Razd->od, ;
		       Zaduz->prva_slob WITH Razd->od, ;
		       Zaduz->datum	WITH Date(), ;
		       Zaduz->status	WITH .T.

	       IF !Razd->lps
		  REPLACE Zaduz->do WITH Razd->kart - 1
	       ELSE
		  REPLACE Zaduz->do WITH Razd->kart + 4
	       ENDIF

	    ENDIF

	    Razd->( dbDelete() )

	    DoneBeep()

	 ENDIF

	 GetList = aMyGet

	 aRazd	 := {}
	 aRec	 := {}
	 t_brzas := 0
	 t_ime	 := Space(28)

	 GetList[1]:Display()
         GetList[2]:Display()

	 @ 15, 24 CLEAR TO 19, 56

      ENDDO

      END SEQUENCE

      win_rest( cOldScreen )
      vstk_pop()

      CLOSE ALL

RETURN NIL

STATIC FUNCTION Maska1()

      @  8, 24 SAY "Zastupnik:" GET t_brzas PICTURE "9999" VALID ChkZas( t_brzas )
      @ 10, 24 SAY "Ime:"       GET t_ime   PICTURE "XXXXXXXXXXXXXXXXXXXXXXXXXXXX" WHEN .F.

      vstk_push()
      SetColor("w/n")
      @ 12, 22 CLEAR TO 12, 58
      @ 12, 24 SAY "LISTA RAZDUZENJA"
      vstk_pop()

      @ 14, 24 SAY "Ser        od        do    ukupno"

      aMyGet = GetList

RETURN NIL

STATIC FUNCTION ChkZas( ttt )

LOCAL lRetVal := .T., ;
      oGet    := GetActive(), ;
      cTemp   := ""

      IF Empty( ttt )
	 RETURN .F.
      ENDIF

      Zastup->( dbSeek( ttt ) )
      IF !Zastup->( Found() )
	 ErrBeep()
	 alert("Zastupnik br. " + AllTrim(Str(ttt)) + " ne postoji!", {" OK "})
	 RETURN .F.
      ENDIF

      t_ime = padr( Left( AllTrim(Zastup->prezime) + " " + AllTrim(Zastup->ime), 28 ), 28, " " )
      GetList[2]:Display()

      Razd->( dbSeek( ttt ) )
      IF !Razd->( Found() )
	 ErrBeep()
	 alert("Zastupnik br. " + AllTrim(Str(ttt)) + " nije nista razduzio!", {" OK "})
      ENDIF

      DO WHILE Razd->zastup == t_brzas .AND. !Razd->( Eof() )

	 cTemp = FMT0L( Str( Razd->serija ), 3 ) + "  " +;
		 FMT0L( Str( Razd->od ), 8 )	 + "  " +;
		 FMT0L( Str( Razd->kart - 1 ), 8 )     + "  " +;
		 FMT0L( Str( Razd->kart - Razd->od ), 8 )

	 aadd( aRazd, cTemp )
	 aadd( aRec , Razd->( RecNo() ) )

	 Razd->( dbSkip() )

      ENDDO

RETURN lRetVal

STATIC FUNCTION Ukup()

LOCAL nRet    := 0

      GO TOP
      DO WHILE !Razd->( Eof() )

	 nRet += Razd->kart - Razd->od

	 Razd->( dbSkip() )

      ENDDO

RETURN nRet

FUNCTION Prebaci()

 Local t_brzas	  := 0, ;
       t_serija   := 0, ;
       t_od	  := 0, ;
       t_do	  := 0, ;
       cOldScreen := "", ;
       t_save_zas := 0,;
       t_save_ser := 0, ;
       t_save_od  := 0, ;
       t_save_do  := 0, ;
       t_menu	  := 0, ;
       lRetVal	  := .f.,;
       nBlok	  := 0

     vstk_push()
     cOldScreen := win_save( 0, 0, 24, 79 )

     BEGIN SEQUENCE

     t_save_zas := Zaduz->zastup
     t_save_ser := Zaduz->serija
     t_save_od	:= Zaduz->od
     t_save_do	:= Zaduz->do

     nBlok := Int((nRBK - 1) / 1000) + 1
     t_od := ((nBlok - 1) * 1000) + 1
     t_do := t_od + 999

     if t_od < Zaduz->prva_slob
       t_od := Zaduz->prva_slob
     endif

     if t_do > Zaduz->do
       t_do := Zaduz->do
     endif

     WinStyle( 9, 14, 18, 66, "ZADUZI & RAZDUZI (" + FMT0L(Str(nSer),3) + "/" + FMT0L(Str(nRBK),8) + ")", Col_Win1 )
     @ 11, 16 SAY "Zastupnik: " + FMT0L(Str(Zaduz->zastup),4)
     @ 12, 16 SAY FMT0L(Str(Zaduz->serija), 3) + Space(2) + "od: " + Str(Zaduz->prva_slob, 8) + Space(2) + "do: " + Str(Zaduz->do, 8) + Space(2) + "Ukupno: " + Str((Zaduz->do - Zaduz->prva_slob) + 1, 8)

     @ 14, 16 SAY "Prebaci na zastupnika:" GET t_brzas PICTURE "9999" VALID ChkZas1(t_brzas)
     @ 15, 16 SAY FMT0L(Str(Zaduz->serija), 3)
     @ 15, 21 SAY "od:" GET t_od PICTURE "99999999" VALID (t_od >= Zaduz->prva_slob)
     @ 15, 35 SAY "do:" GET t_do PICTURE "99999999" VALID (t_do > t_od) .and. (t_do <= Zaduz->do)
     @ 15, 49 SAY "ukupno: " + Str((t_do - t_od) + 1, 8)

     SetCursor(1)
     READ
     SetCursor(0)

     IF LastKey() == 27
	BREAK
     ENDIF

     DO WHILE .T.

	@ 17, 26 PROMPT "PREBACI"
	@ 17, 48 PROMPT "PREKID"

	MENU TO t_menu

	IF t_Menu != 0
	   EXIT
	ENDIF

     ENDDO

     IF t_Menu == 1

       REPLACE Zaduz->do     WITH t_od - 1, ;
	       Zaduz->status WITH iif(Zaduz->prva_slob >= (t_od - 1), .f., .t.)

       IF ( t_do < t_save_do )
	 Zaduz->( dbAppend() )
	 REPLACE Zaduz->zastup	  WITH t_save_zas, ;
		 Zaduz->serija	  WITH t_save_ser, ;
		 Zaduz->od	  WITH t_do + 1,   ;
		 Zaduz->do	  WITH t_save_do,  ;
		 Zaduz->datum	  WITH Date(),	   ;
		 Zaduz->prva_slob WITH t_do + 1,   ;
		 Zaduz->status	  WITH .T.
       ENDIF

       Zaduz->( dbAppend() )
       REPLACE Zaduz->zastup	WITH t_brzas,	    ;
	       Zaduz->serija	WITH t_save_ser,    ;
	       Zaduz->od	WITH t_od,	    ;
	       Zaduz->do	WITH t_do,	    ;
	       Zaduz->datum	WITH Date(),	    ;
	       Zaduz->prva_slob WITH t_od,	    ;
	       Zaduz->status	WITH .T.

       DoneBeep()
       lRetVal := .t.

   ENDIF

   END SEQUENCE

   win_rest( cOldScreen )
   vstk_pop()

RETURN lRetVal

FUNCTION GetZasUkup(t_brzas)

 Local nUkup   := 0, ;
       nOldPos := Razd->(RecNo())

  Razd->(dbSeek(t_brzas))
  IF Razd->(Found())

    DO WHILE (Razd->zastup == t_brzas) .and. !Razd->(Eof())
      nUkup += (Razd->kart - Razd->od)
      Razd->(dbSkip())
    ENDDO

    Razd->(dbGoTo(nOldPos))

  ENDIF

RETURN nUkup
