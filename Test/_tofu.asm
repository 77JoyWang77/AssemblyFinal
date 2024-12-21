.386
.model flat,stdcall
option casemap:none

include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc
include winmm.inc

.CONST
winWidth EQU 300          ; �����e��
winHeight EQU 400         ; ��������
border_left EQU 120
ballSize EQU 20           ; �y���j�p
updateInterval EQU 30     ; �p�ɾ���s���j (ms)
initialVelocity EQU -20   ; ��l�t�� (�t�ȦV�W)
gravity EQU 2             ; �������O�[�t��
initialground EQU 250     ; �a�O����
radius EQU 10             ; �b�|
cakeWidth EQU 60          ; �J�|�e��
cakeHeight EQU 20         ; �J�|����
initialcakeX EQU 230      ; ��l X �y��
initialcakeY EQU 230      ; ��l Y �y��
initialvelocityX EQU -3   ; X ��V�t��
dropSpeed EQU 10
maxCakes EQU 100
cakeMoveSize EQU 5

.DATA
ClassName db "SimpleWinClass8", 0
AppName  db "Tofu", 0
RemainingTriesText db "Remaining:   ", 0
EndGame  db "Game Over", 0

hBackBitmapName db "bitmap4.bmp",0
hitOpenCmd db "open hit.wav type mpegvideo alias hitMusic", 0
hitVolumeCmd db "setaudio hitMusic volume to 300", 0
hitPlayCmd db "play hitMusic from 0", 0

line1Rect RECT <30, 30, 280, 50>
ball RECT <140, 230, 160, 250> ; �y����l��m
firstcake RECT <120, 250, 180, 270>
cakes RECT <120, 250, 180, 270>, 99 DUP(<0, 0, 0, 0>)
colors DWORD 07165FBh, 0A5B0F4h, 0F0EBC4h, 0B2C61Fh, 0D3F0B8h, 0C3CC94h, 0E9EFA8h, 0D38A92h, 094C9E4h, 0B08DDDh, 0E1BFA2h, 09B97D8h, 09ADFCBh, 0A394D1h, 0BF95DCh, 09CE1D6h, 0E099C1h, 0DCD0A0h, 09B93D9h, 0D3D1B2h
colors_count EQU ($ - colors) / 4

.DATA?
hInstance HINSTANCE ?
hBitmap HBITMAP ?
hBackBitmap HBITMAP ?
hBackBitmap2 HBITMAP ?
hdc HDC ?
hdcMem HDC ?
hdcBack HDC ?
hBallBrush HBRUSH ?
brushes HBRUSH maxCakes DUP(?)

velocityY DWORD ?              ; �y�������t��
tempWidth DWORD ?
tempHeight DWORD ?
cakeX DWORD ?                        ; X �y��
cakeY DWORD ?                        ; Y �y��
cVelocityX DWORD ?                   ; X ��V�t��
cVelocityY DWORD ?                   ; Y ��V�t��
currentCakeIndex DWORD ?             ; ��e�J�|����
TriesRemaining BYTE ?                ; �Ѿl����
groundMoveCount DWORD ?              ; �O���a���w���ʪ������`��
needMove DWORD ?
ground DWORD ?
gameover BOOL ?
canDrop BOOL ?
valid BOOL ?
way BOOL ?
move BOOL ?

.CODE
WinMain6 proc
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    LOCAL hwnd:HWND
    LOCAL wr:RECT

    invoke GetModuleHandle, NULL
    mov    hInstance,eax

    ; ��l�Ƶ��f��
    mov wc.cbSize,SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET WndProc6
    mov wc.cbClsExtra,NULL
    mov wc.cbWndExtra,NULL
    push hInstance
    pop wc.hInstance
    mov wc.hbrBackground,COLOR_WINDOW+1
    mov wc.lpszMenuName,NULL
    mov wc.lpszClassName,OFFSET ClassName
    invoke LoadIcon,NULL,IDI_APPLICATION
    mov wc.hIcon,eax
    mov wc.hIconSm,eax
    invoke LoadCursor,NULL,IDC_ARROW
    mov wc.hCursor,eax
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
           CW_USEDEFAULT, CW_USEDEFAULT, tempWidth, tempHeight, \
           NULL, NULL, hInstance, NULL
    mov hwnd,eax

    invoke ShowWindow, hwnd, SW_SHOWNORMAL
    invoke UpdateWindow, hwnd
    

    ; �D�����`��
    .WHILE TRUE
        invoke GetMessage, ADDR msg, NULL, 0, 0
        .BREAK .IF (!eax)
        invoke TranslateMessage, ADDR msg
        invoke DispatchMessage, ADDR msg
    .ENDW
    mov eax, msg.wParam
    ret
WinMain6 endp

WndProc6 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL ps:PAINTSTRUCT

    .IF uMsg == WM_CREATE
        call SetBrushes3
        call initializeCake3

        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap, eax
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap2, eax
        ; ��l�Ƹ귽
        invoke GetDC,hWnd              
        mov hdc, eax
        invoke CreateCompatibleDC,hdc  
        mov hdcMem, eax
        invoke CreateCompatibleDC,hdc 
        mov hdcBack, eax
        invoke SelectObject, hdcMem, hBackBitmap
        invoke SelectObject, hdcBack, hBackBitmap2
        invoke ReleaseDC, hWnd, hdc

        invoke CreateSolidBrush, 00C9A133h
        mov hBallBrush, eax

        ; ��l�Ʋy�B��
        mov velocityY, 0
        mov move, FALSE
        invoke SetTimer, hWnd, 1, updateInterval, NULL

    .ELSEIF uMsg == WM_TIMER
        invoke GetAsyncKeyState, VK_SPACE
        test eax, 8000h ; ���ճ̰���
        jz skip_space_key

        cmp ball.bottom, initialground
        jl skip_space_key

        cmp move, TRUE
        je skip_space_key
        mov velocityY, initialVelocity
        mov move, TRUE

    skip_space_key:
        call update_cake3
        mov ebx, SIZEOF RECT
        imul ebx, currentCakeIndex
        mov eax, cakeX
        mov cakes[ebx].left, eax
        add eax, cakeWidth
        mov cakes[ebx].right, eax
        mov eax, cakeY
        mov cakes[ebx].top, eax
        add eax, cakeHeight
        mov cakes[ebx].bottom, eax

    start_move:
        cmp move, FALSE
        je skip_move
        call Update_move

    skip_move:
        cmp ball.bottom, initialcakeY
        jl move_ground

        call check_ball
        cmp gameover, TRUE
        je game_over
        cmp valid, TRUE
        je next

        cmp cakeX, border_left
        jne move_ground

        call check_collision3
        cmp canDrop, FALSE
        je move_ground

    next:
        invoke mciSendString, addr hitOpenCmd, NULL, 0, NULL
        invoke mciSendString, addr hitVolumeCmd, NULL, 0, NULL
        invoke mciSendString, addr hitPlayCmd, NULL, 0, NULL
        mov move, FALSE
        mov valid,FALSE
        mov eax, cakeHeight
        add needMove, eax
        invoke InvalidateRect, hWnd, NULL, FALSE
        inc currentCakeIndex  ; �U�@�ӳJ�|
        mov cakeX, initialcakeX
        mov cVelocityX, initialvelocityX
        mov cakeY, initialcakeY
        mov cVelocityY, 0
        dec TriesRemaining

        cmp gameover, TRUE
        je game_over
        cmp TriesRemaining, 0
        je game_over
        ret

    move_ground:
        mov ebx, needMove
        cmp ebx, groundMoveCount
        jle skip_fall

        ; �a���M�J�|�~�򲾰�
        add groundMoveCount, cakeMoveSize
        add ground, cakeMoveSize
        add ball.top, cakeMoveSize
        add ball.bottom, cakeMoveSize

        mov ecx, currentCakeIndex
        dec ecx
    move_ground_loop:
        mov eax, ecx
        cmp eax, 0
        jl skip_fall
        mov ebx, SIZEOF RECT
        imul ebx
        add cakes[eax].top, cakeMoveSize
        add cakes[eax].bottom, cakeMoveSize
        dec ecx
        jmp move_ground_loop

    skip_fall:
        invoke InvalidateRect, hWnd, NULL, FALSE
        ret
    game_over:
        ; ��ܹC�������T��
        invoke KillTimer, hWnd, 1
        invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
        invoke DeleteObject, hBitmap
        invoke DeleteDC, hdcMem
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, 0
        ret
    .ELSEIF uMsg == WM_PAINT
        ; ø�s�I���P�y
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke BitBlt, hdcMem, 0, 0, winWidth, winHeight, hdcBack, 0, 0, SRCCOPY
        call Update3
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps

    .ELSEIF uMsg == WM_DESTROY
        ; �M�z�귽
        invoke KillTimer, hWnd, 1
        invoke DeleteObject, hBallBrush
        invoke DeleteObject, hBitmap
        invoke DeleteDC, hdcMem
        invoke ReleaseDC, hWnd, hdc
        invoke PostQuitMessage, NULL

    .ELSE
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
        ret
    .ENDIF
    xor eax, eax
    ret
WndProc6 endp

Update_move PROC
    ; ��s�y����m
    mov eax, velocityY
    add ball.top, eax
    mov eax, velocityY
    add ball.bottom, eax
    add velocityY, gravity
    cmp velocityY, 0
    jl no_collision

    ; �ˬd�I���a�O
    mov eax, ball.bottom
    cmp eax, initialcakeY
    jl no_collision

    ; ����B�ʨéT�w�y��m
    mov velocityY, 0  ; ����B��
    mov move, FALSE

no_collision:
    ret
Update_move ENDP

initializeCake3 PROC
    mov cakeX, initialcakeX
    mov cakeY, initialcakeY
    mov ground, initialground
    mov cVelocityX, initialvelocityX
    mov cVelocityY, 0
    mov TriesRemaining, maxCakes
    dec TriesRemaining
    mov groundMoveCount, 0
    mov needMove, 0
    mov currentCakeIndex, 1
    mov gameover, FALSE
    mov valid, FALSE
    mov eax, firstcake.top
    mov cakes.top, eax
    mov eax, firstcake.bottom
    mov cakes.bottom, eax
    mov eax, firstcake.left
    mov cakes.left, eax
    mov eax, firstcake.right
    mov cakes.right, eax
initializeCake3 ENDP

; ��s�J�|��m
update_cake3 PROC
    cmp cVelocityX, 0
    je end_update
    mov eax, cakeX
    cmp eax, border_left
    je end_update
    add eax, cVelocityX
    mov cakeX, eax
end_update:
    ret
update_cake3 ENDP

; �P�_�O�_�i��U�A�Oreturn eax TRUE
check_collision3 PROC
    LOCAL cr:RECT
    LOCAL lr:RECT

    mov eax, currentCakeIndex
    mov ebx, SIZEOF RECT
    imul ebx
    mov ebx, cakes[eax].bottom
    mov cr.bottom, ebx
    mov ebx, cakes[eax].top
    mov cr.top, ebx
    mov ebx, cakes[eax].left
    mov cr.left, ebx
    mov ebx, cakes[eax].right
    mov cr.right, ebx

    mov ebx, cakes[eax - 16].bottom
    mov lr.bottom, ebx
    mov ebx, cakes[eax - 16].top
    mov lr.top, ebx
    mov ebx, cakes[eax - 16].left
    mov lr.left, ebx
    mov ebx, cakes[eax - 16].right
    mov lr.right, ebx

check_left:
    mov eax, lr.left
    cmp cr.left, eax
    jl check_end
    
check_right:
    mov eax, lr.right
    cmp cr.left, eax
    jl game_not_over

check_end:
    mov canDrop, FALSE
    ret

game_not_over:
    mov canDrop, TRUE
    ret
check_collision3 ENDP

check_ball PROC
    Local cr:RECT

    mov eax, currentCakeIndex
    mov ebx, SIZEOF RECT
    imul ebx
    mov ebx, cakes[eax].bottom
    mov cr.bottom, ebx
    mov ebx, cakes[eax].top
    mov cr.top, ebx
    mov ebx, cakes[eax].left
    mov cr.left, ebx
    mov ebx, cakes[eax].right
    mov cr.right, ebx


    ; �ˬd�y�O�_�P�J�|�ۼ�
    mov eax, ball.right
    cmp eax, cr.left  ; �y���k��ɦb�J�|������ɥk��
    jbe ball_not_collision  ; �p�G�O�A�h���I��

    mov eax, ball.bottom
    cmp eax, cr.top   ; �y�������O�_�b�J�|���W��
    jae invalid_collision  ; �p�G�O�A�h���I��
    jmp ball_not_collision

invalid_collision:
    cmp eax, initialcakeY
    je valid_collision
    mov gameover, TRUE;
    jmp ball_not_collision

valid_collision:
    mov valid, TRUE
ball_not_collision:
    ret
check_ball ENDP

Update3 PROC
    invoke SetBkMode, hdcMem, TRANSPARENT

    mov bl, 10
    xor ah, ah
    mov al, [TriesRemaining]       ; �N TriesRemaining ���ȸ��J eax
    div bl
    mov byte ptr [RemainingTriesText + 11], ' '
    cmp al, 0
    je nextdigit
    add al, '0'                     ; �N�Ʀr�ഫ�� ASCII (����)
    mov byte ptr [RemainingTriesText + 11], al ; �N�r���g�J�r��
    nextdigit:
    add ah, '0'                     ; �N�Ʀr�ഫ�� ASCII (����)
    mov byte ptr [RemainingTriesText + 12], ah ; �N�r���g�J�r��
    invoke DrawText, hdcMem, addr RemainingTriesText, -1, addr line1Rect,DT_CENTER

    mov eax, currentCakeIndex
draw_cakes:
    push eax
    push ecx
    invoke SelectObject, hdcMem, brushes[eax * 4]
    pop ecx
    pop eax
    mov ebx, SIZEOF RECT
    imul ebx
    push eax
    invoke Rectangle, hdcMem, cakes[eax].left, cakes[eax].top, cakes[eax].right, cakes[eax].bottom
    pop eax
    idiv ebx
    dec eax
    cmp eax, 0
    jge draw_cakes

    invoke SelectObject, hdcMem, hBallBrush
    invoke Ellipse, hdcMem, ball.left, ball.top, ball.right, ball.bottom
    ret
Update3 ENDP

SetBrushes3 PROC
    mov esi, 0
    mov edi, 0
brushesloop:
    mov eax, colors[esi * 4]
    invoke CreateSolidBrush, eax
    mov brushes[edi * 4], eax
    inc esi
    inc edi
    cmp edi, maxCakes
    je end_brushesloop
    cmp esi, colors_count
    jne brushesloop
    mov esi, 0
    jmp brushesloop
end_brushesloop:
    ret
SetBrushes3 ENDP
end
