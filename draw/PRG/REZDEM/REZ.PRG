#include "llibg.ch"
#include "inkey.ch"
#include "commands.ch"

#define FND_0	      500

FUNCTION Result()

LOCAL i        := 0, ;
      nKey     := 0

PRIVATE nBrPog	 := 10, ;
	aResFont := {}, ;
	aBrFont  := {}, ;
	aMesFont := {}, ;
	aHits	 := {}, ;
	aOffset  := {}

      CLS

      aHits = CntHit()

      aResFont = GFntLoad("chelv32.fnt")
      aBrFont  = GFntLoad("arial43.fnt")
      aMesFont = GFntLoad("arial20.fnt")

      DispHit()

      ParseHit()

      DO WHILE .T.

	 nKey = Inkey(0)

	 DO CASE

	    CASE nKey = K_F3
		 PrikLis()

            CASE nKey = K_F10
		 Res15()

	    CASE nKey = K_F9
		 Res14()

            CASE nKey = K_ESC
		 EXIT

	 ENDCASE

	 DispHit()

      ENDDO

      GFntErase(aResFont)
      GFntErase(aBrFont)
      GFntErase(aMesFont)

      CLS

      ChgFont(.f.)

RETURN aHits

FUNCTION DispHit()

LOCAL i     := 0, ;
      x     := 0, ;
      y     := 0

      GBmpDisp( GBmpLoad("izv1.bmp"), 0, 0 )

      x = 300
      y = 250

      FOR i = 1 TO 3

	  * senka
	  GPrint( x + 2, y + 2, Str( aHits[i,1], 5 ), 0, 2, aResFont, 2 )
	  * pravi broj
	  GPrint( x, y, Str( aHits[i,1], 5 ), 14, 2, aResFont, 2 )

	  //GPrint(x + 304, y + 2, Str(aHits[i,2], 9, 2), 0, 2, aResFont, 2)
	  GPrint(x + 304, y + 2, USA2YU(Transform(aHits[i,2], "999,999.99")), 0, 2, aResFont, 2)
	  //GPrint(x + 302, y, Str(aHits[i,2], 9, 2), 15, 2, aResFont, 2)
	  GPrint(x + 302, y, USA2YU(Transform(aHits[i,2], "999,999.99")), 15, 2, aResFont, 2)

	  y += 100

      NEXT

RETURN NIL

FUNCTION CntHit()

LOCAL aTemp  := {}, ;
      aRet   := {}, ;
      i      := 0

      cPogodak = Replicate( Chr(0), 64 )

      CntTicket( cTestKomb, 0, 0, cPogodak )

      FOR i = 1 TO 16
	  aadd( aTemp, { Bin2L( SubStr( cPogodak, ((i-1) * 4) + 1, 4) ), 0 } )
      NEXT

      aTemp[1,2] = fnd_15 / aTemp[1,1]

      aTemp[2,2] = fnd_14 / aTemp[2,1]

      aTemp[3,2] = fnd_13 / aTemp[3,1]

      if aTemp[2,1] == 0
	 aTemp[3,2] := (fnd_14 + fnd_13) / aTemp[3,1]
      endif

      * aTemp[16,2] = FND_0 / aTemp[16,1]	&& 0 pogodaka

      aadd( aRet, {aTemp[1,1], aTemp[1,2]} )
      aadd( aRet, {aTemp[2,1], aTemp[2,2]} )
      aadd( aRet, {aTemp[3,1], aTemp[3,2]} )

RETURN aRet

FUNCTION ParseHit()

LOCAL nHandle := 0, ;
      cBuff   := Space(6), ;
      nBrSer  := 0, ;
      nRBK    := 0,;
      cTemp   := "", ;
      nCntHandle := 0, ;
      cSerBr  := Replicate(Chr(0), 6)

      nCntHandle = FCreate("hit.dat")
      WrTicket(cTestKomb, 0, 0, nCntHandle, cSerBr)
      FClose(nCntHandle)

      dbCreate("hit.dbf", {;
			    {"pogodak",    "n",  2, 0}, ;
			    {"serija",     "n",  4, 0}, ;
			    {"rbk",        "n",  8, 0}, ;
			    {"mesto",      "c", 20, 0}, ;
			    {"brzas",      "n",  4, 0}  ;
			  })

      USE Opseg NEW INDEX opseg VIA "DBFNTX"
      GO TOP

      USE hit NEW

      INDEX ON FMT0L( Str( pogodak ), 2 ) + FMT0L( Str( rbk ), 7 ) TO hit
      SET INDEX TO hit
      GO TOP

      nHandle = FOpen("hit.dat")

      DO WHILE .T.

	 cBuff = Space(6)

	 IF FRead(nHandle, @cBuff, 6) == 0
	    EXIT
	 ENDIF

	 cTemp = SubStr(cBuff, 3)

	 nBrSer = ExSer(cTemp)
	 nRBK	= Bin2L(cTemp)

	 // konvertovanje rednog broja kartice
	 // izmenio 31.7.1999
	 // nRBK   = ConvRBK( nRBK )

	 // izmenio 31.7.1999
	 // Opseg->( dbSeek( FMT0L( Str( nBrSer ), 4 ) + FMT0L( Str( nRBK ), 8 ), .T. ) )
	 Opseg->( dbSeek( FMT0L( Str( nBrSer ), 4 ) + FMT0L( Str( ConvRBK( nRBK ) ), 8 ), .T. ) )
	 IF !Opseg->( Found() )
	    Opseg->( dbSkip( -1 ) )
	 ENDIF

	 Hit->(dbAppend())
	 REPLACE Hit->pogodak WITH Asc( Left(cBuff,1) ), ;
		 Hit->serija  WITH nBrSer, ;
		 Hit->rbk     WITH nRBK, ;
		 Hit->mesto   WITH Opseg->mesto, ;
		 Hit->brzas   WITH Opseg->brzas

      ENDDO

      FClose(nHandle)

      FileDelete("hit.dat")

      * Hit->(dbCommitAll())

      CLOSE ALL

RETURN NIL

FUNCTION WrDob(nPos, cSer, cRBK, cMesto, nRedBr, nColor)

LOCAL x := 0, ;
      y := 0

      DEFAULT nRedBr TO 0
      DEFAULT nColor TO 7

      y = 180 + ( 115 * ( nPos - 1 ) )

      // redni broj
      GRect(10, y-45, 100, y-10, LLG_FILL, 0, LLG_MODE_SET)
      GFrame(10, y-45, 100, y-10, 7, 8, 15, 3, 3, 3, 3, LLG_MODE_SET)
      GPrint(94, y-43, nRedBr, 0, 2, aMesFont)

      // mesto
      GRect(110, y-45, 620, y-10, LLG_FILL, 15, LLG_MODE_SET)
      GFrame(110, y-45, 620, y-10, 7, 8, 15, 3, 3, 3, 3, LLG_MODE_SET)
      GWriteAT(116, y-43, cMesto, 0, LLG_MODE_SET, aMesFont)

      aHndSer = BlockNum(10, y, 3, aBrFont, NIL, NIL, NIL, NIL, nColor)
      aHndBr  = BlockNum(185, y, 8, aBrFont, NIL, NIL, NIL, NIL, nColor)

      WriteNum( aHndSer, cSer )
      WriteNum( aHndBr,  cRBK )

RETURN NIL

FUNCTION Res15()

LOCAL cPict  := "", ;
      nPos   := 1, ;
      nKey   := 0, ;
      nRedBr := 1

      cPict = "15.bmp"

      IF File(cPict)
	 GBmpDisp( GBmpLoad(cPict), 0, 0 )
      ELSE
	 CLS
      ENDIF

      IF aHits[1,1] == 0

	 GPrint(320, 240, "NEMA POGODAKA", 14, 1, aResFont)
	 Inkey(0)

      ELSE

	 USE Hit INDEX Hit
	 GO TOP

	 Hit->( dbSeek( "15" ) )
	 DO WHILE Hit->pogodak == 15 .AND. !Hit->(Eof())

	    // izmenio 31.07.1999
	    WrDob( nPos, FMT0L( Str( Hit->serija ), 3 ), FMT0L( Str( ConvRBK( Hit->rbk ) ), 8 ), Hit->mesto, padl( AllTrim( Str( nRedBr ) ), 5, " ") )

	    ++nPos
	    IF (nPos % 4) == 0

	       nPos = 1
	       nKey = Inkey(0)

	       IF nKey == 27
		  nPos = 4
		  EXIT
	       ENDIF

	       IF File(cPict)
		  GBmpDisp( GBmpLoad(cPict), 0, 0 )
	       ELSE
		  CLS
	       ENDIF

	    ENDIF

	    Hit->(dbSkip())

	    ++nRedBr

	 ENDDO

	 IF (nPos % 4) != 0
	    Inkey(0)
	 ENDIF

	 CLOSE ALL

      ENDIF

RETURN NIL

FUNCTION Res10N()

      PrikLis( aOffset )

RETURN NIL

FUNCTION Res14()

LOCAL cPict := "", ;
      nPos  := 1, ;
      nKey  := 0, ;
      nRedBr := 1

      cPict = "14.bmp"

      IF File(cPict)
	 GBmpDisp( GBmpLoad(cPict), 0, 0 )
      ELSE
	 CLS
      ENDIF

      IF aHits[2,1] == 0

	 GPrint(320, 240, "NEMA POGODAKA", 14, 1, aResFont)
	 Inkey(0)

      ELSE

	 USE Hit INDEX Hit
	 GO TOP

	 Hit->( dbSeek( "14" ) )
	 DO WHILE Hit->pogodak == 14 .AND. !Hit->(Eof())

	    // izmenio 31.07.1999
	    WrDob(nPos, FMT0L( Str( Hit->serija), 3 ), FMT0L( Str( ConvRBK( Hit->rbk ) ), 8 ), Hit->mesto, padl( AllTrim( Str( nRedBr ) ), 5, " ") )

	    ++nPos
	    IF (nPos % 4) == 0

	       nPos = 1
	       nKey = Inkey(0)

	       IF nKey == 27
		  nPos = 5
		  EXIT
	       ENDIF

	       IF File(cPict)
		  GBmpDisp( GBmpLoad(cPict), 0, 0 )
	       ELSE
		  CLS
	       ENDIF

	    ENDIF

	    Hit->(dbSkip())

	    ++nRedBr

	 ENDDO

	 IF (nPos % 4) != 0
	    Inkey(0)
	 ENDIF

	 CLOSE ALL

      ENDIF

RETURN NIL

FUNCTION USA2YU(cNum)

   cNum := StrTran(cNum, ".", ":")
   cNum := StrTran(cNum, ",", ".")
   cNum := StrTran(cNum, ":", ",")

RETURN cNum
