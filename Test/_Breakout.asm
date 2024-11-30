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
	planLength EQU 3
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
	colorCount DWORD 0
	endGame BYTE 0
.code 

BreakOut PROC 

	CALL DrawTitle
	CALL ClrScr

	setGame:
	CALL setPlan
	call newBrick
	call drawBrick
	CALL drawPlan
	
	goGame:
	mov al, countTime
	inc al
	cmp al, brickFallTime
	jne noBrickfall

	brickFall:
	call fall
	call newBrick
	call drawBrick
	CALL drawPlan
	mov al, 0

	noBrickFall:
	mov countTime, al

	CALL movePlan
	
	CALL clearBall
	CALL movBall
	CALL drawBall
	CALL drawWall
	CALL setBallDir
	call checkBrick
	CALL checkBall
	cmp endGame, 1
	je endBrickGame


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
		cmp dl, 0
		je skipZero
		mov BYTE PTR [esi], dl
		inc edi
	skipZero:
		inc dl
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
		mov al, planChar
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
		mov dl, ah
		inc dl
		cmp dl, planY
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
		mov edi, planlength
		sub edi, ecx
		mov bl, planDirection[edi]
		neg bh
		jmp endSetting
	
	touchbrick:
		movzx eax, ballY          
		sub eax, 2                   
		mov ecx, maxX             
		mul ecx                   

		movzx edx, ballX          
		dec edx                  
		add eax, edx                       
		mov esi, OFFSET brick
		shl eax, 2
		add esi, eax

		cmp DWORD PTR [esi], 0
		je endSetting
		call clearBrick
		neg bh

	endSetting:
		mov ballDirX, bl
		mov ballDirY, bh
		ret

setBallDir ENDP

clearBrick proc uses eax 
	mov eax, [esi+4]
	cmp eax, [esi]     
    je clearRight
clearLeft:
	mov DWORD PTR[esi-4], 0
	jmp ExitclearBrick
clearRight:
	mov DWORD PTR[esi+4], 0
ExitclearBrick:
	mov DWORD PTR[esi], 0
	ret
clearBrick endp

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

	cmp DWORD PTR [esi+eax*4], 0
	ja DrawBrick1

DrawBrick0:
	mov dl, brickX
	mov dh, brickY
	call Gotoxy
	push eax
	mov  eax, white	
	call SetTextColor
	mov al, brickChar[0]
	call Writechar
	jmp Continue

DrawBrick1:
	mov dl, brickX
	mov dh, brickY
	call Gotoxy
	push eax
	call drawColor
	mov al, brickChar[1]
	call Writechar

Continue:
	pop eax
	inc eax
	loop Col
	pop ecx
	loop Row
	
ExitPrint:	
	mov  eax, white	
	call SetTextColor
	ret
drawBrick ENDP

drawColor proc
	cmp DWORD PTR [esi+eax*4], 2
	je drawYellow
drawRed:
	mov  eax, red	
	call SetTextColor
	jmp ExitdrawColor
drawYellow:
	mov  eax, yellow	
	call SetTextColor
	jmp ExitdrawColor
ExitdrawColor:
	ret
drawColor endp

newBrick proc
	call Randomize
	mov esi, OFFSET brick
	mov ecx, brickmaxX
L:
	cmp ecx, 1
	je Random0
	mov eax, brickTypeNum
	call RandomRange
	cmp eax, 1
	je Random1
Random0:
	mov DWORD PTR [esi], 0
	add esi, 4
	loop L
	jmp ExitnewBrick
	
Random1:
	call setColor
	mov [esi], eax
	mov [esi+4], eax 
	add esi, 8
	dec ecx
	loop L
ExitnewBrick:
	ret
newBrick ENDP

setColor PROC USES ebx
    mov ebx, colorCount       
    cmp ebx, 0
    je SetRed                 
    cmp ebx, 1
    je SetYellow              

SetRed:
    mov eax, 1                
    mov ebx, 1                
    jmp ExitsetColor

SetYellow:
    mov eax, 2                
    mov ebx, 0                
    jmp ExitsetColor

ExitsetColor:
    mov colorCount, ebx       
    ret
setColor ENDP

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