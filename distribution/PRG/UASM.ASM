NAME UASM

INCLUDE \CLIPPER\INCLUDE\EXTENDA.INC

CLpublic <PutSer, ExSer>

CLfunc void PutSer <char nlong, int nbyte>

CLcode

	push	ds
	push	si

	lds	si, nlong
	mov	ax, nByte
	xor	ah, ah
	mov	byte ptr ds:[si + 3], al

	pop	si
	pop	ds

CLret

CLfunc int ExSer <char nlong>

CLcode

	push	ds
	push	si

	lds	si, nlong
	mov	al, byte ptr [si + 3]
	xor	ah, ah
	mov	byte ptr ds:[si + 3], 0

	pop	si
	pop	ds

CLret AX

END

