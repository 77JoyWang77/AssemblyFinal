.386 
.model flat,stdcall 
option casemap:none 

EXTERN WinMain1@0: PROC
EXTERN WinMain2@0: PROC
EXTERN WinMain3@0: PROC
EXTERN WinMain4@0: PROC
EXTERN WinMain5@0: PROC
EXTERN WinMain6@0: PROC

EXTERN getAdvanced1A2BGame@0: PROC
EXTERN getCake1Game@0: PROC
EXTERN getCake2Game@0: PROC
EXTERN getMinesweeperGame@0: PROC

EXTERN Advanced1A2BfromBreakOut@0: PROC
EXTERN Cake1fromBreakOut@0: PROC
EXTERN Cake2fromBreakOut@0: PROC
EXTERN MinesweeperfromBreakOut@0: PROC

Advanced1A2B EQU WinMain1@0
GameBrick EQU WinMain2@0
Cake1 EQU WinMain3@0
Cake2 EQU WinMain4@0
Minesweeper EQU WinMain5@0
Tofu EQU WinMain6@0

checkAdvanced1A2B EQU getAdvanced1A2BGame@0
checkCake1 EQU getCake1Game@0
checkCake2 EQU getCake2Game@0
checkMinesweeper EQU getMinesweeperGame@0

goAdvanced1A2B EQU Advanced1A2BfromBreakOut@0
goCake1 EQU Cake1fromBreakOut@0
goCake2 EQU Cake2fromBreakOut@0
goMinesweeper EQU MinesweeperfromBreakOut@0

goSpecialBrick proto :DWORD
corner_collision proto :DWORD,:DWORD

include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 
include winmm.inc

.CONST
platformWidth EQU 120       ; ���x�e��
platformHeight EQU 15       ; ���x����
stepSize DWORD 10             ; �C�����ʪ������ƶq
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
timer EQU 20
speed DWORD 10
divisor DWORD 180
line1Rect RECT <20, 560, 120, 600>
line2Rect RECT <400, 560, 600, 600>

.DATA 
ClassName db "SimpleWinClass2",0 
AppName  db "AdvancedBreakOut",0
Text db "Window", 0
EndGame db "Game Over!", 0
TimeText db "Time:         ", 0
OtherGameText db "                                  ", 0

hBackBitmapName db "bitmap5.bmp",0

WinText1A2B db "You Win 1A2B", 0
WinTextCake1 db "You Win Cake1", 0
WinTextCake2 db "You Win Cake2", 0
WinTextMinesweeper db "You Win Minesweeper", 0
LoseText1A2B db "You Lose 1A2B", 0
LoseTextCake1 db "You Lose Cake1", 0
LoseTextCake2 db "You Lose Cake2", 0
LoseTextMinesweeper db "You Lose Minesweeper", 0
GoingText1A2B db "1A2B is still going !", 0
GoingTextCake1 db "Cake1 is still going !", 0
GoingTextCake2 db "Cake2 is still going !", 0
GoingTextMinesweeper db "Minesweeper is still going !", 0

offset_center DWORD 0
controlsCreated DWORD 0
platformX DWORD 270           ; ��l X �y��
platformY DWORD 530           ; ��l Y �y��
ballX DWORD 300               ; �p�y X �y��
ballY DWORD 400               ; �p�y Y �y��
velocityX DWORD 0             ; �p�y X ��V�t��
velocityY DWORD 10            ; �p�y Y ��V�t��
brick DWORD brickNumY DUP(brickNumX DUP(0))
fallTimeCount DWORD 5
specialTimeCount DWORD 5
gameOver DWORD 1
gameTypeCount DWORD 2
time DWORD 0
timeCounter DWORD 0
countOtherGameText DWORD 0
winPosX DWORD 400
winPosY DWORD 0

randomNum DWORD 0
randomSeed DWORD 0                 ; �H���ƺؤl


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
WinMain2 proc
    LOCAL wc:WNDCLASSEX 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT                   ; �w�q RECT ���c
    LOCAL msg:MSG
    
    invoke GetModuleHandle, NULL 
    mov    hInstance,eax 

    ; �w�q���f���O
    mov   wc.cbSize,SIZEOF WNDCLASSEX 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc2
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

    ; �]�m�Ȥ�Ϥj�p
    mov wr.left, 0
    mov wr.top, 0
    mov eax, winWidth
    mov wr.right, eax
    mov eax, winHeight
    mov wr.bottom, eax

    ; �վ㵡�f�j�p
    invoke AdjustWindowRect, ADDR wr, WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, FALSE
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
WinMain2 endp


WndProc2 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 

    .IF uMsg == WM_DESTROY 
        
        ; �]�w�C�������X�Ш�����귽
        mov gameOver, 1
        invoke KillTimer, hWnd, 1
        invoke DeleteObject, hBitmap
        invoke DeleteDC, hdcMem
        invoke DeleteDC, hdcBack
        invoke ReleaseDC, hWnd, hdc
        invoke PostQuitMessage, NULL
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_CREATE
        ; ��l�ƹC���귽
        call initializeBreakOut
        call initializeBrick
        call initializeBrush

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
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_TIMER
        ; �B�z�w�ɾ��ƥ�
        cmp gameOver, 1
        je game_over

        ; ��s�C���p�ɾ�
        mov eax, timeCounter
        add eax, timer
        mov timeCounter, eax
        cmp eax, 1000
        jl skipAddTime
        mov timeCounter, 0
        inc time
    skipAddTime:

        ; ��s�j���M�S��j�޿�
        cmp fallTimeCount, 0
        jne no_brick_fall
        call Fall
        call newBrick
        mov eax, fallTime
        mov fallTimeCount, eax

        mov eax, specialTimeCount
        dec eax
        mov specialTimeCount, eax
        cmp eax, 0
        jne no_brick_fall
        call specialBrick
        mov eax, specialTime
        mov specialTimeCount, eax
    no_brick_fall:

        ; ��s�p�y�M���x�޿�
        call update_ball
        call check_platform_collision

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

        call brick_collision

        ; ��ø����
        invoke InvalidateRect, hWnd, NULL, FALSE
        xor eax, eax
        ret

    game_over:
        invoke InvalidateRect, hWnd, NULL, FALSE
        invoke KillTimer, hWnd, 1
        invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, 0
        ret

    .ELSEIF uMsg == WM_PAINT
        ; �B�z����ø��
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke BitBlt, hdcMem, 0, 0, winWidth, winHeight, hdcBack, 0, 0, SRCCOPY
        call DrawScreen
        call updateTime
        call updateOtherGameText
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps
        xor eax, eax
        ret

    .ELSE
        ; �B�z�w�]����
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
        ret
    .ENDIF
    xor eax, eax
    ret
WndProc2 endp


initializeBreakOut PROC
    mov platformX, 240
    mov ballX, 300
    mov ballY, 200
    mov velocityX, 0
    mov velocityY, 10
    mov fallTimeCount, 1
    mov specialTimeCount, 1
    mov gameOver, 0
    mov time, 0
    mov timeCounter, 0
    mov countOtherGameText, 0
    
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
initializeBrush ENDP

updateTime proc
    invoke SetBkMode, hdcMem, TRANSPARENT

    ; ��l�ƫ��лP�ܼ�
    lea edi, TimeText + 14        ; �w���Ʀr�_�l��}
    mov ecx, 4                     ; �w���̤j�Ʀr���
    mov eax, time                 ; ���J score ����
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
    invoke DrawText, hdcMem, addr TimeText, -1, addr line1Rect, DT_CENTER
    ret

div_error:
    ; �B�z���H�s���~�]�i�H�O����x�νոա^
    ret

updateTime ENDP

updateOtherGameText PROC
    cmp countOtherGameText, 0
    jle skip
    dec countOtherGameText
    invoke SetBkMode, hdcMem, TRANSPARENT
    invoke DrawText, hdcMem, addr OtherGameText, -1, addr line2Rect, DT_CENTER
skip:
    ret
updateOtherGameText ENDP

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
    mov velocityX, 0
    mov velocityY, 0
    mov gameOver, 1

end_update:
    ret
update_ball ENDP

check_platform_collision PROC
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
    
    mov eax, platformX
    sub eax, ballX
    add eax, OFFSET_BASE
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

has_collision:
    dec fallTimeCount
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
    neg velocityY                  ; ���� Y ��V�t��
    invoke goSpecialBrick, [esi]
    mov DWORD PTR [esi], 0         ; �����j��

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
    invoke goSpecialBrick, [esi]
    mov DWORD PTR [esi], 0         ; �����j��
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
    invoke goSpecialBrick, [esi]
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
    invoke goSpecialBrick, [esi]
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
    invoke goSpecialBrick, [esi]
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
    invoke goSpecialBrick, [esi]
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

initializeBrick ENDP

newBrick proc
    call GetRandomSeed              ; ���o�H���ؤl
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

newBrick ENDP

specialBrick proc
    call GetRandomSeed              ; ���o�H���ؤl
    mov eax, randomSeed
    mov esi, OFFSET brick           ; ��l�ƿj���}�C����

    mov ebx, brickNumX           ; �j��������
    
    mov ebx, brickTypeNum
    imul eax, eax, 1664525          ; ���H�Y�� a�]1664525 �O�`�έȡ^
    add eax, 1013904223             ; �[�W�W�q c
    and eax, 7FFFFFFFh             ; �O�ҵ��G������
    mov randomSeed, eax             ; ��s�H���ؤl
    xor edx, edx                    ; �M�� edx
    div ebx                         ; ��o�H������
    shl edx, 2
    add esi, edx

    mov ebx, gameTypeCount
    mov [esi], ebx

    inc gameTypeCount
    cmp gameTypeCount, 6
    je initializeGameType
    ret

initializeGameType:
    mov gameTypeCount, 2

    ret
specialBrick ENDP

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
DrawScreen ENDP

goSpecialBrick PROC, brickType:DWORD
    cmp brickType, 2
    je StartGame1
    cmp brickType, 3
    je StartGame2
    cmp brickType, 4
    je StartGame3
    cmp brickType, 5
    je StartGame4
    jmp noGame

StartGame1:
    call checkAdvanced1A2B
    cmp eax, 1
    je goGame1
    mov eax, 11
    call getOtherGame
    mov gameOver, 1
    ret
goGame1:
    mov DWORD PTR [esi], 0
    call goAdvanced1A2B
    call Advanced1A2B
    ret
StartGame2:
    call checkCake1
    cmp eax, 1
    je goGame2
    mov eax, 12
    call getOtherGame
    mov gameOver, 1
    ret
goGame2:
    mov DWORD PTR [esi], 0
    call goCake1
    call Cake1
    ret
StartGame3:
    call checkCake2
    cmp eax, 1
    je goGame3
    mov eax, 13
    call getOtherGame
    mov gameOver, 1
    ret
goGame3:
    mov DWORD PTR [esi], 0
    call goCake2
    call Cake2
    ret
StartGame4:
    call checkMinesweeper
    cmp eax, 1
    je goGame4
    mov eax, 14
    call getOtherGame
    mov gameOver, 1
    ret
goGame4:
    mov DWORD PTR [esi], 0
    call goMinesweeper
    call Minesweeper

noGame:
    mov DWORD PTR [esi], 0
    ret

goSpecialBrick ENDP

getAdvancedBreakOutGame PROC
    mov eax, gameOver
    ret
getAdvancedBreakOutGame ENDP

getOtherGame proc
    mov countOtherGameText, 100
    lea edi, OtherGameText + 20      ; �]�w�r�ꪺ�}�l��m

    cmp eax, 1
    je Advanced1A2BWin
    cmp eax, 2
    je Cake1Win
    cmp eax, 3
    je Cake2Win
    cmp eax, 4
    je MinesweeperWin

    cmp eax, -1
    je Advanced1A2BLose
    cmp eax, -2
    je Cake1Lose
    cmp eax, -3
    je Cake2Lose
    cmp eax, -4
    je MinesweeperLose

    cmp eax, 11
    je Advanced1A2BGoing
    cmp eax, 12
    je Cake1Going
    cmp eax, 13
    je Cake2Going
    cmp eax, 14
    je MinesweeperGoing
    ret

Advanced1A2BWin:
    ; �g�J�r�� "You Win 1A2B" �� OtherGameText
    lea esi, WinText1A2B
    call WriteOtherGameString
    ret

Cake1Win:
    ; �g�J�r�� "You Win Cake1" �� OtherGameText
    lea esi, WinTextCake1
    call WriteOtherGameString
    ret

Cake2Win:
    ; �g�J�r�� "You Win Cake2" �� OtherGameText
    lea esi, WinTextCake2
    call WriteOtherGameString
    ret

MinesweeperWin:
    ; �g�J�r�� "You Win Minesweeper" �� OtherGameText
    lea esi, WinTextMinesweeper
    call WriteOtherGameString
    ret

Advanced1A2BLose:
    ; �g�J�r�� "You Lose 1A2B" �� OtherGameText
    lea esi, LoseText1A2B
    call WriteOtherGameString
    ret

Cake1Lose:
    ; �g�J�r�� "You Lose Cake1" �� OtherGameText
    lea esi, LoseTextCake1
    call WriteOtherGameString
    ret

Cake2Lose:
    ; �g�J�r�� "You Lose Cake2" �� OtherGameText
    lea esi, LoseTextCake2
    call WriteOtherGameString
    ret

MinesweeperLose:
    ; �g�J�r�� "You Lose Minesweeper" �� OtherGameText
    lea esi, LoseTextMinesweeper
    call WriteOtherGameString
    ret

Advanced1A2BGoing:
    ; �g�J�r�� "You Lose 1A2B" �� OtherGameText
    lea esi, GoingText1A2B
    call WriteOtherGameString
    ret

Cake1Going:
    ; �g�J�r�� "You Lose Cake1" �� OtherGameText
    lea esi, GoingTextCake1
    call WriteOtherGameString
    ret

Cake2Going:
    ; �g�J�r�� "You Lose Cake2" �� OtherGameText
    lea esi, GoingTextCake2
    call WriteOtherGameString
    ret

MinesweeperGoing:
    ; �g�J�r�� "You Lose Minesweeper" �� OtherGameText
    lea esi, GoingTextMinesweeper
    call WriteOtherGameString
    ret
getOtherGame endp

; �@��²�檺 WriteOtherGameString ��ƨӼg�J�r��
WriteOtherGameString proc
    ; ��J�GESI = �r��a�}
    lea edi, OtherGameText    ; �}�l��m
next_char:
    mov al, [esi]                 ; ���J�r�ꪺ��e�r��
    mov [edi], al                 ; �s�J�O����
    inc esi                        ; ���ܤU�@�Ӧr��
    inc edi                        ; ���ܤU�@�Ӧ�m
    cmp al, 0                      ; �ˬd�O�_�O null �פ��
    jne next_char                 ; �p�G���O�A�~��g�J
    ret
WriteOtherGameString endp
    
end
