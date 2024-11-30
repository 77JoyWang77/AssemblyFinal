INCLUDE Irvine32.inc
INCLUDELIB	user32.lib

mGoTo MACRO indexX:REQ, indexY:REQ
    PUSH edx
    MOV dl, indexX
    MOV dh, indexY
    call Gotoxy
    POP edx
ENDM

mWrite MACRO drawText:REQ
	LOCAL string
	.data
		string BYTE drawText, 0
	.code
		PUSH edx
		MOV edx, OFFSET string
		call WriteString
		POP edx
ENDM

.data 
	minX EQU 1
	minY EQU 1
	maxX EQU 79
	maxY EQU 24
	planLength EQU 5
	planDirection BYTE planLength DUP(?)
	planX BYTE planLength DUP(?)
	planY EQU 22
	ballX BYTE ?
	ballY BYTE 5
	ballDirX BYTE 0
	ballDirY BYTE 1
	planChar BYTE '='
	ballChar BYTE '@'
	wallChar BYTE '|'
	clearChar BYTE ' '
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
	brickFallTime BYTE 10
	countTime BYTE 0
	endGame BYTE 0
.code 

BreakOut PROC 

	CALL DrawTitle
	CALL ClrScr

	setGame:
	CALL setPlan
	call newBrick
	call drawBrick
	
	goGame:
	CALL movePlan
	CALL drawPlan
	CALL clearBall
	CALL movBall
	CALL drawBall
	CALL drawWall
	CALL setBallDir
	call checkBrick
	CALL checkBall
	cmp endGame, 1
	je endBrickGame

	mov al, countTime
	inc al
	cmp al, brickFallTime
	jne noBrickfall

	brickFall:
	call fall
	call newBrick
	call drawBrick
	mov al, 0

	noBrickFall:
	mov countTime, al

	INVOKE Sleep, 100
	mov al, ballY
	cmp al, maxY

	cmp endGame, 1
	je endBrickGame
	jmp goGame

	endBrickGame:
	CALL WaitMsg

	INVOKE	ExitProcess, 0
	ret

BreakOut ENDP 


DrawTitle PROC
	CALL ClrScr

	mGoTo 2,4
	mWrite "Go To Game    "

	CALL WaitMsg
	ret

DrawTitle ENDP

setPlan PROC
	mov al, minX
	mov ah, maxX
	mov esi, OFFSET planX
	mov edi, OFFSET planDirection

	setPlanMiddle:
		add al, ah
		shr al, 1
		jnc setBallX
		inc al
	setBallX:
		mov ballX, al
	setPlanDir:
		mov bl, planLength
		shr bl, 1
		jnc evenPlan

	oddPlan:
		mov dl, bl
		neg dl
	oddPlanLoop:
		mov [edi], dl
		inc dl
		inc edi
		cmp dl, bl
		jle oddPlanLoop
		jmp planSetting

	evenPlan:
		mov dl, bl
		neg dl
	evenPlanLoop:
		mov [edi], dl
		inc edi
	evenPlanInc:
		inc dl
		cmp dl, 0
		je evenPlanInc
		cmp dl, bl
		jle evenPlanLoop
		
	planSetting:
		sub al, bl
		mov ecx, planLength
	planSettingLoop:
		mov [esi], al
		inc esi
		inc al
		loop planSettingLoop

setPlan ENDP


movePlan PROC
	
	mov ax, 0
	mov esi, OFFSET planX

	CheckLeftKey:
		INVOKE  GetKeyState, VK_LEFT
		test ax, 8000h
		jz CheckRightKey

	CheckLeftBoundary:
		mov dl, minX
		cmp BYTE PTR [esi], dl
		jle CheckRightKey

	MoveLeft:
        mov ecx, planLength
        mov edi, esi

		mov bl, [esi]
		dec bl
		mGoto bl, planY
		mov al, planChar
		CALL WriteChar

		mov bl, [esi + planLength -1]
		mGoto bl, planY
		mov al, clearChar
		CALL WriteChar

    MoveLeftLoop:
        dec BYTE PTR [edi]
        inc edi
        loop MoveLeftLoop
		
		
	CheckRightKey:
		INVOKE GetKeyState, VK_RIGHT
        test ax, 8000h
		jz endMovement

	CheckRightBoundary:
		mov dl, MaxX
		sub dl, planLength
		inc dl
		cmp BYTE PTR [esi], dl
		jge endMovement

	MoveRight:
        mov ecx, planLength
        mov edi, esi

		mov bl, [esi]
		mGoto bl, planY
		mov al, clearChar
		CALL WriteChar

		mov bl, [esi + planLength -1]
		inc bl
		mGoto bl, planY
		mov al, clearChar
		CALL WriteChar
    MoveRightLoop:
        inc BYTE PTR [edi]
        inc edi
        loop MoveRightLoop


	endMovement:
		ret
movePlan ENDP


drawPlan PROC

	mov esi, OFFSET planX
	mov ecx, planLength

	Draw:
		mGoTo [esi], planY
		mov al, planChar
		call WriteChar
		
		inc esi
		loop Draw
	
	ret
drawPlan ENDP

drawBall PROC
	mGoTo ballX, ballY
	mov al, ballChar
	call WriteChar

	ret
drawBall ENDP

clearBall PROC
	mGoTo ballX, ballY
	mov al, clearChar
	call WriteChar

	ret
clearBall ENDP


movBall PROC
	mov al, ballX
	mov ah, ballY

	add al, ballDirX
	add ah, ballDirY

	mov ballX, al
	mov ballY, ah

	ret

movBall ENDP

setBallDir PROC
	mov al, ballX
	mov ah, ballY
	mov bl, ballDirX
	mov bh, ballDirY
	
	leftBoundary:
		cmp al, minX
		jg rightBoundary
		neg bl

	rightBoundary:
		cmp al, maxX
		jl upBoundary
		neg bl

	upBoundary:
		cmp ah, minY
		jg bottomBoundary
		neg bh

	bottomBoundary:
		cmp ah, maxY
		jl PlanBoundary
		mov bl, 0
		mov bh, 0
		jmp endSetting

	PlanBoundary:
		cmp ah, planY
		jne touchbrick
		mov esi, OFFSET planX
		mov ecx, planLength
		
	testTouchPlan:
		cmp [esi], al
		je ballBounce
		inc esi
		loop testTouchPlan
		jmp endSetting

	ballBounce:
		mov edi, 5
		sub edi, ecx
		mov bl, planDirection[edi]
		neg bh
		jmp endSetting
	
	touchbrick:
		movzx eax, ballY          
		dec eax                   
		mov ecx, maxX             
		mul ecx                   

		movzx edx, ballX          
		dec edx                   
		add eax, edx                       
		mov esi, OFFSET brick         

		cmp DWORD PTR [esi+eax*4], 1
		jne endSetting
		mov DWORD PTR [esi+eax*4], 0
		neg bl
		neg bh

	endSetting:
		mov ballDirX, bl
		mov ballDirY, bh
		ret

setBallDir ENDP

checkBall PROC
	mov al, ballY
	cmp al, maxY
	jne endCheckBall
	mov endGame, 1

	endCheckBall:
	ret
checkBall ENDP


drawWall PROC

	LeftWall:
		mov bl, minY
		dec bl
		mov bh, maxY
	drawLeftWall:
		mov al, minX
		dec al
		mGoTo al, bl
		mov al, wallChar
		CALL WriteChar
		inc bl
		cmp bl, bh
		jne drawLeftWall

	RightWall:
		mov bl, minY
		dec bl
		mov bh, maxY
	drawRightWall:
		mov al, maxX
		inc al
		mGoTo al, bl
		mov al, wallChar
		CALL WriteChar
		inc bl
		cmp bl, bh
		jne drawRightWall

	ret
drawWall ENDP

drawBrick proc
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
    mov esi, OFFSET brick + ((brickmaxY-1) * brickmaxX-1) * 4 
    mov edi, OFFSET brick + (brickmaxY * brickmaxX-1) * 4
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
	mov endGame, al
	ret
checkBrick endp

END