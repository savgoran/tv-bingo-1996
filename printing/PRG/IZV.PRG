#include "sixcdx.ch"
#include "machsix.ch"
#include "commands.ch"

FUNCTION IzvRep()

LOCAL nTemp   := 0, ;
      nSelect := Select(), ;
      cTemp   := "", ;
      cTempD  := "", ;
      cTemp2  := "", ;
      cTemp22 := "", ;
      nHandle := 0, ;
      nUkup   := 0, ;
      nUkup1  := 0

      IF !File(cMainDir + "\izv\nagser.dbf")
	 alert("Baza dobitnika ne postoji!", {" OK "})
	 RETURN NIL
      ENDIF

      cTemp = cMainDir + "\izv\NagSer"
      USE &(cTemp) NEW
      GO TOP

      INDEX ON code TO Nagser
      SET INDEX TO NagSer
      GO TOP

      BEGIN SEQUENCE

      IF NagSer->( Eof() ) .AND. NagSer->( Bof() )
	 alert("Baza dobitnika prazna!", {" OK "})
	 BREAK
      ENDIF

      cTemp  = cMainDir + "\izv\izv" + AllTrim( Str( Kolo->kolo ) ) + ".txt"
      cTemp22 = "izv" + AllTrim( Str( Kolo->kolo ) ) + ".txt"

      IF File(cTemp)
	 COPY FILE &(cTemp) TO &(cTemp22)
      ENDIF

      IF !File( cTemp )
	 SET ALTERNATE TO &(cTemp22)
      ELSE
	 SET ALTERNATE TO &(cTemp22) ADDITIVE
      ENDIF

      SET ALTERNATE ON
      SET CONSOLE OFF

      ? Replicate("*", 80)
      ? "NOVCANE NAGRADE"
      ? Replicate("*", 80)

      NagSer->( dbSeek(1) )

      DO WHILE NagSer->code == 1 .AND. !NagSer->( Eof() )

	 nNag = NagSer->nagrada

	 ?
	 ? AllTrim(Str(nNag)) + ". nagrada"
	 ?

	 DO WHILE nNag == NagSer->nagrada .AND. NagSer->code == 1 .AND. !NagSer->( Eof() )

	    ? FMT0L( Str(NagSer->serija), 8 )

	    PrLis1(NagSer->serija)

	    NagSer->( dbSkip() )

	 ENDDO

      ENDDO

      NagSer->( dbSeek(2) )

      IF NagSer->( Found() )

	 ? Replicate("*", 80)
	 ? "ZAMENA"
	 ? Replicate("*", 80)

	 DO WHILE NagSer->code == 2 .AND. !NagSer->(Eof())

	    nUkup = Zamena( NagSer->serija )

	    ?
	    ? "Izvucen broj za zamenu: " + AllTrim( Str(NagSer->serija) )
	    ? "Ukupno dobitnika      : " + AllTrim( Str( nUkup ) )

	    nUkup1 += nUkup

	    NagSer->( dbSkip() )

	 ENDDO

	 ?
	 ? "Ukupno dobitnika: " + AllTrim( Str(nUkup1) )

      ENDIF

      NagSer->( dbSeek(3) )

      IF NagSer->( Found() )

	 ? Replicate("*", 80)
	 ? "ROBNE NAGRADE"
	 ? Replicate("*", 80)

	 DO WHILE NagSer->code == 3 .AND. !NagSer->(Eof())

	    NagSer->( dbSkip() )

	 ENDDO

      ENDIF

      CLOSE ALTERNATE
      SET CONSOLE ON
      SET ALTERNATE OFF
      CLOSE ALTERNATE

      IniPtr()

      cTemp2 = "part1.prt"

      nHandle = FCreate(cTemp2)
      FWrite(nHandle, padc("IZVESTAJ", 80, " "))
      FClose(nHandle)

      cTempD = "part2.prt"

      COPY FILE &(cTemp22) TO &(cTempD)

      Prt3(.F.)

      END SEQUENCE

      CLOSE NagSer
      Select( nSelect )

RETURN NIL

STATIC FUNCTION Zamena( nZam )

LOCAL nRet    := 0, ;
      nSelect := Select()

      nRet = LastTwo(1, Kolo->ukupno, nZam)

      USE Prod NEW
      GO TOP

      DO WHILE !Prod->( Eof() )

	 nRet -= LastTwo(Prod->od, Prod->do, nZam)

	 Prod->( dbSkip() )

      ENDDO

      CLOSE Prod
      Select(nSelect)

RETURN nRet

* u opseg od - do nalazi koliko ima brojeva koji se zavrsavaju sa nBr
FUNCTION LastTwo(nOd, nDo, nBr)

LOCAL nRet := 0, ;
      nOd2 := 0, ;
      nDo2 := 0, ;
      cBr  := 0, ;
      nTho := 0

      IF nBr > nDo
	 RETURN 0
      ENDIF


      cBr = AllTrim( Str(nBr) )

      nTho = Val( "1" + Replicate( "0", Len(cBr) ) )

      nOd2 = Val( Right( Str(nOd), Len(cBr) ) )
      nDo2 = Val( Right( Str(nDo), Len(cBr) ) )

      IF nOd2 <= nBr
	 nOd += (nTho - nOd2)
	 ++nRet
      ELSE
	 nOd += (nTho - nOd2)
      ENDIF

      IF nDo2 >= nBr
	 nDo -= nDo2
	 ++nRet
      ELSE
	 nDo -= nDo2
      ENDIF

      nRet += Int( (nDo - nOd) / nTho )

RETURN nRet
