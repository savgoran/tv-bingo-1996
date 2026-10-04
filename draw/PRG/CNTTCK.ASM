PAGE	,132
NAME	CNTTCK

include extenda.inc

CLpublic <CntTicket>

EXTRN	_read_xms:FAR
EXTRN	_get_seg:FAR

; cCntBuff 64 DB 0

CLfunc void CntTicket <char pattern, int emmhandle, int pageframe, char cCntBuff>

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
pnt_in_cntbuf	DW 0
pnt_in_offbuf	DW 0

; ------------------------------

Begin:	mov    currpage, 0
        mov    serrl, 0
	mov    serrh, 0
	mov    pnt_in_cntbuf, 0
	mov	pnt_in_offbuf, 0
	; mov	 ax, pageframe
	call   _get_seg 		; uzima segment adresu DOS-a
	mov    es, ax

Begin1: xor    si, si
	mov    brojac, 0
	call   SwitchPage1

p4:	cmp    brojac, 2048		; stigo do kraja xms strane ?
	je     Begin1

	call   CheckList1
	cmp    ax, 0feh
	je     izlaz
	; cmp	 bx, 0			  ; 0 pogodaka - upis
	; je	 p5
	cmp    bx, 13			; 13 i vise pogodaka - upis
	jl     p4

p5:	call   UpisSerije1

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

	xor    bx, bx			    ; bx = count hit

;	 mov	ax, word ptr es:[si]
;	 mov	serrl, ax

;	 mov	ax, word ptr es:[si+2]
;	 mov	serrh, ax


	mov    ax, word ptr es:[si+2]
	cmp    ah, 0ffh
	je     kraj			    ; neprodat listic

	lds    di, pattern
	mov    ax, word ptr es:[si + 4]     ; prva cetiri bajta su br.ser.

	cmp    al, 0feh 		    ; ako je kraj baze 0feh
	je     krajFP

	add    si, 4			    ; preskoci rbk

	mov    cx, 6

p1:	mov    ax, word ptr es:[si]
	mov    dx, word ptr [di]

	; cmp	 ax, 0

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

UpisSerije1 PROC NEAR

	push   ds
	push   si

	lds    si, cCntBuff			; ds:si = cCntBuff
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

;	cmp    bx, 10
;	jl     p800
;
;	push   ds
;	push   si

;	mov    ax, brojac
;	dec    ax
;	mov    bx, currpage
;	dec    bx
;
;	lds    si, cOffBuff
;	add    si, pnt_in_offbuf
;
;	mov    word ptr [si], ax
;	mov    word ptr [si + 2], bx
;
;	pop    si
;	pop    ds
;
;	add    pnt_in_offbuf, 4
;
;p800:
	RET

UpisSerije1 ENDP

; CntWord - prebrojava jedinice u DX
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

ENDWORK

END
