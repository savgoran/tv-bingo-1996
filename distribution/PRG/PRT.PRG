#define ESC Chr(27)
#define LINEMAX 250
#define PAGELEN 85
#define MESEC {"januar", "februar", "mart", "april", "maj", "jun", "jul", ;
			"avgust", "septembar", "oktobar", "novembar", "decembar"}
#define DAN {"ponedeljak", "utorak", "sreda", "~etvrtak", ;
									"petak", "subota", "nedelja"}

#define PCL_RESET		    S2P("E")
#define PCL_INIT                    S2P("E(8U&l6d70P&l0E&l1X&l1H&lO&l0suZ*p0x75Y")
#define PCL_END 		    S2P("&lO(8U(sp10h12vsb3T&l6d3E&l1X")

#define PCL_V_POS(x,y)		    Chr(27) + Chr(42) + Chr(112) + alltrim(Str(x)) + "x" + alltrim(str(y)) + Chr(89)
#define PCL_HMI(x)		    Chr(27) + Chr(38) + Chr(107) + alltrim(Str(x,10,2)) + Chr(72)
#define PCL_SET_FONT(x) 	    Chr(27) + Chr(40) + alltrim(Str(x)) + Chr(88)
#define PCL_EJECT		    Chr(12)
#define PCL_UND_DIS		    Chr(27) + Chr(38) + Chr(100) + Chr(64)
#define PCL_SET_ID(x)		    Chr(27) + Chr(42) + Chr(99) + alltrim(Str(x)) + Chr(68)

********************
* 
* DATUM:  3. 8.1991. 
* 
* NAZIV: IniPtr()
* 
* OPIS:  Inicijalizacija sistema stampanja
* 
* 
********************

PROC IniPtr
	PUBLIC PtrScreen										&& Ekran
	PUBLIC PtrNum:=.T., PtrHed:=.F., ;				&& Parametri stampanja
			 PtrTitle:=.F., PtrCon:=.T., PtrQ:=.F., PtrOut := 1
	PUBLIC job_counter :=0, job_max := 0
	PUBLIC NormalC := "W/N,N/W,,,W/N", ;			&& Boje
			 BoldC := "W+/N,N/W,,,W/N"
	PUBLIC BoldON, BoldOFF, UndON, UndOFF, ItalON, ItalOFF, AttrOFF, FontB, FontS
	PUBLIC ScrAttr := {BoldON := Chr(2), ;
			 BoldOFF := Chr(6), ;						&& Atributi pregleda
			 FontB := Chr(1), FontS := Chr(5), ;
			 ItalON := Chr(4), ItalOFF := Chr(8), ;
			 AttrOFF := Chr(9)}

	PUBLIC NewPage := "<Nova strana>"

	PUBLIC PtrAttr := {ESC+"(s3B",                    ESC+"(s0B", ;
			   ESC + "(s12H" + ESC + "&l6C", ESC + "(s16.66H" + ESC + "&l6C", ;
			   ESC+"(s1S",                    ESC+"(s0S", ;
			   ESC+"F"+ESC+"-"+Chr(0)+ESC+"5"}

	PUBLIC PtrReset := ESC + "E", PtrHighQ := ESC + "x" + Chr(1), ;
			 PtrLowQ := ESC + "x" + Chr(0), PtrFF := Chr(12)
	PUBLIC Header  := Space(65) + "Strana \#"
	PUBLIC Title := DAN[DoW(Date())] + ', ' + Str(Day(Date()),2,0)+'. ' + ;
		MESEC[Month(Date())] + ' ' + Str(Year(Date()),4,0) + ;
		". godine, " + Time()
RETURN


********************
* 
* DATUM: 23. 1.1991. 
* 
* NAZIV: Prt1()
* 
* OPIS:  Pocetak hedera
* 
* 
********************

PROCEDURE Prt1
	SAVE SCREEN TO PtrScreen
	@ 24,0 
	SET ALTERNATE TO Part1.prt
	SET ALTERNATE ON
	SET CONSOLE OFF
	job_counter := 0
	* Job(0)
	@ 12,1 CLEAR TO 14,78
	@ 12,1 TO 14,78 DOUBLE
RETURN

********************
* 
* DATUM: 23. 1.1991. 
* 
* NAZIV: Prt2()
* 
* OPIS:  Kraj uzimanja hedera i pocetak uzimanja tela
* 
* 
********************

PROCEDURE Prt2
	CLOSE ALTERNATE
	SET ALTERNATE TO Part2.prt
	SET ALTERNATE ON
RETURN


********************
* 
* DATUM: 10.12.1990. 
* 
* NAZIV: Prt3()
* 
* OPIS:  Prekida uzimanje kontinualnog dela, nudi preview i stampanje.
* 
* 
********************

PROCEDURE Prt3
	QOut ()
	SET CONSOLE ON
	SET ALTERNATE OFF
	CLOSE ALTERNATE
	WHILE .T.
		@ 24,0
		SayInv (24,0, "[P]rint", .F.)
		SayInv (24,13, "[K]valitet", PtRQ)
		SayInv (24,28, "[A]mblem", PtrHed)
		SayInv (24,41, "[N]aslov", PtrTitle)
		SayInv (24,54, "Kontin[u]alno", PtrCon)
		SayInv (24,72, "[H]eder", PtrNum)
		ch := View()
		DO CASE
			CASE ch="Q"; EXIT
			CASE ch="P"; SayInv (24,0, Space(80), .T.) ; GoPrint ()
			CASE ch="C"; /*--- Calc ()       ---*/
			CASE ch="V"; /*--- Calendar ()   ---*/
			CASE ch="A"; PtrHed := !PtrHed
			CASE ch="N"; PtrTitle := !PtrTitle
			CASE ch="H"; PtrNum := !PtrNum
			CASE ch="U"; PtrCon := !PtrCon
			CASE ch="I"; PtrQ := !PtrQ
		END CASE
	END DO
	RESTORE SCREEN FROM PtrScreen
	* ERASE Part1.prt
	* ERASE Part2.prt
RETURN


********************
* 
* DATUM: 31. 5.1990. 
* 
* NAZIV: GoPrint()
* 
* OPIS:  Stampanje datoteka PART1.PRT i PART2.PRT
* 
* 
********************

PROC GoPrint
	LOCAL Line, Buffer, i, N, Page, STATUS := 0, nAlch := 0

	Line := 0
	Page := 1

	nAlch = al_box("Izbor izlaza?", 3, {"Stampac", "File", "Prekid"}, 2, 9, 25, 15, 55)

	DO CASE
	   CASE nAlch = 1
		PtrOut = 1
		SET DEVICE TO PRINT
		SET PRINT ON
	   CASE nAlch = 2
		PtrOut = 2
		FileDelete("tt.prn")
		SET PRINTER TO tt.prn
		SET DEVICE TO PRINT
		SET PRINT ON
	   CASE nAlch = 3
		RETURN NIL
	ENDCASE

	IF !IsPrinter () .and. PtrOut != 2										 && Provera da li je sve OK
		SayScreen ("Stampac nije dobro povezan!", 24,0)
		Inkey (10)
		RETURN 
	END IF

	@ 24,0
	SET CONSOLE OFF

	IF PRow() <> 0											&& Nije pocetak strane
		EJECT
	END IF

	?? PtrReset												&& Inicijalizacija
	* ?? IF (PtrQ, PtrHighQ, PtrLowQ)				  && Kvalitet stampe

	s2p(Chr(27) + "&l26A")       && A4
	s2p(Chr(27) + "&l0O")        && portrait
	s2p(Chr(27) + "&l70F")        && portrait

	s2p(Chr(27) + "&l1E")        && top margina
	s2p(Chr(27) + "&l0U")        && lokicki vrh

	* definicija fonta primarnog
	s2p(Chr(27) + "(0U")
	s2p(Chr(27) + "(s0P")        && neproporcionalni
	s2p(Chr(27) + "(s16.66H")    && sirina slova
	s2p(Chr(27) + "(s0B")        && zacrnjenje: 0
	s2p(Chr(27) + "(s0S")        && kurziv ne
	s2p(Chr(27) + "(s4T")        && helvetica

	s2p(Chr(27) + "*c21D")       && privremeno dodeljivanje ID
	s2p(Chr(27) + "*c6F")        &&

	* definicija fonta sekundarnog
	s2p(Chr(27) + ")0U")
	s2p(Chr(27) + ")s0P")        && neproporcionalni
	s2p(Chr(27) + ")s12H")       && sirina slova
	s2p(Chr(27) + ")s0B")        && zacrnjenje: 0
	s2p(Chr(27) + ")s0S")        && kurziv ne
	s2p(Chr(27) + ")s4T")        && helvetica

	s2p(Chr(27) + "*c20D")       && privremeno dodeljivanje ID
	s2p(Chr(27) + "*c6F")        &&

	s2p(Chr(27) + ")20X")        && aktiviranje fonta sekundarnog
        s2p(Chr(27) + "(21X")        && aktiviranje fonta primarnog

	* s2p(Chr(27) + "&l6C")

	IF PtrTitle												&& Naslov
		ToPrint (Title)
	ELSE
		* QOut ()
	END IF
	* QOut ()
	* Line += 2
	
/*
	// Zaglavlje
	IF PtrHed
		N := MLCount (Buffer := MemoRead ("Amblem.txt"))
		FOR i := 1 TO N
			ToPrint (Trim(MemoLine (Buffer, 50, i)))
			Line++
		NEXT
	END IF
*/

	// Stampanje datoteke PART1.PRT
	N := MLCount (Buffer := MemoRead ("Part1.prt"))
	IF N <> 0 
		? Replicate ("Ä",80)
		FOR i := 1 TO N
			ToPrint (Trim (MemoLine (Buffer, LINEMAX, i)))
			Line++
		NEXT
		? Replicate ("Ä",80)
		Line += 2
	END IF
		
	// Stampanje datoteke PART2.PRT
	f := FOpen("Part2.prt",0)
	// Preskoci <CR><LF> par
	FSeek(f,2,0)

	// Glavni ciklus
	WHILE .T.
		Buffer := Space (LINEMAX)
		fpos := FSeek (f,0,1)							&& Nova pozicija za citanje
		Status = FRead (f,@Buffer,LINEMAX)		       && Citanje linije
		IF Status == 0										&& Eof?
			QOut () ; EJECT ; EXIT
		END IF
		poz := At (Chr(13), Buffer)					&& Nadji kraj linije

		// Da nije pritisnuto ESC?
		Inkey ()
		IF LastKey() == 27
			EXIT
		END IF

		// Nova strana (NEWPAGE)
		IF NewPage $ Left (Buffer, poz-1) .AND. Line <> 0
			QOut () ; Page++ ; Line := 0 ; EJECT
			IF !PtrCon										&& Papir po papir
				SayScreen (Space(80),24,0)
				SayScreen ("Namestite papir i pritisnite <Enter>",24,0)
				Inkey(0)
			END IF
			FSeek (f, fpos+poz+1, 0)					&& Nova pozicija za citanje
			LOOP
		END IF

		// Numeracija strana / heder strane
		IF PtrNum .AND. Line == 0
			s2p(Chr(14))
			ToPrint( "Datum: " + DtoC(Date()) + padl("Strana " + Ltrim(Str(page,3,0)), 78, " ") )
			s2p(Chr(15))
			QOut ()
			Line += 2
		END IF

		// Stampaj liniju!
		ToPrint (Left (Buffer, poz-1))
		Line++

		SayScreen (Space(80),24,0)
		SayScreen ("Stampa se strana broj " + Str(Page,2,0) + ;
					"  linija broj "+Str(Line,2,0),24,0)
		FSeek (f, fpos+poz+1, 0)						&& Nova pozicija za citanje
		
		// Nova strana
		IF Line == PAGELEN
			QOut () ; Page++ ; Line := 0 ; EJECT
			IF !PtrCon										&& Papir po papir
				SayScreen (Space(80),24,0)
				SayScreen ("Namestite papir i pritisnite <Enter>",24,0)
				Inkey(0)
			END IF
		END IF

	END DO		    

	// Kraj stampanja
	FClose (f)
	SET DEVICE TO SCREEN
	SET CONSOLE ON
	SET PRINT OFF
	SET PRINTER TO

RETURN



********************
* 
* DATUM:  3. 8.1991. 
* 
* NAZIV: SayInv (X,Y,Txt,Inv)
* 
* OPIS:  Ispisuje tekst na (X,Y), ako treba bold
* 
* 
********************

PROC SayInv (X,Y,Txt,Inv)
	LOCAL OldC
	IF (Inv, OldC := SetColor (BoldC),)
	@ X,Y SAY Txt
	IF (Inv, SetColor (OldC),)
RETURN


********************
* 
* DATUM:  6. 6.1990. 
* 
* NAZIV: c := Job (n)
* 
* OPIS:  Uvecava brojac za n i ispisuje %
* 
* 
********************

FUNCTION Job (n)
	LOCAL p
	IF job_max <> 0
		job_counter += n
		IF job_counter > job_max
			job_counter := job_max
		END IF
		p := job_counter / job_max
		SayScreen (Replicate('Ý',p*70+1)+Str(p*100,3,0)+'%',13,2)
	END IF
RETURN ""


********************
* 
* DATUM:  4. 8.1991. 
* 
* NAZIV: ToPrint (Line)
* 
* OPIS:  Stampa liniju na stampac
* 
* 
********************

PROC ToPrint (Line)
	LOCAL i
	FOR i := 1 TO Len (ScrAttr)
		Line := StrTran (Line, ScrAttr[i], PtrAttr[i])
	NEXT
	s2p(Line)
	?
RETURN

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

STATIC FUNCTION S2P(cStr)

local i := 0, cntsnd := 0, cchar := "", lPrvi := .F.

      IF PtrOut == 2
	 ?? cStr
	 RETURN NIL
      ENDIF

      cntsnd = PrintSend(cStr)

      IF cntsnd != 0

/*
	 IF !lPrvi
	    lPrvi = .T.
	    IF AScan(aSpor, nTekSN) = 0
	       aadd(aSpor,nTekSN)
	    ENDIF
	 ENDIF
*/

	 DO WHILE cntsnd != 0
	    cStr = Right(cStr, cntsnd)
	    TestPrinter()
	    cntsnd = PrintSend(cStr)
	 ENDDO

      ENDIF

RETURN NIL

FUNCTION TestPrinter()

	 IF !PrintReady(1)
	    DO WHILE !PrintReady(1); ENDDO
	    MilliSec(1000)
	    DO WHILE !PrintReady(1); ENDDO
	 ENDIF

RETURN NIL
