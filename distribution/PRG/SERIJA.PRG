#include "sixcdx.ch"
#include "machsix.ch"
#include "inkey.ch"
#include "commands.ch"

FUNCTION NewSer()

LOCAL cOldScreen := ""

PRIVATE aMyGet	 := {}, ;
	lAppend  := .F.

PRIVATE t_broj     := 0, ;
	t_od	   := 1, ;
	t_do	   := 0, ;
	t_path	   := Space(50)

      USE Serija NEW VIA "SIXCDX"
      SET TAG TO broj
      GO BOTTOM

      GO TOP

      vstk_push()
      cOldScreen = win_save(0,0,24,79)

      WinStyle( 7, 11, 12, 70, "NOVA SERIJA")

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

	 ResetVar()

      ENDDO

      win_rest(cOldScreen)
      vstk_pop()

      CLOSE ALL

RETURN NIL

STATIC FUNCTION Maska()

      @  9, 13 SAY "Redni broj serije:" GET t_broj PICTURE "9999" VALID ChkBroj(t_broj)
      @  9, 38 SAY "Komb.od:"           GET t_od   PICTURE "99999999" WHEN .F.
      @  9, 57 SAY "do:"                GET t_do   PICTURE "99999999" VALID !Empty(t_do) .AND. (t_do > t_od)
      @ 11, 13 SAY "Path:"              GET t_path PICTURE "@!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" VALID !Empty(t_path)

      aMyGet = GetList

RETURN NIL

STATIC FUNCTION StoreVal()

LOCAL nTemp := 0

      t_path = AllTrim(t_path)
      IF Right(t_path, 1) != "\"
	 t_path += "\"
      ENDIF

      IF t_broj == 1
	 nTemp = 1
      ELSE
	 nTemp = Int( ( t_broj * 10000 ) % MBUKUP ) + 1
      ENDIF

      IF lAppend
	 lAppend = .F.
	 Serija->(dbAppend())
      ENDIF

      REPLACE Serija->broj	 WITH t_broj, ;
	      Serija->od	 WITH t_od, ;
	      Serija->do	 WITH t_do, ;
	      Serija->prva_slob  WITH t_od, ;
	      Serija->zad_slob	 WITH t_do, ;
	      Serija->prv_nepro  WITH t_od, ;
	      Serija->poc_br	 WITH nTemp,;
	      Serija->path	 WITH t_path, ;
	      Serija->status	 WITH '1'

RETURN NIL

STATIC FUNCTION ResetVar()

LOCAL i := 0

      t_broj	 := 0
      t_od	 := 1
      t_do	 := 0
      t_path	 := Space(50)

      FOR i = 1 TO Len(GetList)
	  GetList[i]:Display()
      NEXT

RETURN NIL

STATIC FUNCTION ChkBroj(ttt)

LOCAL lRet := .T., ;
      oGet := GetActive(), ;
      i    := 0

      IF Empty(ttt)
	 Serija->(dbGoBottom())
	 oGet:buffer = Str(Serija->broj + 1,4)
	 oGet:Assign()
	 oGet:Display()
	 RETURN .F.
      ENDIF

      Serija->(dbSeek(ttt))

      IF Serija->(Found())

	 t_broj = Serija->broj
	 t_od	= Serija->od
	 t_do	= Serija->do
	 t_path = Serija->path

	 FOR i = 1 TO Len(GetList)
	     GetList[i]:Display()
	 NEXT

	 lAppend = .F.

      ELSE

	 Serija->(dbGoBottom())
	 t_broj = Serija->broj + 1

	 oGet:Display()

	 lAppend = .T.

      ENDIF

RETURN lRet

* funkcija vraca ukupan broj kartica za zaduzenja
FUNCTION UkupZaZad()

LOCAL nRet    := 0, ;
      nOldRec := Serija->( RecNo() )

      Serija->( dbGoTop() )
      DO WHILE !Serija->( Eof() )

	 IF Serija->status != "2"
	    nRet += Int( (( do - prva_slob ) + 1) / 5 )
	 ENDIF

	 Serija->( dbSkip() )

      ENDDO

      Serija->( dbGoTo( nOldRec ) )

RETURN nRet

* total za zaduzenje u tekucoj seriji (u karticama)
FUNCTION TotCurSer()

LOCAL nRet    := 0

      IF Serija->status != "2"
	 nRet += Int( (( Serija->do - Serija->prva_slob ) + 1) / 5 )
      ENDIF

RETURN nRet

FUNCTION NxtSerZad()

LOCAL nTemp := 0

*	nTemp = Serija->prv_nepro - 1

       Serija->(dbGoTop())
       DO WHILE .T.

	  IF Serija->status == '0'

*	      REPLACE Serija->zad_slob WITH nTemp

	     EXIT

	  ENDIF

	  Serija->(dbSkip())

       ENDDO

RETURN NIL

FUNCTION FndZad()

LOCAL lRetVal := .T.

      Serija->(dbGoTop())
      DO WHILE !Serija->(Eof())
	 IF Serija->status == '0'
	    EXIT
	 ENDIF
	 Serija->(dbSkip())
      ENDDO

      IF Serija->(Eof())
	 lRetVal = .F.
      ENDIF

RETURN lRetVal

FUNCTION PrSer()

LOCAL nUkupnoK := 0

      IF al_box("Pregled serija?", 2, {" DA "," NE "}, 2, 9, 25, 15, 55) == 2
	 RETURN NIL
      ENDIF

      USE Serija NEW VIA "SIXCDX"
      SET TAG TO broj
      GO TOP

      IniPtr()
      Prt1()
      Prt2()

      ? padc("PREGLED SERIJA", 80, " ")
      ?

      ? "********************************************************************************"
      ? "Broj         Opseg           Ukupno   Prva neprodata  Prva kartica        Ukupno"
      ? "ser.         od        do   kartica          kartica  za zaduzenje  za zaduzenje"
      ? "********************************************************************************"

      DO WHILE !Serija->(Eof())

	 nUkupnoK = ((Serija->do - Serija->od) + 1)

	 ? FMT0L(Str(Serija->broj, 4), 4) + Space(3) + Str(Serija->od, 8) + Space(2) + ;
	   Str(Serija->do) + Space(2) + Str(nUkupnoK, 8) + Space(9) + ;
	   Str(Serija->prv_nepro, 8) + Space(6) + Str(prva_slob, 8) + Space(6) + ;
	   Str( ((Serija->zad_slob - Serija->prva_slob) + 1), 8)

	 Serija->(dbSkip())

      ENDDO

      ? "********************************************************************************"

      Prt3()

      CLOSE ALL

RETURN NIL
