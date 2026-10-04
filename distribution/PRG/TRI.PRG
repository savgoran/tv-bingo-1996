#include "sixcdx2.ch"
#include "machsix.ch"
#include "fileio.ch"
#include "commands.ch"

FUNCTION GenOneCod()

LOCAL cPatt	:= Replicate( Chr(0), 6 ), ;
      bajt_pos	:= 0, ;
      bit_pos	:= 0, ;
      nBroj	:= 0, ;
      pBroj	:= 0, ;
      nBrPat	:= 0, ;
      i 	:= 0, ;
      cStr	:= ""

      FOR i = 1 TO 5

	  nBroj = Asc( SubStr( Listic5->sadrzaj, i, 1 ) )

	  bajt_pos = Int( nBroj / 8 ) + 1
	  bit_pos = Int( nBroj % 8 )
	  pBroj = 2 ** bit_pos
	  nBrPat = Asc( SubStr( cPatt, bajt_pos, 1 ) ) + pBroj
	  cPatt = Stuff( cPatt, bajt_pos, 1, Chr( nBrPat ) )

      NEXT

      // cStr = L2Bin( nSer ) + cPatt
      cStr = cPatt

RETURN cStr

FUNCTION Get3od90( nRecNo )

 Local cRet  := "", ;
       aTemp := {}, ;
       i     := 0

      Listic5->( dbGoTo( Int( ( nRecNo - 1 ) / 3 ) + 1 ) )

      FOR i = 1 TO 5
	  aadd( aTemp, FMT0L( Str( Asc( SubStr( Listic5->sadrzaj, i, 1 ) ) ), 2 ) )
	  cRet += aTemp[i]
	  if i < 5
	     cRet += ", "
	  endif
      NEXT

      // cRet += aTemp[1] + "," + aTemp[2] + "-" + aTemp[3]

RETURN cRet

FUNCTION TriTest()

 Local nHandle, ;
       cBuff := Space(16)

   nHandle := FOpen( "cnlist3.dat" )

   IniPtr()
   Prt1()
   Prt2()

   DO WHILE .T.

      if FRead( nHandle, @cBuff, 16 ) != 16
	 EXIT
      endif

      ? Str( Bin2L( SubStr( cBuff, 1, 3 ) + Chr(0) ), 6 ) + ". " + ReEX( SubStr( cBuff, 5 ) )

   ENDDO

   FClose( nHandle )

   Prt3()

RETURN NIL
