#include "commands.ch"

STATIC _xms_is    := .F., ;
       _xms_block := 0, ;
       _xms_total := 0, ;
       _user_xms  := .F., ;
       _xms_num1  := 0, ;	    && xms pages for cnlist.dat
       _xms_num2  := 0		    && xms pages for cnlist3.dat

FUNCTION XMS_Init()

LOCAL lRetVal := .T., ;
      cTemp   := Replicate(Chr(0), 8)

      IF !_is_xms()
	 alert( "Nema podrske za XMS!", {" OK "} )
	 RETURN .F.
      ENDIF

      _xms_api()

      _query_xms(cTemp)

      _xms_block = Bin2L( SubStr( cTemp, 1, 4 ) )
      _xms_total = Bin2L( SubStr( cTemp, 5, 4 ) )

      _user_xms = .F.

      IF !_dos_alloc()
	 alert("Nedovoljno konvencionalne memorije!", {" OK "})
	 lRetVal= .F.
      ELSE
	 _xms_is := .T.
      ENDIF

RETURN lRetVal

FUNCTION XMS_Close()

LOCAL i        := 0, ;
      nRetCode := 0

      _dos_free()

      IF _xms_is

	 nRetCode = _free_xms()
	 IF nRetCode != 1
	    alert("XMS free error: " + Str(nRetCode, 4), {" OK "})
	 ENDIF

	 _xms_is = .F.
	 _user_xms = .F.

      ENDIF

RETURN NIL

FUNCTION XMS_Info()

LOCAL nTemp := 0

      IF _xms_is

	 ? "MAXI - XMS Info"
	 ? "Block size: " + Transform(_xms_block, "999,999,999 KB")
	 ? "Total size: " + Transform(_xms_total, "999,999,999 KB")
         ?

#ifdef ZASTITA
	 SentRead( 11, @nTemp )
	 ? "Key count : " + AllTrim( Str(nTemp) )
         ?
#endif

	 ? "User memory"

	 IF _user_xms
	    nTemp = Bin2L( L2Bin( _info_xms() ) )
	    ? Transform( nTemp, "999,999,999 KB")
	 ELSE
	    ? "Not used"
	 ENDIF

      ELSE
	 ? "No XMS present"
      ENDIF

RETURN NIL

FUNCTION XMS_Alloc(nByte)

LOCAL nNumBlock := 0, ;
      i 	:= 0, ;
      nUkup	:= 0, ;
      lRetVal	:= .T.,;
      nRetCode	:= 0

      IF !_xms_is
	 alert("XMS not present!", {" OK "})
	 RETURN .F.
      ENDIF

      IF nByte > ( _xms_block * 1024 )
	 alert("Not enough XMS memory!", {" OK "})
	 RETURN .F.
      ENDIF

      nUkup = ( Int(nByte / 32768) + 2 ) * 32768

      nRetCode = _alloc_xms( Int(nUkup / 1024) )
      IF nRetCode != 1
	 alert( "Greska u alokaciji XMS: " + Str( nRetCode, 3 ) )
      ELSE
	 _user_xms = .T.
      ENDIF

RETURN lRetVal

FUNCTION F2XMS(cFile)

LOCAL nHandle := 0, ;
      nLength := 0, ;
      brojac  := 0, ;
      nTrans  := 0, ;
      numpage := 0

      cFile = Upper( AllTrim( cFile ) )

      IF !File(cFile)
	 alert(Upper(cFile) + " ne postoji!", {" OK "})
	 RETURN NIL
      ENDIF

      nHandle = FOpen(cFile)

      nLength = FSeek(nHandle, 0, 2)

      IF cFile == "CNLIST.DAT"
	 GetHeader(nHandle)
	 FSeek(nHandle, 40, 0)
      ENDIF

      DO WHILE nLength > 0

	 IF nLength > 32768
	    nTrans = 32768
	 ELSE
	    nTrans = nLength
	 ENDIF

	 _f2xms(nHandle, nTrans, numpage)

	 ++numpage
	 nLength -= nTrans

      ENDDO

      FClose(nHandle)

RETURN NIL

STATIC FUNCTION GetHeader(nFileHandle)

LOCAL cTemp	:= Space(40)

      FSeek( nFileHandle, 0, 0 )
      FRead( nFileHandle, @cTemp, 40 )

      cKolo	:= SubStr( cTemp,  1 , 3 )
      fnd_15   := Bin2L( SubStr(cTemp,	4, 4) ) / 100
      fnd_14   := Bin2L( SubStr(cTemp,	8, 4) ) / 100
      fnd_13   := Bin2L( SubStr(cTemp, 12, 4) ) / 100
      nUkKart  := Bin2L( SubStr(cTemp, 20, 4) )
      nUkFond  := Bin2L( SubStr(cTemp, 24, 4) ) / 100

RETURN NIL

FUNCTION GetXmsStart( nWhat )

 Local nRet := 0

 DEFAULT nWhat TO 1

      DO CASE

	 CASE nWhat == 1	    && cnlist.dat
	      nRet := _xms_num1

	 CASE nWhat == 2	    && cnlist3.dat
	      nRet := _xms_num2

      ENDCASE

RETURN nRet
