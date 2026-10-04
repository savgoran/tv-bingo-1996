PAGE	,132
NAME	SCNTCK

include extenda.inc

CLpublic <lCheck_15>

EXTRN	_read_xms:FAR
EXTRN	_get_seg:FAR

CLfunc log lCheck_15 <char pattern, char serbuff >

CLcode

	int 3
	; cli

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
exist_10	DW 0

; ------------------------------

Begin:	mov    currpage, 0
	mov    exist_10, 0
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
	cmp    ax, 0feh
	je     izlaz
	cmp    ax, 0
	je     p4

	mov    exist_10, 1

	call   UpisSerije

	jmp   p4

izlaz:	mov   ax, exist_10

	POP  BP
	POP  DI
	POP  SI
	POP  ES
	POP  DS

	; sti

CLret AX

WORKFUNCS

SwitchPage PROC NEAR

	mov	dx, currpage
	call	_read_xms
        inc     currpage

	RET

SwitchPage ENDP

; CheckList - ispituje da li se u pattern nalazi ista kombinacija kao u ListBuff
; vraca u AX 0 ako je razlicit 1 ako je isti
;
; ds:di - pattern
; es:si - listic

CheckList PROC NEAR

	push   ds
	push   si

	mov    ax, word ptr es:[si]
	mov    serrl, ax

	mov    ax, word ptr es:[si+2]
	mov    serrh, ax

	cmp    ah, 0ffh
	je     krajF

	lds    di, pattern
	mov    ax, word ptr es:[si + 4]   ; prva cetiri bajta su br.ser.

	cmp    al, 0ffh 		  ; ako listic nije prodat ima 0ffh na poc.
	je     krajF

	cmp    al, 0feh 		  ; ako je kraj baze 0feh
	je     krajFP

	add    si, 4

	mov    cx, 6

p1:	mov    ax, word ptr es:[si]
	mov    dx, word ptr [di]

	cmp    ax, 0
	je     p44

	and    dx, ax
	xor    dx, ax
	jnz    krajF

p44:	add    si, 2
	add    di, 2

	loop   p1

	mov    ax, 1
	jmp    kraj

krajF:	mov    ax, 0
	jmp    kraj

krajFP: mov    ax, 0feh

kraj:	pop    si
	add    si, 16
	pop    ds
	inc    brojac

	ret

CheckList ENDP

UpisSerije PROC NEAR

	push   ds

	lds    bx, serbuff
	add    bx, pnt_in_serbuf

	mov    ax, serrl
	mov    word ptr [bx], ax

	mov    ax, serrh
	mov    word ptr [bx+2], ax

	add    pnt_in_serbuf, 4

	pop    ds

	RET

UpisSerije ENDP

ENDWORK

END
