#include "sixcdx2.ch"
#include "machsix.ch"
#include "inkey.ch"
#include "commands.ch"

FUNCTION NewKolo()

LOCAL cOldScreen := ""

PRIVATE aMyGet	:= {}, ;
	lAppend := .F.

PUBLIC	t_kolo	   := 0, ;
	t_datum    := CtoD("  /  /  "), ;
	t_cena	   := 0, ;
	t_p15	    := 0, ;
	t_p14	    := 0, ;
	t_p13	    := 0, ;
	t_pz	   := 0, ;
	t_v15	   := 0, ;
	t_v14	    := 0, ;
	t_v13	    := 0, ;
	t_v536	    := 0, ;
	t_v5361     := 0, ;
	t_vz	   := 0, ;
	t_fond	   := 0, ;
	t_vr_fond  := 0, ;
	t_ukup_fond:= 0, ;
	t_pnov_nag := 0, ;
	t_prob_nag := 0, ;
	t_ukup_kart:= 0, ;
	t_vr_nov   := 0, ;
	t_vr_rob   := 0

#ifdef ZASTITA

      if !SentQuery( 12, "8233" )
	 CLOSE ALL
	 setcolor("w/n")
	 CLS
	 ? "Error(1002) Pozovite servis!!!"
	 QUIT
      endif

#endif

      USE Fond NEW VIA "SIXCDX"
      SET TAG TO kolo
      GO TOP

      GO BOTTOM

      * inicijalizacija promenljivih iz prethodnog kola

      IF Fond->status
	 t_kolo = Fond->kolo + 1
      ELSE
	 t_kolo = Fond->kolo
      ENDIF

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle(3, 13, 21, 68, "NOVO KOLO")

      Maska()
      DO WHILE .T.

	 SetCursor(1)
	 READ
	 SetCursor(0)

	 IF LastKey() == K_ESC
	    EXIT
	 ENDIF

	 StoreVal()
	 DoneBeep()

	 GetList = aMyGet

      ENDDO

      win_rest(cOldScreen)
      vstk_pop()

      CLOSE ALL

RETURN NIL

STATIC FUNCTION Maska()

      vstk_push()
      SetColor("w/n")
      @ 12, 13 CLEAR TO 12, 68
      @ 12, 15 SAY "NOVCANE NAGRADE (%)         VREDNOST          PRENOS"
      vstk_pop()

      @  5, 15 SAY "Kolo:"    GET t_kolo  PICTURE "9999" VALID ChkKolo(t_kolo)
      @  5, 52 SAY "Datum:"   GET t_datum PICTURE "99/99/99" WHEN .F.
      @  7, 15 SAY "Cena kartice: " GET t_cena PICTURE "9999.99" VALID Fresh() .AND. !Empty(t_cena)
      @  7, Col()+1 SAY "EUR."
      @  8, 15 SAY "Fond za nagrade (%) :" GET t_fond PICTURE "999" VALID Fresh()
      @  8, 44 GET t_vr_fond PICTURE "99999999999.99" WHEN .F.
      @  8, Col()+1 SAY "EUR."
      @  9, 15 SAY "Novcane nagrade (%) :" GET t_pnov_nag PICTURE "999" VALID Fresh()
      @  9, 44 GET t_vr_nov PICTURE "99999999999.99" WHEN .F.
      @  9, Col()+1 SAY "EUR."
      @ 10, 15 SAY "Robne nagrade   (%) :" GET t_prob_nag PICTURE "999" VALID Fresh()
      @ 10, 44 GET t_vr_rob PICTURE "99999999999.99" WHEN .F.
      @ 10, Col()+1 SAY "EUR."

      @ 14, 15 SAY "1. nagrada : " GET t_p15  PICTURE "999" VALID Fresh()
      @ 14, 37 GET t_v15 PICTURE "99999999999.99" WHEN .F.
      @ 15, 15 SAY "2. nagrada : " GET t_p14  PICTURE "999" VALID Fresh()
      @ 15, 37 GET t_v14 PICTURE "99999999999.99" WHEN .F.
      @ 16, 15 SAY "3. nagrada : " GET t_p13  PICTURE "999" VALID Fresh()
      @ 16, 37 GET t_v13 PICTURE "99999999999.99" WHEN .F.

      @ 17, 15 SAY "zamena     : " GET t_pz  PICTURE "999" VALID Fresh()
      @ 17, 37 GET t_vz PICTURE "99999999999.99" WHEN .F.

      @ 18, 15 SAY "Fond za 5/36 : "
      @ 18, 37 GET t_v536 PICTURE "99999999999.99"
      @ 18, col()+2 GET t_v5361 PICTURE "99999999999.99"

      @ 19, 15 SAY "Prodato kartica :       " GET t_ukup_kart PICTURE "99999999" WHEN .F.
      @ 20, 15 SAY "Ukupan fond     : " GET t_ukup_fond PICTURE "99999999999.99" WHEN .F.
      @ 20, Col()+1 SAY "EUR."

      aMyGet = GetList

RETURN NIL

STATIC FUNCTION ChkKolo(ttt)

LOCAL lRetVal := .T., ;
      oGet    := GetActive(), ;
      nTemp   := 0

      IF Empty( ttt )

	 Fond->( dbGoBottom() )

	 IF Fond->status
	    t_kolo = Fond->kolo + 1
	 ELSE
	    t_kolo = Fond->kolo
	 ENDIF

	 oGet:Display()

	 RETURN .F.

      ENDIF

      Fond->( dbSeek(ttt) )
      IF Fond->( Found() )

	 t_cena = Fond->cena
	 t_datum = Fond->datum
	 t_ukup_kart = Fond->ukup_kart
	 t_fond = Fond->fond
	 t_ukup_fond = t_ukup_kart * t_cena	&& Fond->ukup_fond
	 t_vr_fond   = Perc(t_ukup_fond, t_fond)
	 t_pnov_nag  = Fond->pnov_nag
	 t_prob_nag  = Fond->prob_nag

	 t_vr_nov = Perc(t_vr_fond, t_pnov_nag)
	 t_vr_rob = Perc(t_vr_fond, t_prob_nag)

	 t_p15	= Fond->p15
	 t_p14	= Fond->p14
	 t_p13	= Fond->p13
	 t_pz	= Fond->pz

	 nTemp = Perc(t_vr_fond, t_pnov_nag)

	 t_v15	= Perc(nTemp, t_p15)
	 t_v14	= Perc(nTemp, t_p14)
	 t_v13	= Perc(nTemp, t_p13)
	 t_vz	= Perc(nTemp, t_pz)
	 t_v536 = Fond->v536
	 t_v5361= Fond->v5361

	 FOR i = 1 TO Len( GetList )
	     GetList[i]:Display()
	 NEXT

	 lAppend = .F.

      ELSE

	 Fond->( dbGoBottom() )

	 IF Fond->( Bof() ) .AND. Fond->( Eof() )
	 ELSE

	    IF Empty(Fond->datum)
	       ErrBeep()
	       alert("Prethodno kolo nije zavrseno!")
	       RETURN .F.
	    ENDIF

         ENDIF

	 t_kolo = Fond->kolo + 1

	 t_cena = Fond->cena
	 t_fond = Fond->fond
	 t_pnov_nag = Fond->pnov_nag
	 t_prob_nag = Fond->prob_nag

	 t_p15	= Fond->p15
	 t_p14	= Fond->p14
	 t_p13	= Fond->p13
	 t_pz	= Fond->pz

	 t_v15	= 0
	 t_v14	= 0
	 t_v13	= 0
	 t_v536 = Fond->v536
	 t_v5361= Fond->v5361
	 t_vz	= 0

	 t_ukup_fond = 0
	 t_ukup_kart = 0

	 FOR i = 1 TO Len( GetList )
	     GetList[i]:Display()
	 NEXT

	 lAppend = .T.

      ENDIF

RETURN lRetVal

STATIC FUNCTION StoreVal()

      IF lAppend

	 lAppend = .F.

	 REPLACE Fond->status WITH .T.

	 CloseKolo()

	 Fond->( dbAppend() )

      ENDIF

      REPLACE Fond->kolo      WITH t_kolo, ;
	      Fond->fond      WITH t_fond, ;
	      Fond->p15       WITH t_p15 , ;
	      Fond->p14       WITH t_p14 , ;
	      Fond->p13       WITH t_p13 , ;
	      Fond->v536      WITH t_v536, ;
	      Fond->v5361     WITH t_v5361,;
	      Fond->pz	      WITH t_pz  , ;
	      Fond->cena      WITH t_cena, ;
	      Fond->pnov_nag  WITH t_pnov_nag, ;
	      Fond->prob_nag  WITH t_prob_nag, ;
	      Fond->ukup_fond WITH t_ukup_fond,;
	      Fond->v15       WITH t_v15,;
	      Fond->v14       WITH t_v14,;
	      Fond->v13       WITH t_v13,;
	      Fond->v536      WITH t_v536

RETURN NIL

STATIC FUNCTION ResetVar()

LOCAL i := 0

      t_kolo	  := 0
      t_datum	  := CtoD("  /  /  ")
      t_cena	  := 0
      t_p15	  := 0
      t_p14	  := 0
      t_p13	  := 0
      t_pz	  := 0
      t_v15	  := 0
      t_v14	  := 0
      t_v13	  := 0
      t_v536	  := 0
      t_v5361	  := 0
      t_vz	  := 0
      t_ukup_fond := 0
      t_pnov_nag  := 0
      t_prob_nag  := 0
      t_ukup_kart := 0
      t_vr_nov	  := 0
      t_vr_rob	  := 0

      FOR i = 1 TO Len( GetList )
	  GetList[i]:Display()
      NEXT

RETURN NIL

STATIC FUNCTION Fresh()

LOCAL lRetVal := .T.,;
      oGet    := GetActive(), ;
      i       := 0

      IF Val(oGet:buffer) > 100
	 ErrBeep()
	 Alert("Procenat ne moze biti veci od 100!")
	 RETURN .F.
      ENDIF

      t_ukup_fond = t_ukup_kart * t_cena
      t_vr_fond   = Perc(t_ukup_fond, t_fond)

      t_vr_nov = Perc(t_vr_fond, t_pnov_nag)
      t_vr_rob = Perc(t_vr_fond, t_prob_nag)

      t_v15	= Perc(t_vr_nov, t_p15)
      t_v14	= Perc(t_vr_nov, t_p14)
      t_v13	= Perc(t_vr_nov, t_p13)
      t_vz	= Perc(t_vr_nov, t_pz)

      FOR i = 1 TO Len( GetList )
	  GetList[i]:Display()
      NEXT

RETURN lRetVal

FUNCTION CloseKolo()

LOCAL nSelect := Select()

	 USE RazdHis NEW VIA "SIXCDX"
	 SET TAG TO kolo
	 GO TOP

	 USE Razd NEW VIA "SIXCDX"
	 SET TAG TO brzas
	 GO TOP

	 msg_start(9, 25, 15, 55)
	 msg("arhiva razduzenja...")

	 DO WHILE !Razd->( Eof() )

	    RazdHis->( dbAppend() )
	    REPLACE RazdHis->kolo    WITH Fond->kolo, ;
		    RazdHis->zastup  WITH Razd->zastup, ;
		    RazdHis->serija  WITH Razd->serija, ;
		    RazdHis->kart    WITH Razd->kart, ;
		    RazdHis->od      WITH Razd->od

	    Razd->( dbSkip() )

	 ENDDO

	 msg_end()

	 Razd->( __dbZap() )

	 CLOSE Razd
	 CLOSE RazdHis

	 dbCreate("OPSEG",  {;
			      {"serija",      "N",  4,  0}, ;
			      {"od",          "N",  8,  0}, ;
			      {"do",          "N",  8,  0}, ;
			      {"mesto",       "C", 20,  0}, ;
			      {"brzas",       "N",  4,  0}  ;
			    }, "SIXCDX")

	 Select(nSelect)

RETURN NIL
