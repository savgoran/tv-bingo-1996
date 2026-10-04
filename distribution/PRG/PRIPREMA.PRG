#include "sixcdx2.ch"
#include "machsix.ch"
#include "commands.ch"
#include "inkey.ch"
#include "fileio.ch"
#include "topv.ch"

* NAPOMENA
* Funkcija Prip() kreira CNLIST.DAT duzine:
* (broj_prodatih-kartica * broj_kombinacija) * 16 + heder(40) + 16(end 0xfe)

FUNCTION Prip()

LOCAL cOldScreen := "", ;
      nHndCLST	 := 0, ;
      nHndCLST5  := 0, ;
      nHndCLSTLC := 0, ;
      nHandle  := 0, ;
      t_kolo   := 0, ;
      t_pass   := SPACE(9), ;
      nBrSer   := 0, ;
      cFile    := "",;
      nCurrFin := 0,;
      nPercCoef:= 0,;
      nTemp    := 0,;
      lDodavanje := .F.

PRIVATE nUkup := 0

#ifdef ZASTITA

      if !SentQuery( 12, "7177" )
	 CLOSE ALL
	 setcolor("w/n")
	 CLS
	 ? "Error(1002) Pozovite servis!!!"
	 QUIT
      endif

#endif

      USE Fond NEW VIA "SIXCDX"
      SET TAG TO kolo
      GO TOP

      GO BOTTOM

      IF Fond->status == .T. .OR. ( Fond->( Eof() ) .AND. Fond->( Bof() ) )
	 ErrBeep()
	 al_box("Kolo nije otvoreno!",1,{" OK "},1,9,25,15,55)
	 CLOSE ALL
	 RETURN NIL
      ELSE
	 t_kolo = Fond->kolo
      ENDIF

      IF al_box("Priprema izvlacenja za kolo br. " + AllTrim( Str(t_kolo) ) + "?",2,{" DA "," NE "},2,9,20,15,60) = 2
	 CLOSE ALL
	 RETURN NIL
      ENDIF

      * NewBase()

      USE Serija NEW VIA "SIXCDX"
      SET TAG TO broj
      GO TOP

      USE LISTIC5 NEW VIA "SIXCDX" PASSWORD "[REDACTED]"
      GO TOP

      USE Opseg NEW VIA "DBFNTX"
      ZAP
      INDEX ON FMT0L( Str( serija ), 4 ) + FMT0L( Str( od ), 8 ) TO opseg
      SET INDEX TO opseg
      GO TOP

      USE Zastup NEW VIA "SIXCDX"
      SET TAG TO brzas
      GO TOP

      USE Razd NEW VIA "SIXCDX"
      SET TAG TO serod
      GO TOP

      nUkup = Koliko()
      nPercCoef := 100 / nUkup

      nTemp := al_box("Ukupno prodatih kartica: " + Str(nUkup,8), 3, {" DODAVANJE ", " POTPUNA "," PREKID "}, 3, 9, 20, 15, 60)
      DO CASE
      CASE nTemp = 1
	lDodavanje := .T.
      CASE nTemp = 3
	CLOSE ALL
	RETURN NIL
      ENDCASE

/*
      IF al_box("Ukupno prodatih kartica: " + Str(nUkup,8), 2, {" OK "," PREKID "}, 2, 9, 20, 15, 60) = 2
	 CLOSE ALL
	 RETURN NIL
      ENDIF
*/
      IF Razd->(Bof()) .AND. Razd->(Eof())
	 ErrBeep()
	 al_box("Nema razduzenja!", 1, {" OK "}, 1, 9, 20, 15, 55)
	 CLOSE ALL
	 RETURN NIL
      ENDIF

      Opseg->( __dbZap() )

      Razd->(dbGoTop())

      msg_start(9,25,15,55)
      msg("Kreiram CNLIST.DAT")

      IF !lDodavanje
	nHndCLSTLC = FCreate( "cnlistlc.dat" )
	WriteHed(nHndCLSTLC, t_kolo, nUkup)
	nHndCLST = FCreate( "cnlist.dat" )
	WriteHed(nHndCLST, t_kolo, nUkup)
      ELSE
	* nHndCLST5 = FOpen( "cnlist5.dat", FO_READWRITE )
	* FWrite( nHndCLST5, Replicate( Chr(0), 40 ), 40 )
	* FSeek( nHndCLST5, -10, FS_END)

	nHndCLSTLC = FOpen( "cnlistlc.dat", FO_READWRITE )
	WriteHed(nHndCLSTLC, t_kolo, nUkup)
	FSeek( nHndCLSTLC, -16, FS_END )

	nHndCLST = FOpen( "cnlist.dat", FO_READWRITE )
	WriteHed(nHndCLST, t_kolo, nUkup)
	FSeek( nHndCLST, -16, FS_END )
      ENDIF

      DO WHILE !Razd->(Eof())

	 nCurrFin += (Razd->kart - Razd->od)

	 IF lDodavanje
	   IF Razd->obrada
	     Razd->(dbSkip())
	     LOOP
	   ENDIF
	 ENDIF

	 IF nBrSer != Razd->serija

	    nBrSer = Razd->serija

	    FClose(nHandle)

	    Serija->( dbSeek( Razd->serija ) )

	    cFile = AllTrim(Serija->path) + "codlis.dat"
	    nHandle = FOpen(cFile, FO_READ)

	    IF nHandle == -1
	       ErrBeep()
	       al_box("CODLIS.DAT serija " + AllTrim(Str(Razd->serija)) + " ne postoji!", 1, {" OK "}, 1, 9, 20, 16, 60)
	       EXIT
	    ENDIF

	 ENDIF

	 Zastup->(dbSeek(Razd->zastup))

	 Opseg->(dbAppend())

	 REPLACE Opseg->serija WITH Razd->serija, ;
		 Opseg->od     WITH Razd->od, ;
		 Opseg->do     WITH Razd->kart - 1, ;
		 Opseg->mesto  WITH Zastup->mesto, ;
		 Opseg->brzas  WITH Zastup->brzas

	 REPLACE Razd->obrada  WITH .T.

	 Extract( Razd->od, Razd->kart - 1, nHandle, nHndCLST, Serija->poc_br )

	 IF Razd->zastup = 500
	   Extract( Razd->od, Razd->kart - 1, nHandle, nHndCLSTLC, Serija->poc_br )
	 ENDIF

	 msg("Kreiram CNLIST.DAT (" + AllTrim(Str(Int(Round(nPercCoef * nCurrFin, 0)))) + "%)")

	 Razd->( dbSkip() )

      ENDDO

      msg_end()

      // end of cnlist file
      FWrite( nHndCLST, Replicate( Chr( 254 ), 16 ) )
      FWrite( nHndCLSTLC, Replicate( Chr( 254 ), 16 ) )
      * FWrite( nHndCLST5, Replicate( Chr( 254 ), 10 ) )

      FClose( nHandle )
      FClose( nHndCLST )
      FClose( nHndCLSTLC )

      //PutHeader5( t_kolo )

      CLOSE ALL

RETURN NIL

STATIC FUNCTION MTrans( nStart, nEnd )

      nStart = ( ( nStart - 1 ) * BR_KOMB ) + 1
      nEnd   = ( ( nEnd - 1 ) * BR_KOMB ) + BR_KOMB

RETURN NIL

STATIC FUNCTION MTrans5( nStart, nEnd )

      nStart = ( ( nStart - 1 ) * BR_KOMB536 ) + 1
      nEnd   = ( ( nEnd - 1 ) * BR_KOMB536 ) + BR_KOMB536

RETURN NIL

STATIC FUNCTION Extract(nStart, nEnd, nHandle, nHandle1, nPocBr)

LOCAL cBuff := Space(16), ;
      cTemp   := "", ;
      nRelRBK := 0

      MTrans( @nStart, @nEnd )

      DO WHILE nStart <= nEnd

	 nRelRBK = CnRel(nStart, nPocBr)
	 FSeek( nHandle, 23 + ( 16 * ( nRelRBK - 1 ) ) )

	 FRead(nHandle, @cBuff, 16)

	 cTemp = L2Bin(nStart)

	 PutSer(cTemp, Razd->serija)

	 cTemp += SubStr(cBuff, 5)

	 FWrite(nHandle1, cTemp)

	 ++ nStart

      ENDDO

RETURN NIL

STATIC FUNCTION Extract5( nStart, nEnd, nHandle )

LOCAL cBuff := Space(16), ;
      cTemp   := "", ;
      nRelRBK := 0

      MTrans5( @nStart, @nEnd )

      //Listic5->( dbGoTo( nStart ) )

      DO WHILE nStart <= nEnd

	 nRelRBK := CnRel5( nStart )
	 Listic5->( dbGoto( nRelRBK ) )
	 cTemp = L2Bin( nStart )

	 PutSer( cTemp, Razd->serija )

	 cTemp += GenOneCod()

	 FWrite(nHandle, cTemp)

	 // gore je dbGoto
	 // Listic5->( dbSkip() )

	 ++ nStart

      ENDDO

RETURN NIL

STATIC FUNCTION Koliko()

LOCAL nRet := 0

      Razd->( dbGoTop() )
      DO WHILE !Razd->(Eof())
	 nRet += Razd->kart - Razd->od
	 Razd->(dbSkip())
      ENDDO

      nTemp = Perc(nRet * Fond->cena, Fond->fond)
      nTemp = Perc(nTemp, Fond->pnov_nag)

      REPLACE Fond->ukup_kart WITH nRet, ;
	      Fond->ukup_fond WITH nRet * Fond->cena, ;
	      Fond->v15       WITH Perc( nTemp, Fond->p15 ), ;
	      Fond->v14       WITH Perc( nTemp, Fond->p14 ), ;
	      Fond->v13       WITH Perc( nTemp, Fond->p13 ), ;
	      Fond->vz	      WITH Perc( nTemp, Fond->pz  )

RETURN nRet

* heder CNLIST.DAT (40)
STATIC FUNCTION WriteHed(nHandle, nKolo, nUkup)

LOCAL nFond := 0

      FWrite(nHandle, FMT0L( Str( nKolo ), 3 ) )			 && 00: comment (3)
      FWrite(nHandle, L2Bin( Fond->v15 * 100 ),  4 )			 && 03: fond 15
      FWrite(nHandle, L2Bin( Fond->v14 * 100 ),  4 )			 && 07: fond 14
      FWrite(nHandle, L2Bin( Fond->v13 * 100 ),  4 )			 && 11: fond 13
      FWrite(nHandle, L2Bin( Fond->vz  * 100 ),  4 )			 && 15: fond zamena
      FWrite(nHandle, L2Bin( nUkup ), 4 )				 && 19: ukupno komb
      FWrite(nHandle, L2Bin( Perc( ( nUkup * Fond->cena ), Fond->fond ) ;
				     * 100 ),  4 )			 && 23: ukupan fond
      FWrite(nHandle, Replicate( Chr(0), 13 ) ) 			 && 27: filler

RETURN NIL

STATIC FUNCTION NewBase()

       dbCreate("OPSEG",    {;
			   {"serija",      "N",  4,  0}, ;
                           {"od",          "N",  8,  0}, ;
			   {"do",          "N",  8,  0}, ;
			   {"mesto",       "C", 20,  0}, ;
			   {"brzas",       "N",  4,  0}  ;
			  }, "SIXCDX")

       dbCreate("NAGSER",   {;
			   {"code",        "N",  1,  0}, ;
			   {"nag",         "N",  2,  0}, ;
			   {"serija",      "N",  4,  0}, ;
			   {"rbk",         "N",  8,  0}, ;
			   {"mesto",       "C", 20,  0}, ;
			   {"brzas",       "N",  4,  0}, ;
			   {"naziv",       "C", 20,  0}  ;
			  }, "SIXCDX")

       USE NAGRADE
       REPLACE SERIJA WITH 0  ALL
       REPLACE BRSER  WITH 0  ALL
       REPLACE MESTO  WITH "" ALL
       REPLACE BRZAS  WITH 0  ALL
       REPLACE TIP    WITH 0  ALL
       CLOSE ALL

RETURN NIL

FUNCTION PutHeader5( nKolo )

 Local nHandle := 0

      nHandle = FOpen( "cnlist5.dat", FO_READWRITE )

      FSeek( nHandle, 0, 0 )

      FWrite(nHandle, FMT0L( Str( nKolo ), 4 ) )			 && 00: comment (3)
      FWrite(nHandle, L2Bin( Fond->v536  * 100 ),  4 )			 && 03: fond 5/36
      FWrite(nHandle, L2Bin( Fond->v5361 * 100 ),  4 )			 && 03: fond 5+1/36

      FClose( nHandle )

RETURN NIL

/*
FUNCTION Test5()

 Local nHandle, ;
       nOd := 0, ;
       nDo := 0, ;
       cBuff := Space(10), ;
       cRBK := Space(4), ;
       nRbk := 0

    nHandle := FOpen("cnlist5.dat", FO_READ)
    if nHandle != -1

       FSeek(nHandle, 40, 0)
       while .t.
	 if FRead(nHandle, @cBuff, 10) == 0
	    exit
	 endif
	 cRBK := Left(cBuff,4)
	 ExSer(cRBK)
	 nRBK := Bin2L(cRBK)
       enddo

       FClose(nHandle)

    endif

RETURN NIL
*/
