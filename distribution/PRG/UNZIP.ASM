INCLUDE L:\CLIPPER5\EXTENDA.INC

BUFF_SIZE EQU 10240

CLextern <far _storni>
CLpublic <UNZIP>

;*******************
; 
; DATUM: 12. 6.1992. 
; 
; NAZIV: UnZip (@InPtr, @OutPtr, InEof, InBuffer, OutBuffer)
; 
; OPIS:  Dekompresija 
; 
; 
;*******************

CLfunc char UNZIP <int InPtr, int OutPtr, int InEof, char InBuffer, char OutBuffer>

CLcode
	JMP Begin
; ---------------------------------
Command 		DB "C", 0
Mode 			DB 0
ClReg			DB 0
; ---------------------------------

Begin:
	PUSH DS
	PUSH ES

	LDS BX, InBuffer			; DS:BX --> InBuffer
	LES DX, OutBuffer			; ES:DX --> OutBuffer

	MOV SI, InPtr			; InPtr -> SI
	MOV DI, OutPtr			; OutPtr -> DI

	MOV AH, Mode			; Stari parametri: MODE
	MOV CL, ClReg			; Broj ponavljanja

	CMP AH, 1				; Ulaz 1?
	JZ In_1
	CMP AH, 2				; Ulaz 2?
	JZ In_2
	CMP AH, 3				; Ulaz 3?
	JZ In_3
	CMP AH, 4				; Ulaz 4?
	JZ In_4
	
Cikl:	     				; --- GETCH ---
	MOV AH, 0				; Mode 0
	CALL GetC				; procitaj simbol
	JC Exit				; EOF?

	MOV AL, DS:[SI + BX - 1]	; Uzmi simbol...

	CMP AL, 0				; Da nije kraj?
	MOV Command, "E"			; Kraj!
	JZ Exit

	AND AL, 10000000b			; Da li je oznaka za komprimovanje?
	JNZ Mode2

	MOV CL, DS:[SI + BX - 1]	; Uzmi broj ponavljanja

In_1:
	MOV AH, 1				; Mode 1
	CALL GetC
	JC Exit

In_3:
	MOV AL, DS:[SI + BX - 1]	; Uzmi simbol...
	MOV AH, 3				; Mode 3
	CALL PutC
	JC Exit
	
	DEC CL
	JNZ In_1
	JMP Cikl

Mode2:
	MOV CL, DS:[SI + BX - 1]	; Uzmi broj ponavljanja
	AND CL, 01111111b

In_2:
	MOV AH, 2				; Mode 2
	CALL GetC
	JC Exit

In_4:
	MOV AL, DS:[SI + BX - 1]	; Uzmi simbol...
	MOV AH, 4				; Mode 4
	CALL PutC
	JC Exit

	DEC CL
	JNZ In_4

	JMP Cikl

Exit:					; --- EXIT ---
	MOV ClReg, CL			; sacuvaj CL
	MOV Mode, AH			; sacuvaj AH

	POP ES
	POP DS

	Ccall _storni <SI, 1>		; SI -> InPtr
	Ccall _storni <DI, 2>		; DI -> OutPtr

	MOV AX, SEG Command		; Vracanje komande
	MOV BX, OFFSET Command

CLret AX BX

WORKFUNCS

;*******************
; 
; DATUM:  9. 6.1992. 
; 
; NAZIV: GetC ()
; 
; OPIS:  Cita simbol iz ulaznog bafera u AL, CARY ako je EOF ili kraj bafera
; 
; 
;*******************

GetC PROC NEAR

	CMP SI, BUFF_SIZE				; da li je kraj bloka?
	JGE Read

	CMP SI, InEof				; EOF?
	JGE Eof

OK:
	INC SI    					; normalno citanje simbola
	MOV AL, DS:[SI+BX-1]
	CLC
	RET

Read:
	MOV Command, "R"
	STC
	RET

Eof:						; Eof
	MOV AL, DS:[SI+BX-1]			; "E" samo ako je procitan \0
	CMP AL, 0
	JNZ Read
	MOV Command, "E"
	STC
	RET
							
GetC ENDP


;*******************
; 
; DATUM:  9. 6.1992. 
; 
; NAZIV: PutC ()
; 
; OPIS:  Upisuje AL u izlazni bafer, na poz. DI
; 
; 
;*******************

PutC PROC NEAR

	CMP DI, BUFF_SIZE				; da li je kraj bloka?
	JGE BlkEnd

	INC DI    					; upis simbola
	XCHG BX, DX
	MOV ES:[DI+BX-1], AL
	XCHG BX, DX
	CLC
	RET

BlkEnd:						; Kraj bloka
	MOV Command, "W"
	STC
	RET

PutC ENDP


ENDWORK

END


