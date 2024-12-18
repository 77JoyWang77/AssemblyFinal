.386
.model flat,stdcall
option casemap:none

include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc

.CONST
winWidth EQU 300        ; �����e��
winHeight EQU 400       ; ��������
ballSize EQU 20         ; �y���j�p
updateInterval EQU 30   ; �p�ɾ���s���j (ms)
initialVelocity EQU -20 ; ��l�t�� (�t�ȦV�W)
gravity EQU 2           ; �������O�[�t��
floor EQU 350           ; �a�O����

.DATA
ClassName db "BallMotionClass", 0
AppName  db "Ball Motion", 0
EndGame  db "Game Over", 0

ball RECT <140, 330, 160, 350> ; �y����l��m
velocityY DWORD ?              ; �y�������t��
move BYTE ?

.DATA?
hInstance HINSTANCE ?
hdcMem HDC ?
hBitmap HBITMAP ?
hBrush HBRUSH ?
hBallBrush HBRUSH ?
hdc HDC ?

.CODE
WinMain6 proc
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    LOCAL hwnd:HWND

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

    ; �Ыص��f
    invoke CreateWindowEx, NULL, ADDR ClassName, ADDR AppName, \
           WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, \
           CW_USEDEFAULT, CW_USEDEFAULT, winWidth, winHeight, \
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
    LOCAL rect:RECT

    .IF uMsg == WM_CREATE
        ; ��l�Ƹ귽
        invoke GetDC, hWnd
        mov hdc, eax

        invoke CreateCompatibleDC, hdc
        mov hdcMem, eax

        invoke CreateCompatibleBitmap, hdc, winWidth, winHeight
        mov hBitmap, eax
        invoke SelectObject, hdcMem, hBitmap

        ; �I���P�y������
        invoke CreateSolidBrush, 00FFFFFFh
        mov hBrush, eax

        invoke CreateSolidBrush, 0000FF00h
        mov hBallBrush, eax

        ; ��l�Ʋy�B��
        mov velocityY, 0
        mov move, FALSE
        invoke SetTimer, hWnd, 1, updateInterval, NULL

    .ELSEIF uMsg == WM_TIMER
        ; �������O
        cmp move, TRUE
        jne no_collision
        add velocityY, gravity

        ; ��s�y����m
        mov eax, ball.top
        add eax, velocityY
        mov ball.top, eax
        mov eax, ball.bottom
        add eax, velocityY
        mov ball.bottom, eax

        ; �ˬd�I���a�O
        mov eax, ball.bottom
        cmp eax, floor
        jl no_collision

        ; ����B�ʨéT�w�y��m
        mov velocityY, 0  ; ����B��
        mov move, FALSE

    no_collision:
        ; ��ø���f
        invoke InvalidateRect, hWnd, NULL, FALSE

    .ELSEIF uMsg == WM_KEYDOWN
        cmp wParam, VK_SPACE
        jne skip_space

        ; �p�G���U�ť���A��l�ƦV�W�B��
        mov velocityY, initialVelocity
        mov move, TRUE

    skip_space:

    .ELSEIF uMsg == WM_PAINT
        ; ø�s�I���P�y
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax

        invoke GetClientRect, hWnd, addr rect
        invoke FillRect, hdcMem, addr rect, hBrush

        invoke SelectObject, hdcMem, hBallBrush
        invoke Ellipse, hdcMem, ball.left, ball.top, ball.right, ball.bottom

        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps

    .ELSEIF uMsg == WM_DESTROY
        ; �M�z�귽
        invoke KillTimer, hWnd, 1
        invoke DeleteObject, hBrush
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

end
