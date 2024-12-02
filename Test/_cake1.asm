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
cakeX DWORD 100           ; 初始 X 座標
cakeY DWORD 50           ; 初始 Y 座標
cakeWidth DWORD 50       ; 平台寬度
cakeHeight DWORD 20       ; 平台高度
stepSize DWORD 5              ; 每次移動的像素數量
winWidth DWORD 600              ; 視窗寬度
winHeight DWORD 600             ; 視窗高度
velocityX DWORD 5               ; 小球 X 方向速度
velocityY DWORD 0               ; 小球 Y 方向速度
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
    LOCAL wr:RECT                   ; 定義 RECT 結構

    ; 定義窗口類別
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

    ; 設置目標客戶區大小
    mov wr.left, 0
    mov wr.top, 0
    mov wr.right, 600
    mov wr.bottom, 600

    ; 調整窗口大小
    invoke AdjustWindowRect, ADDR wr, WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, FALSE

    ; 計算窗口寬度和高度
    mov eax, wr.right
    sub eax, wr.left
    mov winWidth, eax

    mov eax, wr.bottom
    sub eax, wr.top
    mov winHeight, eax

    ; 創建窗口
    invoke CreateWindowEx, NULL, ADDR ClassName, ADDR AppName, \
            WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, \
            0, 0, winWidth, winHeight, \
            NULL, NULL, hInst, NULL
    mov   hwnd,eax 
    invoke SetTimer, hwnd, 1, 50, NULL  ; 更新間隔從 50ms 改為 10ms
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
WinMain3 endp


WndProc3 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT 

    .IF uMsg==WM_DESTROY 
        invoke PostQuitMessage,NULL 
    .ELSEIF uMsg==WM_CREATE 

    .ELSEIF uMsg == WM_TIMER
        ; 更新小球位置
        call update_cake
        invoke InvalidateRect, hWnd, NULL, TRUE

    .ELSEIF uMsg == WM_COMMAND
        mov eax, wParam

    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke GetClientRect, hWnd, addr rect
        RGB    200,200,50
        invoke CreateSolidBrush, eax  ; 創建紅色筆刷
        mov hBrush, eax                          ; 存筆刷句柄
        invoke SelectObject, hdc, hBrush

        mov al, [TriesRemaining]       ; 將 TriesRemaining 的值載入 eax
        add al, '0'                     ; 將數字轉換為 ASCII (單位數)
        mov byte ptr [RemainingTriesText + 11], al ; 將字元寫入字串
        invoke DrawText, hdc, addr RemainingTriesText, -1, addr line1Rect,DT_CENTER

        ; 繪製平台
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
    ; 更新小球位置
    mov eax, cakeX
    add eax, velocityX
    mov cakeX, eax

    mov eax, cakeY
    add eax, velocityY
    mov cakeY, eax

    ; 邊界碰撞檢測（鏡面反射）
    mov eax, cakeX
    cmp eax, border_left           ; 碰到左邊界
    jle reverse_x

    add eax, cakeWidth
    cmp border_right, eax                ; 碰到右邊界
    jle reverse_x

    jmp end_update                ; 若無碰撞，結束

reverse_x:
    neg velocityX

end_update:
    ret
update_cake ENDP

end
