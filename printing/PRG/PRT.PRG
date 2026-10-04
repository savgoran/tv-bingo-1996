#include "commands.ch"

#define ESC Chr(27)
#define LINEMAX 138
#define PAGELEN 60
#define MESEC {"januar", "februar", "mart", "april", "maj", "jun", "jul", ;
			"avgust", "septembar", "oktobar", "novembar", "decembar"}
#define DAN {"ponedeljak", "utorak", "sreda", "~etvrtak", ;
									"petak", "subota", "nedelja"}

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
	PUBLIC IsDone := .F.   && IsDone - da li je stampanje zavrseno

	PUBLIC cFile1 := "", cFile2 := ""

	PUBLIC PtrScreen										&& Ekran
	PUBLIC PtrNum:=.F., PtrHed:=.F., ;				&& Parametri stampanja
			 PtrTitle:=.F., PtrCon:=.T., PtrQ:=.F.
	PUBLIC job_counter :=0, job_max := 0
	PUBLIC NormalC := "W/N,N/W,,,W/N", ;			&& Boje
			 BoldC := "W+/N,N/W,,,W/N"
	PUBLIC BoldON, BoldOFF, UndON, UndOFF, ItalON, ItalOFF, AttrOFF, CompON, CompOFF
	PUBLIC ScrAttr := {BoldON := Chr(2), ;
			  BoldOFF := Chr(6), ;						 && Atributi pregleda
			  UndON := Chr(1), UndOFF := Chr(5), ;
			  ItalON := Chr(4), ItalOFF := Chr(8), ;
			  AttrOFF := Chr(9),;
			  CompON := Chr(3), CompOFF := Chr(7)}
	PUBLIC NewPage := "<Nova strana>", Page := 1, NewChp := "Nova lista"
	PUBLIC GroupLen := "\GL"
	PUBLIC PtrAttr := {ESC+"E", ;
			   ESC+"F", ;
			   ESC+"-"+Chr(1), ESC+"-"+Chr(0), ;
			   ESC+"4", ESC+"5", ;
			   Chr(18) + ESC+"F"+ESC+"-"+Chr(0)+ESC+"5",;
			   ESC+Chr(15), Chr(18)}
	PUBLIC PtrReset := ESC + "@", PtrHighQ := ESC + "x" + Chr(1), ;
			 PtrLowQ := ESC + "x" + Chr(0), PtrFF := Chr(12)
	PUBLIC Header := ""
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

	aa = MakeFileUnq()
	cFile1 = aa[1]
	cFile2 = aa[2]

	* SAVE SCREEN TO PtrScreen
	* 24,0


	SET ALTERNATE TO &(cFile1)
	SET ALTERNATE ON
	SET CONSOLE OFF
	IsDone := .F.
	job_counter := 0
	msg_start(9,25,15,55)
	msg("Priprema izvestaja...")

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
	SET ALTERNATE TO  &(cFile2)
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

PROCEDURE Prt3( lOpc )

	DEFAULT lOpc TO .T.

	IF lOpc

	msg_end()
	SET CONSOLE ON
	SET ALTERNATE OFF
	CLOSE ALTERNATE

	ELSE

	cFile1 = "part1.prt"
	cFile2 = "part2.prt"

	ENDIF

	SAVE SCREEN TO PtrScreen
	QOut ()

	WHILE .T.
		@ 24,0
		SayInv (24,0, "[P]rint", .F.)
		SayInv (24,13, "[K]valitet", PtrQ)
		SayInv (24,28, "[A]mblem", PtrHed)
		SayInv (24,41, "[N]aslov", PtrTitle)
		SayInv (24,54, "Kontin[u]alno", PtrCon)
		SayInv (24,72, "[H]eder", PtrNum)
		ch := View(cFile1, cFile2)
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

	FileDelete(cFile1)
	FileDelete(cFile2)

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
	LOCAL Line, Buffer, i, N, TempLen := 0, TempPos := 0, Status := 0

	Line := 0
	Page := 1

	IF !IsPrinter ()										&& Provera da li je sve OK
		SayScreen ("Stampac nije dobro povezan!", 24,0)
		Inkey (10)
		RETURN 
	END IF


	@ 24,0
	SET DEVICE TO PRINT
	SET PRINT ON
	SET CONSOLE OFF

	IF PRow() <> 0											&& Nije pocetak strane
		EJECT
	END IF

	?? PtrReset												&& Inicijalizacija
	?? IF (PtrQ, PtrHighQ, PtrLowQ)					&& Kvalitet stampe

	IF PtrTitle												&& Naslov
		ToPrint (Title)
	ELSE
		QOut () 
	END IF
	QOut ()
	Line += 2
		
	// Stampanje datoteke PART2.PRT
	f := FOpen(cFile2,0)
	// Preskoci <CR><LF> par
	FSeek(f,2,0)

	// Glavni ciklus
	WHILE .T.
		   TempLen = 0
		   TempPos = 0
		Buffer := Space (LINEMAX)
		fpos := FSeek (f,0,1)		       && Nova pozicija za citanje
		Status := FRead (f,@Buffer,LINEMAX)    && Citanje linije
		IF Status = 0			       && Eof?
			QOut () ; EJECT ; EXIT
		END IF
		poz := At (Chr(13), Buffer)					&& Nadji kraj linije

		// Da nije pritisnuto ESC?
		Inkey ()
		IF LastKey() == 27
			EXIT
		END IF

		TempPos = at(GroupLen,Left(Buffer, poz-1))
		IF TempPos != 0
		   TempLen = Val(SubStr(buffer,TempPos+3,2))
		   IF (PAGELEN - Line) < TempLen
		      Page++ ; Line := 0 ; EJECT
		      IF !PtrCon
			      SayScreen (Space(80),24,0)
			      SayScreen ("Namestite papir i pritisnite <Enter>",24,0)
			      Inkey(0)
		      END IF
		   ENDIF
		   FSeek (f, fpos+poz+1, 0)
		   LOOP
		ENDIF
/*
		// Nova lista
		IF (NewChp $ Left(Buffer, poz-1)) .AND. Line > 32
		   * TempPos = at(NewChp,Buffer)
		   * Header = AllTrim(SubStr(Buffer,TempPos+Len(NewChp)+1))

                   QOut() ; Page := 1 ; Line := 0 ; EJECT

		   IF !PtrCon										   && Papir po papir
			   SayScreen (Space(80),24,0)
			   SayScreen ("Namestite papir i pritisnite <Enter>",24,0)
			   Inkey(0)
		   END IF
		   FSeek (f, fpos+poz+1, 0)					   && Nova pozicija za citanje
		   LOOP
		ENDIF
*/

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
		IF PtrNum .AND. Line == 0 .AND. Page > 1
			ToPrint ( padl(Header + "/" + Ltrim(Str(page,2,0)),78,' ') )
			QOut ()
			Line += 2
		END IF

		// Stampaj liniju!
		ToPrint (Left (Buffer, poz-1))
		Line++

		SayScreen (Space(80),24,0)
		SayScreen ("Stampa se strana broj "+Str(Page,2,0)+;
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
	IsDone := .T.
	FClose (f)
	SET DEVICE TO SCREEN
	SET CONSOLE ON
	SET PRINT OFF

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
	? Line
RETURN

FUNCTION MakeFileUnq()

LOCAL aTemp := {}, ;
      aDir  := {}, ;
      i     := 0, ;
      nBr   := 1, ;
      cc    := "", ;
      aRet  := {}

      aDir = Directory("*.prt")

      IF Len(aDir) > 0

	 FOR i = 1 TO Len(aDir)
	     aadd(aTemp, aDir[i,1])
	 NEXT

	 aTemp = ASort(aTemp)

	 cc = aTemp[Len(aTemp)]
	 nBr = Int(Val(SubStr(cc,4)))
	 ++nBr

      ENDIF

      aadd(aRet, "prt" + FMT0L(Str(nBr),5) + ".prt")
      aadd(aRet, "prt" + FMT0L(Str(nBr+1),5) + ".prt")

RETURN aRet

FUNCTION Make1Unq()

LOCAL aTemp := {}, ;
      aDir  := {}, ;
      i     := 0, ;
      nBr   := 1, ;
      cc    := "", ;
      cRet  := Space(12)

      aDir = Directory("*.prt")

      IF Len(aDir) > 0

	 FOR i = 1 TO Len(aDir)
	     aadd(aTemp, aDir[i,1])
	 NEXT

	 aTemp = ASort(aTemp)

	 cc = aTemp[Len(aTemp)]
	 nBr = Int(Val(SubStr(cc,4)))
	 ++nBr

      ENDIF

      cRet = "prt" + FMT0L(Str(nBr),5) + ".prt"

RETURN cRet
