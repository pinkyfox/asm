org 100h
jmp start
 
errorExit macro str                     ;макрос выхода из-за ошибки, принимает строку с пояснением ошибки.
    push ax                             ;сохраняем регистр ax.
    push dx                             ;сохраняем регистр dx.
 
    mov ah, 09h                         ;\ 
    mov dx, offset str                  ; > выводим сообщение об ошибке.   
    int 21h                             ;/
   
    mov ax, 4C01h                       ;завершаем программу с кодом 1
    int 21h                             ;  
 
    pop dx                              ;восстанавливаем регистр dx.
    pop ax                              ;восстанавливаем регистр ax.
endm      
 
parseFile proc                          ;процедупа построчного считывания файла.
    pusha                               ;сохраняем регистры.
   
_read_next:    
    mov ax, 4200h                       ;вызываем функцию 0х42 для установки указателя в (начало файла + CX + DX).
    mov bx, [fileHandler]               ;в BX заносим дескриптор файла.
    xor cx, cx                          ;обнуляем CX.
    mov dx, [currentPositionInFile]     ;в DX заносим позицию, на которой остановились ранее.
    int 21h                             ;выполняем функцию.    
    jnc _lseek_ok                       ;если удалось сдвинуть указатель, то переходим на метку _lseek_ok,
    errorExit msgLSeekError             ;иначе выводим сообщение об ошибке и выходим из программы.
   
_lseek_ok:
   
    mov ah, 3Fh                         ;функция чтения файла.
    mov cx, 1h                          ;количество символов к прочтению.
    mov dx, offset charBuffer           ;буфер для записи прочитанного.
    int 21h                             ;
    jnc _read_ok                        ;если удалось прочесть из файла, то переходим на метку _read_ok,
    errorExit msgReadError              ;иначе выводим сообщение об ошибке и выходим из программы.
 
_read_ok:
     
    mov cl, byte ptr [charBuffer]       ;заносим значение буфера в cl.                      
    cmp cl, '?'                         ;если это '?',
    jz _eof                             ;то это конец файла, тогда переходим на метку _eof.
 
    mov si, word ptr [currentPositionInFile]    ;\
    inc si                                      ; >увеличиваем счетчик текущей позиции в файле.
    mov word ptr [currentPositionInFile], si    ;/
     
    cmp cl, ';'                         ;если в буфере хранится ';', то
    jz _parsed_ok                       ;переходим на метку _parsed_ok.
    cmp cl, ' '                         ;если в буфере хранится ' ', то
    jz _read_next                       ;переходим на метку _read_next.
    cmp cl, 13                          ;если в буфере хранится CR, то
    jz _read_next                       ;переходим на метку _read_next.
    cmp cl, 10                          ;если в буфере хранится LF, то
    jz _read_next                       ;переходим на метку _read_next.
   
    mov bp, word ptr [exeFileNameSize]  ;заносим в bp текущий размер exeFileName (строки с именем файла).
    mov [exeFileName][bp], cl           ;заносим значение буфера по адресу offset exeFileName + exeFileNameSize.
   
_increment_exeFileNameSize:  
 
    inc bp                              ;уведичиваем текущий размер на 1,
    mov word ptr [exeFileNameSize], bp  ;заносим его обратно в exeFileNameSize и
    jmp _read_next                      ;переходим на метку _read_next.  
   
 
_parsed_ok:
 
    mov bx, word ptr [exeFileNameSize]  ;заносим в bx текущий размер exeFileName (строки с именем файла).
    mov [exeFileName][bx], 0            ;заносим NULL по адресу offset exeFileName + exeFileNameSize.
    mov word ptr [exeFileNameSize], 0   ;сбрасываем счетчик размера строки exeFileName.
    jmp _endp                           ;переходим на метку _endp.
 
_eof:
  
    mov ah, 3Eh                         ;3Eh - функция закрытия файла по описателю.
    mov bx, word ptr [fileHandler]      ;заносим в bx дескриптор файла.
    int 21h                             ;вызываем функцию.
    jnc _end_programm                   ;если удалось закрыть файл, то переходим на метку _endp,
    errorExit msgCloseError             ;иначе выводим сообщение об ошибке и выходим из программы.
	
_end_programm:

    mov ah, 9h                                  ;\ 
    mov dx, offset msgEnd                       ; > иначе выводим сообщение об окончании работы.
    int 21h                                     ;/
    int 20h                                     ;выходим из программы.
	
_endp:
               
    popa                                ;восстанавливаем регистры.
    ret                                 ;возврат из процедуры.
parseFile endp
 
start:
   
    mov ah, 9h					;\ 
    mov dx, offset msgStart                     ; > выводим сообщение о старте программы.
    int 21h                                     ;/
   
    mov sp, program_length + 100h + 200h        ;перемещение стека на 200h после конца программы.  
    mov ah, 4Ah                                 ;освободить всю память после конца программы и стека (4Ah - функция перевыделения памяти).
    stack_shift = program_length + 100h + 200h  ;
    mov bx, stack_shift shr 4	                ;длину программы в байтах сдвигаем на 4 бита вправо (shr), что эквивалентно делению на 16
    inc bx                                      ;+ 1, таким образом получаем размер с нашей программы в параграфах (на один параграф больше)
                                                ;для уверенности, что хватит памяти.  
    int 21h                                     ;
    jnc _realloc_ok                             ;если память успешно перевыделена, то переходим на метку _realloc_ok,
    errorExit msgReallocError                   ;иначе выводим сообщение об ошибке и выходим из программы.
   
_realloc_ok:
   
    mov ax, 3D00h                               ;открываем файл конфигураций с доступом только для чтения.
    mov dx, offset fileName                     ;в dx заносим имя файла.
    int 21h                                     ;
    jnc _open_file_ok                           ;если файл удалось открыть, то переходим на метку _open_file_ok,      
    errorExit msgOpenError                      ;иначе выводим сообщение об ошибке и выходим из программы.
     
_open_file_ok:
   
    mov [fileHandler], ax                       ;заносим дескриптор файла в переменную fileHandler.
   
    mov ax, 4202h                               ;вызываем функцию 0х42 для установки указателя в (конец файла + CX + DX).
    mov bx, [fileHandler]                       ;в BX заносим дескриптор файла.
    xor cx, cx                                  ;обнуляем CX.
    xor dx, dx                                  ;обнуляем DX.
    int 21h                                     ;выполняем функцию.    
    jnc _get_size_ok                            ;если удалось сдвинуть указатель, то переходим на метку _get_size_ok,
    errorExit msgLSeekError                     ;иначе выводим сообщение об ошибке и выходим из программы.
 
_get_size_ok:
    cmp ax, 8                                   ;
    jg _label                          		;если длина файла > 8, то переходим на метку _read_last_char,
    errorExit msgFileParamsError                ;иначе выводим сообщение об ошибке и выходим из программы.

_label:                                         ;начало основного кода.
    call parseFile                              ;начинаем построчно парсить файл.
    ;EPB (EXEC Parameter Block) — блок параметров функции загрузки файла. Информация, которая должна содержаться
    ;в этом блоке, представлена в таблице:
    ;   +---------------+----------------+-------------------------------------------------+
    ;   |   Смещение    |   Длина(Байт)  |  Значение                                       |   
    ;   +---------------+----------------+-------------------------------------------------+
    ;   |      00h      |        2       |  Сегмент окружения DOS для порождаемого процесса|
    ;   |      02h      |        4       |  Смещение и сегмент адреса командной строки     |
    ;   |      06h      |        4       |  Первый адрес блока FCB                         |
    ;   |      0Ah      |        4       |  Второй адрес блока FCB                         |
    ;   |      0Eh      |        2       |  Длина EPB                                      |
    ;   +---------------+----------------+-------------------------------------------------+
    ;Заполняем поля EBP, содержащие сегментные адреса:
    mov ax, cs                                  ;
    mov word ptr [EPB + 4], ax                  ;Сегментный адрес командной строки.
    mov word ptr [EPB + 8], ax                  ;Сегментный адрес первого FCB.
    mov word ptr [EPB + 0Ch], ax                ;Сегментный адрес второго FCB.   
 
    mov ax, 4B00h                               ;Функция DOS 4Bh - загрузка и запуск программы (после отработки передать управление данной программе).
    mov dx, offset exeFileName                  ;имя файла, который надо запустить.
    mov bx, offset EPB                          ;блок EPB.
   
    push ds                                     ;сохраняем регистр ds.
    push es                                     ;сохраняем регистр es.
    pusha                                       ;сохраняем остальные регистры.
   
    mov ss_Seg, ss                              ;сохраняем сегментный регистр стека.
    mov sp_Seg, sp                              ;сохраняем указатель на вершину стека.
   
    int 21h                                     ;запускаем стороннюю программу.
    jnc _execute_file_ok                        ;если программа запустилась успешно, то переходим на метку _execute_file_ok,
    errorExit msgRunError                       ;иначе выводим сообщение об ошибке и выходим из программы.
 
_execute_file_ok:
   
    mov ss, cs:ss_Seg                           ;восстанавливаем сегментный регистр стека.
    mov sp, cs:sp_Seg                           ;восстанавливаем указатель на вершину стека.
;Примечние! т. к. мы не уверены, что отработанная программа не поменяла регистры ds, то обращаемся к переменным ss_Seg и sp_Seg,
;используя регистр cs, который, как мы уже знаем, всегда равен тому сегменту, в котором выполняется текущая команда.  
    popa                                        ;восстанавливаем регистры.
    pop es                                      ;восстанавливаем регистр es.
    pop ds                                      ;восстанавливаем регистр ds.
	
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
EPB                     dw 0000                 ;Использовать текущее окружение.
                        dw offset commandline, 0;Адрес командной строки.
                        dw 005Ch,0,006Ch,0      ;Адреса FCB, переданных DOS нашей программе при запуске (на самом деле они не используются).
commandline             db 0                    ;Максимальная длина командной строки.
                        db ''                   ;Буфер для командной строки
program_length          equ $ - start           ;Длина программы
end start
