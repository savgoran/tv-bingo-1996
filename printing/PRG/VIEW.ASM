;INCLUDE L:EXTENDA.INC
INCLUDE \CLIPPER\INCLUDE\EXTENDA.INC

CODESEG VCODE

CLpublic <VIEW>

;*******************
; 
; DATUM:  1. 8.1991. 
; 
; NAZIV: View 
; 
; OPIS:  Pregled datoteke za stampanje
; 
; 
;*******************

CLfunc char VIEW <char file1, char file2>

CLcode

	PUSH DS
	PUSH ES
	PUSH SI
	PUSH DI
	PUSH BP

	JMP Begin
;--------------------------------------
UPlus			EQU 1											; Tabela kodova u datoteci
BPlus 		EQU 2
IPlus 		EQU 4

UMinus		EQU 5
BMinus 		EQU 6
IMinus 		EQU 8

Norm			EQU 9

LineMaxScr  EQU 132                             ; Max. duzina linije na ekranu
LineMax     EQU 138                             ; Max. duzina linije
LineNum     EQU 24                              ; Broj linija
TabSize     EQU 8                               ; Velicina Tab-a

;--------------------------------------
Screen 		DB LineNum DUP (LineMax DUP (0))
																; Buffer za ekran
LineLen 		DB LineNum DUP (0)						; Duzine linija
VAddr 		DW ?											; Pocetak video mem.
Header	    DB "part1.prt", 0                   ; Zaglavlje...
Body        DB "part2.prt", 0                   ; Telo...
HeaderLen   DB 0                                ; Duzina hedera
TxtBegH     DW 0                                ; Pocetak teksta u baferu
TxtBegL     DW 0                                
TxtEndH     DW 0                                ; Kraj teksta u baferu
TxtEndL     DW 0                                
FileEofH    DW 0                                ; Kraj datoteke
FileEofL    DW 0
EkrPos      DB 0                                ; Pocetna kolona na ekranu
BufKor      DW ?                                ; Adresa levog coska u baferu
PageLen     DB ?                                ; Velicina strane

ContInd		DB 0											; Nastavak?
FileHandle	DW ?
QuitTast		DB 'Q', 0									; QUIT
PrintTast	DB 'P',0										; <P>

TastTable	DB 25h,0ffh,  'C',0							; <Alt-k>
				DB 2fh,0ffh,  'K',0							; <Alt-v>
				DB 44h, 01h,  'D',0							; <D>
				DB 4eh, 01h,  'N',0							; <N>
				DB 41h, 01h,  'A',0							; <A>
				DB 55h, 01h,  'U',0							; <U>
				DB 48h, 01h,  'H',0							; <H>
				DB 4bh, 01h,  'I',0							; <K>

TableLen 	EQU 16										; Duzina tabele

;--------------------------------------			; Tabela atributa
NormAttr    DB 07h                              ; Normal atribut    (0)
NormUAttr	DB 01h										; Normal Underline  (1)
BoldAttr		DB 0fh										; Bold				  (2)
BoldUAttr	DB 09h										; Bold Underline	  (3)
InvAttr     DB 70h                              ; Inverzan atribut  (4)
InvUAttr		DB 70h										;						  (5)
InvBoldAttr	DB 70h										;						  (7)
InvBUAttr	DB 70h										;						  (8)

ColorTable 	EQU NormAttr								; Pocetak tabele atributa
;--------------------------------------

Begin:
   MOV AX, SEG Screen
   MOV DS, AX        
   MOV ES, AX

	CMP ContInd, 0											; Da li treba samo nastaviti?
	JZ Video
	MOV BX, FileHandle
	MOV ContInd, 0
	JMP Scan

Video:
	MOV ContInd, 0											; Nije nastavak
   
	MOV VAddr, 0b000h                            ; Da li je kolor kartica
   INT 11h                                      ; Read Equipment-List
   AND AX, 0030h
   CMP AX, 30h
   JZ Continue
   MOV VAddr, 0b800h                            ; Kolor kartica

;--------------------------------------
Continue:
	MOV HeaderLen, 0
	MOV AX, 0600h                                ; Brisanje ekrana
   MOV BH, NormAttr
   XOR CX, CX
   MOV DH, LineNum-1
   MOV DL, 79
   INT 10h

   MOV AL, ' '                                  ; Brisanje bafera 
   MOV DI, OFFSET Screen
   MOV CX, LineNum*LineMax
   CLD
REP   STOSB

;--------------------------------------
   XOR AX, AX
   MOV TxtEndH, AX                              ; Resetovanje TxtEnd
   MOV TxtEndL, AX

   push ds
   lds	dx, file1

   ; MOV DX, OFFSET Header			   ; Ucitavanje HEADER.PRT

   MOV AX, 3d00h                                ; Open File (DS:DX->Header)
   INT 21H
   MOV BX, AX

   pop ds					; File Handle

   MOV AX, 1                                    ; Broj linije za ucitavanje

GLH:

   CALL  GetLine
   JC CloseH                                    ; Eof?
   INC HeaderLen
   INC AL


   JMP GLH

CloseH:

   MOV AH, 3eh                                  ; Close Header
   INT 21h
;--------------------------------------
   XOR AX, AX
   MOV TxtEndH, AX                              ; Resetovanje TxtEnd
   MOV TxtEndL, AX
   MOV TxtBegH, AX                              ; Resetovanje TxtBeg
   MOV TxtBegL, AX

   ; MOV DX, OFFSET Body			  ; Ucitavanje BODY.PRT

   push ds
   lds	dx, file2

   MOV AX, 3d00h                                ; Open File (DS:DX->Body)
   INT 21H
   MOV BX, AX                                   ; File Handle

   pop ds

   MOV FileHandle, AX

   MOV AX, 4202h                                ; Odredi velicinu datoteke
   XOR CX, CX
   XOR DX, DX
   INT 21h
   MOV FileEofH, DX                             ; Zapisi za kasnije
   MOV FileEofL, AX

   XOR AH, AH
   MOV AL, HeaderLen                            ; Ucitaj deo tela 
   INC AL
GL:
   CALL  GetLine
   JC Dis
   CMP AL, LineNum
   JZ Dis
   INC AL
   JMP GL

;--------------------------------------         ; Odredjivanje raznih param.
Dis:
   MOV AL, LineNum                              ; Duzina strane je ...
   SUB AL, HeaderLen
   MOV PageLen, AL
   
   MOV AX, OFFSET Screen                        ; Adresa prve linije u baf.
   MOV BufKor, AX
   MOV SI, AX
   
   MOV CL, HeaderLen                            ; Odredi adresu coska za kasnije
   XOR CH, CH
   OR CL, CL                                    ; CL = 0 ?
   JZ Dis2                                      ; prva linija

LNo:                                            ; Odredi poc. linije
   ADD SI, LineMax                              ; Sledeca linija
   LOOP LNo

Dis2:
   MOV BufKor, SI
   CALL  DispScr                                 ; Pokazi sliku
;--------------------------------------

Scan:

   int 3

   MOV AH, 07h                                  ; Skaniranje tasture
   INT 21h              
   XOR AH, AH
   OR AL, AL
   JNE Analiza
   MOV AH, 07h
   INT 21h                                      ; Cekaj drugi taster
   MOV AH, 0FFh 

Analiza:
   CMP AX, 001bh                                ; Exit (ESC)
   JNZ A1
   MOV AH, 3eh                                  ; Close 
   INT 21h
	MOV AX, SEG QuitTast
	MOV BX, OFFSET QuitTast
	MOV ContInd, 0

	JMP Exit

A1:
	CMP AX, 0ff4dh                               ; Right (R ARROW)
   JNZ A2
   CALL  Right
   JMP Scan

A2:
   CMP AX, 0ff4bh                               ; Left (L ARROW)
   JNZ A3
   CALL  Left
   JMP Scan
   
A3:
	CMP AX, 0ff47h                               ; Home (HOME)
   JNZ A4
   MOV EkrPos, 0
   CALL  DispScr
   JMP Scan
   
A4:
	CMP AX, 0ff4fh                               ; End (END)
   JNZ A5
   MOV EkrPos, LineMaxScr-80
   CALL  DispScr
   JMP Scan

A5:
   CMP AX, 0ff50h                               ; <Down>
   JNZ A6
   CALL  SubDown
   JMP Scan

   
A6:
	CMP AX, 0ff51h                               ; <PgDn>
   JNZ A7
   CALL  PageDown
   JMP Scan

A7:
	CMP AX, 0ff48h                               ; <Up>
   JNZ A8
   CALL  SubUp
   JMP Scan

A8:
   CMP AX, 0ff49h                               ; <PgUp>
   JNZ A9
   CALL  PageUp
   JMP Scan
   
A9:
	CMP AX, 0ff84h                               ; <Ctrl-PgUp>
   JNZ A10
   CALL  Bot
   JMP Scan
   
A10:
	CMP AX, 0ff76h                               ; <Ctrl-PgDn>
   JNZ A11
   CALL  Eot
   JMP Scan

A11:
	CMP AX, 00009h                               ; Tab (TAB)
   JNZ A12
   MOV CX, TabSize
LoopTab:
   CMP EkrPos, LineMaxScr-80
   JAE ExTab
   INC EkrPos
   LOOP LoopTab
ExTab:
   CALL  DispScr
   JMP Scan
   
A12:
	CMP AX, 0ff0fh                               ; <Shift-Tab>
   JNZ A13
   MOV CX, TabSize
LoopTab2:
   CMP EkrPos, 0
   JBE ExTab
   DEC EkrPos
   LOOP LoopTab2
   JMP ExTab

A13:
   CMP AX, 0050h		                              ; Exit (PRINT)
   JZ Prt
   CMP AX, 0070h		            
   JZ Prt
	JMP A14

Prt:
   MOV AH, 3eh                                  ; Close 
   INT 21h
	MOV AX, SEG PrintTast
	MOV BX, OFFSET PrintTast
	MOV ContInd, 0

	JMP Exit

A14:
	OR AH, AH
	JNZ ScanTable

	MOV AH, 01h												; Zbog pretrazivanja
	CMP AL, 'Z'												; Pretvori u veliko slovo
	JBE ScanTable
	SUB AL, 'a' - 'A'

ScanTable:
	MOV ContInd, 1
	PUSH DS
	POP ES
	LEA DI, TastTable
	MOV CX, TableLen
	CLD
REPNE SCASW													; Trazi
	JNZ NoFoundTast
	MOV AX, ES												; Kod tastera
	MOV BX, DI
	JMP Exit

NoFoundTast:
   JMP Scan

;--------------------------------------
Exit:
	POP BP
	POP DI
	POP SI
	POP ES
	POP DS
CLret AX BX 

;--------------------------------------

;--------------------------------------

WORKFUNCS

;*******************
; 
; DATUM: 24. 7.1991. 
; 
; NAZIV: DispScr
; 
; OPIS:  Ispisivanje ekrana
; 
; 
;*******************

DispScr PROC NEAR
   
   MOV CX, 24
DLine:
   CALL DispLine
   LOOP DLine
   RET

DispScr ENDP


;*******************
; 
; DATUM: 24. 7.1991. 
; 
; NAZIV: GetLine
; 
; OPIS:  Uzima liniju broj AX; BX=File Handle; pocev od TxtEnd pozicije u dat.
;        Ako je na izlazu C, doslo je do kraja datoteke.
; 
; 
;*******************

GetLine PROC NEAR

   PUSH BP
   PUSH AX
   PUSH AX                                      ; Sacuvaj broj linije

   MOV AX, 4200h                                ; FSeek od pocetka dat.
   MOV CX, TxtEndH                              ; TxtEnd => CXdx
   MOV DX, TxtEndL
   INT 21h

   POP AX                                       ; Vrati broj linije
   MOV CX, AX
   MOV BP, AX
   DEC BP                                       ; Jer prvo ide LineLen[0]

   MOV DX, OFFSET Screen                        ; DS:DX -> Screen...
   DEC CX
   JZ ReadL                                     ; Ucitava se prva linija

L2No:                                           ; Odredi adr. poc. linije
   ADD DX, LineMax                              ; Sledeca linija
   LOOP L2No

ReadL:
   MOV DI, DX                                   ; Za kasnije...

   MOV AH, 3fh                                  ; Read
   MOV CX, LineMax                              ; Cita se cela linija
   INT 21h                                      ; Citaj 
   OR AX, AX
   JZ EofGL                                     ; Eof()

	MOV SI, AX												; Sacuvaj ucitanu duzinu linije

   PUSH DS
   POP ES                                       ; ES:DI -> pocetak linije
   MOV DX, DI
   MOV CX, AX                              		; Trazenje <CR>
   CLD
   MOV AL, 13
REPNE SCASB                                     ; Trazi!
   JZ Found

	MOV AX, SI                                   ; Nema <CR>!
   MOV LineLen[BP], AL
	PUSH AX
	DEC AL
	JMP Clean

Found:                                          ; Postoji <CR>
   MOV AX, DI
   SUB AX, DX                                   ; Duzina linije
   INC AL
   MOV LineLen[BP], AL
   PUSH AX

Clean:
   MOV CX, LineMax
   SUB CL, AL                                   ; Koliko je do kraja linije?
   ADD CL, 2
   DEC DI                                       ; Ciscenje ostatka linije
   MOV AL, ' '
REP STOSB

   POP AX                                       ; Duzina linije
   ADD TxtEndL, AX                              ; Novi TXT END
   ADC TxtEndH, 0
   CLC                                          ; Nije Eof
   JMP ExGl

EofGL:
   MOV CX, LineMax                              ; Ocisti zadnju liniju
   MOV AL, ' '
REP STOSB
   STC                                          ; EOF indikator

ExGL:
   POP AX
   POP BP
   RET
GetLine ENDP


;*******************
; 
; DATUM: 24. 7.1991. 
; 
; NAZIV: ADown
; 
; OPIS:  Pomeranje za liniju dole, ako se ne skroluje, bice C
; 
; 
;*******************

ADown PROC NEAR
   
   MOV AX, FileEofL                             ; Eof?
   SUB AX, TxtEndL
   MOV DX, AX
   MOV AX, FileEofH
   SBB AX, TxtEndH
   OR AX, DX
   JA ConAD
   
   JMP FinishScr

ConAD:
   XOR AH, AH                                   ; TxtBeg = TxtBeg + Len [hed]
   MOV AL, HeaderLen
   MOV BP, AX
   MOV AL, LineLen[BP]
   ADD TxtBegL, AX
   ADC TxtBegH, 0

   PUSH DS                                      ; Skrol bafera
   POP ES                                       ; DS == ES = SEG (bafer)
   LEA DI, LineLen[BP]									; !!!
   MOV SI, DI
   INC SI                                       ; [SI] --> [DI]
   MOV CL, PageLen
   XOR CH, CH
REP MOVSB

   MOV DI, BufKor                               ; ES:DI -> cosak
   MOV SI, DI
   ADD SI, LineMax                              ; DS:SI -> na sledeci red
	MOV CX, OFFSET Screen + (LineNum * LineMax)
	SUB CX, SI
   CLD
REP MOVSB                                       ; Pomeri

G24:
   MOV AX, 24                                   ; Uzmi zadnju liniju
   CALL  GetLine
   JNC Finish                                   ; Nije EOF

   CLC                                          
   JMP Finish

FinishScr:
   STC                                          ; Nova lin. nije prihvacena

Finish:
   RET
ADown ENDP


;*******************
; 
; DATUM: 26. 7.1991. 
; 
; NAZIV: PageDown
; 
; OPIS:  Strana dole
; 
; 
;*******************

PageDown PROC NEAR
   
   MOV CL, PageLen                              ; Koliko linija?
   XOR CH, CH
PD:
   PUSH CX
   CALL  ADown
   POP CX
   LOOP PD

   CALL  DispScr
   RET

PageDown ENDP



;*******************
; 
; DATUM: 26. 7.1991. 
; 
; NAZIV: SubDown
; 
; OPIS:  Red dole
; 
; 
;*******************

SubDown PROC NEAR

   CALL  ADown
   JC NoScr                                     ; Kraj datoteke

   PUSH BX                                      ; Sacuvaj BX = File Handle
   MOV AX, 0601h                                ; Scroll up 1 line
   MOV BH, NormAttr
   MOV CH, HeaderLen
   XOR CL, CL
   MOV DX, 0174fh
   INT 10h
   POP BX                                       ; Vrati File Handle

   MOV CX, LineNum
   CALL DispLine

NoScr:
   RET
SubDown ENDP

;*******************
; 
; DATUM: 26. 7.1991. 
; 
; NAZIV: SubUp
; 
; OPIS:  Red gore
; 
; 
;*******************

SubUp PROC NEAR

   CALL  AUp
   JC NoScr2                                    ; Pocetak datoteke

   PUSH BX                                      ; Sacuvaj BX = File Handle
   MOV AX, 0701h                                ; Scroll down 1 line
   MOV BH, NormAttr
   MOV CH, HeaderLen
   XOR CL, CL
   MOV DX, 0174fh
   INT 10h
   POP BX                                       ; Vrati File Handle

   MOV CL, HeaderLen
   INC CL
   XOR CH, CH
   CALL DispLine

NoScr2:
   RET
SubUp ENDP


;*******************
; 
; DATUM: 24. 7.1991. 
; 
; NAZIV: AUp
; 
; OPIS:  Pomeranje za liniju gore, ako se ne skroluje, bice C
; 
; 
;*******************

AUp PROC NEAR
   
   MOV AX, TxtBegL                              ; Da li je BOF?
   OR AX, TxtBegH
   JZ Bof
   
   MOV AL, LineLen[LineNum-1]                   ; Duzina zadnje linije
   XOR AH, AH
   SUB TxtEndL, AX                              ; TxtEnd = TxtEnd - Len[LineNum]
   SBB TxtEndH, 0

   PUSH DS                                      ; Skrol bafera
   POP ES                                       ; DS == ES = SEG (bafer)
   LEA DI, LineLen[LineNum-1]							; !!!
   MOV SI, DI
   DEC SI                                       ; [SI] --> [DI]
   MOV CL, PageLen
   DEC CL
   XOR CH, CH
   STD                                          ; Pomeranje unazad 
REP MOVSB

   LEA DI, Screen[LineNum*LineMax-1]            ; ES:DI -> zadnji simbol
   MOV SI, DI
   SUB SI, LineMax                              ; DS:SI -> na prethodni red
   MOV CX, SI                                   ; Koliko treba pomeriti?
   SUB CX, BufKor
   INC CX
   STD                                          ; Unazad...
REP MOVSB                                       ; Pomeri

   CALL  GetPLine                                ; Uzmi pret. liniju
   JMP ExitAU

Bof:                                            ; BOF
   STC

ExitAU:
   RET

AUp ENDP


;*******************
; 
; DATUM: 26. 7.1991. 
; 
; NAZIV: GetPLine
; 
; OPIS:  Uzimanje prve linije
; 
; 
;*******************

GetPLine PROC NEAR

   MOV CX, TxtBegH
   MOV DX, TxtBegL
   SUB DX, LineMax                              ; -LineMax
   SBB CX, 0
   JNS OKMove                                   ; Pomeranje >= 0

   XOR CX, CX
   XOR DX, DX
   MOV AX, 4200h                                ; FSeek na pocetak dat.
   INT 21h

   MOV CX, TxtBegL                              ; Koliko treba ucitati?
   MOV DX, BufKor                               ; DS:DX -> Kor
   MOV AH, 3fh                                  ; Read
   INT 21h                                      ; Citaj 
   JMP Fnd

OKMove:
   MOV AX, 4200h                                ; FSeek od pocetka dat.
   INT 21h

   MOV DX, BufKor                               ; DS:DX -> Kor
   MOV AH, 3fh                                  ; Read
   MOV CX, LineMax                              ; Cita se cela linija
   INT 21h                                      ; Citaj 

Fnd:
   MOV SI, BufKor                               ; SI -> Kraj linije
   ADD SI, LineMax-1
   MOV CL, LineMax                              ; Trazenje <CR>
   MOV AL, 13
PT:
   CMP AL, [SI]                                 ; Da li je <CR> ?
   JZ Found1                                    ; Nadjen prvi <CR>
   DEC CL
   DEC SI
   JMP PT

Found1:                                          ; Postoji <CR>
   XOR CH, CH
L2:   
   DEC CL
   OR CL, CL                                    ; Da li je pocetak reda?
   JZ Fou2
   DEC SI
   CMP [SI], AL
   JZ Fou
   INC CH
   JMP L2

Fou:
   INC SI
   INC SI
   DEC CH

Fou2:
   PUSH DS                                      ; Pomeri na pocetak
   POP ES
   MOV CL, CH
   XOR CH, CH
   MOV DI, BufKor
   CLD
   PUSH CX                                      ; Sacuvaj duzinu
REP MOVSB
   
   MOV DL, HeaderLen
   XOR DH, DH
   MOV BP, DX
   POP AX
   ADD AL, 2                                    ; + <CR><LF>
   MOV LineLen[BP], AL
   PUSH AX

   MOV CX, LineMax
   SUB CL, AL                                   ; Koliko je do kraja linije?
   ADD CL, 2                                    ; Ciscenje ostatka linije
   MOV AL, ' '
REP STOSB

   POP AX                                       ; Duzina linije
   SUB TxtBegL, AX                              ; Novi TXT BEG
   SBB TxtBegH, 0

   RET

GetPLine ENDP

;*******************
; 
; DATUM: 26. 7.1991. 
; 
; NAZIV: PageUp
; 
; OPIS:  Strana gore
; 
; 
;*******************

PageUp PROC NEAR
   
   MOV CL, PageLen                              ; Koliko linija?
   XOR CH, CH
Pu:
   PUSH CX
   CALL  AUp
   POP CX
   LOOP Pu

   CALL  DispScr
   RET

PageUp ENDP


;*******************
; 
; DATUM: 26. 7.1991. 
; 
; NAZIV: BoT
; 
; OPIS:  Pocetak teksta
; 
; 
;*******************

BoT PROC NEAR

   XOR AX, AX
   MOV TxtEndH, AX                              ; Resetovanje TxtEnd
   MOV TxtEndL, AX
   MOV TxtBegH, AX                              ; Resetovanje TxtBeg
   MOV TxtBegL, AX

   MOV AX, 4200h                                ; Seek na pocetak
   XOR CX, CX
   XOR DX, DX
   INT 21h

   XOR AH, AH
   MOV AL, HeaderLen                            ; Ucitaj deo tela 
   INC AL
GL1:
   CALL  GetLine
   JC Dis1
   CMP AL, LineNum
   JZ Dis1
   INC AL
   JMP GL1

Dis1:
   CALL  DispScr
   RET

BoT ENDP


;*******************
; 
; DATUM: 26. 7.1991. 
; 
; NAZIV: EoT
; 
; OPIS:  Kraj teksta
; 
; 
;*******************

EoT PROC NEAR

   MOV AX, 4202h                                ; Seek na kraj - LineMax*LineNum
   MOV CX, 0ffffh
   MOV DX, -LineMax*LineNum-2
   INT 21h

   OR DX, DX                                    ; Da nije pokazivac pre pocetka?
   JL AD

   MOV TxtEndH, DX                              ; Nova vrednost 
   MOV TxtEndL, AX 

SmallRead:
   MOV AH, 3fh                                  ; Citaj...
   MOV CX, 1                                    ; 1 bajt...
   MOV DX, BufKor                               ; U prvi red
   INT 21h

   INC TxtEndL                                  ; TxtEnd + 1
   ADC TxtEndH, 0

   MOV SI, DX
   CMP BYTE PTR [SI], 0ah                       ; Da li je <LF>?
   JNZ SmallRead

;---
   MOV AX, 4201h
   MOV CX, 0
   MOV DX, 0
   INT 21h
;---

   MOV AX, TxtEndH
   MOV TxtBegH, AX                              ; Resetovanje TxtBeg
   MOV AX, TxtEndL
   MOV TxtBegL, AX                              ; Resetovanje TxtBeg

   XOR AH, AH
   MOV AL, HeaderLen                            ; Ucitaj deo tela 
   INC AL
GL3:
   CALL  GetLine
   JC Dis3
   CMP AL, LineNum
   JZ AD
   INC AL
   JMP GL3

AD:
   CALL  ADown
   JNC AD

Dis3:
   CALL  DispScr
   RET

EoT ENDP


;*******************
; 
; DATUM: 29. 7.1991. 
; 
; NAZIV: Right
; 
; OPIS:  Desno za 1 simbol
; 
; 
;*******************

Right PROC NEAR

   CMP EkrPos, LineMaxScr-80
   JAE RightEx
   INC EkrPos
   CALL  DispScr

RightEx:
   RET
Right ENDP


;*******************
; 
; DATUM: 31. 7.1991. 
; 
; NAZIV: Attr
; 
; OPIS:  Na osnovu simbola u AH, menja atribut u AL.
; 
; 
;*******************

Attr PROC NEAR

	CMP AH, IPlus											; Da li je PLUS?
	JA NoPlus
	OR AL, AH												; Setuj odgovarajuci atribut
	RET

NoPlus:
	CMP AH, IMinus											; Da li je MINUS?
	JA NoMinus
	SUB AH, IPlus
	NOT AH
	AND AL, AH												; Resetuj odgovarajuci atr.
	RET

NoMinus:
	CMP AH, Norm											; NORMAL?
	JNZ NoNorm
	XOR AL, AL												; Atr = 0
	RET

NoNorm:

	RET
Attr ENDP

;*******************
; 
; DATUM: 22. 7.1991. 
; 
; NAZIV: DispLine
; 
; OPIS:  Ispisuje liniju broj CX
; 
; 
;*******************

DispLine PROC NEAR

	PUSH BX
	MOV BX, OFFSET ColorTable									; BX -> ColorTable
   PUSH CX
   MOV AH, CL												; AH = Broj reda

   MOV ES, VAddr                                ; ES:DI -> Video
   MOV DI, 0

   MOV SI, OFFSET Screen                        ; DS:SI -> Screen...
   DEC CX
   JZ Disp                            

LineNo:                                         ; Odredi poc. linije
   ADD SI, LineMax                              ; Sledeca linija
   ADD DI, 160                                  ; Simboli+atributi
   LOOP LineNo

Disp:
   MOV AL, 4		                              ; INVERT
   CMP AH, HeaderLen                            ; Da li treba invert?
   JLE Sym80
   XOR AL, AL												; NORMAL
Sym80:
	MOV CL, 0   											; Prvi simbol koji se stampa?

L1:
	MOV AH, [SI]											; Uzmi simbol
	CMP AH, 10												; 10 prvih su kontrolni
	JA NoCtrl
	CALL  Attr												; Analiziraj atribut
	INC SI
	JMP L1
NoCtrl:
	CMP CL, EkrPos											; CL = EkrPos ?
	JZ BAgW 
	INC SI
	INC CL
	JMP L1

BAgW:
   MOV CL, 80                                   ; Kopira se 80 simbola
AgW:
	MOV AH, [SI]  											; Uzmi simbol
	CMP AH, 10												; Da nije kontrolni?
	JA Move
	CALL  Attr
	INC SI
	JMP AgW
Move:
	MOV ES:[DI], AH										; Upisi simbol
	INC DI
	PUSH AX
	XLAT ColorTable										; Nadji odgovarajuci atr.
	MOV ES:[DI], AL										; Upisi atribut
	POP AX
	INC DI
	INC SI
   LOOP AgW

   POP CX
	POP BX

   RET
DispLine ENDP

;*******************
; 
; DATUM: 29. 7.1991. 
; 
; NAZIV: Left
; 
; OPIS:  Levo za 1 simbol
; 
; 
;*******************

Left PROC NEAR

   CMP EkrPos, 0
   JBE LeftEx
   DEC EkrPos
   CALL  DispScr
LeftEx:
   RET

Left ENDP

	ENDWORK
   
   END
