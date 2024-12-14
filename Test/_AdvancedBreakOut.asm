.386 
.model flat,stdcall 
option casemap:none 

corner_collision proto :DWORD,:DWORD
include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 

.CONST
platformWidth EQU 120       ; ���x�e��
platformHeight EQU 20       ; ���x����
stepSize DWORD 10              ; �C�����ʪ������ƶq
winWidth EQU 800              ; �����e��
winHeight EQU 600             ; ��������
initialBrickRow EQU 20
brickNumX EQU 10
brickNumY EQU 28
brickTypeNum EQU 4
brickWidth EQU 80
brickHeight EQU 20
velocity EQU 10
fallTime EQU 30
ballRadius EQU 10             ; �p�y�b�|
OFFSET_BASE EQU 150

.DATA 
ClassName db "SimpleWinClass2",0 
AppName  db "BreakOut",0 
Text db "Window", 0
EndGame db "Game Over!", 0
offset_center DWORD 0
divisor DWORD 180
controlsCreated DWORD 0

platformX DWORD 350           ; ��l X �y��
platformY DWORD 550           ; ��l Y �y��
ballX DWORD 410                 ; �p�y X �y��
ballY DWORD 500                 ; �p�y Y �y��
velocityX DWORD 0               ; �p�y X ��V�t��
velocityY DWORD 10               ; �p�y Y ��V�t��
brick DWORD brickNumY DUP(brickNumX DUP(0))
fallTimeCount DWORD 30
gameOver DWORD 0

randomNum DWORD 0
randomSeed DWORD 0                 ; �H���ƺؤl


.DATA? 
hInstance1 HINSTANCE ? 
CommandLine LPSTR ? 
tempWidth DWORD ?
tempHeight DWORD ?
tempWidth1 DWORD ?
tempHeight1 DWORD ?
whiteBrush DWORD ?
hBitmap HBITMAP ?
hdcMem HDC ?
redBrush DWORD ?
yellowBrush DWORD ?
blueBrush DWORD ?
purpleBrush DWORD ?
brickX DWORD ?
brickY DWORD ?

.CODE 
WinMain2 proc
    LOCAL wc:WNDCLASSEX 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT                   ; �w�q RECT ���c
    LOCAL msg:MSG
    LOCAL tempWinWidth:DWORD
    LOCAL tempWinHeight:DWORD
    
    invoke GetModuleHandle, NULL 
    mov    hInstance1,eax 

    ; �w�q���f���O
    mov   wc.cbSize,SIZEOF WNDCLASSEX 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc2
    mov   wc.cbClsExtra,NULL 
    mov   wc.cbWndExtra,NULL 
    push  hInstance1
    pop   wc.hInstance
    mov   wc.hbrBackground,COLOR_WINDOW+1 
    mov   wc.lpszMenuName,NULL 
    mov   wc.lpszClassName,OFFSET ClassName 
    invoke LoadIcon,NULL,IDI_APPLICATION 
    mov   wc.hIcon,eax 
    mov   wc.hIconSm,eax 
    invoke LoadCursor,NULL,IDC_ARROW 
    mov   wc.hCursor,eax 
    invoke RegisterClassEx, addr wc 

    ; �]�m�ؼЫȤ�Ϥj�p
    mov wr.left, 0
    mov wr.top, 0
    mov eax, winWidth
    mov wr.right, eax
    mov eax, winHeight
    mov wr.bottom, eax

    ; �վ㵡�f�j�p
    invoke AdjustWindowRect, ADDR wr, WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, FALSE

    ; �p�ⵡ�f�e�שM����
    mov eax, wr.right
    sub eax, wr.left
    mov tempWinWidth, eax
    mov eax, wr.bottom
    sub eax, wr.top
    mov tempWinHeight, eax

    ; �Ыص��f
    invoke CreateWindowEx, NULL, ADDR ClassName, ADDR AppName, \
            WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, \
            0, 0, tempWinWidth, tempWinHeight, NULL, NULL, hInstance1, NULL
    mov   hwnd,eax 
    invoke SetTimer, hwnd, 1, 50, NULL  ; ��s���j�q 50ms �אּ 10ms

    ; ��ܩM��s���f
    invoke ShowWindow, hwnd,SW_SHOWNORMAL 
    invoke UpdateWindow, hwnd 

    ; �D�����`��
    .WHILE TRUE 
        invoke GetMessage, ADDR msg,NULL,0,0 
        .BREAK .IF (!eax) 
        invoke TranslateMessage, ADDR msg 
        invoke DispatchMessage, ADDR msg 
    .ENDW 
    mov     eax,msg.wParam 
    ret 
WinMain2 endp


WndProc2 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT

    .IF uMsg==WM_DESTROY 
        invoke KillTimer, hWnd, 1
        invoke DeleteObject, whiteBrush
        invoke DeleteObject, hBitmap
        invoke DeleteDC, hdcMem
        invoke ReleaseDC, hWnd, hdc
        invoke PostQuitMessage, NULL
        ret

    .ELSEIF uMsg == WM_CREATE
        CALL initializeBreakOut
        CALL initializeBrick
        CALL initializeBrush

        ; �Ыؤ��s�]�ƤW�U�� (hdcMem) �M���
        INVOKE  GetDC,hWnd              
        mov     hdc,eax
        invoke CreateCompatibleDC, hdc
        mov hdcMem, eax
        invoke CreateCompatibleBitmap, hdc, winWidth, winHeight
        mov hBitmap, eax
        invoke SelectObject, hdcMem, hBitmap

        ; ��R�I���C��
        invoke GetClientRect, hWnd, addr rect
        invoke FillRect, hdcMem, addr rect, whiteBrush
        invoke ReleaseDC, hWnd, hdc
    .ELSEIF uMsg == WM_TIMER
        cmp gameOver, 1
        je game_over
        mov eax, fallTimeCount
        dec eax
        mov fallTimeCount, eax
        cmp eax, 0
        jne no_brick_fall

        CALL Fall
        CALL newBrick
        mov eax, fallTime
        mov fallTimeCount, eax
    no_brick_fall:
        ; ��s�p�y��m
        call update_ball

        ; �˴����x�I��
        call check_platform_collision

        invoke GetAsyncKeyState, VK_LEFT
        test eax, 8000h ; ���ճ̰���
        jz skip_left
        mov eax, platformX
        cmp eax, stepSize
        jl skip_left
        sub eax, stepSize
        mov platformX, eax
    skip_left:

        invoke GetAsyncKeyState, VK_RIGHT
        test eax, 8000h ; ���ճ̰���
        jz skip_right
        mov eax, platformX
        add eax, stepSize
        add eax, platformWidth
        cmp eax, winWidth
        jg skip_right
        mov eax, platformX
        add eax, stepSize
        mov platformX, eax
    skip_right:
        call brick_collision

        invoke GetClientRect, hWnd, addr rect
        invoke FillRect, hdcMem, addr rect, whiteBrush  ;�R���i�o���|��
        call DrawScreen

        ; ��ø����
        invoke InvalidateRect, hWnd, NULL, FALSE
        ret

    game_over:
        invoke KillTimer, hWnd, 1
        invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, 0
        ret

    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps

    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 
WndProc2 endp 

initializeBreakOut PROC
    mov eax, 350
    mov platformX, eax
    mov eax, 550
    mov platformY, eax
    mov eax, 410
    mov ballX, eax
    mov eax, 500
    mov ballY, eax
    mov eax, 0
    mov velocityX, eax
    mov eax, 10
    mov velocityY, eax
    mov eax, 30
    mov fallTimeCount, eax
    mov eax, 0
    mov gameOver, eax
    
    mov eax, brickNumX
    mov ebx, brickNumY
    mul ebx
    mov ecx, eax
    mov esi, OFFSET brick
LoopBrick:
    mov DWORD PTR [esi], 0
    add esi, 4
    loop LoopBrick
    ret
initializeBreakOut ENDP

initializeBrush PROC
    invoke CreateSolidBrush, 00FFFFFFh
    mov whiteBrush, eax

    invoke CreateSolidBrush, 00ff901eh
    mov blueBrush, eax

    invoke CreateSolidBrush, 0032C8C8h
    mov yellowBrush, eax

    invoke CreateSolidBrush, 003c14dch
    mov redBrush, eax

    invoke CreateSolidBrush, 00CC6699h
    mov purpleBrush, eax
    ret
initializeBrush ENDP

update_ball PROC
    ; ��s�p�y��m
    mov eax, ballX
    add eax, velocityX
    mov ballX, eax

    mov eax, ballY
    add eax, velocityY
    mov ballY, eax

    ; ��ɸI���˴��]�譱�Ϯg�^
    mov eax, ballX
    cmp eax, ballRadius           ; �I�쥪���
    jle reverse_x_left

    mov eax, winWidth
    sub eax, ballRadius
    cmp ballX, eax                ; �I��k���
    jge reverse_x_right

    mov eax, ballY
    cmp eax, ballRadius           ; �I��W���
    jle reverse_y_top

    mov eax, winHeight
    sub eax, ballRadius
    cmp ballY, eax                ; �I��U���
    jge reverse_y_bottom

    jmp end_update                ; �Y�L�I���A����

reverse_x_left:
    neg velocityX
    mov eax, ballRadius
    mov ballX, eax
    jmp end_update

reverse_x_right:
    neg velocityX
    mov eax, winWidth
    sub eax, ballRadius
    mov ballX, eax
    jmp end_update

reverse_y_top:
    neg velocityY
    mov eax, ballRadius
    mov ballY, eax
    jmp end_update

reverse_y_bottom:
    mov eax, winHeight
    sub eax, ballRadius
    mov ballY, eax
    mov eax, 0
    mov velocityX, eax
    mov velocityY, eax
    mov eax, 1
    mov gameOver, eax

end_update:
    ret
update_ball ENDP

check_platform_collision PROC
    LOCAL speed:DWORD
    LOCAL angle:DWORD

    mov eax, ballY
    add eax, ballRadius
    mov ebx, platformY
    cmp eax, ebx
    jl no_collision

    mov eax, ballY
    add ebx, platformHeight
    add ebx, ballRadius
    cmp eax, ebx
    jg no_collision

    ; �ˬd�O�_�b���x�������d��
    mov eax, ballX
    add eax, ballRadius
    mov ebx, platformX
    cmp eax, ebx
    jl no_collision

    mov eax, ballX
    sub eax, ballRadius
    mov ebx, platformX
    add ebx, platformWidth
    cmp eax, ebx
    jg no_collision

    mov eax, ballX
    mov ebx, platformX
    cmp eax, ebx
    jl side_collision

    mov ebx, platformX
    add ebx, platformWidth
    cmp eax, ebx
    jg side_collision
    mov ebx, platformY
    sub ebx, ballRadius
    mov ballY, ebx

above_collision:

    ; �I���B�z
    mov eax, OFFSET_BASE
    add eax, platformX
    sub eax, ballX
    mov offset_center, eax
    mov eax, velocity
    mov speed, eax

    ; �p�⩷��
    fstp st(0)
    fild offset_center           ; ���J���׭�            
    fldpi                        ; ���J �k
    fild divisor                 ; ���J 180
    fdiv                         ; �p�� �k / 180
    fmul                         ; �p�⩷��

    ; �p��t�פ��q
    fld st(0)                    ; ���׭�
    fcos                         ; �p�� cos(����)
    fild speed                   ; ���J�t�פj�p V
    fmul                         ; �p�� velocityX = cos(����) * V
    fistp DWORD PTR [velocityX]               ; �s�J velocityX

    fld st(0)                    ; ���׭�
    fsin                         ; �p�� sin(����)
    fild speed                   ; ���J�t�פj�p V
    fmul                         ; �p�� velocityY = sin(����) * V
    fistp DWORD PTR [velocityY]               ; �s�J velocityY
    
    ; ���� Y �t�ס]�ϼu�^
    neg velocityY
    jmp no_collision

side_collision:
    mov eax, ballY
    mov ebx, platformY
    cmp eax, ebx
    jl check_leftup_corner

    mov eax, ballY
    mov ebx, platformY
    add ebx, platformHeight
    cmp eax, ebx
    jg check_leftbottom_corner

    mov eax, platformX
    add eax, platformWidth
    cmp eax, ballX
    jl check_right_side_collision

check_left_side_collision:
    mov eax, platformX
    sub eax, ballX
    cmp eax, ballRadius
    jle left_side_collision
    jmp no_collision

left_side_collision:
    mov eax, platformX
    sub eax, ballRadius
    mov ballX, eax
    mov eax, velocityX
    cmp eax, 0
    jl no_collision
    neg velocityX
    jmp no_collision
    
check_right_side_collision:
    mov eax, ballX
    sub eax, platformX
    sub eax, platformWidth
    cmp eax, ballRadius
    jle right_side_collision
    jmp no_collision

right_side_collision:

    mov eax, platformX
    add eax, platformWidth
    add eax, ballRadius
    mov ballX, eax
    mov eax, velocityX
    cmp eax, 0
    jg no_collision
    neg velocityX
    jmp no_collision

check_leftup_corner:
    mov angle, 150
    mov eax, platformX
    mov ebx, platformY
    INVOKE corner_collision, eax, ebx
    cmp eax, 1
    jne check_rightup_corner
    jmp do_corner_collision

check_rightup_corner:
    mov angle, 30
    mov eax, platformX
    add eax, platformWidth
    mov ebx, platformY
    INVOKE corner_collision, eax, ebx
    cmp eax, 1
    jne no_collision
    jmp do_corner_collision

check_leftbottom_corner:
    mov angle, 210
    mov eax, platformX
    mov ebx, platformY
    add ebx, platformHeight
    INVOKE corner_collision, eax, ebx
    cmp eax, 1
    jne check_rightbottom_corner
    jmp do_corner_collision

check_rightbottom_corner:
    mov angle, 330
    mov eax, platformX
    add eax, platformWidth
    mov ebx, platformY
    add ebx, platformHeight
    INVOKE corner_collision, eax, ebx
    cmp eax, 1
    jne no_collision

do_corner_collision:
    ; �N�����ഫ�����סGangle * �k / 180
    fild angle              ; ���J����
    fldpi                   ; ���J �k
    fmul                    ; angle * �k
    fild divisor            ; ���J 180
    fdiv                    ; ���������ഫ

    ; �p�� velocityX = speed * cos(angle)
    fld st(0)               ; �N���׸��J���|
    fcos
    fild speed
    fmul
    fistp velocityX

    ; �p�� velocityY = speed * sin(angle)
    fld st(0)               ; �A�����J����
    fsin
    fild speed
    fmul
    fistp velocityY


no_collision:
    ret
check_platform_collision ENDP


brick_collision PROC
    Local brickIndexX : DWORD
    Local brickIndexY : DWORD
    Local brickRemainderX : DWORD
    Local brickRemainderY : DWORD
    Local tempX : DWORD
    Local tempY : DWORD

    xor edx, edx
    mov eax, ballX
    mov ebx, brickWidth
    div ebx
    mov brickIndexX, eax
    mov brickRemainderX, edx

    xor edx, edx
    mov eax, ballY 
    mov ebx, brickHeight
    div ebx
    mov brickIndexY, eax
    mov brickRemainderY, edx

    ;�o��|��M��bug
    mov eax, brickNumY
    cmp eax, brickIndexY
    jle no_brick_collision

up_brick_collision:           ; brick + brickIndexX * 4 + (brickIndexY - 1) * brickNumX * 4
    cmp brickIndexY, 0
    jle bottom_brick_collision
    mov eax, brickRemainderY
    cmp eax, ballRadius
    jg bottom_brick_collision
    
    mov eax, brickIndexX
    shl eax, 2

    mov ebx, brickIndexY
    dec ebx
    cmp ebx, brickNumY
    jge left_brick_collision
    imul ebx, brickNumX
    shl ebx, 2

    mov esi, OFFSET brick
    add esi, eax              ; esi += ��������
    add esi, ebx              ; esi += ��������

    cmp DWORD PTR [esi], 0
    jne brick_collisionY


bottom_brick_collision:       ; brick + brickIndexX * 4 + (brickIndexY + 1) * brickNumX * 4
    mov ebx, brickNumY
    dec ebx
    cmp brickIndexY, ebx  
    jge left_brick_collision
    mov eax, brickHeight
    sub eax, brickRemainderY
    cmp eax, ballRadius
    jg left_brick_collision
    
    mov eax, brickIndexX
    shl eax, 2

    mov ebx, brickIndexY
    inc ebx
    imul ebx, brickNumX
    shl ebx, 2

    mov esi, OFFSET brick
    add esi, eax              ; esi += ��������
    add esi, ebx              ; esi += ��������

    cmp DWORD PTR [esi], 0
    jne brick_collisionY
    jmp left_brick_collision

brick_collisionY:
    ; �I���B�z
    mov DWORD PTR [esi], 0         ; �����j��
    neg velocityY                  ; ���� Y ��V�t��


left_brick_collision:         ; brick + (brickIndexX - 1) * 4 + brickIndexY * brickNumX * 4
    cmp brickIndexX, 0
    jle right_brick_collision
    mov eax, brickRemainderX
    cmp eax, ballRadius
    jg right_brick_collision
    
    mov eax, brickIndexX
    dec eax
    shl eax, 2

    mov ebx, brickIndexY

    imul ebx, brickNumX
    shl ebx, 2

    mov esi, OFFSET brick
    add esi, eax              ; esi += ��������
    add esi, ebx              ; esi += ��������

    cmp DWORD PTR [esi], 0
    jne brick_collisionX


right_brick_collision:        ; brick + (brickIndexX + 1) * 4 + brickIndexY * brickNumX * 4
    mov ebx, brickNumX
    dec ebx
    cmp brickIndexX, ebx  
    jge corner_brick
    mov eax, brickWidth
    sub eax, brickRemainderX
    cmp eax, ballRadius
    jg corner_brick
    
    mov eax, brickIndexX
    inc eax
    shl eax, 2

    mov ebx, brickIndexY

    imul ebx, brickNumX
    shl ebx, 2

    mov esi, OFFSET brick
    add esi, eax              ; esi += ��������
    add esi, ebx              ; esi += ��������

    cmp DWORD PTR [esi], 0
    jne brick_collisionX
    jmp corner_brick

brick_collisionX:
    ; �I���B�z
    mov DWORD PTR [esi], 0         ; �����j��
    neg velocityX                  ; ���� X ��V�t��
    jmp corner_brick

corner_brick:

leftup:
    mov esi, OFFSET brick
    mov eax, brickIndexX
    dec eax
    cmp eax, 0
    jl rightup
    mov tempX, eax
    shl eax, 2
    add esi, eax
    mov eax, brickIndexY
    dec eax
    cmp eax, 0
    jl leftbottom
    mov tempY, eax
    mov ebx, brickNumX
    mul ebx
    shl eax, 2
    add esi, eax
    cmp DWORD PTR [esi], 0
    je leftbottom

    mov eax, brickIndexX
    mov ebx, brickWidth
    mul ebx
    mov tempX, eax

    mov eax, brickIndexY
    mov ebx, brickHeight
    mul ebx
    mov tempY, eax

    Invoke corner_collision, tempX, tempY
    cmp eax, 0
    je leftbottom
    mov DWORD PTR [esi], 0
    cmp velocityX, 0
    jge skipLeftupX
    neg velocityX
skipLeftupX:
    cmp velocityY, 0
    jge leftbottom
    neg velocityY


leftbottom:
    mov esi, OFFSET brick
    mov eax, brickIndexX
    dec eax
    mov tempX, eax
    shl eax, 2
    add esi, eax
    mov eax, brickIndexY
    inc eax
    cmp eax, brickNumY
    jge rightup
    mov tempY, eax
    mov ebx, brickNumX
    mul ebx
    shl eax, 2
    add esi, eax
    cmp DWORD PTR [esi], 0
    je rightup

    mov eax, brickIndexX
    mov ebx, brickWidth
    mul ebx
    mov tempX, eax

    mov eax, brickIndexY
    inc eax
    mov ebx, brickHeight
    mul ebx
    mov tempY, eax

    Invoke corner_collision, tempX, tempY
    cmp eax, 0
    je rightup
    mov DWORD PTR [esi], 0
    cmp velocityX, 0
    jge skipLeftbottomX
    neg velocityX
skipLeftbottomX:
    cmp velocityY, 0
    jle rightup
    neg velocityY

rightup:
    mov esi, OFFSET brick
    mov eax, brickIndexX
    inc eax
    cmp eax, brickNumX
    jge no_brick_collision
    mov tempX, eax
    shl eax, 2
    add esi, eax
    mov eax, brickIndexY
    dec eax
    cmp eax, 0
    jl rightbottom
    mov tempY, eax
    mov ebx, brickNumX
    mul ebx
    shl eax, 2
    add esi, eax
    cmp DWORD PTR [esi], 0
    je rightbottom

    mov eax, brickIndexX
    inc eax
    mov ebx, brickWidth
    mul ebx
    mov tempX, eax

    mov eax, brickIndexY
    mov ebx, brickHeight
    mul ebx
    mov tempY, eax

    Invoke corner_collision, tempX, tempY
    cmp eax, 0
    je rightbottom
    mov DWORD PTR [esi], 0
    cmp velocityX, 0
    jle skipRightupX
    neg velocityX
skipRightupX:
    cmp velocityY, 0
    jge rightbottom
    neg velocityY

rightbottom:
    mov esi, OFFSET brick
    mov eax, brickIndexX
    inc eax
    mov tempX, eax
    shl eax, 2
    add esi, eax
    mov eax, brickIndexY
    inc eax
    cmp eax, brickNumY
    jge no_brick_collision
    mov tempY, eax
    mov ebx, brickNumX
    mul ebx
    shl eax, 2
    add esi, eax
    cmp DWORD PTR [esi], 0
    je no_brick_collision

    mov eax, brickIndexX
    inc eax
    mov ebx, brickWidth
    mul ebx
    mov tempX, eax

    mov eax, brickIndexY
    inc eax
    mov ebx, brickHeight
    mul ebx
    mov tempY, eax

    Invoke corner_collision, tempX, tempY
    cmp eax, 0
    je no_brick_collision
    mov DWORD PTR [esi], 0
    mov eax, velocityX
    cmp eax, 0
    jle skipRightbottomX
    neg velocityX
skipRightbottomX:
    mov eax, velocityY
    cmp eax, 0
    jle no_brick_collision
    neg velocityY

no_brick_collision:
    ret
brick_collision ENDP


corner_collision PROC,
    corner_X : DWORD,
    corner_Y : DWORD
    LOCAL square_X : DWORD
    LOCAL square_Y : DWORD

    mov eax, ballX
    sub eax, corner_X
    imul eax, eax
    mov square_X, eax

    mov eax, ballY
    sub eax, corner_Y
    imul eax, eax
    mov square_Y, eax
    
    mov eax, ballRadius
    imul eax, eax
    mov edx, square_X
    add edx, square_Y
    cmp edx, eax
    jg no_corner_collision
    mov eax, 1
    jmp end_corner_collision

no_corner_collision:
    mov eax, 0
end_corner_collision:
    ret
corner_collision ENDP


initializeBrick proc
    mov esi, OFFSET brick

    mov eax, brickNumX
    mov ecx, initialBrickRow
    mul ecx
    mov ecx, eax
    mov ebx, brickTypeNum

    invoke GetTickCount
    mov eax, edx
    cdq
initializenewRandomBrick:
    div ebx
    mov [esi], edx
    add esi, 4
    loop initializenewRandomBrick

initializeBrick ENDP

newBrick proc
    call GetRandomSeed              ; ���o�H���ؤl
    mov eax, randomSeed
    mov esi, OFFSET brick           ; ��l�ƿj���}�C����
    mov ecx, brickNumX              ; �j���ƶq
    mov ebx, brickTypeNum           ; �j��������

newRandomBrick:
    ; �u�ʦP�l�ͦ���: (a * seed + c) % m
    imul eax, eax, 1664525          ; ���H�Y�� a�]1664525 �O�`�έȡ^
    add eax, 1013904223             ; �[�W�W�q c
    and eax, 7FFFFFFFh             ; �O�ҵ��G������
    mov randomSeed, eax             ; ��s�H���ؤl
    xor edx, edx                    ; �M�� edx
    div ebx                         ; ��o�H������
    mov [esi], edx                  ; �N�����s�J�}�C
    add esi, 4                      ; ���ʨ�U�@�Ӧ�m
    loop newRandomBrick             ; ����
    ret

newBrick ENDP

GetRandomSeed proc
    invoke QueryPerformanceCounter, OFFSET randomSeed
    ret
GetRandomSeed ENDP


Fall proc
    mov esi, OFFSET brick + ((brickNumY-1) * brickNumX-1) * 4 
    mov edi, OFFSET brick + (brickNumY * brickNumX-1) * 4
    std                                           
    mov ecx, (brickNumY-1)*brickNumX                               
    rep movsd                                    
    cld       
    call checkBrick
    ret
Fall endp
    
checkBrick PROC
    mov esi, OFFSET brick + ((brickNumY-1) * brickNumX) * 4
    mov ecx, brickNumX
Loopcheck:
    cmp DWORD PTR [esi], 0
    jne hasBrick
    add esi, 4
    loop Loopcheck
    jmp noBrick

hasBrick:
    mov eax, 1
    mov gameOver, eax
noBrick:
    ret
checkBrick ENDP

DrawScreen PROC

    invoke SelectObject, hdcMem, purpleBrush

    ; ø�s�p�y
    mov eax, ballX
    sub eax, ballRadius
    mov ecx, ballY
    sub ecx, ballRadius
    mov edx, ballX
    add edx, ballRadius
    mov esi, ballY
    add esi, ballRadius
    invoke Ellipse, hdcMem, eax, ecx, edx, esi

    ; ø�s���x
    mov eax, platformX
    add eax, platformWidth
    mov edx, platformY
    add edx, platformHeight
    mov [tempWidth], eax
    mov [tempHeight], edx
    invoke Rectangle, hdcMem, platformX, platformY, tempWidth, tempHeight

    ; ø�s�j��
    mov esi, OFFSET brick
    mov eax, 0
    mov ecx, brickNumY
DrawBrickRow:
    push ecx
    mov ecx, brickNumX
DrawBrickCol:
    xor edx, edx
    push eax
    mov ebx, brickNumX
    div ebx

    push edx
    mov ebx, brickHeight
    mul ebx
    mov brickY, eax
    pop edx
        
    mov eax, edx
    mov ebx, brickWidth
    mul ebx
    mov brickX, eax

    pop eax

    cmp DWORD PTR [esi+eax*4], 1
    je YBrick
    cmp DWORD PTR [esi+eax*4], 2
    je RBrick
    cmp DWORD PTR [esi+eax*4], 3
    je BBrick
    jmp Continue
YBrick:
    push eax
    push ecx
    invoke SelectObject, hdcMem, yellowBrush
    pop ecx
    pop eax
    jmp startDrawBrick
RBrick:
    push eax
    push ecx
    invoke SelectObject, hdcMem, redBrush
    pop ecx
    pop eax
    jmp startDrawBrick
BBrick:
    push eax
    push ecx
    invoke SelectObject, hdcMem, blueBrush
    pop ecx
    pop eax
    
startDrawBrick:
    push eax
    push edx
    mov eax, brickX
    add eax, brickWidth
    mov edx, brickY
    add edx, brickHeight
    mov [tempWidth], eax
    mov [tempHeight], edx
    pop edx
    pop eax
    push eax
    push ecx
    invoke Rectangle, hdcMem, brickX, brickY, tempWidth, tempHeight
    pop ecx
    pop eax

Continue:  
    inc eax
    dec ecx
    cmp ecx, 0
    jne DrawBrickCol
    pop ecx
    dec ecx
    cmp ecx, 0
    jne DrawBrickRow
    ret
DrawScreen ENDP

end