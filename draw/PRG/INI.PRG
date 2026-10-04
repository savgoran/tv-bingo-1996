#include "inkey.ch"
#include "fileio.ch"
#include "commands.ch"

#define CRLF	      Chr(13) + Chr(10)

FUNCTION ReadIni(cFileINI, cKey)

LOCAL nHandle := 0, ;
      cBuff   := Space(255), ;
      nPos    := 0, ;
      fsPoz   := 0, ;
      cRet    := "", ;
      cLine   := ""

      nHandle = FOpen(cFileIni)
      IF nHandle == -1
	 alert("Not INI file!", {" ok "})
	 RETURN ""
      ENDIF

      cKey = Upper(cKey)

      DO WHILE .T.

	 cBuff = Space(255)

	 IF FRead(nHandle, @cBuff, 255) == 0
	    EXIT
	 ENDIF

	 nPos = at(CRLF, cBuff)

	 cLine = SubStr(cBuff, 1, nPos-1)

	 cRet = ChkLine( cLine, cKey )
	 IF !Empty(cRet)
	    EXIT
	 ENDIF

	 fsPoz += (nPos+1)
	 FSeek(nHandle, fsPoz)

      ENDDO

      FClose(nHandle)

      IF Empty(cRet)
	 ? "Nema!"
      ENDIF

RETURN cRet

FUNCTION ChkLine(cLine1, cKey1)

LOCAL nPos := 0, ;
      cTemp := "", ;
      crKey := "", ;
      cRet  := ""

      nPos = at("=", cLine1)
      IF nPos != 0
	 crKey = AllTrim( Upper( SubStr(cLine1, 1, nPos-1) ) )
	 IF crKey == cKey1
	    cRet = AllTrim(SubStr(cLine1, nPos+1))
	 ENDIF
      ENDIF

RETURN cRet
