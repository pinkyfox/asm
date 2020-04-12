assume cs:code, ds:code, es
code segment
start: 
	mov	ax,code
	mov	ds,ax	                ;data segment указывает на метку code
	mov	bl,25					;кол-во строк в тетрисе
	mov	ax,0b800h				;ссылаемся на сегмент дисплея
	mov	es,ax					;заносим данную ссылку в es
	mov	di,000h					;смещение относительно сегмента 0b800h
initialize:
	mov	dl,10					;ширина игровой зоны
	mov	cl,34					;ширина левой и правой буфеных частей
  leftFill:
	mov	al,'*'					;символ '*' для записи в видеобуфер
	mov	es:[di],al				;записываем его по адресу 0b800h:di
	inc	di						;di++
	mov	al,0					;цвет символа '*' соответсвует 0
	mov	es:[di],al				;записывем цвет по адресу 0b00h:di+1
	inc	di						;di++ переходим к следующему символу
	dec	cl						;увеличиваем счетчик
	cmp	cl,0					;уменьшаем счеичик cl
	jnz	leftFill				;если не 0, продолжаем 
	mov	al,'*'					;начинаем рисовать левую границу, символ, который используется для строительства
	mov	es:[di],al				;заносим его в видеобуфер по адресу es:di
	inc	di						;di++
	mov	al,77h					;цвет элемента стены
	mov	es:[di],al				;заносим его цвет в видеобуфер по адресу es:di+1
	inc	di						;к переходим к следующему элементу
	mov	cl,10					;переустанавливаем счетчик
  center:		
	mov	al,' '					;заполнаем расстояние от стенки до стенки ' '
	mov	es:[di],al				;помещаем символ в видеобуфер по адресу es:di
	inc	di						;di++
	mov	al,0					;цвет символа
	mov	es:[di],al				;помещаем цвет символа в видеобуфер
	inc	di						;переходим к следующему символу		
	cmp	bl,1					;проверяем, не последняя ли это строка
	jnz	inner1					;если нет, то мы не должны рисовать нижний ограничитель
	sub	di,2					;если да, то откатываемся на 2 позиции назад(символ + цвет) 
	mov	al,'*'					;символ для отрисовки нижнего сепаратора
	mov	es:[di],al				;сохраняем его в видеобуфер по адресу es:di
	inc	di						;di++
	mov	al,77h					;цвет пэлементарного сепаратора
	mov	es:[di],al				;сохраняем цвет в видеобуфер по адресу es:di+1
	inc	di						;переходим к следующему символу
  inner1:	
    dec	cl				        ;уменьшаем счетчик на 1
	cmp	cl,0					;закончили ли мы отрисовывать центр?
	jnz	center					;если нет, рисуем снова
	mov	cl,34					;если да, переустанавиваем счетчик
	mov	al,'*'					;рисуем правую границу
	mov	es:[di],al				;сохраняем символ в видеобуфер по адресу es:di
	inc	di						;di++
	mov	al,77h					;цвет символа
	mov	es:[di],al				;сохраняем цвет символа в видеобуфер по адресу es:di+1
	inc	di						;к следующему символу
  rightFill:
	mov	al,'*'					;запоняем правую буферную зону
	mov	es:[di],al				;сохраняем символ в видеобуфер
	inc	di						;id++ 
	mov	al,0					;цвет символа
	mov	es:[di],al				;сохраняем цвет символа в видеобуфере
	inc	di						;переходим к следующему символу
	dec	cl						;уменьшаем счетчик
	cmp	cl,0					;счетчик равен 0?
	jnz	rightFill				;если нет, продолжаенм отрисовку
	dec	bl						;уменьшаем счетчик строк
	cmp	bl,0					;отрисовали ли мы все строки?
	jnz	initialize				;если нет, продолжаем отрисовку


	mov dh,0 					;счетчик поворотов
	mov ch,0 
	 
	mov si,offset x_line 		;записываем адрес первого эелемента в si
    call setPiece 				;вызываем процедуру становки фигуры
    call showCurrentPiece 		;вызываем процедуру отрисовки фигуры
hang:
;**********MAIN CODE**********  
    push cx
	mov cx,0
	mov dx, 0EA60h 
	mov ah,86h
	int 15h 
	pop cx
	call onTimer
	call readKeySR
	jmp hang
;
;**********setPixel**********
setPixel:
	push bx                     
	push ax
	mov di,000h					;выставляем указатель в начало видеобуфера
	mov ax,160					;размер видеобуфера 80*2  34 кирпичиков - ограничитель - 10 пустот - ограничитель - 34 кирпичика 
	mul bl						;умножаем на кол-во строк
	add di,ax					;                                      
	mov ax,2					;размер столбца
	add bh,34					;умножаем на отступ в 34 кирпичика
	mul bh
	add di,ax
	inc di						;переводим di на установку цвета
	mov es:[di],dl				;устанавливаем цвет
	pop ax                      ;восстанавливаем регистры
	pop bx
	ret

;**********getPixel**********
getPixel:
	push bx
	mov di,000h					;выставляем указатель на начало видеобуфера
	mov ax,160					;видео-память имеет разамер строки в 160 байт 
	mul bl						;умножаем на строки 
	add di,ax					;добовляем позицию ряда в ВП
	mov ax,2					;2байта размер столбца
	add bh,34					;отступ, чтобы получить первую колонку игровой зоны
	mul bh						;определяем, на какой мы колонке 
	add di,ax					;добавляем в память отступ
	mov	ah,es:[di]				;загружаем символ в аh, который располагался по адресу
	inc di						;переводим di на цвет
	mov al,es:[di]				;цвет сохраняем в al
	pop bx
	ret

;**********setPiece**********
setPiece:
	xor cl,cl                   ;обнуляем счетчик
  sploop:
	mov dl,[si]					;устанавливаем dl столбец и строку той фигуры, которую необходимо обработать
	push dx						;заносим dl в стек через dx
	inc	si 						;продвигаемся дальше
	inc cl 						;увеличиваем счетчик
	cmp cl,9 					;сделали мы это 9 раз?
	jnz	sploop 					;если нет, продолжаем
	mov si,OFFSET currentX		;заносим в si адрес currentX
	add si,8 					;+8 чтобы сослаться на конец текущего куска
  spcurrent:
	pop dx						;pop в dl
	mov [si],dl					;заносим dl в si
	dec si 						;уменьшаем на 1 si
 	dec cl 						;уменьшаем счетчик
	cmp	cl,0 					;если это мы проделали менее 8 раз
	jnz spcurrent 				;возвращаемся и проделываем данную операцию снова
	ret

;**********showCurrentPiece**********
showCurrentPiece:
	xor cl,cl 					;обнуляем счетчик
	mov si,OFFSET currentX 		;ссылаемся на текущий кусок
	mov	dl,[si]					;цвет для отрисовки куска
	inc si						;сдвигаемся к первому значению
  scploop:
	mov bl,[si+4] 				;заносим ряд
	mov bh,[si] 				;заносим колонку
	call setPixel
	inc si 						;si++
	inc cl 						;приращиваем счетчик
	cmp cl,4 					;эо произошло 4 раза?
	jnz scploop 				;если нет, повторяем
	ret

;**********hideCurrentPiece**********
;красит фигуру в черный
hideCurrentPiece:
	xor	cl,cl					;счетчик нуль
	mov	si,OFFSET currentX		;ссылка на текущий элемент
	inc	si						;подбираемс к 1 элементу (0 элемент -- цвет)
	mov	dl,0					;новый цвет черный
  hideLoop:
	mov	bh,[si]					;утснавливаем индекс столбца
	mov	bl,[si+4]				;устанавливаем индекс строки
	call setPixel
	inc	si						;двигаемся вперед
	inc	cl						;увеличиваем счетчик
	cmp	cl,4					;проделали ли мы это 4 раза?
	jnz	hideLoop				;если нет, повторяем
	ret

;**********blockPixel**********
;конвертируем фигуры в кирпичики
 blockPixel:
	mov di,000h					;выставляем указатель на 0
	mov ax,160					;размер строки 80*2
	mul bl						;умнажаем на строки
	add di,ax					;добавляем смещение к адресу
	mov ax,2					;размер колонки 2 байта
	add bh,34					;заносим отступ колонок
	mul bh                      ;умножаем размер на кол0во колонок
	add di,ax                   ;добавляем смещение к адресу
	mov al,'*'					;заносим '*' в al
	mov es:[di],al 				;заносим кирпичик в память
	inc di						;переводим указатель на установку цвета
	;this is where we should comment out below
	mov es:[di],dl				;устанавливаем цвет 
	ret

;**********blockPiece**********    
;принимаем текущий кусок и вызываем blockPixel для него
blockPiece:
	xor cl,cl 					;счетчк в 0
	mov si,OFFSET currentX 		;заносим адрес на текущий кусок
	mov	dl,[si]					;цвет куска
	inc si						;переходим к первому значению
  bploop:
	mov bl,[si+4] 				;строка
	mov bh,[si] 				;столбец
	call blockPixel				;конвертируем фигуру в кирпичики 
	inc si 						;si++
	inc cl 						;увеличиваем счетчики
	cmp cl,4 					;мы это сделали 4 раза?
	jnz bploop 					;если нет, делаем снова
	ret

;**********canMoveDown**********
;Определет может ли фигура опускаться ниже?
	;getPixel принимает:  
					;  bl = currentPiece row + 1
					;  bh = column
	;getPixel возвращает:	
					;  al = цвет bl
					;  ah = символ bl
	;returns:	
					;  al = 1 если можно, 0 -- нельзя
canMoveDown:
	mov	si,OFFSET currentX		;переходим к адресу текущей фигуры
	inc	si						;переходим к ее форме
	xor	cl,cl					;сбрасываем счетчик
  downLoop:
  	mov	al,1					;заносим "true" в al, если мы можем двигаться вниз
  	cmp	cl,4					;просмотрели ли мы все значения row+1?
  	jz	clear					;ели да, вернем "true"
	mov	bh,[si]					;значение столбца кладем в bh
	mov	bl,[si+4]				;кладем соответсвующее ему значение строки в bl
	inc	bl						;мы хотим получить символ, который находится под текущей строкой,  строка + 1
	call getPixel               ;вызываем функцию получения пикселя
	inc	cl						;увеличиваем счетчик
	inc	si						;переходим дальше
	cmp	ah,'*'					;является ли значение под текушей фигурой '*'
	jz	blocked					;  если да, возвращаем 0
	jnz	downLoop				;  если нет, повторяем
  blocked:
  	call blockPiece             ; блокируем фигуру
  	xor al,al
  	ret
  clear:
  	ret

;**********canMoveLeft**********
;Определяет можно ли фигуре сдвинуться влево
	;getPixel:
					;  bl = currentPiece row
					;  bh = currentPiece column - 1
	;getPixel:	
					;  al = цвет
					;  ah = символ
	;returns:
					;  al = 1, если можно и 0, если нельзя
					
canMoveLeft:
	mov	si,OFFSET currentX		;заносим адрес текущей фигуры
	inc	si						;переходим к данным	
	mov	cl,0					;сбрасываем счетчики
 leftLoop:
  	mov	al,1					;полагаем, что движение влево возможно
  	cmp	cl,4					;мы просмотрели 4 столбца?
  	jz	clear					;если да return true (1)
  	mov	bh,[si]					;заносим значение солбца в bh
  	dec	bh						;сдвигаемся влево на позицию
  	mov	bl,[si+4]				;значение строки помещаем в bl
  	inc	cl						;увеличиваем счетчики
	inc	si						;переходим к следующему куску памяти
  	call getPixel               ;получаем пиксель
  	cmp	ah,'*'					;это кирпичик, '*'?
  	jz	blockedcml				;если да, то return 0
  	jnz	leftLoop				;если нет, пробуем снова
  blockedcml:
  	xor al,al
  	ret

;**********canMoveRight**********
; Определяет можно ли фигуре сдвинуться вправо
	;getPixel:
					;  bl = currentPiece row
					;  bh = currentPiece column + 1
	;getPixel:	
					;  al = цвет
					;  ah = символ
	;returns:
					;  al = 1, если можно сдвинуться вправо, иначе 0
canMoveRight:
	mov	si,OFFSET currentX		;ссылаемся на текущую фигуру
	inc	si						;переходим к символам
	mov	cl,0					;сбрасываем счетчики
  rightLoop:
  	mov	al,1					;полагаем что сдвинуться вправо можно
  	cmp	cl,4					;мы просмотрели все 4 столбца?
  	jz	clear					;если да то, return true
  	mov	bh,[si]					;заносим столбец в bh
  	inc	bh						;сдвигаемся вправо путем приращения компоненты 
  	mov	bl,[si+4]				;заносим строку в bl
  	inc	cl						;увеличиваем счетчики
	inc	si						;к следующему значению
  	call getPixel				;получаем пиксель позиции si + 1, si + 4
  	cmp	ah,'*'					;это кирпичик '*'?
  	jz	blockedcmr				;если да то, return false
  	jnz	rightLoop				;иначе повторяем
blockedcmr:
  	xor al,al
  	ret


;**********moveDown**********
 ;сдвигает фигуру на одну строку вниз
moveDown:
	mov	si,OFFSET currentX
	mov	dl,[si]					;цвет фигуры заносим в dl
	inc	si						;переходим к контексту
	mov	cl,0					;сбрасываем счетчики
  incrRows:
  	inc	cl						;увеличиваем счетчик 
  	mov	bl,[si+4]				;заносим строку в bl
  	inc bl						;увеличиваем значение строки на 1
  	mov	[si+4],bl				;заносим обратно в память увеличенное значение строки
  	inc si						;продвигаемся дальше по контексту 
  	cmp	cl,4					;мы это проделали 4 раза?
  	jnz	incrRows				;если нет, повторяем 
  	ret							

;**********moveLeft**********
;сдвиг фигуры на одну колонку влево
moveLeft:
	mov	si,OFFSET currentX		;ссылаемся на текущий кусок
	inc	si						;переходим к контексту
	mov	cl,0					;сбрасываем счетчики
  incCols:
  	inc	cl						;увеличиваем счетчики
  	mov	bl,[si]					;столбец помещаем в bl
  	dec	bl						;сдвигаемся на столбец левее
  	mov	[si],bl					;заносим новое значение стобца обратно
  	inc	si						;к следующему столбцу
  	cmp	cl,4					;прошли ли мы все столбцы?
  	jnz	incCols					;если нет, повторяем
  	ret

;**********moveRight**********
;сдвиг фигуры на одну колонку вправо
moveRight:
	mov	si,OFFSET currentX		
	inc	si						;переходим к контексту
	mov	cl,0					;сбрасываем счетчик
  decCols:
  	inc	cl						;увеличиваем счетчик
  	mov	bl,[si]					;заносим столбец в bl
  	inc	bl						;увеличиваем номер колонки на 1
  	mov	[si],bl					;заносим новое значение (колонка + 1) обратно в память
  	inc	si						;двигаемся к следующему столбцу
  	cmp	cl,4					;мы это повторили 4 раза?
  	jnz	decCols					;если нет, повторяем еще раз
  	ret

;**********readKeySR**********
readKeySR proc
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
    mov ax,03
    int 10h
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
	
no_key_pressed:
    pop di 						;восстанавливаем состояние регистров
	pop dx 
	pop bx
	pop cx
	pop si
	pop ax
  	ret 						;возврат управления из обработчика прерывания 
readKeySR endp

;**********clearRow**********
clearRow:
	push bx 					;сохраняем регистры
	push ax
	push dx
	push di
	push es

	mov bl,0                	;строка, начинаем с первой строки
	mov bh,1                	;столбец, начинаем с первого столбца
foreachcolumn:
	call getPixel 				;получем пиксель
	cmp ah,'*' 					;если это не кирпичик
	jnz foreachrow 				;переходим к foreachrow
	inc bh 						;увеличиваем столбец
	cmp bh,11 					;мы прошли 10 столбцов?
	jnz foreachcolumn 			;если нет, повторяем
	mov bh,1  					;сбрасываем столбцы
	jmp crEND 					;переходим к очистке
foreachrow:
	mov bh,1 					;сбрасываем счетчик колонок
	inc bl 						;увеличиваем строки
	cmp bl,24 					;мы пршли 24 ряда?
	jnz foreachcolumn 			;если нет, продолжаем проверку колонок
	jmp cRterm 					;если да, то переходим к cRterm 

crEND:
	dec bl 						;переходим на строку выше
	call getPixel 				;получаем пиксель 
	dec di 						;откатываемся на контекст
	mov es:[di],' ' 			;заменяем содержимое пробелом
	inc di 						;возвращаемся к цвету
	inc bl 						;возвращяемся к ряду, который мы очищали
	mov dl,al 					;заносим цвет в dl
	call setPixel 				;устанавливаем пиксель
	dec di 						;назад к контексту
	mov es:[di],ah 				;записываем символ, который был сверху
	inc di 						;переходим к цвету
	inc bh 						;увеличиваем столбцы
	cmp bh,11 					;мы обработали 10 столбцов?
	jnz crEND 					;если нет, наинаем сначала
	mov bh,1 					;сбрасываем столбцы
	dec bl 						;поднимаемся на ряд выше
	cmp bl,0 					;достигли ли мы вершины?
	jnz crEND 					;если нет, повторяем снова
	jmp cRterm 					;если да, переходим к концу
cRterm:
	pop es 						;восстанавливаем регистры 
	pop di
	pop dx
	pop ax
	pop bx
	ret 						;возвращаемс

onTimer proc
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
	
	mov ch, [figureCounter]
	inc ch
    cmp ch,7                    ;мы использовали 8 различных фигур?
	jnz wtcont 					;если нет, продолжаем
	mov ch,0 					;если да, сбрасываем счетчик
	mov byte ptr [figureCounter], ch
wtcont:
	mov byte ptr [figureCounter], ch
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

	pop dx  					;восстанавливаем регистры
	pop bx
    pop ax
    pop si
	ret
terminate:  
    call gameOver
    mov ah, 1
    int 21h  
    mov ax,03
    int 10h
	mov ax,4C00h
	int 21h
onTimer endp 

gameOver proc  
    mov ax,03
    int 10h 
    mov ax, 0b800h
    mov es, ax
    mov di, 1760
    mov cx, 160
    mov si, offset gameOverMsg
loop1:     
    mov al, byte ptr [si]   
    mov es:[di],al
    inc di
    inc si      
    mov al, byte ptr [si]   
    mov es:[di],al
    inc di
    inc si
    loop loop1     
    ret
gameOver endp

rotatePiece:
	push es 				    ;сохраняем регистры
	push di
	push ds
	push si
	push cx
	push ax

	mov ax,code 					
	mov es,ax 
	mov di,offset rotationcount 	;выставляем указатель на rotationcount
	mov dh,[di] 					;заносим rotationcount значение в dh
	cmp dh,4 						;нужно сделать 4 оборота?
	jnz rpcont 						;если нет, продолжаем
	mov dh,0 						;сброс rotationcount

rpcont:
	xor cl,cl 						;сбрасываем счетчик

	mov si,offset currentX 			;заносим в si указатель на currentpiece
	inc si 							;переходим к контексту 

	
	mov di,offset r1x_line 			;заносим в di адрес начало массива фигур вращенияя
	inc di 							;мы на первой строке

	mov ax,36 						;умножаем размер 4-ех массивов фигур поворота
	mul ch 				 			;на piecenumber
	add di,ax 						;и добавляем к di

	
	mov ax,9 						;заносим размер одного массива
	mul dh 							;умножаем на rotationcount
	add di,ax 						;добавляем результат к di, чтобы сослаться на корректный массив поворота
rotation:

	mov al,[si] 		 			;заносим значение currentpiece указаетлся в al			

	mov ah,[di] 					;заносим значение rotation указателя в ah	

	add al,ah 						;складываем значения

	mov [si],al 					;заносим al в currentpiece 

	inc si 							;продвигаемся дальше по массиву
	inc di 							;продвигаемся дальше по массиву
	inc cl 							;увеличиваем счетчик
	cmp cl,8 						;мы перезаписали все 8 элементов массива
	jnz rotation                    ;если нет, то повторяем операцию

	inc dh 							;rotationcounter++
	mov di,offset rotationcount 	;ссылаемся на rotationcount
	mov [di],dh 					;изменяем rotationcount на то, что хранитяс в dh


	pop ax 							;восстанавливаем регистры
	pop cx
	pop si
	pop ds
	pop di
	pop es
	ret 							;return



;**********TETRIS SHAPES WITH COLORS**********
x_line     db      22h,5,5,5,5
y_line     db      0,1,2,3
x_l        db      55h,5,6,7,5
y_l        db      0,0,0,1
x_r        db      33h,5,6,7,7
y_r        db      0,0,0,1

x_s        db      11h,5,6,6,7
y_s        db      1,1,0,0

x_z        db      44h,5,6,6,7
y_z        db      0,0,1,1

x_t        db      22h,5,6,7,6
y_t        db      0,0,0,1
x_box      db      66h,5,6,5,6
y_box      db      0,0,1,1

;**********CURRENT PIECE**********
currentX 	db      0,0,0,0,0		;holds the color & column values of the current piece being rendered
currentY 	db      0,0,0,0			;holds the row values of the current piece being rendered

;**********COLORS**********
midCol		db		77h				;light gray background and text
wallCol		db		88h				;dark gray background and text
black		db		00h				;black background, black text
space		db		32				;the ascii char for an empty space
redBack		db		44h				;the color value for red background
blueBack	db		11h				;the color value for a blue background
cyanBack	db		33h				;the color value for a cyan background
greenBack	db		22h				;the color value for a green background

;**********ROTATIONS**********
;we add these to the current piece array to get rotated pieces
r1x_line     db      0,-1,0,1,2
r1y_line     db      1,0,-1,-2
r2x_line     db      0,1,0,-1,-2
r2y_line     db      -1,0,1,2
r3x_line     db      0,-1,0,1,2
r3y_line     db      1,0,-1,-2
r4x_line     db      0,1,0,-1,-2
r4y_line     db      -1,0,1,2

r1x_l        db      0,0,0,-1,1 		
r1y_l        db      0,0,1,1 		 	
r2x_l        db      0,0,0,1,1
r2y_l        db      1,1,0,-2
r3x_l        db      0,0,-1,-2,-1
r3y_l        db      -1,0,1,2
r4x_l        db      0,0,1,2,-1
r4y_l        db      0,-1,-2,-1

r1x_r      db      0,0,0,-1,-1
r1y_r      db      2,0,1,1
r2x_r      db      0,0,0,1,-1
r2y_r      db      -1,1,0,-2
r3x_r      db      0,0,-1,-2,1
r3y_r      db      -1,0,1,0
r4x_r      db      0,0,1,2,1
r4y_r      db      0,-1,-2,1

r1x_s      db      0,0,-1,0,-1
r1y_s      db      -1,0,1,2
r2x_s      db      0,0,1,0,1
r2y_s      db      1,0,-1,-2
r3x_s      db      0,0,-1,0,-1
r3y_s      db      -1,0,1,2
r4x_s      db      0,0,1,0,1
r4y_s      db      1,0,-1,-2

r1x_z      db      0,0,-1,0,-1
r1y_z      db      1,2,0,-1
r2x_z      db      0,0,1,0,1
r2y_z      db      -1,-2,0,1
r3x_z      db      0,0,-1,0,-1
r3y_z      db      1,2,0,-1
r4x_z      db      0,0,1,0,1
r4y_z      db      -1,-2,0,1

r1x_t      db      0,0,0,-1,0
r1y_t      db      1,0,1,1
r2x_t      db      0,0,0,1,0
r2y_t      db      0,1,0,-2
r3x_t      db      0,0,-1,-2,0
r3y_t      db      -1,0,1,1
r4x_t      db      0,0,1,2,0
r4y_t      db      0,-1,-2,0

r1x_box      db      0,0,0,0,0
r1y_box      db      0,0,0,0
r2x_box      db      0,0,0,0,0
r2y_box      db      0,0,0,0
r3x_box      db      0,0,0,0,0
r3y_box      db      0,0,0,0
r4x_box      db      0,0,0,0,0
r4y_box      db      0,0,0,0

gameOverMsg db '*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'G',10000100b,'A',10000010b,'M',10000011b,'E',10000101b,' ',0,' ',0,'O',10000100b,'V',10000010b,'E',10000011b,'R',10000101b,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,
			db   '*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'P',10000100b,'R',10000010b,'E',10000011b,'S',10000101b,'S',10000100b,' ',0,'A',10000010b,'N',10000011b,'Y',10000101b,' ', 0,'K',10000100b,'E',10000010b,'Y',10000011b,' ',0,'T',10000101b,'O',10000100b,'*',0,'E',10000010b,'X',10000011b,'I',10000101b,'T',10000100b,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0,'*',0
 
rotationcount db 0
figureCounter db 0

SLOWDOWN	db		0

code	ends
end	start