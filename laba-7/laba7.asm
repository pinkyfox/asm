org 100h
jmp start
 
errorExit macro str                     ;������ ������ ��-�� ������, ��������� ������ � ���������� ������.
    push ax                             ;��������� ������� ax.
    push dx                             ;��������� ������� dx.
 
    mov ah, 09h                         ;\ 
    mov dx, offset str                  ; > ������� ��������� �� ������.   
    int 21h                             ;/
   
    mov ax, 4C01h                       ;��������� ��������� � ����� 1
    int 21h                             ;  
 
    pop dx                              ;��������������� ������� dx.
    pop ax                              ;��������������� ������� ax.
endm      
 
parseFile proc                          ;��������� ����������� ���������� �����.
    pusha                               ;��������� ��������.
   
_read_next:    
    mov ax, 4200h                       ;�������� ������� 0�42 ��� ��������� ��������� � (������ ����� + CX + DX).
    mov bx, [fileHandler]               ;� BX ������� ���������� �����.
    xor cx, cx                          ;�������� CX.
    mov dx, [currentPositionInFile]     ;� DX ������� �������, �� ������� ������������ �����.
    int 21h                             ;��������� �������.    
    jnc _lseek_ok                       ;���� ������� �������� ���������, �� ��������� �� ����� _lseek_ok,
    errorExit msgLSeekError             ;����� ������� ��������� �� ������ � ������� �� ���������.
   
_lseek_ok:
   
    mov ah, 3Fh                         ;������� ������ �����.
    mov cx, 1h                          ;���������� �������� � ���������.
    mov dx, offset charBuffer           ;����� ��� ������ ������������.
    int 21h                             ;
    jnc _read_ok                        ;���� ������� �������� �� �����, �� ��������� �� ����� _read_ok,
    errorExit msgReadError              ;����� ������� ��������� �� ������ � ������� �� ���������.
 
_read_ok:
     
    mov cl, byte ptr [charBuffer]       ;������� �������� ������ � cl.                      
    cmp cl, '?'                         ;���� ��� '?',
    jz _eof                             ;�� ��� ����� �����, ����� ��������� �� ����� _eof.
 
    mov si, word ptr [currentPositionInFile]    ;\
    inc si                                      ; >����������� ������� ������� ������� � �����.
    mov word ptr [currentPositionInFile], si    ;/
     
    cmp cl, ';'                         ;���� � ������ �������� ';', ��
    jz _parsed_ok                       ;��������� �� ����� _parsed_ok.
    cmp cl, ' '                         ;���� � ������ �������� ' ', ��
    jz _read_next                       ;��������� �� ����� _read_next.
    cmp cl, 13                          ;���� � ������ �������� CR, ��
    jz _read_next                       ;��������� �� ����� _read_next.
    cmp cl, 10                          ;���� � ������ �������� LF, ��
    jz _read_next                       ;��������� �� ����� _read_next.
   
    mov bp, word ptr [exeFileNameSize]  ;������� � bp ������� ������ exeFileName (������ � ������ �����).
    mov [exeFileName][bp], cl           ;������� �������� ������ �� ������ offset exeFileName + exeFileNameSize.
   
_increment_exeFileNameSize:  
 
    inc bp                              ;����������� ������� ������ �� 1,
    mov word ptr [exeFileNameSize], bp  ;������� ��� ������� � exeFileNameSize �
    jmp _read_next                      ;��������� �� ����� _read_next.  
   
 
_parsed_ok:
 
    mov bx, word ptr [exeFileNameSize]  ;������� � bx ������� ������ exeFileName (������ � ������ �����).
    mov [exeFileName][bx], 0            ;������� NULL �� ������ offset exeFileName + exeFileNameSize.
    mov word ptr [exeFileNameSize], 0   ;���������� ������� ������� ������ exeFileName.
    jmp _endp                           ;��������� �� ����� _endp.
 
_eof:
  
    mov ah, 3Eh                         ;3Eh - ������� �������� ����� �� ���������.
    mov bx, word ptr [fileHandler]      ;������� � bx ���������� �����.
    int 21h                             ;�������� �������.
    jnc _end_programm                   ;���� ������� ������� ����, �� ��������� �� ����� _endp,
    errorExit msgCloseError             ;����� ������� ��������� �� ������ � ������� �� ���������.
	
_end_programm:

    mov ah, 9h                                  ;\ 
    mov dx, offset msgEnd                       ; > ����� ������� ��������� �� ��������� ������.
    int 21h                                     ;/
    int 20h                                     ;������� �� ���������.
	
_endp:
               
    popa                                ;��������������� ��������.
    ret                                 ;������� �� ���������.
parseFile endp
 
start:
   
    mov ah, 9h									;\ 
    mov dx, offset msgStart                     ; > ������� ��������� � ������ ���������.
    int 21h                                     ;/
   
    mov sp, program_length + 100h + 200h        ;����������� ����� �� 200h ����� ����� ���������.  
    mov ah, 4Ah                                 ;���������� ��� ������ ����� ����� ��������� � ����� (4Ah - ������� ������������� ������).
    stack_shift = program_length + 100h + 200h  ;
    mov bx, stack_shift shr 4 + 1               ;����� ��������� � ������ �������� �� 4 ���� ������ (shr), ��� ������������ ������� �� 16
                                                ;+ 1, ����� ������� �������� ������ � ����� ��������� � ���������� (�� ���� �������� ������)
                                                ;��� �����������, ��� ������ ������.  
    int 21h                                     ;
    jnc _realloc_ok                             ;���� ������ ������� ������������, �� ��������� �� ����� _realloc_ok,
    errorExit msgReallocError                   ;����� ������� ��������� �� ������ � ������� �� ���������.
   
_realloc_ok:
   
    mov ax, 3D00h                               ;��������� ���� ������������ � �������� ������ ��� ������.
    mov dx, offset fileName                     ;� dx ������� ��� �����.
    int 21h                                     ;
    jnc _open_file_ok                           ;���� ���� ������� �������, �� ��������� �� ����� _open_file_ok,      
    errorExit msgOpenError                      ;����� ������� ��������� �� ������ � ������� �� ���������.
     
_open_file_ok:
   
    mov [fileHandler], ax                       ;������� ���������� ����� � ���������� fileHandler.
   
    mov ax, 4202h                               ;�������� ������� 0�42 ��� ��������� ��������� � (����� ����� + CX + DX).
    mov bx, [fileHandler]                       ;� BX ������� ���������� �����.
    xor cx, cx                                  ;�������� CX.
    xor dx, dx                                  ;�������� DX.
    int 21h                                     ;��������� �������.    
    jnc _get_size_ok                            ;���� ������� �������� ���������, �� ��������� �� ����� _get_size_ok,
    errorExit msgLSeekError                     ;����� ������� ��������� �� ������ � ������� �� ���������.
 
_get_size_ok:
	cmp ax, 8                                   ;
    jg _label                          			;���� ����� ����� > 8, �� ��������� �� ����� _read_last_char,
    errorExit msgFileParamsError                ;����� ������� ��������� �� ������ � ������� �� ���������.

_label:                                         ;������ ��������� ����.
    call parseFile                              ;�������� ��������� ������� ����.
    ;EPB (EXEC Parameter Block) � ���� ���������� ������� �������� �����. ����������, ������� ������ �����������
    ;� ���� �����, ������������ � �������:
    ;   +---------------+----------------+-------------------------------------------------+
    ;   |   ��������    |   �����(����)     |  ��������                                       |   
    ;   +---------------+----------------+-------------------------------------------------+
    ;   |      00h      |        2       |  ������� ��������� DOS ��� ������������ ��������|
    ;   |      02h      |        4       |  �������� � ������� ������ ��������� ������    |
    ;   |      06h      |        4       |  ������ ����� ����� FCB                         |
    ;   |      0Ah      |        4       |  ������ ����� ����� FCB                         |
    ;   |      0Eh      |        2       |  ����� EPB                                     |
    ;   +---------------+----------------+-------------------------------------------------+
    ;��������� ���� EBP, ���������� ���������� ������:
    mov ax, cs                                  ;
    mov word ptr [EPB + 4], ax                  ;���������� ����� ��������� ������.
    mov word ptr [EPB + 8], ax                  ;���������� ����� ������� FCB.
    mov word ptr [EPB + 0Ch], ax                ;���������� ����� ������� FCB.   
 
    mov ax, 4B00h                               ;������� DOS 4Bh - �������� � ������ ��������� (����� ��������� �������� ���������� ������ ���������).
    mov dx, offset exeFileName                  ;��� �����, ������� ���� ���������.
    mov bx, offset EPB                          ;���� EPB.
   
    push ds                                     ;��������� ������� ds.
    push es                                     ;��������� ������� es.
    pusha                                       ;��������� ��������� ��������.
   
    mov ss_Seg, ss                              ;��������� ���������� ������� �����.
    mov sp_Seg, sp                              ;��������� ��������� �� ������� �����.
   
    int 21h                                     ;��������� ��������� ���������.
    jnc _execute_file_ok                        ;���� ��������� ����������� �������, �� ��������� �� ����� _execute_file_ok,
    errorExit msgRunError                       ;����� ������� ��������� �� ������ � ������� �� ���������.
 
_execute_file_ok:
   
    mov ss, cs:ss_Seg                           ;��������������� ���������� ������� �����.
    mov sp, cs:sp_Seg                           ;��������������� ��������� �� ������� �����.
;���������! �. �. �� �� �������, ��� ������������ ��������� �� �������� �������� ds, �� ���������� � ���������� ss_Seg � sp_Seg,
;��������� ������� cs, �������, ��� �� ��� �����, ������ ����� ���� ��������, � ������� ����������� ������� �������.  
    popa                                        ;��������������� ��������.
    pop es                                      ;��������������� ������� es.
    pop ds                                      ;��������������� ������� ds.
	
    jmp _label
 
 
fileName                db 'test.txt', 0
ss_Seg                  dw 0
sp_Seg                  dw 0
msgStart                db 13,10, 'Start a super program.',13,10,'$'
msgEnd                  db 13,10, 'End the super program.',13,10,'$'
msgFileParamsError      db 13,10, 'Invalid file params.',13,10,'$'                
msgLSeekError           db 13,10, 'Lseek error.',13,10,'$'
msgRunError             db 13,10, 'Cannot run executable file.',13,10,'$'
msgReallocError         db 13,10, 'Realloc error.',13,10,'$'
msgOpenError            db 13,10, 'Cannot open file.',13,10,'$'
msgCloseError           db 13,10, 'Cannot close file.',13,10,'$'
msgReadError            db 13,10, 'Read error.',13,10,'$'      
fileHandler             dw 0
currentPositionInFile   dw 0
charBuffer              db 0
exeFileNameSize         dw 0  
isEndOfFile             db 0
exeFileName             db 512 dup (0)  
exeFileFolder           db 512 dup (0)    
EPB                     dw 0000                 ;������������ ������� ���������.
                        dw offset commandline, 0;����� ��������� ������.
                        dw 005Ch,0,006Ch,0      ;������ FCB, ���������� DOS ����� ��������� ��� ������� (�� ����� ���� ��� �� ������������).
commandline             db 0                    ;������������ ����� ��������� ������.
                        db ''                   ;����� ��� ��������� ������
program_length          equ $ - start           ;����� ���������
end start