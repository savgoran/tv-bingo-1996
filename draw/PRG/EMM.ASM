NAME MYEMM
INCLUDE EXTENDA.INC

CLpublic <EMMPRESENT, EMMAVLPG, EMMTOTPG, EMMUSPG, EMMPGFRM, EMMALLOC, EMMDEALLOC, EMMSTATUS, EMMMAPPG>
CLpublic <MEMTOEMM, EMMTOMEM, F2EMM>

EXTRN __emmInstalled:FAR
EXTRN __emmGetStatus:FAR
EXTRN __emmGetPageFrameSeg:FAR
EXTRN __emmAllocPages:FAR
EXTRN __emmDeAllocPages:FAR
EXTRN __emmMapUnMapPage:FAR
EXTRN __emmGetTotalPageCount:FAR
EXTRN __emmGetAllocPageCount:FAR
EXTRN __emmGetUnAllocPageCount:FAR

CLfunc log EMMPRESENT

CLcode

	call	__emmInstalled
	cmp	ax, 0
	je	l1

	mov	ax, 0
	jmp	kraj

l1:	mov	ax, 1

kraj:

Clret AX

CLfunc int EMMAVLPG

CLcode

	call	__emmGetUnAllocPageCount

Clret DX

CLfunc int EMMTOTPG

CLcode

	call	__emmGetTotalPageCount

Clret DX

CLfunc int EMMUSPG

CLcode

	call	__emmGetAllocPageCount

Clret DX

CLfunc int EMMPGFRM

CLcode

	call	__emmGetPageFrameSeg

Clret BX

CLfunc int EMMALLOC <int pages>

CLcode

	mov	bx, pages
	call	__emmAllocPages

Clret DX

CLfunc int EMMDEALLOC <int handle>

CLcode

	mov	dx, handle
	call	__emmDeAllocPages

Clret DX

CLfunc log EMMSTATUS

CLcode

	call	__emmGetStatus
	cmp	ax, 0
	je	l2

	mov	ax, 0
	jmp	kraj1

l2:	mov	ax, 1

kraj1:

Clret AX

CLfunc int EMMMAPPG <int handle, int LogPage, int PhyPage>

CLcode

        mov     dx, handle
	mov	ax, PhyPage
	mov	bx, LogPage
	mov	ah, 44h
	int	67h
	xor	al, al
	xchg	al, ah
	mov	al, ah
	xor	ah, ah

Clret AX

CLfunc void MEMTOEMM <char sptr, int pageframe, int emmoff, int cnt>

CLcode

	push	ds
        push    es
	push	si
	push	di

	pushf
	cld

	mov	cx, cnt
	mov	ax, pageframe
	mov	es, ax
	mov	di, emmoff
	lds	si, sptr

	repnz	movsb

	popf

	pop	di
	pop	si
	pop	es
	pop	ds

CLret

CLfunc void EMMTOMEM <char sptr, int pageframe, int emmoff, int cnt>

CLcode

	push	ds
        push    es
	push	si
	push	di

	pushf
	cld

	mov	si, emmoff
	mov	cx, cnt
	les	di, sptr
	mov	ax, pageframe
	mov	ds, ax

	repnz	movsb

	popf

	pop	di
	pop	si
	pop	es
	pop	ds

CLret

CLfunc int F2EMM <int fHandle, int nEmmHandle, int nPageFrame, int nEmmPage, int cnt>

CLcode

	push	ds
	push	es
	push	di
	push	si

	mov	dx, nEmmHandle
	mov	bx, nEmmPage
	mov	ax, 4400h
	int	67h

	mov	ah, 3fh
	mov	bx, fHandle
	mov	cx, cnt
	mov	dx, nPageFrame
	mov	ds, dx
	xor	dx, dx

	int	21h

	pop	si
	pop	di
        pop     es
	pop	ds

CLret	AX

END
