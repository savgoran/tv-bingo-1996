#include "sixcdx2.ch"
#include "machsix.ch"
#include "inkey.ch"
#include "commands.ch"
#include "fileio.ch"
#include "topv.ch"

#define CRLF	      Chr(13) + Chr(10)

FUNCTION MakePath()

LOCAL cOldScreen := ""

/*
      IF File("path.cfg")
	 RESTORE FROM path.cfg ADDITIVE
      ENDIF

      IF File("cena.cfg")
	 RESTORE FROM cena.cfg ADDITIVE
      ENDIF
*/

      cPath = padr(cPath, 30, " ")

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(7, 24, 13, 57, "PATH")

      @  9, 26 SAY "Baza listica"
      @ 10, 26 GET cPath PICTURE "@!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
      @ 12, 26 SAY "Cena listica: " GET nCena PICTURE "9999"

      SetCursor(1)
      READ
      SetCursor(0)

      win_rest(cOldScreen)
      vstk_pop()

      IF LastKey() == K_ESC
	 RETURN NIL
      ENDIF

      cPath = AllTrim(cPath)
      IF Right(cPath, 1) != "\"
	 cPath += "\"
      ENDIF

/*
      SAVE TO path.cfg ALL LIKE cPath
      SAVE TO cena.cfg ALL LIKE nCena
*/
      DoneBeep()

RETURN NIL

/*
FUNCTION GetPass(nBr)

LOCAL nIndex  := 0, ;
      nHndCod := 0, ;
      cBuff   := Space(18), ;
      cRet    := "", ;
      i       := 0, ;
      cStr    := "", ;
      aNet    := {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', ;
		  'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', ;
		  'Y', 'Z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}

      nHndCod = FOpen("codcg.dat")

      nUkup = nBr-1

      FSeek(nHndCod, nUkup*18)
      FRead(nHndCod, @cBuff, 18)

      cStr = Sx_DeCrypt(cBuff, "Sandra")

      FOR i = 1 TO 18 STEP 2
	  cRet += aNet[ Val(SubStr(cStr, i, 2)) ]
      NEXT

      FClose(nHndCod)

RETURN cRet
*/

FUNCTION PutZero(nBr)

LOCAL nIndex  := 0, ;
      nHndCod := 0, ;
      cBuff   := Space(18)

      nHndCod = FOpen("codcg.dat", 1)

      nUkup = nBr-1

      FSeek(nHndCod, nUkup * 18)
      FWrite(nHndCod, cBuff)

      FClose(nHndCod)

RETURN NIL

FUNCTION ChkPass(nBr)

LOCAL nIndex  := 0, ;
      nHndCod := 0, ;
      cBuff   := Space(18), ;
      RetVal  := .F.

      nHndCod = FOpen("codcg.dat", 1)

      nUkup = nBr-1

      FSeek(nHndCod, nUkup * 18)
      FRead(nHndCod, @cBuff, 18)

      FClose(nHndCod)

      IF Empty(cBuff)
	 RetVal = .T.
      ENDIF

RETURN RetVal

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


FUNCTION Perc(nSum, nPerc)
RETURN (nSum / 100) * nPerc

FUNCTION UnNag()

LOCAL cOldScreen := "", ;
      i 	 := 0

PRIVATE aGet := {}, ;
	t_brnag    := 1, ;
	t_naziv    := Space(20), ;
	t_slika    := Space(15), ;
	t_ukup	   := 1, ;
	t_broj	   := 0

      IF !File("nagrade.dbf")

	 dbCreate("NAGRADE", {;
			       {"BRNAG",      "N",   4,  0}, ;
			       {"SERIJA",     "N",   4,  0}, ;
			       {"BRSER",      "N",   8,  0}, ;
			       {"NAZIV",      "C",  20,  0}, ;
			       {"SLIKA",      "C",  15,  0}, ;
			       {"MESTO",      "C",  20,  0}, ;
			       {"BRZAS",      "N",   4,  0}, ;
			       {"TIP",        "N",   1,  0}  ;
			     }, "SIXCDX" )

      ENDIF

      USE NAGRADE NEW VIA "SIXCDX"
      SET ORDER TO 0
      GO BOTTOM

      IF LastRec() > 0
	 IF al_box("Brisete bazu?", 2, {" DA "," NE "}, 2, 9, 25, 15, 55) == 1
	    ZAP
	 ENDIF
      ENDIF

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(8, 25, 16, 55, "UNOS NAGRADA")

      UnNagMas()

      DO WHILE .T.

	 SetCursor(1)
	 READ
	 SetCursor(0)

	 IF LastKey() == 27
	    EXIT
	 ENDIF

	 FOR i = 1 TO t_ukup

	     dbAppend()
	     REPLACE brnag    WITH RecNo(), ;
		     naziv    WITH t_naziv, ;
		     slika    WITH t_slika, ;
		     tip      WITH t_broj

	 NEXT

	 t_ukup  = 1
	 t_brnag = RecNo() + 1
	 t_broj  = 0

	 GetList = aGet

      ENDDO

      win_rest(cOldScreen)
      vstk_pop()

      CLOSE ALL

RETURN NIL

STATIC FUNCTION UnNagMas()

      @ 10, 27 SAY "Broj  :" GET t_brnag PICTURE "9999" WHEN .F.
      @ 12, 27 SAY "Naziv :" GET t_naziv PICTURE "@!@K XXXXXXXXXXXXXXXXXXXX"
      @ 13, 27 SAY "Slika :" GET t_slika PICTURE "@!@K XXXXXXXXXXXXXXX"
      @ 14, 27 SAY "Broj  :" GET t_broj  PICTURE "9"
      @ 15, 27 SAY "Ukupno:" GET t_ukup  PICTURE "9999" VALID t_ukup > 0

      aGet = GetList

RETURN NIL

FUNCTION ReadIni(cFileINI, cKey)

LOCAL nHandle := 0, ;
      cBuff   := Space(255), ;
      nPos    := 0, ;
      fsPoz   := 0, ;
      cRet    := "", ;
      cLine   := ""

      nHandle = FOpen(cFileIni)
      IF nHandle == -1
	 alert("Not INI file!", {" ok "})
	 RETURN ""
      ENDIF

      cKey = Upper(cKey)

      DO WHILE .T.

	 cBuff = Space(255)

	 IF FRead(nHandle, @cBuff, 255) == 0
	    EXIT
	 ENDIF

	 nPos = at(CRLF, cBuff)

	 cLine = SubStr(cBuff, 1, nPos-1)

	 cRet = ChkLine( cLine, cKey )
	 IF !Empty(cRet)
	    EXIT
	 ENDIF

	 fsPoz += (nPos+1)
	 FSeek(nHandle, fsPoz)

      ENDDO

      FClose(nHandle)

      IF Empty(cRet)
	 ? "Nema!"
      ENDIF

RETURN cRet

FUNCTION ChkLine(cLine1, cKey1)

LOCAL nPos := 0, ;
      cTemp := "", ;
      crKey := "", ;
      cRet  := ""

      nPos = at("=", cLine1)
      IF nPos != 0

	 crKey = AllTrim( Upper( SubStr(cLine1, 1, nPos-1) ) )

	 * komentar ;
	 IF Left(crKey, 1) == ";"
	    RETURN cRet
	 ENDIF

	 IF crKey == cKey1
	    cRet = AllTrim(SubStr(cLine1, nPos+1))
	 ENDIF

      ENDIF

RETURN cRet

FUNCTION CnRel(nRBK, nPocBr)

LOCAL nRet  := 0

      nRet = Log2Phy( Rel2Log( nRBK ) )

RETURN nRet

* FUNKCIJE ZA RELATIVNO POMERANJE POKAZIVACA PREMA POCETNOM BROJU U BAZI LISTIC
FUNCTION Log2Phy(nZadSer)

LOCAL nRet := 0

      --nZadSer

      IF (Serija->poc_br + nZadSer) <= MBUKUP
	 nRet = Serija->poc_br + nZadSer
      ELSE
	 nRet = (Serija->poc_br + nZadSer) - MBUKUP
      ENDIF

RETURN nRet

FUNCTION Phy2Log(nPhy)

LOCAL nRet := 0

      IF nPhy >= Serija->poc_br
	 nRet = nPhy - Serija->poc_br
      ELSE
	 nRet = (MBUKUP - Serija->poc_br) + nPhy
      ENDIF

RETURN nRet+1

FUNCTION Rel2Log(nRel)

LOCAL nLog := 0

      nLog = nRel		 && - 100000

RETURN nLog

FUNCTION Log2Rel(nLog)

LOCAL nRel := 0

      nRel = nLog		 && + 100000

RETURN nRel

FUNCTION TRecNo()

LOCAL nRel := 0

      nRel = Log2Rel( Phy2Log( Listic->(RecNo()) ) )

RETURN nRel

FUNCTION TGoTo( nRel )

LOCAL nLog := 0

      TEof = .F.
      TBof = .F.

      nRel = Abs(nRel)

      nLog = Rel2Log( nRel )

      IF nLog <= MBUKUP
	 Listic->( dbGoTo( Log2Phy(nLog) ) )
      ELSE
	 TGoBott()
      ENDIF

RETURN NIL

FUNCTION TGoTop()

      TEof = .F.
      TBof = .F.

      Listic->( TGoTo( Rel2Log( Serija->od ) ) )

RETURN NIL

FUNCTION TGoBott()

      TEof = .F.
      TBof = .F.

      Listic->( TGoTo( Rel2Log( Serija->do ) ) )

RETURN NIL

FUNCTION TSkip(nSkip)

LOCAL nRecNo := 0

      DEFAULT nSkip TO 1

      nLog = Rel2Log( TRecNo() )

      IF nSkip > 0
	 TBof = .F.
	 IF (nLog + nSkip) > MBUKUP
	    TGoBott()
	    TEof = .T.
	 ELSE
	    TGoTo( Log2Rel( nLog ) + nSkip)
	 ENDIF
      ELSE
	 TEof = .F.
	 IF (nLog + nSkip) < 1
	    TGoTop()
	    TBof = .T.
	 ELSE
	    TGoTo( Log2Rel( nLog ) + nSkip)
	 ENDIF
      ENDIF

RETURN NIL

FUNCTION TLastRec()
RETURN Serija->do

FUNCTION LGoTo( nLisBr )

      TGoTo( ( ( nLisBr - 1 ) * BR_KOMB ) + 1 )

RETURN NIL

FUNCTION LSkip( nSkip )

      DEFAULT nSkip TO 1

      TSkip( nSkip * BR_KOMB )

RETURN NIL

FUNCTION LRecNo()

 Local nRel    := 0

      nRel = Int( TRecNo() / BR_KOMB ) + 1

RETURN nRel

* KRAJ FUNKCIJA ZA RELATIVNO POMERANJE POKAZIVACA

FUNCTION PrLis()

LOCAL cMBpath  := "", ;
      cMBpath5 := "", ;
      cOldScreen := "", ;
      cOldSel	 := Select(), ;
      nod	 := 0, ;
      ndo	 := 0, ;
      nSer	 := 0, ;
      aTemp	 := {}

PRIVATE nHandle    := 0

/*
      IF !lKolo
	 ErrBeep()
	 al_box("Nije izabrano ni jedno kolo!",1,{" OK "},1,9,20,15,60)
	 RETURN NIL
      ENDIF
*/

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(7, 27, 12, 55, "PREGLED KOMBINACIJA")

      @  9, 29 SAY "Serija:" GET nSer PICTURE "9999" VALID !Empty(nSer)
      @ 11, 29 SAY "od " GET nod PICTURE "99999999"  VALID !Empty(nod)
      @ 11, 42 SAY "od " GET ndo PICTURE "99999999"

      SetCursor(1)
      READ
      SetCursor(0)

      win_rest(cOldScreen)
      vstk_pop()

      BEGIN SEQUENCE

      IF LastKey() == 27
	 BREAK
      ENDIF

      IF File("opseg.dbf")
	 USE Opseg NEW INDEX Opseg VIA "DBFNTX"
      ENDIF

      USE Serija NEW VIA "SIXCDX"
      SET TAG TO BROJ
      GO TOP

      Serija->(dbSeek(nSer))
      IF !Serija->(Found())
	 ErrBeep()
	 al_box("Serija ne postoji!", 1, {" OK "}, 1, 9, 25, 15, 55)
	 BREAK
      ENDIF

      IF Empty(ndo)
	 ndo = nod
      ELSE
	 IF ( ndo - nod ) > 10
	    ndo = nod + 10
	 ENDIF
      ENDIF

      IF nod < Serija->od .OR. ndo > Serija->do
	 alert("Serija " + AllTrim(Str(nSer)) + " opseg " + Str(Serija->od,8) + "-" + Str(Serija->do,8) + "!", {" OK "})
	 BREAK
      ENDIF

      cMBPath  = AllTrim( Serija->path ) + "listic.dbf"
      cMBPath5 = AllTrim( Serija->path ) + "listic5.dbf"

      DO WHILE .T.

	 IF !File(cMBpath)
	    ErrBeep()
	    IF al_box(cMBpath + " ne postoji!",2,{" PONOVI "," PREKID "},1,9,20,16,60) = 2
	       BREAK
	    ENDIF
	 ELSE
	    EXIT
	 ENDIF

      ENDDO

      IF !NetUse(cMBpath5, "MiRRoR")
	 BREAK
      ENDIF

      IF !NetUse(cMBpath, "MiRRoR")
	 BREAK
      ENDIF

      TGoTop()

      IniPtr()
      Prt1()
      Prt2()

      IF Empty(ndo)
	 ndo = nod
      ENDIF

      LGoTo(nod)
      DO WHILE LRecNo() <= ndo .AND. !TEof

	    IF File("opseg.dbf")
	       ? "RBK: " + FMT0L( Str( LRecNo() ), 7 ) + " " + "RecNo: " + Str( Listic->(RecNo()), 7) + " " +;
		 iif( ChkSold( nSer, LRecNo() ), "PRODAT", "NEPRODAT" )
	    ELSE
	       ? "RBK: " + FMT0L( Str( LRecNo() ), 7 ) + " " + "RecNo: " + Str( Listic->(RecNo()), 7)
	    ENDIF
	    aTemp := Get5od36( TRecNo() )
	    ? "5 od 36 (1): " + aTemp[1,1] + "-" + aTemp[1,2] + "-" + aTemp[1,3] + "-" + aTemp[1,4] + "-" + aTemp[1,5]
	    ? "5 od 36 (2): " + aTemp[2,1] + "-" + aTemp[2,2] + "-" + aTemp[2,3] + "-" + aTemp[2,4] + "-" + aTemp[2,5]
	    FOR i = 1 TO BR_KOMB
		GetKomb()
		TSkip()
	    NEXT

      ENDDO

      Prt3()

      END SEQUENCE

      CLOSE ALL

RETURN NIL

FUNCTION FillIzg()

LOCAL cMBpath  := "", ;
      cMBpath5 := "", ;
      cOldScreen := "", ;
      cOldSel	 := Select(), ;
      nod	 := 0, ;
      ndo	 := 0, ;
      nSer	 := 0, ;
      aTemp	 := {}

PRIVATE nHandle    := 0

      IF al_box("Baza izgleda listica?",2,{" DA "," NE "},2,9,20,15,60) = 2
	 RETURN NIL
      ENDIF

      IF File("izg.dbf")
	DELETE FILE izg.dbf
      ENDIF

      IF File("izg.ntx")
	DELETE FILE izg.ntx
      ENDIF

      dbCreate("IZG.DBF", { ;
			  {"SERIJA",       "N",  4,  0}, ;
			  {"RBK",          "N",  8,  0}, ;
			  {"K1",           "C", 27,  0}, ;
			  {"K2",           "C", 27,  0}, ;
			  {"K3",           "C", 27,  0}, ;
			  {"K51",          "C",  5,  0}, ;
			  {"K52",          "C",  5,  0}  ;
			  }, "DBFNTX")

      // IF File("opseg.dbf")
      //    USE Opseg NEW INDEX Opseg VIA "DBFNTX"
      // ENDIF

      USE Izg NEW VIA "DBFNTX"
      INDEX ON FMT0L(Str(Izg->serija),3) + FMT0L(Str(Izg->rbk),8) TO Izg
      SET INDEX TO Izg
      GO TOP

      USE Razd NEW VIA "SIXCDX"
      SET TAG TO serod
      GO TOP

      USE Serija NEW VIA "SIXCDX"
      SET TAG TO BROJ
      GO TOP

      cMBPath  = AllTrim( Serija->path ) + "listic.dbf"
      * cMBPath5 = AllTrim( Serija->path ) + "listic5.dbf"

      DO WHILE .T.

	 IF !File(cMBpath)
	    ErrBeep()
	    IF al_box(cMBpath + " ne postoji!",2,{" PONOVI "," PREKID "},1,9,20,16,60) = 2
	       BREAK
	    ENDIF
	 ELSE
	    EXIT
	 ENDIF

      ENDDO

      /*
      IF !NetUse(cMBpath5, "MiRRoR")
	 BREAK
      ENDIF
      */

      IF !NetUse(cMBpath, "MiRRoR")
	 BREAK
      ENDIF

      TGoTop()

      msg_start( 9, 25, 15, 55 )

      DO WHILE !Razd->(Eof())

	 Serija->( dbSeek( Razd->serija ) )
	 LGoTo( Razd->od )

	 msg( "Izgled listica " + FMT0L(Str(Razd->serija),3) + "/" + FMT0L(Str(Razd->od),8) + "-" + FMT0L(Str(Razd->kart-1),8)  + "- " + Str(Listic->(RecNo())) )

	 DO WHILE LRecNo() <= (Razd->kart - 1)

	    * Listic5->( dbGoTo( Set536( TRecNo(), BR_KOMB536 ) ) )

	    Izg->( dbAppend() )

	    REPLACE Izg->serija WITH Razd->serija, ;
		    Izg->rbk	WITH LRecNo(), ;
		    Izg->k1	WITH Listic->sadrzaj
		    * Izg->k51	  WITH Listic5->sadrzaj, ;

	    * Listic5->( dbSkip() )
	    * REPLACE Izg->k52	  WITH Listic5->sadrzaj

	    TSkip()
	    REPLACE Izg->k2	WITH Listic->sadrzaj

	    TSkip()
	    REPLACE Izg->k3	WITH Listic->sadrzaj

	    TSkip()

	 ENDDO

	 Razd->( dbSkip() )

      ENDDO

      msg_end()

/*
      LGoTo(nod)
      DO WHILE LRecNo() <= ndo .AND. !TEof

	    IF File("opseg.dbf")
	       ? "RBK: " + FMT0L( Str( LRecNo() ), 7 ) + " " + "RecNo: " + Str( Listic->(RecNo()), 7) + " " +;
		 iif( ChkSold( nSer, LRecNo() ), "PRODAT", "NEPRODAT" )
	    ELSE
	       ? "RBK: " + FMT0L( Str( LRecNo() ), 7 ) + " " + "RecNo: " + Str( Listic->(RecNo()), 7)
	    ENDIF
	    aTemp := Get5od36( TRecNo() )
	    ? "5 od 36 (1): " + aTemp[1,1] + "-" + aTemp[1,2] + "-" + aTemp[1,3] + "-" + aTemp[1,4] + "-" + aTemp[1,5]
	    ? "5 od 36 (2): " + aTemp[2,1] + "-" + aTemp[2,2] + "-" + aTemp[2,3] + "-" + aTemp[2,4] + "-" + aTemp[2,5]
	    FOR i = 1 TO BR_KOMB
		GetKomb()
		TSkip()
	    NEXT

      ENDDO
*/

      CLOSE ALL

RETURN NIL


FUNCTION GetKomb()

 Local cRet := "", ;
       i    := 0, ;
       nn   := 0

      ?

      for i = 1 to 27 step 3
	  nn = Asc(substr(sadrzaj,i,1))
	  ?? iif(nn=126,"--",FMT0L(Str(nn,2),2)) + "  "
      next

      ?

      for i = 2 to 27 step 3
	  nn = Asc(substr(sadrzaj,i,1))
	  ?? iif(nn=126,"--",FMT0L(Str(nn,2),2)) + "  "
      next

      ?

      for i = 3 to 27 step 3
	  nn = Asc(substr(sadrzaj,i,1))
	  ?? iif(nn=126,"--",FMT0L(Str(nn,2),2)) + "  "
      next

      ?

RETURN nil

FUNCTION PrLis1(nSer, nRBK)

LOCAL cPath   := "", ;
      nOldSel := Select(), ;
      nPos    := 0, ;
      aRet    := {}


	 aadd( aRet, "" )
	 aadd( aRet, "" )
	 aadd( aRet, "" )
	 aadd( aRet, "" )

	 USE Serija NEW VIA "SIXCDX"
	 SET TAG TO broj
	 GO TOP

	 Serija->(dbSeek(nSer))
	 IF !Serija->(Found())
	    ? "Nema serije za zadatu karticu!"
	    CLOSE Serija
	    Select(nOldSel)
	    RETURN NIL
	 ENDIF

	 cPath = AllTrim(Serija->path) + "listic.dbf"

	 USE &(cPath) NEW VIA "SIXCDX" PASSWORD "[REDACTED]"
	 TGoTop()

	 TGoTo(nRBK)

	 nPos := Int( TRecNo() % BR_KOMB )
	 if nPos == 0
	    nPos := BR_KOMB
	 endif

	 aRet[1] += padr("Serija: " + FMT0L( Str( nSer ), 3 ) + " RBK: " + FMT0L( Str( Listic->( ConvRBK( TRecNo() ) ) ), 6 ) + "/" + Str( nPos, 1 ) + " (" + FMT0L( Str( RecNo() ), 7 ) + ")", 36, " ")

	 for i = 1 to 27 step 3
	     nn = Asc(substr(Listic->sadrzaj,i,1))
	     aRet[2] += iif( nn = 126, "--", FMT0L( Str( nn, 2 ), 2 ) ) + "  "
	 next

	 for i = 2 to 27 step 3
	     nn = Asc(substr(Listic->sadrzaj,i,1))
	     aRet[3] += iif( nn = 126, "--", FMT0L( Str( nn, 2 ), 2 ) ) + "  "
	 next

	 for i = 3 to 27 step 3
	     nn = Asc(substr(Listic->sadrzaj,i,1))
	     aRet[4] += iif( nn = 126, "--", FMT0L( Str( nn, 2 ), 2 ) ) + "  "
	 next

	 CLOSE Listic
	 CLOSE Serija

	 Select(nOldSel)

RETURN aRet

FUNCTION ChkSold( nSer, nRBK )

 Local lRet := .f.

   Opseg->( dbSeek( FMT0L( Str( nSer ), 4 ) + FMT0L( Str( nRBK ), 8 ), .T. ) )
   IF !Opseg->( Found() )
      Opseg->( dbSkip( -1 ) )
   ENDIF

   if nSer = Opseg->serija .and. ( nRBK >= Opseg->od .and. nRBK <= Opseg->do )
      lRet := .t.
   endif

RETURN lRet

FUNCTION ReEx( cPatt )

LOCAL i        := 0, ;
      nByte    := 0, ;
      nCntByte := 1, ;
      aRet     := {},;
      cRet     := "",;
      nBr      := 0

      nnn = FCreate( "rr.dat" )
      FWrite( nnn, cPatt )
      FClose( nnn )

      DO WHILE nCntByte <= Len( cPatt )

	 nByte = Asc( SubStr( cPatt, nCntByte, 1 ) )

	 FOR i = 1 TO 8
	     IF IsBit( nByte, i )
		nBr = ( (nCntByte - 1) * 8 ) + ( i - 1 )
		aadd( aRet, nBr )
	     ENDIF
	 NEXT

	 ++nCntByte

      ENDDO

      FOR i = 1 TO Len( aRet )
	  cRet += FMT0L( Str(aRet[i]), 2 ) + ", "
      NEXT

RETURN cRet

FUNCTION AppRec(cSrcDBF, cDstDBF, nHow, lAppend)

LOCAL aNameFld := {}, ;
      i        := 0, ;
      nCnt	:= 0, ;
      cBodyS   := "", ;
      cBodyD   := "", ;
      nSelect  := Select(), ;
      nOldRec  := RecNo()

      DEFAULT nHow	 TO 1
      DEFAULT lAppend	 TO .T.

      Select(cSrcDBF)

      aNameFld = Array(FCount())
      AFields(aNameFld)

      DO WHILE nCnt < nHow

	 Select(cDstDBF)

	 IF lAppend
	    dbAppend()
	 ENDIF

	 FOR i = 1 TO Len(aNameFld)
	     cBodyS = cSrcDBF + "->" + (aNameFld[i])
	     cBodyD = cDstDBF + "->" + (aNameFld[i])
	     REPLACE &(cBodyD) WITH &(cBodyS)
	 NEXT

	 Select(cSrcDBF)

	 dbSkip()

	 ++nCnt

      ENDDO

      Select(nSelect)
      dbGoTo( nOldRec )

RETURN NIL

FUNCTION XTrans()

 Local nHndSrc := 0, ;
       nHndDst := 0, ;
       cHed    := Space(23), ;
       cBuff   := Space(16)

   nHndSrc := FOpen( "e:\codlis.dat" )
   nHndDst := FCreate( "codlis.dat" )

   FSeek( nHndSrc, 0, 0 )
   FRead( nHndSrc, @cHed, 23 )

   FWrite( nHndDst, cHed )

   USE listic.dbf NEW VIA "SIXCDX" PASSWORD "[REDACTED]" ALIAS "DEST"
   GO TOP

   USE e:\listic.dbf NEW VIA "SIXCDX" PASSWORD "[REDACTED]" ALIAS "SOURCE"
   GO TOP

   Msg_Start( 9, 25, 15, 55 )

   DO WHILE Source->( RecNo() ) <= 100000

      Msg( Str( Source->( RecNo() ), 6 ) )

      FRead( nHndSrc, @cBuff, 16 )
      FWrite( nHndDst, cBuff )

      Dest->( dbAppend() )
      REPLACE Dest->sadrzaj WITH Source->sadrzaj

      Source->( dbSkip() )

   ENDDO

   Msg_End()

   CLOSE ALL

   FClose( nHndDst )
   FClose( nHndSrc )

RETURN NIL

FUNCTION NetUse(cDbf, cPass)

LOCAL lRetVal := .T.

      DEFAULT cPass TO ""

      USE (cDbf) NEW VIA "SIXCDX" SHARED

      IF !Empty(cPass)
	 Sx_SetPass(cPass)
      ENDIF

      IF NetErr()
	 al_box("Greska u otvaranju deljene baze " + AllTrim(cDbf) + "!", 1, {" OK "}, 1, 9, 20, 16, 60)
	 lRetVal = .F.
      ENDIF

RETURN lRetVal

FUNCTION GenQ()

 Local cRet := "", ;
       i := 0, ;
       nBr := 0

   FOR i = 1 TO 5
       nBr := Int( Random() % 9 ) + 48
       cRet += Chr(nBr)
   NEXT

RETURN cRet

FUNCTION ConvRBK( nRBK )
return Int( ( nRBK - 1 ) / BR_KOMB ) + 1

FUNCTION ConvFromRBK( nRBK )
return Int( ( nRBK - 1 ) * BR_KOMB ) + 1

FUNCTION Get5od36( nRecNo )

 Local cRet   := "", ;
       aTemp  := {}, ;
       aTemp1 := {}, ;
       i      := 0,  ;
       brkart := 0

      brkart := Int( ( nRecNo - 1 ) / BR_KOMB ) + 1
      // Listic5->( dbGoTo( ( ( brkart - 1 ) * 2 ) + 1 ) )
      Listic5->( dbGoTo( Set536( nRecNo, BR_KOMB536 ) ) )

      FOR i = 1 TO 5
	  aadd( aTemp, FMT0L( Str( Asc( SubStr( Listic5->sadrzaj, i, 1 ) ) ), 2 ) )
      NEXT
      aadd(aTemp1, aTemp)
      aTemp := {}

      Listic5->( dbSkip() )

      FOR i = 1 TO 5
	  aadd( aTemp, FMT0L( Str( Asc( SubStr( Listic5->sadrzaj, i, 1 ) ) ), 2 ) )
      NEXT
      aadd(aTemp1, aTemp)

RETURN aTemp1

FUNCTION Set536( nRBK, nBrKomb )

LOCAL nRealRBK := 0, ;
      nLogRBK  := 0, ;
      nRet     := 0

      DEFAULT nBrKomb TO 1

      nRealRBK := Int( ( nRBK - 1 ) / BR_KOMB ) + 1
      nLogRBK  := ( ( nRealRBK - 1 ) * BR_KOMB536 ) + 1

      nRet := Int(nLogRBK % 376802)
      if nRet = 0
	 nRet = 1
      endif

RETURN nRet

FUNCTION CnRel5( nPhyRecNo )

 Local nRet := 0

   nRet := Int(nPhyRecNo % 376802)
   if nRet == 0
      nRet := 1
   endif

RETURN nRet

