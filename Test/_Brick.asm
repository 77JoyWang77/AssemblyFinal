INCLUDE Irvine32.inc
INCLUDELIB	user32.lib

.data
maxX EQU 79
maxY EQU 24
brickTypeNum EQU 2
brickminX EQU 1
brickminY EQU 1
brickmaxX EQU 79
brickmaxY EQU 22
brickX byte ?
brickY byte ?
brick DWORD 22 DUP(79 DUP(0))
brickChar byte ' ','-'

.code
GameBrick PROC
	call ClrScr
draw:
	call newBrick
	call drawBrick
	call fall
	INVOKE Sleep, 80
	call checkBrick
	cmp al,1
	jne draw
	;;;
invoke ExitProcess,0 
GameBrick ENDP

drawBrick proc
	;call ClrScr
	mov esi, OFFSET brick
	mov eax, 0
	mov ecx, brickmaxY
Row:
	push ecx
	mov ecx, brickmaxX
Col:
	xor edx, edx
	push eax
	mov ebx, brickmaxX
	div ebx
	add dl, 1
	add al, 1
	mov brickX, dl
	mov brickY, al
	pop eax

	cmp DWORD PTR [esi+eax*4], 1
	je DrawBrick1
	jmp DrawBrick0

DrawBrick0:
	mov dl, brickX
	mov dh, brickY
	call Gotoxy
	push eax
	mov  eax, red	
	call SetTextColor
	mov al, brickChar[0]
	call Writechar
	pop eax
	jmp Continue

DrawBrick1:
	mov dl, brickX
	mov dh, brickY
	call Gotoxy
	push eax
	mov  eax, red	
	call SetTextColor
	mov al, brickChar[1]
	call Writechar
	pop eax

Continue:
	inc eax
	loop Col
	pop ecx
	loop Row
	
ExitPrint:	
	mov  eax, white	
	call SetTextColor
	ret
drawBrick ENDP

newBrick proc
	call Randomize
	mov esi, OFFSET brick
	mov ecx, brickmaxX
L:
	mov eax, brickTypeNum
	call RandomRange
	mov [esi], eax
	add esi, 4
	loop L
	ret
newBrick ENDP

Fall proc
    mov esi, OFFSET brick + (brickmaxY-2) * brickmaxX * 4 
    mov edi, OFFSET brick + (brickmaxY-1) * brickmaxX * 4
    std                                           
    mov ecx, (brickmaxY-1)*brickmaxX                               
    rep movsd                                    
    cld       
    ret
Fall endp

checkBrick proc
	xor al,al
	mov esi, OFFSET brick+ (brickmaxY-1) * brickmaxX * 4
	mov ecx, brickmaxX
Check:
	cmp DWORD PTR [esi],1
	je HaveBrick
	add esi,4
	Loop Check
	jmp Exitcheck

HaveBrick:
	mov al, 1
	jmp Exitcheck
	
Exitcheck:
	ret
checkBrick endp
END