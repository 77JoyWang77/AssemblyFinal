.386 
.model flat,stdcall 
option casemap:none 

include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 
include winmm.inc

EXTERN getOtherGame@0: PROC
backBreakOut EQU getOtherGame@0

.CONST
winWidth EQU 300          ; �����e��
winHeight EQU 350         ; ��������
cakeHeight EQU 20         ; �J�|����
border_left EQU 30        ; �J�|�ϼu�����
border_right EQU 270      ; �J�|�ϼu�k���
initialcakeX EQU 50       ; ��l X �y�� 1
initialcakeY EQU 80       ; ��l Y �y��
initialvelocityX EQU 5    ; ��l X ��V�t�� 1
initialvelocityX1 EQU -5  ; ��l X ��V�t�� 2
initialcakeWidth EQU 100  ; �J�|��l�e��
initialground EQU 300     ; ��l�a�O
dropSpeed EQU 10          ; �J�|�����t��
updateInterval EQU 30     ; �p�ɾ���s���j (ms)
cakeMoveSize EQU 5        ; �U������
heighest EQU 280          ; �J�|�̰�����

.DATA 
ClassName db "SimpleWinClass4", 0 
AppName  db "Cake", 0 
RemainingTriesText db "Remaining:   ", 0
EndGame db "Game Over!", 0

; ����/�I��
hBackBitmapName db "bmp/cake2_background.bmp",0
hitOpenCmd db "open wav/hit.wav type mpegvideo alias hitMusic", 0
hitVolumeCmd db "setaudio hitMusic volume to 100", 0
hitPlayCmd db "play hitMusic from 0", 0

; �����m
cakes RECT 99 DUP(<0, 0, 0, 0>)        ; �J�|
line1Rect RECT <20, 20, 280, 40>       ; ��r

; �����C��
colors DWORD 07165FBh, 0A5B0F4h, 0F0EBC4h, 0B2C61Fh, 0D3F0B8h, 0C3CC94h, 0E9EFA8h, 0D38A92h, 094C9E4h, 0B08DDDh, 0E1BFA2h, 09B97D8h, 09ADFCBh, 0A394D1h, 0BF95DCh, 09CE1D6h, 0E099C1h, 0DCD0A0h, 09B93D9h, 0D3D1B2h
colors_count EQU ($ - colors) / 4

winPosX DWORD 400              ; �ù���m X �y��
winPosY DWORD 0                ; �ù���m Y �y��
gameover BOOL TRUE             ; �C���������A
fromBreakout BOOL FALSE        ; �q Breakout �}�ҹC��

.DATA? 
hInstance HINSTANCE ?          ; �{����ҥy�`
hBitmap HBITMAP ?              ; ��ϥy�`
hBackBitmap HBITMAP ?          ; �I����ϥy�`
hBackBitmap2 HBITMAP ?         ; �ĤG�I����ϥy�`
hdcMem HDC ?                   ; �O����]�ƤW�U��
hdcBack HDC ?                  ; �I���]�ƤW�U��

brushes HBRUSH 99 DUP(?)       ; �J�|����
tempWidth DWORD ?              ; �Ȧs�e��
tempHeight DWORD ?             ; �Ȧs����

maxCakes DWORD ?               ; �̤j�J�|�ƶq
cakeWidth DWORD ?              ; �J�|�e��
cakeX DWORD ?                  ; �J�| X �y��
cakeY DWORD ?                  ; �J�| Y �y��
velocityX DWORD ?              ; �J�| X ��V�t��
velocityY DWORD ?              ; �J�| Y ��V�t��
currentCakeIndex DWORD ?       ; ��e���G����
TriesRemaining BYTE ?          ; �Ѿl����
groundMoveCount DWORD ?        ; �a���w���ʶZ��
needMove DWORD ?               ; �a���ݲ��ʶZ��
ground DWORD ?                 ; �a��
falling BOOL ?                 ; �O�_���J�|���b����
moveDown BOOL ?                ; �O�_�ݭn�U���a�O

.CODE 
; �Ыص���
WinMain4 proc

    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT

    invoke GetModuleHandle, NULL 
    mov    hInstance,eax

    ; ��l�Ƶ��f��
    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET WndProc4
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
    mov   hwnd,eax 
    invoke SetTimer, hwnd, 1, updateInterval, NULL
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

WinMain4 endp

; �����B��
WndProc4 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 

    .IF uMsg == WM_CREATE 

        ; ��l�ƹC���귽
        call initializeCake2
        call SetBrushes2

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
        invoke GetAsyncKeyState, VK_SPACE
        test eax, 8000h
        jz skip_space_key

        cmp falling, TRUE             ; �p�G�ثe�S�����b�������J�|�A�Ұʱ����޿�
        je skip_space_key

        mov falling, TRUE
        mov velocityX, 0
        mov velocityY, dropSpeed

    skip_space_key:
        ; ��s�J�|���A
        call update_cake2
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
        
        ; �ˬd�O�_�P��L�J�|�Φa����Ĳ
        cmp falling, FALSE
        je move_ground
        call check_collision2
        cmp eax, TRUE
        je move_ground

    handle_collision:
        ; �I������
        invoke mciSendString, addr hitOpenCmd, NULL, 0, NULL
        invoke mciSendString, addr hitVolumeCmd, NULL, 0, NULL
        invoke mciSendString, addr hitPlayCmd, NULL, 0, NULL

        mov ebx, SIZEOF RECT
        imul ebx, currentCakeIndex
        mov eax, cakes[ebx].left
        mov ecx, cakes[ebx].right
        sub ecx, eax
        mov cakeWidth, ecx                 ; ��s�J�|�e��
        mov falling, FALSE                 ; ����U
        dec TriesRemaining                 ; ��ֳѾl�J�|��
        mov cakeY, initialcakeY            ; ��l�ƳJ�| Y �y��
        mov velocityY, 0                   ; ��l�ƳJ�| Y ��V�t��

        invoke GetTickCount                ; �ͦ��H����
        mov ebx, 2
        cdq
        idiv ebx
        cmp edx, 0
        jne from_right

        mov cakeX, initialcakeX            ; ��l�ƳJ�| X �y�С]���^
        mov velocityX, initialvelocityX    ; ��l�ƳJ�| X ��V�t��
        jmp end_update

    from_right:
        mov eax, border_right              ; �q�k��
        sub eax, 20
        sub eax, cakeWidth
        mov cakeX, eax                     ; ��l�ƳJ�| X �y�С]�k�^
        mov velocityX, initialvelocityX1   ; ��l�ƳJ�| X ��V�t��

    end_update:
        cmp moveDown, FALSE                ; �P�_�O�_�ݲ��ʦa�O
        je skip_move_ground

        mov eax, cakeHeight
        add needMove, eax

    skip_move_ground:
        invoke InvalidateRect, hWnd, NULL, FALSE      ; ��s�e��
        inc currentCakeIndex                          ; �U�@�ӳJ�|

        cmp gameover, TRUE
        je game_over

        cmp TriesRemaining, 0             ; �p�G�Ѿl���Ƭ� 0�A�����C��
        je game_over
        ret

    move_ground:
        ; �T�{�a�O�O�_�ݭn����
        mov ebx, needMove
        cmp ebx, groundMoveCount
        jle skip_fall

        ; �a������
        add groundMoveCount, cakeMoveSize
        add ground, cakeMoveSize

        ; �J�|����
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
        invoke InvalidateRect, hWnd, NULL, FALSE      ; ��s�e��
        ret

    game_over:
        ; ��ܹC�������T��
        invoke KillTimer, hWnd, 1
        cmp fromBreakout, TRUE
        je skipMsg
        invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
    skipMsg:
        invoke PostMessage, hWnd, WM_DESTROY, 0, 0
        ret

    .ELSEIF uMsg == WM_PAINT
        
        ; ø�s�e��
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke BitBlt, hdcMem, 0, 0, winWidth, winHeight, hdcBack, 0, 0, SRCCOPY
        call Update2
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps

    .ELSEIF uMsg == WM_DESTROY 

        cmp fromBreakout, FALSE
        je getDestory

        ; ��^���G
        cmp TriesRemaining, 0
        jne notWin
        cmp gameover, FALSE
        jne notWin
        mov eax, 3
        call backBreakOut
        jmp getDestory
    notWin:
        mov eax, -3
        call backBreakOut

        ; �M�z�귽
    getDestory:
        mov winPosX, 400
        mov winPosY, 0
        mov fromBreakout, FALSE
        mov gameover, TRUE
        invoke KillTimer, hWnd, 1
        invoke DeleteObject, hBitmap
        invoke DeleteObject, hBackBitmap
        invoke DeleteObject, hBackBitmap2
        invoke DeleteDC, hdcMem
        invoke DeleteDC, hdcBack
        invoke ReleaseDC, hWnd, hdc
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, NULL
    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 
WndProc4 endp 

; ��l�ƹC��
initializeCake2 PROC

    cmp fromBreakout, TRUE
    je skipMaxcakes
    mov maxCakes, 99
skipMaxcakes:
    mov cakeX, initialcakeX
    mov cakeY, initialcakeY
    mov velocityX, initialvelocityX
    mov velocityY, 0
    mov ground, initialground
    mov cakeWidth, initialcakeWidth
    mov currentCakeIndex, 0
    mov eax, maxCakes
    mov TriesRemaining, al
    mov groundMoveCount, 0
    mov needMove, 0
    mov gameover, FALSE
    mov falling, FALSE
    mov moveDown, FALSE
    mov edi, OFFSET cakes
    mov ecx, maxCakes
    imul ecx, 4
    xor eax, eax
    rep stosd

initializeCake2 ENDP

; ��s�J�|��m
update_cake2 PROC

    cmp velocityX, 0               ; �L X ��V�t�סA���L�U�C�ާ@
    je movedown

    mov eax, cakeX                 ; ��s�J�| X �y��
    add eax, velocityX
    mov cakeX, eax

    mov eax, cakeX
    cmp eax, border_left           ; �J�|�I�쥪���
    jle reverse_x

    add eax, cakeWidth
    cmp eax, border_right          ; �J�|�I��k���
    jge reverse_x

movedown:
    mov eax, cakeY                 ; ��s�J�| Y �y��
    add eax, velocityY
    mov cakeY, eax
    jmp end_update

reverse_x:
    neg velocityX                  ; ���� X ��V�t��

end_update:
    ret

update_cake2 ENDP

; �P�_�O�_����U���A�Oreturn eax TRUE
check_collision2 PROC

    LOCAL cr:RECT

    mov eax, currentCakeIndex
    mov ebx, SIZEOF RECT
    imul ebx
    mov ebx, cakes[eax].bottom
    mov cr.bottom, ebx
    mov ebx, cakes[eax].left
    mov cr.left, ebx
    mov ebx, cakes[eax].right
    mov cr.right, ebx

    mov ebx, cr.bottom              ; �ˬd�O�_�I��a��
    cmp ebx, ground
    jge collision_found

    cmp ebx, winHeight              ; �ˬd�O�_�I��ù�����
    jge collision_found

    cmp currentCakeIndex, 0         ; �p�G�٥����J�|�A���L�H�U�ާ@
    je check_end

check_other:
    mov ecx, currentCakeIndex       ; �ˬd�O�_�I���L�J�|
    dec ecx

check_loop:
    cmp ecx, 0
    jl check_end

    mov ebx, SIZEOF RECT
    imul ebx, ecx

    mov eax, cakes[ebx].left        ; �{�b���k������j�󵥩󤧫e�������
    cmp cr.right, eax
    jle next_check
    
    mov eax, cakes[ebx].right       ; �{�b����������p�󵥩󤧫e���k���
    cmp cr.left, eax
    jge next_check

    mov eax, cakes[ebx].top         ; �p�{�b�������b���e�������A�o�͸I��
    cmp cr.bottom, eax
    jge collision_found

next_check:
    dec ecx
    jmp check_loop

check_end:
    mov eax, TRUE                   ; �~�򸨤U
    ret

collision_found:
    cmp currentCakeIndex, 0         ; �p�G�����ӳJ�|�A���Τ���
    je dont_cut
  
    cmp cr.bottom, heighest         ; �p�G�S�����b�̤W�����J�|�A�C������
    je game_not_over

    mov gameover, TRUE
    mov moveDown, FALSE
    jmp dont_cut

game_not_over:
    mov moveDown, TRUE              ; ���b�̤W�����J�|
    mov eax, currentCakeIndex
    mov ebx, SIZEOF RECT
    imul ebx, eax
    mov eax, cakes[ebx - 16].left   ; �p�G����W�X�W�@�ӳJ�|�A�����̷s���J�|
    cmp cr.left, eax
    jge check_right_cut
    mov cakes[ebx].left, eax

check_right_cut:
    mov eax, cakes[ebx - 16].right  ; �p�G����W�X�W�@�ӳJ�|�A�����̷s���J�|
    cmp cr.right, eax
    jle dont_cut
    mov cakes[ebx].right, eax

dont_cut:
    mov eax, FALSE                  ; ����U
    ret

check_collision2 ENDP

; ��s�e��
Update2 PROC

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
    invoke DrawText, hdcMem, addr RemainingTriesText, -1, addr line1Rect, DT_CENTER

    ; �J�|
    mov eax, currentCakeIndex
    draw_cakes:
    push eax
    push ecx
    invoke SelectObject, hdcMem, brushes[eax * 4]  ; ��ܵ���
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
    ret

Update2 ENDP

; �]�w����
SetBrushes2 PROC

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

SetBrushes2 ENDP

; ��^�C�����A
getCake2Game PROC
    mov eax, gameover
    ret
getCake2Game ENDP

; �]�m�C���ӷ�
Cake2fromBreakOut PROC
    mov winPosX, 1570
    mov winPosY, 0
    mov maxCakes, 10
    mov fromBreakout, 1
    ret
Cake2fromBreakOut ENDP
end