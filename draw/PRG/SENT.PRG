// SentinelPro

#define DEVID	   36067
// #define WPW	      53155
// #define OWP1       63016
// #define OWP2        9710

static unitInfo, WPW := 0, OWP1 := 0, OWP2 := 0

FUNCTION SentInit()

 Local lRet := .f., ;
       data := 0

   if _SproInit() != 0
      return .f.
   endif

   unitInfo := Space(24)

   if _SproFirst( (DEVID), @unitInfo ) != 0
      return .f.
   endif

   SentRead( 8,  @WPW  )
   SentRead( 9,  @OWP1 )
   SentRead( 10, @OWP2 )

RETURN .t.

FUNCTION SentRead( addr, data )

   if _SproRead( @unitInfo, (addr), @data ) != 0
      return .f.
   endif

RETURN .t.

FUNCTION SentActive( addr, cPass )

 Local cWP1 := Space(2), cWP2 := Space(2)

   cWP1 := Bin2W( Hex2Bin( SubStr( cPass, 1, 4 ) ) )
   cWP2 := Bin2W( Hex2Bin( SubStr( cPass, 5, 4 ) ) )

   if _SproActiv( @unitInfo, (WPW), (cWP1), (cWP2), (addr) ) != 0
      return .f.
   endif

RETURN .t.

FUNCTION SentDecr( addr )

   if _SproDecr( @unitInfo, (WPW), (addr) ) != 0
      return .f.
   endif

RETURN .T.

FUNCTION SentQuery( addr, query, vresponse )

 Local response  := Space( Len(query) ), ;
       queryData := Space( Len(query) ), ;
       cnt	 := 0, ;
       lRet	 := .f.

   CvrtQueryStr( query, @queryData )

   while cnt < 10

     if _SproQuery( @unitInfo, (addr), @queryData, @response, 0, ( Len(query) / 2 ) ) == 0

	if queryData != response
	   lRet := .t.
	   EXIT
	endif

     endif

     ++cnt

   enddo

   if ( vresponse != nil ) .and. lRet
      vresponse := response
   endif

RETURN lRet

FUNCTION SentOWrite( addr, data, acess )

   if _SproOverw( @unitInfo, (WPW), (OWP1), (OWP2), (addr), (data), (acess) ) != 0
      return .f.
   endif

RETURN .T.

FUNCTION SwapByte( cWord )
RETURN Right( cWord, 1 ) + Left( cWord, 1 )

*
* Convert a hex character to a digit (0 - 15)
*
FUNCTION HexToDigit (ch)
        PRIVATE testch, digit

        IF ISDIGIT (ch)
        digit = (ASC(ch) - ASC('0'))
        ELSE
        testch = UPPER (ch)
        digit = (ASC(testch) - ASC('A') + 10)
        ENDIF

RETURN digit

*
* Converts the query string to a real query string
*
PROCEDURE CvrtQueryStr(queryData, queryStr)
        PRIVATE hexstr, i, temp

        hexstr = RTRIM(queryData)
        queryStr = ""

        FOR i = 1 TO LEN (hexstr) STEP 2
        temp = (HexToDigit (SUBSTR (hexstr, i, 1)) * 16) ;
               + HexToDigit (SUBSTR (hexstr, i + 1, 1) )
        queryStr = queryStr + CHR (temp)
        NEXT

RETURN

FUNCTION Hex2Bin( hexstr )

 Local i     := 0, ;
       cTemp := "", ;
       cRet  := ""

   hexstr := AllTrim( hexstr )
   if ( Len( hexstr ) / 2 ) != Int( Len( hexstr ) / 2 )
      hexstr := '0' + hexstr
   endif

   cTemp := Space( Len( hexstr ) / 2 )

   CvrtQueryStr( hexstr, @cTemp )

   for i := Len(cTemp) to 1 step -1
       cRet += SubStr( cTemp, i, 1 )
   next

RETURN cRet

FUNCTION GetPass()

 Local cOldScreen, ;
       cPass   := Space(8), ;
       GetList := {}, ;
       xTemp   := "", ;
       data    := 0

   cOldScreen := SetColor()

   WinStyle( 9, 25, 15, 55, "PASSWORD" )

   @ 11,27 SAY "Unesite lozinku:"
   @ 13,27 GET cPass PICTURE "@!XXXXXXXX" VALID !Empty(cPass)

   SetCursor(1)
   READ
   SetCursor(0)

   IF LastKey() != 27

      if SentActive( 12, cPass )

	 if SentQuery( 12, SubStr( cPass, 1, 4 ), @xTemp )
	    xTemp := Bin2W( SwapByte(xTemp) )
	    SentOWrite( 14, xTemp, 3 )
	 endif

	 if SentQuery( 12, SubStr( cPass, 5, 4 ), @xTemp )
	    xTemp := Bin2W( SwapByte(xTemp) )
	    SentOWrite( 15, xTemp, 3 )
	 endif

	 SentRead( 16, @data )

	 SentOWrite( 11, data, 2 )

      else

	 setcolor("w/n")
	 cls
	 alert( "Neispravna sifra!!!", { "QUIT" } )
	 quit

      endif

   else

      setcolor("w/n")
      cls
      quit

   endif

   SetColor( cOldScreen )

RETURN NIL

FUNCTION WinStyle(t,l,b,r,text,ColStr)

LOCAL cOldColor

	 SetColor("N/W,W+/B,,,B/W")

	 @ t, l CLEAR TO b, r
	 // sha_shadow(t, l, b, r)

	 SetColor("G+/B")
	 @ t, l CLEAR TO t,r
	 @ t, (l+(r-l)/2) - Int(Len(text)/2) SAY text

	 SetColor("N/W,W+/B,,,B/W")

RETURN NIL

FUNCTION SentTest( lVar )

 Local lRet := .f.

   if SentQuery( 12, "4591" )
      lVar := .t.
      lRet := .t.
   else
      lVar := .f.
   endif

RETURN lRet
