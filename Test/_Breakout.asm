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
	maxX EQU 79
	maxY EQU 24
	planX BYTE 38, 39, 40, 41, 42
	planY BYTE 22
	ballX BYTE 40
	ballY BYTE 5
	ballDirX BYTE 0
	ballDirY BYTE 1
	planLength DWORD 5
	planDirection BYTE -2, -1, 0, 1, 2
	planChar BYTE '='
	ballChar BYTE '@'
	wallChar BYTE '|'
.code 

BreakOut PROC 

	CALL DrawTitle
	CALL ClrScr
	
	goGame:
	CALL movePlan
	CALL drawPlan
	CALL drawBall
	CALL drawWall
	CALL movBall
	INVOKE Sleep, 80
	jmp goGame

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


movePlan PROC
	
	mov ax, 0
	mov esi, OFFSET planX

	CheckLeftKey:
		INVOKE  GetKeyState, VK_LEFT
		test ax, 8000h
		jz CheckRightKey

	CheckLeftBoundary:
		mov dl, 0
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
		mov edx, MaxX
		sub edx, planLength
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