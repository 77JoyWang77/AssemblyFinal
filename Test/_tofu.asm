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
border_left EQU 120       ; ���G�U�������
border_right EQU 180      ; ���G�U���S���
updateInterval EQU 30     ; �p�ɾ���s���j (ms)
initialVelocity EQU -20   ; �y��l�t�� (�t�ȦV�W)
gravity EQU 2             ; �������O�[�t��
initialground EQU 250     ; ��l�a�O
tofuWidth EQU 60          ; ���G�e��
tofuHeight EQU 20         ; ���G����
initialtofuX EQU 240      ; ���G��l X �y�� 1
initialvelocityX EQU -3   ; ���G��l X ��V�t�� 1
initialtofuX1 EQU 0       ; ���G��l X �y�� 2
initialvelocityX1 EQU 3   ; ���G��l X ��V�t�� 2
initialtofuY EQU 230      ; ���G��l Y �y��
maxTofu EQU 100           ; �̦h���G��
tofuMoveSize EQU 5        ; �U������

.DATA
ClassName db "SimpleWinClass8", 0
AppName db "Tofu", 0
RemainingTriesText db "Remaining:   ", 0
EndGame db "Game Over", 0

; ����/�I��
hBackBitmapName db "bmp/tofu_background.bmp",0
hitOpenCmd db "open wav/hit.wav type mpegvideo alias hitMusic", 0
hitVolumeCmd db "setaudio hitMusic volume to 100", 0
hitPlayCmd db "play hitMusic from 0", 0

; �����m
line1Rect RECT <30, 30, 280, 50>                       ; ��r
initialball RECT <140, 230, 160, 250>                  ; �y��l
ball RECT <140, 230, 160, 250>                         ; �y
firsttofu RECT <120, 250, 180, 270>                    ; ���G��l
tofus RECT <120, 250, 180, 270>, 99 DUP(<0, 0, 0, 0>)  ; ���G

; �����C��
colors DWORD 07165FBh, 0A5B0F4h, 0F0EBC4h, 0B2C61Fh, 0D3F0B8h, 0C3CC94h, 0E9EFA8h, 0D38A92h, 094C9E4h, 0B08DDDh, 0E1BFA2h, 09B97D8h, 09ADFCBh, 0A394D1h, 0BF95DCh, 09CE1D6h, 0E099C1h, 0DCD0A0h, 09B93D9h, 0D3D1B2h
colors_count EQU ($ - colors) / 4

winPosX DWORD 400              ; �ù���m X �y��
winPosY DWORD 0                ; �ù���m Y �y��
gameover BOOL FALSE            ; �C���������A

.DATA?
hInstance HINSTANCE ?          ; �{����ҥy�`
hBitmap HBITMAP ?              ; ��ϥy�`
hBackBitmap HBITMAP ?          ; �I����ϥy�`
hBackBitmap2 HBITMAP ?         ; �ĤG�I����ϥy�`
hdcMem HDC ?                   ; �O����]�ƤW�U��
hdcBack HDC ?                  ; �I���]�ƤW�U��

hBallBrush HBRUSH ?            ; �y����
brushes HBRUSH maxTofu DUP(?)  ; ���G����
tempWidth DWORD ?
tempHeight DWORD ?

velocityY DWORD ?              ; �y Y ��V�t��
velocityX DWORD ?              ; ���G X ��V�t��
tofuX DWORD ?                  ; ���G X �y��
tofuY DWORD ?                  ; ���G Y �y��
currentTofuIndex DWORD ?       ; ��e���G����
TriesRemaining BYTE ?          ; �Ѿl����
groundMoveCount DWORD ?        ; �a���w���ʶZ��
needMove DWORD ?               ; �a���ݲ��ʶZ��
ground DWORD ?                 ; �a��
canDrop BOOL ?                 ; ���G�i��U
valid BOOL ?                   ;
way BOOL ?                     ;
move BOOL ?                    ;

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
           winPosX, winPosY, tempWidth, tempHeight, NULL, NULL, hInstance, NULL
    mov hwnd,eax
    invoke SetTimer, hwnd, 1, updateInterval, NULL
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
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT

    .IF uMsg == WM_CREATE
        call SetBrushes3
        call initializetofu3

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
    .ELSEIF uMsg == WM_TIMER
        invoke GetAsyncKeyState, VK_UP
        test eax, 8000h ; ���ճ̰���
        jz skip_space_key

        cmp ball.bottom, initialground
        jl skip_space_key

        cmp move, TRUE
        je skip_space_key
        mov velocityY, initialVelocity
        mov move, TRUE

    skip_space_key:
        call update_tofu3
        mov ebx, SIZEOF RECT
        imul ebx, currentTofuIndex
        mov eax, tofuX
        mov tofus[ebx].left, eax
        add eax, tofuWidth
        mov tofus[ebx].right, eax
        mov eax, tofuY
        mov tofus[ebx].top, eax
        add eax, tofuHeight
        mov tofus[ebx].bottom, eax

    start_move:
        cmp move, FALSE
        je skip_move
        call Update_move

    skip_move:
        cmp ball.bottom, initialtofuY
        jl move_ground

        call check_ball
        cmp gameover, TRUE
        je game_over
        cmp valid, TRUE
        je next

        cmp way, TRUE
        jne from_left
        cmp tofuX, border_left
        jg move_ground
        jmp next1

    from_left:
        cmp tofuX, border_left
        jl move_ground
    next1:
        call check_collision3
        cmp canDrop, FALSE
        je move_ground

    next:
        invoke mciSendString, addr hitOpenCmd, NULL, 0, NULL
        invoke mciSendString, addr hitVolumeCmd, NULL, 0, NULL
        invoke mciSendString, addr hitPlayCmd, NULL, 0, NULL
        mov move, FALSE
        mov valid,FALSE
        mov eax, tofuHeight
        add needMove, eax
        
        inc currentTofuIndex  ; �U�@�Ө��G
        invoke GetTickCount
        mov ebx, 2
        cdq
        idiv ebx
        cmp edx, 0
        jne Next
        mov way, TRUE
        mov tofuX, initialtofuX
        invoke GetTickCount
        mov ebx, 5
        cdq
        idiv ebx
        add edx, 2
        neg edx
        mov velocityX, edx
        jmp Next1
    Next:
        mov way, FALSE
        mov tofuX, initialtofuX1
        invoke GetTickCount
        mov ebx, 5
        cdq
        idiv ebx
        add edx, 2
        mov velocityX, edx
    Next1:
        mov tofuY, initialtofuY
        dec TriesRemaining
        invoke InvalidateRect, hWnd, NULL, FALSE

        cmp gameover, TRUE
        je game_over
        cmp TriesRemaining, 0
        je game_over
        ret

    move_ground:
        mov ebx, needMove
        cmp ebx, groundMoveCount
        jle skip_fall

        ; �a���M���G�~�򲾰�
        add groundMoveCount, tofuMoveSize
        add ground, tofuMoveSize
        add ball.top, tofuMoveSize
        add ball.bottom, tofuMoveSize

        mov ecx, currentTofuIndex
        dec ecx
    move_ground_loop:
        mov eax, ecx
        cmp eax, 0
        jl skip_fall
        mov ebx, SIZEOF RECT
        imul ebx
        add tofus[eax].top, tofuMoveSize
        add tofus[eax].bottom, tofuMoveSize
        dec ecx
        jmp move_ground_loop

    skip_fall:
        invoke InvalidateRect, hWnd, NULL, FALSE
        ret
    game_over:
        ; ��ܹC�������T��
        invoke InvalidateRect, hWnd, NULL, FALSE
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
        mov gameover, 1
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

initializetofu3 PROC
    mov tofuX, initialtofuX
    mov tofuY, initialtofuY
    mov ground, initialground
    mov velocityX, initialvelocityX
    mov TriesRemaining, maxTofu
    dec TriesRemaining
    mov groundMoveCount, 0
    mov needMove, 0
    mov currentTofuIndex, 1
    mov velocityY, 0
    mov move, FALSE
    mov gameover, FALSE
    mov valid, FALSE
    mov way, TRUE
    mov edi, OFFSET tofus
    mov ecx, maxTofu
    imul ecx, 4
    xor eax, eax
    rep stosd
    mov eax, firsttofu.top
    mov tofus.top, eax
    mov eax, firsttofu.bottom
    mov tofus.bottom, eax
    mov eax, firsttofu.left
    mov tofus.left, eax
    mov eax, firsttofu.right
    mov tofus.right, eax
    mov eax, initialball.top
    mov ball.top, eax
    mov eax, initialball.bottom
    mov ball.bottom, eax
    mov eax, initialball.left
    mov ball.left, eax
    mov eax, initialball.right
    mov ball.right, eax
initializetofu3 ENDP

Update_move PROC
    ; ��s�y����m
    mov eax, velocityY
    add ball.top, eax
    mov eax, velocityY
    add ball.bottom, eax
    add velocityY, gravity
    cmp velocityY, 0
    jl no_collision

    mov eax, ball.bottom
    cmp eax, initialground
    je stop_move

    ; �ˬd�I���a�O
    mov eax, ball.bottom
    cmp eax, initialtofuY
    jl no_collision

    cmp way, TRUE
    jne check_way
    mov eax, ball.right
    cmp tofuX, eax
    jg no_collision
    jmp stop_move
check_way:
    mov eax, ball.left
    cmp tofuX, eax
    jl no_collision
    jmp stop_move
stop_move:
    ; ����B�ʨéT�w�y��m
    mov velocityY, 0  ; ����B��
    mov move, FALSE

no_collision:
    ret
Update_move ENDP

; ��s���G��m
update_tofu3 PROC
    cmp velocityX, 0
    je end_update
    cmp way, TRUE
    jne left
    mov eax, tofuX
    cmp eax, border_left
    jle end_update
    add eax, velocityX
    mov tofuX, eax
    ret
left:
    mov eax, tofuX
    cmp eax, border_left
    jge end_update
    add eax, velocityX
    mov tofuX, eax
    ret
end_update:
    mov velocityX, 0
    ret
update_tofu3 ENDP

; �P�_���G�O�_�i��U�A�Oreturn eax TRUE
check_collision3 PROC
    LOCAL cr:RECT
    LOCAL lr:RECT

    mov eax, currentTofuIndex
    mov ebx, SIZEOF RECT
    imul ebx
    mov ebx, tofus[eax].left
    mov cr.left, ebx
    mov ebx, tofus[eax].right
    mov cr.right, ebx

    mov ebx, tofus[eax - 16].left
    mov lr.left, ebx
    mov ebx, tofus[eax - 16].right
    mov lr.right, ebx

check_left:
    mov eax, lr.left
    cmp cr.right, eax
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

    mov eax, currentTofuIndex
    mov ebx, SIZEOF RECT
    imul ebx
    mov ebx, tofus[eax].bottom
    mov cr.bottom, ebx
    mov ebx, tofus[eax].top
    mov cr.top, ebx
    mov ebx, tofus[eax].left
    mov cr.left, ebx
    mov ebx, tofus[eax].right
    mov cr.right, ebx
    
    cmp ball.bottom, initialtofuY
    jne check_side

    cmp way, TRUE
    jne left_way

    cmp cr.left, 150
    jg ball_not_collision
    jmp valid_collision

left_way:
    cmp cr.right, 150
    jl ball_not_collision
    jmp valid_collision

check_side:
    mov eax, ball.bottom
    cmp eax, initialground
    jl ball_not_collision

    cmp way, TRUE
    jne left_way2

    ; �ˬd�y�O�_�P���G�ۼ�
    mov eax, ball.right
    cmp eax, cr.left
    jl ball_not_collision
    mov ebx, cr.left
    sub eax, ebx
    add cr.left, eax
    add cr.right, eax
    mov gameover, TRUE
    jmp valid_collision

left_way2:
    mov eax, ball.left
    cmp eax, cr.right
    jg ball_not_collision
    mov ebx, cr.right
    sub ebx, eax
    sub cr.left, ebx
    sub cr.right, ebx
    mov gameover, TRUE

valid_collision:
    mov ebx, SIZEOF RECT
    imul ebx, currentTofuIndex
    mov eax, cr.left
    mov tofus[ebx].left, eax
    mov eax, cr.right
    mov tofus[ebx].right, eax
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

    mov eax, currentTofuIndex
draw_tofus:
    push eax
    push ecx
    invoke SelectObject, hdcMem, brushes[eax * 4]
    pop ecx
    pop eax
    mov ebx, SIZEOF RECT
    imul ebx
    push eax
    invoke Rectangle, hdcMem, tofus[eax].left, tofus[eax].top, tofus[eax].right, tofus[eax].bottom
    pop eax
    idiv ebx
    dec eax
    cmp eax, 0
    jge draw_tofus

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
    cmp edi, maxTofu
    je end_brushesloop
    cmp esi, colors_count
    jne brushesloop
    mov esi, 0
    jmp brushesloop
end_brushesloop:
    ret
SetBrushes3 ENDP

getTofuGame PROC
    mov eax, gameover
    ret
getTofuGame ENDP
end
