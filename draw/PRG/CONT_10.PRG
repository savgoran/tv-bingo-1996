#include "commands.ch"

STATIC a10 := {}, ;
       y   := 0

FUNCTION Prik_10( cBuff )

LOCAL cSer  := 0, ;
      i     := 0, ;
      cTemp := Space(4), ;
      aTemp := {}

      IF y = 0
	 y = n10y
      ENDIF

      FOR i = 1 TO Len( cBuff ) STEP 4

	  cTemp = SubStr( cBuff, i, 4 )
	  cSer	= FMT0L( Str( ExSer( cTemp ) ), 3 )
	  cSer += "/" + FMT0L( Str( ConvRBK( Bin2L( cTemp ) ) ), 8 )
	  * cSer = FMT0L( Str( Bin2L( cTemp ) ), 8 )

	  IF AScan(a10, cSer) == 0
	     aadd(aTemp, cSer)
	  ENDIF

      NEXT

      FOR i = 1 TO Len(aTemp)

	  aadd(a10, aTemp[i])
	  GPrint(n10x, y, aTemp[i], 14, 1, aRBfont )
	  y += 30

      NEXT

RETURN NIL

FUNCTION Fresh_10()

LOCAL i := 0

      y = n10y

      FOR i = 1 TO Len(a10)
	  GPrint(n10x, y, a10[i], 14, 1, aRBfont )
	  y += 30
      NEXT

RETURN NIL
