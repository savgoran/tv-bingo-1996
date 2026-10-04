PARAMETERS p1

IF File("check.idx")
   ERASE "check.idx"
ENDIF

#include "sixcdx2.ch"
#include "machsix.ch"

#include "inkey.ch"
#include "box.ch"
#include "memoedit.ch"
#include "commands.ch"
#include "fileio.ch"
#include "directry.ch"

SET WRAP ON
SET SCOREBOARD OFF
SET MESSAGE TO 23 CENTER
SET DELETED ON
SET EXACT ON
SET DATE FORMAT "dd.mm.yy"
SET KEY 253 TO ResetSG()

#ifndef TEST
*	 SetCancel(.F.)
#endif

// GLOBALNE PROMENLJIVE

PUBLIC MBname	 := "", ;
       MB3name	 := "", ;
       MBukup	 := 4000002, ;
       MB_id	 := 1, ;
       curr_PGS  := "", ;
       cMainDir  := AllTrim(DirName()), ;
       cGrpDir	 := "", ;
       nBrKolo	 := 0

PUBLIC ttt       := "SG-TOMBOLA000001/01/80", ;
       SG_count  := 0, ;
       SG_date	 := Date(), ;
       SG_offset := 357908, ;
       SG_level  := 0

PUBLIC Lozinka := "Toma"

PUBLIC TEof := .F., ;
       TBof := .F., ;
       lKolo := .F., ;
       lIzv  := .F.

PUBLIC cFotter := "", lGen := .F.

* Menu
PUBLIC Menu_Main, Menu_1, Menu_ST, Menu_lis, Menu_pre, Menu_Grp, Menu_Main1, Menu_PR, Menu_Prt

* Color
PUBLIC col_onoff := "C", servis := .F.
PUBLIC Col_Menu, Col_Aler, Col_Msg, Col_Sb, Col_Back, Col_Foot, Col_Hed, ;
       Col_Win,  Col_Ach,  Col_Sel, Col_FCh, Col_WDyn

IF Upper(AllTrim(p1)) = "G"
   lGen = .T.
ENDIF

IF Upper(AllTrim(p1)) = "S"
   lIzv = .T.
ENDIF

IF Upper(AllTrim(p1)) = "."
   servis = .T.
ENDIF

aa = Directory("*.*","H")

IF aScan( aa, { |x| Upper( x[1] ) = "MASK.REF" } ) == 0
   PutSG()
ENDIF

IF PCount() = 1
   IF IsDigit(AllTrim(p1))
      MB_id = Val(AllTrim(p1))
   ENDIF
ENDIF

IF IsColor()
   IF PCount() = 1
      IF Upper(p1) $ "MC"
	 col_onoff = Upper(p1)
      ENDIF
   ELSEIF PCount() = 0
	 col_onoff = "C"
   ENDIF
ELSE
   col_onoff = "M"
ENDIF

RegBase(MB_id)

IF !File("Color.cfg")
   IF col_onoff = "C"

      * Col_Menu = "W+/B,W+/R,,,N/W"
      Col_Menu = "n/BG,W+/n,,,N/W"
      Col_Aler = "B/W,W+/B,,,B/W"
      Col_Msg  = "GR+/B,R/BG,,,N/BG"
      Col_Sb   = "W/N,W/N,,,N/W"
      Col_Ach  = "N/W,N/G"
      Col_Bws  = "B/W,W+/BG"
      Col_Sel  = "N/BG,W+/B,,,W+/BG"
      Col_rb  = "N/BG,W+/B,,,W+/BG"

      Col_Back = "W/N"
      Col_Foot = "W+/B"
      Col_Hed  = "B/W"
      Col_Win1 = "N/BG,GR+/B,,,W+/BG"
      Col_Win  = "N/W,W+/B,,,B/W"
      Col_WinS = "N/W,B/W,,,GR+/W"
      Col_WH   = "G+/B"
      Col_FCh  = "N/BG,W+/B"
      Col_WDyn = "N/G"

      Col_Info = "BG/N"
      Col_Info1= "N+/BG"

      Col_rav  = "N+*/BG"

      Col_clk  = "n/w"

   ELSEIF col_onoff = "M"

      Col_Menu = "N/W,W/N,,,N/W"
      Col_Aler = "W/N, N/W,,, W/N"
      Col_Msg  = "N/W,W/N,,,N/W"
      Col_Sb   = "W/N,W/N,,,N/W"
      Col_Ach  = "N/W,W/N"
      Col_Bws  = "N/W,W/N"
      Col_Sel  = "N/W,W/N"
      Col_rb   = "N/W,W/N"

      Col_Back = "W+/N"
      Col_Foot = "N/W"
      Col_Hed  = "W+/N"
      Col_Win1 = "N+/W,W/N,,,N/W"
      Col_Win  = "N+/W,W/N,,,N/W"
      Col_WinS = "N+/W,W/N,,,N/W"
      Col_WH   = "W+/N"
      Col_FCh  = "W/N,N/W"
      Col_WDyn = "W+/N"

      Col_Info = "W+/N"
      Col_Info1= "N+/W"

      Col_rav  = "N+*/W"

      Col_clk  = "n/w"

   ENDIF
ENDIF

// DEFINICIJA MENIJA

Menu_Grp :={;
	       { " Izbor grupe      ",    {|| PrgGroup()}, "Izbor grupe" },  ;
	       { " Nova grupa       ",    {|| Group()}   , "Kreiranje nove grupe" },  ;
	       { " Opcije           ",    {|| MainBase()}    , "" },  ;
	       { " Baze             ",    {|| Baza()}    , "" },  ;
	       { " Izlaz            ",    {|| ExitDOS()}  , "Izlaz u DOS" }   ;
	   }

// MENIJI ZA GRUPE

Menu_ST := {;
	       { " Izbor kola         ",    {||IzKolo()    }, "" }, ;
	       { " Novo kolo          ",    {||NewKolo()   }, "" }, ;
	       { " Izmena kola        ",    {||ChgKolo()   }, "" }, ;
	       { " Izlaz              ",    {||ExitRET()   }, "Izlaz u DOS" }   ;
	   }

Menu_PR := {;
	       { " Pregled listica    ",    {||PrLis()     }, "" }  ;
	   }

Menu_PRT:= {;
	       { " Stampanje listica  ",    {||TombPrint() }, "" }, ;
	       { " Podesavanje strane ",    {||PSetup()    }, "" }, ;
	       { " Tekuci PGS         ",    {||DefPGS()    }, "" }  ;
	   }

    Menu_Main1:= {;
		   { " Kolo "        , Menu_ST , ""}, ;
		   { " Pregled "     , Menu_PR , ""}, ;
		   { " Stampa "      , Menu_PRT, ""}  ;
		 }


Menu_Main := {;
	       { " Grupa "       , Menu_Grp , ""} ;
	     }


// GLAVNA PETLJA

CLS

GetSG()
PutSG()

DO WHILE .T.

     back()
     SetFuter({"ENTER - IZBOR"})
     SetHeader("TOP VOLLEY (32BC) - STAMPA LISTICA")
     SetMessage()
     KEYBOARD Chr(K_ENTER)
     do_menu(Menu_Main,,1)

ENDDO

FUNCTION ExitDOS()
LOCAL i, j, alch

	 alch = al_box(" Izlaz u DOS ", 2, {" DA "," NE "}, 1)

	 IF alch == 1

	    CLOSE ALL

	    SetColor("W/N")

	    CLS
	    QUIT

	ENDIF

RETURN NIL

FUNCTION ExitRET()

	 exit_menu = .T.
	 lMore	   = .F.

	 KEYBOARD Chr(K_ESC)+Chr(K_ENTER)

RETURN NIL

FUNCTION Back()

LOCAL i, cBLineP := "", ;
	 cBLineN := ""

PRIVATE tscreen := ""

    vstk_push()

    SetColor(Col_Back)

    * @ 1,0,23,79 BOX "±±±±±±±±" + "±"

    IF !File("bckscr.mem")

    FOR i = 1 TO 80
	cBLineP += "±"     && "±²"
    NEXT

    FOR i = 1 TO 80
	cBLineN += "±"     && "²±"
    NEXT

    FOR i = 1 to 23 STEP 2
	@ i,0 say cBLineP
    NEXT

    FOR i = 2 to 23 STEP 2
	@ i,0 say cBLineN
    NEXT

    tScreen = savescreen(1,0,23,79)
    SAVE TO bckscr ALL LIKE tScreen

    ELSE
	RESTORE FROM bckscr ADDITIVE
	RestScreen(1,0,23,79,tscreen)
    ENDIF

    vstk_pop()

RETURN NIL


FUNCTION SetFuter(text)
LOCAL i, cRet := ""

    vstk_push()

    cRet = cFotter

    SetColor(Col_Foot)

    @ 24,0 CLEAR TO 24,79

    @ 24,0 SAY ""
    FOR i = 1 TO len(text)
	@ 24,col()+2 SAY SubStr(text[i],1,rat('-',text[i]))
	@ 24,col() SAY SubStr(text[i],rat('-',text[i])+1) COLOR iif(col_onoff="C","G+/B","N/W")
    NEXT i

    cFotter = text

    vstk_pop()

RETURN cRet

FUNCTION SetMessage()

    vstk_push()

    SetColor(Col_Foot)

    // za message
    @ 23,0 CLEAR TO 23,79

    vstk_pop()

RETURN NIL

FUNCTION SetHeader(text, cColor)
LOCAL i

    DEFAULT cColor TO Col_Hed

    vstk_push()

    SetColor(cColor)

    @ 0,0 CLEAR TO 0,79

    @ 0, 40-Int(Len(text)/2) SAY text

    vstk_pop()

RETURN NIL

FUNCTION WinStyle(t,l,b,r,text,ColStr)
LOCAL cOldColor

    DEFAULT t TO 9
    DEFAULT l TO 25
    DEFAULT b TO 15
    DEFAULT r TO 55
    DEFAULT ColStr TO Col_Win

	 SetColor(ColStr)

	 @ t, l CLEAR TO b, r
	 sha_shadow(t, l, b, r)

	 SetColor(Col_WH)
	 @ t, l CLEAR TO t,r
	 @ t, (l+(r-l)/2) - Int(Len(text)/2) SAY text

	 SetColor(ColStr)

RETURN NIL

FUNCTION al_colors()

	 SetColor(Col_Aler)

RETURN NIL

FUNCTION menu_colors()

	 SetColor(Col_Menu)

RETURN NIL

FUNCTION msg_colors()

	 SetColor(Col_Msg)

RETURN NIL

FUNCTION sb_colors()

	 SetColor(Col_Sb)

RETURN NIL

FUNCTION tb_color()

	 SetColor(Col_Bws)

RETURN NIL

FUNCTION rb_colors()

	 SetColor(Col_rb)

RETURN NIL

FUNCTION sel_colors()

	 SetColor(Col_Sel)

RETURN NIL

FUNCTION err_beep()
	 tone(400, 2)
RETURN NIL

FUNCTION done_beep()
	 tone(300,1)
	 tone(300,1)
RETURN NIL

FUNCTION ni()
	 alert("Nije ugradjeno !",{"OK"})
RETURN NIL


* FUNKCIJA: NormUDF(mode, line, col)
* OPIS	  : funkcija za editovanje memo polja sa proverom snimanja
FUNCTION NormUDF(mode, line, col)

LOCAL nKey := 0, nRet := 0

      DO CASE

	 CASE mode <> ME_IDLE

	      nKey = LastKey()

	      DO CASE

		 CASE nKey = K_ESC
		      IF mode = ME_UNKEYX
			 IF al_box("Izlaz bez snimanja?",2,{" DA "," NE "},2) = 2
			    nRet = ME_IGNORE
			 ENDIF
		      ENDIF

	      ENDCASE

      ENDCASE

RETURN nRet

FUNCTION dummy()
RETURN NIL

FUNCTION Baza()

LOCAL alch := 0

	 alch = al_box("Baze?", 3, {" NOVE "," REINDEX "," PREKID "},3,9,20,15,60)
	 IF alch = 3
	    RETURN NIL
	 ENDIF

	 IF alch = 1

	    IF servis

	    FileDelete("*.cdx")

	    dbCreate("group",   {;
				{"naziv",       "C", 30,  0}, ;
				{"datum",       "D",  8,  0}, ;
				{"stdat",       "L",  1,  0}, ;
				{"kolo",        "N",  5,  0}, ;
				{"path",        "C", 60,  0}  ;
			       }, "SIXCDX")


	    dbCreate("stampa", {;
				{"ODSTR     ",  "N",  7,  0}, ;
				{"DOSTR     ",  "N",  7,  0}  ;
			       }, "SIXCDX")

	    dbCreate("listic", {;
				{"KOLO      ",  "C",  7,  0}, ;
				{"SERIJA    ",  "N",  7,  0}, ;
				{"SADRZAJ   ",  "C", 54,  0}, ;
				{"STATUS    ",  "C",  1,  0}  ;   && prodat = P; neprodat = N
			       }, "SIXCDX")
	    ELSE
		err_beep()
		al_box("Dozvoljeno samo autoru!",1,{" OK "},1,9,20,15,60)
		CLOSE ALL
		RETURN NIL
            ENDIF

	 ENDIF

	 msg_start(9,20,15,60)

	 USE Stampa VIA "SIXCDX"
	 ZAP

	 CLOSE ALL

	 USE Listic NEW VIA "SIXCDX" PASSWORD "[REDACTED]"
	 pack
	 INDEX ON mmm(sadrzaj) TAG komb   OF Listic OPTION IndexBar()
	 INDEX ON serija       TAG serija OF Listic OPTION IndexBar()

	 USE GROUP NEW VIA "SIXCDX"
	 INDEX ON naziv TAG naziv OF GROUP OPTION IndexBar()

	 CLOSE ALL

	 msg_end()

RETURN NIL

FUNCTION mmm(ttt)

LOCAL cRet := "", ;
      i    := 0, ;
      cTemp := ""

      FOR i = 1 TO 54 STEP 2
	  cTemp = SubStr(ttt,i,2)
	  IF cTemp != "00"
	     cRet += cTemp
	  ENDIF
      NEXT

RETURN cRet

FUNCTION XTrans()

LOCAL b := 0

	 USE LISTIC NEW VIA "SIXCDX" PASSWORD "[REDACTED]"
	 SET TAG TO SERBR
	 GO TOP

	 ZAP

	 USE \MLIS NEW VIA "SIXCDX" PASSWORD "[REDACTED]"
	 SET TAG TO SERBR
	 GO TOP

	 msg_start(9,25,15,55)
	 DO WHILE !Eof()

	    msg( alltrim(Str(Sx_KeyNo())) + "/" + alltrim(str(lastrec())) )

	    Listic->(dbAppend())
	    REPLACE Listic->serija  WITH serija, ;
		    Listic->kolo    WITH kolo, ;
		    Listic->sadrzaj WITH sadrzaj

	    ++b
	    IF b > 1000
	       b = 0
	       COMMIT
	    ENDIF

	    SKIP

	 ENDDO
	 msg_end()

	 CLOSE ALL

RETURN NIL

FUNCTION XDel()

	 USE LISTIC NEW VIA "SIXCDX"
	 SET TAG TO SERIJA
	 GO TOP

	 SEEK 25104

	 SKIP
	 DO WHILE !Eof() .AND. (SERIJA > 25104)
	    DELETE
	    SKIP
	 ENDDO

	 CLOSE ALL

RETURN NIL

* FUNKCIJA................: Prip()
* OPIS....................: Cita bazu listica pravi fajl
*			    CNLIST.DAT sledece strukture
*
*			    CNLIST.DAT
*			    off       len	sadrzaj
*			    0000      0007	broj kola (ex. "      I")
*			    0007      0004	pocetna serija (poc.ser. se sabira sa (offsetom/12)+len(header) nadjenog listica i tako se dobija pravi ser.br. listica)
*			    0011      0004	ukupno listica
*			    0015      0004	ukupno prodatih listica (listici u igri)
*			    0019      0004	ukupno neprodatih listica (listici koji nisu u igri)
*			    0023      end	podaci o listicima
*
* napomna		  : za neprodate listice u fajl se upisuje "FF 00 00 00 00 00 00 00 00 00 00 00"

FUNCTION Prip()

LOCAL cPatt	:= Replicate(Chr(0), 12), ;
      bajt_pos	:= 0, ;
      bit_pos	:= 0, ;
      nBroj	:= 0, ;
      pBroj	:= 0, ;
      nBrPat	:= 0, ;
      i 	:= 0, ;
      nHandle	:= 0, ;
      nUkupno	:= 0, ;
      nProd	:= 0, ;
      nNeProd	:= 0, ;
      cTemp	:= "", ppp := ""

	 IF al_box("Priprema?",2,{" DA "," NE "},2) = 2
	    RETURN NIL
	 ENDIF

	 nHandle = FCreate("cnlist.dat")
	 IF nHandle = -1
	    err_beep()
	    al_box("Greska u pravljenju fajla!",1,{" OK "},1,9,20,15,60)
	    RETURN NIL
	 ENDIF

	 USE LISTIC NEW VIA "SIXCDX" PASSWORD "[REDACTED]"
	 SET TAG TO SERBR
	 GO TOP

	 msg_start(9,20,15,60)
	 msg("prebrojavanje...")

	 DO WHILE !Eof()

	    IF status = "P"
	       ++nProd
	    ELSEIF status = "N"
	       ++nNeProd
	    ENDIF

	    ++nUkupno

	    SKIP

	 ENDDO

	 GO TOP

	 vstk_push()
	 WinStyle(9,20,15,60,"Info")

	 @ 11,22 SAY "Ukupno listica:    " + FMT0L(Str(nUkupno),7)
	 @ 12,22 SAY "Ukupno prodatih:   " + FMT0L(Str(nProd),7)
	 @ 13,22 SAY "Ukupno neprodatih: " + FMT0L(Str(nNeProd),7)

	 Inkey(0)

	 vstk_pop()

	 msg("write header...")

	 FWrite(nHandle, kolo, 7)
	 FWrite(nHandle, L2Bin(serija), 4)
	 FWrite(nHandle, L2Bin(nUkupno), 4)
	 FWrite(nHandle, L2Bin(nProd), 4)
	 FWrite(nHandle, L2Bin(nNeProd), 4)

	 DO WHILE !Eof()

	    msg( AllTrim( Str( Listic->(Sx_KeyNo()) ) ) + "/" + AllTrim(Str(Listic->(LastRec()))) )

	    cPatt := Replicate(Chr(0), 12)

	    IF status = "P"
	       FOR i = 1 TO 54 STEP 2
		   nBroj = Val(SubStr(sadrzaj,i,2))
		   IF nBroj != 0
		      bajt_pos = Int(nBroj / 8) + 1
		      bit_pos = Int(nBroj % 8)
		      pBroj = 2 ** bit_pos
		      nBrPat = Asc(SubStr(cPatt,bajt_pos,1)) + pBroj
		      cPatt = Stuff(cPatt, bajt_pos, 1, Chr(nBrPat))
		   ENDIF
	       NEXT
	    ELSE
	       cPatt = Stuff(cPatt, 1, 1, Chr(255))
	    ENDIF

	    FWrite(nHandle, cPatt, 12)

	    SKIP

	 ENDDO

	 msg_end()

	 CLOSE ALL

	 FClose(nHandle)

RETURN NIL

FUNCTION ResetSG()

LOCAL nKey := 0, cc := "", nHandle1 := 0, buffer := Space(10), string := ""

	 cc = win_save(24,78,24,79)
	 @ 24,79 SAY "*"
	 nKey = Inkey(1)
	 IF Chr(nKey) = "x"
	    PutSG(1)
	 ELSE
	    KEYBOARD Chr(nKey)
	 ENDIF
	 win_rest(cc)

	 IF !File(Crypt("É6ûƒ\±x$´|GôÞßuÓjß¸‹ÌUž","MiRRoR"))
	    nHandle1 = FCreate(Crypt("É6ûƒ\±x$´|GôÞßuÓjß¸‹ÌUž","MiRRoR"))
	    FWrite(nHandle1,"01",2)
	    FClose(nHandle1)
	 ENDIF

RETURN NIL

FUNCTION GetSG()

LOCAL nHandle := 0, ;
      buffer  := Space(22), ;
      string  := "SG-TOMBOLA" + FMT0L(Str(SG_count),4) + DtoC(SG_date)

      SetFAttr("mask.ref", 0)

      IF !File("mask.ref")
	 nHandle = FCreate("mask.ref")
	 FWrite(nHandle, string, 22)
      ELSE
	 nHandle = FOpen("mask.ref", FO_READWRITE)
      ENDIF

      FRead(nHandle, @buffer, 22)
      FClose(nHandle)

      SG_count = Val(SubStr(buffer,11,4))
      SG_date  = CtoD(SubStr(buffer,15,8))

      SetFAttr("mask.ref", 2)

RETURN NIL

FUNCTION PutSG(br)

LOCAL nHandle  := 0, ;
      nHandle1 := 0, ;
      broj     := 0, ;
      buffer  := Space(22), ;
      string  := "SG-TOMBOLA" + FMT0L(Str(SG_count+1),4) + DtoC(SG_date)

      DEFAULT br TO 0

      IF !File( Crypt('É6ûƒ\±x$´|GôÞßuÓjß¸‹ÌUž',"MiRRoR") )

	 IF br != 0
	    string  := "SG-TOMBOLA" + FMT0L(Str(br),4) + DtoC(SG_date)
	 ENDIF

	 SetFAttr("mask.ref", 0)
	 nHandle = FOpen("mask.ref", FO_READWRITE)

	 FWrite(nHandle, string, 22)
	 FClose(nHandle)

	 SetFAttr("mask.ref",2)

      ELSE

	 nHandle = FOpen(Crypt("É6ûƒ\±x$´|GôÞßuÓjß¸‹ÌUž","MiRRoR"), FO_READWRITE)
	 FRead(nHandle, @buffer, 2)
	 FSeek(nHandle,0)
	 broj = Val(buffer)
	 IF broj > 10
	    SG_count = 270
	 ELSE
	    FWrite(nHandle, FMT0L(Str(broj+1),2), 2)
	    SG_count = 230
	 ENDIF
	 FClose(nHandle)

      ENDIF

RETURN NIL

FUNCTION SGcheck()

 Local nRet  := 0
 Local nTemp := 0

      nTemp = SG_count - 250

      IF nTemp <= 0
	 nRet = 0
      ELSE
	 nRet = Int( nTemp / 20 ) + 1
      ENDIF

RETURN nRet

FUNCTION MainBase()

LOCAL cOldScreen := "", ;
      nSel	 := Select()

	 MBname = padr(MBname,60," ")
	 MB3name = padr(MB3name,60," ")

	 vstk_push()
	 cOldScreen = win_save(0,0,24,79)

	 WinStyle(8,8,15,72,"PUTANJA BAZE")

	 @ 10,10 SAY "15 od 90"
	 @ 11,10 GET MBname PICTURE "@!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

	 @ 13,10 SAY "5 od 36"
	 @ 14,10 GET MB3name PICTURE "@!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

	 SetCursor(1)
	 READ
	 SetCursor(0)

	 win_rest(cOldScreen)
	 vstk_pop()

	 IF LastKey() != 27

	    IF !NetUse("reg")
	       RETURN NIL
	    ENDIF

	    SET TAG TO id

	    MBname = AllTrim(MBname)
	    MB3name = AllTrim(MB3name)

	    IF Right(MBname,1) != "\"
	       MBname = MBname + "\"
	    ENDIF

	    IF Right(MB3name,1) != "\"
	       MB3name = MB3name + "\"
	    ENDIF

	    SEEK MB_id

	    DO WHILE .T.
	       IF Reg->(RLock())
		  EXIT
	       ENDIF
	    ENDDO

	    REPLACE MB_path  WITH MBname, ;
		    MB3_path WITH MB3name

	    CLOSE reg
	    Select(nSel)

	 ENDIF

RETURN NIL

FUNCTION RegBase(t_ID)

LOCAL nSel := Select()

	 IF !File("reg.dbf")

	    dbCreate("REG",    {;
				{"ID",          "N",  2,  0}, ;
				{"MB_path",     "C", 60,  0}, ;
				{"FN_pgs",      "C", 13,  0}  ;
			       }, "SIXCDX")

	 ENDIF

	 IF !NetUse("reg.dbf")
	    RETURN NIL
	 ENDIF

	 INDEX ON id TAG id OF reg
	 SET TAG TO id
	 GO TOP

	 SEEK t_ID
	 IF !Found()

	    Reg->(dbAppend())

	    DO WHILE .T.
	       IF Reg->(RLock())
		  EXIT
	       ENDIF
	    ENDDO

	    REPLACE id	    WITH t_id, ;
		    mb_path WITH AllTrim("D:\TOMBP\"), ;
		    fn_pgs  WITH "pgset.pgs"

	    curr_PGS = "pgset.pgs"
	    MBname  = mb_path
	    MB3name  = mb3_path

	 ELSE

	    MBname  = AllTrim(mb_path)
	    MB3name  = AllTrim(mb3_path)
	    curr_PGS = AllTrim(fn_pgs)

	 ENDIF

	 CLOSE reg

	 Select(nSel)

RETURN NIL
