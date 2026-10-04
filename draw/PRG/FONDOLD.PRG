#include "llibg.ch"

FUNCTION ShwFond()

LOCAL cPict := "", ;
      aFndFont, ;
      aEurFont, ;
      x, y

      x = 604
      y = 230

      aFndFont = GFntLoad("chelv32.fnt")
      aEurFont = GFntLoad("swiss20.fnt")

      IF File("fond.bmp")
	 GBmpDisp( GBmpLoad("fond.bmp"), 0, 0 )
      ELSE
	 CLS
      ENDIF

      * GPrint( 320, 60, "KOLO: " + AllTrim(cKolo) , 1, 1, aFndFont )

      GPrint( x+2, y+2, USA2YU(Transform(CalcEuro(fnd_15), "9,999,999.99")),  0, 2, aFndFont, 2 )
      GPrint( x, y, USA2YU(Transform(CalcEuro(fnd_15), "9,999,999.99")), 15, 2, aFndFont, 2 )

      y += 25
      * euro
      //GPrint( x+2, y+2, USA2YU(Transform(fnd_15, "9,999,999.99 DM")),  0, 2, aEurFont, 2 )
      GPrint( x, y, USA2YU(Transform(fnd_15, "9,999,999.99 DM")), 10, 2, aEurFont, 2 )
      y -= 25

      y += 100
      GPrint( x+2, y+2, USA2YU(Transform(CalcEuro(fnd_14), "9,999,999.99")),  0, 2, aFndFont, 2 )
      GPrint( x, y, USA2YU(Transform(CalcEuro(fnd_14), "9,999,999.99")), 15, 2, aFndFont, 2 )

      y += 25
      * euro
      //GPrint( x+2, y+2, USA2YU(Transform(fnd_14, "9,999,999.99 DM")),  0, 2, aEurFont, 2 )
      GPrint( x, y, USA2YU(Transform(fnd_14, "9,999,999.99 DM")), 10, 2, aEurFont, 2 )
      y -= 25

      y += 100
      GPrint( x+2, y+2, USA2YU(Transform(CalcEuro(fnd_13), "9,999,999.99")),  0, 2, aFndFont, 2 )
      GPrint( x, y, USA2YU(Transform(CalcEuro(fnd_13), "9,999,999.99")), 15, 2, aFndFont, 2 )

      y += 25
      * euro
      //GPrint( x+2, y+2, USA2YU(Transform(fnd_13, "9,999,999.99 DM")),  0, 2, aEurFont, 2 )
      GPrint( x, y, USA2YU(Transform(fnd_13, "9,999,999.99 DM")), 10, 2, aEurFont, 2 )
      y -= 25

      InKey(0)

      GFntErase(aEurFont)
      GFntErase(aFndFont)

      CLS

      ChgFont(.f.)

RETURN NIL
