#include "sixcdx2.ch"
#include "machsix.ch"
#include "inkey.ch"
#include "box.ch"
#include "commands.ch"
#include "fileio.ch"
#include "set.ch"
#include "save_arr.ch"

#define BR_KOMB        3
#define BR_KOMB536     2

#define BOXTOP   8
#define BOXLEFT 10
#define TRUE  .T.
#define FALSE .F.

* fChoice(nSel,nOrd,afName,cAkt,lDod,RetVal,lFresh)
*
* Koristi:  Skipper()
*
* fChoice - tabelarno prikazuje polja (afName) iz baze (nSel) indeksirano po (nOrd)
*	    Pojavljuje se prilikom unosa podataka sa GET (nalazi se u preBlock).
*	    Unosenjem promenljive automatski se postavlja na slog u bazi koji je
*	    jednak ili veci od unetog. Ako je lDod parametar .T. pritiskom na ENTER
*	    upisuje se u bazu (nSel). (cAkt) odredjuje inicijalni slog u bazi.
*
*
* nSel	 - broj radne oblasti
* nOrd	 - broj kontrolnog indeksa
* afName - polje koje sadrzi imena polja iz baze koje treba prikazati
* nIndex - element afName[nIndex] po kome se pretrazuje (default 1)
* cAkt	 - inicijalna pozicija u bazi po indeksu
* lDod	 - ako je .T. dozvoljeno dodavanje u bazu (default .F.)
* RetVal - funkcija fChoice vraca ovu vrednost (default .F.)
* lFresh - Osvezava getovanu varijablu ako je .T. (default)

* FUNCTION fChoice(nSel,nOrd,afName,nIndex,cAkt,lDod,RetVal,lFresh)

FUNCTION fChoice(afName, GetInd, nSel, nOrd, xInitSch, lFresh, lDod, lRetVal)

LOCAL nOldSel	 := 0,	;
      nOldOrd	 := 0,	;
      cOldScreen := "", ;
      xOldIniSch := "", ;
      cOldFutter := "", ;
      nRec	 := 0 , ;
      lUpdate	 := .F.,;
      nUkupElem  := 0,	;
      nMax	 := 0,	;
      nUkupSir	 := 0,	;
      lOldGet	 := .F.,;
      nUkupSlog  := 0

LOCAL oGet := GetActive(), ;
      nGetLen := 0, ;
      t := 0, l := 0, b := 0, r := 0, ;
      tb,	     ;
      nKey := 0,     ;
      cSearch := "", ;
      cBody   := "", ;
      nVarLen := 0,  ;
      oColumn

*      DEFAULT SearchInd  TO   1
      DEFAULT GetInd	 TO   1
      DEFAULT nSel	 TO Select()
      DEFAULT nOrd	 TO IndexOrd()
      DEFAULT lFresh	 TO .T.
      DEFAULT lDod	 TO .F.
      DEFAULT lRetVal	 TO .F.

      nUkupElem = Len(afName)

      lOldGet = oGet:hasFocus

      oGet:SetFocus()
      nGetLen = Len(oGet:buffer)
      oGet:KillFocus()

      IF lFresh
	 IF lDod
	    cOldFutter = SetFuter({" - IZBOR","ENTER - POTVRDA","DEL - BRISANJE","ESC - PREKID"})
	 ELSE
	    cOldFutter = SetFuter({" - PREGLED","ESC - PREKID"})
	 ENDIF
      ELSE
	 cOldFutter = SetFuter({" - PREGLED","ESC - PREKID"})
      ENDIF

      xOldIniSch = xInitSch

      nRec = RecNo()

      nOldSel = Select()

      SELECT(nSel)

      IF nOrd != NIL
	 nOldOrd = Sx_TagOrder()
	 Sx_SetTagOrder(nOrd)
	 GO TOP
      ENDIF

      FOR i = 1 TO Len(afName)
	  cBody = afName[i]
	  IF nMax < Len(&cBody)
	     nMax = Len(&cBody)
	  ENDIF
	  nUkupSir += Len(&cBody)
      NEXT

      IF nUkupSir > 50
	 nUkupSir = 50
      ENDIF

      cBody = afName[GetInd]
      nVarLen = Len(&cBody)

      nUkupSlog := Sx_KeyCount()

      t = oGet:row+1
      l = oGet:col-1
*      b = t + iif(LastRec() < (23-t), iif(LastRec()=0,1,LastRec()) + 1, 23-t)
      b = t + iif(nUkupSlog < (23-t), iif(nUkupSlog=0,1,nUkupSlog) + 1, 23-t)
      r = l + nUkupSir + 1

      IF r > 79
	 r = 79
	 l = 79 - nUkupSir - 1
      ENDIF

      IF t > 19
	 b = oGet:row - 3
	 t = b - iif(nUkupSlog > b, b-2, nUkupSlog + 2)
      ENDIF

      vstk_push()
      cOldScreen = win_save(t, l, 24, r+1)

      SetCursor(0)

      tb = TBrowseDB(t+1, l+1, b-1, r-1)

      IF col_onoff = "C"
	 *			1     2   3   4     5
	       tb:colorSpec = "W/R,GR+/B,W+/R,N/W,GR+/R"
	       SetColor("w+/r")
      ELSEIF col_onoff = "M"
	 *			1     2   3   4     5
	       tb:colorSpec = "n/w,  w/n,n/w,N/W,  w/n"
	       SetColor("n/w")
      ENDIF


      IF nUkupElem = 1

	  tb:AddColumn(TBColumnNew("", FieldBlock(afName[1])))

      ELSE

	  tb:headSep = "�"
	  tb:colSep  = "�"

	  tb:nBottom = tb:nBottom + iif(tb:nBottom < 22, 2, 0)
	  tb:Configure()

	  FOR i = 1 TO nUkupElem

	      oColumn = TBColumnNew(afName[i], FieldBlock(afName[i]))

	      IF Len(Eval(oColumn:block)) > 30
		 oColumn:width = 30
	      ENDIF

	      oColumn:colorBlock = { || {1,2} }

	      IF i == GetInd
		 oColumn:defColor = {5,5}
	      ELSE
		 oColumn:defColor = {3,3}
	      ENDIF

	      tb:AddColumn(oColumn)

	  NEXT

      ENDIF

      @ tb:nTop-1, tb:nLeft-1, tb:nBottom+1, tb:nRight+1 BOX B_SINGLE + ' '
      sha_shadow(tb:nTop-1, tb:nLeft-1, tb:nBottom+1, tb:nRight+1)

      IF nUkupElem > 1
	 @ t, r-3 SAY ">>"
      ENDIF

* @ t,l+1 SAY Sx_IndexName()

      tb:skipBlock := { |x| Skipper (x) }

      IF xInitSch != NIL
	 SEEK xInitSch
      ELSE
	 GO TOP
      ENDIF

      DO WHILE .T.

	 tb:forceStable()

	 IF !lFresh
	    cBody = afName[GetInd]
	    FreshGet(oGet, Left(&cBody, nGetLen))
	 ELSE
	    @ oGet:row, oGet:col + Len(cSearch) SAY ""
	 ENDIF

	 IF nUkupElem > 1
	    IF tb:colPos = 1
	       @ t, r-3 SAY ">>"
	    ELSEIF tb:colPos = tb:colCount
	       @ t, r-3 SAY "<<"
	    ENDIF
	 ENDIF

	 nKey = inkey(0)

	 DO CASE

	    CASE nKey = K_DEL
		 IF lDod
		    IF al_box("Brisete slog?",2,{" DA "," NE "},2) = 1
		       DELETE
		       tb:refreshAll()
		    ENDIF
		 ENDIF

	    CASE nKey = K_ESC
		 IF lDod
		    IF lFresh
		       oGet:SetFocus()
		       oGet:buffer = xOldIniSch
		       oGet:Assign()
		       oGet:Display()
		       oGet:KillFocus()
		    ENDIF
		    lRetVal = .F.
		    EXIT
		 ELSE
		    IF lFresh
		       oGet:SetFocus()
		       IF Empty(cAkt)
			  oGet:buffer = padr(AllTrim(cSearch),nGetLen,' ')
		       ELSE
			  oGet:buffer = xOldIniSch
		       ENDIF
		       oGet:Assign()
		       oGet:Display()
		       oGet:KillFocus()
		    ENDIF
		    lRetVal = .F.
		    EXIT
		 ENDIF

	    CASE nKey = K_ENTER

		 IF lDod
		    IF Eof()
		       dbAppend()
		       cBody1 = afName[GetInd]
		       REPLACE &cBody1 WITH Left(upper(cSearch),nGetLen)
		    ENDIF
		 ENDIF

		 IF lFresh
		    oGet:SetFocus()
		    IF !lDod
		       IF lUpdate
			  oGet:buffer = padr(AllTrim(cSearch),nGetLen,' ')
		       ELSE
			  oGet:buffer = xOldIniSch
		       ENDIF
		    ELSE
		       cBody = afName[GetInd]
		       oGet:buffer = &cBody
		    ENDIF
		    oGet:Assign()
		    oGet:Display()
		    oGet:KillFocus()
		 ELSE
		    lRetVal = .F.
		 ENDIF
		 EXIT

	    CASE Chr(nKey) $ ".,-\/*()%#$!?" .OR. IsAlpha(Chr(nKey)) .OR. nKey = K_SPACE .OR. IsDigit(Chr(nKey))
		 lUpdate = .T.
		 cSearch = cSearch + Upper(Chr(nKey))
		 IF lFresh
		    oGet:SetFocus()
		    oGet:buffer = padr(cSearch,nVarLen,' ')
		    oGet:Assign()
		    oGet:Display()
		    oGet:KillFocus()
		 ENDIF

		 SEEK cSearch

		 tb:refreshAll:forceStable()

	    CASE nKey = K_BS
		 cSearch = Left(cSearch,Len(cSearch)-1)
		 IF lFresh
		    oGet:SetFocus()
		    oGet:buffer = padr(cSearch,nVarLen,' ')
		    oGet:Assign()
		    oGet:Display()
		    oGet:KillFocus()
		 ENDIF

	    CASE nKey = K_LEFT
		 IF !lFresh
		    cSearch = ""
		 ENDIF
		 tb:left()

	    CASE nKey = K_RIGHT
		 IF !lFresh
		    cSearch = ""
		 ENDIF
		 tb:right()

	    CASE nKey = K_DOWN
		 IF !lFresh
		    cSearch = ""
		 ENDIF
		 tb:down()

	    CASE nKey = K_UP
		 IF !lFresh
		    cSearch = ""
		 ENDIF
		 tb:up()

	    CASE nKey = K_PGUP
		 IF !lFresh
		    cSearch = ""
		 ENDIF
		 tb:PageUp()

	    CASE nKey = K_PGDN
		 IF !lFresh
		    cSearch = ""
		 ENDIF
		 tb:PageDown()

	    CASE nKey = K_CTRL_PGDN
		 IF !lFresh
		    cSearch = ""
		 ENDIF
		 tb:goBottom()

	    CASE nKey = K_CTRL_PGUP
		 IF !lFresh
		    cSearch = ""
		 ENDIF
		 tb:goTop()

	 END CASE

      ENDDO

      win_rest(cOldScreen)
      vstk_pop()

      SetFuter(cOldFutter)

      IF nOrd != NIL
	 Sx_SetTagOrder(nOldOrd)
      ENDIF

      Select(nOldSel)

      GO nRec

      IF lOldGet
	 oGet:SetFocus()
      ENDIF

/*
      IF lRetVal
	 KEYBOARD Chr(K_ENTER)
      ENDIF
*/

RETURN lRetVal

FUNCTION FreshGet(oGet, xVal)

	 oGet:SetFocus()
	 oGet:buffer = Transform(xVal, oGet:picture)
	 oGet:Assign()
	 oGet:Display()
	 oGet:KillFocus()

RETURN NIL

STATIC FUNCTION Skipper( nSkip )

   LOCAL i       := 0

   do case
   case ( nSkip == 0 .or. lastrec() == 0 )
      dbSkip( 0 )

   case ( nSkip > 0 .and. !eof() )
      while ( i < nSkip )           // Skip Foward

         dbskip( 1 )

         if eof()
	    dbskip( -1 )
            exit

         endif

         i++

      enddo

   case ( nSkip < 0 )
      while ( i > nSkip )           // Skip backward

         dbskip( -1 )

         if bof()
            exit

         endif

         i--

      enddo

   endcase

   RETURN i

* FUNKCIJA......: Choice(aNiz, duzina, bSort)
*
* Opis..........: Prikazuje tabelarno elemente prosledjenog niza (preko reference)
*		  i omogucava izbor.
*		  Vraca vrednost na sledeci nacin: Left(odabran_element, duzina)
*		  i osvezava GET
* bSort 	: blok za sortiranje (exm. { |x,y| x > y })

FUNCTION Choice(aNiz, duzina, bSort)

LOCAL oGet := GetActive(), ;
      t := 0, l := 0, b := 0, r := 0, ;
      nChoice	 := 0	, ;
      cOldScreen := ""  , ;
      cOldColor  := ""  , ;
      nIniPos	 := 0	, ;
      cOldFutter := ""  , ;
      nKey	 := 0	, ;
      aGL	 := {}	, ;
      cOldScr	 := ""  , ;
      nWinLen	 := 0	, ;
      RetVal	 := .F. , ;
      najduzi	 := 0	, ;
      cBuff	 := ""  , ;
      lOldFocus  := .F. , ;
      lUpdate	 := .F.

PRIVATE p

      lOldFocus = oGet:hasFocus

      oGet:SetFocus()

      cBuff = oGet:buffer

      oGet:KillFocus()

      DEFAULT duzina TO Len(cBuff)

      cOldFutter = SetFuter({" - IZBOR","ENTER - POTVRDA","F5 - DODAVANJE","F6 - BRISANJE","PREKID - ESC"})

      FOR i = 1 TO Len(aNiz)
	  IF najduzi < Len(aNiz[i])
	     najduzi = Len(aNiz[i])
	  ENDIF
      NEXT

      t = oGet:row+1
      l = oGet:col-1
      b = t + iif(Len(aNiz) < (23-Row()), Len(aNiz) + 1, 23-t)
      r = l + najduzi + 1

      IF r > 79
	 r = 79
	 l = 79 - najduzi - 1
      ENDIF

*      IF Len(aNiz) > 4
	 IF (b - t) < 4
	    b = oGet:row - 1
	    t = b - iif(Len(aNiz) > b, b-1, Len(aNiz))
	 ENDIF
*      ENDIF

      vstk_push()
      cOldScreen = win_save(t, l, b+1, r+1)

      SetColor(Col_FCh)

      @ t, l, b, r BOX B_SINGLE + ' '
*      sha_shadow(t,l,b,r)

      nIniPos = Ascan(aNiz, { |x| Left(x, duzina) = cBuff })

      DO WHILE .T.

	 nChoice = Achoice(t+1, l+1, b-1, r-1, aNiz,,"achUDF",nIniPos)

	 nKey = LastKey()
	 DO CASE

	    CASE nKey = K_F6
		 IF Len(aNiz) > 0
		    err_beep()
		    IF al_box("Brisete slog " + aNiz[nChoice] + " ?",1,{" DA "," NE "},2) = 1
		       lUpdate = .T.
		       nIniPos = nChoice
		       aDel(aNiz,nChoice)
		       aSize(aNiz,Len(aNiz)-1)
		       * FArrSave()
		       IF Len(aNiz) = 0
			  EXIT
		       ENDIF
		    ELSE
		       nIniPos = nChoice
		    ENDIF
		 ENDIF

            CASE nKey = K_ENTER    &&  Izvrsi selekciju
		 EXIT

	    CASE nKey = K_F5	   && dodavanje novog sloga u listu

		 vstk_push()
		 cOldScr = win_save(0,0,24,79)

		 nWinLen = iif(len(aNiz[1]) + 4 < 30, 30, len(aNiz[1]) + 4)

		 WinStyle(9,40-int(nWinLen/2), 15, 40 + int(nWinLen/2),"UNOS",iif(col_onoff = "C","b/w,w+/b","n/w,w/n"))

		 @ 11, 33 SAY "Unesi novi slog:"

		 p = space(len(aNiz[1]))

		 aadd(aGL,GetNew(13,40 - int(nWinLen/2) + 2, MemVarBlock("p"),,"@!"))
		 aGL[1]:postBlock = {|| !Empty(p)}

		 KEYBOARD Chr(K_BS)

		 SetCursor(1)
		 ReadModal(aGL)

		 aGL := {}

		 IF LastKey() != K_ESC
		    lUpdate = .T.
		    aadd(aNiz,p)
		    IF ValType(bSort) = "B"
		       ASort(aNiz,,, bSort)
		       nIniPos = AScan(aNiz, p)
		    ELSE
		       nIniPos = Len(aNiz)
		    ENDIF
		    * FArrSave()
		 ENDIF

		 win_rest(cOldScr)
		 vstk_pop()

            CASE nKey = K_ESC
		 RetVal = .T.
		 EXIT
		 * KEYBOARD Chr(K_ESC)

	 ENDCASE

      ENDDO

      win_rest(cOldScreen)
      vstk_pop()

      IF LastKey() != K_ESC .AND. nChoice != 0
	 oGet:SetFocus()
	 oGet:buffer = padr( Left(aNiz[nChoice], duzina), Len(oGet:buffer), ' ')
	 oGet:Assign()
	 oGet:Display()
	 oGet:KillFocus()
      ENDIF

      IF lUpdate
	 FArrSave()
      ENDIF

      SetFuter(cOldFutter)

      IF lOldFocus
	 oGet:SetFocus()
      ENDIF

RETURN RetVal

FUNCTION Choice1(aNiz)

LOCAL oGet := GetActive(), ;
      t := 0, l := 0, b := 0, r := 0, ;
      nChoice	 := 0	, ;
      cOldScreen := ""  , ;
      cOldColor  := ""  , ;
      nIniPos	 := 0	, ;
      cOldFutter := ""  , ;
      nKey	 := 0	, ;
      aGL	 := {}	, ;
      cOldScr	 := ""  , ;
      nWinLen	 := 0	, ;
      RetVal	 := .F. , ;
      najduzi	 := 0

PRIVATE p

      cOldFutter = SetFuter({" - IZBOR","ENTER - POTVRDA","F5 - DODAVANJE","F6 - BRISANJE","PREKID - ESC"})

*****************

      FOR i = 1 TO Len(aNiz)
	  IF najduzi < Len(aNiz[i])
	     najduzi = Len(aNiz[i])
	  ENDIF
      NEXT

      t = oGet:row+1
      l = oGet:col-1
      b = t + iif(Len(aNiz) < (24-Row()), Len(aNiz) + 1, 24-t)
      r = l + najduzi + 1

      IF r > 79
	 r = 79
	 l = 79 - najduzi - 1
      ENDIF

      IF Len(aNiz) > 4
	 IF (b - t) < 4
	    b = oGet:row - 1
	    t = b - iif(Len(aNiz) > b, b-1, Len(aNiz))
	 ENDIF
      ENDIF

*****************

      vstk_push()
      cOldScreen = win_save(t, l, b+1, r+1)

      SetColor(Col_FCh)

      @ t, l, b, r BOX B_SINGLE + ' '
      sha_shadow(t,l,b,r)

      nIniPos = Ascan(aNiz,oGet:buffer)

      DO WHILE .T.

	 nChoice = Achoice(t+1, l+1, b-1, r-1, aNiz,,"achUDF",nIniPos)

	 nKey = LastKey()
	 DO CASE

	    CASE nKey = K_F6
		 IF Len(aNiz) > 0
		    err_beep()
		    IF al_box("Brisete slog " + aNiz[nChoice] + " ?",1,{" DA "," NE "},2) = 1
		       nIniPos = 1
		       aDel(aNiz,nChoice)
		       aSize(aNiz,Len(aNiz)-1)
		       FArrSave()
		       IF Len(aNiz) = 0
			  EXIT
		       ENDIF
		    ELSE
		       nIniPos = nChoice
		    ENDIF
		 ENDIF

            CASE nKey = K_ENTER    &&  Izvrsi selekciju
		 EXIT

	    CASE nKey = K_F5	   && dodavanje novog sloga u listu

		 vstk_push()
		 cOldScr = win_save(0,0,24,79)

		 nWinLen = iif(len(aNiz[1]) + 4 < 30, 30, len(aNiz[1]) + 4)

		 WinStyle(9,40-int(nWinLen/2), 15, 40 + int(nWinLen/2),"UNOS",iif(col_onoff = "C","b/w,w+/b","n/w,w/n"))

		 @ 11, 33 SAY "Unesi novi slog:"

		 p = space(len(aNiz[1]))

		 aadd(aGL,GetNew(13,40 - int(nWinLen/2) + 2, MemVarBlock("p"),,"@!"))
		 aGL[1]:postBlock = {|| !Empty(p)}

		 KEYBOARD Chr(K_BS)

		 SetCursor(1)
		 ReadModal(aGL)

		 aGL := {}

		 IF LastKey() != K_ESC
		    aadd(aNiz,p)
		    nIniPos = Len(aNiz)
		    FArrSave()
		 ENDIF

		 win_rest(cOldScr)
		 vstk_pop()

            CASE nKey = K_ESC
		 EXIT
		 KEYBOARD Chr(K_ESC)
		 RetVal = .T.

	 ENDCASE

      ENDDO

      IF LastKey() != K_ESC .AND. nChoice != 0
	 oGet:buffer = padr(aNiz[nChoice],Len(oGet:buffer),' ')
	 oGet:Assign()
	 oGet:Display()
      ENDIF

      win_rest(cOldScreen)
      vstk_pop()

      SetFuter(cOldFutter)

RETURN RetVal

FUNCTION Choice2(aNiz, ll, duzina)
RETURN

/*

LOCAL oGet, t := 0, l := 0, b := 0, r := 0, nChoice := 0, ;
      cOldScreen := "", cOldColor := "", nIniPos := 0, cOldFutter, ;
      lOldSet := .F., najduzi := 0, i := 0

      DEFAULT ll     TO .F.
      DEFAULT duzina TO 2

      lOldSet = Set(_SET_EXACT, .T.)

      cOldFutter = SetFuter({"IZBOR - ","POTVRDA - ENTER","PREKID - ESC"})

      oGet = GetActive()

      FOR i = 1 TO Len(aNiz)
	  IF najduzi < Len(aNiz[i])
	     najduzi = Len(aNiz[i])
	  ENDIF
      NEXT

      t = oGet:row+1
      l = oGet:col-1
      b = t + iif(Len(aNiz) < (24-Row()), Len(aNiz) + 1, 24-t)
      r = l + najduzi + 1

      IF r > 79
	 r = 79
	 l = 79 - najduzi - 1
      ENDIF

      IF Len(aNiz) > 4
	 IF (b - t) < 4
	    b = oGet:row - 1
	    t = b - iif(Len(aNiz) > b, b-1, Len(aNiz))
	 ENDIF
      ENDIF

      cOldScreen = win_save(t, l, b+1, r+1)

      cOldColor = SetColor(Col_Ach)

      @ t, l, b, r BOX B_SINGLE + ' '
      sha_shadow(t,l,b,r)

*      oGet:SetFocus()
      nIniPos = Ascan(aNiz ,{ |x|  padr(Left(x,duzina),duzina,' ') == oGet:buffer })
*      oGet:KillFocus()

      IF nIniPos > Len(aNiz)
	 nIniPos = 1
      ENDIF

      nChoice = Achoice(t+1, l+1, b-1, r-1, aNiz,,,nIniPos)
      SetColor(cOldColor)

      IF LastKey() != K_ESC .AND. nChoice != 0
	 oGet:SetFocus()
	 oGet:buffer = Left(aNiz[nChoice],duzina)
	 oGet:Assign()
	 oGet:Display()
	 oGet:KillFocus()
      ENDIF

      win_rest(cOldScreen)

      SetFuter(cOldFutter)

      Set(_SET_EXACT, lOldSet)

RETURN ll
*/

FUNCTION AchUDF(mode,curr_elem,rel_elem)

LOCAL RetVal := 2, ;
      nKey   := LastKey()

      DO CASE

	 CASE mode = 3

	      DO CASE

		 CASE nKey = K_F6
		      RetVal = 1

                 CASE nKey = 13
		      RetVal = 1

                 CASE nKey = 27
		      RetVal = 0

		 CASE nKey = K_F5
		      RetVal = 0
		      KEYBOARD Chr(K_F5)

		 OTHERWISE
		      RetVal = 3

	      ENDCASE

      ENDCASE

RETURN RetVal


FUNCTION IndexBar()

STATIC aScrn, cSaveColor, nLast

LOCAL nRecs := Sx_KeysIncluded() , cStd := "GR+/B", color := col_split(Col_Win)

// BOF() is TRUE on first call to OPTION UDF.  Use this for setup.
IF Bof()
  nLast := LastRec()
  cSaveColor := SetColor( "GR+/B,R+/W" )
  aScrn := { BOXTOP, BOXLEFT, BOXTOP + 11, BOXLEFT + 60 ,;
	    savescreen( BOXTOP-1, BOXLEFT, BOXTOP + 12, BOXLEFT + 61 ) }

  * DispBox( BOXTOP, BOXLEFT, BOXTOP + 11, BOXLEFT + 60 , 2 )

  WinStyle(BOXTOP-1, BOXLEFT, BOXTOP + 11, BOXLEFT + 60,"INDEX")

  color = col_split()
  SetColor(color[1])

  Scroll( BOXTOP + 1, BOXLEFT + 1, BOXTOP + 10, BOXLEFT + 59 )
  SetPos( BOXTOP + 2, BOXLEFT + 5)
  DevOut( "Kreiranje indeksa   :               ")
  SetPos( BOXTOP + 3, BOXLEFT + 5)
  DevOut( "Ime taga            :               ")
  SetPos( BOXTOP + 4, BOXLEFT + 5)
  DevOut( "Ukupno slogova      :               ")
  SetPos( BOXTOP + 5, BOXLEFT + 5)
  DevOut( "Tekuci slog         :               ")
  SetPos( BOXTOP + 6, BOXLEFT + 5)
  DevOut( "Procenata zavrseno  :               ")
  SetPos( BOXTOP + 8, BOXLEFT + 5)
  DevOut( "0% 컴컴컴컴컴컴컴컴컴� 50% 컴컴컴컴컴컴컴컴컴 100%")

  // Clear the area, create the guage
  Scroll(BOXTOP + 2, BOXLEFT  + 27, BOXTOP + 11 - 5, BOXLEFT + 60 - 1, 0 )
  SetPos( BOXTOP + 2, BOXLEFT  + 28)
  DevOut( Sx_I_IndexName(), color[2])
  SetPos( BOXTOP + 3, BOXLEFT  + 28)
  DevOut( Sx_I_TagName(), color[2]  )
  SetPos( BOXTOP + 4, BOXLEFT  + 28)
  DevOut( LTrim( Transform( nLast,"999,999,999")), color[2] )
  aReplicate( BOXTOP + 9, BOXLEFT + 5, chr(219), 50, "N/N" )

ELSEIF Eof()
  SetColor( cSaveColor )
  restscreen(BOXTOP-1, BOXLEFT, BOXTOP + 12, BOXLEFT + 61,aScrn[5])

ELSE
  // Show how many keys have been included so far
  SetPos( BOXTOP + 5, BOXLEFT + 28)
  DevOut( LTrim( Transform( nRecs ,  "999,999,999")), color[2] )
  SetPos( BOXTOP + 6, BOXLEFT + 28)
  DevOut( LTrim( Transform( ( nRecs / nLast) * 100 ,  "999")), color[2] )

  // Show how far we have got
  aReplicate( BOXTOP + 9, BOXLEFT + 5, chr(219),;
              int(( nRecs / nLast) * 50 ), "GR+/W" )
ENDIF

Return(TRUE)

FUNC aReplicate( nR, nC, cSt, nLen, cColor )

     SetPos( nR, nC )
     DevOut( Replicate( cSt, nLen ), cColor )

RETURN NIL

* FUNKCIJA............: save_array(the_array, file_name)
*                       rest_array(file_name)
*
* Snimanje indeksiranih promenljiva na disk
*
FUNCTION save_array(the_array, file_name)

PRIVATE f_handle

    f_handle = fCreate(file_name)
    save_arr(the_array)
    fClose(f_handle)

RETURN NIL

FUNCTION rest_array(file_name)

LOCAL rest_array

PRIVATE f_handle, the_array

    f_handle = fOpen(file_name)
    GET_TYPE()
    rest_array = rest_arr()
    fClose(f_handle)

RETURN rest_array

FUNCTION save_arr(the_array)

LOCAL len_array, elem_type, i

      WRITE_AHD(the_array)
      len_array = len(the_array)
      FOR i = 1 to len_array

	  elem_type = valtype(the_array[i])

	  DO CASE

	     CASE elem_type = "A"
		  SAVE_ARR(the_array[i])

	     CASE elem_type = "C"
		  SAVE_CHAR(the_array[i])

	     CASE elem_type = "D"
		  SAVE_DATE(the_array[i])

	     CASE elem_type = "L"
		  SAVE_LOG(the_array[i])

	     CASE elem_type = "N"
		  SAVE_NUM(the_array[i])

	  ENDCASE

      NEXT

RETURN NIL

FUNCTION rest_arr()

LOCAL len_array, elem_type, the_array, i

    * Odred`ivanje velic~ine i deklarisanje indeksirane promenljive
    len_array = GET_AR_SIZE()
    the_array = array(len_array)

    * Rekonstruisanje svakog elementa
    FOR i = 1 TO len_array
        * Odred`ivanje njegovog tipa
        elem_type = GET_TYPE()
        DO CASE
            CASE elem_type = "A"
                * Umetnuta indeksirana promenljiva, rekurzivno ...
		the_array[i] = rest_arr()

            CASE elem_type = "B"
                * Fatalna gres`ka - nismo upisali element tog tipa
                ? "GRES`KA: NISMO UPISALI BLOK KODA"
                inkey(0)

            CASE elem_type = "C"
                the_array[i] = GET_CHAR()

            CASE elem_type = "D"
                the_array[i] = GET_DATE()

            CASE elem_type = "L"
                the_array[i] = GET_LOG()

            CASE elem_type = "N"
                the_array[i] = GET_NUM()
        ENDCASE
    NEXT

RETURN the_array
* ************************************************************

FUNCTION FArrSave()

PRIVATE f_handle

	f_handle = fCreate("choice.arr")

	save_arr(aSpec)
	save_arr(aLek)

	fClose(f_handle)

RETURN NIL

FUNCTION FArrRest()

PRIVATE f_handle

	f_handle = fOpen("choice.arr", 0)

	GET_TYPE()
	aSpec = rest_arr()
	GET_TYPE()
	aLek  = rest_arr()

	fClose(f_handle)

RETURN NIL

FUNCTION SArrSave()

PRIVATE f_handle

	f_handle = fCreate("sernum.dat")

	save_arr(rlData)

	fClose(f_handle)

RETURN NIL

FUNCTION SArrRest()

PRIVATE f_handle

	f_handle = fOpen("sernum.dat", 0)

	GET_TYPE()
	rlData = rest_arr()

	fClose(f_handle)

RETURN NIL

FUNCTION ConvOldData()

	 USE InsDesc1 NEW VIA "SIXCDX"
	 GO TOP

	 DO WHILE !Eof()

	    IF Left(kljuc,1) = "2"
	       REPLACE kljuc WITH "4" + SubStr(kljuc,2)
	    ENDIF

	    SKIP

	 ENDDO

	 CLOSE ALL

RETURN NIL

FUNCTION TimeToMin(cTime)
RETURN (Val(cTime)*60+Val(SubStr(cTime,at(":",cTime)+1)))

FUNCTION MinToTime(nMin)

LOCAL cHour := Space(1), ;
      cMin  := Space(2)

	 IF (nMin/60) > 1
	    cHour = "0"
	    cMin  = FMT0L(Str(nMin,2),2)
	 ELSE
	    cHour = AllTrim(Str(Int(nMin/60)))
	    cMin  = Str(nMin % 60,2)
	 ENDIF

RETURN cHour + ":" + FMT0L(cMin,2)

FUNCTION NetUse(cDbf, cPass)

LOCAL lRetVal := .T.

      DEFAULT cPass TO ""

      USE (cDbf) NEW VIA "SIXCDX" SHARED

      IF !Empty(cPass)
	 Sx_SetPass( cPass )
      ENDIF

      IF NetErr()
	 al_box("Greska u otvaranju deljene baze " + AllTrim(cDbf) + "!", 1, {" OK "}, 1, 9, 20, 16, 60)
	 lRetVal = .F.
      ENDIF

RETURN lRetVal

FUNCTION Set536( nRBK, nBrKomb )

LOCAL nRealRBK := 0, ;
      nLogRBK  := 0, ;
      nRet     := 0

      DEFAULT nBrKomb TO 1

      nRealRBK := Int( ( nRBK - 1 ) / BR_KOMB ) + 1
      nLogRBK  := ( ( nRealRBK - 1 ) * BR_KOMB536 ) + 1

      nRet := Int(nLogRBK % 376802)
      if nRet = 0
	 nRet = 1
      endif

RETURN nRet
