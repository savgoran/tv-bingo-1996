#include "llibg.ch"

FUNCTION ShwFond()

LOCAL cPict := "", ;
      aFndFont, ;
      aMesFont

      aFndFont = GFntLoad("chelv32.fnt")
      aMesFont = GFntLoad("arial20.fnt")

      IF File("fond.bmp")
	 GBmpDisp( GBmpLoad("fond.bmp"), 0, 0 )
      ELSE
	 CLS
      ENDIF

      * GPrint( 320, 60, "KOLO: " + AllTrim(cKolo) , 1, 1, aFndFont )

      //GPrint( 606, 257, USA2YU(Transform(fnd_15, "9,999,999.99")),  0, 2, aFndFont, 2 )
      //GPrint( 604, 255, USA2YU(Transform(fnd_15, "9,999,999.99")), 15, 2, aFndFont, 2 )

      GPrint( 606, 257, "STAN 64m2",  0, 2, aMesFont, 2 )
      GPrint( 604, 255, "STAN 64m2", 15, 2, aMesFont, 2 )

      //GPrint( 606, 357, Str( fnd_14, 10, 2 ),  0, 2, aFndFont, 2 )
      GPrint( 606, 357, USA2YU(Transform(fnd_14, "9,999,999.99")),  0, 2, aFndFont, 2 )
      //GPrint( 604, 355, Str( fnd_14, 10, 2 ), 15, 2, aFndFont, 2 )
      GPrint( 604, 355, USA2YU(Transform(fnd_14, "9,999,999.99")), 15, 2, aFndFont, 2 )

      //GPrint( 606, 457, Str( fnd_13, 10, 2 ),  0, 2, aFndFont, 2 )
      GPrint( 606, 457, USA2YU(Transform(fnd_13, "9,999,999.99")),  0, 2, aFndFont, 2 )
      //GPrint( 604, 455, Str( fnd_13, 10, 2 ), 15, 2, aFndFont, 2 )
      GPrint( 604, 455, USA2YU(Transform(fnd_13, "9,999,999.99")), 15, 2, aFndFont, 2 )

      InKey(0)

      GFntErase(aMesFont)
      GFntErase(aFndFont)

      CLS

      ChgFont(.f.)

RETURN NIL
