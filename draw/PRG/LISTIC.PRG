#include "llibg.ch"
#include "commands.ch"

#define TAB_X	      331
#define TAB_Y	      66
#define TAB_H_TICK    24
#define TAB_V_TICK    21
#define SER_X	      135
#define SER_Y	      247
#define RBK_X	      198
#define RBK_Y	      247
#define KB_X	      268
#define KB_Y	      247
#define SER_V_TICK    33
#define KOMB_VIS      69
#define T536_X	      138
#define T536_Y	      190
#define AB_X	      74
#define AB_Y	      275

#define koef	      0.04

/* NORMAL
#define TAB_X	      324
#define TAB_Y	      59
#define TAB_H_TICK    32
#define TAB_V_TICK    28
#define SER_X	      81
#define SER_Y	      145
#define RBK_X	      169
#define RBK_Y	      145
#define KB_X	      257
#define KB_Y	      145
#define SER_V_TICK    33
#define KOMB_VIS      92
#define T536_X	      138
#define T536_Y	      190
#define AB_X	      74
#define AB_Y	      275
/*

/* STARI LISTIC
#define TAB_X	      323
#define TAB_Y	      54
#define TAB_H_TICK    33
#define TAB_V_TICK    30
#define SER_X	      75
#define SER_Y	      145
#define RBK_X	      166
#define RBK_Y	      145
#define KB_X	      258
#define KB_Y	      145
#define SER_V_TICK    33
#define KOMB_VIS      97
#define T536_X	      134
#define T536_Y	      191
#define AB_X	      71
#define AB_Y	      281
*/

FUNCTION PrikLis()

LOCAL nFlash  := 0, ;
      nRedBr  := 1, ;
      nPos    := 0, ;
      cDbf    := "", ;
      lisbmp  := "listic.bmp"

PRIVATE aLisFont := {}

      USE Izg NEW INDEX Izg
      GO TOP

      cDbf := "Hit" + Str(Listic, 1) + ".dbf"

      USE (cDbf) ALIAS HIT NEW INDEX Hit
      GO TOP

      aLisFont = GFntLoad("tms12.fnt")

      Hit->( dbSeek( "15" ) )
      DO WHILE Hit->pogodak == 15 .AND. !Hit->(Eof())

	 Izg->( dbSeek( FMT0L( Str( Hit->serija ), 3 ) + FMT0L( Str( ConvRBK( Hit->RBK ) ), 8 ) ) )

	 IF File(lisbmp)
	    GBmpDisp( GBmpLoad(lisbmp), 0, 0 )
	 ENDIF

	 nPos := Int( Hit->RBK % 3 )
	 if nPos == 0
	    nPos := 3
	 endif

	 ShowLis()
	 WrDob( 3, FMT0L( Str( Hit->serija ), 3 ), FMT0L( Str( ConvRBK( Hit->RBK ) ), 8 ), Hit->mesto, padl( AllTrim( Str( nRedBr ) ), 5, " ") )
	 Flash(nPos)
	 //Inkey(0)

	 Hit->( dbSkip() )

	 ++nRedBr

      ENDDO

      GFntErase( aLisFont )

      CLOSE ALL

RETURN NIL

FUNCTION ShowLis()

LOCAL x_tab := TAB_X, ;
      y_tab := TAB_Y, ;
      aKomb := {}, ;
      i     := 0, ;
      j     := 0, ;
      cBr   := ""

      DO CASE
	CASE Listic == 1
	  aadd(aKomb, Izg->k1)
	  aadd(aKomb, Izg->k2)
	  aadd(aKomb, Izg->k3)
	CASE Listic == 2
	  aadd(aKomb, Izg->k4)
	  aadd(aKomb, Izg->k5)
	  aadd(aKomb, Izg->k6)
	CASE Listic == 3
	  aadd(aKomb, Izg->k7)
	  aadd(aKomb, Izg->k8)
	  aadd(aKomb, Izg->k9)
      ENDCASE

      // Serija
      GPrint(SER_X, SER_Y, FMT0L(Str(Izg->serija), 3), 0, 1, aLisFont, 1)

      // RBK
      GPrint(RBK_X, RBK_Y, padl(AllTrim(Str(Izg->rbk)), 7, "*"), 0, 1, aLisFont, 1)

      // KB
      GPrint(KB_X, KB_Y, "XXX", 0, 1, aLisFont, 1)

      FOR j := 1 TO 3

      FOR i := 1 TO 27 STEP 3
	  cBr := AllTrim(Str( Asc( SubStr( aKomb[j], i, 1 ) ) ))
	  IF cBr != "126"
	     GPrint(x_tab, y_tab, cBr, 0, 1, aLisFont, 1)
	  ENDIF
	  IF i == 1
	     x_tab += (TAB_H_TICK - 1)
	  ELSE
	     x_tab += (TAB_H_TICK + (koef * i))
	  ENDIF
      NEXT

      x_tab := TAB_X
      y_tab += TAB_V_TICK

      FOR i := 2 TO 27 STEP 3
	  cBr := AllTrim(Str( Asc( SubStr( aKomb[j], i, 1 ) ) ))
	  IF cBr != "126"
	     GPrint(x_tab, y_tab, cBr, 0, 1, aLisFont, 1)
	  ENDIF
	  IF i == 2
	     x_tab += (TAB_H_TICK - 1)
	  ELSE
	     x_tab += (TAB_H_TICK + (koef * i))
	  ENDIF
      NEXT

      x_tab := TAB_X
      y_tab += TAB_V_TICK

      FOR i := 3 TO 27 STEP 3
	  cBr := AllTrim(Str( Asc( SubStr( aKomb[j], i, 1 ) ) ))
	  IF cBr != "126"
	     GPrint(x_tab, y_tab, cBr, 0, 1, aLisFont, 1)
	  ENDIF
	  IF i == 3
	     x_tab += (TAB_H_TICK - 1)
	  ELSE
	     x_tab += (TAB_H_TICK + (koef * i))
	  ENDIF
      NEXT

      x_tab := TAB_X
      y_tab := TAB_Y + ( KOMB_VIS * j )

      NEXT

      x_tab := T536_X
      y_tab := T536_Y
/*
      aKomb := {}
      aadd(aKomb, Izg->k51)
      aadd(aKomb, Izg->k52)

      FOR j := 1 TO 2
      FOR i := 1 TO 5
	  cBr := AllTrim(Str( Asc( SubStr( aKomb[j], i, 1 ) ) ))
	  GPrint(x_tab, y_tab, FMT0L(cBr,2), 0, 1, aLisFont, 1)
	  x_tab += TAB_H_TICK
      NEXT
      x_tab := T536_X
      y_tab := T536_Y + ( 36 * j )
      NEXT

      IF Int(Izg->rbk / 2) != (Izg->rbk / 2)
	 GPrint(AB_X, AB_Y, "A", 0, 1, aLisFont, 1)
      ELSE
	 GPrint(AB_X, AB_Y, "B", 0, 1, aLisFont, 1)
      ENDIF
*/
RETURN NIL

FUNCTION Flash( nRed )

LOCAL x := 317, ;
      y := 55, ;
      nColor := 13

      --nRed
      y += ( nRed * 68 )

      DO WHILE nextkey() == 0

	 GRect(x, y, x + 221, y + 65, LLG_FILL, nColor, LLG_MODE_XOR)
	 MilliSec(600)
	 GRect(x, y, x + 221, y + 65, LLG_FILL, nColor, LLG_MODE_XOR)
	 MilliSec(600)

      ENDDO

      CLEAR TYPEAHEAD

RETURN NIL
