org 100h  
 
jmp start0

clear_screeng proc                    ; ��������� ������� ������
	    mov ah, 0003h				  ; �������� �����, ���������� ���� BIOS, ���������� ����� 3 (80�25).
	    int 10h
        
	    mov ah, 1112h			      ; ���������� ����������� ����� 8�8
	    mov bl, 00h					  ; ����� ������ 
	    int 10h
        
	    ret
clear_screeng endp

print macro str
	push ax
	mov ah, 09h
	mov dx, offset str
	int 21h
	pop ax
endm

;*******************************  
start0:   
        mov al, 03h                   ; ������� � ����������
        int 10h 
        cld                           ; ���������� ���� ����������� ��� ��������� �������� (����� �� �����)                       
        mov cl, [80h]				  ; ������� � CL ���������� �������� ������ ���������� 	
        cmp cl, 1					  ; ���� 1 ��� �����, 	
        jle start					  ; ��������� � ����� start, ������� ��������� ��������� � ����������� ������
		
        mov cx, -1					  ; ������� � CX -1, ����� �� ������������� ����������� �� ��������� �������� 
        mov di, 81h 				  ; � DI ������� ����� ������ ������ ���������� 
             
_find_param:

        mov al, ' '         		  ; � AL ������� ' ', ����� ���������� � �������� ��������� 

        repz scasb         			  ; ��������� ������ �� ��� ���, ���� �� ������ ������ �������� �� �������
        inc word ptr argc   		  ; �������������� ����������, ������� ������ � ���� ���������� ���������� 
        mov dx, word ptr argc		  ; ������� �������� �������� ���������� � DX
        cmp dx, 2					  ; ���� ���������� ���������� 2 � �����, ��
        jge _cmd_error           	  ; ������� ��������� �� ������ ����� � ��������� � ������� ��������� � ���������� ������
        
        dec di             			  ; �������������� DI, ����� �� ����� ����� ������� ������� ���������  
        mov bp, di            		  ; ������� ������ ����� � BP
        mov si, di          		  ; � SI	
_scan_params:

        lodsb              			  ; ��������� ������ �� ������, ������� ������ SI � AL
        cmp al, 0Dh         		  ; ���� ������ ������ ������� �������, ��
        je _params_ended    		  ; ��������� �� ����� _params_ended 
        cmp al, ' '          		  ; ���� ��� ������, ��  
        jne _scan_params      		  ; ��������� � ������ 

        dec si               		  ; �������������� SI, ����� �� �������� �� ������ ������ ����� ���������� ������� ���������
        mov byte ptr [si],'0'         ; ������� �� ������� ������ ������ ����� ASCIIZ-������
        mov di, si            		  ; ������� ����� �� SI � DI
        inc di               		  ; �������������� DI
        jmp short _find_param 		  ; ������ �������� ������ [128 ���� ����� � 127 ���� ������] �� ����� _find_param 

 

_params_ended:

        dec si               		  ; �������������� SI
        mov byte ptr [si], 0Dh		  ; ������� ������ �������� ������� �� ������, ����������� � SI
		mov dx, si					  ; ������� SI � DI
		sub dx, bp					  ; �������� �� ������ ����� ������-��������� ����� �� ������
		mov byte ptr lenFileName, dl  ; �������� ���������� �������� � ���������� lenFileName
		mov cx, dx                    ; ������� � CX ����� ������-���������
		xor si, si					  ; �������� SI
		mov si, offset szFileName	  ; ������� � SI ����� szFileName
_loop1:       
        mov dx, [bp]        		  ; ������� � DX ������ ������-���������
		mov [si], dx				  ; ���������� ������ ������ �� ������, ����������� � SI
		inc si 						  ; ����������� SI
		inc bp						  ; ����������� BP
    	loop _loop1					  ; ����
		jmp start1					  ; ��������� �� ����� start1
_cmd_error:   
        xor ax, ax
        print msgCmdError             ; ������� ��������� 
start:	    	    
	    xor ax, ax                    ;�������� ax
        print msgEnterName            ; ������� ���������
 
        mov ah, 0Ah  				  ;\ 
        mov dx, offset bufFileName	  ; >��������� ��� ����� � ���������� bufFileName
        int 21h 					  ;/ 
start1:  
        xor bh ,bh					  ; �������� BH
        mov bl, [lenFileName]		  ; ������� �������� ���������� lenFileName(����� ������-���������)
        mov [szFileName][bx], 0  	  ; ��������� �� � ���� ASCIIZ-������
        
        mov ax, 3D00h                ; ��������� ���� � �������� �� ������
        mov dx, offset szFileName    ; ����� ����� �����
        int 21h
        jnc _open_ok                 ; ���� �� ��������� ������ ��� �������� ����� ��������� �� ����� _open_ok
									 ; AX �������� ��� ������, ��� �������� ��� ����������.
                                     ; ����� ������� ��������� �� ������
 
_error_exit:
        print msgOpenError           ; ����� ��������� �� ������
        mov ax, 4C01h                ; ��������� ��������� � ����� 1
        int 21h					     ; ���������� ���������
 
_open_ok:
        mov [hFileIn], ax    		 ; ��������� ��������� (handle) �����
 
_show_menu: 
        print menu			         ; ������� ����
 
									 ; ������� ������ ������������
_wait:
        xor ax, ax					 ; �������� AX 
        int 16h						 ; ������� ����� ������� �� ������������
        cmp al, '1'					 ; ���� ������������ ����� '1', �� 
        jz  _type					 ; ��������� �� ����� _type
        cmp al, 27                   ; ���� ������������ ����� 'esc', ��				
        jnz _wait					 ; ����� ������� ����������� �����
_exit:            
        mov ax, 4C00h        		 ; ��������� ��������� 
        int 21h                      ; � ����� 0
 
_type:
	    call clear_screeng			 ; �������� ��������� ������� ������
        mov  [hFileOut], 1           ; ����������� ���������� ������ (�����)

_common_out:
									 ; ���������� ����� �����
        mov ax, 4202h        		 ; �������� ������� 0�42 ��� ��������� ��������� � ����� ����� + CX + DX (AL = 0x2) 
        mov bx, [hFileIn]	 		 ; ������� � BX ��������� �����
        xor cx, cx			 		 ; �������� CX 
        xor dx, dx           		 ; �������� DX 
        int 21h				 		 ; ��������� ������� 
        jnc _size_ok		 		 ; ���� �� ��������� ����� ��������� ���������, �� ��������� � ����� _size_ok
_lseek_error:
        mov dx, offset msgLSeekError ; ����� ������� ������ ������������ ���������
        jmp _error_exit				 ; � ������ ������ ��-�� ������ 
 
_size_ok:
									 ; �������������� ����� ����� (DX * 65536) + AX
        mov word ptr [nFileSize_low], ax ; ������� � ������� ��� ����� � nFileSize_low 
        mov word ptr [nFileSize_high], dx ; ������� � ������� ��� ����� � nFileSize_high
        mov ax, 4200h                ; �������� ������� 0�42 ��� ��������� ��������� � ������ ����� + CX + DX (AL = 0x0),
									 ; BX ��� �������� ����� ��������
        xor cx, cx                   ; �������� CX
        xor dx, dx                   ; �������� DX
        int 21h                      ; ��������� �������
        jc  _lseek_error             ; ���� CF = 0, �� ��������� ������ ��� ��������� ��������� ���������� � �� ��������� �� ����� _lseek_error 
									 ; ������ � ���������� ���� �� ���������� ������
        mov ax, word ptr [nFileSize_low]  ; ������� � AX ������� ��� ����� 
		mov si, word ptr [nFileSize_high] ; ������� � SI ������� ��� �����
_next_block:
        mov cx, BLOCK_SIZE			 ; � CX ������� ������ ����� 
		mov bp, 0000h				 ; � BP ������� 0000 ��� ����, ����� ����������� 64-������ ����� 00000600h - ������ �����
        sub ax, cx					 ; �������� ������� ��� ����� 
		sbb si, bp				     ; ����� ��� ������� ����� � ������ ����� ��������
        jae _save_new_size           ; ���� ������ ����� ������, ��� ������ �����, �� ��������� �� ����� _save_new_size
        xor ax, ax					 ; ����� �������� AX 
		xor si, si				     ; � �������� SI
		mov cx, word ptr [nFileSize_low] ; ������� ������� ��� ����� � CX
_save_new_size:
        mov word ptr [nFileSize_high], si ; ������� ������� ��� ����� ����� ��������� �����
		mov word ptr [nFileSize_low], ax  ; ������� ������� ��� ����� ����� ���������� �����
									 ; CX �������� ������ ���������� �����
        mov dx, offset file_buf      ; ������� ����� ��� ���������� ������ �� �����
        mov bx, [hFileIn]			 ; ������� ���������� �����

        mov ah, 3Fh  				 ;��������� ���� �� �����
        int 21h
        jnc _read_ok  				 ; ���� ������ �� ��������� (CF = 0), ��������� � ����� _read_ok
        mov dx, offset msgReadError  ; ����� ������� ��������� �� ������ ������
        jmp _error_exit				 ; � ��������� � ���������� ���������� ���������
 
_read_ok:
        mov cx, ax                   ; ������� � CX ����� ������������� ����������� ����
 
        mov bx, [hFileOut]			 ; ������� � BX ��������� ����� (���� BX = 1, �� ���������� ������ STDOUT)
        mov ah, 40h                  ; ������� � AH ����� ������� ������
        int 21h						 ; ��������� ������� 
        jnc _write_ok				 ; ���� ������ ��������� ��� ������ (CF = 0), �� ��������� �� ����� _write_ok
        mov dx, offset msgWriteError ; ����� ������� ��������� �� ������ 
        jmp _error_exit              ; � ��������� � ���������� ���������� ���������
_write_ok:
        xor  ax, ax					 ; �������� AX
        int  16h					 ; ���� �� ������������ ������� ����� �������
        call clear_screeng			 ; �������� ��������� ������� ������
        mov ax, word ptr [nFileSize_low]  ; ������� � AX ������� ��� ����� ����� �����
		mov si, word ptr [nFileSize_high] ; ������� � SI ������� ��� ����� ����� �����
        cmp si, 0                    ; ���� ������� ��� ����� �� ����� ����, ��
        jnz _next_block              ; ��������� � �������� ���������� �����
		cmp ax, 0					 ; ���� ��������� ������� ��� ����� �� ��������� ����
		jnz _next_block				 ; ���� ������� ��� ����� �� ����� ����, �� ��������� � �������� ���������� �����
            
        print msgOutOk               ; ������� ��������� �� �������� ��������� 
        jmp _show_menu				 ; ��������� �� ����� _show_menu
;------------------------------------------------------------DATA--------------------------------------------------------------------------;
msgEnterName    db  13,10,'Input file: $'
bufFileName     db  254  										; ������ ������
lenFileName     db  0    										; ����� ��������� ������
szFileName      db  254 dup(0)   								; ������
msgOpenError    db  13,10, 'Cannot open file.',13,10,'$' 
msgCmdError     db  13,10, 'Invalid cmd parameters',13,10,'$'
msgLSeekError   db  13,10, 'lseek error',13,10,'$'
msgReadError    db  13,10, 'read error',13,10,'$'
msgWriteError   db  13,10, 'write error',13,10,'$'
msgOutOk        db  13,10,10,'---------------------------------',13,10,'Operation completed successfully.',13,10,'$'
				    
menu            db  13,10, 'What is your choice?',13,10
                db  '1   - Show file on screen',13,10
                db  'Esc - exit',13,10,13,10,'$'
                    
hFileIn         dw  0
hFileOut        dw  0
nFileSize_high  dw  0
nFileSize_low   dw  0
argc            dw  0
file_buf        db  4096 dup (?)
BLOCK_SIZE      equ 4096 
;------------------------------------------------------------ENDD--------------------------------------------------------------------------;
end start