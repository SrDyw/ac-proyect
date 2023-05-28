format binary as 'img'
org 7c00h

mov ax, cs
mov ds, ax


;Código para leer desde HDD:
	mov	ah,0x02      ;usar el BIOS para cargar
	mov	al,0x04      ;cantidad de sectores
	mov	ch,0x00
	mov	cl,0x02      ;a partir del segundo sector lógico
	mov	dh,0x00
	mov	dl,0x80      ;del primer disco duro
	mov	bx,0x800     ;y escribir el contenido en 0x800:0
	mov	es,bx
	mov	bx,0x0000
    @@: int	0x13
	jc	@b

	jmp	8000h	     ;poner en ejecución el código cargado en HDD


times 510-($-$$) db 0
		 dw 0aa55h

org 8000h

;=====================================================================================================
;--------------------------------PROJECT CODE START-----------------------------------------------------
;=====================================================================================================




SCREEN_BUFFER equ 0b800h
COLOR_TEXT_INFO equ 0xc
COLOR_TEXT_USER equ 0xf
TYPE_SIZE equ 20
MAX_LENGTH equ 255


xor ax, ax
mov es, ax
mov ax,timer_2
mov [es:4*8], ax
mov [es:4*8+2], cs

sti


mov ax, 3
int 10h



push SCREEN_BUFFER
pop es

xor di, di
mov si, str_info_10
mov ah, COLOR_TEXT_INFO
call READ_STRING

call JUMP_LINE
mov si, str_team
mov [es:di], byte '*'
mov [es:di+1], byte COLOR_TEXT_INFO
add di, 4
call READ_STRING ; Member 1
call JUMP_LINE

sub di, 4
mov [es:di], byte '*'
mov [es:di+1], byte COLOR_TEXT_INFO
add di, 4
add si, 17
call READ_STRING ; Member 2
call JUMP_LINE

sub di, 4
mov [es:di], byte '*'
mov [es:di+1], byte COLOR_TEXT_INFO
add di, 4
add si, 15
call READ_STRING ; Member 3
call JUMP_LINE

mov ax, 0
int 16h
call CLS
; jmp END_PR

; OPERATION CHOOSER
xor di, di
OPERATION_CHOOSER:
  mov ah, COLOR_TEXT_INFO
  mov si, str_info_0
  call READ_STRING
  call JUMP_LINE
  mov cx, 1
  call CATCH_USER_INPUT

  cmp al, 'c'
  jz ENCODE_CHOOSED

  cmp al, 'd'
  jz DECODE_CHOOSED

  ; ELSE USER DONT KNNOW HOW TO WRITE XD
  mov si, str_info_7
  mov ah, 1h
  call READ_STRING
  call JUMP_LINE
  mov ax, 0
  int 16h
  call CLS
  jmp OPERATION_CHOOSER

ENCODE_CHOOSED:
  mov [int_oper], 0
  jmp @f

DECODE_CHOOSED:
  mov [int_oper], 1
@@:
call CLS


; SHOW INFO TO TYPE THE STRING WHRER di -> position, si -> string, ah -> color, cx -> character quantity
xor di, di

cmp [int_oper], 1
jz FLAG_DEC


FLAG_ENC:
  mov si, str_info_1
  jmp @f
FLAG_DEC:
  mov si, str_info_8
  jmp @f

@@:
mov ah, COLOR_TEXT_INFO
call READ_STRING

; LITERALLY, A JUMP LINE
call JUMP_LINE

; SAVE THE USER INPUT IN str_encode
mov cx, TYPE_SIZE
call CATCH_USER_INPUT
call INPUT_TO_ENCODE


; CLEAN SCREEN
call CLS

; OFFSET INPUT
OFFSET_CHOOSER:
  mov si, str_info_2
  call READ_STRING

  call CLEAN_USER_INPUT
  call JUMP_LINE

  mov cx, 1
  call CATCH_USER_INPUT

  call CONVERT_TO_NUMBER

; DIRECTION INPUT
DIRECTION_CHOOSER:
  call CLS
  mov si, str_info_3
  call READ_STRING

  call JUMP_LINE
  call CLEAN_USER_INPUT
  mov cx, 1
  call CATCH_USER_INPUT

  cmp al, 'p'
  jz POSITVE_CHOOSED

  cmp al, 'n'
  jz NEGATIVE_CHOOSED

  ; ELSE USER DONT KNNOW HOW TO WRITE XD
  mov si, str_info_7
  mov ah, 1h
  call READ_STRING
  call JUMP_LINE
  mov ax, 0
  int 16h
  call CLS
  jmp DIRECTION_CHOOSER

POSITVE_CHOOSED:
  mov [int_dir], 0
  jmp @f

NEGATIVE_CHOOSED:
  mov [int_dir], 1
@@:

call CLS


mov si, str_encode
mov bx, 0

cmp [int_oper], 1
jz DECODE

ENCODE:
  cmp bx, TYPE_SIZE
  jz @f

  mov al,[str_encode+bx]

  cmp al, '$'
  jz @f

  cmp [int_dir], 1
  jz .SUB

  .ADD:
    add al, [int_offset]
    jmp .END_SECTION
  .SUB:
    sub al, [int_offset]

  .END_SECTION:
    mov [str_encode+bx], al
    inc bx
    jmp ENCODE


DECODE:
  cmp bx, TYPE_SIZE
  jz @f

  mov al,[str_encode+bx]

  cmp al, '$'
  jz @f

  cmp [int_dir], 1
  jz .ADD

  .SUB:
    sub al, [int_offset]
    jmp .END_SECTION
  .ADD:
    add al, [int_offset]


  .END_SECTION:
    mov [str_encode+bx], al
    inc bx
    jmp DECODE

@@:
; SHOW FINAL RESULT
call CLS

mov si, str_info_6
call READ_STRING
call JUMP_LINE
mov si, str_encode
mov dl, 0
call READ_STRING_SLOW



jmp $

; VARS
str_info_0 db 'Cifrar(c) Descifrar(d): ', '$'
str_info_1 db 'Escriba la cadena que desea cifrar: ', '$'
str_info_2 db 'Intruduzca el numero de desface: ', '$'
str_info_3 db 'Direccion positiva(p) o negativa (n): ', '$'
str_info_4 db 'Cadena, Desface, Direccion: ', '$'
str_info_5 db 'Es correcto (s/n): ', '$'
str_info_6 db 'Resultado: ', '$'
str_info_7 db 'Indroduzca los datos solicitados... Presione cualquier tecla ', '$'
str_info_8 db 'Escriba la cadena que desea decifrar: ', '$'
str_info_9 db 'Cadena Decifrada: ', '$'
str_info_10 db 'Proyecto 1, Cifrado Cesar', '$'
str_user_input db '$$$$$$$$$$$$$$$$$$$$'
str_encode db '$$$$$$$$$$$$$$$$$$$$'
str_team db 'Dayniel Martinez$', 'Carlos Alvarez$', 'George Walker$'
int_offset db 0
int_dir db 0
int_oper db 0

; FUNCTIONS


CONVERT_TO_NUMBER:
  mov al, [str_user_input]
  mov ah, 0
  sub ax, 48
  mov[int_offset], al
  ret

CLEAN_USER_INPUT:
  push cx
  push bx

  mov cx, TYPE_SIZE
  mov bx, 0

  .CLEAN_LOOP:
    mov [str_user_input+bx], byte '$'
    inc bx
    loop .CLEAN_LOOP

  pop bx
  pop cx
  ret


JUMP_LINE:
  add di, 320
  ret

; ah -> color | si -> string to show | di -> position
READ_STRING:
  push di
  push si
  .READ_LOOP:

    mov al, [si]
    cmp al, '$'
    jz @f

    mov [es:di], ax
    add di, 2
    inc si
    dec cx
    jmp .READ_LOOP

  @@:
  pop si
  pop di
  ret

READ_STRING_SLOW:
  push di
  push si
  .READ_LOOP:
    .WAIT:
      cmp dl, 11
      jne .WAIT


    mov al, [si]
    cmp al, '$'
    jz @f

    mov [es:di], ax
    add di, 2
    inc si
    dec cx
    mov dl, 0
    jmp .READ_LOOP

  @@:
  pop si
  pop di
  ret

CATCH_USER_INPUT:
  mov bx, 0
  push di

  ; READ USER INPUT AND SHOW IN SCREEN
  USER_TYPE:
    cmp cx, 0
    jz @f

    mov ax, 0
    int 16h
    cmp ah, 1ch
    jz @f

    mov ah, COLOR_TEXT_USER

    mov[es:di], al
    mov[es:di+1], ah
    add di, 2
    mov[str_user_input+bx], al
    inc bx
    loop USER_TYPE

  @@:
    pop di
    ret

INPUT_TO_ENCODE:
  push bx
  push cx

  mov bx, 0
  mov di, 0
  mov cx, TYPE_SIZE

  .SAVE_LOOP:
    mov al, [str_user_input+bx]
    cmp al, '$'
    jz @f
    mov [str_encode+bx], al
    inc bx
    loop .SAVE_LOOP
  @@:
    pop cx
    pop bx
    ret
CLS:
  mov ax, 3
  xor di, di
  int 10h
  mov ah, COLOR_TEXT_INFO
  mov al, 0
  ret
timer_2:
  cli
  inc dl
  mov al, 20h
  out 20h, al
  sti
  iret


times 2*510-($-$$) db 0
dw 0xaa55



;=====================================================================================================
;--------------------------------PROJECT CODE END-----------------------------------------------------
;=====================================================================================================


































include 'interrupts.ASM'     ;el fichero interrupts contiene el re-mapeo de la TVI

;Estos son  ejemplos que trabajan con las interrupciones timer, RTC y teclado:

	mov	ax,0003h     ;establecer el modo de video (texto)
	int	10h
	mov	di,0
	mov	cx,0
	call	pintar
	mov	[segundos], 0
    @@: cmp	[segundos],18*5
	je	salir
	jmp	@b
salir:
	mov	byte[atributo],0
	call	pintar

jmp $

pintar:
	mov	ax,0b800h
	mov	es,ax
	mov	di,160*12+2*25
	mov	cx, 21
ciclo:
	mov    bl,[cadena+si]
	mov    [es:di],bl
	mov    bh,[atributo]
	mov    [es:di+1],bh
	inc    si
	add    di,2
	loop   ciclo
	ret

cadena db 'Ejercicio con la IRQ0'
atributo db 01110001b
aux dw 160*13
segundos db 0

;ISR para timer:
timer:
	cli
	inc    [segundos]
	mov    al,20h
	out    20h,al
	sti
iret

;ISR para teclado:

teclado:
	xor    dx,dx
	in     al,60h	     ;leer con AL el SCAN de la tecla presionada
	test   al,10000000b  ; compruebo si está presionada o no, 1 liberado, 0 presionado
	jnz    liberada      ;si estÃ¡ liberada no voy a hacer nada
	cmp    al,1ch	     ;1ch es el código SCAN de Enter
	je     bajar
	mov    bp,keymap     ;utilizar bp para apuntar al mapa del teclado
	xor    ah,ah	     ;limpiar la parte alta para poder sumar bp + al
	add    bp,ax	     ;sumar bp + al
	mov    al,[bp]	     ;muevo el ascii correspondiente para AL
	call   print
	jmp    liberada
bajar:
	mov    ax,cx
	mov    si,160
	mul    si
	mov    si,ax
	inc    cx

liberada:
	mov    al,20h
	out    20h,al
iret

keymap: 
db 0		   
db 27,'1234567890-=',8
db 9,'qwertyuiop[]',10
db 0,'asdfghjkl;',39,96,0,'\'
db 'zxcvbnm,./',0,'*',0,' '
db 0,'2345678901',0,'3789-456+1230.'

print:
	mov    si,[aux]
	mov    bx,0xb800
	add    si,dx
	mov    es,bx
	mov    dl,01110010b
	mov    [es:si],al
	mov    [es:si+1],dl
	add    si,2
	mov    [aux],si
ret

clockPos dw 160-8*2
datePos dw 160*2-16*2
days db 'DomLunMarMieJueVieSab'
months db 'EneFebMarAbrMayJunJulAgoSepOctNovDic'

;ISR para RTC:

     show_time: mov	al,0ch			; leer el registro C del RTC para que siga generando interrupciones
		out	70h,al
		in	al,71h

		mov	di,[clockPos]		; posición designada para el "reloj"
		
		mov	ch,71h
		mov	cl,':'

		mov	al,4			; solicitar valor de las horas
		out	70h,al
		in	al,71h
		call	show_bcd

		mov	[es:di],cx
		add	di,2

		mov	al,2			; solicitar valor de los minutos
		out	70h,al
		in	al,71h
		call	show_bcd

		mov	[es:di],cx
		add	di,2

		mov	al,0			; solicitar valor de los segundos
		out	70h,al
		in	al,71h
		call	show_bcd

		mov	di,[datePos]

		mov	al,6			; solicitar valor del día de la semana
		out	70h,al
		in	al,71h
		call	show_week_day

		mov	cl,','
		mov	[es:di],cx
		add	di,2

		mov	cl,' '
		mov	[es:di],cx
		add	di,2

		mov	al,8			; solicitar valor del mes
		out	70h,al
		in	al,71h
		call	show_month

		mov	cl,' '
		mov	[es:di],cx
		add	di,2

		mov	al,7			; solicitar valor del día del mes
		out	70h,al
		in	al,71h
		call	show_bcd

		mov	[es:di],cx
		add	di,2

		mov	al,50			; solicitar valor de la centuria
		out	70h,al
		in	al,71h
		call	show_bcd

		mov	al,9			; solicitar valor del año
		out	70h,al
		in	al,71h
		call	show_bcd

		mov	al,20h			; enviar el fin de interrupción
		out	0a0h,al 		; al PIC esclavo
		out	20h,al			; y al maestro
		iret

      show_bcd: mov	bl,al
		xor	eax,eax
		or	al,bl
		shr	al,4
		and	bl,0fh
		mov	ah,ch
		mov	bh,ch
		shl	ebx,16
		or	eax,ebx
		add	eax,00300030h
		mov	[es:di],eax
		add	di,4
		ret

 show_week_day: dec	al
		xor	ah,ah			; Hacer una multiplicación por tres
		mov	si,ax			; Pero de manera incremental
		shl	si,1			; solo sumando
		add	si,ax
		mov	bx,days 		; Utilizar bx como apuntador al texto
		add	bx,si			; Apuntar al nombre de día correcto
		mov	cl,[bx]
		mov	[es:di],cx
		mov	cl,[bx+1]
		mov	[es:di+2],cx
		mov	cl,[bx+2]
		mov	[es:di+4],cx
		add	di,6
		ret

    show_month: dec	al
		test	al,10h			; Si el dígito más significativo es 0
		jz	@f			; Se procede como para el día de la semana
		and	al,0fh			; En caso contrario, solo debe sumarse diez
		add	al,10			; ;-)
	    @@: xor	ah,ah			; Hacer una multiplicación por tres
		mov	si,ax			; Pero de manera incremental
		shl	si,1			; solo sumando
		add	si,ax
		mov	bx,months		; Utilizar bx como apuntador al texto
		add	bx,si			; Apuntar al nombre de día correcto
		mov	cl,[bx]
		mov	[es:di],cx
		mov	cl,[bx+1]
		mov	[es:di+2],cx
		mov	cl,[bx+2]
		mov	[es:di+4],cx
		add	di,6
		ret


times (4*512)-($-$$) db 0 ; 4*512 porque defini arriba 4 sectores
