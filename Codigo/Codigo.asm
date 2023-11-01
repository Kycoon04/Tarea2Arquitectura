.model small
.stack 100h
.data
prompt db "Ingrese el nombre del archivo: $"
menuOpciones1 db "1. Cargar texto por defecto", 10, 13, "$"
menuOpciones2 db "2. Ingresar nombre de archivo", 10, 13, "$"
menuOpciones3 db "3. Salir", 10, 13, "$"
pressEnter db "Presione ENTER para continuar...$"

CantidadLetras db "Cantidad de letras:", 10, 13, "$"
CantidadPalabras db "Cantidad de palabras:", 10, 13, "$"

defaultFile db "texto.txt","$"
fileName db ?
fileHandle dw "$"
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
   ;mov ax,00  ; Configuración inicial del mouse
   ;int 33h    ; Inicializa el mouse
   add dx,10
   mov ax,4  
   ;int 33h    ; Ejecuta la interrupción del mouse
   mov ax,01h ; Establece para mostrar el cursor del mouse
   ;int 33h    ; Ejecuta la operación del mouse

menu:
	mov ah,00h 
    mov al,12h 
    int 10h 
	
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
waitForSelection:
    mov ah, 01h
    int 16h
    jz waitForSelection

    mov ah, 00h
    int 16h

	cmp al, '1'
	jne notOP1
	lea dx, defaultFile 
	call readFile
	call closeFile
	call count
	call printResults
	notOP1:
	
 

    cmp al, '2'
	jne notOP2
	call askFileName
	lea dx, fileName
	call readFile
	call closeFile
	call count
	call printResults
	notOP2:
	
	cmp al, '3'
    je salir
	
	jne menu ;Si escribe algo diferente aqui lo manda otra vez al menu
	
;------------------------------------------------------Opciones del menu----------------------------------------------------
salir:
mov ah, 04ch
int 21h


askFileName proc
	;mostrar en pantalla
	mov ah,00h 
	mov al,12h 
	int 10h 
	posicion 1, 1 
	mov ah, 09h
	lea dx, prompt
	int 21h
	mov si, offset fileName
	waitForInput:
		mov ah, 01h
		int 16h
		jz waitForInput
		mov ah, 00h
		int 16h
		
		cmp al, 0Dh ; ENTER key
		je inputRetrieved
		
		cmp al, 08h
		je backspace
		
        mov [si], al ;añade caracter
		mov al,'$'
		mov [si+1],al
        inc si 
		jmp askFileNameScreen
		
		backspace:
			cmp si, offset fileName
			je waitForInput

			dec si
			mov [si],'$'
		
		askFileNameScreen:
		
		;mostrar en pantalla
		mov ah,00h 
		mov al,12h 
		int 10h 
		posicion 1, 1 
		mov ah, 09h
		lea dx, prompt
		int 21h
		lea dx, fileName
		int 21h
		

        jmp waitForInput

	inputRetrieved:
    ret
askFileName endp
		

;requiere que el nombre del archivo esté cargado en dx
readFile proc
    ; Abrir el archivo
    mov ah, 3Dh ; función para abrir el archivo
    mov al, 0   ; modo de lectura
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
    jne notEOF
	ret
	notEOF:

    ; Si no es '@', incrementar el contador y continuar leyendo
    inc si
	inc contador
    jmp readLoop
	fileError:
		posicion 25, 20 
		mov ah, 09h
		lea dx, menuOpciones1
		int 21h	
		ret
closeFile proc
    mov ah, 3Eh
    mov bx, fileHandle
    int 21h
	lea si, buffer 
	mov cx, contador
	mov letras, 0
    ret	
	

count proc
	xor bx,bx ;BX = 0: hubo espacio antes, BX=1: no hubo espacio
	countLoop:
		lodsb ; Cargar el siguiente carácter del buffer en AL
		
		test bx,bx
		jz check_word ;si hubo espacio, verificar si hay palabra

		cmp al, ' '
		je space_detected
		cmp al,0Dh ;salto de línea
		je space_detected
		
		jmp check_letter
		
		space_detected:
		mov bx,0
		jmp countLoop
		
	check_word:
		cmp al, ' ' 
		je check_letter 
		cmp al,0Dh
		je check_letter
		
		inc palabras  
		mov bx,1  
		
		
		
	check_letter:
		;TODO: dividir en mayusculas y mínusculas
		;TODO: añadir números a la cuenta
		cmp al, 'A'
		jb notLetter
		cmp al, 'z'
		ja notLetter ; lo mismo pero para las minusculas 

	isLetter:
		mov bx,1
		inc letras
		loop countLoop	;  si el carácter es una letra incrementa
	notLetter: 
		loop countLoop
	ret
count endp

printResults proc		
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

	posicion 15, 0
	mov ah, 09h
	lea dx, pressEnter
	int 21h

	call waitForEnter
	jmp menu
ret
printResults endp

waitForEnter proc
    waitingForEnter:
        mov ah, 01h  
        int 16h
        cmp al, 0Dh  ; ENTER key
        je endWait  
        
        mov ah, 00h  ;
        int 16h

        jmp waitingForEnter  

    endWait:
    ret
waitForEnter endp

	
	;Sacado de internet como pasar de numero a letras
numToStr proc
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