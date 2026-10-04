#include "llibg.ch"
#include "inkey.ch"
#include "commands.ch"
#include "error.ch"

FUNCTION Main( nCmdP1 )

LOCAL aCmd     := {} , ;
      nHandle  := 0  , ;
      objLocal, ;
      bLastHandler

PUBLIC nTimeBeg := TimeToSec( Time() ), nTimeEnd := 0

PRIVATE cPogodak   := Replicate(Chr(0), 44), ;
	cTestKomb  := Replicate(Chr(0), 12), ;
	aPog	   := {}, ;
	lBat	   := .F., ;
	cBuff3	   := ""

PRIVATE aBigFont := {}, ;
	aRBFont  := {}, ;
	aCNTFont := {}, ;
	cFileRes := "", ;
        cKolo    := "", ;
	fnd_15	 := 0, ;
	fnd_14	 := 0, ;
	fnd_13	 := 0, ;
	nUkKart  := 0, ;
	nUkFond  := 0

* INI promenljive
PRIVATE nNumColor  := 14, ;
	cFont	   := "", ;
	nBigX	   := 10, ;
	nBigY	   := 10, ;
	nBigColor  := 14, ;
	nRBX	   := 10, ;
	nRBY	   := 10, ;
	nStartScan := 0 , ;
	n10X	   := 300,;
	n10Y	   := 20, ;
	nVolume    := 180,;
	sl1	   := "",;
	sl2	   := "",;
	sl3	   := "",;
	sl4	   := "",;
	sl5	   := "",;
	sl6	   := "",;
	sl7	   := "",;
	sl8	   := "",;
	sl9	   := "",;
	nCNTX	   := 430, ;
	nCNTY	   := 10, ;
	fastscan   := 0

PRIVATE xNumPos    := 0, ;
	nCntNum    := 0, ;
	aFont	   := {}, ;
	kraj	   := .T., ;
	aBroj	   := {}, ;
	nBrRed	   := 0, ;
	nScroll    := 0, ;
	nTick	   := 0, ;
	nWid	   := 0

      SET SCOREBOARD OFF
      SET INTENSITY ON

      SetCancel(.f.)

#ifdef ZASTITA

// 旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
// � HARDVERSKA ZASTITA 			  �
// �						  �
// �						  �
// 읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸

_DecryptX( 97, 7, 0, 5777 )

if !SentInit()
   cls
   ? "Error(1001) Pozovite servis!!!"
   quit
endif

SentDecr( 11 )

if !SentQuery( 12, "4855" )
   GetPass()
endif

#endif

      cFont	 = ReadIni("kargen.ini", "numfont")
      nNumColor  = Val( ReadIni("kargen.ini", "numcolor") )
      nBigX	 = Val( ReadIni("kargen.ini", "nbigx") )
      nBigY	 = Val( ReadIni("kargen.ini", "nbigy") )
      nBigColor  = Val( ReadIni("kargen.ini", "nBigColor") )
      nRBX	 = Val( ReadIni("kargen.ini", "nrbx") )
      nRBY	 = Val( ReadIni("kargen.ini", "nrby") )
      nStartScan = Val( ReadIni("kargen.ini", "nstartscan") )
      n10X	 = Val( ReadIni("kargen.ini", "n10x") )
      n10Y	 = Val( ReadIni("kargen.ini", "n10y") )
      nVolume	 = Val( ReadIni("kargen.ini", "nVolume") )
      nCNTX	 = Val( ReadIni("kargen.ini", "nCNTX") )
      nCNTY	 = Val( ReadIni("kargen.ini", "nCNTY") )
      fastscan	 = Val( ReadIni("kargen.ini", "fastscan") )
      sl1	 =  ReadIni("kargen.ini", "sl1")
      sl2	 =  ReadIni("kargen.ini", "sl2")
      sl3	 =  ReadIni("kargen.ini", "sl3")
      sl4	 =  ReadIni("kargen.ini", "sl4")
      sl5	 =  ReadIni("kargen.ini", "sl5")
      sl6	 =  ReadIni("kargen.ini", "sl6")
      sl7	 =  ReadIni("kargen.ini", "sl7")
      sl8	 =  ReadIni("kargen.ini", "sl8")
      sl9	 =  ReadIni("kargen.ini", "sl9")

      bLastHandler := ErrorBlock( { |oErr| MyHandler(oErr, .T.) } )

      BEGIN SEQUENCE

      IF !XMS_Init()
	 alert("Nema podrske za XMS!", {" OK "})
	 BREAK
      ENDIF

      IF !File("cnlist.dat")
	 Alert("CNLIST.DAT ne postoji!", {" OK "})
	 BREAK
      ENDIF

      InitSnd(2)
      SetVolume(nVolume)

      IF !XMS_Alloc( FileSize("cnlist.dat") + FileSize("cnlist3.dat") )
	 BREAK
      ENDIF

      ?
      ? "Ucitavanje listica..."

      F2XMS("cnlist.dat")

      XMS_Info()
      Inkey(5)

      CLS

      aFont    = GFntLoad(cFont)
      aBigFont = GFntLoad("swiss.fnt")
      aRBFont  = GFntLoad("swiss20.fnt")
      aCNTFont	= GFntLoad("chelv12.fnt")

      CalcFnt(aFont)

      * SET VIDEOMODE TO LLG_VIDEO_VGA_640_480_16
      * SET VIDEOMODE TO LLG_VIDEO_VESA_640_480_256
      SET VIDEOMODE TO LLG_VIDEO_VESA_640_480_256

      * SetColor("w/b+,w/b+")
      * GRect( 0, 0, 640, 480, LLG_FILL, 9, LLG_MODE_SET )

      LoadSound( "ding.raw" )

      DispBig("00")
      WrRB()

      IF File("emg.mem")
	 aBroj := ReadEmg()
	 ChgFont(.f.)
      ENDIF

      DO WHILE kraj

	 aCmd = GetCmd()

	 IF aCmd[1] != "IDLE"
	    ApplyCmd( aCmd )
	 ENDIF

      ENDDO

      SET VIDEOMODE TO LLG_VIDEO_TXT

      GFntErase(aFont)
      GFntErase(aBigFont)
      GFntErase(aRBFont)
      GFntErase(aCNTFont)

      END SEQUENCE

      XMS_Close()

      ErrorBlock( bLastHandler )

      FErase("emg.mem")

/* STRUKTURA DATOTEKE cpatt.dat

   0 - kolo
   4 - pattern za pretrazivanje
   8 - broj dobitnika sa 15
  12 - broj dobitnika sa 14
  16 - broj dobitnika sa 13
  20 - ukupan broj izvucenih brojeva
  22 - izvuceni brojevi (uk.br.izv.br * 2)

*/

      IF Len(aPog) > 0 .AND. !lBat

	 nHandle = FCreate("cpatt.dat")

	 * upis broja kola
	 FWrite(nHandle, cKolo)

	 * upis paterna 12 bajta
	 FWrite(nHandle, cTestKomb)

	 * 15
	 FWrite( nHandle, L2Bin(aPog[1,1]) )
	 * 14
	 FWrite( nHandle, L2Bin(aPog[2,1]) )
	 * 13
	 FWrite( nHandle, L2Bin(aPog[3,1]) )

	 * upis ukupnog broja izvucenih brojeva
	 FWrite( nHandle, Str(Len(aBroj), 2) )

	 * upis brojeva
	 FOR i = 1 TO Len(aBroj)
	     FWrite(nHandle, aBroj[i])
	 NEXT

	 * upis datuma
	 FWrite(nHandle, DtoC(Date()))

	 FClose(nHandle)

      ENDIF

      SpkOff()

      QUIT

RETURN NIL

FUNCTION GetCmd()

LOCAL cTemp := Space(30)

      @ MaxRow(), 0 SAY "Command:" GET cTemp PICTURE "@!" COLOR "bg/n,w/n"

      SetCursor(1)
      READ
      SetCursor(0)

      IF LastKey() != K_ESC
	 if Empty(cTemp)
	    cTemp := "IDLE"
	 else
	   cTemp = Upper( AllTrim( cTemp ) )
	 endif
      ELSE
	 cTemp = "IDLE"
      ENDIF

RETURN TokCmd( cTemp )

FUNCTION ApplyCmd( aCmd )

LOCAL l_15    := .F., ;
      l_3     := .f., ;
      nTemp   := 0, ;
      cntbuff := Replicate( Chr(0), 12 ), ;
      Buff_10 := Replicate( Chr(0), 400 )    && mesto za 100 dobitaka

      DO CASE

	 CASE aCmd[1] == "-"

	      Pano("")
	      Undo()
	      cTestKomb = FillPatt(aBroj)

	 CASE IsDigit( aCmd[1] )

#ifdef ZASTITA
	      IF !SentTest()
		 alert( "Hardverska zastita istekla!!!" )
	      ENDIF
#endif

	      IF WriteDigit(aCmd[1])

		 PlaySound()

		 cTestKomb = FillPatt(aBroj)

		 IF ( nStartScan > 0 ) .AND. ;
		    ( Len(aBroj) >= nStartScan )

		    Pano("")

		    DispBig( aBroj[ Len(aBroj) ], .T., 14)     && zuto

		    //l_15 = lCheck_15( cTestKomb, Buff_10, GetXmsStart( 1 ) )
		    IF fastscan = 0
		      l_15 = lCheck_15( cTestKomb, Buff_10 )
		    ELSE
		      cntbuff := Replicate( Chr(0), 12 )
		      lCheckCnt( cTestKomb, cntbuff )
		      nCnt15 := Bin2L(SubStr(cntbuff, 1, 4))
		      nCnt14 := Bin2L(SubStr(cntbuff, 5, 4))
		      nCnt13 := Bin2L(SubStr(cntbuff, 9, 4))
		      l_15 := nCnt15 > 0
		      WrCNT(nCnt15, nCnt14, nCnt13)
		    ENDIF

		    IF l_15

		       DispBig( aBroj[ Len(aBroj) ], .T., 12)	&& crveno

		       Buff_10 = SubStr( Buff_10, 1, at( Replicate( Chr(0), 4), Buff_10 ) - 1 )

		       LoadSound( "stop.raw" )
		       PlaySound(.t.)
		       LoadSound( "ding.raw" )

		       Pano("D O S T A", .T.)
		       //Prik_10( Buff_10 )
		       DrawTop()

                    ELSE

		       DispBig( aBroj[ Len(aBroj) ], .T.)   && zeleno
		       Pano("NEMA POGODAKA")

		    ENDIF

		 ENDIF

              ENDIF


         CASE aCmd[1] == "FONT"
	      ChgFont()

	 CASE aCmd[1] == "FOND"
	      ShwFond()

	 CASE aCmd[1] == "NUMCOLOR"
	      IF GetPrompt("Broj boje:", "nNumColor", {|| .T. })
		 ChgFont(.f.)
	      ENDIF

	 CASE aCmd[1] == "RESULT"
	      aPog = Result()

	 CASE aCmd[1] == "TEST"
	      Test( if( Len(aCmd) > 1, Val(aCmd[2]), nil ), if( Len(aCmd) > 2, Upper(aCmd[3]), nil ) )

         CASE aCmd[1] == "TOPV"
	      DrawTop()

	 CASE aCmd[1] == "SL1"
	      IF File(sl1)
		GBmpDisp(GBmpLoad(sl1), 0, 0)
		Inkey(0)
		CLS
		ChgFont(.f.)
	      ENDIF

	 CASE aCmd[1] == "SL2"
	      IF File(sl2)
		GBmpDisp(GBmpLoad(sl2), 0, 0)
		Inkey(0)
		CLS
		ChgFont(.f.)
	      ENDIF

	 CASE aCmd[1] == "SL3"
	      IF File(sl3)
		GBmpDisp(GBmpLoad(sl3), 0, 0)
		Inkey(0)
		CLS
		ChgFont(.f.)
	      ENDIF

	 CASE aCmd[1] == "SL4"
	      IF File(sl4)
		GBmpDisp(GBmpLoad(sl4), 0, 0)
		Inkey(0)
		CLS
		ChgFont(.f.)
	      ENDIF

	 CASE aCmd[1] == "SL5"
	      IF File(sl5)
		GBmpDisp(GBmpLoad(sl5), 0, 0)
		Inkey(0)
		CLS
		ChgFont(.f.)
	      ENDIF

	 CASE aCmd[1] == "SL6"
	      IF File(sl6)
		GBmpDisp(GBmpLoad(sl6), 0, 0)
		Inkey(0)
		CLS
		ChgFont(.f.)
	      ENDIF

	 CASE aCmd[1] == "SL7"
	      IF File(sl7)
		GBmpDisp(GBmpLoad(sl7), 0, 0)
		Inkey(0)
		CLS
		ChgFont(.f.)
	      ENDIF

	 CASE aCmd[1] == "SL8"
	      IF File(sl8)
		GBmpDisp(GBmpLoad(sl8), 0, 0)
		Inkey(0)
		CLS
		ChgFont(.f.)
	      ENDIF

	 CASE aCmd[1] == "SL9"
	      IF File(sl9)
		GBmpDisp(GBmpLoad(sl9), 0, 0)
		Inkey(0)
		CLS
		ChgFont(.f.)
	      ENDIF

	 CASE aCmd[1] == "IZLAZ"
	      IF GetYN("Kraj rada:")
		 kraj = .F.
	      ENDIF

      ENDCASE

RETURN NIL

FUNCTION GetYN(cText)

LOCAL cOldPrompt := "", ;
      cAns	 := Space(1), ;
      lRetVal	 := .F.

      cOldPrompt = SaveScreen(24,0,24,79)

      @ MaxRow(), 0 CLEAR TO MaxRow(), 79

      @ MaxRow(), 0 SAY cText GET cAns PICTURE "@!X" VALID cAns $ "DN"

      SetCursor(1)
      READ
      SetCursor(0)

      IF LastKey() != 27
	 IF cAns = "D"
	    lRetVal = .T.
	 ENDIF
      ENDIF

      RestScreen(cOldPrompt)

RETURN lRetVal

FUNCTION Getprompt(cText, cVar, bBlock)

LOCAL cOldPrompt := "", ;
      cAns	 := Space(1), ;
      lRetVal	 := .T., ;
      GetList	 := {}

      DEFAULT bBlock TO {|| .T.}

      cOldPrompt = SaveScreen(24,0,24,79)

      @ MaxRow(), 0 CLEAR TO MaxRow(), 79

      @ MaxRow(), 0 SAY cText
      aadd( GetList, GetNew(MaxRow(), Col() + 1, MemVarBlock(cVar)) )

      GetList[1]:postBlock = bBlock

      SetCursor(1)
      ReadModal(GetList)
      SetCursor(0)

      IF LastKey() == 27
	 lRetVal = .F.
      ENDIF

      @ MaxRow(), 0 CLEAR TO MaxRow(), 79
      RestScreen(24,0,24,79,cOldPrompt)

RETURN lRetVal

FUNCTION WriteDigit(cBr, opc)

LOCAL lRetVal := .T., ;
      i       := 0

	 DEFAULT opc TO .T.

	 cBr = FMT0L(cBr, 2)

	 FOR i = 1 TO Len(cBr)
	     IF !IsDigit( SubStr(cBr, i, 1) )
		RETURN .F.
	     ENDIF
	 NEXT

	 IF opc
	    IF Len(aBroj) > 0
	       IF AScan(aBroj, cBr) != 0
		  RETURN .F.
	       ENDIF
	    ENDIF
         ENDIF

	 IF Val(cBr) > 90 .OR. Val(cBr) < 1
	    RETURN .F.
	 ENDIF

	 ++nCntNum
	 IF nCntNum % (nBrRed + 1) == 0
	    Scroll(16, 0, 27, 79, nScroll)
	    nCntNum = 1
	    xNumPos = nTick
	 ENDIF

	 GWriteAt(xNumPos, 408, cBr, nNumColor, LLG_MODE_SET, aFont)
	 xNumPos += nWid + nTick

	 IF opc
	    DispBig(cBr, .T.)
	    aadd(aBroj, cBr)
	    WriteEmg(aBroj)
	 ENDIF

	 WrRB( Len(aBroj) )

RETURN lRetVal

FUNCTION Undo()

LOCAL cLastBr := aBroj[Len(aBroj)]

	 xNumPos -= nWid + nTick

	 IF nCntNum = 0
	    Scroll(16, 0, 27, 79, 0 - nScroll)
	    nCntNum = nBrRed
	    xNumPos = nTick + ( (nWid + nTick) * (nBrRed - 1) )
	 ENDIF

	 --nCntNum

	 GWriteAt(xNumPos, 408, cLastBr, 0, LLG_MODE_SET, aFont)

	 aDel(aBroj, Len(aBroj))
	 ASize(aBroj, Len(aBroj)-1)

	 IF Len(aBroj) > 0
	    DispBig( aBroj[ Len(aBroj) ] )
	 ELSE
	    DispBig( "", .F. )
	 ENDIF

RETURN NIL

STATIC FUNCTION CalcFnt(aFont)

LOCAL nTemp := 0

      nTemp = GWriteAt(0, 0, "00", 0, LLG_MODE_NIL, aFont)

      nWid   = nTemp
      nTick  = Int(nTemp / 2)
      nTemp += nTick
      nBrRed = Int(640 / nTemp)

      nScroll = Int(aFont[LLG_FNT_AVGWIDTH] / 16) + 1

      xNumPos = nTick

RETURN NIL

FUNCTION ChgFont(opc)

LOCAL i := 0

      DEFAULT opc TO .T.

      IF opc

	 IF !GetPrompt("Font name:", "cFont", {|| File( AllTrim(cFont) + ".fnt") } )
	    RETURN NIL
	 ENDIF

	 aFont = GFntLoad(cFont)

      ENDIF

      IF Len( aBroj ) > 0

	 * GRect( 0, 0, 640, 480, LLG_FILL, 9, LLG_MODE_SET )

	 CalcFnt(aFont)

	 nCntNum = 0

	 Scroll(16, 0, 27, 79, -16)

	 FOR i = 1 TO Len(aBroj)
	     WriteDigit(aBroj[i], .F.)
	 NEXT

	 DispBig( aBroj[ Len(aBroj) ] )
	 Fresh_10()

      ELSE

	 * GRect( 0, 0, 640, 480, LLG_FILL, 9, LLG_MODE_SET )

	 WrRB( 0 )
	 DispBig( "00" )

      ENDIF

RETURN NIL

FUNCTION DispBig(cNum, opc, nColor)

      DEFAULT opc    TO .T.
      DEFAULT nColor TO 9

/*
      IF Left(cNum, 1) == "0"
	 cNum = Right(cNum, 1)
      ENDIF
*/

      IF opc

	 * broj u krugu
	 * GEllipse(nBigX, nBigY, 40, 40, , , LLG_FILL, 7, LLG_MODE_SET, 14)
	 * GPrint(nBigX, nBigY, cNum, 9, 1, aBigFont, 1)

	 * broj u kocki
	 GFrame(nBigX, nBigY, nBigX + 50, nBigY + 50, 7, 8, 15, 3, 3, 3, 3, LLG_MODE_SET)
	 * GRect(nBigX, nBigY, nBigX + 50, nBigY + 50, LLG_FILL, nColor, LLG_MODE_SET)
	 GPrint(nBigX + 25, nBigY + 25, SubStr(cNum,1,1), nBigColor, 1, aBigFont, 1)

	 GFrame(nBigX + 53, nBigY, nBigX + 50 + 53, nBigY + 50, 7, 8, 15, 3, 3, 3, 3, LLG_MODE_SET)
	 * GRect(nBigX + 53, nBigY, nBigX + 50 + 53, nBigY + 50, LLG_FILL, nColor, LLG_MODE_SET)
	 GPrint(nBigX + 53 + 25, nBigY + 25, SubStr(cNum,2,1), nBigColor, 1, aBigFont, 1)

      ELSE

	 * GEllipse(nBigX, nBigY, 40, 40, , , LLG_FILL, 0, LLG_MODE_SET, 0)

	 GRect(nBigX, nBigY, nBigX + 53 + 50, nBigY + 50, LLG_FILL, 0, LLG_MODE_SET)

      ENDIF

RETURN NIL

STATIC FUNCTION FillPatt(aRndBr)

LOCAL i, bajt_pos, bit_pos, nBroj, pBroj, tPatt

       tPatt = Replicate(Chr(0),12)

       FOR i = 1 TO Len(aRndBr)
	   nBroj = Val( aRndBr[i] )
	   IF nBroj != 0
	      bajt_pos = Int( nBroj / 8 ) + 1
	      bit_pos = Int( nBroj % 8 )
	      pBroj = 2 ** bit_pos
	      nBrPat = Asc( SubStr( tPatt, bajt_pos,1 ) ) + pBroj
	      tPatt = Stuff( tPatt, bajt_pos, 1, Chr( nBrPat ) )
	   ENDIF
       NEXT

RETURN tPatt

/*
FUNCTION PrikDob()

LOCAL i   := 0, ;
      red := 100, ;
      nTemp := 0, ;
      aFFF  := {}

      aFont = GFntLoad("chelv32.fnt")

      FOR i = 11 TO 7 STEP -1
	  nTemp = GWriteAt(10, red, Str(i-1,2) + ". pogodaka:", 14, LLG_MODE_SET, aFont)
	  GPrint(630, red, Str( Bin2L( SubStr(cPogodak, ((i-1) * 4) + 1, 4) ), 7) , 14, 2, aFont)
	  red += 55
      NEXT

      GFntErase(aFFF)

RETURN NIL
*/

FUNCTION GPrint(x, y, cText, nColor, nJustify, aFont, nVerJust)

LOCAL nTemp   := 0

      DEFAULT nJustify TO  0
      DEFAULT nColor   TO  0
      DEFAULT nVerJust TO  0

      nTemp = GwriteAT(x, y, cText, nColor, LLG_MODE_NIL, aFont)

      DO CASE
	 CASE nJustify == 0   && left
	      x = x
	 CASE nJustify == 1   && center
	      x = Int(x - (nTemp / 2))
	 CASE nJustify == 2   && right
	      x -= nTemp
      ENDCASE

      DO CASE
	 CASE nVerJust == 0   && top
	      y = y
	 CASE nVerJust == 1   && middle
	      y = y - Int(aFont[LLG_FNT_HEIGHT] / 2)
	      y -= 1
	 CASE nVerJust == 2   && bottom
	      y = y - aFont[LLG_FNT_HEIGHT]
      ENDCASE

      GwriteAT(x, y, cText, nColor, LLG_MODE_SET, aFont)

RETURN NIL

FUNCTION Pano(cText, opc)

      DEFAULT opc TO .F.

      cText = padr( Left( Upper(cText), 15 ), 15, " " )

      @ MaxRow(), MaxCol() - 15 SAY cText COLOR iif(opc, "r+/n", "w/n")

RETURN NIL

FUNCTION WrRB(nBr)

LOCAL cBr := ""

      DEFAULT nBr TO 0

      cBr = FMT0L(Str(nBr), 2)

      GRect(nRBX, nRBY, nRBX + 50, nRBY + 30, LLG_FILL, 12, LLG_MODE_SET)

      GPrint(nRBX + 25, nRBY + 15, cBr, 15, 1, aRBFont, 1)

RETURN NIL

FUNCTION MyHandler( oError, lLocalHandler )

LOCAL i    := 0, ;
      nAct := 1

      IF oError:genCode == EG_ZERODIV
	 RETURN 0
      ENDIF

      SET VIDEOMODE TO LLG_VIDEO_TXT
      alert("(" + AllTrim( Str( oError:genCode ) ) + ") " + AllTrim( oError:description ) + ": "  + AllTrim( oError:operation ) + " File: " + AllTrim(oError:filename), {" OK "} )

      while !( ProcName( nAct ) == "" )
	  ? "Called from:", ProcName( nAct ), ;
	    "(" + LTrim( Str( ProcLine( nAct ) ) ) + ")"
	  nAct++
      enddo

      BREAK

RETURN NIL

FUNCTION Test( p1, p2 )

 Local aTest := {}

 DEFAULT p1 TO 15
 DEFAULT p2 TO "NORMAL"

   aBroj := {}

   DO CASE
      CASE p2 == "NORMAL"
      for i = 1 to p1
	  aadd( aBroj, FMT0L( Str( i ), 2 ) )
      next
      CASE p2 == "RND"
      for i = 1 to p1
	  // aadd( aBroj, FMT0L( Str( Int( Random() % 90 ) + 1 ), 2 ) )
	  aBroj := NumRnd( p1 )
      next
   ENDCASE

   cTestKomb = FillPatt( aBroj )
   ChgFont(.f.)

   // KEYBOARD "RESULT" + Chr(K_ENTER)

return nil

FUNCTION NumRnd( nHow )

 Local aRet := {}, ;
       cnt  := 0, ;
       num  := 0, ;
       nInc := 0

   nInc := Int( 90 / nHow ) + 3
   num	:= Int( Random() % 9 ) + 1

   do while cnt <= nHow

      if AScan( aRet, FMT0L( Str( num ), 2 ) ) == 0 .or. ;
	 Len( aRet ) == 0
	 AAdd( aRet,  FMT0L( Str( num ), 2 ) )
	 ++cnt
      endif

      num += nInc
      if num > 90
	 num := Int( Random() % 9 ) + 1
      endif

   end

RETURN aRet

FUNCTION DrawTop()

  DO WHILE nextkey() == 0
     GBmpDisp(GBmpLoad("tops.bmp"), 180, 10)
     MilliSec(600)
     GBmpDisp(GBmpLoad("topl.bmp"), 180, 10)
     MilliSec(600)
     GRect(180, 10, 380, 100, LLG_FILL, 0, LLG_MODE_SET)
  ENDDO

  GRect(180, 10, 380, 100, LLG_FILL, 0, LLG_MODE_SET)

RETURN NIL

FUNCTION WrCNT(nCnt15, nCnt14, nCnt13)

 Local x := nCNTX, ;
       y := nCNTY

      GRect(x, y, x + 60, y + 24, LLG_FILL, iif(nCnt15 > 0, 4, 8), LLG_MODE_SET)
      GPrint(x + 30, y + 15, AllTrim(Str(nCnt15)), 15, 1, aCNTFont, 1)
      x += 70
      GRect(x, y, x + 60, y + 24, LLG_FILL, iif(nCnt14 > 0, 2, 8), LLG_MODE_SET)
      GPrint(x + 30, y + 15, AllTrim(Str(nCnt14)), 15, 1, aCNTFont, 1)
      x += 70
      GRect(x, y, x + 60, y + 24, LLG_FILL, iif(nCnt13 > 0, 2, 8), LLG_MODE_SET)
      GPrint(x + 30, y + 15, AllTrim(Str(nCnt13)), 15, 1, aCNTFont, 1)

RETURN NIL
