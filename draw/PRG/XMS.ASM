NAME XMS30
INCLUDE \CLIP53\INCLUDE\EXTENDA.INC

CODESEG XMS30
DATASEG

; .MODEL SMALL
; .286

CLpublic <_is_xms, _xms_api, _query_xms, _alloc_xms, _free_xms, _info_xms, _read_xms, _write_xms>
CLpublic <_dos_alloc, _dos_free, _f2xms, _xms2f, _get_seg>

CLstatic <long xms_control 0>
CLstatic <long xms_offset 0>
CLstatic <int _dos_seg 0>
CLstatic <int xms_handle 0>
CLstatic <byte ASCIIZ <<16 DUP(0)>>, cptr xms_move ASCIIZ>

CLfunc log _is_xms

CLcode

	mov	ax, 4300h

	int	2fh

	cmp	al, 80h
	jne	l1

	mov	ax, 1
	jmp	l2

l1:	xor	ax, ax

l2:

CLret	AX

CLFunc int _xms_api

CLcode

	push	es

	mov	ax, 4310h
	int	2fh
	mov	word ptr [xms_control], bx
	mov	word ptr [xms_control + 2], es

	pop	es

	mov	ah, 0

	; sub	  sp, 256
	call	[xms_control]
	; add	  sp, 256

CLret AX

CLFunc void _query_xms <char freedata>

CLcode

	mov	ah, 88h

	; sub	  sp, 256
	call	[xms_control]
	; add	  sp, 256

	push	ds
	lds	bx, freedata
	db	66h, 50h
	pop	cx
	mov	word ptr [bx], cx	; size of largest free ext.mem.blk KB
	pop	cx
	mov	word ptr [bx+2], cx

	db	66h, 52h
	pop	cx
	mov	word ptr [bx+4], cx	; total amount of free ext.mem. KB
	pop	cx
	mov	word ptr [bx+6], cx

	pop	ds

CLret

CLFunc int _alloc_xms <long nKB>

CLcode

	mov	ah, 89h
	; mov	  edx, nKB
	db	66h, 8bh, 56h, 0fah

	; sub	  sp, 256
	call	[xms_control]
	; add	  sp, 256

	mov	xms_handle, dx

	cmp	ax, 1
	je	l200

	xor	ax, ax
	mov	al, bl

l200:

CLret AX

CLFunc int _free_xms <>

CLcode

	mov	ah, 0Ah
	mov	dx, xms_handle

	; sub	  sp, 256
	call	[xms_control]
	; add	  sp, 256

	cmp	ax, 1
	je	l100

	xor	ax, ax
	mov	al, bl

l100:

CLret AX

CLFunc long _info_xms <>

CLcode

	mov	ah, 8Eh
	mov	dx, xms_handle

	; sub	  sp, 256
	call	[xms_control]
	; add	  sp, 256

	db	66h, 52h
	pop	ax
	pop	bx

CLret BX AX

; dx = numpage
CLFunc log _read_xms <>

CLcode

       push	ds
       push	si

       mov	ax, dx
       mov	bx, 8000h
       mul	bx		; dx:ax = ax * bx
				; offset u XMS-u

       lds	si, xms_move

       mov	word ptr [si + 6], ax
       mov	word ptr [si + 8], dx

       mov	ax, xms_handle
       mov	word ptr [si + 4], ax

       mov	ax, 8000h
       mov	word ptr [si], ax
       xor	ax, ax
       mov	word ptr [si + 2], ax

       mov	word ptr [si + 10], ax
       xor	ax, ax
       mov	word ptr [si + 12], ax
       mov	ax, _dos_seg
       mov	word ptr [si + 14], ax

       push	ds
       push	si

       mov	ah, 0bh
       lds	si, xms_move

       call	[xms_control]

       pop	si
       pop	ds

       pop	si
       pop	ds

CLret ax

; dx = numpage
CLFunc log _write_xms <>

CLcode

       push	ds
       push	si

       mov	ax, dx		; numpage
       mov	bx, 8000h
       mul	bx		; dx:ax = ax * bx
				; offset u XMS-u

       lds	si, xms_move

       mov	word ptr [si + 12], ax
       mov	word ptr [si + 14], dx

       mov	ax, xms_handle
       mov	word ptr [si + 10], ax

       mov	ax, 8000h
       mov	word ptr [si], ax
       xor	ax, ax
       mov	word ptr [si + 2], ax

       mov	word ptr [si + 4], ax
       mov	word ptr [si + 6], ax
       mov	ax, _dos_seg
       mov	word ptr [si + 8], ax

       push	ds
       push	si

       mov	ah, 0bh
       lds	si, xms_move

       call	[xms_control]

       pop	si
       pop	ds

       pop	si
       pop	ds

CLret ax

CLFunc log _dos_alloc

CLcode

	mov	ah, 48h
	mov	bx, 800h
	int	21h

	jnc	l3

	xor	ax, ax
	jmp	l4

l3:	mov	[_dos_seg], ax
	mov	ax, 1

l4:

CLret ax

CLFunc void _dos_free <>

CLcode

	push	es

	mov	ah, 49h
	mov	bx, _dos_seg
	mov	es, bx
	int	21h

	pop	es

CLret

CLFunc void _f2xms <int nhandle, int cnt, int numhandle>

CLcode

	push	ds

	mov	ah, 3fh
	mov	bx, nhandle
	mov	cx, cnt
	mov	dx, _dos_seg
	mov	ds, dx
	xor	dx, dx
	int	21h

	pop	ds

	mov	dx, numhandle
	call	_write_xms

CLret

CLFunc void _xms2f <int nhandle, int cnt, int numhandle>

CLcode

	mov	dx, numhandle
	call	_read_xms

	push	ds

	mov	ah, 40h
	mov	bx, nhandle
	mov	cx, cnt
	mov	dx, _dos_seg
	mov	ds, dx
	xor	dx, dx
	int	21h

	pop	ds


CLret

CLFunc int _get_seg <>

CLcode

	mov	ax, _dos_seg

CLret ax

END
