.model small
.stack 100h
.data
prompt db "Ingrese el nombre del archivo: $"
menuOpciones1 db "1.           Cargar Texto", 10, 13, "$"
menuOpciones2 db "2.               Salir", 10, 13, "$"
CantidadLetras db "Cantidad de letras:", 10, 13, "$"
CantidadPalabras db "Cantidad de palabras:", 10, 13, "$"
menuOpciones3 db "3.    Ingresar nombre de archivo", 10, 13, "$"
fileName db "texto.txt","$"
fileHandle dw ?
buffer db 2048 dup(?)
contador dw 1
letras dw 0
palabras dw 0
strBuffer db 10 dup(0)
dobleEspacio db 0 
posicion macro x, y
    mov ah, 02H
    mov bh, 00h
    mov dh, x
    mov dl, y
    int 10H
endm

.code
mov ax,@DATA
mov ds, ax

   mov ah,00h ; Establece el modo de video
   mov al,12h ; Selecciona el modo de video
   int 10h    ; Ejecuta la interrupción de video
   mov ax,00  ; Configuración inicial del mouse
   int 33h    ; Inicializa el mouse
   add dx,10
   mov ax,4  
   int 33h    ; Ejecuta la interrupción del mouse
   mov ax,01h ; Establece para mostrar el cursor del mouse
   int 33h    ; Ejecuta la operación del mouse

    posicion 11, 20 ;Coloca el siguiente texto en el centro de la pantalla, fue a puro "ojo"
    mov ah, 09h
    lea dx, menuOpciones1
    int 21h
	posicion 12, 20
    mov ah, 09h
    lea dx, menuOpciones2
    int 21h
	posicion 13, 20 
    mov ah, 09h
    lea dx, menuOpciones3
    int 21h
menu:
    mov ah, 01h
    int 16h
    jz menu

    mov ah, 00h
    int 16h

	cmp al, '1'
	je readFile
	
    cmp al, '2'
    je salir

    cmp al, '3'
    ;je getFileName
	
	jne menu ;Si escribe algo diferente aqui lo manda otra vez al menu
	
;------------------------------------------------------Opciones del menu----------------------------------------------------
salir:
mov ah, 04ch
int 21h

readFile:
    ; Abrir el archivo
    mov ah, 3Dh ; función para abrir el archivo
    mov al, 0   ; modo de lectura
    lea dx, fileName
    int 21h
    jc fileError ; en caso de que de error va salta a error 

    mov fileHandle, ax ; aquí guardamos el manejador del archivo

    ; Iniciamos un contador para el buffer
    mov si, offset buffer

	readLoop:
    ; Lee cada uno de los carácteres del archivo
    mov ah, 3Fh 
    mov bx, fileHandle
    lea dx, [si] ; la dirección donde se almacena el carácter 
    mov cx, 1 ; lee un carácter a la vez uno a uno 
    int 21h
    jc fileError ; saltar a error en caso de error

    ; Verificamos si el carácter leído es '@'
    mov al, [si]
    cmp al, '@'
    je foundAt ; saltar a foundAt si encontramos '@'

    ; Si no es '@', incrementar el contador y continuar leyendo
    inc si
	inc contador
    jmp readLoop
	
foundAt:
    ; Cerrar el archivo
    mov ah, 3Eh
    mov bx, fileHandle
    int 21h
	lea si, buffer 
	mov cx, contador
	mov letras, 0
    jmp countLoop	
	
fileError:
    posicion 25, 20 
    mov ah, 09h
    lea dx, menuOpciones1
    int 21h

countLoop:
    lodsb ; Cargar el siguiente carácter del buffer en AL
	
	cmp al, ' '
	je isWord
	cmp al, '.'
	je isWord
    cmp al, 'A'
    jb notLetter
    cmp al, 'z'
    ja notLetter ; lo mismo pero para las minusculas 

isLetter:
    mov dobleEspacio, 0
    inc letras
    loop countLoop	;  si el carácter es una letra incrementa
isWord:
    inc dobleEspacio
    cmp dobleEspacio,2
    je resetDobleEspacio
    inc palabras
	jmp notLetter
	
	resetDobleEspacio:
    mov dobleEspacio, 0 
notLetter: 
    loop countLoop
    
	mov ax, letras
	call numToStr ; Convierte el número de letras a una cadena ya que no sabia que no era posible imprimir un numero
    
	
    mov ah,00h ; Establece el modo de video
    mov al,12h ; Selecciona el modo de video
    int 10h 
	
	posicion 11, 0
    mov ah, 09h
    lea dx, CantidadLetras
    int 21h
    lea dx, [di] 
    mov ah, 09h
    int 21h 
	
	mov ax, palabras
	call numToStr 
	
	posicion 13, 0
    mov ah, 09h
    lea dx, CantidadPalabras
	int 21h
	lea dx, [di] 
    mov ah, 09h
    int 21h
	
	
	;Sacado de internet como pasar de numero a letras
numToStr:
    ; Asume que el número a convertir ya está en AX
    lea di, strBuffer + 10 ; Apunta DI al final del buffer
    mov byte ptr [di], '$' ; Terminador de cadena para DOS
    mov bx, 10 ; Base decimal

reverseLoop:
    dec di ; Mueve el puntero hacia atrás
    xor dx, dx ; Limpia DX
    div bx ; Divide AX por 10, resultado en AL, residuo en DX
    add dl, '0' ; Convierte el residuo a ASCII
    mov [di], dl ; Almacena el carácter en el buffer

    test ax, ax ; Verifica si AX es 0
    jnz reverseLoop ; Si no es 0, continúa el bucle
    ret
end