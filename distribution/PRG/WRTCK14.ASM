PAGE	,132
NAME	WRTCK

include c:\clipper\include\extenda.inc

CLpublic <WrTicket>

EXTRN	_read_xms:FAR
EXTRN	_get_seg:FAR

; serbr : broj pogodaka (1), ser + rbk (4) = 6 bajta

CLfunc void WrTicket <char pattern, int lower_bound, int pageframe, int fhandle, char serbr>

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
pnt_in_cntbuf	DW 0

; ------------------------------

Begin:	mov    currpage, 0
	mov    pnt_in_cntbuf, 0
	; mov	 ax, pageframe
	call   _get_seg
	mov    es, ax

Begin1: xor    si, si
	mov    brojac, 0
	call   SwitchPage1

p4:	cmp    brojac, 2048		 ; stigo do kraja emm strane ?
	je     Begin1

	call   CheckList1
	cmp    ax, 0feh
	je     izlaz
	cmp    bx, lower_bound
	jl     p4

	call   WrCount

	jmp   p4

izlaz:	POP  BP
	POP  DI
	POP  SI
	POP  ES
	POP  DS

CLret

WORKFUNCS

SwitchPage1 PROC NEAR

	; mov	  dx, emmhandle
	; mov	  bx, currpage
	; mov	  ax, 4400h
	; int	  67h

	mov	dx, currpage
	call	_read_xms
        inc     currpage

	RET

SwitchPage1 ENDP

; CheckList - ispituje da li se u pattern nalazi ista kombinacija kao u ListBuff
; vraca u AX 0 ako je razlicit 1 ako je isti
;
; ds:di - pattern
; es:si - listic

CheckList1 PROC NEAR

	push   ds
        push   si

	push   ds

	lds    bx, serbr

	mov    ax, word ptr es:[si]
	mov    word ptr [bx + 2], ax

	mov    ax, word ptr es:[si+2]
	mov    word ptr [bx + 4], ax

	pop    ds

	xor    bx, bx			    ; bx = count hit

	lds    di, pattern
	mov    ax, word ptr es:[si + 4]     ; prva cetiri bajta su br.ser.

	cmp    al, 0feh 		    ; ako je kraj baze 0feh
	je     krajFP

	add    si, 4			    ; preskoci rbk

	mov    cx, 6

p1:	mov    ax, word ptr es:[si]
	mov    dx, word ptr [di]

	or     ax, ax
	jz     p44

	and    dx, ax

	; xor	 dx, ax

	jz     p44

	call   CntWord

p44:	add    si, 2
	add    di, 2

	loop   p1
	jmp    kraj

krajFP: mov    ax, 0feh

kraj:	pop    si
	add    si, 16
	pop    ds
	inc    brojac

	ret

CheckList1 ENDP

WrCount PROC NEAR

	push   ds
	push   ax
	push   cx
	push   dx
	push   di

	; upis broja pogodaka
	push   ds

	lds    di, serbr
	mov    byte ptr [di], bl

	pop    ds

	mov    ah, 40h
	mov    bx, fhandle
	mov    cx, 6
	lds    dx, serbr

	int    21h

	pop    di
        pop    dx
	pop    cx
	pop    ax
        pop    ds

	RET

WrCount ENDP

; CntWord - prebrojava jedinice u DX
CntWord PROC NEAR

	push   cx

	mov    cx, 16

p77:	shl    dx, 1
	jnc    p78

	inc    bx

	or     dx, dx
	jz     p99

p78:	loop   p77

p99:	pop    cx

	RET

CntWord ENDP

ENDWORK

END
