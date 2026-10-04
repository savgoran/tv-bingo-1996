FUNCTION MEdInit()

	 PUBLIC cEdScreen := "", cFile := ""

RETURN NIL

FUNCTION MEd1()

	 cFile = Make1Unq()
	 SET ALTERNATE TO &(cFile)
	 SET ALTERNATE ON
	 SET CONSOLE OFF

RETURN NIL

FUNCTION MEd2()

	 SET CONSOLE ON
	 SET ALTERNATE OFF
	 CLOSE ALTERNATE

	 vstk_push()
	 cEdScreen = win_save(0,0,24,79)

	 WinStyle(0,0,23,79,"PREGLED : " + AllTrim(cFile))
	 @ 1,1 TO 23,79

	 MemoEdit(MemoRead(cFile), 2, 2, 22, 78, .F.)

	 win_rest(cEdScreen)
	 vstk_pop()

	 FileDelete(cFile)

RETURN NIL
