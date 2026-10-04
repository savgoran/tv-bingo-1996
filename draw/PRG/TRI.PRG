#include "llibg.ch"
#include "inkey.ch"
#include "commands.ch"

FUNCTION Res3( cBuff, cPict )

 Local aSer   := {}, ;
       i      := 1, ;
       nPos   := 1, ;
       nRedBr := 1

 Private aBrFont  := {}, ;
	 aMesFont := {}

 DEFAULT cPict TO ""

      USE Opseg NEW INDEX Opseg VIA "DBFNTX"
      GO TOP

      aBrFont  = GFntLoad("arial43.fnt")
      aMesFont = GFntLoad("arial20.fnt")

      aSer := Parse3( cBuff )

      IF File( cPict )
	 GBmpDisp( GBmpLoad(cPict), 0, 0 )
      ELSE
	 CLS
      ENDIF

      DO WHILE i <= Len( aSer )

	  WrDob(nPos, FMT0L( Str( aSer[i,1] ), 3 ), FMT0L( Str( aSer[i,2] ), 8 ), aSer[i,3], padl( AllTrim( Str( nRedBr ) ), 5, " ") )

	  ++i

	  ++nPos
	  IF nPos % 5 == 0

	     nPos := 1
	     nKey := Inkey(0)

	     IF nKey = 27
		nPos = 5
		EXIT
	     ENDIF

	     IF File(cPict)
		GBmpDisp( GBmpLoad(cPict), 0, 0 )
	     ELSE
		CLS
	     ENDIF

	  ENDIF

	  ++nRedBr

      ENDDO

      IF (nPos % 5) != 0
	 Inkey(0)
      ENDIF

      GFntErase(aBrFont)
      GFntErase(aMesFont)

      CLS

      CLOSE ALL

      ChgFont(.f.)

RETURN NIL

STATIC FUNCTION Parse3( cBuff )

 Local aRet   := {}, ;
       i      := 0, ;
       cTemp  := "", ;
       cSer   := "", ;
       nBrSer := 0, ;
       nRBK   := 0

      FOR i = 1 TO Len( cBuff ) STEP 4

	  cTemp = SubStr( cBuff, i, 4 )

	  nBrSer = ExSer( cTemp )
	  nRBK	 = Bin2L( cTemp )

	  Opseg->( dbSeek( FMT0L( Str( nBrSer ), 4 ) + FMT0L( Str( nRBK ), 8 ), .T. ) )
	  IF !Opseg->( Found() )
	     Opseg->( dbSkip( -1 ) )
	  ENDIF

	  // cSer = FMT0L( Str( Bin2L( cTemp ) ), 8 )

	  IF AScan( aRet, cSer ) == 0
	     aadd( aRet, { nBrSer, nRBK, Opseg->mesto } )
	  ENDIF

      NEXT

RETURN aRet
