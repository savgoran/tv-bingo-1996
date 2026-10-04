#define LEN_KOMB	16

FUNCTION Lis2Emm()

PRIVATE nFileHandle := 0, ;
	nEmmAvlPg   := 0, ;
	nTckTotPage := 0, ;
	nUkL	:= 0, ;
	cHeader := Space(30)

	nFileHandle = FOpen("cnlist.dat")

	GetHeader()

	nPageFrame = EmmPgFrm()
	nEmmAvlPg  = EmmAvlPg()

	IF !CheckEMM()
	   RETURN NIL
	ENDIF

	nEmmHandle = EmmAlloc(nTckTotPage)

	LoadTckEmm()

	FClose(nFileHandle)

RETURN NIL

FUNCTION CheckEMM()

	nUkL	= (FSeek(nFileHandle,0,2) - 23) / LEN_KOMB
	++nUkL
	nTckTotPage = Int(( (FSeek(nFileHandle,0,2) + LEN_KOMB) - 23 ) / 16384) + 1

	IF nTckTotPage > nEmmAvlPg
	   alert("Nedovoljno EMM!",{" OK "})
	   RETURN .F.
	ENDIF

RETURN .T.

FUNCTION LoadTCKEmm()

LOCAL nListLen := 0, ;
      nTrans   := 0, ;
      currpage := 0

      nListLen = (nUkL-1) * LEN_KOMB

      FSeek(nFileHandle, 23, 0)

      DO WHILE nListLen > 0

	 IF nListLen >= 16384
	    nTrans = 16384
	 ELSE
	    nTrans = nListLen
	 ENDIF

	 nn = f2emm(nFileHandle, nEmmHandle, nPageFrame, currpage, nTrans)
	 IF nn < nTrans
	    CLS
	    ? "Greska u citanju fajla!"
	    ? Str(nTrans,7) + " - " + Str(nn,7)
	    QUIT
	 ENDIF

	 nListLen -= nTrans

	 ++currpage

      ENDDO

      ccc = Replicate(Chr(254), LEN_KOMB)
      MemToEmm(ccc, nPageFrame, nTrans + 1, LEN_KOMB)

RETURN .T.

STATIC FUNCTION GetHeader()

LOCAL cTemp := Space(23)

      FRead(nFileHandle, @cTemp, 23)

      cKolo    := SubStr(cTemp, 1 ,7)
      nPocSer  := Bin2L(SubStr(cTemp,  8 ,4)) - 1
      * nUkupLis := Bin2L(SubStr(cTemp, 12 ,4))
      nFond    := Bin2L( SubStr(cTemp, 12 ,4) ) / 100

      cFileRes = "rez" + AllTrim(cKolo) + ".dat"

RETURN NIL

FUNCTION MakeRez()

LOCAL nHandle := 0, ;
      i       := 0

      nHandle = FCreate(cFileRes)

      FWrite(nHandle, FMT0L( AllTrim(cKolo), 4 ) )

      FOR i = 1 TO Len(aBroj)
	  FWrite(nHandle, aBroj[i], 2)
      NEXT

      FClose(nHandle)

RETURN NIL

FUNCTION EmmInfo()

	 ? "EMM present     : " + iif(EmmPresent(),"DA","NE")
	 ? "Ukupno strana   : " + Str(EmmTotPg(),5) + " = " + Str(EmmTotPg()*16,7)
	 ? "Zauzeto strana  : " + Str(EmmUsPg(),5)  + " = " + Str(EmmUsPg()*16,7)
	 ? "Slobodno strana : " + Str(EmmAvlPg(),5) + " = " + Str(EmmAvlPg()*16,7)
	 ? "Page frame      : " + Str(EmmPgFrm(),5)

RETURN NIL
