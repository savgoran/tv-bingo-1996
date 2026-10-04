PARAMETERS p1

#include "sixcdx2.ch"
#include "machsix.ch"

#include "inkey.ch"
#include "box.ch"
#include "memoedit.ch"
#include "commands.ch"
#include "fileio.ch"
#include "directry.ch"
#include "achoice.ch"

CX = 7
CY = 15

RAZD_VER = "1.2"

SET WRAP ON
SET SCOREBOARD OFF
SET MESSAGE TO 23 CENTER
SET DELETED ON
SET EXACT ON
SET DATE FORMAT "dd.mm.yy"
SET KEY K_ALT_K TO Calc()

// GLOBALNE PROMENLJIVE

PUBLIC MBNAME := DirName(), ;
       MBUKUP := 4000002, ;
       mk     := "", ;
       TEK_KOLO := 0
       * MBUKUP := 10000000

PUBLIC TEof := .F., ;
       TBof := .F.

PUBLIC P_BRKOLO  := 0, ;
       P_PASS	 := Space(9), ;
       nCena	 := 3,;
       nProcFond := 50

PUBLIC cFotter := "", cPath := "E:\"

* Menu
PUBLIC Menu_Main, Menu_Ser, Menu_Kolo, Menu_Zas, Menu_Zad, Menu_raz, Menu_Ex, Menu_Izv

* Color
PUBLIC col_onoff := "C", servis := .F., nTimeBeg := TimeToSec( Time() ), nTimeEnd := 0

PUBLIC Col_Menu, Col_Aler, Col_Msg, Col_Sb, Col_Back, Col_Foot, Col_Hed, ;
       Col_Win,  Col_Ach,  Col_Sel, Col_FCh, Col_WDyn

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

IF !File("Color.cfg")
   IF col_onoff = "C"

      * Col_Menu = "W+/B,W+/R,,,N/W"
      Col_Menu = "w+/GR,W+/N,,,N/W"
      * Col_Aler = "B/W,W+/B,,,B/W"
      Col_Aler = "w+/r,gr+/n,,,w+/r"
      Col_Msg  = "GR+/B,R/BG,,,N/BG"
      Col_Sb   = "W/N,W/N,,,N/W"
      Col_Ach  = "N/W,N/G"
      Col_Bws  = "B/W,W+/BG"
      Col_Sel  = "N/BG,W+/B,,,W+/BG"
      Col_rb  = "N/BG,W+/B,,,W+/BG"

      Col_Back = "W/N"
      Col_Foot = "W+/BG"
      Col_Hed  = "W+/B"
      Col_Win = "N/BG,GR+/B,,,W+/BG"
      Col_Win1	= "N/W,W+/B,,,B/W"
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

#ifdef ZASTITA

// ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
// ³ HARDVERSKA ZASTITA 			  ³
// ³						  ³
// ³						  ³
// ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

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

// DEFINICIJA MENIJA

Menu_Ser :={;
	       { " Nova serija         ",    {|| NewSer()}, "Otvaranje nove serije"}, ;
	       { " Pregled serija      ",    {|| PrSer()}, "Pregled serija"} ;
	   }

Menu_Kol :={;
	       { " Otvaranje kola      ",    {|| NewKolo() }, "Novo kolo" }  ;
	   }

	     * { " Prikupljanje podat. ",    {|| GrabInfo()}, "" },  ;
	     * { " Unos centra         ",    {|| UnCentar()}, "Unos i izmena centra" },  ;

Menu_Zas :={;
	       { " Unos zastupnika     ",    {|| UnZas()}, "Unos i izmena zastupnika" },  ;
               { " Pregled zastupnika  ",    {|| PrZas()}, "" },  ;
	       { " Brisanje zastupnika ",    {|| DelZas()}, "" }   ;
	   }

Menu_Zad :={;
	       { " Zaduzivanje kartica ",   {|| UnZad()}, "Zaduzivanje kartica" }, ;
	       { " Izmena zaduzenja    ",   {|| ChgZad()}, "Izmena zaduzenja" },  ;
	       { " Pregled zaduzenja   ",   {|| PregZad()} , "Pregled zaduzenja" },  ;
	       { " Pregled listica     ",   {|| PrLis()} , "Pregled listica" }  ;
	   }

Menu_Raz :={;
	       { " Razduzivanje kartica   ",   {|| RazdX()}, "Razduzivanje kartica" }, ;
	       { " Ponistenje razduzenja  ",   {|| ChgRazd()}, "Ponistenje razduzenja po kolu" },  ;
               { " Pregled razduzenja     ",   {|| PregRazd()}, "Pregled razduzenja po kolu" },  ;
	       { " Pregled istorije razduzenja ",   {|| PregRazdHis()}, "Pregled istorije razduzenja po kolu" },  ;
	       { " Nerazduzena zaduzenja  ",   {|| RazdPrnX()}, "Pregled nerazduzenih zaduzenja" },  ;
	       { " Baza izgleda listica   ",   {|| FillIzg()} , "" },  ;
               { " Priprema za izvlacenje ",   {|| Prip()} , "Priprema za izvlacenje" }   ;
	   }

	       * { " Prodaja po mestima    ",   {|| RangCity()},   "" },  ;
	       * { " Prodaja po prodavcima ",   {|| RangProd()},   "" }   ;
	       * { " Dobici po centrima     ",   {|| IzvCen()},   "Izvestaj o dobicima po centrima" },  ;


Menu_Izv :={;
	       { " Izvestaj o izvlacenju  ",   {|| exizvrep()}, "Izvestaj sa izvlacenja" }  ;
	   }

Menu_Ex  :={;
	       { " Izlaz            ",    {|| ExitDOS()}  , "Izlaz u DOS" },  ;
	       { " Unos nagrada     ",    {|| UnNag() }   , "Unos robnih nagrada" },  ;
	       { " Arhiva HD->FD    ",    {|| BackUp({"*.dbf","*.cdx","*.ntx"},"A:")}  , "Snimanje podataka sa diska na disketu" },  ;
	       { " Arhiva FD->HD    ",    {|| Restore("A:")}  , "Ucitavanje arhive sa diskete" },  ;
	       { " Baze             ",    {|| Baza()}, "" }  ;
	   }

Menu_Main := {;
	       { "Serija"      , Menu_Ser, ""}, ;
	       { "Kolo"        , Menu_Kol, ""}, ;
	       { "Zastupnik"   , Menu_Zas, ""}, ;
	       { "Zaduzenje"   , Menu_Zad, ""}, ;
	       { "Razduzenje"  , Menu_Raz, ""}, ;
	       { "Izves."      , Menu_Izv, ""}, ;
	       { "Izlaz"       , Menu_Ex , ""}  ;
	     }


// GLAVNA PETLJA

#ifdef PROF
ShowTime(0,72,.F.,Col_clk,.F.,.T.)
#endif

IF File("path.cfg")
   RESTORE FROM path.cfg ADDITIVE
ENDIF

IF File("cena.cfg")
   RESTORE FROM cena.cfg ADDITIVE
ENDIF

IF File("razd.ini")
   nCena = Val( ReadIni("razd.ini", "cena_listica") )
   cPath = ReadIni("razd.ini", "mainpath")
   nProcFond = Val( ReadIni("razd.ini", "novcani_fond") )
ENDIF

CLS

back()
* SetFuter({"ENTER - IZBOR","ALT+K - KALKULATOR"})
nTemp := 0

USE Fond NEW VIA "SIXCDX"
SET TAG TO Kolo
GO BOTTOM

TEK_KOLO := Fond->kolo

CLOSE ALL

#ifdef ZASTITA
SentRead( 11, @nTemp )
SetHeader( "TOP VOLLEY " + RAZD_VER + " | Count: " + FMT0L( Str( nTemp ), 3 ) )
#else
SetHeader( "TOP VOLLEY " + RAZD_VER + "   " + AllTrim(Str(TEK_KOLO)) + ". kolo" )
#endif

IF File("mkolo.dbf")

USE Mkolo NEW VIA "SIXCDX"
GO TOP

IF MKolo->(Bof()) .AND. Mkolo->(Eof())
ELSE
   GO BOTTOM

   IF !ChkPass(MKolo->broj)
      ErrBeep()
      al_box("Program zakljucan. Pozovite programera!",1,{" OK "},1,9,20,15,60)
      QUIT
   ENDIF

   IF MKolo->status = .T.
      P_BRKOLO = MKolo->broj
      P_PASS   = MKolo->password
      SetHeader("LOTO 5+5 Kolo: " + Str(P_BRKOLO, 4) + " Password: " + P_PASS)
   ENDIF
ENDIF

CLOSE ALL

ENDIF

SetMessage()

DO WHILE .T.

     KEYBOARD Chr(K_ENTER)
     do_menu(Menu_Main,,1)

ENDDO

FUNCTION ExitDOS()
LOCAL i, j, alch

	 alch = al_box(" Izlaz u DOS ", 2, {" DA "," NE "}, 1)

	 IF alch == 1

#ifdef PROF
	    ShowTime()
#endif

	    CLOSE ALL

	    SetColor("W/N")

	    CLS
	    QUIT

	ENDIF

RETURN NIL

FUNCTION Back()

LOCAL i, cBLineP := "", ;
	 cBLineN := ""

PRIVATE tscreen := ""

    vstk_push()

    SetColor(Col_Back)

    FOR i = 1 TO 80
	cBLineP += "Û"     && "±²"
    NEXT	    

    FOR i = 1 TO 80
	cBLineN += "Û"     && "²±"
    NEXT

    FOR i = 1 to 23 STEP 2
	@ i,0 say cBLineP
    NEXT

    FOR i = 2 to 23 STEP 2
	@ i,0 say cBLineN
    NEXT

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
	@ 24,col() SAY SubStr(text[i],rat('-',text[i])+1) COLOR iif(col_onoff="C","R+/Bg","N/W")
    NEXT i

    cFotter = text

    vstk_pop()

RETURN cRet

FUNCTION SetMessage()

    vstk_push()

    SetColor(Col_Foot)

    // ZA MESSAGE
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

FUNCTION ErrBeep()
	 tone(400, 2)
RETURN NIL

FUNCTION DoneBeep()
	 tone(300,1)
	 tone(300,1)
RETURN NIL

FUNCTION ni()
	 alert("Nije ugradjeno !",{"OK"})
RETURN NIL


FUNCTION AchUDF(nMode, nCurr, nPos)

LOCAL nRetVal := AC_CONT, ;
      nKey    := LastKey()

      DO CASE

	 CASE nMode == AC_EXCEPT

	      DO CASE

		 CASE nKey == K_RETURN
		      nRetVal = AC_SELECT

                 CASE nKey == K_ESC
		      nRetVal = AC_ABORT

		 OTHERWISE
		      nRetVal = AC_GOTO

	      ENDCASE

      ENDCASE

RETURN nRetVal

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

	    FileDelete("*.cdx")

	    dbCreate("serija",  {;
				{"broj",        "N",  4,  0}, ;
				{"od",          "N",  8,  0}, ;
				{"do",          "N",  8,  0}, ;
				{"prva_slob",   "N",  8,  0}, ;
				{"zad_slob",    "N",  8,  0}, ;
				{"prv_nepro",   "N",  8,  0}, ;
				{"poc_br",      "N",  8,  0}, ;   && pocetni broj
				{"path",        "C", 50,  0}, ;
				{"status",      "C",  1,  0}  ;   && *
				}, "SIXCDX")

* Serija->status
* 0 - Serija slobodna i za zaduzivanje i za razduzivanje
* 1 - Serija cela zaduzena ali ima jos neprodatih
* 2 - Serija razduzena

	    dbCreate("FOND",    {;
				{"kolo",        "N",  4,  0}, ;
				{"datum",       "D",  8,  0}, ;   && datum izvlacenja
				{"cena",        "N",  6,  2}, ;   && cena kartice
				{"fond",        "N",  3,  0}, ;   && fond za nagrade
				{"p15",         "N",  3,  0}, ;   && % 15
				{"p14",         "N",  3,  0}, ;   && % 14
				{"p13",         "N",  3,  0}, ;   && % 13
				{"pZ",          "N",  3,  0}, ;   && % zamena
				{"v15",         "N", 14,  2}, ;   && vrednost 15
				{"v14",         "N", 14,  2}, ;   && vrednost 14
				{"v13",         "N", 14,  2}, ;   && vrednost 13
				{"v536",        "N", 14,  2}, ;   && vrednost 5/36 (5 od 36)
				{"v5361",       "N", 14,  2}, ;   && vrednost 5/36 (5+1 od 36)
				{"vz",          "N", 14,  2}, ;   && vrednost zamene
				{"d15",         "N",  6,  0}, ;   && broj dobitnika 15
				{"d14",         "N",  6,  0}, ;   && broj dobitnika 14
				{"d13",         "N",  6,  0}, ;   && broj dobitnika 13
				{"d536",        "N",  6,  0}, ;   && broj dobitnika 5/36
				{"dz",          "N",  6,  0}, ;   && broj dobitnika zamene
				{"ukup_fond",   "N", 14,  2}, ;   && ukupni fond
				{"ukup_kart",   "N",  8,  0}, ;   && prodato kartica
				{"pnov_nag",    "N",  3,  0}, ;   && % za novcane nagrade
				{"prob_nag",    "N",  3,  0}, ;   && % za robne nagrade
				{"status",      "L",  1,  0}  ;   && izvlacenje .T. bilo
			       }, "SIXCDX")

	    dbCreate("CENTAR", {;
				{"broj",        "N",  1,  0}, ;
				{"naziv",       "C", 20,  0}, ;
				{"path",        "C", 60,  0}, ;
				{"last",        "D",  8,  0}  ;
			       }, "SIXCDX")

	    dbCreate("ZASTUP",  {;
				{"brzas",       "N",  4,  0}, ;
				{"prezime",     "C", 25,  0}, ;
				{"ime",         "C", 25,  0}, ;
				{"mesto",       "C", 20,  0}, ;
				{"adresa",      "C", 25,  0}, ;
				{"tel",         "C", 20,  0}  ;
			       }, "SIXCDX")

	    dbCreate("ZADUZ",  {;
				{"zastup",      "N",  4,  0}, ;
				{"serija",      "N",  4,  0}, ;
                                {"od",          "N",  8,  0}, ;
				{"do",          "N",  8,  0}, ;
				{"datum",       "D",  8,  0}, ;
				{"prva_slob",   "N",  8,  0}, ;
				{"status",      "L",  1,  0}  ;
			       }, "SIXCDX")

	    dbCreate("RAZD",   {;
				{"zastup",      "N",  4,  0}, ;
				{"serija",      "N",  4,  0}, ;      && broj serije
				{"kart",        "N",  8,  0}, ;      && vracena kartica
				{"od",          "N",  8,  0}, ;      && prodato od kartice br.
				{"lps",         "L",  1,  0}, ;      && ima/nema presecnu karticu
				{"obrada",      "L",  1,  0}  ;      && slog obradjen u cnlist.dat
			       }, "SIXCDX")

	    dbCreate("RAZDHIS",{;
				{"kolo",        "N",  4,  0}, ;
                                {"zastup",      "N",  4,  0}, ;
				{"serija",      "N",  4,  0}, ;      && broj serije
				{"kart",        "N",  8,  0}, ;      && vracena kartica
				{"od",          "N",  8,  0}  ;      && prodato od kartice br.
			       }, "SIXCDX")

	    dbCreate("opseg",  {;
				{"serija",      "N",  4,  0}, ;
                                {"od",          "N",  8,  0}, ;
				{"do",          "N",  8,  0}, ;
				{"mesto",       "C", 20,  0}, ;
				{"brzas",       "N",  4,  0}  ;
			       }, "SIXCDX")

	    dbCreate("mkolo",  {;
				{"broj",        "N",  5,  0}, ;
				{"ukupno",      "N",  8,  0}, ;
				{"password",    "C",  9,  0}, ;
				{"status",      "L",  1,  0}  ;
			       }, "SIXCDX")

	 ENDIF

	 msg_start(9,20,15,60)

	 USE Serija VIA "SIXCDX"
	 INDEX ON broj TAG broj OF Serija

	 USE Fond NEW VIA "SIXCDX"
	 INDEX ON kolo TAG kolo OF Fond

	 USE Centar NEW VIA "SIXCDX"
	 INDEX ON broj TAG broj OF Centar

	 USE Zastup VIA "SIXCDX"
	 INDEX ON brzas TAG brzas OF Zastup

	 USE Zaduz VIA "SIXCDX"
	 INDEX ON zastup TAG brzas OF Zaduz
	 INDEX ON FMT0L( Str(serija), 4 ) + FMT0L( Str(od), 8 ) TAG serod OF Zaduz
	 INDEX ON FMT0L( Str(zastup), 4 ) + FMT0L( Str(serija),4) + FMT0L( Str(prva_slob), 8 ) TAG zsp OF Zaduz

	 USE Razd VIA "SIXCDX"
	 INDEX ON zastup TAG brzas OF Razd
	 INDEX ON FMT0L(Str(serija),4) + FMT0L(Str(od), 8) TAG serod OF Razd
	 INDEX ON FMT0L( Str(zastup), 4 ) + FMT0L( Str(serija),4) + FMT0L( Str(od), 8 ) TAG zso OF Razd

	 USE RazdHis NEW VIA "SIXCDX"
	 INDEX ON FMT0L( Str(kolo), 4 ) + FMT0L( Str(zastup), 4 ) TAG kolo OF RazdHis

	 CLOSE ALL

	 msg_end()

RETURN NIL
