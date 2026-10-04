NAME ADLIB
INCLUDE \CLIP53\INCLUDE\EXTENDA.INC

.MODEL SMALL
.286

CLpublic <IsSound>

CLFunc log IsSound

CLcode

      int	3

      mov	ax, 0460h
      call	Wr2Snd
      mov	ax, 0480h
      call	Wr2Snd
      mov	dx, 388h
      in	al, dx
      mov	bl, al		& bl = status1
      mov	ax, 0421h
      mov	cx, 6

      nop
      nop
      nop
      nop

      in	al, dx		& al = status2

      and	bl, 0e0h
      cmp	bl, 0
      jnz	NoSound

      and	al, 0e0h
      cmp	al, 0c0h
      jne	NoSound

      mov	ax, 1
      jmp	kraj

NoSound:
      mov	ax, 0
      jmp	kraj


kraj:

CLret ax

WORKFUNCS

; al = index
; ah = data
Wr2Snd PROC NEAR

CLcode

      push	dx

      mov	dx, 388h
      out	dx, al
      mov	cx, 6
w1:   in	al, dx
      loop	w1
      xchg	ah, al
      mov	dx, 389h
      out	dx, al
      mov	cx, 35
w2:   in	al, dx
      loop	w2

      pop	dx

      ret

Wr2Snd ENDP

END
