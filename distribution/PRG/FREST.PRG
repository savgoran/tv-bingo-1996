#include "Inkey.ch"

#define BUFF_SIZE 10240
#define NEXT_ZIP cZip + AllTrim(Str(nZip++,3,0))

STATIC InBuffer, OutBuffer
STATIC InPtr, OutPtr, InEof
STATIC InFile, OutFile
STATIC nDisk, cDrive
STATIC nZip
STATIC lSkip

********************
* 
* DATUM:  9. 6.1992. 
* 
* NAZIV: Restore (cDrv)
* 
* OPIS:  Restore datoteka sa drajva cDRV
* 
* 
********************

PROC Restore (cDrv)
	LOCAL aName := {}, aSize := {}, aTmp, i, nFree, cOldScreen := ""
	LOCAL TB, m_x, m_y, cTime, cDate, cNF, Ch
	FIELD f_chk, f_name, f_size, f_zip, f_perc

PRIVATE InBuffer, OutBuffer
PRIVATE InPtr, OutPtr, InEof
PRIVATE InFile, OutFile
PRIVATE nDisk, cDrive
PRIVATE nZip
PRIVATE lSkip
	
	// Inicijalizacija
	vstk_push()
	cOldScreen = win_save(0,0,24,79)

	cDrive := cDrv
	nDisk := Asc(Upper(cDrive)) - Asc("A") + 1
	cZip := cDrive + "SAVE.Z"
	InBuffer := Space(BUFF_SIZE)
	OutBuffer := Space(BUFF_SIZE)
	InPtr := BUFF_SIZE
	InEof := 0
	nZip := 1
	cTime := Space(8)
	cDate := Space(8)
	cNF := Space(3)

	// Pocetak kontrole
	BEGIN SEQUENCE

		// Priprema diskete
		ChangeDisk ()

		// Heder
		IF File (cDrive + "FILES.Z")
			InFile := FOpen (cDrive + "FILES.Z")
			FRead (InFile, @cTime, 8)
			FRead (InFile, @cDate, 8)
			FRead (InFile, @cNF, 3)
		ELSE
			ErrBeep()
			al_box("Nema informacija o datotekama u arhivi!",1,{" OK "},1,9,20,16,60)
			BREAK
		END IF

		IF al_box("ARHIVA KREIRANA: " + cDate + " u " + cTime, 2, {" RESTORE "," PREKID "}, 1, 9, 20,16, 60) == 2
			BREAK
		END IF

		// Nazivi datoteka
		aName := Array (Val (cNF))
		cTmp := Space(12)
		FOR i := 1 to Len(aName)
			FRead(InFile, @cTmp, 12)
			aName[i] := SubStr(cTmp,1)
		NEXT
		FClose (InFile)

		// Kreiranje datoteke za pregled
		DBCreate ("__tmp", { ;
				{"f_chk", "C", 1, 0}, ;
				{"f_name", "C", 12, 0}  ;
			} ;
		)
		USE __tmp NEW
		FOR i := 1 TO Len (aName)
			APPEND BLANK
			f_name := aName[i]
			f_chk := "û"
		NEXT
		GO TOP

		// Tabela
		al_box("ENTER-Oznacavanje datoteke",1,{" OK "},1)
		m_x := 3 ; m_y := 33
		DispBox (m_x, m_y, m_x+17, m_y+17, "ÉÍ»º¼ÍÈº ")
		sha_shadow(m_x, m_y, m_x+17, m_y+17)
		TB := TBrowseDB (m_x+1, m_y+2, m_x+16, m_y+15)
		TB:headSep := " Ä"
	
		TB:addColumn (TBColumnNew ("", {|| f_chk } ) )
		TB:addColumn (TBColumnNew ("NAZIV", {|| f_name } ) )
		TB:colPos := 2

		// Izbor datoteka koje ce se izvuci iz arhive
		WHILE .T.
			WHILE !TB:stabilize() ; END DO
			
			Ch := Inkey (0)

			DO CASE
				CASE Ch == K_ESC ; EXIT
				CASE Ch == K_DOWN ; TB:down()
				CASE Ch == K_UP ; TB:up()
				CASE Ch == K_ENTER 
					f_chk := IIF (Empty(f_chk), "û", " ")
					TB:refreshCurrent()
					TB:down()
			END CASE
		END DO

		// Na pocetak
		TB:goTop()
		TB:refreshCurrent()

		// Dearhiviranje...
		* Msg ("DEARHIVIRANJE...")
		InFile := FOpen (NEXT_ZIP)

		IF FError() <> 0 
			ErrBeep()
			al_box("Arhiva je ostecena!",1,{" OK "},1)
			BREAK
		END IF

		GO TOP
		TB:refreshAll()
		WHILE !TB:stabilize() ; END DO

		FOR i := 1 TO Len(aName)
			UnCompress (AllTrim(aName[i]))
			IF !lSkip
				f_chk := "+"
			END IF
			TB:refreshCurrent()
			TB:down()
			WHILE !TB:stabilize() ; END DO
		NEXT

	// Kraj kontrole
	END SEQUENCE

	win_rest(cOldScreen)
	vstk_pop()

	// Zatvaranje 
	FClose (OutFile)

	CLOSE ALL
	FErase ("__tmp.dbf")

	InBuffer := NIL
	OutBuffer := NIL

RETURN

********************
* 
* DATUM: 11. 6.1992. 
* 
* NAZIV: UnCompress (OutFileName)
* 
* OPIS:  Dekomprimovanje datoteke
* 
* 
********************

STATIC PROC UnCompress (OutFileName)
	LOCAL cCommand

	OutPtr := 0

	IF ! (lSkip := (f_chk == " "))
		OutFile := FCreate (OutFileName)
	END IF

	// Komunikacija sa asm programom
	WHILE .T.

		// Odredjivanje sledece akcije
		cCommand := UnZip (@InPtr, @OutPtr, InEof, InBuffer, OutBuffer)

		// Sta treba uraditi?
		IF cCommand == "R"
			ReadBlock ()

		ELSEIF cCommand == "W" .OR. cCommand == "C"
			WriteBlock ()

		ELSEIF cCommand == "E"
			WriteBlock ()
			EXIT

		END IF

	END DO

	// Gotovo
	IF !lSkip
		FClose (OutFile) 
	END IF
	
	// Pomeri InPtr 
	InPtr++
	IF InPtr > BUFF_SIZE
		ReadBlock()
	END IF

RETURN 



********************
* 
* DATUM: 12. 6.1992. 
* 
* NAZIV: ReadBlock ()
* 
* OPIS:  Citanje bloka
* 
* 
********************

STATIC FUNC ReadBlock
	LOCAL cTmp, nRead
	
	// Citanje bloka
	InEof := FRead (InFile, @InBuffer, BUFF_SIZE)

	// Ako nije procitan ceo blok i na kraju se ne nalazi \0\0, citaj opet
	WHILE InEof < BUFF_SIZE .AND. SubStr (InBuffer, InEof-1, 2) <> Chr(0)+Chr(0)

		// Zamena diskete
		FClose (InFile)
		ChangeDisk ()
		InFile := FOpen (NEXT_ZIP)

		cTmp := Space(BUFF_SIZE)
		nRead := FRead (InFile, @cTmp, BUFF_SIZE - InEof)

		InBuffer := Left (InBuffer, InEof) + Left (cTmp, nRead)
		InEof += nRead
	END DO

	InPtr := 0

RETURN


********************
* 
* DATUM: 12. 6.1992. 
* 
* NAZIV: WriteBlock ()
* 
* OPIS:  Upisivanje bloka
* 
* 
********************

STATIC FUNC WriteBlock 

	IF !lSkip
		* Msg ("Writing...")

		// Upis bloka
		FWrite (OutFile, OutBuffer, OutPtr)
	END IF

	OutPtr := 0

RETURN




********************
* 
* DATUM: 10. 6.1992. 
* 
* NAZIV: ChangeDisk 
* 
* OPIS:  Zamena diskete
* 
* 
********************

STATIC PROC ChangeDisk
	LOCAL aFile, nError := 1

	msg_start(9,20,16,60)

	WHILE .T.

		IF al_box("Stavite disketu broj " + AllTrim (Str (nZip,3,0)),2,{" OK "," PREKID "},1,9,20,16,60) == 2
			msg_end()
			BREAK
		END IF

		WHILE nError <> 0
			// Testiranje diskete
			Msg ("Testira se disketa...")
			nError := DiskStat (cDrive)

			DO CASE
				CASE nError == 1 
					IF al_box("Niste stavili disketu!",2,{" OK "," PREKID "},1,9,20,15,60) == 2
					   msg_end()
					   BREAK
					ENDIF
				CASE nError == 2 .OR. nError == 4
					IF al_box("Nesto nije u redu sa disketom!",2,{" OK "," PREKID "},1,9,20,15,60) == 2
					   msg_end()
					   BREAK
					ENDIF
				CASE nError == 3
					nError := 0
			END CASE
		END DO

		// Da li je prava disketa?
		IF File (cZip + AllTrim (Str (nZip, 3,0)))
			EXIT
		END IF
	END DO

	msg_end()

RETURN



