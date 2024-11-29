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
.code 

BreakOut PROC 

	CALL DrawTitle
	CALL ClrScr

	setGame:
	CALL setPlan
	
	goGame:
	CALL movePlan
	CALL drawPlan
	CALL drawBall
	CALL drawWall
	CALL movBall
	CALL setBallDir
	INVOKE Sleep, 80
	mov al, ballY
	cmp al, maxY
	jne goGame


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
    MoveRightLoop:
        inc BYTE PTR [edi]
        inc edi
        loop MoveRightLoop


	endMovement:
		ret
movePlan ENDP


drawPlan PROC
	CALL ClrScr
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
		jne endSetting
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

	endSetting:
		mov ballDirX, bl
		mov ballDirY, bh
		ret

setBallDir ENDP


drawWall PROC

	LeftWall:
		mov bl, 0
		mov bh, maxY
	drawLeftWall:
		mGoTo 0, bl
		mov al, wallChar
		CALL WriteChar
		inc bl
		cmp bl, bh
		jne drawLeftWall

	RightWall:
		mov bl, 0
		mov bh, maxY
		add bh, 2
	drawRightWall:
		mGoTo maxX, bl
		mov al, wallChar
		CALL WriteChar
		inc bl
		cmp bl, bh
		jne drawRightWall

	ret
drawWall ENDP

END