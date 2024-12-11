.386 
.model flat,stdcall 
option casemap:none 

include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 

.CONST
cakeWidth EQU 50        ; �J�|�e��
cakeHeight EQU 20       ; �J�|����
stepSize EQU 50         ; �C�����ʪ������ƶq
winWidth EQU 600        ; �����e��
winHeight EQU 600       ; ��������
border_right EQU 450
border_left EQU 150
maxCakes EQU 20         ; �̤j�J�|�ƶq
ground EQU 560
initialcakeX EQU 200    ; ��l X �y��
initialcakeY EQU 80     ; ��l Y �y��
initialvelocityX EQU 5  ; X ��V�t��
dropSpeed EQU 10
time EQU 40             ; ��s�t�סA�v�T�j���t��

.DATA 
ClassName db "SimpleWinClass", 0 
AppName  db "Cake", 0 
RemainingTriesText db "Remaining:   ", 0
EndGame db "Game Over!", 0

cakeX DWORD 200                       ; ��l X �y��
cakeY DWORD 80                        ; ��l Y �y��
velocityX DWORD 5                     ; X ��V�t��
velocityY DWORD 0                     ; Y ��V�t��
currentCakeIndex DWORD 0              ; ��e�J�|����
cakes RECT maxCakes DUP(<0, 0, 0, 0>) ; �x�s�J�|���
falling BOOL FALSE                    ; �O�_���J�|���b����
gameover BOOL FALSE
TriesRemaining BYTE 20                ; �Ѿl����
line1Rect RECT <20, 20, 580, 40>

.DATA? 
hInstance HINSTANCE ? 
tempWidth DWORD ?
tempHeight DWORD ?
hBitmap HBITMAP ?
hdcMem HDC ?
hBrush HBRUSH ?
blueBrush HBRUSH ?

.CODE 
WinMain3 proc
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT

    invoke GetModuleHandle, NULL 
    mov    hInstance,eax

    ; ��l�Ƶ��f��
    mov   wc.cbSize,SIZEOF WNDCLASSEX 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc3
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
            0, 0, tempWidth, tempHeight, NULL, NULL, hInstance, NULL
    mov   hwnd,eax 
    invoke SetTimer, hwnd, 1, time, NULL
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
WinMain3 endp

WndProc3 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT 

    .IF uMsg==WM_DESTROY 
        invoke KillTimer, hWnd, 1
        invoke DeleteObject, hBrush
        invoke DeleteObject, hBitmap
        invoke DeleteDC, hdcMem
        invoke ReleaseDC, hWnd, hdc
        invoke PostQuitMessage,0
    .ELSEIF uMsg==WM_CREATE 
        INVOKE  GetDC,hWnd              
        mov     hdc,eax
        invoke CreateCompatibleDC, hdc
        mov hdcMem, eax
        invoke CreateCompatibleBitmap, hdc, winWidth, winHeight
        mov hBitmap, eax
        invoke SelectObject, hdcMem, hBitmap

        ; ��R�I���C��
        invoke GetClientRect, hWnd, addr rect
        invoke CreateSolidBrush, 00FFFFFFh
        mov hBrush, eax
        invoke FillRect, hdcMem, addr rect, hBrush
        invoke ReleaseDC, hWnd, hdc
    .ELSEIF uMsg == WM_TIMER
        invoke GetAsyncKeyState, VK_SPACE
        test eax, 8000h ; ���ճ̰���
        jz skip_space_key

        ; �p�G�ثe�S�����b�������J�|�A�Ұʱ����޿�
        cmp falling, TRUE
        je skip_space_key
        mov falling, TRUE

        ; ��l�Ʒs�J�|��m
        mov velocityX, 0
        mov velocityY, dropSpeed

    skip_space_key:
        call update_cake
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
        je skip_fall
        call check_collision
        cmp eax, TRUE
        je skip_fall

    handle_collision:
        mov falling, FALSE
        inc currentCakeIndex  ; �U�@�ӳJ�|
        dec TriesRemaining
        mov cakeX, initialcakeX
        mov cakeY, initialcakeY
        mov velocityX, initialvelocityX
        mov velocityY, 0
        cmp gameover, TRUE
        je game_over
        cmp TriesRemaining, 0
        je game_over

    skip_fall:
        invoke GetClientRect, hWnd, addr rect
        invoke FillRect, hdcMem, addr rect, hBrush
        call Update
        invoke InvalidateRect, hWnd, NULL, FALSE
        ret
    game_over:
        ; ��ܹC�������T��
        invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
        invoke KillTimer, hWnd, 1
        invoke DeleteObject, hBrush
        invoke DeleteObject, hBitmap
        invoke DeleteDC, hdcMem
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, 0
        ret
    
    .ELSEIF uMsg == WM_COMMAND
        mov eax, wParam

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
WndProc3 endp 

; ��s�J�|��m
update_cake PROC
    cmp velocityX, 0
    je movedown
    mov eax, cakeX
    add eax, velocityX
    mov cakeX, eax

    ; ��ɸI���˴��]�譱�Ϯg�^
    mov eax, cakeX
    cmp eax, border_left           ; �I�쥪���
    jle reverse_x

    add eax, cakeWidth
    cmp eax, border_right          ; �I��k���
    jge reverse_x

movedown:
    mov eax, cakeY
    add eax, velocityY
    mov cakeY, eax
    jmp end_update                 ; �Y�L�I���A����

reverse_x:
    neg velocityX

end_update:
    ret
update_cake ENDP

; �P�_�O�_����U���A�Oreturn eax TRUE
check_collision PROC
    LOCAL cr:RECT

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

    ; �ˬd�O�_�I��a��
    mov ebx, cr.bottom
    cmp ebx, ground
    jge collision_found

    cmp currentCakeIndex, 0
    je check_end
check_other:
    ; �ˬd�O�_�I���L�J�|
    mov ecx, currentCakeIndex
    dec ecx
check_loop:
    cmp ecx, 0
    jl check_end

    ; �������ɩM�k��ɬO�_���|
    mov ebx, SIZEOF RECT
    imul ebx, ecx
check_left:
    mov eax, cakes[ebx].left
    cmp cr.right, eax
    jle next_check
    
check_right:
    mov eax, cakes[ebx].right
    cmp cr.left, eax
    jge next_check

check_bottom:
    mov eax, cakes[ebx].top
    cmp cr.bottom, eax
    jge game_not_over

next_check:
    dec ecx
    jmp check_loop

check_end:
    mov eax, TRUE
    ret

collision_found:
    cmp currentCakeIndex, 0
    je game_not_over
    mov gameover, TRUE
game_not_over:
    mov eax, FALSE
    ret
check_collision ENDP

; ��s�e��
Update PROC
    invoke CreateSolidBrush, 00c8c832h
    mov blueBrush, eax
    invoke SelectObject, hdcMem, blueBrush

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
Update ENDP


end WinMain3