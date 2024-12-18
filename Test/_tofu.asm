.386
.model flat,stdcall
option casemap:none

include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc

.CONST
winWidth EQU 300        ; 視窗寬度
winHeight EQU 400       ; 視窗高度
ballSize EQU 20         ; 球的大小
updateInterval EQU 30   ; 計時器更新間隔 (ms)
initialVelocity EQU -20 ; 初始速度 (負值向上)
gravity EQU 2           ; 模擬重力加速度
floor EQU 350           ; 地板高度

.DATA
ClassName db "BallMotionClass", 0
AppName  db "Ball Motion", 0
EndGame  db "Game Over", 0

ball RECT <140, 330, 160, 350> ; 球的初始位置
velocityY DWORD ?              ; 球的垂直速度
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

    ; 初始化窗口類
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

    ; 創建窗口
    invoke CreateWindowEx, NULL, ADDR ClassName, ADDR AppName, \
           WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, \
           CW_USEDEFAULT, CW_USEDEFAULT, winWidth, winHeight, \
           NULL, NULL, hInstance, NULL
    mov hwnd,eax

    invoke ShowWindow, hwnd, SW_SHOWNORMAL
    invoke UpdateWindow, hwnd

    ; 主消息循環
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
        ; 初始化資源
        invoke GetDC, hWnd
        mov hdc, eax

        invoke CreateCompatibleDC, hdc
        mov hdcMem, eax

        invoke CreateCompatibleBitmap, hdc, winWidth, winHeight
        mov hBitmap, eax
        invoke SelectObject, hdcMem, hBitmap

        ; 背景與球的筆刷
        invoke CreateSolidBrush, 00FFFFFFh
        mov hBrush, eax

        invoke CreateSolidBrush, 0000FF00h
        mov hBallBrush, eax

        ; 初始化球運動
        mov velocityY, 0
        mov move, FALSE
        invoke SetTimer, hWnd, 1, updateInterval, NULL

    .ELSEIF uMsg == WM_TIMER
        ; 模擬重力
        cmp move, TRUE
        jne no_collision
        add velocityY, gravity

        ; 更新球的位置
        mov eax, ball.top
        add eax, velocityY
        mov ball.top, eax
        mov eax, ball.bottom
        add eax, velocityY
        mov ball.bottom, eax

        ; 檢查碰撞地板
        mov eax, ball.bottom
        cmp eax, floor
        jl no_collision

        ; 停止運動並固定球位置
        mov velocityY, 0  ; 停止運動
        mov move, FALSE

    no_collision:
        ; 重繪窗口
        invoke InvalidateRect, hWnd, NULL, FALSE

    .ELSEIF uMsg == WM_KEYDOWN
        cmp wParam, VK_SPACE
        jne skip_space

        ; 如果按下空白鍵，初始化向上運動
        mov velocityY, initialVelocity
        mov move, TRUE

    skip_space:

    .ELSEIF uMsg == WM_PAINT
        ; 繪製背景與球
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax

        invoke GetClientRect, hWnd, addr rect
        invoke FillRect, hdcMem, addr rect, hBrush

        invoke SelectObject, hdcMem, hBallBrush
        invoke Ellipse, hdcMem, ball.left, ball.top, ball.right, ball.bottom

        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps

    .ELSEIF uMsg == WM_DESTROY
        ; 清理資源
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
