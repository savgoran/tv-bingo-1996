NAME XMS30
INCLUDE \CLIP53\INCLUDE\EXTENDA.INC

.MODEL SMALL
; .286

ext_mem_move STRUC
     xms_length     DD	   ?
     source_handle  DW	   ?
     source_offset  DD	   ?
     dest_handle    DW	   ?
     dest_offset    DD	   ?
ext_mem_move ENDS

.DATA

xms_control  DD     0		; adresa XMS API funkcije
_dos_seg     DW     0		; segment u konvencionalnoj memoriji
xms_offset   DD     0		; 32-bitni ofset u XMS memoriji
xms_handle   DW     0
; xms_move     ext_mem_move	  <0,0,0,0,0>

.CODE

CLpublic <_is_xms, _xms_api, _query_xms, _alloc_xms, _free_xms, _info_xms, _read_xms, _write_xms>
CLpublic <_dos_alloc, _dos_free, _f2xms, _get_seg>

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

	sub	sp, 256
	call	[xms_control]
	add	sp, 256

CLret AX

CLFunc void _query_xms <char freedata>

CLcode

	mov	ah, 88h

	sub	sp, 256
	call	[xms_control]
	add	sp, 256

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

	sub	sp, 256
	call	[xms_control]
	add	sp, 256

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

	sub	sp, 256
	call	[xms_control]
	add	sp, 256

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

	sub	sp, 256
	call	[xms_control]
	add	sp, 256

	db	66h, 52h
	pop	ax
	pop	bx

CLret BX AX

; dx = numpage
CLFunc log _read_xms <>

CLcode

       jmp	_read_start

; -----------------------------------------

xms_move     ext_mem_move	<0,0,0,0,0>

; -----------------------------------------       

_read_start:
       mov	ax, dx
       mov	bx, 8000h
       mul	bx		; dx:ax = ax * bx
				; offset u XMS-u

       mov	word ptr xms_move.[source_offset], ax
       mov	word ptr xms_move.[source_offset + 2], dx

       mov	ax, xms_handle
       mov	word ptr xms_move.[source_handle], ax

       mov	ax, 8000h
       mov	word ptr xms_move.[xms_length], ax
       xor	ax, ax
       mov	word ptr xms_move.[xms_length + 2], ax

       mov	word ptr xms_move.[dest_handle], ax
       xor	ax, ax
       mov	word ptr xms_move.[dest_offset], ax
       mov	ax, _dos_seg
       mov	word ptr xms_move.[dest_offset + 2], ax

       push	si

       mov	ah, 0bh
       mov	si, OFFSET xms_move

; zasto ovde da ne bude mov bx, SEG xms_move
       ; mov	  bx, ss
       ; mov	  bx, SEG xms_move
       ; mov	  ds, bx

       sub	sp, 256

       call    [xms_control]

       add	sp, 256

       pop     si

CLret ax

; dx = numpage
CLFunc log _write_xms <>

CLcode

       jmp	_write_start

; -----------------------------------------

xms_move     ext_mem_move	<0,0,0,0,0>

; -----------------------------------------       

_write_start:
       mov	ax, dx		; numpage
       mov	bx, 8000h
       mul	bx		; dx:ax = ax * bx
				; offset u XMS-u

       mov	word ptr xms_move.[dest_offset], ax
       mov	word ptr xms_move.[dest_offset + 2], dx

       mov	ax, xms_handle
       mov      word ptr xms_move.[dest_handle], ax

       mov	ax, 8000h
       mov	word ptr xms_move.[xms_length], ax
       xor	ax, ax
       mov	word ptr xms_move.[xms_length + 2], ax

       mov	word ptr xms_move.[source_handle], ax
       mov	word ptr xms_move.[source_offset], ax
       mov	ax, _dos_seg
       mov	word ptr xms_move.[source_offset + 2], ax

       push	si

       mov  ah, 0bh
       mov  si, OFFSET xms_move
       ; mov  bx, SEG xms_move
       ; mov  bx, ss
       ; mov  ds, bx

       sub  sp, 256
       call    [xms_control]
       add  sp, 256

       pop     si

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

CLFunc int _get_seg <>

CLcode

	mov	ax, _dos_seg

CLret ax

END
