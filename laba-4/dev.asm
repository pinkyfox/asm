readKeySR proc:
	push ax 					;сохраняем регистры
	push si
	push cx
	push bx
	push dx
	push di
	
	mov ah,1                ; функция проверки клавиатуры
	int 16h
	jz no_key_pressed
	
	xor ah,ah               ; функция чтения кода клавиши
	int 16h                 ; АН = код клавиши
	
	cmp ah, 1
	jz quit
  	cmp ah,4Bh 					;это ->?
  	jz leftSR 					;если да, то перейти к метке leftSR
  	cmp ah,4Dh 					;это <-?
  	jz rightSR                  ;если да, то перейти к метке rightSR
  	cmp ah,48h                  ;это ^?
  	jz spaceRot                 ;если да, то перейти к метке spaceRot
    
    xor ah,ah               ; функция чтения кода клавиши
	int 16h                 ; АН = код клавиши
	
	cmp ah, 1
	jz quit
  	cmp ah,4Bh 					;это ->?
  	jz leftSR 					;если да, то перейти к метке leftSR
  	cmp ah,4Dh 					;это <-?
  	jz rightSR                  ;если да, то перейти к метке rightSR
  	cmp ah,48h                  ;это ^?
  	jz spaceRot                 ;если да, то перейти к метке spaceRot
    
  	jmp termSR 					;если ни одна из перечисленных клавиш не была нажата, переходим
leftSR:
	call canMoveLeft 	     	;проверяем, можем ли мы сдвинуть фигуру влево
	cmp al,1                    ;можно ли сдвинуть фигуру влево
	jnz termSR                  ;если al != 1, termSR
leftyesSR:
  	call hideCurrentPiece       ;вызываем процедуру сокрытия фигуры
  	call moveLeft               ;вызываем процедуру сдвига влево
  	call showCurrentPiece       ;вызываем процедуру отрисовки фигуры

  	jmp termSR                  
; аналогично и  для сдвига вправо
rightSR:
	call canMoveRight 			
	cmp al,1
	jnz termSR  	
rightyesSR:
 	call hideCurrentPiece
  	call moveRight
  	call showCurrentPiece

  	jmp termSR

spaceRot:
	call hideCurrentPiece       ;вызываем процедуру сокрытия фигуры
	call rotatePiece            ;вызываем процедуру поворота фигуры
	call showCurrentPiece       ;вызываем процедуру отрисовки фигуры
	jmp termSR

quit:
	mov ax,4C00h
	int 21h
	
termSR:
	in al,60h 					;считываем с сопутствующим удалением из буфера символ
	in al,64h   				;считываем информацию из 64h порта
	and al,1 					;производим операцию побитового и 
	; бит №7 6 5 4 3 2 1 0
	   ; &                 -> в результате получаем 0000000x, если х:
	    ; 0 0 0 0 0 0 0 1   
	; признак наличия данных в выходном буфере (0 — буфер пуст, 1 — буфер содержит данные)
	cmp al,1 					;если бит 0 имеет значение 1, то буфер клавиатуры нуждается в очистке
	jz termSR 					;если буфер не пуст, ухожим к метке termSR
	
	pop di 						;восстанавливаем состояние решистров
	pop dx 
	pop bx
	pop cx
	pop si
	pop ax
no_key_pressed:
  	ret 						;возврат управления из обработчика прерывания 
readKeySR endp
































mov ch,0 					;счетчик фигур
mov dh,0 					;счетчик поворотов

onTimer proc:
whiletrue3:
	push si 					
	push ax
	push bx
	push dx
	
	mov	si,OFFSET SLOWDOWN      ;записываем адрес переменной SLOWDOWN 
	mov	al,[si]                 ;заносим значение по адресу si в al
	inc	al                      ;al++
	mov	[si],al                 ;записываем обратно значение в SLOWDOWN
	cmp	al,5					;slowdown равна 5
	jnz	timedone                ;если не равна переходим timedone
	xor al,al                   ;обнуляем al
	mov	[si],al                 ;записываем обратно значение в SLOWDOWN
	push cx                     
	call clearRow               ;вызываем процедуру clearRow
	call canMoveDown            ;вызываем процедуру canMoveDown
	pop cx						;можем ли мы двигаться вниз?
	cmp al,0 					;если нет
	jz setNewPiece				;возвращаемся и создаем новую фигуру

	push cx
	call hideCurrentPiece	 	;скрываем фигуру
	pop cx
	push cx
	call moveDown 				;спускаем ее вниз 
	pop cx
	push cx
	call showCurrentPiece 		;показываем ее снова
	pop cx

timedone:
	pop dx  					;восстанавливаем регистры
    pop bx
    pop ax
    pop si
    ret                        ;передаем управление из обработчика прерываний

setNewPiece:
	push ax 					;сохраняем регистры
	push es
	push di

	mov ax,code 				
	mov es,ax 
	mov di,offset rotationcount ;заносим в di ссылку на rotationcount
	mov [di],0 					;сбрасываем значение rotationcount

	pop di 						;восстанавливаем регистры 
	pop es
	pop ax

	inc ch
    cmp ch,7                    ;мы использовали 8 различных фигур?
	jnz wtcont 					;если нет, продолжаем
	mov ch,0 					;если да, сбрасываем счетчик
wtcont:	
	;si=piecenumber*8 + address_of_pieceline
	mov ax,9					;заносим в ax 9, потому что 1 это цвет
	mul ch 						;умножаем на номер фигуры
	mov si,offset x_line 		;загружаем начало массива фигур
	add si,ax   				;складываем указатели
	push cx
	call setPiece 				;заносим фигуру в currentX|Y
	pop cx
	call showCurrentPiece		;вызываем процедуру отображения

	;проверяем, конец ли игры
	push cx
	call canMoveDown			;можеи ли мы продвинуться вниз?
	pop cx
	cmp al,0 					;если нет, то переходим terminate
	jz terminate


 	mov    al,20h               ;сообщаем контроллеру,  
    out    20h,al    			;что прерывание окончено
	pop dx  					;восстанавливаем регистры
	pop bx
    pop ax
    pop si
	ret
terminate:
	mov ax,4C00h
	int 21h
onTimer endp