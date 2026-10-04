INCLUDE \CLIPPER\INCLUDE\EXTENDA.INC

CLpublic <SAYSCREEN>

;*******************
; 
; DATUM: 22. 6.1991. 
; 
; NAZIV: SayScreen (txt, x, y)
; 
; OPIS:  Ispisivanje teksta TXT na koordinati (X,Y), bez atributa
; 
; 
;*******************

CLfunc void SAYSCREEN <char str, int xcoord, int ycoord>

CLcode
	PUSH ES
	PUSH SI
	PUSH DI
	PUSH DS

   MOV BX, 0b000h                            	; Da li je kolor kartica
   INT 11h                                   	; Read Equipment-List
   AND AX, 0030h
   CMP AX, 30h												; 
   JZ Continue
   MOV BX, 0b800h                            	; Kolor kartica

Continue:	
	MOV ES, BX												; Pocetak video memorije

	MOV AX, ycoord
	ADD AX, AX

	MOV CX, xcoord
	OR CX, CX												; y = 0 ?
	JZ Disp

L1:
	ADD AX, 160
	LOOP L1

Disp:
	MOV DI, AX												; ES:DI -> pocetak
	
	LDS SI, str												; DS:SI --> STR

	MOV BX, 25*160
	CLD

Cikl:	
	MOV AL, [SI]											; Uzmi simbol
	OR AL, AL												; Kraj?
	JZ Exit
	STOSB							
	INC DI													; Idi na sledeci u video-memoriji
	INC SI													; Sledeci simbol
	CMP BX, DI												; Van video memorije
	JE Exit 
	JMP Cikl

Exit:	
	POP DS
	POP DI
	POP SI
	POP ES
Clret 

	END
