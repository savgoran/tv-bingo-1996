NAME SOUND
INCLUDE \CLIP53\INCLUDE\EXTENDA.INC

.MODEL small
.286

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; MACRO DEFINITIONs
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
WAITWRITE               MACRO
LOCAL                   loopWait,endloop
;          Arguments : DX = Status port (BASEADDR+0Ch)
;          Returns   : n/a
;          Destroys  : AL

                        push    cx
                        xor     cx,cx           ; need that for slow SBs !
loopWait:               dec     cx
                        jz      endloop
                        in      al,dx           ; AL = WRITE COMMAND STATUS
                        or      al,al
                        js      loopWait        ; Jump if bit7=1 - writing not allowed
endloop:                pop     cx
ENDM

WAITREAD                MACRO
LOCAL                   loopWait,endloop
;          Arguments : DX = Status port   (normaly BASEADDR+0Eh)
;          Returns   : n/a
;          Destroys  : AL

                        push    cx
                        xor     cx,cx           ; need that for slow SBs !
loopWait:               dec     cx
                        jz      endloop
                        in      al,dx           ; AL = DATA AVAILABLE STATUS
                        or      al,al
                        jns     loopWait        ; Jump if bit7=0 - no data available
endloop:                pop     cx
ENDM

;컴� End of Macrodefinitions 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

.DATA

Base	       DW      0
DataPort       DW      0
ReadData       DW      0
WriteData      DW      0
DataAvailable  DW      0
Reset	       DW      0

SOUNDBUFFER LABEL BYTE
	       DB     32768	dup (0)

.CODE

CLpublic <InitSound, WriteDSP, ReadDSP, WriteMixer, x_shl, x_shr, GetSEG, GetOFF, GetLo, GetHi, LoadSamp, GetSize>
CLpublic <ToPort, FromPort>

CLFunc log InitSound <int poc>

CLcode

      mov	ax, poc
      mov	Base, ax
      mov	ax, Base
      mov	bx, 10h
      mul	bx
      mov	base, ax
      mov	ReadData, ax
      add	ReadData, 20Ah
      mov	WriteData, ax
      add	WriteData, 20Ch
      mov	DataAvailable, ax
      add	DataAvailable, 20Eh
      mov	Reset, ax
      add	Reset, 206h
      mov	DataPort, ax
      add	DataPort, 200h

      mov	dx, Reset
      mov	al, 1
      out	dx, al

      in	al, dx
      in        al, dx
      in        al, dx
      in	al, dx	      ; wait 3 msec

      xor	al, al
      out	dx, al

      mov	dx, DataAvailable
      WAITREAD
      sub	dx, 4
      in	al, dx

      cmp	al, 0aah
      je	l58

l57:  mov	ax, 0
      jmp	l59

l58:  mov	ax, 1
l59:

CLret AX

CLFunc void WriteDSP <int podatak>

CLcode

      mov	dx, WriteData
      WAITWRITE
      mov	ax, podatak
      out	dx, al

CLret

CLFunc int ReadDSP <>

CLcode

      mov	dx, DataAvailable
      WAITREAD
      sub	dx, 4
      in	ax, dx

CLret AX

CLFunc void ToPort <int nPort, int nData>

CLcode

      mov	dx, nPort
      mov	ax, nData
      out	dx, al

CLret

CLFunc int FromPort <int nPort>

CLcode

      mov	dx, nPort
      in	ax, dx

CLret AX

CLFunc int GetSEG <>

CLcode

      mov	ax, ds

CLret AX

CLFunc int GetOFF <>

CLcode

      mov	ax, offset SOUNDBUFFER

CLret AX

CLFunc int x_shr <int nBr, int nCnt>

CLcode

      mov      ax, nBr
      mov      cx, nCnt
      shr      ax, cl

CLret AX

CLFunc int x_shl <int nBr, int nCnt>

CLcode

      mov      ax, nBr
      mov      cx, nCnt
      shl      ax, cl

CLret AX

CLFunc int GetLo <int nBr>

CLcode

       mov     ax, nBr
       xor     ah, ah

CLret AX

CLFunc int GetHi <int nBr>

CLcode

       mov     ax, nBr
       xchg    ah, al
       xor     ah, ah

CLret AX

CLFunc void LoadSamp <int nHandle, int nSize>

CLcode

      push     si

      mov      ah, 3fh
      mov      bx, nHandle
      mov      cx, nSize

      mov      si, offset SOUNDBUFFER

      mov      word ptr [si], cx
      add      si, 2
      mov      dx, si

      int      21h

      pop      si

CLret

CLFunc int GetSize < >

CLcode

      push     si

      mov      si, offset SOUNDBUFFER
      mov      ax, word ptr [si]
      dec      ax

      pop      si

CLret AX

CLFunc void WriteMixer <int reg, int mxdata>

CLcode

      mov      dx, Base
      add      dx, 204h
      mov      ax, reg
      out      dx, al
      inc      dx
      in       al, dx
      mov      ax, mxdata
      out      dx, al

CLret

END
