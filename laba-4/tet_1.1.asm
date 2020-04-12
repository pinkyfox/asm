assume cs:code, ds:code, es
code segment
start: 
	mov	ax,code
	mov	ds,ax	                ;data segment ��������� �� ����� code
	mov	bl,25					;���-�� ����� � �������
	mov	ax,0b800h				;��������� �� ������� �������
	mov	es,ax					;������� ������ ������ � es
	mov	di,000h					;�������� ������������ �������� 0b800h
initialize:
	mov	dl,10					;������ ������� ����
	mov	cl,34					;������ ����� � ������ ������� ������
  leftFill:
	mov	al,'*'					;������ '*' ��� ������ � ����������
	mov	es:[di],al				;���������� ��� �� ������ 0b800h:di
	inc	di						;di++
	mov	al,0					;���� ������� '*' ������������ 0
	mov	es:[di],al				;��������� ���� �� ������ 0b00h:di+1
	inc	di						;di++ ��������� � ���������� �������
	dec	cl						;����������� �������
	cmp	cl,0					;��������� ������� cl
	jnz	leftFill				;���� �� 0, ���������� 
	mov	al,'*'					;�������� �������� ����� �������, ������, ������� ������������ ��� �������������
	mov	es:[di],al				;������� ��� � ���������� �� ������ es:di
	inc	di						;di++
	mov	al,77h					;���� �������� �����
	mov	es:[di],al				;������� ��� ���� � ���������� �� ������ es:di+1
	inc	di						;� ��������� � ���������� ��������
	mov	cl,10					;����������������� �������
  center:		
	mov	al,' '					;��������� ���������� �� ������ �� ������ ' '
	mov	es:[di],al				;�������� ������ � ���������� �� ������ es:di
	inc	di						;di++
	mov	al,0					;���� �������
	mov	es:[di],al				;�������� ���� ������� � ����������
	inc	di						;��������� � ���������� �������		
	cmp	bl,1					;���������, �� ��������� �� ��� ������
	jnz	inner1					;���� ���, �� �� �� ������ �������� ������ ������������
	sub	di,2					;���� ��, �� ������������ �� 2 ������� �����(������ + ����) 
	mov	al,'*'					;������ ��� ��������� ������� ����������
	mov	es:[di],al				;��������� ��� � ���������� �� ������ es:di
	inc	di						;di++
	mov	al,77h					;���� �������������� ����������
	mov	es:[di],al				;��������� ���� � ���������� �� ������ es:di+1
	inc	di						;��������� � ���������� �������
  inner1:	
    dec	cl				        ;��������� ������� �� 1
	cmp	cl,0					;��������� �� �� ������������ �����?
	jnz	center					;���� ���, ������ �����
	mov	cl,34					;���� ��, ���������������� �������
	mov	al,'*'					;������ ������ �������
	mov	es:[di],al				;��������� ������ � ���������� �� ������ es:di
	inc	di						;di++
	mov	al,77h					;���� �������
	mov	es:[di],al				;��������� ���� ������� � ���������� �� ������ es:di+1
	inc	di						;� ���������� �������
  rightFill:
	mov	al,'*'					;�������� ������ �������� ����
	mov	es:[di],al				;��������� ������ � ����������
	inc	di						;id++ 
	mov	al,0					;���� �������
	mov	es:[di],al				;��������� ���� ������� � �����������
	inc	di						;��������� � ���������� �������
	dec	cl						;��������� �������
	cmp	cl,0					;������� ����� 0?
	jnz	rightFill				;���� ���, ����������� ���������
	dec	bl						;��������� ������� �����
	cmp	bl,0					;���������� �� �� ��� ������?
	jnz	initialize				;���� ���, ���������� ���������


	mov dh,0 					;������� ���������
	mov ch,0 
	 
	mov si,offset x_line 		;���������� ����� ������� ��������� � si
    call setPiece 				;�������� ��������� �������� ������
    call showCurrentPiece 		;�������� ��������� ��������� ������
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
	mov di,000h					;���������� ��������� � ������ �����������
	mov ax,160					;������ ����������� 80*2  34 ���������� - ������������ - 10 ������ - ������������ - 34 ��������� 
	mul bl						;�������� �� ���-�� �����
	add di,ax					;                                      
	mov ax,2					;������ �������
	add bh,34					;�������� �� ������ � 34 ���������
	mul bh
	add di,ax
	inc di						;��������� di �� ��������� �����
	mov es:[di],dl				;������������� ����
	pop ax                      ;��������������� ��������
	pop bx
	ret

;**********getPixel**********
getPixel:
	push bx
	mov di,000h					;���������� ��������� �� ������ �����������
	mov ax,160					;�����-������ ����� ������� ������ � 160 ���� 
	mul bl						;�������� �� ������ 
	add di,ax					;��������� ������� ���� � ��
	mov ax,2					;2����� ������ �������
	add bh,34					;������, ����� �������� ������ ������� ������� ����
	mul bh						;����������, �� ����� �� ������� 
	add di,ax					;��������� � ������ ������
	mov	ah,es:[di]				;��������� ������ � �h, ������� ������������ �� ������
	inc di						;��������� di �� ����
	mov al,es:[di]				;���� ��������� � al
	pop bx
	ret

;**********setPiece**********
setPiece:
	xor cl,cl                   ;�������� �������
  sploop:
	mov dl,[si]					;������������� dl ������� � ������ ��� ������, ������� ���������� ����������
	push dx						;������� dl � ���� ����� dx
	inc	si 						;������������ ������
	inc cl 						;����������� �������
	cmp cl,9 					;������� �� ��� 9 ���?
	jnz	sploop 					;���� ���, ����������
	mov si,OFFSET currentX		;������� � si ����� currentX
	add si,8 					;+8 ����� ��������� �� ����� �������� �����
  spcurrent:
	pop dx						;pop � dl
	mov [si],dl					;������� dl � si
	dec si 						;��������� �� 1 si
 	dec cl 						;��������� �������
	cmp	cl,0 					;���� ��� �� ��������� ����� 8 ���
	jnz spcurrent 				;������������ � ����������� ������ �������� �����
	ret

;**********showCurrentPiece**********
showCurrentPiece:
	xor cl,cl 					;�������� �������
	mov si,OFFSET currentX 		;��������� �� ������� �����
	mov	dl,[si]					;���� ��� ��������� �����
	inc si						;���������� � ������� ��������
  scploop:
	mov bl,[si+4] 				;������� ���
	mov bh,[si] 				;������� �������
	call setPixel
	inc si 						;si++
	inc cl 						;����������� �������
	cmp cl,4 					;�� ��������� 4 ����?
	jnz scploop 				;���� ���, ���������
	ret

;**********hideCurrentPiece**********
;������ ������ � ������
hideCurrentPiece:
	xor	cl,cl					;������� ����
	mov	si,OFFSET currentX		;������ �� ������� �������
	inc	si						;���������� � 1 �������� (0 ������� -- ����)
	mov	dl,0					;����� ���� ������
  hideLoop:
	mov	bh,[si]					;������������ ������ �������
	mov	bl,[si+4]				;������������� ������ ������
	call setPixel
	inc	si						;��������� ������
	inc	cl						;����������� �������
	cmp	cl,4					;��������� �� �� ��� 4 ����?
	jnz	hideLoop				;���� ���, ���������
	ret

;**********blockPixel**********
;������������ ������ � ���������
 blockPixel:
	mov di,000h					;���������� ��������� �� 0
	mov ax,160					;������ ������ 80*2
	mul bl						;�������� �� ������
	add di,ax					;��������� �������� � ������
	mov ax,2					;������ ������� 2 �����
	add bh,34					;������� ������ �������
	mul bh                      ;�������� ������ �� ���0�� �������
	add di,ax                   ;��������� �������� � ������
	mov al,'*'					;������� '*' � al
	mov es:[di],al 				;������� �������� � ������
	inc di						;��������� ��������� �� ��������� �����
	;this is where we should comment out below
	mov es:[di],dl				;������������� ���� 
	ret

;**********blockPiece**********    
;��������� ������� ����� � �������� blockPixel ��� ����
blockPiece:
	xor cl,cl 					;������ � 0
	mov si,OFFSET currentX 		;������� ����� �� ������� �����
	mov	dl,[si]					;���� �����
	inc si						;��������� � ������� ��������
  bploop:
	mov bl,[si+4] 				;������
	mov bh,[si] 				;�������
	call blockPixel				;������������ ������ � ��������� 
	inc si 						;si++
	inc cl 						;����������� ��������
	cmp cl,4 					;�� ��� ������� 4 ����?
	jnz bploop 					;���� ���, ������ �����
	ret

;**********canMoveDown**********
;��������� ����� �� ������ ���������� ����?
	;getPixel ���������:  
					;  bl = currentPiece row + 1
					;  bh = column
	;getPixel ����������:	
					;  al = ���� bl
					;  ah = ������ bl
	;returns:	
					;  al = 1 ���� �����, 0 -- ������
canMoveDown:
	mov	si,OFFSET currentX		;��������� � ������ ������� ������
	inc	si						;��������� � �� �����
	xor	cl,cl					;���������� �������
  downLoop:
  	mov	al,1					;������� "true" � al, ���� �� ����� ��������� ����
  	cmp	cl,4					;����������� �� �� ��� �������� row+1?
  	jz	clear					;��� ��, ������ "true"
	mov	bh,[si]					;�������� ������� ������ � bh
	mov	bl,[si+4]				;������ �������������� ��� �������� ������ � bl
	inc	bl						;�� ����� �������� ������, ������� ��������� ��� ������� �������,  ������ + 1
	call getPixel               ;�������� ������� ��������� �������
	inc	cl						;����������� �������
	inc	si						;��������� ������
	cmp	ah,'*'					;�������� �� �������� ��� ������� ������� '*'
	jz	blocked					;  ���� ��, ���������� 0
	jnz	downLoop				;  ���� ���, ���������
  blocked:
  	call blockPiece             ; ��������� ������
  	xor al,al
  	ret
  clear:
  	ret

;**********canMoveLeft**********
;���������� ����� �� ������ ���������� �����
	;getPixel:
					;  bl = currentPiece row
					;  bh = currentPiece column - 1
	;getPixel:	
					;  al = ����
					;  ah = ������
	;returns:
					;  al = 1, ���� ����� � 0, ���� ������
					
canMoveLeft:
	mov	si,OFFSET currentX		;������� ����� ������� ������
	inc	si						;��������� � ������	
	mov	cl,0					;���������� ��������
 leftLoop:
  	mov	al,1					;��������, ��� �������� ����� ��������
  	cmp	cl,4					;�� ����������� 4 �������?
  	jz	clear					;���� �� return true (1)
  	mov	bh,[si]					;������� �������� ������ � bh
  	dec	bh						;���������� ����� �� �������
  	mov	bl,[si+4]				;�������� ������ �������� � bl
  	inc	cl						;����������� ��������
	inc	si						;��������� � ���������� ����� ������
  	call getPixel               ;�������� �������
  	cmp	ah,'*'					;��� ��������, '*'?
  	jz	blockedcml				;���� ��, �� return 0
  	jnz	leftLoop				;���� ���, ������� �����
  blockedcml:
  	xor al,al
  	ret

;**********canMoveRight**********
; ���������� ����� �� ������ ���������� ������
	;getPixel:
					;  bl = currentPiece row
					;  bh = currentPiece column + 1
	;getPixel:	
					;  al = ����
					;  ah = ������
	;returns:
					;  al = 1, ���� ����� ���������� ������, ����� 0
canMoveRight:
	mov	si,OFFSET currentX		;��������� �� ������� ������
	inc	si						;��������� � ��������
	mov	cl,0					;���������� ��������
  rightLoop:
  	mov	al,1					;�������� ��� ���������� ������ �����
  	cmp	cl,4					;�� ����������� ��� 4 �������?
  	jz	clear					;���� �� ��, return true
  	mov	bh,[si]					;������� ������� � bh
  	inc	bh						;���������� ������ ����� ���������� ���������� 
  	mov	bl,[si+4]				;������� ������ � bl
  	inc	cl						;����������� ��������
	inc	si						;� ���������� ��������
  	call getPixel				;�������� ������� ������� si + 1, si + 4
  	cmp	ah,'*'					;��� �������� '*'?
  	jz	blockedcmr				;���� �� ��, return false
  	jnz	rightLoop				;����� ���������
blockedcmr:
  	xor al,al
  	ret


;**********moveDown**********
 ;�������� ������ �� ���� ������ ����
moveDown:
	mov	si,OFFSET currentX
	mov	dl,[si]					;���� ������ ������� � dl
	inc	si						;��������� � ���������
	mov	cl,0					;���������� ��������
  incrRows:
  	inc	cl						;����������� ������� 
  	mov	bl,[si+4]				;������� ������ � bl
  	inc bl						;����������� �������� ������ �� 1
  	mov	[si+4],bl				;������� ������� � ������ ����������� �������� ������
  	inc si						;������������ ������ �� ��������� 
  	cmp	cl,4					;�� ��� ��������� 4 ����?
  	jnz	incrRows				;���� ���, ��������� 
  	ret							

;**********moveLeft**********
;����� ������ �� ���� ������� �����
moveLeft:
	mov	si,OFFSET currentX		;��������� �� ������� �����
	inc	si						;��������� � ���������
	mov	cl,0					;���������� ��������
  incCols:
  	inc	cl						;����������� ��������
  	mov	bl,[si]					;������� �������� � bl
  	dec	bl						;���������� �� ������� �����
  	mov	[si],bl					;������� ����� �������� ������ �������
  	inc	si						;� ���������� �������
  	cmp	cl,4					;������ �� �� ��� �������?
  	jnz	incCols					;���� ���, ���������
  	ret

;**********moveRight**********
;����� ������ �� ���� ������� ������
moveRight:
	mov	si,OFFSET currentX		
	inc	si						;��������� � ���������
	mov	cl,0					;���������� �������
  decCols:
  	inc	cl						;����������� �������
  	mov	bl,[si]					;������� ������� � bl
  	inc	bl						;����������� ����� ������� �� 1
  	mov	[si],bl					;������� ����� �������� (������� + 1) ������� � ������
  	inc	si						;��������� � ���������� �������
  	cmp	cl,4					;�� ��� ��������� 4 ����?
  	jnz	decCols					;���� ���, ��������� ��� ���
  	ret

;**********readKeySR**********
readKeySR proc
	push ax 					;��������� ��������
	push si
	push cx
	push bx
	push dx
	push di
	
	mov ah,1                ; ������� �������� ����������
	int 16h
	jz no_key_pressed
	
	xor ah,ah               ; ������� ������ ���� �������
	int 16h                 ; �� = ��� �������
	
	cmp ah, 1
	jz quit
  	cmp ah,4Bh 					;��� ->?
  	jz leftSR 					;���� ��, �� ������� � ����� leftSR
  	cmp ah,4Dh 					;��� <-?
  	jz rightSR                  ;���� ��, �� ������� � ����� rightSR
  	cmp ah,48h                  ;��� ^?
  	jz spaceRot                 ;���� ��, �� ������� � ����� spaceRot
    
    xor ah,ah               ; ������� ������ ���� �������
	int 16h                 ; �� = ��� �������
	
	cmp ah, 1
	jz quit
  	cmp ah,4Bh 					;��� ->?
  	jz leftSR 					;���� ��, �� ������� � ����� leftSR
  	cmp ah,4Dh 					;��� <-?
  	jz rightSR                  ;���� ��, �� ������� � ����� rightSR
  	cmp ah,48h                  ;��� ^?
  	jz spaceRot                 ;���� ��, �� ������� � ����� spaceRot
 
  	jmp termSR 					;���� �� ���� �� ������������� ������ �� ���� ������, ���������
leftSR:
	call canMoveLeft 	     	;���������, ����� �� �� �������� ������ �����
	cmp al,1                    ;����� �� �������� ������ �����
	jnz termSR                  ;���� al != 1, termSR
leftyesSR:
  	call hideCurrentPiece       ;�������� ��������� �������� ������
  	call moveLeft               ;�������� ��������� ������ �����
  	call showCurrentPiece       ;�������� ��������� ��������� ������

  	jmp termSR                  
; ���������� �  ��� ������ ������
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
	call hideCurrentPiece       ;�������� ��������� �������� ������
	call rotatePiece            ;�������� ��������� �������� ������
	call showCurrentPiece       ;�������� ��������� ��������� ������
	jmp termSR

quit:          
    mov ax,03
    int 10h
	mov ax,4C00h
	int 21h
	
termSR:
	in al,60h 					;��������� � ������������� ��������� �� ������ ������
	in al,64h   				;��������� ���������� �� 64h �����
	and al,1 					;���������� �������� ���������� � 
	; ��� �7 6 5 4 3 2 1 0
	   ; &                 -> � ���������� �������� 0000000x, ���� �:
	    ; 0 0 0 0 0 0 0 1   
	; ������� ������� ������ � �������� ������ (0 � ����� ����, 1 � ����� �������� ������)
	cmp al,1 					;���� ��� 0 ����� �������� 1, �� ����� ���������� ��������� � �������
	jz termSR 					;���� ����� �� ����, ������ � ����� termSR
	
no_key_pressed:
    pop di 						;��������������� ��������� ���������
	pop dx 
	pop bx
	pop cx
	pop si
	pop ax
  	ret 						;������� ���������� �� ����������� ���������� 
readKeySR endp

;**********clearRow**********
clearRow:
	push bx 					;��������� ��������
	push ax
	push dx
	push di
	push es

	mov bl,0                	;������, �������� � ������ ������
	mov bh,1                	;�������, �������� � ������� �������
foreachcolumn:
	call getPixel 				;������� �������
	cmp ah,'*' 					;���� ��� �� ��������
	jnz foreachrow 				;��������� � foreachrow
	inc bh 						;����������� �������
	cmp bh,11 					;�� ������ 10 ��������?
	jnz foreachcolumn 			;���� ���, ���������
	mov bh,1  					;���������� �������
	jmp crEND 					;��������� � �������
foreachrow:
	mov bh,1 					;���������� ������� �������
	inc bl 						;����������� ������
	cmp bl,24 					;�� ����� 24 ����?
	jnz foreachcolumn 			;���� ���, ���������� �������� �������
	jmp cRterm 					;���� ��, �� ��������� � cRterm 

crEND:
	dec bl 						;��������� �� ������ ����
	call getPixel 				;�������� ������� 
	dec di 						;������������ �� ��������
	mov es:[di],' ' 			;�������� ���������� ��������
	inc di 						;������������ � �����
	inc bl 						;������������ � ����, ������� �� �������
	mov dl,al 					;������� ���� � dl
	call setPixel 				;������������� �������
	dec di 						;����� � ���������
	mov es:[di],ah 				;���������� ������, ������� ��� ������
	inc di 						;��������� � �����
	inc bh 						;����������� �������
	cmp bh,11 					;�� ���������� 10 ��������?
	jnz crEND 					;���� ���, ������� �������
	mov bh,1 					;���������� �������
	dec bl 						;����������� �� ��� ����
	cmp bl,0 					;�������� �� �� �������?
	jnz crEND 					;���� ���, ��������� �����
	jmp cRterm 					;���� ��, ��������� � �����
cRterm:
	pop es 						;��������������� �������� 
	pop di
	pop dx
	pop ax
	pop bx
	ret 						;�����������

onTimer proc
whiletrue3:
	push si 					
	push ax
	push bx
	push dx
	
	mov	si,OFFSET SLOWDOWN      ;���������� ����� ���������� SLOWDOWN 
	mov	al,[si]                 ;������� �������� �� ������ si � al
	inc	al                      ;al++
	mov	[si],al                 ;���������� ������� �������� � SLOWDOWN
	cmp	al,5					;slowdown ����� 5
	jnz	timedone                ;���� �� ����� ��������� timedone
	xor al,al                   ;�������� al
	mov	[si],al                 ;���������� ������� �������� � SLOWDOWN
	push cx                     
	call clearRow               ;�������� ��������� clearRow
	call canMoveDown            ;�������� ��������� canMoveDown
	pop cx						;����� �� �� ��������� ����?
	cmp al,0 					;���� ���
	jz setNewPiece				;������������ � ������� ����� ������

	push cx
	call hideCurrentPiece	 	;�������� ������
	pop cx
	push cx
	call moveDown 				;�������� �� ���� 
	pop cx
	push cx
	call showCurrentPiece 		;���������� �� �����
	pop cx

timedone:
	pop dx  					;��������������� ��������
    pop bx
    pop ax
    pop si
    ret                        ;�������� ���������� �� ����������� ����������

setNewPiece:
	push ax 					;��������� ��������
	push es
	push di

	mov ax,code 				
	mov es,ax 
	mov di,offset rotationcount ;������� � di ������ �� rotationcount
	mov [di],0 					;���������� �������� rotationcount

	pop di 						;��������������� �������� 
	pop es
	pop ax
	
	mov ch, [figureCounter]
	inc ch
    cmp ch,7                    ;�� ������������ 8 ��������� �����?
	jnz wtcont 					;���� ���, ����������
	mov ch,0 					;���� ��, ���������� �������
	mov byte ptr [figureCounter], ch
wtcont:
	mov byte ptr [figureCounter], ch
	;si=piecenumber*8 + address_of_pieceline
	mov ax,9					;������� � ax 9, ������ ��� 1 ��� ����
	mul ch 						;�������� �� ����� ������
	mov si,offset x_line 		;��������� ������ ������� �����
	add si,ax   				;���������� ���������
	push cx
	call setPiece 				;������� ������ � currentX|Y
	pop cx
	call showCurrentPiece		;�������� ��������� �����������

	;���������, ����� �� ����
	push cx
	call canMoveDown			;����� �� �� ������������ ����?
	pop cx
	cmp al,0 					;���� ���, �� ��������� terminate
	jz terminate

	pop dx  					;��������������� ��������
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
	push es 				    ;��������� ��������
	push di
	push ds
	push si
	push cx
	push ax

	mov ax,code 					
	mov es,ax 
	mov di,offset rotationcount 	;���������� ��������� �� rotationcount
	mov dh,[di] 					;������� rotationcount �������� � dh
	cmp dh,4 						;����� ������� 4 �������?
	jnz rpcont 						;���� ���, ����������
	mov dh,0 						;����� rotationcount

rpcont:
	xor cl,cl 						;���������� �������

	mov si,offset currentX 			;������� � si ��������� �� currentpiece
	inc si 							;��������� � ��������� 

	
	mov di,offset r1x_line 			;������� � di ����� ������ ������� ����� ���������
	inc di 							;�� �� ������ ������

	mov ax,36 						;�������� ������ 4-�� �������� ����� ��������
	mul ch 				 			;�� piecenumber
	add di,ax 						;� ��������� � di

	
	mov ax,9 						;������� ������ ������ �������
	mul dh 							;�������� �� rotationcount
	add di,ax 						;��������� ��������� � di, ����� ��������� �� ���������� ������ ��������
rotation:

	mov al,[si] 		 			;������� �������� currentpiece ���������� � al			

	mov ah,[di] 					;������� �������� rotation ��������� � ah	

	add al,ah 						;���������� ��������

	mov [si],al 					;������� al � currentpiece 

	inc si 							;������������ ������ �� �������
	inc di 							;������������ ������ �� �������
	inc cl 							;����������� �������
	cmp cl,8 						;�� ������������ ��� 8 ��������� �������
	jnz rotation                    ;���� ���, �� ��������� ��������

	inc dh 							;rotationcounter++
	mov di,offset rotationcount 	;��������� �� rotationcount
	mov [di],dh 					;�������� rotationcount �� ��, ��� �������� � dh


	pop ax 							;��������������� ��������
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