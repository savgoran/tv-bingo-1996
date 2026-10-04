#include "sixcdx2.ch"
#include "machsix.ch"
#include "commands.ch"

#define CRLF	      Chr(13) + Chr(10)

FUNCTION ExIzvRep()

LOCAL i       := 0, ;
      nHandle := 0, ;
      cBuff   := Space(12), ;
      cPatt   := "", ;
      cPatt1  := "", ;
      nHow    := 0

PRIVATE aBroj	:= {}, ;
	aBroj5	:= {}, ;
	cKolo	:= 0 , ;
	cDatum	:= "", ;
	nDob15	:= 0 , ;
	nDob14	:= 0 , ;
	nDob13	:= 0 , ;
	nDob5	:= 0

PRIVATE lCreHit := .F.

      IF !File("cpatt.dat")
	 alert("Nema podataka o izvlacenju!")
	 RETURN NIL
      ENDIF

      nHandle = FOpen("cpatt.dat")

      FRead(nHandle, @cBuff, 3)
      cKolo = SubStr(cBuff, 1, 3)

      FRead(nHandle, @cBuff, 12)    && pre 24. broja
      cPatt = SubStr(cBuff, 1)

      FRead(nHandle, @cBuff, 4)
      nDob15 = Bin2L( cBuff )

      FRead(nHandle, @cBuff, 4)
      nDob14 = Bin2L( cBuff )

      FRead(nHandle, @cBuff, 4)
      nDob13 = Bin2L( cBuff )

      FRead(nHandle, @cBuff, 2)
      nHow = Val( SubStr(cBuff, 1, 2) )

      FOR i = 1 TO nHow
	  FRead( nHandle, @cBuff, 2 )
	  aadd( aBroj, SubStr( cBuff, 1, 2 ) )
      NEXT

      FRead(nHandle, @cBuff, 8)
      cDatum := CtoD( cBuff )

      FClose(nHandle)

      // 5 od 36
      nHandle = FOpen("cpatt5.dat")

      // cKolo
      FRead(nHandle, @cBuff, 4)
      // cPatt
      FRead(nHandle, @cBuff, 6)

      // broj dobitnika
      FRead(nHandle, @cBuff, 4)
      nDob5 = Bin2L( cBuff )

      FRead(nHandle, @cBuff, 2)
      nHow = Val( SubStr( cBuff, 1, 2 ) )

      FOR i = 1 TO nHow
	  FRead( nHandle, @cBuff, 2 )
	  aadd( aBroj5, SubStr( cBuff, 1, 2 ) )
      NEXT

      FClose(nHandle)

      msg_start(9,25,15,55)

      BEGIN SEQUENCE

/*
      IF !File("hit.dbf") .OR. !File("hit.cdx")

	 lCreHit = .T.

      ELSE

	 IF al_box( "Kreirati HIT.DAT?", 2, {" DA "," NE "}, 2, 9, 25, 15, 55 ) == 1
	    lCreHit = .T.
	 ELSE
	    lCreHit = .F.
	 ENDIF

      ENDIF

      IF lCreHit

	 // msg("U toku je kreiranje HIT.DAT!")
	 // IF !FillData(cPatt, cPatt1)
	 //    BREAK
	 // ENDIF

	 msg("Azuriranje podataka...")

      ENDIF
*/

      ParseHit()

      msg("Kreiram izvestaj...")
      GenRep()

      END SEQUENCE

      msg_end()

RETURN NIL

STATIC FUNCTION FillData( cPatt )

LOCAL nHandle := 0, ;
      cSerBr  := Replicate(Chr(0), 6)

      IF !XMS_Init()
	 alert("Nema podrske za XMS memoriju", {" OK "})
	 RETURN .F.
      ENDIF

      IF !XMS_Alloc( FileSize("cnlist.dat") )
	 alert("Nedovoljno XMS meorije", {" OK "})
	 RETURN .F.
      ENDIF

      F2XMS("cnlist.dat")

      msg("U toku je kreiranje HIT.DAT!")

      nHandle = FCreate("hit.dat")

      * upis serija do 24. broja
      WrTicket(cPatt, 7, 0, nHandle, cSerBr)

      FClose(nHandle)

      XMS_Close()

RETURN .T.

STATIC FUNCTION ParseHit()

      Local nHandle  := 0
      Local cBuff    := Space(6)
      Local nBrSer   := 0
      Local nRBK     := 0
      Local cTemp    := ""
      Local nUkupSer := 0
      Local nCnt     := 0
      Local cText    := ""
      Local nTmpHnd  := 0

      FileDelete("hit.cdx")

      dbCreate("hit.dbf", {;
			    {"pogodak",    "n",  2, 0}, ;
			    {"serija",     "n",  4, 0}, ;
			    {"rbk",        "n",  8, 0}, ;
			    {"mesto",      "c", 20, 0}, ;
			    {"brzas",      "n",  4, 0}  ;
			  }, "SIXCDX")


      USE Opseg NEW
      INDEX ON FMT0L( Str( serija ), 4 ) + FMT0L( Str( od ), 8 ) TO opseg
      SET INDEX TO opseg
      GO TOP

      USE hit NEW VIA "SIXCDX"
      INDEX ON IndFunc() + FMT0L( Str( brzas ), 4 ) + FMT0L( Str( serija ), 4 ) + FMT0L( Str( rbk ), 7 ) TAG hit OF hit
      SET INDEX TO hit
      SET TAG TO hit
      GO TOP

      altd()

      nUkupSer = Int( FileSize("hit.dat") / 6 )

      msg("create...")

      nTmpHnd = FCreate( "temp.$$$" )

      nHandle = FOpen("hit.dat")

      DO WHILE .T.

	 cBuff = Space(6)

	 IF FRead(nHandle, @cBuff, 6) == 0
	    EXIT
	 ENDIF

	 cTemp = SubStr(cBuff, 3)

	 nBrSer = ExSer(cTemp)
	 nRBK	= Bin2L(cTemp)

	 Opseg->( dbSeek( FMT0L( Str( nBrSer ), 4 ) + FMT0L( Str( ConvRBK( nRBK ) ), 8 ), .T. ) )
	 IF !Opseg->( Found() )
	    Opseg->( dbSkip( -1 ) )
	 ENDIF

	 cText = Str( Asc( Left( cBuff, 1 ) ), 2 ) + "," + AllTrim( Str( nBrSer ) ) + "," + ;
		 AllTrim( Str( nRBK ) ) + "," + AllTrim( Opseg->mesto ) + "," + ;
		 AllTrim( Str( Opseg->brzas ) )

	 FWrite( nTmpHnd, cText + Chr(13) + Chr(10) )

	 ++nCnt
	 msg( Str( Int( ( nCnt / nUkupSer) * 100 ), 3 ) + "%" )

      ENDDO

      FClose(nHandle)
      FClose(nTmpHnd)

      msg("appending...")
      APPEND FROM temp.$$$ DELIMITED WITH ","

      CLOSE ALL

      FileDelete( "temp.$$$" )

RETURN

FUNCTION IndFunc()
RETURN FMT0L( Str( 16 - Hit->pogodak ), 2 )

STATIC FUNCTION GenRep()

LOCAL t_brpog	:= 0, ;
      t_brzas	:= 0, ;
      t_ukupdob := 0, ;
      tTmpCnt	:= 1, ;
      nUkup	:= 0, ;
      nFond	:= 0, ;
      nTemp	:= 0, ;
      nTemp33	:= 0, ;
      aDob	:= {4, 5, 6, 7, 8}, ;
      kkk	:= 1, ;
      tt9	:= 0, ;
      tt8	:= 0, ;
      tt7	:= 0, ;
      aFond	:= {}, ;
      nCnt	:= 1, ;
      aTri	:= {}, ;
      c536Text	:= ""

      USE Mkolo NEW VIA "SIXCDX"
      GO BOTTOM

      // nUkup = ( mkolo->ukupno * 5 ) / 2

      USE Fond NEW VIA "SIXCDX"
      SET TAG TO kolo
      GO TOP

      Fond->( dbSeek( Val(cKolo) ) )

      //USE Hit5 NEW VIA "SIXCDX"

      USE Hit NEW VIA "SIXCDX"

      INDEX ON IndFunc() + FMT0L( Str( brzas ), 4 ) + FMT0L( Str( serija ), 4 ) + FMT0L( Str( rbk ), 7 ) TAG hit OF hit
      INDEX ON IndFunc() + FMT0L( Str( serija ), 4 ) + FMT0L( Str( rbk ), 7 ) TAG hitz OF hit

      SET INDEX TO hit
      SET TAG TO hit
      GO TOP

      IniPtr()
      Prt1()
      Prt2()

      nTemp = Perc( Fond->ukup_fond, Fond->fond )
      nTemp1 = Perc( nTemp, Fond->pnov_nag )

      aTri  := Get3()

      aFond = SrFond()

      ? FontB + BoldON + padc("IZVESTAJ O IZVLACENJU - EXTRA TOMBOLA", 93, " ") + BoldOFF
      ?

      ? padc( "Kolo: " + BoldON + AllTrim( Str( Fond->kolo ) ) + BoldOFF, 93, " " )
      ?
      ? "Datum izvlacenja: " + BoldON + DtoC( cDatum ) + BOldOFF
      ?
      ?
      ? "Broj prodatih kartica: " + BoldON + Str(Fond->ukup_kart, 8) + BoldOFF
      ?
      ?
      ? "Ukupni fond                      " + BoldON + Str(Fond->ukup_fond, 14, 2) + " EUR" + BoldOFF
      ?
      ? "Fond za nagrade         " + BoldON + Str(Fond->fond, 2) + "%      " + Str(Perc(Fond->ukup_fond, Fond->fond), 14, 2) + " EUR" + BoldOFF
      ?
*      ?
*      ? "Fond za novcane nagrade " + BoldON + Str(Fond->pnov_nag,2) + "%      " + Str(Perc(nTemp, Fond->pnov_nag), 14, 2) + " EUR" + BoldOFF
*      ?
*      ? "Fond za robne nagrade   " + BoldON + Str(Fond->prob_nag ,2) + "%      " + Str(Perc(nTemp, Fond->prob_nag), 14, 2) + BoldOFF + " EUR"
      ?
      ?
      ?
      ? "Fond za 1. nagradu      " + BoldON + Str(Fond->p15 ,2) + "%      " + Str(Perc(nTemp1, Fond->p15 ), 14, 2) + BoldOFF + " EUR"
      ?
      ? "Fond za 2. nagradu      " + BoldON + Str(Fond->p14 ,2) + "%      " + Str(Perc(nTemp1, Fond->p14 ), 14, 2) + BoldOFF + " EUR"
      ?
      ? "Fond za 3. nagradu      " + BoldON + Str(Fond->p13 ,2) + "%      " + Str(Perc(nTemp1, Fond->p13 ), 14, 2) + BoldOFF + " EUR"
      ?
*      ? "Fond za nagradu 5/36    " + BoldON + "         " + Str( Fond->v536, 14, 2) + BoldOFF + " EUR"
*      ?
*      ? "Fond za nagradu 5+1/36  " + BoldON + "         " + Str( Fond->v5361, 14, 2) + BoldOFF + " EUR"
*      ?
      ?
      ? "IZVESTAJ O DOBICIMA     dobitnika           vrednost"
      ?

      ? "1. nagrada            :    " + Str( aFond[1,1], 6 ) + Space( 5 ) + Str( aFond[1,2], 14, 2 )
      ?
      ? "2. nagrada            :    " + Str( aFond[2,1], 6 ) + Space( 5 ) + Str( aFond[2,2], 14, 2 )
      ?
      ? "3. nagrada            :    " + Str( aFond[3,1], 6 ) + Space( 5 ) + Str( aFond[3,2], 14, 2 )
      ?
*      c536Text := iif(Len(aBroj5) = 5, "nagrada 5/36          :    ", "nagrada 5+1/36        :    ")
*      ? c536Text + Str( aFond[4,1], 6 ) + Space( 5 ) + Str( aFond[4,2], 14, 2 )
*      ?
/*
      ?
      ? "BROJEVI ZA ZAMENU"
      ?
      ? BoldON + Zamena() + BoldOFF
*/
      ?
      ?
      ? "Za novcane nagrade izvuceni su sledeci brojevi:"
      ?
      ? Space(15) + BoldON

      FOR i = 1 TO Len( aBroj )
	  ?? aBroj[i] + " "
	  IF i % 20 == 0
	     ?
	     ? Space(15)
	  ENDIF
      NEXT

/*
      ?
      ? 'Za igru "5 od 36" su izvuceni sledeci brojevi:'
      ?
      ? Space(15) + BoldON

      FOR i = 1 TO Len(aBroj5)
	  ?? aBroj5[i] + " "
      NEXT
*/
      ?
      ?

      Nagrada( 15, Fond->v15 )
      Nagrada( 14, Fond->v14 )
      //Nagrada( 13, Fond->v13 )

      ? NewPage
      // RepPrice( 14 )
      RepPrice( 13 )
/*
      if Len(aBroj5) = 5
	Nagrada5( 5, Fond->v536 )
      elseif Len(aBroj) > 5
	Nagrada5( 5, Fond->v5361 )
      endif
*/
      RobNag()

      SET TAG TO HitZ
      GO TOP

      ? NewPage
      ? BoldON + padc( "IZGLED DOBITNIH KOMBINACIJA", 93, " " ) + BoldOFF
      ?
      IzgLis(15)
      IzgLis(14)

      IF aFond[3,2] >= 50
	IzgLis(13)
      ENDIF

*      IzgLis5(5)

      ? NewPage
      ? BoldON + padc( "NAGRADE SORTIRANE PO REDNOM BROJU", 93, " " ) + BoldOFF
      ?

      NagradaZ( 15, aFond[1,2] )
      NagradaZ( 14, aFond[2,2] )
      NagradaZ( 13, aFond[3,2] )

      Prt3()

      IF File( "kolo" + AllTrim(Str(Fond->kolo)) + ".prn" )
	 DeleteFile( "kolo" + AllTrim(Str(Fond->kolo)) + ".prn" )
      ENDIF

      IF File("tt.prn")
	 RenameFile( "tt.prn", "kolo" + AllTrim(Str(Fond->kolo)) + ".prn" )
      ENDIF

      ClrPRcod( "part2.prt" )

      RenameFile( "part2.prt", "kolo" + AllTrim(Str(Fond->kolo)) + ".txt" )

      CLOSE ALL

      FileDelete( "part1.prt" )
      FileDelete( "hit.cdx" )

RETURN NIL

FUNCTION SrFond()

LOCAL aRet  := {}, ;
      nTemp := 0

      aadd( aRet, { nDob15, Fond->v15 / nDob15 } )
      aadd( aRet, { nDob14, Fond->v14 / nDob14 } )
      if nDob14 == 0
	 aadd( aRet, { nDob13, (Fond->v13 + Fond->v14) / nDob13 } )
      else
	 aadd( aRet, { nDob13, Fond->v13 / nDob13 } )
      endif
      if Len(aBroj5) = 5
	aadd( aRet, { nDob5,  Fond->v536 / nDob5 } )
      elseif Len(aBroj5) > 5
	aadd( aRet, { nDob5,  Fond->v5361 / nDob5 } )
      endif

      REPLACE Fond->d15  WITH nDob15, ;
	      Fond->d14  WITH nDob14, ;
	      Fond->d13  WITH nDob13, ;
	      Fond->datum WITH cDatum

RETURN aRet

FUNCTION Nagrada( nNag, nFond )

LOCAL t_brpog	:= 0, ;
      t_brzas	:= 0, ;
      nTmpCnt	:= 0, ;
      t_ukupdob := 0

      ? "NAGRADA " + BoldON + FMT0L(Str(nNag),2) + BoldOFF + Space(4) + "Kolo: " + BoldON + AllTrim( Str(Fond->kolo) ) + BoldOFF + Space(4) + "Vrednost: " + BoldON + Str( nFond, 14, 2 ) + BoldOFF + " EUR"
      //? "NAGRADA " + BoldON + FMT0L(Str(nNag),2) + BoldOFF + Space(4) + "Kolo: " + BoldON + AllTrim( Str(Fond->kolo) ) + BoldOFF
      ? "==========================================================="
      ?

      Hit->( dbSeek( FMT0L( Str(16 - nNag), 2)	) )
      IF Hit->(Found())

	 // ? FontS + BoldOFF
	 ? BoldOFF

	 t_brpog = Hit->pogodak
	 nTmpCnt = 1

	 DO WHILE Hit->pogodak == t_brpog .AND. !Hit->(Eof())

	    IF Hit->brzas != t_brzas

	       ? BoldON + "Zastup.br.: " + FMT0L( Str(Hit->brzas), 4) + " Mesto: " + Hit->mesto + BoldOFF
	       ?

	       t_brzas = Hit->brzas
	       nTmpCnt = 1

	    ENDIF

	    ?? FMT0L(Str(Hit->serija), 3) + "/" + FMT0L( Str( ConvRBK( Hit->rbk ) ), 7 ) + " "

	    ++nTmpCnt
	    IF Int( nTmpCnt % 9 ) == 0
	       ?
	       nTmpCnt = 1
	    ENDIF

	    ++ t_ukupdob

	    Hit->(dbSkip())

	 ENDDO

	 ? FontB
	 ?
	 ? BoldON + "Ukupno dobitnika: " + Str(t_ukupdob, 7)
	 ?

	 t_ukupdob := 0

      ELSE

	 ? BoldON + "NEMA DOBITNIKA" + BoldOFF
	 ?

      ENDIF

RETURN NIL

STATIC FUNCTION RobNag()

LOCAL nOldSel := Select()

      IF !File("nagrade.dbf")
	 RETURN NIL
      ENDIF

      USE Nagrade NEW VIA "SIXCDX"
      GO TOP

      ? FontB + "ROBNE NAGRADE"
      ? "==========================================================="
      ?

      IF Bof() .AND. Eof()

	 ? "NISU IZVUCENE"

      ELSE

	 DO WHILE !Eof()

	    IF Nagrade->tip == 0
	       ? Str(brnag,3) + ".  " + naziv + Space(2) + FMT0L(Str(serija),3) + "/" + FMT0L(Str(brser),8) + Space(2) +;
		 "Zastupnik: " + Str(brzas,4) + " - " + mesto
	    ELSE
	       ? Str(brnag,3) + ".  " + naziv + Space(2) + Str(brser,12) + Space(2) +;
		 "Ukupno dobitnika: " + AllTrim( mesto )
	    ENDIF

	    dbSkip()

	 ENDDO

      ENDIF

      CLOSE Nagrade

      Select(nOldSel)

RETURN NIL

* cisti part2.prt od ekranskih atributa
FUNCTION ClrPRcod( cFile )

LOCAL nHandle := 0, ;
      nSrc    := 0, ;
      cBuff   := Space(400), ;
      cLine   := "", ;
      nOff    := 0, ;
      lExit   := .T., ;
      nPos    := 0

      nHandle = FCreate("temp.$$$")
      nSrc = FOpen( cFile )

      FSeek( nSrc, 0 )
      DO WHILE lExit

	 FSeek( nSrc, nOff )
	 IF FRead( nSrc, @cBuff, 400 ) == 0
	    lExit = .F.
	 ENDIF

	 nPos = at( CRLF, cBuff )
	 cLine = SubStr( cBuff, 1, nPos - 1 )

	 cLine = ClrCod( cLine )
	 FWrite(nHandle, cLine + CRLF)

	 nOff += ( nPos + 1 )

      ENDDO

      FClose( nSrc )
      FClose( nHandle )

      FileDelete( cFile )
      RenameFile( "temp.$$$", cFile )

RETURN NIL

FUNCTION ClrCod( cLine )

LOCAL i    := 0

      FOR i = 1 TO Len( ScrAttr )
	  cLine = StrTran( cLine, ScrAttr[i], "" )
      NEXT

RETURN cLine

FUNCTION IzvCen()

LOCAL i     := 0, ;
      j     := 0, ;
      nPog  := 0, ;
      nCen  := 0, ;
      aTemp := {}, ;
      nTemp := 0

      IF !File("hit.dbf")
	 ErrBeep()
	 alert("HIT.DBF ne postoji!", {" OK "})
	 RETURN NIL
      ENDIF

      IF al_box("Izvestaj o dobicima?", 2, {" DA "," NE "}, 2, 9, 25, 15, 55) == 2
	 RETURN NIL
      ENDIF

      USE Fond NEW VIA "SIXCDX"
      SET TAG TO kolo
      GO BOTTOM

      USE Centar NEW VIA "SIXCDX"
      SET TAG TO broj
      GO TOP

      USE Hit NEW VIA "SIXCDX"
      GO TOP

      DO WHILE !Hit->( Eof() )

	 nCen = Val( Left( Str(Hit->brzas), 1 ) )
	 nPos = AScan(aTemp, {|x| x[1] == nCen})
	 IF nPos == 0
	    aadd(aTemp, {nCen, {0,0,0,0,0}})
	    nPos = Len(aTemp)
	 ENDIF

	 nPog = 11 - Hit->pogodak
	 ++ aTemp[nPos, 2, nPog]

	 Hit->( dbSkip() )

      ENDDO

      IniPtr()
      Prt1()
      Prt2()

      ? FontB + padc("IZVESTAJ O DOBICIMA PO CENTRIMA", 80, " ")
      ? padc("kolo: " + FMT0L( Str( Fond->kolo ), 4 ), 80, " ")
      ?
      ?
      ? Replicate("*", 62)
      ? "Naziv centra            10      9      8      7      6  Ukupno"
      *  XXXXXXXXXXXXXXXXXXXX 99999  99999  99999  99999  99999  999999

      ? Replicate("*", 62)

      FOR i = 1 TO Len(aTemp)

	  Centar->( dbSeek( aTemp[i,1] ) )
	  ? Centar->naziv + " "

	  FOR j = 1 TO 5
	      ?? Str(aTemp[i, 2, j], 5) + "  "
	      nTemp += aTemp[i, 2, j]
	  NEXT

	  ?? BoldON + Str(nTemp,6) + BoldOFF
	  nTemp := 0

      NEXT

      aTemp1 = {0,0,0,0,0}
      FOR i = 1 TO Len(aTemp)
	  FOR j = 1 TO 5
	      aTemp1[j] += aTemp[i, 2, j]
	  NEXT
      NEXT

      ? Replicate("*", 62)

      nTemp := 0
      ? BoldON + Space(21)
      FOR i = 1 TO 5
	  ?? Str(aTemp1[i], 5) + "  "
	  nTemp += aTemp1[i]
      NEXT
      ?? Str(nTemp,6) + BoldOFF

      Prt3()

      CLOSE ALL

RETURN NIL

FUNCTION BrojNag()

 Local i       := 0
 Local nTemp   := 0
 Local nTemp1  := 0
 Local nTemp2  := 0
 Local cOldCen := ""
 Local cNumCen := ""

      IF al_box("Brojcane nagrade?", 2, {" DA "," NE "}, 2, 9, 25, 15, 55) == 2
	 RETURN NIL
      ENDIF

      USE Fond NEW VIA "SIXCDX"
      SET TAG TO Kolo
      GO BOTTOM

      USE Centar NEW VIA "SIXCDX"
      SET TAG TO BROJ
      GO TOP

      USE Opseg NEW VIA "SIXCDX"
      INDEX ON Str(brzas,4) TO temp
      SET INDEX TO temp
      GO TOP

      USE Nagrade NEW VIA "SIXCDX"
      GO TOP

      IniPtr()
      Prt1()
      Prt2()

      DO WHILE !Nagrade->( Eof() )

	 IF Nagrade->tip != 0

	    ? 'KENO - Nagrade "zadnje cifre" - kolo br. ' + FMT0L(Str(Fond->kolo),3)
            ?
	    ? Replicate("*", 25)
	    ? BoldON + Nagrade->naziv + BoldOFF + " " + Str( Nagrade->brser, 4 )
	    ? Replicate("*", 25)

	    Opseg->( dbGoTop() )

	    Centar->( dbGoTop() )
	    DO WHILE !Centar->( Eof() )

	       Opseg->( dbSeek( Str( Centar->broj, 1 ) ) )
	       IF !Opseg->( Eof() )
		  ? "Podcentar: " + BoldON + Centar->naziv + BoldOFF
	       ENDIF

	       DO WHILE Left( AllTrim( Str( Opseg->brzas ) ), 1 ) == Str(Centar->broj,1) .AND. ;
			!Opseg->( Eof() )

		  nTemp = LastTwo( Opseg->od, Opseg->do, Nagrade->brser )

		  IF nTemp > 0
		     ? "Zastupnik : " + FMT0L(Str(Opseg->brzas),4) + "  " + Str(nTemp, 5)
		  ENDIF

		  nTemp1 += nTemp

		  Opseg->( dbSkip() )

	       ENDDO

	       ? Space(10) + "Ukupno: " + BoldON + Str( nTemp1, 5 ) + BoldOFF
	       ?
	       nTemp2 += nTemp1
	       nTemp1 := 0

	       Centar->( dbSkip() )

            ENDDO

	    ? Replicate("*", 25)
	    ? BoldON + Space(10) + "Ukupno: " + Str( nTemp2, 5 ) + BoldOFF
	    nTemp2 = 0

	 ENDIF

	 Nagrade->( dbSkip() )

      ENDDO

      Prt3()

      CLOSE ALL

      DeleteFile("temp.idx")

RETURN NIL

FUNCTION Get3()

 Local nHandle := 0, ;
       aRet    := {}, ;
       nByte   := 0, ;
       cTemp   := "", ;
       cSer    := "", ;
       cBuff3  := Replicate( Chr(0), 400 ), ;
       i       := 0

      nHandle := FOpen( "cpatt3.dat" )

      nByte := FRead( nHandle, @cBuff3, 400 )
      // nByte := ( Int( nByte / 4 ) + 1 ) * 4
      cBuff3 := SubStr( cBuff3, 1, at( Replicate( Chr(0), 4 ), cBuff3 ) - 1 )

      FClose( nHandle )

      FOR i = 1 TO Len( cBuff3 ) STEP 4

	  cTemp = SubStr( cBuff3, i, 4 )
	  cSer = FMT0L( Str( ExSer( cTemp ) ), 3 ) + "/" + FMT0L( Str( Bin2L( cTemp ) ), 7 )

	  IF AScan( aRet, cSer ) == 0
	     aadd( aRet, cSer )
	  ENDIF

      NEXT

RETURN aRet

FUNCTION Zamena()

 Local nOldSel := Select(), ;
       cRet    := ""

   USE Nagrade NEW

   while !Nagrade->( Eof() )

      cRet += FMT0L( Str( Nagrade->brser ), 2 )

      Nagrade->( dbSkip() )

      if !Nagrade->( Eof() )
	 cRet += ", "
      endif

   enddo

   CLOSE Nagrade

   Select( nOldSel )

RETURN cRet

FUNCTION NagradaZ(nNag, nFond)

LOCAL t_brpog	:= 0, ;
      t_brzas	:= 0, ;
      nTmpCnt	:= 1, ;
      t_ukupdob := 0

      ?
      ? "NAGRADA " + BoldON + FMT0L(Str(nNag),2) + BoldOFF + Space(4) + "Kolo: " + BoldON + AllTrim( Str(Fond->kolo) ) + BoldOFF + Space(4) + "Vrednost: " + BoldON + Str( nFond, 14, 2 ) + BoldOFF + " EUR"
      ? "==========================================================="
      ?

      SET SCOPE TO FMT0L( Str(16 - nNag), 2 )
      GO TOP

      ?

      DO WHILE !Hit->(Eof())

	    ?? FMT0L( Str( Hit->Serija), 2 ) + "/" + FMT0L( Str( ConvRBK( Hit->rbk) ), 6 ) + " "

	    ++nTmpCnt
	    IF Int( nTmpCnt % 9 ) == 0
	       ?
	       nTmpCnt = 1
	    ENDIF

	    ++ t_ukupdob

	    Hit->(dbSkip())

      ENDDO

      ? FontB
      ? BoldON + "Ukupno dobitnika: " + Str(t_ukupdob, 7)
      ?
      ?

      t_ukupdob := 0

      SET SCOPE TO
      GO TOP

RETURN NIL

FUNCTION Nagrada5Z(nNag, nFond)

LOCAL t_brpog	:= 0, ;
      t_brzas	:= 0, ;
      nTmpCnt	:= 1, ;
      t_ukupdob := 0, ;
      nOldSel	:= Select()

      Select( "hit5" )

      ?
      ? "NAGRADA " + BoldON + FMT0L(Str(nNag),2) + BoldOFF + Space(4) + "Kolo: " + BoldON + AllTrim( Str(Fond->kolo) ) + BoldOFF + Space(4) + "Vrednost: " + BoldON + Str( nFond, 14, 2 ) + BoldOFF + " EUR"
      ? "==========================================================="
      ?

      ?

      DO WHILE !Hit5->(Eof())

	    ?? FMT0L(Str( Hit5->rbk ), 6) + " "

	    ++nTmpCnt
	    IF Int( nTmpCnt % 12 ) == 0
	       ?
	       nTmpCnt = 1
	    ENDIF

	    ++ t_ukupdob

	    Hit5->(dbSkip())

      ENDDO

      ? FontB
      ? BoldON + "Ukupno dobitnika: " + Str(t_ukupdob, 7)
      ?
      ?

      t_ukupdob := 0

      Select( nOldSel )

RETURN NIL

FUNCTION Nagrada5(nNag, nFond)

LOCAL t_brpog	:= 0, ;
      t_brzas	:= 0, ;
      nTmpCnt	:= 1, ;
      t_ukupdob := 0, ;
      nOldSel	:= Select()

      Select( "hit5" )

      ?
      ? "NAGRADA " + BoldON + FMT0L(Str(nNag),2) + BoldOFF + Space(4) + "Kolo: " + BoldON + AllTrim( Str(Fond->kolo) ) + BoldOFF + Space(4) + "Vrednost: " + BoldON + Str( nFond, 14, 2 ) + BoldOFF + " EUR"
      ? "==========================================================="
      ?

      ?

      DO WHILE !Hit5->(Eof())

	    ? BoldON + "Zastup.br.: " + FMT0L( Str(Hit5->brzas), 4) + " Mesto: " + Hit5->mesto + BoldOFF
	    ?
	    ?? FMT0L( Str( Hit5->serija ), 3) + "/" + FMT0L( Str( Hit5->rbk ), 7 ) + " "

	    ++nTmpCnt
	    IF Int( nTmpCnt % 9 ) == 0
	       ?
	       nTmpCnt = 1
	    ENDIF

	    ++ t_ukupdob

	    Hit5->(dbSkip())

      ENDDO

      ? FontB
      ? BoldON + "Ukupno dobitnika: " + Str(t_ukupdob, 7)
      ?
      ?

      t_ukupdob := 0

      Select( nOldSel )

RETURN NIL

FUNCTION IzgLis( nNag )

LOCAL nOldSel := Select(), ;
      aLis    := {"", "", "", ""}, ;
      aTemp   := {}, ;
      nCnt    := 0, ;
      i       := 0

      ?
      ? "NAGRADA " + BoldON + FMT0L( Str( nNag ), 2 ) + BoldOFF + Space(4) + "Kolo: " + BoldON + AllTrim( Str( Fond->kolo ) ) + BoldOFF
      ? "==========================================================="
      ?

      SET SCOPE TO FMT0L( Str( 16 - nNag ), 2 )
      GO TOP

      DO WHILE !Hit->( Eof() )

	 aTemp := PrLis1(Hit->serija, Hit->RBK)

	 FOR i := 1 TO 4
	     aLis[i] += aTemp[i] + Space(4)
	 NEXT

	 ++nCnt

         Hit->( dbSkip() )

	 IF !Hit->( Eof() )

	    IF nCnt == 2

	       nCnt = 0

	       FOR i = 1 TO 4
		   ? aLis[i]
	       NEXT

	       ?

	       aLis = {"", "", "", ""}

	    ENDIF

	 ELSE

	    IF nCnt > 0

	       FOR i = 1 TO 4
		   ? aLis[i]
	       NEXT

	    ENDIF

	    ?

	 ENDIF

      ENDDO

      Select( nOldSel )

      SET SCOPE TO
      GO TOP

RETURN NIL

FUNCTION IzgLis5( nNag )

LOCAL nOldSel := Select(), ;
      aLis    := {"", "", "", ""}, ;
      aTemp   := {}, ;
      nCnt    := 0, ;
      i       := 0

      ?
      ? "NAGRADA 5 od 36" + Space(4) + "Kolo: " + BoldON + AllTrim( Str( Fond->kolo ) ) + BoldOFF
      ? "==========================================================="
      ?

      Select( "hit5" )
      Hit5->( dbGoTop() )

      DO WHILE !Hit5->( Eof() )

	 aTemp := PrLis1(Hit5->serija, ConvFromRBK( Hit5->RBK ) )

	 FOR i := 1 TO 4
	     aLis[i] += aTemp[i] + Space(4)
	 NEXT

	 ++nCnt

	 Hit5->( dbSkip() )

	 IF !Hit5->( Eof() )

	    IF nCnt == 2

	       nCnt = 0

	       FOR i = 1 TO 4
		   ? aLis[i]
	       NEXT

	       ?

	       aLis = {"", "", "", ""}

	    ENDIF

	 ELSE

	    IF nCnt > 0

	       FOR i = 1 TO 4
		   ? aLis[i]
	       NEXT

	    ENDIF

	    ?

	 ENDIF

      ENDDO

      Select( nOldSel )

RETURN NIL

