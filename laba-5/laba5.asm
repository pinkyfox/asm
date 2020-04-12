org 100h  
 
jmp start0

clear_screeng proc                    ; процедура очистки экрана
	    mov ah, 0003h				  ; Очистить экран, установить поля BIOS, установить режим 3 (80х25).
	    int 10h
        
	    mov ah, 1112h			      ; установить стандартный шрифт 8х8
	    mov bl, 00h					  ; номер шрифта 
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
        mov al, 03h                   ; переход в видеорежим
        int 10h 
        cld                           ; сбрасываем флаг направления для строковых операций (слева на право)                       
        mov cl, [80h]				  ; заносим в CL количество символов строки параметров 	
        cmp cl, 1					  ; если 1 или менее, 	
        jle start					  ; переходим к метке start, которая запускает программу в стандартном режиме
		
        mov cx, -1					  ; заносим в CX -1, чтобы не накладывались ограничения на строковые операции 
        mov di, 81h 				  ; в DI заносим адрес начала строки параметров 
             
_find_param:

        mov al, ' '         		  ; в AL заносим ' ', чтобы сравнивать с пробелом параметры 

        repz scasb         			  ; сканируем строку до тех пор, пока не найдем символ отличный от пробела
        inc word ptr argc   		  ; инкрементируем переменную, которая хранит в себе количество параметров 
        mov dx, word ptr argc		  ; заносим значение счетчика параметров в DX
        cmp dx, 2					  ; если количество параметров 2 и более, то
        jge _cmd_error           	  ; выводим сообщение об ошибке ввода и переходим к запуску программы в нормальном режиме
        
        dec di             			  ; декрементируем DI, чтобы он ханил адрес первого символа параметра  
        mov bp, di            		  ; заносим данный адрес в BP
        mov si, di          		  ; и SI	
_scan_params:

        lodsb              			  ; загружаем символ по адресу, который хранит SI в AL
        cmp al, 0Dh         		  ; если данный символ возврат каретки, то
        je _params_ended    		  ; переходим на метку _params_ended 
        cmp al, ' '          		  ; если это пробел, то  
        jne _scan_params      		  ; переходим в начало 

        dec si               		  ; декрементируем SI, чтоюы он ссылался на первый символ после последнего символа параметра
        mov byte ptr [si],'0'         ; заносим по данному адресу символ конца ASCIIZ-строки
        mov di, si            		  ; заносим адрес из SI в DI
        inc di               		  ; инкрементируем DI
        jmp short _find_param 		  ; делаем короткий прыжок [128 байт назад и 127 байт вперед] на метку _find_param 

 

_params_ended:

        dec si               		  ; декрементируем SI
        mov byte ptr [si], 0Dh		  ; заносим символ возврата каретки по адресу, хранящемуся в SI
		mov dx, si					  ; заносим SI в DI
		sub dx, bp					  ; вычитаем из адреса конца строки-параметра адрес ее начала
		mov byte ptr lenFileName, dl  ; помещаем полученное значение в переменную lenFileName
		mov cx, dx                    ; заносим в CX длину строки-параметра
		xor si, si					  ; обнуляем SI
		mov si, offset szFileName	  ; заносим в SI адрес szFileName
_loop1:       
        mov dx, [bp]        		  ; заносим в DX символ строки-параметра
		mov [si], dx				  ; записываем данный символ по адресу, хранящемуся в SI
		inc si 						  ; увеличиваем SI
		inc bp						  ; увеличиваем BP
    	loop _loop1					  ; цикл
		jmp start1					  ; переходим на метку start1
_cmd_error:   
        xor ax, ax
        print msgCmdError             ; выводим сообщение 
start:	    	    
	    xor ax, ax                    ;обнуляем ax
        print msgEnterName            ; выводим сообщение
 
        mov ah, 0Ah  				  ;\ 
        mov dx, offset bufFileName	  ; >считываем имя файла в переменную bufFileName
        int 21h 					  ;/ 
start1:  
        xor bh ,bh					  ; обнуляем BH
        mov bl, [lenFileName]		  ; заносим значение переменной lenFileName(длина строки-параметра)
        mov [szFileName][bx], 0  	  ; переводим ее к типу ASCIIZ-строки
        
        mov ax, 3D00h                ; открываем файл с доступом по чтению
        mov dx, offset szFileName    ; адрес имени файла
        int 21h
        jnc _open_ok                 ; если не произошло ошибки при открытии файла переходим на метку _open_ok
									 ; AX содержит код ошибки, для простоты его игнорируем.
                                     ; иначе выводим сообщение об ошибке
 
_error_exit:
        print msgOpenError           ; вывод сообщения об ошибке
        mov ax, 4C01h                ; завершаем программу с кодом 1
        int 21h					     ; завершение программы
 
_open_ok:
        mov [hFileIn], ax    		 ; сохраняем описатель (handle) файла
 
_show_menu: 
        print menu			         ; выводим меню
 
									 ; ожидаем выбора пользователя
_wait:
        xor ax, ax					 ; обнуляем AX 
        int 16h						 ; ожидаем ввода символа от пользователя
        cmp al, '1'					 ; если пользователь нажал '1', то 
        jz  _type					 ; переходим на метку _type
        cmp al, 27                   ; если пользователь нажал 'esc', то				
        jnz _wait					 ; иначе ожидаем корректного ввода
_exit:            
        mov ax, 4C00h        		 ; завершаем программу 
        int 21h                      ; с кодом 0
 
_type:
	    call clear_screeng			 ; вызываем процедуру очистки экрана
        mov  [hFileOut], 1           ; стандратное устройство вывода (экран)

_common_out:
									 ; определяем длину файла
        mov ax, 4202h        		 ; вызываем функцию 0х42 для установки указателя в конец файла + CX + DX (AL = 0x2) 
        mov bx, [hFileIn]	 		 ; заносим в BX описатель файла
        xor cx, cx			 		 ; обнуляем CX 
        xor dx, dx           		 ; обнуляем DX 
        int 21h				 		 ; выполняем функцию 
        jnc _size_ok		 		 ; если не произошла ошбка установки указателя, то переходим к метке _size_ok
_lseek_error:
        mov dx, offset msgLSeekError ; иначе выводим ошибку перестановки указателя
        jmp _error_exit				 ; и делаем выходи из-за ошибки 
 
_size_ok:
									 ; действительная длина файла (DX * 65536) + AX
        mov word ptr [nFileSize_low], ax ; заносим в младшие два байта в nFileSize_low 
        mov word ptr [nFileSize_high], dx ; заносим в старшие два байта в nFileSize_high
        mov ax, 4200h                ; вызываем функцию 0х42 для установки указателя в начало файла + CX + DX (AL = 0x0),
									 ; BX уже содержит нужно значение
        xor cx, cx                   ; обнуляем CX
        xor dx, dx                   ; обнуляем DX
        int 21h                      ; выполняем функцию
        jc  _lseek_error             ; если CF = 0, то произошла ошибка при установке файлового указателия и мы переходим на метку _lseek_error 
									 ; читаем и записываем файл на устройство вывода
        mov ax, word ptr [nFileSize_low]  ; заносим в AX младшие два байта 
		mov si, word ptr [nFileSize_high] ; заносим в SI старшие два байта
_next_block:
        mov cx, BLOCK_SIZE			 ; в CX заносим размер блока 
		mov bp, 0000h				 ; в BP заносим 0000 для того, чтобы представить 64-битное число 00000600h - размер блока
        sub ax, cx					 ; вычитаем младшие два байта 
		sbb si, bp				     ; затем два старших байта с учетом флага переноса
        jae _save_new_size           ; если размер блока меньше, чем размер файла, то переходим на метку _save_new_size
        xor ax, ax					 ; иначе обнуляем AX 
		xor si, si				     ; и обнуляем SI
		mov cx, word ptr [nFileSize_low] ; заносим младшие два байта в CX
_save_new_size:
        mov word ptr [nFileSize_high], si ; заносим старшие два байта после вычитания блока
		mov word ptr [nFileSize_low], ax  ; заносим младшие два байта после вычитайния блока
									 ; CX содержит размер очередного блока
        mov dx, offset file_buf      ; заносим буфер для считывания данных из файла
        mov bx, [hFileIn]			 ; заносим дескриптор файла

        mov ah, 3Fh  				 ;считываем блок из файла
        int 21h
        jnc _read_ok  				 ; если ошибок не произошло (CF = 0), переводим к метке _read_ok
        mov dx, offset msgReadError  ; иначе выводим сообщение об ошибке чтения
        jmp _error_exit				 ; и переходим к аварийному завершению программы
 
_read_ok:
        mov cx, ax                   ; заносим в CX число действительно прочитанных байт
 
        mov bx, [hFileOut]			 ; заносим в BX описатель файла (если BX = 1, то устройство вывода STDOUT)
        mov ah, 40h                  ; заносим в AH номер функции записи
        int 21h						 ; выполняем функцию 
        jnc _write_ok				 ; если запись произошла без ошибок (CF = 0), то переводим на метку _write_ok
        mov dx, offset msgWriteError ; иначе выводим сообщение об ошибке 
        jmp _error_exit              ; и переходим к аварийному завершению программы
_write_ok:
        xor  ax, ax					 ; обнуляем AX
        int  16h					 ; ждем от пользователя нажатия любой клавиши
        call clear_screeng			 ; вызываем процедуру очистки экрана
        mov ax, word ptr [nFileSize_low]  ; заносим в AX младшие два байта длины файла
		mov si, word ptr [nFileSize_high] ; заносим в SI старшие два байта длины файла
        cmp si, 0                    ; если старшие два байта не равны нулю, то
        jnz _next_block              ; переходим к обрабоке следующего блока
		cmp ax, 0					 ; инче проверяем бладшие два байта на равенство нулю
		jnz _next_block				 ; если младшие два байта не равны нулю, то переходим к обрабоке следующего блока
            
        print msgOutOk               ; выводим сообщение об успешном прочтении 
        jmp _show_menu				 ; переходим на метку _show_menu
;------------------------------------------------------------DATA--------------------------------------------------------------------------;
msgEnterName    db  13,10,'Input file: $'
bufFileName     db  254  										; размер буфера
lenFileName     db  0    										; длина введенной строки
szFileName      db  254 dup(0)   								; строка
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