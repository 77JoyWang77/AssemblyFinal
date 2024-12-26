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
stepSize EQU 10                ; �C�����ʪ������ƶq
winWidth EQU 600               ; �����e��
winHeight EQU 600              ; ��������
winPosX EQU 400                ; ���� X ��m
winPosY EQU 0                  ; ���� Y ��m
timer EQU 20                   ; ������s�ɶ�
platformWidth EQU 120          ; ���x�e��
platformHeight EQU 15          ; ���x����
brickNumX EQU 10               ; �j���C��
brickNumY EQU 27               ; �j�����
brickTypeNum EQU 6             ; �j�������ƶq
brickWidth EQU 60              ; �j���e��
brickHeight EQU 20             ; �j������
fallTime EQU 3                 ; �����p�ɡ]��^
specialTime EQU 1              ; �S��p�ɡ]��^
ballRadius EQU 10              ; �p�y�b�|
OFFSET_BASE EQU 150            ; ���x�ϼu����
speed DWORD 10                 ; ���ʳt��
divisor DWORD 180              ; �p�Ⱓ��
line1Rect RECT <50, 555, 150, 615> ; ���ưϰ�

initialplatformX EQU 240       ; ���x��l X �y��
platformY EQU 530              ; ���x Y �y��
initialballX EQU 300           ; �p�y��l X �y��
initialballY EQU 400           ; �p�y��l Y �y��
initialvelocityX EQU 0       ; �p�y��l X ��V�t��
initialvelocityY EQU 10      ; �p�y��l Y ��V�t��
initialBrickRow EQU 5          ; ��l�j�����
initialfallTimeCount EQU 5            ; �j�������p�ɾ�
initialspecialTimeCount EQU 3         ; �S��j���p�ɾ�

.DATA 
ClassName db "SimpleWinClass7",0 
AppName  db "BreakOut",0 
Text db "Window", 0
EndGame db "Game Over!", 0
ScoreText db "Score:         ", 0

hBackBitmapName db "bmp/simplebreakout_background.bmp",0

; ����
fallBrickOpenCmd db "open wav/fallBrick.wav type mpegvideo alias fallBrickMusic", 0
fallBrickVolumeCmd db "setaudio fallBrickMusic volume to 100", 0
fallBrickPlayCmd db "play fallBrickMusic from 0", 0

brickOpenCmd db "open wav/brick.wav type mpegvideo alias brickMusic", 0
brickVolumeCmd db "setaudio brickMusic volume to 100", 0
brickPlayCmd db "play brickMusic from 0", 0

specialBrickOpenCmd db "open wav/specialBrick.wav type mpegvideo alias specialBrickMusic", 0
specialBrickVolumeCmd db "setaudio specialBrickMusic volume to 100", 0
specialBrickPlayCmd db "play specialBrickMusic from 0", 0

platformOpenCmd db "open wav/platform.wav type mpegvideo alias platformMusic", 0
platformVolumeCmd db "setaudio platformMusic volume to 100", 0
platformPlayCmd db "play platformMusic from 0", 0

breakOutLoseOpenCmd db "open wav/breakOutLose.wav type mpegvideo alias breakOutLoseMusic", 0
breakOutLoseVolumeCmd db "setaudio breakOutLoseMusic volume to 100", 0
breakOutLosePlayCmd db "play breakOutLoseMusic from 0", 0

gameOver DWORD 1               ; �C������

.DATA? 
hInstance HINSTANCE ?          ; �{����ҥy�`
hBitmap HBITMAP ?              ; ��ϥy�`
hBackBitmap HBITMAP ?          ; �I����ϥy�`
hBackBitmap2 HBITMAP ?         ; �ĤG�I����ϥy�`
hdcMem HDC ?                   ; �O����]�ƤW�U��
hdcBack HDC ?                  ; �I���]�ƤW�U��

tempWidth DWORD ?              ; �����ץ��e��
tempHeight DWORD ?             ; �����ץ�����
whiteBrush DWORD ?             ; �զ�e��
redBrush DWORD ?               ; ����e��
yellowBrush DWORD ?            ; ����e��
greenBrush DWORD ?             ; ���e��
blueBrush DWORD ?              ; �Ŧ�e��
purpleBrush DWORD ?            ; ����e��
blackBrush DWORD ?             ; �¦�e��

brickX DWORD ?                 ; �j�� X �y��
brickY DWORD ?                 ; �j�� Y �y��
platformX DWORD ?              ; ���x X �y��
offset_center DWORD ?          ; ���x���߰����q
ballX DWORD ?                  ; �y X �y��
ballY DWORD ?                  ; �y Y �y��
velocityX DWORD ?              ; �y X ��V�t��
velocityY DWORD ?              ; �y Y ��V�t��

brick DWORD brickNumY DUP(brickNumX DUP(?)) ; �j���x�}
fallTimeCount DWORD ?          ; �j�������p�ɾ�
specialTimeCount DWORD ?       ; �S��j���p�ɾ�
score DWORD ?                  ; ����
randomSeed DWORD ?             ; �H���ƺؤl


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
    invoke SetTimer, hwnd, 1, timer, NULL
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

        ; �]�w�C�������X�Ш�����귽
        mov gameOver, 1
        invoke KillTimer, hWnd, 1
        invoke DeleteObject, hBitmap
        invoke DeleteDC, hdcMem
        invoke ReleaseDC, hWnd, hdc
        invoke PostQuitMessage, NULL

    .ELSEIF uMsg == WM_CREATE
        ; ��l�ƹC���귽
        CALL initializeBreakOut1
        CALL initializeBrick1
        CALL initializeBrush1

        ; �[�����
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap, eax
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap2, eax

        ; �]�m���s DC
        invoke GetDC, hWnd
        mov hdc, eax
        invoke CreateCompatibleDC, hdc
        mov hdcMem, eax
        invoke CreateCompatibleDC, hdc
        mov hdcBack, eax
        invoke SelectObject, hdcMem, hBackBitmap
        invoke SelectObject, hdcBack, hBackBitmap2
        invoke ReleaseDC, hWnd, hdc
    .ELSEIF uMsg == WM_TIMER
        cmp gameOver, 1     ; �C������
        je game_over
        ; ��s�j���B�p�y�M���x�޿�
        call check_brick_fall1
        call update_ball1
        call check_platform_collision1

        ; �B�z���䲾��
        invoke GetAsyncKeyState, VK_LEFT
        test eax, 8000h
        jz skip_left
        mov eax, platformX
        cmp eax, stepSize
        jl skip_left
        sub eax, stepSize
        mov platformX, eax
    skip_left:
        ; �B�z�k�䲾��
        invoke GetAsyncKeyState, VK_RIGHT
        test eax, 8000h
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
        ; �P�_�j���I��
        call brick_collision1

        ; ��ø����
        invoke InvalidateRect, hWnd, NULL, FALSE
        ret

    game_over:
        ; �C����������
        invoke mciSendString, addr breakOutLoseOpenCmd, NULL, 0, NULL
        invoke mciSendString, addr breakOutLoseVolumeCmd, NULL, 0, NULL
        invoke mciSendString, addr breakOutLosePlayCmd, NULL, 0, NULL

        invoke KillTimer, hWnd, 1
        invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, 0

    .ELSEIF uMsg == WM_PAINT
        ; �B�z����ø��
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke BitBlt, hdcMem, 0, 0, winWidth, winHeight, hdcBack, 0, 0, SRCCOPY
        call DrawScreen1
        call updateScore
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps

    .ELSE
        ; �B�z�w�]����
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 
WndProc7 endp 

initializeBreakOut1 PROC    ; �C����l��
    mov platformX, initialplatformX
    mov ballX, initialballX
    mov ballY, initialballY
    mov velocityX, initialvelocityX
    mov velocityY, initialvelocityY
    mov fallTimeCount, initialfallTimeCount
    mov specialTimeCount, initialspecialTimeCount
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

initializeBrush1 PROC       ; �e���l��
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

initializeBrick1 proc           ; �j����l��
    mov esi, OFFSET brick
    mov eax, brickNumX
    mov ecx, initialBrickRow
    mul ecx
    mov ecx, eax
    mov ebx, 2                  ; �j������ (0���L�A1���զ�j��)

    invoke GetTickCount         ; �����e���t�έp�ɾ���
    mov eax, edx
    cdq
newRandomBrick:
    div ebx
    cmp edx, 0
    mov [esi], edx
    add esi, 4
    loop newRandomBrick

initializeBrick1 ENDP

update_ball1 PROC                  ; ��s�y��m
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

check_brick_fall1 PROC          ; ��s�j���M�S��j�޿�
    cmp fallTimeCount, 0
    jne no_brick_fall

    ; �j���U������
    invoke mciSendString, addr fallBrickOpenCmd, NULL, 0, NULL
    invoke mciSendString, addr fallBrickVolumeCmd, NULL, 0, NULL
    invoke mciSendString, addr fallBrickPlayCmd, NULL, 0, NULL

    ; �j���U��
    call Fall1
    call newBrick1
    mov eax, fallTime
    mov fallTimeCount, eax

    ; �S�ƿj��
    mov eax, specialTimeCount
    dec eax
    mov specialTimeCount, eax
    cmp eax, 0
    jne no_brick_fall
    call specialBrick1
    mov eax, specialTime
    mov specialTimeCount, eax
no_brick_fall:
    ret
check_brick_fall1 ENDP

check_platform_collision1 PROC      ; ���x�I��
    LOCAL angle:DWORD       ; �ϼu����

    mov eax, ballY
    add eax, ballRadius
    mov ebx, platformY
    cmp eax, ebx
    jl no_collision         ; �W�L���x�W��

    mov eax, ballY
    add ebx, platformHeight
    add ebx, ballRadius
    cmp eax, ebx
    jg no_collision         ; �W�L���x�U��

    mov eax, ballX
    add eax, ballRadius
    mov ebx, platformX
    cmp eax, ebx
    jl no_collision         ; �W�L���x����

    mov eax, ballX
    sub eax, ballRadius
    mov ebx, platformX
    add ebx, platformWidth
    cmp eax, ebx
    jg no_collision         ; �W�L���x�k��

    mov eax, ballX
    mov ebx, platformX
    cmp eax, ebx
    jl side_collision       ; ���x������

    mov ebx, platformX
    add ebx, platformWidth
    cmp eax, ebx
    jg side_collision       ; ���x�k����
    mov ebx, platformY
    sub ebx, ballRadius
    mov ballY, ebx

above_collision:
    ; �I���B�z (�t�צV30~150��)
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
    fistp DWORD PTR [velocityX]  ; �s�J velocityX

    fld st(0)                    ; ���׭�
    fsin                         ; �p�� sin(����)
    fild speed                   ; ���J�t�פj�p V
    fmul                         ; �p�� velocityY = sin(����) * V
    fistp DWORD PTR [velocityY]  ; �s�J velocityY
    
    ; ���� Y �t�ס]�ϼu�^
    neg velocityY
    jmp has_collision

side_collision:                 ; ���x����
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

check_left_side_collision:      ; ���x������ (�t��X�V�k)
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
    
check_right_side_collision:     ; ���x�k���� (�t��X�V��)
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

check_leftup_corner:            ; ���x���W���� (�t�צV150��)
    mov angle, 150
    mov eax, platformX
    mov ebx, platformY
    INVOKE corner_collision1, eax, ebx
    cmp eax, 1
    jne check_rightup_corner
    jmp do_corner_collision

check_rightup_corner:           ; ���x�k�W���� (�t�צV30��)
    mov angle, 30
    mov eax, platformX
    add eax, platformWidth
    mov ebx, platformY
    INVOKE corner_collision1, eax, ebx
    cmp eax, 1
    jne no_collision
    jmp do_corner_collision

check_leftbottom_corner:        ; ���x���U���� (�t�צV210��)
    mov angle, 210
    mov eax, platformX
    mov ebx, platformY
    add ebx, platformHeight
    INVOKE corner_collision1, eax, ebx
    cmp eax, 1
    jne check_rightbottom_corner
    jmp do_corner_collision

check_rightbottom_corner:       ; ���x�k�U���� (�t�צV330��)
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
    ; ���x�I������
    invoke mciSendString, addr platformOpenCmd, NULL, 0, NULL
    invoke mciSendString, addr platformVolumeCmd, NULL, 0, NULL
    invoke mciSendString, addr platformPlayCmd, NULL, 0, NULL
    dec fallTimeCount
no_collision:
    ret
check_platform_collision1 ENDP

brick_collision1 PROC           ; �j���I��
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
    neg velocityY             ; ���� Y ��V�t��
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
    neg velocityX             ; ���� X ��V�t��
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
    mov tempX, eax          ; tempX = brickIndexX * brickWidth

    mov eax, brickIndexY
    mov ebx, brickHeight
    mul ebx
    mov tempY, eax          ; tempY = brickIndexY * brickHeight

    Invoke corner_collision1, tempX, tempY
    cmp eax, 0
    je leftbottom
    invoke goSpecialBrick1, [esi]
    cmp velocityX, 0
    jge skipLeftupX         
    neg velocityX           ; X ��V�t�׬���
skipLeftupX:
    cmp velocityY, 0
    jge leftbottom
    neg velocityY           ; Y ��V�t�׬���

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
    mov tempX, eax          ; tempX = brickIndexX * brickWidth

    mov eax, brickIndexY
    inc eax
    mov ebx, brickHeight
    mul ebx
    mov tempY, eax          ; tempY = (brickIndexY + 1) * brickHeight

    Invoke corner_collision1, tempX, tempY
    cmp eax, 0
    je rightup
    invoke goSpecialBrick1, [esi]
    cmp velocityX, 0
    jge skipLeftbottomX
    neg velocityX           ; X ��V�t�׬���
skipLeftbottomX:
    cmp velocityY, 0
    jle rightup
    neg velocityY           ; Y ��V�t�׬��t

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
    mov tempX, eax          ; tempX = (brickIndexX + 1) * brickWidth

    mov eax, brickIndexY
    mov ebx, brickHeight
    mul ebx
    mov tempY, eax          ; tempY = brickIndexY * brickHeight

    Invoke corner_collision1, tempX, tempY
    cmp eax, 0
    je rightbottom
    invoke goSpecialBrick1, [esi]
    cmp velocityX, 0
    jle skipRightupX
    neg velocityX           ; X ��V�t�׬��t
skipRightupX:
    cmp velocityY, 0
    jge rightbottom
    neg velocityY           ; Y ��V�t�׬���

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
    mov tempX, eax          ; tempX = (brickIndexX + 1) * brickWidth

    mov eax, brickIndexY
    inc eax
    mov ebx, brickHeight
    mul ebx
    mov tempY, eax          ; tempY = (brickIndexY + 1) * brickHeight

    Invoke corner_collision1, tempX, tempY
    cmp eax, 0
    je no_brick_collision
    invoke goSpecialBrick1, [esi]
    mov eax, velocityX
    cmp eax, 0
    jle skipRightbottomX
    neg velocityX           ; X ��V�t�׬��t
skipRightbottomX:
    mov eax, velocityY
    cmp eax, 0
    jle no_brick_collision
    neg velocityY           ; Y ��V�t�׬��t

no_brick_collision:
    ret
brick_collision1 ENDP

corner_collision1 PROC,     ; �����I��
    corner_X : DWORD,
    corner_Y : DWORD
    LOCAL square_X : DWORD
    LOCAL square_Y : DWORD

    mov eax, ballX
    sub eax, corner_X
    imul eax, eax
    mov square_X, eax       ; square_X = (ballX - cornerX) ** 2

    mov eax, ballY
    sub eax, corner_Y
    imul eax, eax
    mov square_Y, eax       ; square_Y = (ballY - cornerY) ** 2
    
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

updateScore proc
    invoke SetBkMode, hdcMem, TRANSPARENT

    lea edi, ScoreText + 14
    mov ecx, 4                      ; �̤j�Ʀr���
    mov eax, score
    mov ebx, 10
    cmp ebx, 0
    je div_error                    ; �p�G���Ƭ� 0�A������~�B�z

convert_loop:
    xor edx, edx
    div ebx
    add dl, '0'                     ; �N�l���ର ASCII
    dec edi
    mov [edi], dl
    dec ecx
    test eax, eax
    jnz convert_loop

    mov al, ' '                    ; �]�m�e�m�Ů�
fill_spaces:
    dec edi
    mov [edi], al
    dec ecx
    jnz fill_spaces

    invoke DrawText, hdcMem, addr ScoreText, -1, addr line1Rect, DT_CENTER
    ret

div_error:
    ret
updateScore ENDP

newBrick1 proc                      ; �ͦ��s�j��
    call GetRandomSeed1             ; ���o�H���ؤl
    mov eax, randomSeed
    mov esi, OFFSET brick
    mov ecx, brickNumX
    mov ebx, 2                      ; �j������ (0���L�A1���զ�)

newRandomBrick:
    imul eax, eax, 1664525          ; ���H�Y�� a�]1664525 �O�`�έȡ^
    add eax, 1013904223             ; �[�W�W�q c
    and eax, 7FFFFFFFh              ; �O�ҵ��G������
    mov randomSeed, eax             ; �u�ʦP�l�ͦ���: (a * seed + c) % m
    xor edx, edx
    div ebx
    mov [esi], edx
    add esi, 4
    loop newRandomBrick

    ret
newBrick1 ENDP

specialBrick1 proc                  ; �ͦ��S��j��
    call GetRandomSeed1             ; ���o�H���ؤl
    mov eax, randomSeed
    mov esi, OFFSET brick

    mov ebx, brickNumX              ; �j���ƶq
    imul eax, eax, 1664525          ; ���H�Y�� a�]1664525 �O�`�έȡ^
    add eax, 1013904223             ; �[�W�W�q c
    and eax, 7FFFFFFFh              ; �O�ҵ��G������
    mov randomSeed, eax             ; �u�ʦP�l�ͦ���: (a * seed + c) % m
    xor edx, edx
    div ebx
    shl edx, 2
    add esi, edx                    ; �H����m
    
    mov ebx, brickTypeNum           ; �j��������
    imul eax, eax, 1664525          ; ���H�Y�� a�]1664525 �O�`�έȡ^
    add eax, 1013904223             ; �[�W�W�q c
    and eax, 7FFFFFFFh              ; �O�ҵ��G������
    mov randomSeed, eax             ; �u�ʦP�l�ͦ���: (a * seed + c) % m
    xor edx, edx
    div ebx
    mov [esi], edx

    ret
specialBrick1 ENDP

GetRandomSeed1 proc                 ; ���o�H���ؤl
    invoke QueryPerformanceCounter, OFFSET randomSeed
    ret
GetRandomSeed1 ENDP


Fall1 proc                          ; �j���U��
    mov esi, OFFSET brick + ((brickNumY-1) * brickNumX-1) * 4 
    mov edi, OFFSET brick + (brickNumY * brickNumX-1) * 4
    std                                           
    mov ecx, (brickNumY-1)*brickNumX                               
    rep movsd                                    
    cld       
    call checkBrick1
    ret
Fall1 endp
    
checkBrick1 PROC                    ; �P�_�j���O�_�U����W�L���x
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

    ; �P�_�j���C��
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
    
startDrawBrick:             ; ø�s�j��
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

goSpecialBrick1 PROC, brickType:DWORD       ; �S��j�� (���ĻP�[��)
    cmp brickType, 1
    je brick1
    ; �S��j������
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

brick1:                     ; �զ�j��
    ;�զ�j������
    invoke mciSendString, addr brickOpenCmd, NULL, 0, NULL
    invoke mciSendString, addr brickVolumeCmd, NULL, 0, NULL
    invoke mciSendString, addr brickPlayCmd, NULL, 0, NULL
    mov DWORD PTR [esi], 0
    add score, 1
    ret
brick2:                     ; ����j�� (���� + 6)
    add score, 6
    mov DWORD PTR [esi], 0
    ret
brick3:                     ; ����j�� (���� + 10)
    add score, 10
    mov DWORD PTR [esi], 0
    ret
brick4:                     ; ���j�� (���� + 18)
    add score, 18
    mov DWORD PTR [esi], 0
    ret
brick5:                     ; �Ŧ�j�� (���� + 30)
    add score, 30
    mov DWORD PTR [esi], 0
    ret

goSpecialBrick1 ENDP

getBreakOutGame PROC        ; �T�{�C���O�_����
    mov eax, gameOver       ; �s�Jeax (�ǤJhome)
    ret
getBreakOutGame ENDP

end