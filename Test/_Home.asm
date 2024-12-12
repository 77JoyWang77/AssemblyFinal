.386 
.model flat,stdcall 
option casemap:none 

EXTERN WinMain1@0: PROC
EXTERN WinMain2@0: PROC
EXTERN WinMain3@0: PROC
EXTERN WinMain4@0: PROC
EXTERN WinMain5@0: PROC
Advanced1A2B EQU WinMain1@0
GameBrick EQU WinMain2@0
Cake1 EQU WinMain3@0
Minesweeper EQU WinMain4@0
Cake2 EQU WinMain5@0

WinMain proto :DWORD

include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 

.DATA 
ClassName db "SimpleWinClass",0 
AppName  db "Home",0 
ButtonClassName db "button", 0 
ButtonText1 db "1A2B", 0
ButtonText2 db "Breakout", 0
ButtonText3 db "Cake1", 0
ButtonText4 db "Minesweeper", 0
ButtonText5 db "Cake2", 0
winWidth EQU 400        ; 視窗寬度
winHeight EQU 600       ; 視窗高度

.DATA? 
hInstance HINSTANCE ? 
hBitmap HBITMAP ?
hBrush HBRUSH ?
hdcMem HDC ?
tempWidth DWORD ?
tempHeight DWORD ?

.CODE 
Home PROC 
    invoke GetModuleHandle, NULL 
    mov    hInstance,eax 
    invoke WinMain, hInstance
    ret
Home ENDP

WinMain proc hInst:HINSTANCE
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT                   ; 定義 RECT 結構

    ; 定義窗口類別
    mov   wc.cbSize,SIZEOF WNDCLASSEX 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc
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

    ; 設置客戶區大小
    mov wr.left, 0
    mov wr.top, 0
    mov eax, winWidth
    mov wr.right, eax
    mov eax, winHeight
    mov wr.bottom, eax

    ; 調整窗口大小
    invoke AdjustWindowRect, ADDR wr, WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, FALSE
    mov eax, wr.right
    sub eax, wr.left
    mov tempWidth, eax
    mov eax, wr.bottom
    sub eax, wr.top
    mov tempHeight, eax

    ; 創建窗口
    invoke CreateWindowEx, NULL, ADDR ClassName, ADDR AppName, \
            WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, \
            0, 0, tempWidth, tempHeight, NULL, NULL, hInst, NULL
    mov   hwnd,eax 
    invoke SetTimer, hwnd, 1, 50, NULL

    ; 顯示和更新窗口
    invoke ShowWindow, hwnd,SW_SHOWNORMAL 
    invoke UpdateWindow, hwnd 

    ; 主消息循環
    .WHILE TRUE 
        invoke GetMessage, ADDR msg,NULL,0,0 
        .BREAK .IF (!eax) 
        invoke TranslateMessage, ADDR msg 
        invoke DispatchMessage, ADDR msg 
    .ENDW 
    mov     eax,msg.wParam 
    ret 
WinMain endp


WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT

    .IF uMsg==WM_DESTROY 
        invoke KillTimer, hWnd, 1
        ; 清理資源
        invoke DeleteObject, hBrush
        invoke DeleteObject, hBitmap
        invoke DeleteDC, hdcMem
        ; 發送退出訊息
        invoke PostQuitMessage, NULL
        ret
    .ELSEIF uMsg == WM_CREATE
        INVOKE  GetDC,hWnd              
        mov     hdc,eax

        ; 創建內存設備上下文 (hdcMem) 和位圖
        invoke CreateCompatibleDC, hdc
        mov hdcMem, eax

        invoke CreateCompatibleBitmap, hdc, winWidth, winHeight
        mov hBitmap, eax
        invoke SelectObject, hdcMem, hBitmap

        ; 填充背景顏色
        invoke GetClientRect, hWnd, addr rect
        invoke CreateSolidBrush, 00FFFFFFh
        mov hBrush, eax
        invoke FillRect, hdcMem, addr rect, hBrush

        invoke CreateWindowEx, NULL,  ADDR ButtonClassName, ADDR ButtonText1, \
               WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_CENTER, \
               100, 100, 200, 50, hWnd, 1, hInstance, NULL
        invoke CreateWindowEx, NULL,  ADDR ButtonClassName, ADDR ButtonText2, \
               WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_CENTER, \
               100, 170, 200, 50, hWnd, 2, hInstance, NULL
        invoke CreateWindowEx, NULL,  ADDR ButtonClassName, ADDR ButtonText3, \
               WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_CENTER, \
               100, 240, 200, 50, hWnd, 3, hInstance, NULL
        invoke CreateWindowEx, NULL,  ADDR ButtonClassName, ADDR ButtonText4, \
               WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_CENTER, \
               100, 310, 200, 50, hWnd, 4, hInstance, NULL
        invoke CreateWindowEx, NULL,  ADDR ButtonClassName, ADDR ButtonText5, \
               WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_CENTER, \
               100, 380, 200, 50, hWnd, 5, hInstance, NULL
    .ELSEIF uMsg == WM_COMMAND
        mov eax, wParam
        cmp eax, 1
        je StartGame1
        cmp eax, 2
        je StartGame2
        cmp eax, 3
        je StartGame3
        cmp eax, 4
        je StartGame4
        cmp eax, 5
        je StartGame5
    .ELSEIF uMsg == WM_TIMER
        ; 重繪視窗
        invoke InvalidateRect, hWnd, NULL, FALSE

    .ELSEIF uMsg == WM_PAINT
        ; 先開始繪製
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        ; 使用 BitBlt 複製內存位圖到螢幕
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps

    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 
StartGame1:
    ; 呼叫遊戲啟動
    call Advanced1A2B
    ret
StartGame2:
    ; 呼叫遊戲啟動
    call GameBrick
    ret
StartGame3:
    ; 呼叫遊戲啟動
    call Cake1
    ret
StartGame4:
    ; 呼叫遊戲啟動
    call Minesweeper
    ret
StartGame5:
    ; 呼叫遊戲啟動
    call Cake2
    ret
WndProc endp 

end
