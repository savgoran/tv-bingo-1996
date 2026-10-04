#include "sixcdx2.ch"
#include "machsix.ch"

cls

set printer to pp.txt
set device to printer
set printer on

sa5br := 0

use maska new via "sixcdx"

for i = 1 to 512
    if isf(i) = 5
       append blank
       replace broj with i
       ? str(i,3) + ". " + ntoc(i,2,9,'0')
    endif
next i

close all

?
? "ukupno sa 5: " + str(sa5br,5)

set device to screen
set printer off
set printer to

function isf(neki_broj)

local br_bit := 0, n:=0

	 for n = 1 to 9
	     IF isbit(neki_broj,n)
		++br_bit
	     ENDIF
	 next

return br_bit
