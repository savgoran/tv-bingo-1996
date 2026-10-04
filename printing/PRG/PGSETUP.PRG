#include "sixcdx2.ch"
#include "machsix.ch"
#include "inkey.ch"
#include "box.ch"
#include "commands.ch"

FUNCTION PSetup()

LOCAL cOldScreen := "", ;
      cc	 := "", ;
      cFilePGSET := AllTrim(Group->path) + "\pgset.cfg", ;
      cFN	 := Space(12), ;
      aFN	 := {}, ;
      aTemp	 := {}, ;
      nRet	 := 0, ;
      nSel	 := 0

PRIVATE t_tab_x   := 428,  ;
	t_tab_y   := 218,  ;
	t_ser_x   := 190,  ;
	t_ser_y   := 300,  ;
	t_rbk_x   := 177,  ;
	t_rbk_y   := 364,  ;
	t_kb_x	  := 500,  ;
	t_kb_y	  := 170,  ;
	t_536_x   := 177,  ;
	t_536_y   := 420,  ;
	t_5361_x  := 247,  ;
	t_5361_y  := 420,  ;
	t_hor	  := 1163, ;
	t_ver	  := 842,  ;
	t_bar_x   := 800,  ;
	t_bar_y   := 170,  ;
	t_red	  := 60,   ;
	t_red5	  := 40,   ;
	t_hor_d_1 := 72,   ;
	t_hor_d_2 := 83,   ;
	t_br_lis  := 8,    ;
	t_br_komb := 3,    ;
	t_vis_komb:= 200,  ;
	t_raz_komb:= 0,    ;
	t_fnt_komb:= "HLYUH12B", ;
	t_fnt_ser := "TMSYT10B", ;
	t_fnt_kolo:= "HLYUH08N", ;
	t_fnt_536 := "HLYUH10B"

      cFN = GetPGS()

      IF !Empty(cFN)
	 IF File(AllTrim(Group->path) + "\" + cFN)
	    RESTORE FROM ( AllTrim(Group->path) + "\" + cFN ) ADDITIVE
	 ENDIF
      ELSE
	 cFn = "pgset.pgs"
	 cc = AllTrim(Group->path) + "\PGSET.PGS"
	 SAVE ALL LIKE t_* TO (cc)
      ENDIF

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(3,15,22,67,"PODESAVANJE STRANE " + cFN)

      vstk_push()

      @ 15,15 TO 15,67
      @ 15,41 SAY "Â"

      @  4,30 SAY "Hor    Ver   Razmak izmedju redova:"

      SetColor("w/n")
      @ 12,15 CLEAR TO 12,67
      @ 16,15 CLEAR TO 16,67
      @ 12,17 SAY "Dimenzije listica         Razmak izmedju brojeva"
      @ 16,17 SAY "SPECIJALNE OPCIJE       ³ FONT"
      vstk_pop()

      @ 17,41 SAY "³"
      @ 18,41 SAY "³"
      @ 19,41 SAY "³"
      @ 20,41 SAY "³"
      @ 21,41 SAY "³"

      @  5,17 SAY "Tabela:    " GET t_tab_x PICTURE "9999"
      @  5,Col()+3 GET t_tab_y PICTURE "9999"
      @  6,17 SAY "Serija:    " GET t_ser_x PICTURE "9999"
      @  6,Col()+3 GET t_ser_y PICTURE "9999"
      @  7,17 SAY "RBK:       " GET t_rbk_x PICTURE "9999"
      @  7,Col()+3 GET t_rbk_y PICTURE "9999"
      @  8,17 SAY "Kon.br.:   " GET t_kb_x PICTURE "9999"
      @  8,Col()+3 GET t_kb_y PICTURE "9999"
      @  9,17 SAY "5/36 (1):  " GET t_536_x PICTURE "9999"
      @  9,Col()+3 GET t_536_y PICTURE "9999"
      @ 10,17 SAY "5/36 (2):  " GET t_5361_x PICTURE "9999"
      @ 10,Col()+3 GET t_5361_y PICTURE "9999"
      @ 11,17 SAY "Bar code:  " GET t_bar_x PICTURE "9999"
      @ 11,Col()+3 GET t_bar_y PICTURE "9999"

      @ 13,17 SAY "Sirina       :    " GET t_hor PICTURE "9999"
      @ 14,17 SAY "Visina       :    " GET t_ver PICTURE "9999"

      @  6,43 SAY "Vertikalni   :    " GET t_red  PICTURE "9999"
      @  7,43 SAY "Horiz. 5/36  :    " GET t_red5  PICTURE "9999"

      @ 13,43 SAY "Prvi:"   GET t_hor_d_1 PICTURE "9999"
      @ 13,54 SAY "Ostali:" GET t_hor_d_2 PICTURE "9999"

      @ 18,17 SAY "Br.list.na strani:  " GET t_br_lis   PICTURE "99"
      @ 19,17 SAY "Br.komb.na lis.  :  " GET t_br_komb  PICTURE "99" WHEN .F. COLOR "n+/w"
      @ 20,17 SAY "Visina komb.     :"   GET t_vis_komb PICTURE "9999"
      @ 21,17 SAY "Razmak izm.komb. :"   GET t_raz_komb PICTURE "9999"

      @ 18,43 SAY "Br.u komb. :"         GET t_fnt_komb PICTURE "@!XXXXXXXXXX"
      @ 19,43 SAY "Ser.br.    :"         GET t_fnt_ser  PICTURE "@!XXXXXXXXXX"
      @ 20,43 SAY "Kolo&Datum :"         GET t_fnt_kolo PICTURE "@!XXXXXXXXXX"
      @ 21,43 SAY "5/36       :"         GET t_fnt_536  PICTURE "@!XXXXXXXXXX"

      SetCursor(1)
      READ
      SetCursor(0)

      IF LastKey() != 27

	 vstk_push()
	 cc = win_save(0,0,24,79)

	 cFN = padr(AllTrim(cFN),12," ")

	 WinStyle(9,25,15,55,"IME FAJLA")

	 @ 11, 27 SAY "Unesi ime fajla:"
	 @ 13, 27 GET cFN PICTURE "@!XXXXXXXXXXXX"

	 SetCursor(1)
	 READ
	 SetCursor(0)

	 win_rest(cc)
	 vstk_pop()

	 IF LastKey() != 27
	    cc = AllTrim(Group->path) + "\" + AllTrim(cFN) + ".pgs"
	    SAVE ALL LIKE t_* TO (cc)
	    done_beep()
	 ENDIF

      ENDIF

      win_rest(cOldScreen)
      vstk_pop()

RETURN NIL

FUNCTION GetPGS()

LOCAL aTemp := {}, ;
      aFN   := {}, ;
      cRet  := "", ;
      nSel  := Select()

      aTemp = Directory(AllTrim(Group->path) + "\*.pgs")

      IF Len(aTemp) > 0

	 FOR i = 1 To Len(aTemp)
	     aadd(aFN, aTemp[i,1])
	 NEXT

	 vstk_push()
	 cc = win_save(0,0,24,79)

	 WinStyle(9,33,16,47,"FAJL?")
	 @ 10,33 TO 16,47

	 nRet = AChoice(11,34,15,46,aFN)

	 win_rest(cc)
	 vstk_pop()

	 IF nRet = 0
	    cRet = ""
	 ELSE
	    cRet = AllTrim(aFN[nRet])
	 ENDIF

      ENDIF

RETURN cRet

FUNCTION DefPGS()

LOCAL nSel := Select()

PRIVATE cDefPGS := "", ;
	cFN	:= Space(12)

      cDefPGS = GetPGS()

      IF cDefPGS != ""

	 IF !NetUse(cMainDir + "\reg")
	    RETURN NIL
	 ENDIF

	 SET TAG TO id
	 GO TOP

	 SEEK MB_id

	 DO WHILE .T.
	    IF Reg->(RLock())
	       EXIT
	    ENDIF
	 ENDDO

	 REPLACE fn_pgs WITH cDefPGS

	 curr_PGS = cDefPGS

	 CLOSE reg
	 Select(nSel)

      ENDIF

RETURN NIL

FUNCTION ShowDefPGS(pp)

      vstk_push()
      SetColor("r+/w")
      @ 24,70 SAY pp
      vstk_pop()

RETURN NIL
