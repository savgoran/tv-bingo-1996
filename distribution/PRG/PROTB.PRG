#include "sixcdx2.ch"
#include "machsix.ch"
#include "Common.ch"
#include "Inkey.ch"
#include "Setcurs.ch"
#include "Error.ch"

#define APP_MODE_ON( b )      ( b:cargo := TRUE  )
#define APP_MODE_OFF( b )     ( b:cargo := FALSE )
#define APP_MODE_ACTIVE( b )  ( b:cargo )

#define MY_HEADSEP      "мям"
#define MY_COLSEP       " Ё "

* PROCEDURA : MyBrowse(nTop, nLeft, nBottom, nRight, columns, cMyUDF, lWork, cRetUdf, lEdit, lShadow)
*
* nTop, nLeft, nBottom, nRight - koordinate prozora
*
* columns - TbColumn objekti; format { ZAGLAVLJE , IME VAR. , SELECT() , BLOCK }
*	    BLOCK - se ubacuje u POST getovane varijable
*
* cMyUdf  - Korisnicka funkcija koja se izvrsava svaki put kada se dodaje novi slog
*
* lWork   - ako je .T. moguc rad u tabeli
*	    ako je .F. samo prikaze podatke u tabeli i izadje
*
* cRetUdf - Korisnicka funkcija koja se izvrsava kada je pritisnut enter.
*	    Ako se izostavi pritiskom na enter ulazi se u editovanje
*
* lEdit   - Logicka promenljiva koja govori dali se tabela pregleda ili edituje
*	    Ako je parametar izostavljen podrazumevana vrednost je .F.
*	    Kod pregleda pre pozivanja funkcije kreirati index sa imenom CHECK po kljucnom polju
*
* aAddAct - Externe korisnicke funkcije koje se dodaju u meni AKCIJA
*	    format : { " Naziv u meniju ", {|| Udf()} }
*
* lShadow - Senka (default .F.)
*
* col_str - color string za tbrowse
*
* IdleUDF - funkcija koja se izvrsava posle pritiska bilo kog tastera
*
* aSep	  - niz koji sadrzi karaktere za separaciju (HeadSep, ColSep, FootSep)
*	    ako nisu navedeni podrazumevaje se uobicajeni (дбд,Ё,дад)

PROCEDURE MyBrowse(nTop, nLeft, nBottom, nRight, columns, cMyUDF, lWork, cRetUdf, lEdit, aAddAct, lShadow, col_str, IdleUDF, aSep)

   LOCAL oBrowse                          // The TBrowse object
   LOCAL cColorSave, nCursSave            // State preservers
   LOCAL nKey                             // Keystroke
   LOCAL lMore := TRUE                    // Loop control
   LOCAL lSavReadExit := READEXIT( .T. )  // Enable Up/Down as READ exit keys
   LOCAL cOldScreen := ""
   LOCAL cOldFuter := ""

   PRIVATE TbUDF := cMyUDF, pRetUdf := cRetUdf, pIdleUDF := IdleUDF,;
	   plEdit := lEdit, cOldFuter1 := ""

   PRIVATE cOldTag := "", cOldOrder := 0, poBrowse

   PRIVATE ActMenu := {}, MenuAkc, lCheck := .F.

   DEFAULT lWork   TO .T.
   DEFAULT plEdit  TO .F.
   DEFAULT aAddAct TO {{" Nema akcija! ", {|| dummy() }, ""}}
   DEFAULT lShadow TO .F.
   DEFAULT aSep    TO {"мям"," Ё ",""}            && дад}

   lCheck = File("check.idx")

   vstk_push()

   IF !Empty(col_str)
      SetColor(col_str)
   ELSE
      tb_color()
   ENDIF

   oBrowse := StockBrowseNew( nTop, nLeft, nBottom, nRight, columns )

   IF lShadow
      IF (nRight < 79) .OR. (nBottom < 24)
	 sha_shadow( nTop, nLeft, nBottom, nRight )
      ENDIF
   ENDIF

   poBrowse = oBrowse

   IF Len(aAddAct) > 0
      FOR i = 1 TO Len(aAddAct)
	  aadd(ActMenu,aAddAct[i])
      NEXT
      MenuAkc = {{" Akcija ", ActMenu , ""}}
   ENDIF

   IF !plEdit
      IF lCheck
	 cOldFuter = SetFuter({"SPACE - SELEKT","F4 - DESELEKT","F2 - ODABRANO","F10 - AKCIJA","ESC - IZLAZ"})
      ELSE
	 cOldFuter = SetFuter({"F10 - AKCIJA","ESC - IZLAZ"})
      ENDIF
   ELSE
      cOldFuter = SetFuter({"F10 - AKCIJA","ESC - IZLAZ"})
   ENDIF

* cOldScreen = win_save(0,0,23,79)

* FormatColumn(oBrowse)

   APP_MODE_OFF( oBrowse )

   oBrowse:skipBlock := { |x| Skipper( x, oBrowse ) }

   oBrowse:headSep := aSep[1]		  && MY_HEADSEP
   oBrowse:colSep  := aSep[2]		  && MY_COLSEP
   oBrowse:footSep := aSep[3]		  && MY_FOOTSEP

   nCursSave := setcursor( SC_NONE )

   BEGIN SEQUENCE

   IF !lWork
      oBrowse:forceStable()
      oBrowse:deHilite()
      BREAK
   ENDIF

   IF !plEdit .AND. lCheck
      oBrowse:freeze = 1
      oBrowse:colPos = 2
   ENDIF

   while lMore

      if ( oBrowse:colPos <= oBrowse:freeze )
	 oBrowse:colPos := ( oBrowse:freeze + 1 )
      endif

      oBrowse:forceStable()

      iif(!Empty(pIdleUdf),&pIdleUdf,NIL)

      if ( oBrowse:hitBottom .and. !APP_MODE_ACTIVE( oBrowse ) )
         APP_MODE_ON( oBrowse )
         nKey := K_DOWN

      else
         if ( oBrowse:hitTop .or. oBrowse:hitBottom )
            tone( 125, 0 )

         endif

         oBrowse:refreshCurrent():forceStable()

         nKey := inkey( 0 )

      endif

      if ( nKey == K_ESC )
         lMore := .F.

      else
	 applyKey( oBrowse, nKey )

      endif
   enddo

   oBrowse:deHilite()

   END SEQUENCE

   setcursor( nCursSave )
   READEXIT( lSavReadExit )

   SetFuter(cOldFuter)

   vstk_pop()

*   win_rest(cOldScreen)

RETURN

STATIC FUNCTION Skipper( nSkip, oBrowse )

   LOCAL lAppend := APP_MODE_ACTIVE( oBrowse )
   LOCAL i       := 0

   do case
   case ( nSkip == 0 .or. lastrec() == 0 )
      dbSkip( 0 )

   case ( nSkip > 0 .and. !eof() )
      while ( i < nSkip )           // Skip Foward

         dbskip( 1 )

         if eof()
	    IF plEdit
	       iif( lAppend, i++, dbskip( -1 ) )
	       IF lAppend
		  oBrowse:panHome()
	       ENDIF
	    ELSE
	       dbskip(-1)
	    ENDIF
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

STATIC PROCEDURE ApplyKey( oBrowse, nKey )
LOCAL nRec := 0

   do case
   case nKey == K_ALT_K
	calc()

   case nKey == K_DOWN
      oBrowse:down()

   case nKey == K_PGDN
      oBrowse:pageDown()

   case nKey == K_CTRL_PGDN
      oBrowse:goBottom()
      APP_MODE_OFF( oBrowse )

   case nKey == K_UP
      oBrowse:up()

      if APP_MODE_ACTIVE( oBrowse )
         APP_MODE_OFF( oBrowse )
         oBrowse:refreshAll()

      endif

   case nKey == K_PGUP
      oBrowse:pageUp()

      if APP_MODE_ACTIVE( oBrowse )
         APP_MODE_OFF( oBrowse )
         oBrowse:refreshAll()
      endif

   case nKey == K_CTRL_PGUP
      oBrowse:goTop()
      APP_MODE_OFF( oBrowse )

   case nKey == K_RIGHT
      oBrowse:right()

   case nKey == K_LEFT
      oBrowse:left()

   case nKey == K_HOME
      oBrowse:home()

   case nKey == K_END
      oBrowse:end()

   case nKey == K_CTRL_LEFT
      oBrowse:panLeft()

   case nKey == K_CTRL_RIGHT
      oBrowse:panRight()

   case nKey == K_CTRL_HOME
      oBrowse:panHome()

   case nKey == K_CTRL_END
      oBrowse:panEnd()

   case nKey == K_DEL
      IF al_box("Brisanje sloga?",2,{" DA "," NE "},2) = 1
	 DELETE
	 oBrowse:refreshAll()
	 DO WHILE oBrowse:stable
	    oBrowse:stabilize()
	 ENDDO
	 oBrowse:up()
	 IF Bof()
	    oBrowse:goTop()
	 ENDIF
      ENDIF

   case nKey == K_F2
    IF !plEdit .AND. lCheck
      IF Sx_IndexName() == "CHECK.IDX"
	Sx_SetTag(cOldTag)
	SetFuter(cOldFuter1)
        dbGoTop()
      ELSE
	IF Sx_KeyCount("CHECK") > 0
	   cOldTag = Sx_TagName()
	   SET TAG TO check
	   cOldFuter1 = SetFuter({"SPACE - SELEKT","F4 - DESELEKT","F2 - SVE","F10 - AKCIJA","ESC - IZLAZ"})
	   dbGoTop()
	ELSE
	   ErrBeep()
	   RETURN NIL
	ENDIF
      ENDIF
      oBrowse:refreshAll()
    ENDIF

   CASE nKey == K_F4
    IF !plEdit .AND. lCheck
       IF Sx_KeyCount("CHECK") > 0
	  IF Sx_IndexName() = "CHECK.IDX"
	     Sx_SetTag(cOldTag)
	     SetFuter(cOldFuter1)
	  ENDIF
	  nRec = RecNo()
	  nOldOrder = Sx_TagOrder()
	  Sx_SetTag("check")
	  DO WHILE Sx_KeyGoto(1)
	     Sx_KeyDrop()
	  ENDDO
	  Sx_SetTagOrder(nOldOrder)
	  dbGoto(nRec)
	  oBrowse:refreshAll()
       ENDIF
    ENDIF

   CASE nKey == K_F10
    IF !plEdit
       IF Len(ActMenu) > 0
	  KEYBOARD Chr(K_ENTER)
	  do_menu(MenuAkc,,1)
	  oBrowse:refreshAll()
       ENDIF
    ENDIF

   CASE nKey == K_SPACE
    IF !plEdit .AND. lCheck
      nRec = RecNo()
      IF Sx_IndexName() = "CHECK.IDX"
	 dbSkip()
	 nRec = RecNo()
	 dbSkip(-1)
	 Sx_KeyDrop()
	 dbGoTo(nRec)
	 oBrowse:refreshAll()
       ELSE
	 cOldOrder = Sx_TagOrder()
         SET TAG TO check
	 IF Sx_FindRec( nRec )
	    Sx_KeyDrop()
	    Sx_SetTagOrder(cOldOrder)
	 ELSE
	    Sx_SetTagOrder(cOldOrder)
	    dbGoto(nRec)
	    Sx_KeyAdd("CHECK")
	 ENDIF
       oBrowse:refreshCurrent()
       ENDIF
       IF Sx_IndexName() = "CHECK.IDX"
	  IF Sx_KeyCount() = 0
	     Sx_SetTagOrder(cOldOrder)
	     dbGoTop()
	     oBrowse:refreshAll()
	     SetFuter(cOldFuter1)
	  ENDIF
       ENDIF
     ENDIF

   CASE nKey == K_RETURN
      iif(!Empty(pRetUdf),&pRetUdf,DoGet( oBrowse ))

   OTHERWISE
      KEYBOARD chr( nKey )
      IF plEdit
	 DoGet( oBrowse )
      ELSE
	 Inkey()
	 ErrBeep()
      ENDIF

   ENDCASE

   RETURN

PROCEDURE doGet( oBrowse )

   LOCAL lFlag := TRUE
   LOCAL oCol
   LOCAL GetList
   LOCAL nKey
   LOCAL nLen
   LOCAL lAppend
   LOCAL bSavIns
   LOCAL nSavRecNo := recno()
   LOCAL xNewKey
   LOCAL xSavKey

   if EOF()
      lAppend := APP_MODE_ON( oBrowse )
   else
      lAppend := APP_MODE_ACTIVE( oBrowse )
   endif

   oBrowse:forceStable()

   if ( lAppend .and. ( recno() == lastrec() + 1 ) )
      dbAppend()
      iif(!Empty(TbUDF),&TbUDF,dummy())
   endif

   xSavKey := iif( empty( indexkey() ), NIL, &( indexkey() ) )

   oCol := oBrowse:getColumn( oBrowse:colPos )

   nLen := oBrowse:colWidth( oBrowse:colPos )

   GetList := { getnew( row(), col(),     ;
                        oCol:block,       ;
			,		  ;
                        oCol:picture,     ;
                        oBrowse:colorSpec ) }

   IF !Empty(oCol:cargo)

      IF oCol:cargo[1] != NIL
	 GetList[1]:preBlock  = oCol:cargo[1]
      ENDIF

      IF oCol:cargo[2] != NIL
	 GetList[1]:postBlock = oCol:cargo[2]
      ENDIF

   ENDIF

   bSavIns := setkey( K_INS, { || InsToggle() } )

   setcursor( iif( ReadInsert(), SC_INSERT, SC_NORMAL ) )
   READ
   setcursor( SC_NONE )
   setkey( K_INS, bSavIns )

   IF LastKey() == 27
      IF lAppend
	 DELETE
	 oBrowse:inValidate()
	 oBrowse:refreshAll():forceStable()
         oBrowse:up():forceStable()
      ENDIF
   ENDIF

   APP_MODE_OFF( oBrowse )

   xNewKey := if( empty( indexkey() ), NIL, &( indexkey() ) )

   oBrowse:inValidate()
   oBrowse:refreshAll():forceStable()

   if !( xNewKey == xSavKey ) .or. ( lAppend .and. xNewKey != NIL )

      oBrowse:refreshAll():forceStable()

      while &( indexkey() ) > xNewKey .and. !oBrowse:hitTop()
         oBrowse:up():forceStable()

      enddo

   endif

   nKey := lastkey()
   if nKey == K_UP   .or. nKey == K_DOWN .or. ;
      nKey == K_PGUP .or. nKey == K_PGDN

      keyboard( chr( nKey ) )

   endif

   RETURN


STATIC PROCEDURE InsToggle()

   if readinsert()
      readinsert( FALSE )
      setcursor( SC_NORMAL )

   else
      readinsert( TRUE )
      setcursor( SC_INSERT )

   endif

   RETURN

STATIC FUNCTION StockBrowseNew( nTop, nLeft, nBottom, nRight, columns )

   LOCAL oBrowse
   LOCAL n
   LOCAL oColumn
   LOCAL cType
   LOCAL dummy

   oBrowse := TBrowseDB( nTop, nLeft, nBottom, nRight )

*   IF (nRight < 79) .OR. (nBottom < 24)
*      sha_shadow( nTop, nLeft, nBottom, nRight )
*   ENDIF

   IF !plEdit .AND. lCheck
      oBrowse:AddColumn(TBColumnNew(" Ш",{|| IsCheck(oBrowse) }))
   ENDIF

   for n := 1 to Len(columns)

      dummy = columns[n,2]

      IF ValType(dummy) = "B"
	 oColumn = TBColumnNew(columns[n,1], columns[n,2])
      ELSE
	 oColumn = TBColumnNew(columns[n,1], FieldWBlock(columns[n,2], columns[n,3]))
      ENDIF

      IF columns[n,4] != NIL
	 oColumn:cargo = { columns[n,4,1], columns[n,4,2] }
      ENDIF

      oBrowse:addColumn(oColumn)

   next

   RETURN oBrowse


FUNCTION IsCheck(oBr)

LOCAL cRetVal := "  ", nOldOrder := 0, nRec := RecNo()

      IF Sx_KeyCount("CHECK.IDX") = 0
	 Return( cRetVal )
      ENDIF

      IF Sx_IndexName() = "CHECK.IDX"
	 Return( " Ш" )
      ENDIF

      nOldOrder = Sx_TagOrder()

      SET TAG TO check
      IF Sx_FindRec( nRec )
	 cRetVal := " Ш"
      ENDIF
      dbGoto(nRec)
      oBr:refreshCurrent()

      Sx_SetTagOrder(nOldOrder)

RETURN cRetVal

FUNCTION TBDel()

LOCAL nRec	:= RecNo(), ;
      cOldOrder := 0

	 IF !File("check.idx")
	    ErrBeep()
	    al_box("Nema: CHECK.IDX",1,{" OK "},1)
	    RETURN .F.
	 ENDIF

	 IF Sx_KeyCount("CHECK") = 0
	    IF al_box("Brisaje tekuceg sloga?",2,{" DA "," NE "},1) = 1
	       DELETE
	    ENDIF
	 ELSE
	    IF al_box("Brisanje odabranih slogova?",2,{" DA "," NE "},1) = 1
	       cOldOrder = Sx_TagOrder()
	       SET TAG TO CHECK
	       GO TOP
	       DO WHILE !Eof()
		  DELETE
		  SKIP
	       ENDDO
	       Sx_SetTagOrder(cOldOrder)
	       dbGoTo(nRec)
	    ENDIF
	    poBrowse:refreshAll():forceStable()
	 ENDIF

	 KEYBOARD REPLICATE(CHR(K_ESC),2)

RETURN NIL
