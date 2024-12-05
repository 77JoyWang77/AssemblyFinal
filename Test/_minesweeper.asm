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

WinMain4 proto :DWORD
check_collision PROTO index:DWORD

.DATA 
ClassName db "SimpleWinClass", 0 
AppName  db "Cake", 0 
ButtonClassName db "button", 0 
cakeX DWORD 200           ; ��l X �y��
cakeY DWORD 80           ; ��l Y �y��
cakeWidth DWORD 50       ; ���x�e��
cakeHeight DWORD 20       ; ���x����
stepSize DWORD 50              ; �C�����ʪ������ƶq
winWidth DWORD 600              ; �����e��
winHeight DWORD 600             ; ��������
velocityX DWORD 5               ; �p�y X ��V�t��
velocityY DWORD 0               ; �p�y Y ��V�t��
border_right DWORD 450
border_left DWORD 150
maxCakes EQU 10                          ; �̤j�J�|�ƶq
currentCakeIndex DWORD 0                   ; ��e�J�|����
cakes RECT maxCakes DUP(<0, 0, 0, 0>)      ; �J�|�}�C�A�x�s�C�ӳJ�|�����
falling BOOL FALSE                         ; �O�_���J�|���b����
gameover BOOL TRUE
fallSpeed DWORD 5                          ; �J�|�����t��

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
Minesweeper PROC 
start: 
    invoke GetModuleHandle, NULL 
    mov    hInstance,eax 
    invoke GetCommandLine
    mov CommandLine,eax
    invoke WinMain4, hInstance
    ret
Minesweeper ENDP

WinMain4 proc hInst:HINSTANCE
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT                   ; �w�q RECT ���c

    ; �w�q���f���O
    mov   wc.cbSize,SIZEOF WNDCLASSEX 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc4
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
    mov wr.right, 600 ;����e
    mov wr.bottom, 600

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
            0, 0, tempWidth, tempHeight, NULL, NULL, hInst, NULL
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
WinMain4 endp


WndProc4 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT 

    .IF uMsg==WM_DESTROY 
        invoke PostQuitMessage,0
    .ELSEIF uMsg==WM_CREATE 
    .ELSEIF uMsg == WM_KEYDOWN
    .ELSEIF uMsg == WM_COMMAND
        mov eax, wParam

    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        

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
WndProc4 endp 


end
