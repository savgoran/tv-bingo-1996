INCLUDE L:\CLIPPER5\EXTENDA.INC

BUFF_SIZE EQU 10240

CLextern <far _storni>
CLpublic <ZIP>


;*******************
; 
; DATUM: 12. 6.1992. 
; 
; NAZIV: Zip (@InPtr, InEof, @OutPtr, InBuffer, OutBuffer)
; 
; OPIS:  Kompresija 
; 
; 
;*******************


CLfunc char ZIP <int InPtr, int OutPtr, int InEof, char InBuffer, char OutBuffer>

CLcode
   JMP Begin

; ---------------------------------
Command        DB "C", 0
String         DB 130 DUP (0)
CxReg          DW 0
Mode           DB 0
; ---------------------------------

Begin:
   PUSH DS
   PUSH ES

   LDS BX, InBuffer                 ; DS:BX --> InBuffer
   LES DX, OutBuffer                ; ES:DX --> OutBuffer

   MOV SI, InPtr                    ; InPtr -> SI
   MOV DI, OutPtr                   ; OutPtr -> DI

   MOV AH, Mode                     ; Stari parametri: MODE
   MOV CX, CxReg                    ; ...pokazivac na STRING

   CMP AH, 3                        ; Ulaz 3?
   JZ Eof

   CMP AH, 4                        ; Ulaz 4?
   JZ In_4
   
   CMP AH, 5                        ; Ulaz 5?
   JNZ Jump6
   JMP Mode1_0

Jump6:
   CMP AH, 6                        ; Ulaz 6?
   JNZ Cikl
   JMP Mode2_0

Cikl:                               ; --- GETCH ----
   CALL GetC                        ; procitaj simbol
   JNC Mode0                        ; Nije kraj bloka ili EOF?

   CMP Command, "E"                 ; Da li je EOF?
   JZ Eof
   JMP ExitR

Eof:
   MOV AH, 3
   CALL Commit                      ; String --> OutBuffer
   JNC NormExit
   JMP ExitW                        ; WRITE

NormExit:
   MOV AH, 0                        ; Mode 0, za sledeci pocetak
   JMP Exit

Mode0:                              ; --- <01> A ---
   CMP AH, 0                        ; Mode 0?
   JNZ Mode1
                  
   MOV String[1], 1                 ; Upisi 00000001
   MOV AL, DS:[SI + BX - 1]         ; Uzmi prvi simbol...
   MOV String[2], AL
   MOV CX, 2            
   MOV AH, 1                        ; --> Mode 1
   JMP Cikl

Mode1:                              ; --- <03> ABC ---
   CMP AH, 1                        ; Mode 1?
   JNZ Mode2
                  
   MOV AL, DS:[SI + BX - 1]
   XCHG CX, BX
   CMP AL, String[BX]               ; Ch == previous?
   XCHG CX, BX                      
   JZ Mode1_2

   CMP String[1], 01111111b         ; Da li je bafer pun?
   JZ Mode1_0

   INC String[1]                    ; Nije, upisi novi simbol...
   INC CX
   XCHG CX, BX
   MOV String[BX], AL
   XCHG CX, BX
   JMP Cikl

Mode1_2:                            ; --- <03> ABCC ---
   CMP CX, 2                        ; Da li u stringu ima samo 1 simbol?
   JZ One

In_4:
   MOV AH, 4
   CALL Commit                      ; PutS(String)
   JC ExitW
   MOV AH, 0                        ; Mode 0
   JMP Mode0

One:
   MOV String[1], 10000010b         ; Upisi i simbole...
   MOV AL, DS:[SI+BX-1]
   MOV String[2], AL
   MOV CX, 2
   MOV AH, 2                        ; Mode 2
   JMP Cikl

Mode1_0:
   MOV AH, 5
   CALL Commit
   JC ExitW
   MOV AH, 0                        ; Mode 0
   JMP Mode0

Mode2:                              ; --- <03> A ---
   MOV AL, DS:[SI+BX-1]             ; Ch == previous?
   CMP AL, String[2]
   JNZ Mode2_0

   CMP String[1], 10000000b + 127   ; Da li je bafer pun?
   JZ Mode2_0

   INC String[1]
   JMP Cikl

Mode2_0:
   MOV AH, 6
   CALL Commit                      ; Isprazni bafer
   JC ExitW
   MOV AH, 0
   JMP Mode0

ExitR:
   MOV Command, "R"
   JMP Exit

ExitW:
   MOV Command, "W"

Exit:                               ; --- EXIT ---
   MOV CxReg, CX                    ; sacuvaj CX
   MOV Mode, AH                     ; sacuvaj AH

   POP ES
   POP DS

   Ccall _storni <SI, 1>            ; SI -> InPtr
   Ccall _storni <DI, 2>            ; DI -> OutPtr

   MOV AX, SEG Command              ; Vracanje komande
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
                                    
   CMP SI, BUFF_SIZE                ; da li je kraj bloka?
   JGE Read

   CMP SI, InEof                    ; EOF?
   JGE InpEof

OK:
   INC SI                           ; normalno citanje simbola
   MOV AL, DS:[SI+BX-1]
   CLC
   RET

Read:
   MOV Command, "R"
   STC
   RET

InpEof:                             ; Eof
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

   INC DI                           ; upis simbola
   XCHG BX, DX
   MOV ES:[DI+BX-1], AL
   XCHG BX, DX
   RET

PutC ENDP



;*******************
; 
; DATUM:  9. 6.1992. 
; 
; NAZIV: Commit
; 
; OPIS:  PutS (String)
; 
; 
;*******************

Commit PROC NEAR

   CMP CX, 0                        ; Da li uopste ima necega u baferu?
   JNZ Write
   CLC                              ; nema, izadji
   RET

Write:
   PUSH AX

   MOV AX, BUFF_SIZE                ; Da li se ceo string moze upisati? 
   SUB AX, DI
   CMP CX, AX
   JG NoRoom

   PUSH BX

   XOR BX, BX

Again:
   INC BX
   MOV AL, String[BX]
   CALL PutC
   CMP BX, CX
   JNE Again

   MOV CX, 0
   MOV CxReg, CX        

   POP BX
   POP AX
   CLC
   RET

NoRoom:
   MOV CxReg, CX
   MOV Command, "W"
   POP AX
   STC
   RET

Commit ENDP

ENDWORK

END


