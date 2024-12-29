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
tofu RECT <120, 250, 180, 270>, 99 DUP(<0, 0, 0, 0>)  ; ���G

; �����C��
colors DWORD 07165FBh, 0A5B0F4h, 0F0EBC4h, 0B2C61Fh, 0D3F0B8h, 0C3CC94h, 0E9EFA8h, 0D38A92h, 094C9E4h, 0B08DDDh, 0E1BFA2h, 09B97D8h, 09ADFCBh, 0A394D1h, 0BF95DCh, 09CE1D6h, 0E099C1h, 0DCD0A0h, 09B93D9h, 0D3D1B2h
colors_count EQU ($ - colors) / 4

winPosX DWORD 400              ; �ù���m X �y��
winPosY DWORD 0                ; �ù���m Y �y��
gameover BOOL TRUE             ; �C���������A

.DATA?
hInstance HINSTANCE ?          ; �{����ҥy�`
hBitmap HBITMAP ?              ; ��ϥy�`
hBackBitmap HBITMAP ?          ; �I����ϥy�`
hBackBitmap2 HBITMAP ?         ; �ĤG�I����ϥy�`
hdcMem HDC ?                   ; �O����]�ƤW�U��
hdcBack HDC ?                  ; �I���]�ƤW�U��

hBallBrush HBRUSH ?            ; �y����
brushes HBRUSH maxTofu DUP(?)  ; ���G����
tempWidth DWORD ?              ; �Ȧs�e��
tempHeight DWORD ?             ; �Ȧs����

velocityY DWORD ?              ; �y Y ��V�t��
velocityX DWORD ?              ; ���G X ��V�t��
tofuX DWORD ?                  ; ���G X �y��
tofuY DWORD ?                  ; ���G Y �y��
currentTofuIndex DWORD ?       ; ��e���G����
TriesRemaining BYTE ?          ; �Ѿl����
groundMoveCount DWORD ?        ; �a���w���ʶZ��
needMove DWORD ?               ; �a���ݲ��ʶZ��
ground DWORD ?                 ; �a��
way BOOL ?                     ; �������G��m�ATRUE ���k�AFALSE ����
move BOOL ?                    ; �y�O�_���ʤ�

.CODE
WinMain6 proc
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    LOCAL hwnd:HWND
    LOCAL wr:RECT

    invoke GetModuleHandle, NULL
    mov    hInstance,eax

    ; ��l�Ƶ��f��
    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET WndProc6
    mov wc.cbClsExtra, NULL
    mov wc.cbWndExtra, NULL
    push hInstance
    pop wc.hInstance
    mov wc.hbrBackground, COLOR_WINDOW+1
    mov wc.lpszMenuName, NULL
    mov wc.lpszClassName, OFFSET ClassName
    invoke LoadIcon, NULL, IDI_APPLICATION
    mov wc.hIcon, eax
    mov wc.hIconSm, eax
    invoke LoadCursor, NULL, IDC_ARROW
    mov wc.hCursor, eax
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

        ; ��l�ƹC���귽
        call SetBrushes3
        call initializetofu

        ; �[�����
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap, eax
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap2, eax

        ; ��l�Ƶe��
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

        ; �����ť���
        invoke GetAsyncKeyState, VK_UP
        test eax, 8000h ; ���ճ̰���
        jz skip_space_key

        cmp ball.bottom, initialground    ; �p�G�y���b��l��m�A���L�ť���
        jl skip_space_key

        cmp move, TRUE                    ; �p�G�y�b���ʡA���L�ť���
        je skip_space_key
        mov velocityY, initialVelocity    ; �]�m�y��t
        mov move, TRUE                    ; �]�m�y���A

    skip_space_key:
        ; ��s���G���A
        call update_tofu
        mov ebx, SIZEOF RECT
        imul ebx, currentTofuIndex
        mov eax, tofuX
        mov tofu[ebx].left, eax
        add eax, tofuWidth
        mov tofu[ebx].right, eax
        mov eax, tofuY
        mov tofu[ebx].top, eax
        add eax, tofuHeight
        mov tofu[ebx].bottom, eax

        ; ��s�y���A
        call update_ball2
        cmp ball.bottom, initialtofuY      ; �p�G�y�٥��쨧�G�����ݡA���L�ѤU���P�_
        jl move_ground

        ; �T�{�y�P���G���I��
        call check_ball
        cmp gameover, TRUE                 ; �p�G gameover �� TRUE�A�����C��
        je game_over
        cmp eax, TRUE                      ; �p�G�I���A�]�m�U�@�Ө��G
        je next

        ; �T�{���G�O�_�B��i��U��m
        call check_tofu
        cmp eax, FALSE
        je move_ground

    next:
        ; �I������
        invoke mciSendString, addr hitOpenCmd, NULL, 0, NULL
        invoke mciSendString, addr hitVolumeCmd, NULL, 0, NULL
        invoke mciSendString, addr hitPlayCmd, NULL, 0, NULL

        mov move, FALSE                    ; �y�����
        add needMove, tofuHeight           ; �W�[�a�O�ݲ��ʶZ��
        inc currentTofuIndex               ; �U�@�Ө��G
        dec TriesRemaining                 ; ��ֳѾl���G��

        ; ����H�� X ��V�t��
        invoke GetTickCount
        mov ebx, 5
        cdq
        idiv ebx
        add edx, 2
        mov velocityX, edx
        
        ; ����H�����G��s��m
        invoke GetTickCount
        mov ebx, 2
        cdq
        idiv ebx
        cmp edx, 0
        jne from_left

        mov way, TRUE                     ; ��s�b�k��
        mov tofuX, initialtofuX
        neg velocityX
        jmp end_update

    from_left:
        mov way, FALSE                    ; ��s�b����
        mov tofuX, initialtofuX1

    end_update:
        invoke InvalidateRect, hWnd, NULL, FALSE      ; ��s�e��

        cmp TriesRemaining, 0             ; �p�G�Ѿl���Ƭ� 0�A�����C��
        je game_over
        ret

    move_ground:
        ; �T�{�a�O�O�_�ݭn����
        mov ebx, needMove
        cmp ebx, groundMoveCount
        jle skip_fall

        ; �a���M�y����
        add groundMoveCount, tofuMoveSize
        add ground, tofuMoveSize
        add ball.top, tofuMoveSize
        add ball.bottom, tofuMoveSize

        ; ���G����
        mov ecx, currentTofuIndex
        dec ecx
    move_ground_loop:
        mov eax, ecx
        cmp eax, 0
        jl skip_fall
        mov ebx, SIZEOF RECT
        imul ebx
        add tofu[eax].top, tofuMoveSize
        add tofu[eax].bottom, tofuMoveSize
        dec ecx
        jmp move_ground_loop

    skip_fall:
        invoke InvalidateRect, hWnd, NULL, FALSE      ; ��s�e��
        ret

    game_over:
        ; ��ܹC�������T��
        invoke InvalidateRect, hWnd, NULL, FALSE
        invoke KillTimer, hWnd, 1
        invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
        invoke PostMessage, hWnd, WM_DESTROY, 0, 0
        ret

    .ELSEIF uMsg == WM_PAINT

        ; ø�s�e��
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke BitBlt, hdcMem, 0, 0, winWidth, winHeight, hdcBack, 0, 0, SRCCOPY
        call Update3
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps

    .ELSEIF uMsg == WM_DESTROY

        ; �M�z�귽
        mov gameover, TRUE
        invoke DeleteObject, hBitmap
        invoke DeleteObject, hBackBitmap
        invoke DeleteObject, hBackBitmap2
        invoke DeleteDC, hdcMem
        invoke DeleteDC, hdcBack
        invoke ReleaseDC, hWnd, hdc
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, NULL

    .ELSE
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
        ret
    .ENDIF
    xor eax, eax
    ret
WndProc6 endp

; ��l�ƹC��
initializetofu PROC

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
    mov way, TRUE
    mov edi, OFFSET tofu
    mov ecx, maxTofu
    imul ecx, 4
    xor eax, eax
    rep stosd
    mov eax, firsttofu.top
    mov tofu.top, eax
    mov eax, firsttofu.bottom
    mov tofu.bottom, eax
    mov eax, firsttofu.left
    mov tofu.left, eax
    mov eax, firsttofu.right
    mov tofu.right, eax
    mov eax, initialball.top
    mov ball.top, eax
    mov eax, initialball.bottom
    mov ball.bottom, eax
    mov eax, initialball.left
    mov ball.left, eax
    mov eax, initialball.right
    mov ball.right, eax

initializetofu ENDP

; ��s�y���A
update_ball2 PROC

    cmp move, FALSE           ; �y���b���ʡA���L�U�C�ާ@
    je no_collision

    ; ��s�y����m
    mov eax, velocityY
    add ball.top, eax
    mov eax, velocityY
    add ball.bottom, eax
    add velocityY, gravity
    cmp velocityY, 0          ; �y�٦b�W�ɪ��A�A���|�P�a�O�I���A���L�U�C�P�_
    jl no_collision

    mov eax, ball.bottom      ; �y�w�b��l���סA�����
    cmp eax, initialground
    je stop_move

    ; �ˬd�I���a�O
    mov eax, ball.bottom
    cmp eax, initialtofuY
    jl no_collision

    cmp way, TRUE             ; �P�_���G��V
    jne from_left

    mov eax, ball.right       ; ���G�b�k��A�p�G�I��y���k��A�����
    cmp tofuX, eax
    jg no_collision
    jmp stop_move

from_left:
    mov eax, ball.left        ; ���G�b����A�p�G�I��y������A�����
    cmp tofuX, eax
    jl no_collision
    jmp stop_move

stop_move:
    mov velocityY, 0          ; �y�t���k�s
    mov move, FALSE

no_collision:
    ret

update_ball2 ENDP

; ��s���G���A
update_tofu PROC

    cmp velocityX, 0          ; �t�׬� 0�A���L�ާ@
    je end_update

    cmp way, TRUE             ; �P�_���G��V
    jne from_left

    mov eax, tofuX
    cmp eax, border_left      ; ���G�b�k��A�p�G�p����ɡA�����
    jle end_update
    add eax, velocityX        ; ��s���G��m
    mov tofuX, eax
    ret

from_left:
    mov eax, tofuX
    cmp eax, border_left      ; ���G�b����A�p�G�j����ɡA�����
    jge end_update
    add eax, velocityX        ; ��s���G��m
    mov tofuX, eax
    ret

end_update:
    mov velocityX, 0          ; ���G�t���k�s
    ret

update_tofu ENDP

; �P�_���G�O�_�i��U�A�Oreturn eax TRUE
check_tofu PROC

    LOCAL cr:RECT
    LOCAL lr:RECT

    cmp way, TRUE             ; �P�_���G��V
    jne from_left

    cmp tofuX, border_left    ; ���G�b�k��A�p�G���쥪��ɡAreturn FALSE
    jg check_end
    jmp check_last_tofu

from_left:
    cmp tofuX, border_left    ; ���G�b����A�p�G���쥪��ɡAreturn FALSE
    jl check_end

check_last_tofu:              ; �T�{�{�b�����G�w�b�W�Ө��G�W��
    mov eax, currentTofuIndex
    mov ebx, SIZEOF RECT
    imul ebx
    mov ebx, tofu[eax].left
    mov cr.left, ebx
    mov ebx, tofu[eax].right
    mov cr.right, ebx

    mov ebx, tofu[eax - 16].left
    mov lr.left, ebx
    mov ebx, tofu[eax - 16].right
    mov lr.right, ebx

check_left:                   ; �{�b���k������p�󵥩�W�Ӫ������
    mov eax, lr.left
    cmp cr.right, eax
    jl check_end
    
check_right:                  ; �{�b����������j�󵥩�W�Ӫ��k���
    mov eax, lr.right
    cmp cr.left, eax
    mov eax, TRUE
    ret

check_end:
    mov eax, FALSE
    ret

check_tofu ENDP

; �ˬd�O�_�P���G�I���A�Oreturn eax TRUE
check_ball PROC

    Local cr:RECT

    mov eax, currentTofuIndex
    mov ebx, SIZEOF RECT
    imul ebx
    mov ebx, tofu[eax].left
    mov cr.left, ebx
    mov ebx, tofu[eax].right
    mov cr.right, ebx
    
    cmp ball.bottom, initialtofuY   ; ���ˬd�y�����w�b���G����
    jne check_side

    cmp way, TRUE                   ; �P�_���G��V
    jne left_way

    cmp cr.left, 150                ; ���G�b�k��A���G������ܤ֤p��y�������I
    jg ball_not_collision
    jmp valid_collision

left_way:
    cmp cr.right, 150               ; ���G�b����A���G������ܤ֤j��y�������I
    jl ball_not_collision
    jmp valid_collision

check_side:
    mov eax, ball.bottom            ; �ˬd�y�P���G�b�P�@�����A�p�G�I���Agameover �� TRUE
    cmp eax, initialground
    jl ball_not_collision

    cmp way, TRUE                   ; �P�_���G��V
    jne left_way2

    mov eax, ball.right             ; ���G�b�k��A���G����ɦp�p�󵥩�y���k��ɡA�h�I��
    cmp eax, cr.left
    jl ball_not_collision
    mov ebx, cr.left                ; �ץ����G��m�A�קK�X�{���|�e��
    sub eax, ebx
    add cr.left, eax
    add cr.right, eax
    mov gameover, TRUE
    jmp valid_collision

left_way2:
    mov eax, ball.left              ; ���G�b����A���G�k��ɦp�j�󵥩�y���k��ɡA�h�I��
    cmp eax, cr.right
    jg ball_not_collision
    mov ebx, cr.right               ; �ץ����G��m�A�קK�X�{���|�e��
    sub ebx, eax
    sub cr.left, ebx
    sub cr.right, ebx
    mov gameover, TRUE

valid_collision:
    mov ebx, SIZEOF RECT            ; �N�ץ����G��m�A�s�^�}�C
    imul ebx, currentTofuIndex
    mov eax, cr.left
    mov tofu[ebx].left, eax
    mov eax, cr.right
    mov tofu[ebx].right, eax
    mov eax, TRUE
    ret

ball_not_collision:
    mov eax, FALSE
    ret

check_ball ENDP

; ��s�e��
Update3 PROC

    invoke SetBkMode, hdcMem, TRANSPARENT

    ; ��r
    mov bl, 10
    xor ah, ah
    mov al, [TriesRemaining]                       ; �N TriesRemaining ���ȸ��J al
    div bl
    mov byte ptr [RemainingTriesText + 11], ' '    ; ���N�Q��ƪ�l����

    cmp al, 0
    je nextdigit
    add al, '0'                                    ; �N�Ʀr�ഫ�� ASCII (����)
    mov byte ptr [RemainingTriesText + 11], al     ; �g�J�Q���

nextdigit:
    add ah, '0'                                    ; �N�Ʀr�ഫ�� ASCII (����)
    mov byte ptr [RemainingTriesText + 12], ah     ; �g�J�Ӧ��
    invoke DrawText, hdcMem, addr RemainingTriesText, -1, addr line1Rect,DT_CENTER

    ; ���G
    mov eax, currentTofuIndex
draw_tofus:
    push eax
    push ecx
    invoke SelectObject, hdcMem, brushes[eax * 4]  ; ��ܵ���
    pop ecx
    pop eax
    mov ebx, SIZEOF RECT
    imul ebx
    push eax
    invoke Rectangle, hdcMem, tofu[eax].left, tofu[eax].top, tofu[eax].right, tofu[eax].bottom
    pop eax
    idiv ebx
    dec eax
    cmp eax, 0
    jge draw_tofus

    ; �y
    invoke SelectObject, hdcMem, hBallBrush
    invoke Ellipse, hdcMem, ball.left, ball.top, ball.right, ball.bottom
    ret

Update3 ENDP

; �]�w����
SetBrushes3 PROC

    invoke CreateSolidBrush, 00C9A133h
    mov hBallBrush, eax
    
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

; ��^�C�����A
getTofuGame PROC
    mov eax, gameover
    ret
getTofuGame ENDP
end
