.386 
.model flat,stdcall 
option casemap:none 

goSpecialBrick1 proto :DWORD
corner_collision1 proto :DWORD,:DWORD

include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 
include winmm.inc

.CONST
platformWidth EQU 120       ; ���x�e��
platformHeight EQU 15       ; ���x����
stepSize DWORD 10              ; �C�����ʪ������ƶq
winWidth EQU 600              ; �����e��
winHeight EQU 600             ; ��������
initialBrickRow EQU 5
brickNumX EQU 10
brickNumY EQU 27
brickTypeNum EQU 6
brickWidth EQU 60
brickHeight EQU 20
fallTime EQU 3
specialTime EQU 1
ballRadius EQU 10             ; �p�y�b�|
OFFSET_BASE EQU 150
speed DWORD 10
divisor DWORD 180
line1Rect RECT <50, 555, 150, 615>
line2Rect RECT <350, 560, 600, 600>

.DATA 
ClassName db "SimpleWinClass7",0 
AppName  db "BreakOut",0 
Text db "Window", 0
EndGame db "Game Over!", 0
ScoreText db "Score:         ", 0

offset_center DWORD 0

hBackBitmapName db "simplebreakout_background.bmp",0

fallBrickOpenCmd db "open fallBrick.wav type mpegvideo alias fallBrickMusic", 0
fallBrickVolumeCmd db "setaudio fallBrickMusic volume to 300", 0
fallBrickPlayCmd db "play fallBrickMusic from 0", 0

brickOpenCmd db "open brick.wav type mpegvideo alias brickMusic", 0
brickVolumeCmd db "setaudio brickMusic volume to 300", 0
brickPlayCmd db "play brickMusic from 0", 0

specialBrickOpenCmd db "open specialBrick.wav type mpegvideo alias specialBrickMusic", 0
specialBrickVolumeCmd db "setaudio specialBrickMusic volume to 300", 0
specialBrickPlayCmd db "play specialBrickMusic from 0", 0

platformOpenCmd db "open platform.wav type mpegvideo alias platformMusic", 0
platformVolumeCmd db "setaudio platformMusic volume to 300", 0
platformPlayCmd db "play platformMusic from 0", 0

breakOutLoseOpenCmd db "open breakOutLose.wav type mpegvideo alias breakOutLoseMusic", 0
breakOutLoseVolumeCmd db "setaudio breakOutLoseMusic volume to 300", 0
breakOutLosePlayCmd db "play breakOutLoseMusic from 0", 0

platformX DWORD 240           ; ��l X �y��
platformY DWORD 530           ; ��l Y �y��
ballX DWORD 300                 ; �p�y X �y��
ballY DWORD 400                 ; �p�y Y �y��
velocityX DWORD 0               ; �p�y X ��V�t��
velocityY DWORD 10               ; �p�y Y ��V�t��
brick DWORD brickNumY DUP(brickNumX DUP(0))
fallTimeCount DWORD 5
specialTimeCount DWORD 5
gameOver DWORD 1
score DWORD 0
winPosX DWORD 400
winPosY DWORD 0
countScoreAddText DWORD 0
randomNum DWORD 0
randomSeed DWORD 0                 ; �H���ƺؤl
addScoreTextPos DWORD 0


.DATA? 
hInstance HINSTANCE ? 
hBitmap HBITMAP ?
hBackBitmap HBITMAP ?
hBackBitmap2 HBITMAP ?
hdcMem HDC ?
hdcBack HDC ?

tempWidth DWORD ?
tempHeight DWORD ?
whiteBrush DWORD ?
redBrush DWORD ?
yellowBrush DWORD ?
greenBrush DWORD ?
blueBrush DWORD ?
purpleBrush DWORD ?
blackBrush DWORD ?
brickX DWORD ?
brickY DWORD ?

.CODE 
WinMain7 proc
    LOCAL wc:WNDCLASSEX 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT                   ; �w�q RECT ���c
    LOCAL msg:MSG
    
    invoke GetModuleHandle, NULL 
    mov    hInstance,eax 

    ; �w�q���f���O
    mov   wc.cbSize,SIZEOF WNDCLASSEX 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc7
    mov   wc.cbClsExtra,NULL 
    mov   wc.cbWndExtra,NULL 
    push  hInstance
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
    mov tempWidth, eax
    mov eax, wr.bottom
    sub eax, wr.top
    mov tempHeight, eax

    ; �Ыص��f
    invoke CreateWindowEx, NULL, ADDR ClassName, ADDR AppName, \
            WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, \
            winPosX, winPosY, tempWidth, tempHeight, NULL, NULL, hInstance, NULL
    mov   hwnd,eax 
    invoke SetTimer, hwnd, 1, 20, NULL  ; ��s���j�q 50ms �אּ 10ms

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
WinMain7 endp


WndProc7 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 

    .IF uMsg==WM_DESTROY 
        mov gameOver, 1
        invoke KillTimer, hWnd, 1
        invoke DeleteObject, hBitmap
        invoke DeleteDC, hdcMem
        invoke ReleaseDC, hWnd, hdc
        invoke PostQuitMessage, NULL
        ret

    .ELSEIF uMsg == WM_CREATE
        CALL initializeBreakOut1
        CALL initializeBrick1
        CALL initializeBrush1

        lea edi, brick
        add edi, 168
        mov DWORD PTR [edi], 2
        add edi, 4
        mov DWORD PTR [edi], 3
        add edi, 4
        mov DWORD PTR [edi], 4
        add edi, 4
        mov DWORD PTR [edi], 5

        ; �Ыؤ��s�]�ƤW�U�� (hdcMem) �M���
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap, eax
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap2, eax
        invoke GetDC,hWnd              
        mov hdc, eax
        invoke CreateCompatibleDC,hdc
        mov hdcMem, eax
        invoke CreateCompatibleDC,hdc 
        mov hdcBack, eax
        invoke SelectObject, hdcMem, hBackBitmap
        invoke SelectObject, hdcBack, hBackBitmap2
        invoke ReleaseDC, hWnd, hdc
    .ELSEIF uMsg == WM_TIMER
        cmp gameOver, 1
        je game_over
     
        cmp fallTimeCount, 0
        jne no_brick_fall

        invoke mciSendString, addr fallBrickOpenCmd, NULL, 0, NULL
        invoke mciSendString, addr fallBrickVolumeCmd, NULL, 0, NULL
        invoke mciSendString, addr fallBrickPlayCmd, NULL, 0, NULL
        
        CALL Fall1
        CALL newBrick1
        mov eax, fallTime
        mov fallTimeCount, eax

        mov eax, specialTimeCount
        dec eax
        mov specialTimeCount, eax
        cmp eax, 0
        jne no_brick_fall

        CALL specialBrick1
        mov eax, specialTime
        mov specialTimeCount, eax

    no_brick_fall:
        ; ��s�p�y��m
        call update_ball1

        ; �˴����x�I��
        call check_platform_collision1

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
        call brick_collision1

        ; ��ø����
        invoke InvalidateRect, hWnd, NULL, FALSE
        ret

    game_over:
        invoke mciSendString, addr breakOutLoseOpenCmd, NULL, 0, NULL
        invoke mciSendString, addr breakOutLoseVolumeCmd, NULL, 0, NULL
        invoke mciSendString, addr breakOutLosePlayCmd, NULL, 0, NULL
        invoke KillTimer, hWnd, 1
        invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, 0
        ret

    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke BitBlt, hdcMem, 0, 0, winWidth, winHeight, hdcBack, 0, 0, SRCCOPY
        call DrawScreen1
        call updateScore1
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps

    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 
WndProc7 endp 

initializeBreakOut1 PROC
    mov platformX, 240
    mov ballX, 300
    mov ballY, 500
    mov velocityX, 0
    mov velocityY, 10
    mov fallTimeCount, 1
    mov specialTimeCount, 5
    mov gameOver, 0
    mov score, 0
    
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
initializeBreakOut1 ENDP

initializeBrush1 PROC
   
    invoke CreateSolidBrush, 00FFFFFFh
    mov whiteBrush, eax

    invoke CreateSolidBrush, 003c14dch
    mov redBrush, eax

    invoke CreateSolidBrush, 0032C8C8h
    mov yellowBrush, eax

    invoke CreateSolidBrush, 00009100h
    mov greenBrush, eax

    invoke CreateSolidBrush, 00ff901eh
    mov blueBrush, eax

    invoke CreateSolidBrush, 00CC6699h
    mov purpleBrush, eax

    invoke CreateSolidBrush, 00000000h
    mov blackBrush, eax

    
    ret
initializeBrush1 ENDP

update_ball1 PROC
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
    mov velocityX, 0
    mov velocityY, 0
    mov gameOver, 1

end_update:
    ret
update_ball1 ENDP

check_platform_collision1 PROC
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
    jmp has_collision

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
    jmp has_collision
    
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
    jmp has_collision

check_leftup_corner:
    mov angle, 150
    mov eax, platformX
    mov ebx, platformY
    INVOKE corner_collision1, eax, ebx
    cmp eax, 1
    jne check_rightup_corner
    jmp do_corner_collision

check_rightup_corner:
    mov angle, 30
    mov eax, platformX
    add eax, platformWidth
    mov ebx, platformY
    INVOKE corner_collision1, eax, ebx
    cmp eax, 1
    jne no_collision
    jmp do_corner_collision

check_leftbottom_corner:
    mov angle, 210
    mov eax, platformX
    mov ebx, platformY
    add ebx, platformHeight
    INVOKE corner_collision1, eax, ebx
    cmp eax, 1
    jne check_rightbottom_corner
    jmp do_corner_collision

check_rightbottom_corner:
    mov angle, 330
    mov eax, platformX
    add eax, platformWidth
    mov ebx, platformY
    add ebx, platformHeight
    INVOKE corner_collision1, eax, ebx
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

has_collision:
    invoke mciSendString, addr platformOpenCmd, NULL, 0, NULL
    invoke mciSendString, addr platformVolumeCmd, NULL, 0, NULL
    invoke mciSendString, addr platformPlayCmd, NULL, 0, NULL
    dec fallTimeCount
no_collision:
    ret
check_platform_collision1 ENDP


brick_collision1 PROC
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
    neg velocityY                  ; ���� Y ��V�t��
    invoke goSpecialBrick1, [esi]

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
    neg velocityX                  ; ���� X ��V�t��
    invoke goSpecialBrick1, [esi]
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

    Invoke corner_collision1, tempX, tempY
    cmp eax, 0
    je leftbottom
    invoke goSpecialBrick1, [esi]
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

    Invoke corner_collision1, tempX, tempY
    cmp eax, 0
    je rightup
    invoke goSpecialBrick1, [esi]
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

    Invoke corner_collision1, tempX, tempY
    cmp eax, 0
    je rightbottom
    invoke goSpecialBrick1, [esi]
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

    Invoke corner_collision1, tempX, tempY
    cmp eax, 0
    je no_brick_collision
    invoke goSpecialBrick1, [esi]
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
brick_collision1 ENDP


corner_collision1 PROC,
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
corner_collision1 ENDP

updateScore1 proc
    invoke SetBkMode, hdcMem, TRANSPARENT

    ; ��l�ƫ��лP�ܼ�
    lea edi, ScoreText + 14        ; �w���Ʀr�_�l��}
    mov ecx, 4                     ; �w���̤j�Ʀr���
    mov eax, score                 ; ���J score ����
    mov ebx, 10                    ; �]�m���ơA�T�{�D�s

    ; �T�O�����D�s
    cmp ebx, 0
    je div_error                   ; �p�G���Ƭ� 0�A������~�B�z

    ; �q�k�쥪�B�z�Ʀr
convert_loop:
    xor edx, edx
    div ebx                        ; EDX:EAX / EBX�A�l�Ʀs�J EDX
    add dl, '0'                    ; �N�l���ର ASCII
    dec edi                        ; ����e�@�Ӧ�m
    mov [edi], dl                  ; �s�J�r��
    dec ecx                        ; �B�z�U�@���
    test eax, eax                  ; �p�G EAX �� 0�A����
    jnz convert_loop

    ; ��R�e�m�Ů�
    mov al, ' '                    ; ASCII �Ů�
fill_spaces:
    dec edi                        ; ����e�@�Ӧ�m
    mov [edi], al                  ; ��R�Ů�
    dec ecx                        ; ��ֳѾl�Ŷ�
    jnz fill_spaces                ; �����

    ; ø�s��r
    invoke DrawText, hdcMem, addr ScoreText, -1, addr line1Rect, DT_CENTER
    ret

div_error:
    ; �B�z���H�s���~�]�i�H�O����x�νոա^
    ret

updateScore1 ENDP


initializeBrick1 proc
    mov esi, OFFSET brick

    mov eax, brickNumX
    mov ecx, initialBrickRow
    mul ecx
    mov ecx, eax
    mov ebx, 2

    invoke GetTickCount
    mov eax, edx
    cdq
initializenewRandomBrick:
    div ebx
    cmp edx, 0
    mov [esi], edx
    add esi, 4
    loop initializenewRandomBrick

initializeBrick1 ENDP

newBrick1 proc
    call GetRandomSeed1              ; ���o�H���ؤl
    mov eax, randomSeed
    mov esi, OFFSET brick           ; ��l�ƿj���}�C����
    mov ecx, brickNumX              ; �j���ƶq
    mov ebx, 2           ; �j��������

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
newBrick1 ENDP

specialBrick1 proc
    call GetRandomSeed1              ; ���o�H���ؤl
    mov eax, randomSeed
    mov esi, OFFSET brick           ; ��l�ƿj���}�C����

    mov ebx, brickNumX           ; �j��������
    imul eax, eax, 1664525          ; ���H�Y�� a�]1664525 �O�`�έȡ^
    add eax, 1013904223             ; �[�W�W�q c
    and eax, 7FFFFFFFh             ; �O�ҵ��G������
    mov randomSeed, eax             ; ��s�H���ؤl
    xor edx, edx                    ; �M�� edx
    div ebx                         ; ��o�H������
    shl edx, 2
    add esi, edx
    
    mov ebx, brickTypeNum           ; �j��������
    imul eax, eax, 1664525          ; ���H�Y�� a�]1664525 �O�`�έȡ^
    add eax, 1013904223             ; �[�W�W�q c
    and eax, 7FFFFFFFh             ; �O�ҵ��G������
    mov randomSeed, eax             ; ��s�H���ؤl
    xor edx, edx                    ; �M�� edx
    div ebx                         ; ��o�H������
    mov [esi], edx

    ret
specialBrick1 ENDP

GetRandomSeed1 proc
    invoke QueryPerformanceCounter, OFFSET randomSeed
    ret
GetRandomSeed1 ENDP


Fall1 proc
    mov esi, OFFSET brick + ((brickNumY-1) * brickNumX-1) * 4 
    mov edi, OFFSET brick + (brickNumY * brickNumX-1) * 4
    std                                           
    mov ecx, (brickNumY-1)*brickNumX                               
    rep movsd                                    
    cld       
    call checkBrick1
    ret
Fall1 endp
    
checkBrick1 PROC
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
checkBrick1 ENDP

DrawScreen1 PROC

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
    je WBrick
    cmp DWORD PTR [esi+eax*4], 2
    je RBrick
    cmp DWORD PTR [esi+eax*4], 3
    je YBrick
    cmp DWORD PTR [esi+eax*4], 4
    je GBrick
    cmp DWORD PTR [esi+eax*4], 5
    je BBrick
    cmp DWORD PTR [esi+eax*4], 6
    je PBrick
    jmp Continue

WBrick:
    push eax
    push ecx
    invoke SelectObject, hdcMem, whiteBrush
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
YBrick:
    push eax
    push ecx
    invoke SelectObject, hdcMem, yellowBrush
    pop ecx
    pop eax
    jmp startDrawBrick
GBrick:
    push eax
    push ecx
    invoke SelectObject, hdcMem, greenBrush
    pop ecx
    pop eax
    jmp startDrawBrick
BBrick:
    push eax
    push ecx
    invoke SelectObject, hdcMem, blueBrush
    pop ecx
    pop eax
    jmp startDrawBrick
PBrick:
    push eax
    push ecx
    invoke SelectObject, hdcMem, purpleBrush
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
DrawScreen1 ENDP

goSpecialBrick1 PROC, brickType:DWORD
    cmp brickType, 1
    je brick1
    invoke mciSendString, addr specialBrickOpenCmd, NULL, 0, NULL
    invoke mciSendString, addr specialBrickVolumeCmd, NULL, 0, NULL
    invoke mciSendString, addr specialBrickPlayCmd, NULL, 0, NULL
    cmp brickType, 2
    je brick2
    cmp brickType, 3
    je brick3
    cmp brickType, 4
    je brick4
    cmp brickType, 5
    je brick5

brick1:
    invoke mciSendString, addr brickOpenCmd, NULL, 0, NULL
    invoke mciSendString, addr brickVolumeCmd, NULL, 0, NULL
    invoke mciSendString, addr brickPlayCmd, NULL, 0, NULL
    mov DWORD PTR [esi], 0
    add score, 1
    ret
brick2:
    add score, 6
    mov DWORD PTR [esi], 0
    ret
brick3:
    add score, 10
    mov DWORD PTR [esi], 0
    ret
brick4:
    add score, 18
    mov DWORD PTR [esi], 0
    ret
brick5:
    add score, 30
    mov DWORD PTR [esi], 0
    ret

goSpecialBrick1 ENDP

getBreakOutGame PROC
    mov eax, gameOver
    ret
getBreakOutGame ENDP

end