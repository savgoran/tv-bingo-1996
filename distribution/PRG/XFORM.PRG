#include "sixcdx2.ch"
#include "machsix.ch"
#include "commands.ch"

FUNCTION RepPrice( nNag )

LOCAL nTemp := 0, ;
      aPage := {},;
      i     := 0, ;
      nCnt  := 0

PRIVATE nPog  := 0, ;
	nUkup := 0

      SET SCOPE TO FMT0L( Str(16 - nNag), 2 )
      GO TOP

      DO WHILE !Hit->(Eof())

	 IF nPog != Hit->pogodak

	    nPog = Hit->pogodak

	    ? FontS + BoldON + "POGODAKA: " + Str(nPog,2) + Space(20) + "Kolo: " + AllTrim(cKolo)

	 ENDIF

	 aPage = Make1Page()
	 FOR i = 1 TO Len( aPage )
	     ? AllTrim( aPage[i] )
	 NEXT

	 ? NewPage
	 ++nCnt

      ENDDO

      ?? BoldOFF

      SET SCOPE TO

RETURN NIL

FUNCTION Make1Page()

LOCAL i     := 0, ;
      aCol  := {}, ;
      aPage := Array(80), ;
      nCnt  := 0

PRIVATE t_brzas := 0, ;
	lOpet := .F.

      aPage = AFill(aPage, "")

      DO WHILE nCnt < 10 .AND. !Hit->( Eof() )

	 aCol = Make1Col()
	 FOR i = 1 TO Len(aCol)
	     aPage[i] += ( aCol[i,1] + " " )
	 NEXT

	 ++nCnt

      ENDDO

      IF Hit->( Eof() )

	 IF i >= 79
	    i = 1
	 ENDIF

	 aPage[i] += Space(12)
	 ++i

* aPage[i] += BoldON + "Dob: " + Str(nUkup,7) + BoldOFF

	 aPage[i] += "Dob: " + Str(nUkup,7)
	 nUkup := 0

      ENDIF

RETURN aPage

FUNCTION Make1Col()

LOCAL i       := 0, ;
      aCol    := {}, ;
      nCnt    := 1, ;
      kk      := 0

      DO WHILE Len(aCol) < 80 .AND. !Hit->( Eof() )

	 IF t_brzas != Hit->brzas
* aadd( aCol, { BoldON + padr(FMT0L(Str(Hit->brzas),4), 12, " ") + BoldOFF, 1 } )
	    aadd( aCol, { padr(FMT0L(Str(Hit->brzas),4), 12, " "), 1 } )
	    t_brzas = Hit->brzas
	    LOOP
	 ENDIF

	 aadd( aCol, { FMT0L( Str( Hit->serija ), 3 ) + "\" + FMT0L( Str( ConvRBK( Hit->rbk ) ), 8 ), 0 } )
	 ++nUkup

	 kk = Hit->pogodak

	 Hit->( dbSkip() )

      ENDDO

RETURN aCol

/*
FUNCTION IndFunc()

LOCAL nPog := 0, ;
      cRet := ""

	 IF Hit->pogodak = 10
	    IF Int(Hit->rbk / 5) == Hit->rbk / 5
	       nPog = 11
	    ELSE
	       nPog = 10
	    ENDIF
	 ELSE
	    nPog = Hit->pogodak
	 ENDIF

	 nPog = 15 - nPog
	 cRet = FMT0L( Str(nPog), 2)

RETURN cRet
*/
