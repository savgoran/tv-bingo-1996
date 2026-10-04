#include "llibg.ch"
#include "inkey.ch"
#include "commands.ch"
#include "fileio.ch"

#define BR_KOMB       3

FUNCTION BlockNum(poc_x, poc_y, nHow, aBlkFont, cIniTxt, nWidith, nHeight, nTick, nBkColor, nFgColor)

LOCAL i    := 0, ;
      aRet := {}, ;
      aTemp := {}

      DEFAULT nWidith	TO 50
      DEFAULT nHeight	TO 60
      DEFAULT nTick	TO  5
      DEFAULT nFgColor	TO  9
      DEFAULT nBkColor	TO  7
      DEFAULT cIniTxt	TO ""

      aTemp = Array(nHow)
      aTemp = AFill(aTemp, 0)

      aadd(aRet, {poc_x, poc_y, nHow, nWidith, nHeight, nTick, aBlkFont, nBkColor, nFgColor})
      aadd(aRet, aTemp)

      * pocx = 175
      * pocy = 400

      FOR i = 1 TO nHow
	  GFrame(poc_x, poc_y, poc_x + nWidith, poc_y + nHeight, nBkColor, 15, 8, 3, 3, 3, 3, LLG_MODE_SET)
	  * GRect(poc_x, poc_y, poc_x + nWidith, poc_y + nHeight, LLG_FILL, nBkColor, LLG_MODE_SET)
	  * GRect(poc_x, poc_y, poc_x + nWidith, poc_y + nHeight, LLG_FRAME, 0, LLG_MODE_SET)
	  poc_x += (nWidith + nTick)
      NEXT i

      WriteNum(aRet, cIniTxt)

RETURN aRet

FUNCTION WriteNum(aHandle, cNum)

LOCAL i := 0, ;
      cStr := ""

      cStr = padl(AllTrim(cNum), aHandle[1,3], "*")

      FOR i = 1 TO aHandle[1,3]
	  Write1Num(aHandle, SubStr(cStr,i,1), i)
      NEXT

RETURN NIL

FUNCTION Write1Num(aHandle, cNum, nPos)

LOCAL x := 0, ;
      y := 0, ;
      xFont := 0

      IF aHandle[1,7][LLG_FNT_SIZE] == 43
	 xFont = 10
      ELSE
	 xFont =  5
      ENDIF

      x = (aHandle[1,1] + ((aHandle[1,4] + aHandle[1,6]) * (nPos-1))) + xFont
      y = aHandle[1,2]

      IF aHandle[1,7][LLG_FNT_SIZE] < 43
	 --x
	 y -= 2
      ENDIF

      GWriteAT(x, y, aHandle[2,nPos], aHandle[1,8], LLG_MODE_SET, aHandle[1,7])
      GWriteAT(x, y, cNum, aHandle[1,9], LLG_MODE_SET, aHandle[1,7])

      aHandle[2,nPos] = cNum

RETURN NIL

FUNCTION ShowSmall(nPos, cSer, cBr)

LOCAL y := 0

      y = 130 + ((nPos - 1) * 35)

      BlockNum(350, y, 3, 25, 30, 2, aFont1, cSer)
      BlockNum(436, y, 7, 25, 30, 2, aFont1, cBr)

RETURN NIL

FUNCTION ConvRBK( nRBK )
RETURN Int( ( nRBK - 1 ) / BR_KOMB ) + 1

FUNCTION Perc(nSum, nPerc)
RETURN (nSum / 100) * nPerc

FUNCTION TokCmd( cCmd )

 Local aRet := {}

   TokenInit( @cCmd, Chr(32) + "," )

   while !TokenEnd()
      aadd( aRet, AllTrim( TokenNext( cCmd ) ) )
   end

RETURN aRet

// funkcija koja snima svaki uneti broj
FUNCTION WriteEmg(aNums)

 Local nHandle, ;
       i := 0

    IF !File("emg.mem")
       nHandle := FCreate("emg.mem", FC_NORMAL)
       FClose(nHandle)
    ENDIF

    nHandle := FOpen("emg.mem", FO_WRITE)

    IF nHandle != -1
       FSeek(nHandle, 0, 0)
       FOR i := 1 TO Len(aNums)
	   FWrite(nHandle, aNums[i], 2)
       NEXT
       FClose(nHandle)
    ENDIF

RETURN NIL

FUNCTION ReadEmg()

 Local nHandle,;
       cBuff := Space(2), ;
       aTemp := {}

    nHandle := FOpen("emg.mem", FO_READ)
    IF nHandle != -1
       FSeek(nHandle, 0, 0)
       WHILE .t.
	 IF FRead(nHandle, @cBuff, 2) == 0
	    EXIT
	 ENDIF
	 aadd(aTemp, cBuff)
       ENDDO
       FClose(nHandle)
    ENDIF

RETURN aTemp

FUNCTION CalcEuro(nDem)
RETURN Round(nDem / 1.95583, 2)
