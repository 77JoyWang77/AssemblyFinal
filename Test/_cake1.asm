.386 
.model flat,stdcall 
option casemap:none 

RGB macro red,green,blue
	xor eax,eax
	mov ah,blue
	shl eax,8
	mov ah,green
	mov al,red
endm

include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 

WinMain3 proto :DWORD

.DATA 
ClassName db "SimpleWinClass", 0 
AppName  db "Cake", 0 
ButtonClassName db "button", 0 
cakeX DWORD 100           ; ��l X �y��
cakeY DWORD 50           ; ��l Y �y��
cakeWidth DWORD 50       ; ���x�e��
cakeHeight DWORD 20       ; ���x����
stepSize DWORD 5              ; �C�����ʪ������ƶq
winWidth DWORD 600              ; �����e��
winHeight DWORD 600             ; ��������
velocityX DWORD 5               ; �p�y X ��V�t��
velocityY DWORD 0               ; �p�y Y ��V�t��
border_right DWORD 550
border_left DWORD 50

TriesRemaining  db 9
RemainingTriesText db "Remaining:  ", 0
EndGame db "Game Over!", 0
line1Rect RECT <20, 20, 580, 40>

.DATA? 
hInstance HINSTANCE ? 
CommandLine LPSTR ? 
hBrush DWORD ?
tempWidth DWORD ?
tempHeight DWORD ?

.CODE 
Cake1 PROC 
start: 
    invoke GetModuleHandle, NULL 
    mov    hInstance,eax 
    invoke GetCommandLine
    mov CommandLine,eax
    invoke WinMain3, hInstance
    ret
Cake1 ENDP

WinMain3 proc hInst:HINSTANCE
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT                   ; �w�q RECT ���c

    ; �w�q���f���O
    mov   wc.cbSize,SIZEOF WNDCLASSEX 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc3
    mov   wc.cbClsExtra,NULL 
    mov   wc.cbWndExtra,NULL 
    push  hInst 
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
    mov wr.right, 600
    mov wr.bottom, 600

    ; �վ㵡�f�j�p
    invoke AdjustWindowRect, ADDR wr, WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, FALSE

    ; �p�ⵡ�f�e�שM����
    mov eax, wr.right
    sub eax, wr.left
    mov winWidth, eax

    mov eax, wr.bottom
    sub eax, wr.top
    mov winHeight, eax

    ; �Ыص��f
    invoke CreateWindowEx, NULL, ADDR ClassName, ADDR AppName, \
            WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, \
            0, 0, winWidth, winHeight, \
            NULL, NULL, hInst, NULL
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
WinMain3 endp


WndProc3 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT 

    .IF uMsg==WM_DESTROY 
        invoke PostQuitMessage,NULL 
    .ELSEIF uMsg==WM_CREATE 

    .ELSEIF uMsg == WM_TIMER
        ; ��s�p�y��m
        call update_cake
        invoke InvalidateRect, hWnd, NULL, TRUE

    .ELSEIF uMsg == WM_COMMAND
        mov eax, wParam

    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke GetClientRect, hWnd, addr rect
        RGB    200,200,50
        invoke CreateSolidBrush, eax  ; �Ыج��ⵧ��
        mov hBrush, eax                          ; �s����y�`
        invoke SelectObject, hdc, hBrush

        mov al, [TriesRemaining]       ; �N TriesRemaining ���ȸ��J eax
        add al, '0'                     ; �N�Ʀr�ഫ�� ASCII (����)
        mov byte ptr [RemainingTriesText + 11], al ; �N�r���g�J�r��
        invoke DrawText, hdc, addr RemainingTriesText, -1, addr line1Rect,DT_CENTER

        ; ø�s���x
        mov eax, cakeX
        add eax, cakeWidth
        mov edx, cakeY
        add edx, cakeHeight
        mov [tempWidth], eax
        mov [tempHeight], edx
        invoke Rectangle, hdc, cakeX, cakeY, tempWidth, tempHeight

        invoke EndPaint, hWnd, addr ps
    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 
WndProc3 endp 

update_cake PROC
    ; ��s�p�y��m
    mov eax, cakeX
    add eax, velocityX
    mov cakeX, eax

    mov eax, cakeY
    add eax, velocityY
    mov cakeY, eax

    ; ��ɸI���˴��]�譱�Ϯg�^
    mov eax, cakeX
    cmp eax, border_left           ; �I�쥪���
    jle reverse_x

    add eax, cakeWidth
    cmp border_right, eax                ; �I��k���
    jle reverse_x

    jmp end_update                ; �Y�L�I���A����

reverse_x:
    neg velocityX

end_update:
    ret
update_cake ENDP

end
