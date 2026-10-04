PAGE	,132
NAME	SCNTCK

include extenda.inc

CLpublic <lCheckCnt>

EXTRN	_read_xms:FAR
EXTRN	_get_seg:FAR

CLfunc void lCheckCnt <char pattern, char cntbuff>

CLcode

	PUSH DS
	PUSH ES
	PUSH SI
	PUSH DI
	PUSH BP

	JMP  Begin

; ------------------------------

currpage	DW 0
brojac		DW 0
serrl		DW 0
serrh		DW 0
pnt_in_serbuf	DW 0
exist_15	DW 0

; ------------------------------

Begin:	mov    currpage, 0
	mov    exist_15, 0
        mov    serrl, 0
	mov    serrh, 0
	mov    pnt_in_serbuf, 0
	call   _get_seg
	mov    es, ax

Begin1: xor    si, si
	mov    brojac, 0
	call   SwitchPage

p4:	cmp    brojac, 2048		; stigo do kraja strane ?
	je     Begin1

	call   CheckList

	cmp    ax, 0feh 		; kraj podataka
	je     izlaz

	cmp    bx, 13			; if < 13 p4
	jl     p4

	call   UpisSerije

	jmp   p4

izlaz:	POP  BP
	POP  DI
	POP  SI
	POP  ES
	POP  DS

CLret

WORKFUNCS

SwitchPage PROC NEAR

	mov	dx, currpage
	call	_read_xms
        inc     currpage

	RET

SwitchPage ENDP

; CheckList - u BX vraca broj pogodjenih brojeva
;
; ds:di - pattern
; es:si - listic

CheckList PROC NEAR

	push   ds
	push   si

	xor    bx, bx

	mov    ax, word ptr es:[si]
	mov    serrl, ax

	mov    ax, word ptr es:[si+2]
	mov    serrh, ax

	lds    di, pattern
	mov    ax, word ptr es:[si + 4]   ; prva cetiri bajta su br.ser.

	cmp    al, 0feh 		  ; ako je kraj baze 0feh
	je     krajFP

	add    si, 4

	mov    cx, 6

p1:	mov    ax, word ptr es:[si]
	mov    dx, word ptr [di]

	cmp    ax, 0
	je     p44

	and    dx, ax

	call   CntWord

p44:	add    si, 2
	add    di, 2

	loop   p1

	mov    ax, 0
	jmp    kraj

krajFP: mov    ax, 0feh
	pop    si
	pop    ds
	ret

kraj:	pop    si
	add    si, 16
	pop    ds
	inc    brojac

	ret

CheckList ENDP

; CntWord - prebrojava jedinice u DX i vraca rezultat u BX
CntWord PROC NEAR

	push   cx

	mov    cx, 16

p77:	shl    dx, 1
	jnc    p78

	inc    bx			; povecaj brojac

	or     dx, dx			; dx = 0 ?
	jz     p79

p78:	loop   p77

p79:	pop    cx

	RET

CntWord ENDP

UpisSerije PROC NEAR

	push   ax
	push   ds
	push   si

	lds    si, cntbuff			; ds:si = cCntBuff
	mov    ax, 15
	sub    ax, bx
	mov    bx, 4
	mul    bx

	add    si, ax				; ds:[si + offset]

	cmp    word ptr [si], 0ffffh
	jne    p700

	mov    word ptr [si], 0
	add    si, 2

p700:	inc    word ptr [si]

	pop    si
	pop    ds
	pop    ax

	RET

UpisSerije ENDP

ENDWORK

END
