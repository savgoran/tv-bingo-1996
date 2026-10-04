#define BUFF_SIZE 10240
#define NEXT_ZIP cZip + AllTrim(Str(nZip++,3,0))

STATIC InBuffer, OutBuffer
STATIC InPtr, OutPtr, InEof
STATIC InFile, OutFile
STATIC nDisk, cDrive
STATIC nZip


********************
* 
* DATUM:  9. 6.1992. 
* 
* NAZIV: Backup (aFile, cDrv)
* 
* OPIS:  Bekap niza datoteka na cDrv
* 
* 
********************

PROC Backup (aFile, cDrv)
	LOCAL aName := {}, aSize := {}, aTmp, i, nFree, cOldScreen := ""
	LOCAL TB, m_x, m_y
	FIELD f_chk, f_name, f_size, f_zip, f_perc

	PRIVATE InBuffer, OutBuffer
	PRIVATE InPtr, OutPtr, InEof
	PRIVATE InFile, OutFile
	PRIVATE nDisk, cDrive
	PRIVATE nZip
	
	// Inicijalizacija
	vstk_push()
	cOldScreen = win_save(0,0,24,79)

	cDrive := cDrv
	nDisk := Asc(Upper(cDrive)) - Asc("A") + 1
	cZip := cDrive + "SAVE.Z"
	InBuffer := Space(BUFF_SIZE)
	OutBuffer := Space(BUFF_SIZE)
	OutPtr := 0
	nZip := 1

	// Nadji sve specificirane datoteke
	AEval (aFile, { |f| aTmp := Directory (f), ;
			AEval (aTmp, { |x| AAdd (aName, x[1]), AAdd (aSize, x[2]) } ) } )

	// Ako nema datoteka, kraj!
	IF Len (aName) == 0
		al_box("Ne postoje datoteke za snimanje!",1,{" OK "},1,9,20,15,60)
		RETURN
	END IF

	// Kreiranje datoteke za pregled
	DBCreate ("__tmp", { ;
			{"f_chk",  "C",  1, 0}, ;
			{"f_name", "C", 12, 0}, ;
			{"f_size", "C", 12, 0}, ;
			{"f_zip",  "C", 12, 0}, ;
			{"f_perc", "C",  5, 0}  ;
		} ;
	)
	USE __tmp NEW
	FOR i := 1 TO Len (aName)
		APPEND BLANK
		f_name := padr(substr(aName[i],1,at('.',aName[i])-1),8,' ')+substr(aName[i],at('.',aName[i])+1,3)
		f_size := Str (aSize[i])
	NEXT
	GO TOP

	// Tabela
	m_x := 3 ; m_y := 15
	DispBox (m_x, m_y, m_x+17, m_y+49, "ÉÍ»º¼ÍÈº ")
	sha_shadow(m_x, m_y, m_x+17, m_y+49)
	TB := TBrowseDB (m_x+1, m_y+2, m_x+16, m_y+47)
	TB:headSep := " Ä"
	
	TB:addColumn (TBColumnNew ("", {|| f_chk } ) )
	TB:addColumn (TBColumnNew ("NAZIV", {|| f_name } ) )
	TB:addColumn (TBColumnNew ("  VELICINA", {|| f_size } ) )
	TB:addColumn (TBColumnNew ("   ARHIVA", {|| f_zip } ) )
	TB:addColumn (TBColumnNew ("", {|| f_perc } ) )

	TB:colPos := 2

	WHILE !TB:stabilize() ; END DO

	// Pocetak kontrole
	BEGIN SEQUENCE

		// Treba staviti disketu sa dovoljno prostora za heder
		nFree := 0
		WHILE nFree < Len (aName) * 12 + 20
			// Priprema diskete
			ChangeDisk ()
			// Ima li dovoljno prostora?
			IF (nFree := DiskSpace (nDisk)) < Len (aName) * 12 + 20 
				IF al_box("Prostor na disketi nije dovoljan!",2,{" OK "," PREKID "},1,9,20,16,60) == 2
					BREAK
				END IF
			END IF
		END DO

		// Heder
		OutFile := FCreate (cDrive + "FILES.Z")
		FWrite (OutFile, Time() + DtoC(Date()) + Str(Len(aName), 3,0) )
		AEval (aName, { |n| FWrite (OutFile, PadL(n,12) ) } )
		FClose (OutFile)

		// Arhiviranje...
		OutFile := FCreate (NEXT_ZIP)

		* Msg ("ARHIVIRANJE...")

		FOR i := 1 TO Len(aName)
			f_zip := Str (Compress (aName[i]))
			f_chk := "û"
			f_perc := Str((1-Val(f_zip)/Max(Val(f_size),1))*100,4,0) + "%"

			TB:refreshCurrent()
			TB:down()
			WHILE !TB:stabilize() ; END DO
		NEXT

		// Zatvaranje 
		FClose (OutFile)

	// Kraj kontrole
	END SEQUENCE

	CLOSE ALL
	FErase ("__tmp.dbf")

	win_rest(cOldScreen)
	vstk_pop()

	InBuffer := NIL
	OutBuffer := NIL

RETURN

********************
* 
* DATUM: 11. 6.1992. 
* 
* NAZIV: n = Compress (InFileName)
* 
* OPIS:  Komprimovanje datoteke, vraca novu duzinu
* 
* 
********************

STATIC FUNC Compress (InFileName)
	LOCAL cCommand, nSize := -OutPtr

	InPtr := BUFF_SIZE
	InEof := 0

	InFile := FOpen (InFileName)

	// Komunikacija sa asm programom
	WHILE .T.

		// Odredjivanje sledece akcije
		cCommand := Zip (@InPtr, @OutPtr, InEof, InBuffer, OutBuffer)

		// Sta treba uraditi?
		IF cCommand == "R"
			ReadBlock ()

		ELSEIF cCommand == "W" 
			nSize += OutPtr
			WriteBlock ()

		ELSEIF cCommand == "E"
			nSize += OutPtr
			WriteBlock ()

			// Oznaka za kraj
			OutBuffer := Chr (0) + Chr (0) + Space (BUFF_SIZE-2)
			OutPtr := 2
			WriteBlock ()

			EXIT
		END IF

	END DO

	// Gotovo
	FClose (InFile) 
	
RETURN nSize



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
	
	// Citanje bloka
	* Msg ("Reading...")
	InEof := FRead (InFile, @InBuffer, BUFF_SIZE)
	InPtr := 0

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
	LOCAL aFile, nError := 1, n

	IF al_box("Stavite novu disketu...",2,{" OK "," PREKID "},1,9,20,15,60) == 2
		BREAK
	END IF

	msg_start(9,20,15,60)

	WHILE nError <> 0

		// Testiranje diskete
		Msg("Testira se disketa...")
		nError := DiskStat (cDrive)

		DO CASE
			CASE nError == 1 
				IF al_box("Niste stavili disketu!",2,{" OK "," PREKID "},1,9,20,15,60) == 2
				   msg_end()
				   BREAK
				ENDIF
			CASE nError == 2
				IF al_box("Disketa nije formatirana!",2,{" OK "," PREKID "},1,9,20,15,60) == 2
				   msg_end()
				   BREAK
				ENDIF
			CASE nError == 3
				IF al_box("Disketa je zasticena od upisa!",2,{" OK "," PREKID "},1,9,20,15,60) == 2
				   msg_end()
				   BREAK
				ENDIF
			CASE nError == 4
				IF al_box("Nesto nije u redu sa disketom!",2,{" OK "," PREKID "},1,9,20,15,60) == 2
				   msg_end()
				   BREAK
				ENDIF
		END CASE
	END DO

	// Brisanje diskete
	aFile := Directory (cDrive + "*.*", "HSD")

	IF Len (aFile) <> 0
		n := al_box("Disketa nije prazna! Slobodan prostor: " + ;
			AllTrim (Str(DiskSpace(nDisk))) + "; Zelite li brisanje diskete?", 2,;
				{" Da ", " Ne "}, 1, 9,20,16,60)
				
		IF n == 1
			* Msg ("Brise se disketa...")
			msg_end()
			xDel (cDrive + "\")
			RETURN
		ELSE
			msg_end()
			BREAK
		END IF
	END IF

	msg_end()

RETURN


********************
* 
* DATUM: 16. 6.1992. 
* 
* NAZIV: xDel (cSpec)
* 
* OPIS:  Brisanje specificiranog dir-a
* 
* 
********************

PROC xDel (cSpec)
	LOCAL aFiles, i
	
	msg_start(9,20,15,60)

	// Prvo uzmi sve datoteke
	aFiles := Directory (cSpec + "*.*", "HSD")

	// Izbrisi sve u tekucem
	AEval (aFiles, { |f| IIF (f[5] <> "D", ;
		Msg (Lower (cSpec + f[1]) + Chr(FileRemove(cSpec + f[1]))), ) } )

	FOR i := 1 TO Len (aFiles) 
		IF ! (aFiles[i][1] $ "..") .AND. aFiles[i][5] == "D"
			xDel (cSpec + aFiles[i][1] + "\")
			Msg (Upper (cSpec + aFiles[i][1]))
			DirRemove (cSpec + aFiles[i][1])
		END IF
	NEXT

	msg_end()

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
	LOCAL nFree
	
	* Msg ("Writing...")

	// Da li je disketa ispunjena?
	nFree := DiskSpace (nDisk)

	IF nFree < OutPtr

		// Popuni koliko moze
		FWrite (OutFile, OutBuffer, nFree)

		// Zatvori staru arhivu
		FClose (OutFile)

		// Izmenite disketu...
		WHILE DiskSpace(nDisk) < OutPtr - nFree
			ChangeDisk ()
		END DO

		// Otvori novu...
		OutFile := FCreate (NEXT_ZIP)

		// Ispisi ostatak bafera
		FWrite (OutFile, SubStr (OutBuffer, nFree+1, OutPtr-nFree))
	ELSE
		// Upis bloka
		FWrite (OutFile, OutBuffer, OutPtr)
	END IF

	// Pokazivac na pocetak
	OutPtr := 0

RETURN
