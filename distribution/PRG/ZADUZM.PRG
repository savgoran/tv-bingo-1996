#include "sixcdx.ch"
#include "machsix.ch"
#include "commands.ch"
#include "inkey.ch"

FUNCTION UnZad()

LOCAL cOldScreen := ""

PRIVATE nNextOd := 0, ;
	nNextDo := 0

PRIVATE aGet	:= {}, ;
	t_brzas := 0 , ;
	t_datum := Date(), ;
	t_od	:= 0, ;
	t_do	:= 0, ;
	t_ime	:= Space(25), ;
	t_mesto := Space(20)

      USE Serija NEW VIA "SIXCDX"
      SET TAG TO broj
      GO TOP

      DO WHILE !Serija->(Eof())
	 IF Serija->status == '1'
	    EXIT
	 ENDIF
	 Serija->(dbSkip())
      ENDDO

      IF Serija->(Eof())
	 ErrBeep()
	 al_box("Nema kartica za zaduzenje!", 1, {" OK "}, 1, 9, 20, 15, 60)
	 CLOSE ALL
	 RETURN NIL
      ENDIF

      USE Zastup NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      USE Zaduz NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      SET RELATION TO zastup INTO Zastup
      GO TOP

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(4, 17, 20, 64, "ZADUZIVANJE ZASTUPNIKA")

      Mask()
      DO WHILE .T.

	 SetCursor(1)
	 READ
	 SetCursor(0)

	 IF LastKey() = K_ESC
	    EXIT
	 ENDIF

	 IF al_box("Zaduzujete zastupnika br. " + AllTrim(Str(t_brzas)) + " sa blokom od " + Str(t_od,7) + " do " + Str(t_do,7) + "?", 2, {" DA "," NE "}, 2, 9, 20, 17, 60) = 1
	    StoreVal()
	    DoneBeep()
	 ENDIF

	 OldZad()

	 GetList = aGet
	 ResetVar(.F.)

      ENDDO

      win_rest(cOldScreen)
      vstk_pop()

      SET RELATION TO
      CLOSE ALL

RETURN NIL

STATIC FUNCTION Mask()

      vstk_push()
      SetColor("w/n")
      @ 13,19 clear to 13,62
      @ 13,20 SAY "STARA ZADUZENJA"
      vstk_pop()

      vstk_push()
      SetColor("w+/b")
      @ 15,19 clear to 15,62
      @ 15,19 SAY "Datum      ser       od        do     ostalo"
      vstk_pop()

      @  6, 19 SAY "Broj zastupnika:" GET t_brzas PICTURE "@K 9999" VALID ChkZasBr(t_brzas)
      @  6, 48 SAY "Datum:" GET t_datum PICTURE "99/99/99"
      @  8, 19 SAY "Novo zaduzenje od " GET t_od PICTURE "9999999" WHEN .F.
      @  8, Col()+2 SAY "do" GET t_do PICTURE "9999999" VALID ChkDo(t_do)
      @ 10, 19 SAY "Prezime i ime:" GET t_ime PICTURE "XXXXXXXXXXXXXXXXXXXXXXXXX" WHEN .F. COLOR "n+/w, n/w"
      @ 11, 19 SAY "Mesto:        " GET t_mesto PICTURE "XXXXXXXXXXXXXXXXXXXX" WHEN .F. COLOR "n+/w, n/w"

      aGet = GetList

RETURN NIL

STATIC FUNCTION StoreVal()

      Zaduz->(dbAppend())

      REPLACE Zaduz->zastup    WITH t_brzas, ;
	      Zaduz->datum     WITH t_datum, ;
	      Zaduz->serija    WITH Serija->broj, ;
              Zaduz->od        WITH t_od, ;
	      Zaduz->do        WITH t_do, ;
	      Zaduz->prva_slob WITH t_od, ;
	      Zaduz->status    WITH .T.

      REPLACE Serija->prva_slob WITH Zaduz->do + 1

      IF Serija->status == '0'
	 REPLACE Serija->status WITH '1'
      ENDIF

      IF t_do == Serija->do
	 REPLACE Serija->status WITH '2'
	 NxtSerZad()
      ENDIF

RETURN NIL

STATIC FUNCTION ResetVar(opc)

LOCAL i := 0

      DEFAULT opc TO .F.

      IF opc
	 t_brzas := 0
      ENDIF

      t_datum := Date()
      t_od    := 0
      t_do    := 0
      t_ime   := Space(25)
      t_mesto := Space(20)

      FOR i = 1 TO Len(GetList)
	  GetList[i]:Display()
      NEXT

RETURN NIL

STATIC FUNCTION ChkZasBr(ttt)

LOCAL RetVal := .T., ;
      oGet   := GetActive()

      IF Empty(ttt)
	 RETURN .F.
      ENDIF

      Zastup->(dbSeek(ttt))

      IF !Zastup->(Found())

	 ErrBeep()
	 al_box("Zastupnik broj " + Str(ttt,4) + " ne postoji!", 1, {" OK "}, 1, 9, 20, 15, 60)
	 oGet:buffer = Space(4)
	 oGet:Assign()
	 oGet:Display()
	 RetVal = .F.

      ELSE

	 t_ime	 = padr(Left(AllTrim(Zastup->prezime) + " " + AllTrim(Zastup->ime), 25), 25, " ")
	 t_mesto = Zastup->mesto

	 GetList[5]:Display()
	 GetList[6]:Display()

	 OldZad()

	 IF !GetNext()
	    ErrBeep()
	    al_box("Nema vise kartica za zaduzenje!", 1, {" OK "}, 1, 9, 25, 15, 55)
	 ENDIF

	 t_od = nNextOd

	 * t_od = 0
	 t_do = 0

	 GetList[3]:Display()
	 GetList[4]:Display()

      ENDIF

RETURN RetVal

STATIC FUNCTION OldZad()

LOCAL aOldZad := {}, ;
      red     := 0, ;
      i       := 0

      Zaduz->( dbSeek(t_brzas) )

      IF Zaduz->(Found())

	 DO WHILE Zaduz->zastup == t_brzas

	    IF Zaduz->status
	       aadd( aOldZad, {DtoC(Zaduz->datum), FMT0L(Str(Zaduz->serija), 4), FMTBLL(Str(Zaduz->prva_slob), 8), FMTBLL(Str(Zaduz->do), 8), FMTBLL(Str( ((Zaduz->do - Zaduz->prva_slob) + 1) ), 8)} )
	    ENDIF

	    Zaduz->(dbSkip())

	 ENDDO

      ENDIF

      IF !Empty( aOldZad )

	 red = 16
	 FOR i = 1 TO 5
	     IF i <= Len(aOldZad)
		@ red, 19 SAY aOldZad[i,1] + Space(2) + aOldZad[i,2] + Space(1) + aOldZad[i,3] + Space(2) + aOldZad[i,4] + Space(3) + aOldZad[i,5]
	     ELSE
		@ red, 19 SAY Space(40)
	     ENDIF
	     ++red
	 NEXT

      ENDIF

RETURN NIL

STATIC FUNCTION GetNext(ttt)

LOCAL lRetVal := .T.

      nNextOd = Serija->prva_slob

RETURN lRetVal

FUNCTION PrZad1()

LOCAL nUkup1 := 0, ;
      nUkup2 := 0, ;
      nt1    := 0, ;
      t_brzas := 0

      IF al_box("Pregled zaduzenih kartica?", 2, {" DA "," NE "}, 2, 9, 20, 16, 60) = 2
	 RETURN NIL
      ENDIF

      USE Zastup NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      USE Zaduz NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      SET RELATION TO brzas INTO Zastup
      GO TOP

      IniPtr()
      Prt1()
      Prt2()

      ? padc("PREGLED NEPRODATIH TOMBOLSKIH KARTICA PO ZASTUPNICIMA",80," ")
      ?

      ? Replicate("*", 80)
      ? "Br.   Prezime i ime              Mesto                Adresa"
      ? Replicate("*", 80)

      DO WHILE !Eof()

	 ?
	 ? FMT0L(Str(Zastup->brzas),4) + Space(2) + padr( Left(AllTrim(Zastup->prezime) + " " + AllTrim(Zastup->ime), 25), 25, " ") + Space(2) + Zastup->mesto + Space(1) + Left(Zastup->adresa,20)
	 ?

	 ? Space(41) + "datum        od        do        ostalo"

	 t_brzas = Zaduz->brzas

	 DO WHILE (Zaduz->brzas == t_brzas) .AND. !Zaduz->(Eof())

	    IF Zaduz->status

	       nt1 = Int( ( ( Zaduz->do - Zaduz->prva_slob ) + 1 ) / 2 )

	       ? Space(38) + DtoC(Zaduz->datum) + "  " + Str(Zaduz->prva_slob,8) + ;
		 "  " + Str(Zaduz->do) + "     " + Str( nt1, 9)

	    ENDIF

	    nUkup1 += nt1
	    nt1 = 0

	    SKIP

	 ENDDO

	 ? Space(38) + "=========================================="
	 ? Space(38) + "Ukupno neprodatih kartica        " + Str(nUkup1, 9)
	 ? Space(38) + "=========================================="

	 nUkup2 += nUkup1
	 nUkup1 = 0

      ENDDO

      ? Replicate("*", 80)
      ? Space(71) + Str(nUkup2, 9)

      Prt3()

      CLOSE ALL

RETURN NIL

FUNCTION PrZad2()

LOCAL cOldScreen := "", ;
      t_brzas	 := 0, ;
      t_datum	 := CtoD("  /  /  "), ;
      nUkup1	 := 0, ;
      nUkup2	 := 0, ;
      nUkup3	 := 0, ;
      nt1	 := 0, ;
      t_brzas1	 := 0, ;
      brojac	 := 0

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(7, 25, 12, 51, "PREGLED ZADUZENJA")

      @  9, 27 SAY "Zastupnik br.:" GET t_brzas PICTURE "9999"
      @ 11, 27 SAY "Datum        :" GET t_datum PICTURE "99/99/99"

      SetCursor(1)
      READ
      SetCursor(0)

      win_rest(cOldScreen)
      vstk_pop()

      IF LastKey() == K_ESC
	 RETURN NIL
      ENDIF

      USE Zastup NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      IF !Empty(t_brzas)
	 Zastup->(dbSeek( t_brzas ))
	 IF !Zastup->(Found())
	    ErrBeep()
	    al_box("Zastupnik br. " + Str(t_brzas,4) + " ne postoji!", 1, {" OK "}, 1, 9, 20, 15, 60)
	    CLOSE ALL
	    RETURN NIL
	 ENDIF
      ENDIF

      USE Zaduz NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      IF !Empty(t_brzas)
	 Zaduz->(dbSeek( FMT0L(Str(t_brzas), 4) ))
	 IF !Zaduz->(Found())
	    ErrBeep()
	    al_box("Zastupnik br. " + Str(t_brzas,4) + " nije nista zaduzio!", 1, {" OK "}, 1, 9, 20, 16, 60)
	    CLOSE ALL
	    RETURN NIL
	 ENDIF
      ENDIF

      IniPtr()
      Prt1()
      Prt2()

      * ? padc("ZADUZENJE TOMBOLSKIH KARTICA PO ZASTUPNICIMA",80," ")

      IF !Empty(t_brzas)
      *   ? padc("zastupnik br. " + Str(t_brzas, 4), 80, " ")
	 Zaduz->(dbSeek( FMT0L(Str(t_brzas),4) ))
      ENDIF

      IF !Empty(t_datum)
	 ? padc("za datum :" + DtoC(t_datum), 80, " ")
      ENDIF

      ?

      * ? "********************************************************************************"
      * ? "Broj   Datum          Serije                        Ukupno                      "
      * ? "zas.                   od        do    kartica     kartica       Dinara         "
      * ? "********************************************************************************"

      DO WHILE !Eof()

	 IF !Empty(t_brzas)
	    IF Zaduz->brzas != t_brzas
	       EXIT
	    ENDIF
	 ENDIF

	 Zastup->(dbSeek(Zaduz->brzas))

	 ? padl("Datum: " + DtoC(Date()),80," ")
	 ?

	 ? padc("ZADUZENJE TOMBOLSKIH KARTICA",80," ")
	 ? padc("zastupnik br. " + Str(Zastup->brzas, 4) + " - " + AllTrim(Zastup->prezime) + " " + AllTrim(Zastup->ime), 80, " ")
	 ?

	 ? "********************************************************************************"
	 ? "Broj   Datum     Ser   Red.broj                           Ukupno                "
	 ? "zas.                         od        do    kartica     kartica       Dinara   "
	 ? "********************************************************************************"

	 t_brzas1 = Zaduz->brzas

	 DO WHILE (Zaduz->brzas == t_brzas1) .AND. !Zaduz->(Eof())

	    IF !Empty(t_datum)
	       IF Zaduz->datum != t_datum
		  SKIP
		  LOOP
	       ENDIF
	    ENDIF

	    IF Zaduz->status

	       nt1 = Int(((Zaduz->do - Zaduz->prva_slob)+1)/2)

	       ? FMT0L(Str(Zaduz->brzas), 4) + Space(3) + DtoC(Zaduz->datum) + Space(2) + FMT0L(Str(Zaduz->serija,4),4) + Space(2) +;
		 Str(Zaduz->prva_slob,8) + Space(2) + Str(Zaduz->do) + Space(3) + Str( nt1, 8)

	    ENDIF

	    nUkup1 += nt1
	    nt1 = 0

	    SKIP

	 ENDDO

	 Zastup->(dbSeek(t_brzas1))

	 ? "Ime: " + padr( Left(AllTrim(Zastup->prezime) + " " + AllTrim(Zastup->ime), 25), 25, " ") + Space(26) + Str(nUkup1,8) + Space(3) + Str(nUkup1 * nCena,10,2)

	 nUkup2 += nUkup1
	 nUkup1 = 0

	 ? "********************************************************************************"
	 ? Space(56) + Str(nUkup2, 8) + Space(3) + Str(nUkup2 * nCena, 10, 2)

	 nUkup3 += nUkup2
	 nUkup2 = 0

	 ++brojac
	 IF (brojac % 3) == 0
	    brojac = 0
	    ? NewPage
	 ELSE
	   ?
	   ?
	   ?
	   ?
	   ?
	   ?
	 ENDIF

      ENDDO

      ? "********************************************************************************"
      ? Space(50) + Str(nUkup3, 8) + Space(3) + Str(nUkup3 * nCena, 10, 2)

      Prt3()

      CLOSE ALL

RETURN NIL

FUNCTION PrZad3()

LOCAL cOldScreen := "", ;
      t_brzas	 := 0, ;
      t_datum	 := CtoD("  /  /  "), ;
      nUkup1	 := 0, ;
      nUkup2	 := 0, ;
      nUkup3	 := 0, ;
      nt1	 := 0, ;
      t_brzas1	 := 0, ;
      brojac	 := 0

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(7, 25, 12, 51, "PREGLED ZADUZENJA")

      @  9, 27 SAY "Zastupnik br.:" GET t_brzas PICTURE "9999"
      @ 11, 27 SAY "Datum        :" GET t_datum PICTURE "99/99/99"

      SetCursor(1)
      READ
      SetCursor(0)

      win_rest(cOldScreen)
      vstk_pop()

      IF LastKey() == K_ESC
	 RETURN NIL
      ENDIF

      USE Zastup NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      IF !Empty(t_brzas)
	 Zastup->(dbSeek( t_brzas ))
	 IF !Zastup->(Found())
	    ErrBeep()
	    al_box("Zastupnik br. " + Str(t_brzas,4) + " ne postoji!", 1, {" OK "}, 1, 9, 20, 15, 60)
	    CLOSE ALL
	    RETURN NIL
	 ENDIF
      ENDIF

      USE Zaduz NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      IF !Empty(t_brzas)
	 Zaduz->(dbSeek( FMT0L(Str(t_brzas), 4) ))
	 IF !Zaduz->(Found())
	    ErrBeep()
	    al_box("Zastupnik br. " + Str(t_brzas,4) + " nije nista zaduzio!", 1, {" OK "}, 1, 9, 20, 16, 60)
	    CLOSE ALL
	    RETURN NIL
	 ENDIF
      ENDIF

      IniPtr()
      Prt1()
      Prt2()

      ? padl("Datum : " + DtoC(Date()), 80, " ")
      ?
      ? padc("ZADUZENJE TOMBOLSKIH KARTICA",80," ")
      IF !Empty(t_brzas)
	 ? padc("zastupnik br. " + Str(t_brzas, 4), 80, " ")
         Zaduz->(dbSeek( FMT0L(Str(t_brzas),4) ))
      ENDIF


      IF !Empty(t_datum)
	 ? padc("za datum :" + DtoC(t_datum), 80, " ")
      ENDIF

      ?

      ? "********************************************************************************"
      ? "Broj   Datum     Ser   Red.broj                           Ukupno                "
      ? "zas.                         od        do    kartica     kartica       Dinara   "
      ? "********************************************************************************"

      DO WHILE !Eof()

         IF !Empty(t_brzas)
            IF Zaduz->brzas != t_brzas
               EXIT
            ENDIF
         ENDIF

	 Zastup->(dbSeek(Zaduz->brzas))

	 t_brzas1 = Zaduz->brzas

	 DO WHILE (Zaduz->brzas == t_brzas1) .AND. !Zaduz->(Eof())

	    IF !Empty(t_datum)
	       IF Zaduz->datum != t_datum
		  SKIP
		  LOOP
	       ENDIF
	    ENDIF

	    IF Zaduz->status

	       nt1 = Int(((Zaduz->do - Zaduz->prva_slob)+1)/2)

	       ? FMT0L(Str(Zaduz->brzas), 4) + Space(3) + DtoC(Zaduz->datum) + Space(2) + FMT0L(Str(Zaduz->serija,4),4) + Space(2) +;
		 Str(Zaduz->prva_slob,8) + Space(2) + Str(Zaduz->do) + Space(3) + Str( nt1, 8)

	    ENDIF

	    nUkup1 += nt1
	    nt1 = 0

	    SKIP

	 ENDDO

	 ? padr(Left(AllTrim(Zastup->prezime) + " " + AllTrim(Zastup->ime),25),25," ") + Space(31) + Str(nUkup1, 8) + Space(3) + Str(nUkup1 * nCena, 10, 2)

	 Zastup->(dbSeek(t_brzas1))

	 nUkup2 += nUkup1
	 nUkup1 = 0

      ENDDO

      ? "********************************************************************************"
      ? Space(56) + Str(nUkup2, 8) + Space(3) + Str(nUkup2 * nCena, 10, 2)

      Prt3()

      CLOSE ALL

RETURN NIL

FUNCTION ChkDo(ttt)

LOCAL RetVal := .T.

/*
      IF (ttt % 1000) != 0
	 ErrBeep()
	 al_box("Blok se mora zavrsavati brojem koji je deljiv sa 1000!",1,{" OK "},1,9,20,16,60)
	 RETURN .F.
      ENDIF
*/

      IF ttt <= t_od
	 ErrBeep()
	 al_box("Broj kartice mora da bude veci!",1,{" OK "},1,9,20,16,60)
	 RETURN .F.
      ENDIF

      IF ttt > Serija->zad_slob
	 ErrBeep()
	 al_box("U seriji " + Str(Serija->broj,4) + " nema toliko slobodnih kartica!", 1, {" OK "}, 1, 9, 20, 16, 60)
	 RETURN .F.
      ENDIF

RETURN RetVal

/*
FUNCTION PrLis1(nSer, nRBK)

LOCAL cPath := "", ;
      nOldSel := Select()

	 USE Serija NEW VIA "SIXCDX"
	 SET TAG TO broj
	 GO TOP

	 Serija->(dbSeek(nSer))
	 IF !Serija->(Found())
	    ? "Nema serije za zadatu karticu!"
	    RETURN NIL
	 ENDIF

	 cPath = AllTrim(Serija->path) + "listic.dbf"

	 USE &(cPath) NEW VIA "SIXCDX" PASSWORD "[REDACTED]"
	 TGoTop()

	 TGoTo(nRBK)

	 ? "Serija: " + FMT0L(Str(nSer),3) + " red.br.: " + FMT0L(str(Listic->(TRecNo())),8) + " phy: " + FMT0L(str(RecNo()),7)

	 ?

	 for i = 1 to 27 step 3
	     nn = Asc(substr(Listic->sadrzaj,i,1))
	     ?? iif(nn=126,"--",FMT0L(Str(nn,2),2)) + "  "
	 next

	 ?

	 for i = 2 to 27 step 3
	     nn = Asc(substr(Listic->sadrzaj,i,1))
	     ?? iif(nn=126,"--",FMT0L(Str(nn,2),2)) + "  "
	 next

	 ?

	 for i = 3 to 27 step 3
	     nn = Asc(substr(Listic->sadrzaj,i,1))
	     ?? iif(nn=126,"--",FMT0L(Str(nn,2),2)) + "  "
	 next

	 CLOSE Listic
	 CLOSE Serija

	 Select(nOldSel)

RETURN NIL
*/

FUNCTION PregZad()

LOCAL i 	 := 0, ;
      t_ukup	 := 0, ;
      t_ukup_zas := 0, ;
      t_ukup_all := 0, ;
      lPrvi	 := .F., ;
      cOldScreen := "", ;
      t_od	 := 0, ;
      t_do	 := 0, ;
      t_fakt	 := "N", ;
      t_ser	 := 0, ;
      nCntZas	 := 0

      USE Fond	 NEW VIA "SIXCDX"
      SET TAG TO kolo
      GO BOTTOM

      IF Fond->status
	 alert("Kolo nije otvoreno!", {" OK "})
	 CLOSE ALL
	 RETURN NIL
      ENDIF

      USE Zastup NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      USE Zaduz  NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      vstk_push()
      cOldScreen = win_save(0, 0, 24, 79)

      WinStyle(7, 26, 13, 54, "PREGLED ZADUZENJA")

      @  9, 28 SAY "Zastupnik od" GET t_od   PICTURE "9999"
      @  9, 46 SAY "do"           GET t_do   PICTURE "9999"
      @ 10, 28 SAY "Serija:"      GET t_ser  PICTURE "999"
      @ 12, 28 SAY "Faktura:"     GET t_fakt PICTURE "@!X" VALID t_fakt $ "D_N"

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

      Zaduz->( dbSeek( t_od, .T. ) )
      IF Zaduz->( Eof() ) .OR. Zaduz->zastup > t_do
	 ErrBeep()
	 alert("Nema podataka za unet broj zastupnika!", {" OK "})
	 CLOSE ALL
	 RETURN NIL
      ENDIF

      IniPtr()
      Prt1()
      Prt2()

      IF t_fakt == "N"
	 ZadHed()
      ENDIF

      DO WHILE Zaduz->zastup <= t_do .AND. !Zaduz->( Eof() )

	 IF t_fakt == "D"
	    ZadHed()
	 ENDIF

	 Zastup->( dbSeek( Zaduz->zastup ) )
	 ? BoldON + Str( Zastup->brzas, 4 ) + " " + padr( Left( AllTrim(Zastup->prezime) + " " + AllTrim(Zastup->ime), 25 ), 25, " " ) + BoldOFF

	 t_ukup_zas = 0

	 lPrvi = .T.

	 DO WHILE Zaduz->zastup == Zastup->brzas .AND. !Zaduz->( Eof() )

	    IF Zaduz->status

	       IF t_ser > 0
		 IF Zaduz->serija != t_ser
		   Zaduz->( dbSkip() )
		   LOOP
		 ENDIF
	       ENDIF

	       t_ukup = ( Zaduz->do - Zaduz->prva_slob ) + 1

	       IF lPrvi
		  lPrvi = .F.
		  ?? Space(1)
	       ELSE
		  ? Space(31)
	       ENDIF

	       ?? Str( Zaduz->serija, 3 ) + " " + Str( Zaduz->prva_slob, 8 ) + "  " + ;
		  Str( Zaduz->do, 8 ) + "  " + Str( Fond->cena, 4, 2 ) + "  " + Str( t_ukup, 8 ) + "  " + ;
		  Str( t_ukup * Fond->cena, 14, 2 )

	       t_ukup_zas += t_ukup

	    ENDIF

	    Zaduz->( dbSkip() )

	 ENDDO

	 IF t_fakt == "D"
	    ? "*************************************************************************************"
	    ? BoldON + Space(61) + Str( t_ukup_zas, 8 ) + "  " + Str( t_ukup_zas * Fond->cena, 14, 2 ) + BoldOFF
	    ?
            ?
            ?
            ?

	    ++nCntZas
	    IF nCntZas % 4 == 0
	       ? NewPage
	    ENDIF

	 ENDIF

	 IF t_fakt = "N"
	    ? BoldON + Space(61) + Str( t_ukup_zas, 8 ) + "  " + Str( t_ukup_zas * Fond->cena, 14, 2 ) + BoldOFF
	 ENDIF

	 t_ukup_all += t_ukup_zas

      ENDDO

      IF t_fakt == "N"
	 ? "*************************************************************************************"
	 ? BoldON + Space(61) + Str( t_ukup_all, 8 ) + "  " + Str( t_ukup_all * Fond->cena, 14, 2 ) + BoldOFF
      ENDIF

      Prt3()

      DeleteFile("tt.prn")
      ClrPRcod("part2.prt")
      RenameFile( "part2.prt","tt.prn")

      CLOSE ALL

RETURN NIL

STATIC FUNCTION ZadHed()

      ? FontB + padl(DtoC( Date() ), 85, " ")
      ?
      ?
      ? padc( "IZVESTAJ O ZADUZENJU", 85, " " ) + FontS
      ?
      ?
      ?

      ? "*************************************************************************************"
      ? "Zast Ime                       Ser                     Cena    Ukupno          Ukupno"
      ? "                                         od        do   din   kartica          dinara"
      ? "*************************************************************************************"

RETURN NIL

* IZMENA ZADUZENJA
FUNCTION ChgZad()

LOCAL cOldScreen := "", ;
      t_brzas	 := 0 , ;
      aTemp	 := {}, ;
      aTemp1	 := {}, ;
      nUkup	 := 0 , ;
      i 	 := 0 , ;
      red	 := 12, ;
      nChoice	 := 0

      USE Zastup NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      USE Zaduz NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      vstk_push()
      cOldScreen = win_save(0, 0, 24, 79)

      BEGIN SEQUENCE

      IF Zaduz->(Bof()) .AND. Zaduz->(Eof())
	 alert("Baza zaduzenja prazna!", {" OK "})
	 BREAK
      ENDIF

      WinStyle(7, 17, 18, 63, "IZMENA ZADUZENJA")

      @  9, 19 SAY "Broj zastupnika:" GET t_brzas PICTURE "9999" VALID ChkZas1(t_brzas)
      @ 11, 19 SAY "ser        od        do      prva    ukupno"

      SetCursor(1)
      READ
      SetCursor(0)

      IF LastKey() == 27
	 BREAK
      ENDIF

      Zaduz->( dbSeek( t_brzas ) )
      IF Zaduz->( Found() )

	 aTemp := {}

	 DO WHILE Zaduz->zastup == t_brzas .AND. !Zaduz->( Eof() )

	    nUkup = ( Zaduz->do - Zaduz->prva_slob ) + 1

	    aadd(aTemp, FMT0L(Str(Zaduz->serija),3)    + Space(2) + ;
			FMT0L(Str(Zaduz->od),8)        + Space(2) + ;
			FMT0L(Str(Zaduz->do),8)        + Space(2) + ;
			FMT0L(Str(Zaduz->prva_slob),8) + Space(2) + ;
			FMTBLL(Str(nUkup),8) )

	    aadd(aTemp1, Zaduz->( RecNo() ) )

	    Zaduz->( dbSkip() )

	 ENDDO

	 nChoice = AChoice(12, 19, 16, 61, aTemp)
	 IF nChoice != 0

	    Zaduz->( dbGoTo( aTemp1[nChoice] ) )
	    @ 12, 19 CLEAR TO 16, 61
	    @ 12, 19 SAY aTemp[nChoice] COLOR "r/w"

	    GetChg()

	 ENDIF

      ENDIF

      END SEQUENCE

      win_rest(cOldScreen)
      vstk_pop()

      CLOSE ALL

RETURN NIL

FUNCTION ChkZas1(ttt)

LOCAL lRetVal := .T., ;
      oGet    := GetActive()

      IF Empty(ttt)
	 RETURN .F.
      ENDIF

      Zastup->( dbSeek(ttt) )
      IF !Zastup->( Found() )
	 ErrBeep()
	 al_box("Zastupnik br." + Str(ttt,4) + " ne postoji!", 1, {" OK "}, 1, 9, 25, 16, 55)
	 oGet:buffer = Space(4)
	 oGet:Display()
	 lRetVal = .F.
      ENDIF

RETURN lRetVal

FUNCTION GetChg()

LOCAL t_zastup	  := 0, ;
      t_serija	  := Zaduz->serija, ;
      t_od	  := Zaduz->prva_slob, ;
      t_do	  := Zaduz->do, ;
      t_datum	  := Zaduz->datum, ;
      t_prva_slob := Zaduz->prva_slob, ;
      t_status	  := Zaduz->status, ;
      nMenu	  := 0

PRIVATE t_ukup	  := 0

      @ 14, 19 SAY "zas   ser            od        do    ukupno"

      @ 15, 19 GET t_zastup PICTURE "9999"     VALID ChkZas1(t_zastup)
      @ 15, 25 GET t_serija PICTURE "999"      WHEN .F.
      @ 15, 34 GET t_od     PICTURE "99999999" VALID ChkOd( t_od )
      @ 15, 44 GET t_do     PICTURE "99999999" WHEN .F.
      @ 15, 54 GET t_ukup   PICTURE "99999999" WHEN .F.

      SetCursor(1)
      READ
      SetCursor(0)

      IF LastKey() == 27
	 RETURN
      ENDIF

      DO WHILE .T.

	 @ 17, 28 PROMPT "IZMENA"
	 @ 17, 47 PROMPT "PREKID"

	 MENU TO nMenu

	 IF nMenu != 0
	    EXIT
	 ENDIF

      ENDDO

      IF nMenu == 1

	 REPLACE Zaduz->do	  WITH ( t_od - 1 ), ;
		 Zaduz->status	  WITH iif( Zaduz->prva_slob >= Zaduz->do, .F., .T. )

	 Zaduz->( dbAppend() )
	 REPLACE Zaduz->zastup	  WITH t_zastup, ;
		 Zaduz->serija	  WITH t_serija, ;
		 Zaduz->od	  WITH t_od, ;
		 Zaduz->do	  WITH t_do, ;
		 Zaduz->datum	  WITH t_datum, ;
		 Zaduz->prva_slob WITH t_od, ;
		 Zaduz->status	  WITH .T.

	 DoneBeep()

      ENDIF

RETURN NIL

FUNCTION ChkOd(ttt)

LOCAL lRet := .T., ;
      oGet := GetActive()

      IF ( ttt >= Zaduz->prva_slob ) .AND. ( ttt <= Zaduz->do )
	 t_ukup = Str( ( Zaduz->do - ttt ) + 1, 8 )
         GetList[5]:Display()
      ELSE
	 ErrBeep()
	 oGet:buffer = Str(Zaduz->prva_slob, 8)
	 oGet:Assign()
         oGet:Display()
	 lRet = .F.
      ENDIF

RETURN lRet
