.model tiny                
.code  
.386                       ; для определения переходов
org 100h                   ; отступ от PSP

_terminate_n_stay_resident_part_start:                     
	jmp _main               
 
maxCmdSize            equ 07Fh
maxBuffSize           equ 190h
clearValue            equ 1E0h       
endl                  equ 0

cmdSize               db  ?
cmdText               db  maxCmdSize  + 2 dup(0) 
buffer                db  maxBuffSize + 2 dup(0)
sourcePath            db  maxCmdSize  + 2 dup(0) 

sourceID              dw  0
fPosHigh              dw  0
fPosLow               dw  0
charsForPrint         dw  0

oldKeyboardIntHandler dd  0    
;===================================================Interrupt_handler_start=======================================================
newKeybordIntHandler proc far                      
	pushf								; сохраняем регистры флагов  
	call cs:oldKeyboardIntHandler		; вызываем старый обработчик                              
	
	push ds                           	; сохраняем сегментные
    push es                           	; регистры
	
	pusha								; сохраняем регистры общего назначения
	
	push cs                           	; DS = CS
	pop ds                            	;
    
    in  al, 60h							; считываем скан-код клавишы из порта клавиатуры 	         			
    
	cmp al, 01h                    		; если это escape, то     
    je _esc_routine						; переходим на метку _esc_routine
    
	cmp al, 48h							; если это pageUp, то        
    je _pageUp_routine					; переходим на метку _pageUp_routine
    
	cmp al, 50h							; если это pageDown, то    
    je _pageDown_routine 				; переходим на метку _pageDown_routine

_useless_key:							; если это клавиша, отличная от вышеперечисленных, то
	popa								; восстанавливаем регистры общего назначения
    
	pop es								; восстанавливаем сегментные
    pop ds								; регистры
	
    jmp _int_end						; переходим на метку _int_end

_pageUp_routine:
	mov si, word ptr [fPosHigh] 		; заносим старшие два байта, которые описываеют текущую позицию в файле
	mov bp, word ptr [fPosLow]			; записываем младшие два байта
	cmp si, 0							; не находимся ли мы в начале файла?
	jne _up_ok							; если старшие два байта отличны от нуля, то нет, и тогда переходим на метку _up_ok
	cmp bp, 0							; если они равны 0, то проверяем младшие два байта,
	je _useless_key						; если они равны 0, то мы в начале файла и промотать влево нельзя, следовательно, переходим на метку _useless_key
_up_ok:
    mov ax, 3D00h			        	; функция 3D00h - открыть существующий файл сдоступом к чтению
	mov dx, offset sourcePath			; загружаем в DX название исходного файла (ASCIIZ-строка)
	int 21h                         	;    
	
	jc _esc_routine						; если файл не удалось открыть, то выходим из программы              
	
	mov word ptr [sourceID], ax		; загружаем описатель файла в переменную sourceID

;================================================================================================================================
	sub bp, maxBuffSize					; пытаемся сдвинуться назад на размер буфера, производя вычитание  
	sbb si, 0							; с заемом 
	test si, 8000h						; проверяем: не отрицательная ли текущая позиция? 
	jz _current_pos_ok					; если она не отрицательная, то переходим на метку _current_pos_ok
;================================================================================================================================

	mov word ptr [fPosHigh], 0			; иначе выставляем ее страшие два байта в 0			
	mov word ptr [fPosLow], 0			; и младшие два тоже
	
	mov ax, 4200h              			; функция 4200h - переместить  указатель в начало файла + смещение CX:DX
	mov bx, word ptr [sourceID]		; заносим описатель файла
	xor cx, cx							; обнуляем страшие 2 байта смещения
	xor dx, dx		 					; и младшие 2 байта 
	int 21h                   
	
	neg bp								; в BP хранится отрицательное число элементов файла, которые необходмо прочесть, поэтому вполняем операцию (-1) * BP  
	
	mov ah, 3Fh                     	; функция 3Fh - чтения из файла 
	mov cx, bp                      	; в CX загружаем количество элементов для чтения
	mov dx, offset buffer				; в DX загружаем смещения буффера, в который будет считывать данные из файла
	int 21h
	
	cmp ax, 0							; если быо считано <0 символов, то
    jbe _close_file     				; переходим на метку _close_file
 
    call printToVideoMemory				; вызываем процедуру печати 
	
	jmp _close_file						; переходим на метку _close_file

;================================================================================================================================
_current_pos_ok:    
	mov ax, 4200h              			; функция 4200h - переместить  указатель в начало файла + смещение CX:DX
	mov bx, word ptr [sourceID]		; заносим описатель файла
	mov cx, si							; заносим старшие 2 байта текущей позиции 
	mov dx, bp							; заносим младшие 2 байта  
	int 21h                                              
   
    mov ah, 3Fh							; функция 3Fh - чтения из файла 
	mov cx, maxBuffSize					; в CX загружаем количество элементов для чтения
	mov dx, offset buffer				; в DX загружаем смещения буффера, в который будет считывать данные из файла
	int 21h                             
    
	cmp ax, 0							; если быо считано <0 символов, то
    jbe _close_file						; переходим на метку _close_file

    call printToVideoMemory             ; вызываем процедуру печати 
    
	mov si, word ptr [fPosHigh] 		; заносим в SI старшие 2 байта текущей позиции,
	mov bp, word ptr [fPosLow]			; а BP - младшие 2
	
	sub bp, ax							; вычитаем из текущей позиции с заемом кол-во реально прочитанных 
	sbb si, 0							; символов
    
	mov word ptr [fPosHigh], si		; и сохраняем разультат вычитния старший 2 байт
	mov word ptr [fPosLow], bp      	; и младших
    
    jmp _close_file						; переходим на метку _close_file
    
_pageDown_routine:
    mov ax, 3D00h						; функция 3D00h - открыть существующий файл сдоступом к чтению	        
	mov dx, offset sourcePath       	; загружаем в DX название исходного файла (ASCIIZ-строка)
	int 21h                            	;    
	
	jc _esc_routine              		; если файл не удалось открыть, то переходим на метку _esc_routine
   
	mov word ptr [sourceID], ax        ; загружаем описатель файла в переменную sourceID     
	
	mov ax, 4202h					 	; функция 4202h - переместить  указатель в конец файла + смещение CX:DX
	mov bx, sourceID                  	; заносим описатель файла
	xor cx, cx                         	; CX = 0  
	xor dx, dx                         	; DX = 0   
	int 21h

	mov si, word ptr [fPosHigh] 		; заносим в SI старшие 2 байта текущей позиции,
	mov bp, word ptr [fPosLow]        	; а BP - младшие 2 
	cmp si, dx							; проверяем не превышает ли текущая позиция длину файла
	jle _down_ok						; если страшие 2 байта текущей позиции не больше старших 2 байтов длины файла, то переходим на метку _down_ok 
	cmp bp, ax							; иначе проверяем 2 младших байта, если они больше младших 2 байтов длины файла, то 
	jg _useless_key						; переходим на метку _useless_key
	
_down_ok:
	mov ax, 4200h                      	; функция 4200h - переместить  указатель в начало файла + смещение CX:DX Записываем в ah код 42h - ф-ция DOS уставноки указателя файла
	mov bx, word ptr [sourceID]	 	; заносим описатель файла
	mov cx, si                        	; заносим старшие 2 байта текущей позиции  
	mov dx, bp		                    ; заносим младшие 2 байта  
	int 21h                              
 
    mov ah, 3Fh                     	; функция 3Fh - чтения из файла 
	mov cx, maxBuffSize             	; в CX загружаем количество элементов для чтения
	mov dx, offset buffer         		; в DX загружаем смещения буффера, в который будет считывать данные из файла
	int 21h                         
    
	cmp ax, 0							; если быо считано <0 символов, то
    jbe _close_file                    	; переходим на метку _close_file

    call printToVideoMemory 			; вызываем процедуру печати 
    
    add bp, ax							; увеличиваем текущую позицию в файле путем 
	adc si, 0							; сложения с переносом
    
	mov word ptr [fPosHigh], si		; и сохраняем разультат вычитния старший 2 байт
	mov word ptr [fPosLow], bp        	; и младших 
    
_close_file:
    mov ah, 3Eh                 		; функция 3Eh - ф-ия закрытия файла
	mov bx, word ptr [sourceID]       	; в BX загружаем описатель файла, подлежащего закрытию
	int 21h     
	
	popa								; восстанавливаем все регистры общего назначения
	
	pop es                            	; восстанавливаем сегментные
	pop ds	                          	; регистры
	
	jmp _int_end 						; переходим на метку _int_end 				
   
_esc_routine:    
	cli													; запрещаем маскируемые прерывания
	mov ax, 2509h										; фунция 2509h - функця установки обработчика прерывания 9h		
    mov dx, word ptr cs:[oldKeyboardIntHandler]		; смещение обработчика
    mov ds, word ptr cs:[oldKeyboardIntHandler + 2]	; сегмент обработчика
    int 21h												;
	sti 												; разрешаем маскируемые прерывания
    
	popa								; восстанавливаем регистры общего назначения	
	
	pop es								; восстанавливаем сегментные 
	pop ds	                          	; регистры
    
    mov es, cs:2ch     					; получим из PSP адрес собственного 
    mov ah, 49h        					; окружения резидента и выгрузим его 
    int 21h           					;  
    
    push cs           					; выгрузим теперь саму программу, для этого ES должен
    pop es            					; быть равен CS
    
	mov ah, 49h        					; выгружаем резидента из памяти 
    int 21h           					;                         
    
_int_end:
	iret       							; возврат управления контроллеру прерываний
newKeybordIntHandler endp                                  ;

;===================================================Interrupt_handler_end=======================================================
printToVideoMemory proc 				;ax - число элементов для вывода на экран
	pusha					
    
    mov word ptr [charsForPrint], ax	; заносим в charsForPrint количество символов для печати 
    
    mov ax, 0b800h						; настраиваемся на видеопамять 
    mov es, ax
    xor di, di 							; смещение от ее начала равно 0
    
    mov cx, word ptr [clearValue]		; сколько места экрана нужно очистить
_clear_sreen_loop:
    mov al, ' ' 						; заносим в AL символ пробела
    mov es:[di], al					; заносим его в видеобуфер
	add di, 2
    loop _clear_sreen_loop

	mov di, 320h 						; указываем смещение относительно видеопамяти
	
	mov cx, 50h							; заносим кол-во символов для печати 
_print_separator_loop:
	mov al, '='							; символ для печати заносим в AL
	mov es:[di], al					; заносим его в видеобуфер
	inc di								; двигаемся к байту цвета сивола и фона
	mov al, 00001100b					; ярко-красный символ '=' на черном фоне 
	mov es:[di], al					; заносим его цвет в видеобуфер
	inc di								; двигаемся к следующему символу
	loop _print_separator_loop
	
	mov si, offset buffer				; зносим в SI указатель на буфер с символами для печати  
    xor di, di 							; обнуляем смещение относительно видеопамяти 							

    mov cx, word ptr [charsForPrint]	; заносим кол-во символов для печати 
_print_text_loop:
    mov al, [si] 						; заносим в AL символ из буфера
    mov es:[di], al					; затем помещаем этот символ в видеопамять
	inc di 								; двигаемся к байту цвета сивола и фона
	mov al, 00001111b					; светло-серый символ на черном фоне
	inc di								; двигаемся к следующему символу
	inc si								; продвигаемся вперед в буфере
    loop _print_text_loop
    
    popa								; восстанавливаем регистры общего назначения
    ret
printToVideoMemory endp 
;*************************************************************************************************************************

_terminate_n_stay_resident_part_end:		; маркер конча резидентной части 

;**************************************************************************************************************************
println macro info          			
	push ax                 			
	push dx                 			

	mov ah, 09h             			; команда вывода 
	mov dx, offset info        			; загрузка в DX адреса выводимого сообщения
	int 21h                 			
	
	mov dl, 0Ah            				; символ перехода на новую строку
	mov ah, 02h             			; команда вывода символа
	int 21h                 		

	mov dl, 0Dh             			; символ возврата каретки
	mov ah, 02h             			; команда вывода символа
	int 21h                       

	pop dx                  
	pop ax                  
endm 
;**************************************************************************************************************************     
parseCmd proc                         
	pusha
	
	cld                               	; установка направления строковыйх операций
	mov bx, 80h                       	; заносим в BX адрес, где хранится вдлина командной строки
	mov cl, cs:[bx]                   	; згружаем в CL длину командной строки
	xor ch, ch                        	; обнуляем CH

	xor dx, dx                     		; обнуляем DX
	mov di, 81h							; начало содержания командной строки

	mov al, ' '                       	
	repne scasb	                      	; найти байт, равный AL в блоке из CX байт по адресу ES:DI 
	
	mov al, ' '							; 
    repe scasb     						; найти байт, отличный от пробела
    
	dec di     							; указываем на первый символ за пробелом
    inc cx
	
	xor ax, ax                        	; обнуляем AX                                                 
 
	mov si, di                      	; загружаем в SI смещение, с которого начинаются аргументы
	mov di, offset sourcePath			; место, куда будет загружна командная строка  
	
	mov al, [si]						; заносим символ из командной строки в AL
	cmp al, ' '							; если это пробел, то 
    je _bad_cmd_args 					; переходим на метку _bad_cmd_args
    cmp al, 0Dh							; если это символ возврата каретки, то
    je _bad_cmd_args					; переходим на метку _bad_cmd_args
	
_copy_cmd_arg_loop:
    mov al, [si]						; заносим символ из командной строки в AL
    cmp al, ' '                        	; если это пробел, то 
    je _end_was_founded                	; переходим на метку _end_was_founded
    cmp al, 0Dh                        	; если это символ возврата каретки, то
    je _end_was_founded                	; переходим на метку _end_was_founded
    
    mov [di], al						; заносим символ в переменную sourcePath
    inc di								; передвигаем указатель буфера
    inc si 								; и командной строки
    jmp _copy_cmd_arg_loop 
    
_bad_cmd_args:
    println badCmdArgsMsg				; выводим сообщение об ошибке 
    xor ax, ax								
    jmp _parsed   
	
_end_was_founded:     
    mov al, endl						;
    mov [di], al                		; загружаем символ конца строки в результирующую строки 
    xor ax, ax
    
_parsed:                       
	popa
	ret                           
parseCmd endp
                        
;********************************************************************************************************************   
setHandler proc                       	; установка нового обработчика прерываний. Результат ax=0 если нет ошибок, иначе ax!=0 
	push bx                           
	push dx                            

	cli                               	; запрещаем прерывания (запрет/разрешение необходимо для корректной установки нового обработчика )

	mov ah, 35h                       	; функция получения адреса обработчика прерывания
	mov al, 09h                       	; прерывание, обработчик которого необходимо получить (09h - прерывание клавиатуры)
	int 21h                            
; в результате выполнения функции в ES:BX помещается адрес текущего обработчика прерывания                                                 
; сохраняем старый обработчик:
	mov word ptr [oldKeyboardIntHandler], bx     ; смещение
	mov word ptr [oldKeyboardIntHandler + 2], es ; сегмент

	push ds			                	; сохраняем значение DS
	pop es                            	; восстанавливаем значение ES

	mov ah, 25h                       	; функция замены обработчика прерывания
	mov al, 09h                       	; прерывание, обработчк которого будет заменен
	mov dx, offset newKeybordIntHandler	; загружаем в DX смещение нового обработчика прерывания, который будет установлен на место старого обработчика 
	int 21h                           

	sti                               	; разрешаем прерывания

	xor ax, ax                         	; загружаем в AX - 0, т.е. ошибок не произошло

	pop dx                            	; восстанавливаем значения регистров и переходим выходим из процедуры
	pop bx                            
	ret                               
setHandler endp                                                                   

checkErrors proc
	pusha
	
	mov ax, 3D00h						; открываем файл 
	mov dx, offset sourcePath
	int 21h
	
	jnc _file_exist						; если файл открылся, то переходим на метку _file_exist
	
	println fileDoesNotExistErrorMsg	; выводим сообщение об ошибке
	mov ax, 4C01h						; вывходим из программы с кодом ошибки 1
	int 21h
	
_file_exist:	
	mov bx, ax							; заносим описатель файла в BX
	
	mov ax, 4202h						; получаем размер файла в байтах
	xor cx, cx
	xor bx, bx
	int 21h
	
	jnc _fseek_ok						; если не возникло ошибке по перемещению указателя, то переходим на метку _fseek_ok
	
	println fseekErrorMsg				; выводим сообщение об ошибке
	mov ax, 4C01h                      	; вывходим из программы с кодом ошибки 1
	int 21h
	
_fseek_ok:
	mov ah, 3Eh							; закрываем файл 
	int 21h
	
	jnc _file_was_successfully_closed	;если файл успешно закрылся, то переходим на метку _file_was_successfully_closed
	
	println canNotCloseFileErrorMsg		; выводим сообщение об ошибке
	mov ax, 4C01h                      	; вывходим из программы с кодом ошибки 1
	int 21h
	
_file_was_successfully_closed:	
	popa
	ret
checkErrors endp

_main:
	call parseCmd                     	; парсим командную строку
	cmp ax, 0                         	; если возникла ошибкаб то выходим
	jne _end_main                      	 
	
	call checkErrors
	
	call setHandler                   	; устанавливаем новый обработчик прерывания
	cmp ax, 0                         	; если возникла ошибка - выходим
	jne _end_main				           

	mov ax, 3100h                      	; оставляем программу резидентной                        
	mov dx, (_terminate_n_stay_resident_part_end - _terminate_n_stay_resident_part_start + 200h) / 16 ; Заносим в DX размер программы + PSP,
	inc dx          					; делим на  16, т.к. в DX необходимо занести размер в 16 байтных параграфах
	int 21h                            

_end_main:                              
	int 20h
	
fileDoesNotExistErrorMsg		db 	10,13,'File does not exist error. Program was terminated!$'                           
fseekErrorMsg 					db 	10,13,'File seek error. Program was terminated!$'
canNotCloseFileErrorMsg			db	10,13,'Cannot close file error. Program was terminated!$'
badCmdArgsMsg         			db 	10,13,'Bad cmd arguments! Only one argument is required. Program was terminated!$'

end _terminate_n_stay_resident_part_start