.386
.model flat,stdcall
option casemap:none

include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc
include winmm.inc

.CONST
winWidth EQU 300          ; 視窗寬度
winHeight EQU 400         ; 視窗高度
border_left EQU 120
ballSize EQU 20           ; 球的大小
updateInterval EQU 30     ; 計時器更新間隔 (ms)
initialVelocity EQU -20   ; 初始速度 (負值向上)
gravity EQU 2             ; 模擬重力加速度
initialground EQU 250     ; 地板高度
radius EQU 10             ; 半徑
cakeWidth EQU 60          ; 蛋糕寬度
cakeHeight EQU 20         ; 蛋糕高度
initialcakeX EQU 200      ; 初始 X 座標
initialcakeY EQU 230      ; 初始 Y 座標
initialvelocityX EQU -5   ; X 方向速度
dropSpeed EQU 10
maxCakes EQU 100
cakeMoveSize EQU 5

.DATA
ClassName db "SimpleWinClass8", 0
AppName  db "Tofu", 0
RemainingTriesText db "Remaining:   ", 0
EndGame  db "Game Over", 0

hBackBitmapName db "bitmap4.bmp",0
hitOpenCmd db "open hit.wav type mpegvideo alias hitMusic", 0
hitVolumeCmd db "setaudio hitMusic volume to 300", 0
hitPlayCmd db "play hitMusic from 0", 0

line1Rect RECT <30, 30, 280, 50>
ball RECT <140, 230, 160, 250> ; 球的初始位置
cakes RECT <120, 250, 180, 270>, 99 DUP(<0, 0, 0, 0>)
colors DWORD 07165FBh, 0A5B0F4h, 0F0EBC4h, 0B2C61Fh, 0D3F0B8h, 0C3CC94h, 0E9EFA8h, 0D38A92h, 094C9E4h, 0B08DDDh, 0E1BFA2h, 09B97D8h, 09ADFCBh, 0A394D1h, 0BF95DCh, 09CE1D6h, 0E099C1h, 0DCD0A0h, 09B93D9h, 0D3D1B2h
colors_count EQU ($ - colors) / 4

.DATA?
hInstance HINSTANCE ?
hBitmap HBITMAP ?
hBackBitmap HBITMAP ?
hBackBitmap2 HBITMAP ?
hdc HDC ?
hdcMem HDC ?
hdcBack HDC ?
hBallBrush HBRUSH ?
brushes HBRUSH 99 DUP(?)

velocityY DWORD ?              ; 球的垂直速度
move BYTE ?
tempWidth DWORD ?
tempHeight DWORD ?
cakeX DWORD ?                        ; X 座標
cakeY DWORD ?                        ; Y 座標
cVelocityX DWORD ?                   ; X 方向速度
cVelocityY DWORD ?                   ; Y 方向速度
currentCakeIndex DWORD ?             ; 當前蛋糕索引
TriesRemaining BYTE ?                ; 剩餘次數
groundMoveCount DWORD ?              ; 記錄地面已移動的像素總數
needMove DWORD ?
ground DWORD ?
moveDown BOOL ?
gameover BOOL ?
canDrop BOOL ?

.CODE
WinMain6 proc
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    LOCAL hwnd:HWND
    LOCAL wr:RECT

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
           CW_USEDEFAULT, CW_USEDEFAULT, tempWidth, tempHeight, \
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

    .IF uMsg == WM_CREATE
        call SetBrushes3
        call initializeCake3

        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap, eax
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap2, eax
        ; 初始化資源
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

        ; 初始化球運動
        mov velocityY, 0
        mov move, FALSE
        invoke SetTimer, hWnd, 1, updateInterval, NULL

    .ELSEIF uMsg == WM_TIMER
        invoke GetAsyncKeyState, VK_SPACE
        test eax, 8000h ; 測試最高位
        jz skip_space_key

        cmp move, TRUE
        je skip_space_key
        mov velocityY, initialVelocity
        mov move, TRUE

    skip_space_key:
        call update_cake3
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

    start_move:
        cmp move, FALSE
        je skip_move
        call Update_move

     skip_move:
        cmp ball.bottom, 230
        jl move_ground

        cmp cakeX, border_left
        jne move_ground

        call check_collision3
        cmp canDrop, FALSE
        je move_ground

        mov eax, cakeHeight
        add needMove, eax
        invoke InvalidateRect, hWnd, NULL, FALSE
        inc currentCakeIndex  ; 下一個蛋糕
        mov cakeX, initialcakeX
        mov cVelocityX, initialvelocityX
        mov cakeY, initialcakeY
        mov cVelocityY, 0
        dec TriesRemaining
        cmp gameover, TRUE
        je game_over
        cmp TriesRemaining, 0
        je game_over
        ret

    move_ground:
        mov ebx, needMove
        cmp ebx, groundMoveCount
        jle skip_fall

        ; 地面和蛋糕繼續移動
        add groundMoveCount, cakeMoveSize
        add ground, cakeMoveSize

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
        invoke InvalidateRect, hWnd, NULL, FALSE
        ret
    game_over:
        ; 顯示遊戲結束訊息
        invoke KillTimer, hWnd, 1
        invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
        invoke DeleteObject, hBitmap
        invoke DeleteDC, hdcMem
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, 0
        ret
    .ELSEIF uMsg == WM_PAINT
        ; 繪製背景與球
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke BitBlt, hdcMem, 0, 0, winWidth, winHeight, hdcBack, 0, 0, SRCCOPY
        call Update3
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps

    .ELSEIF uMsg == WM_DESTROY
        ; 清理資源
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

Update_move PROC
    ; 更新球的位置
    mov eax, ball.top
    add eax, velocityY
    mov ball.top, eax
    mov eax, ball.bottom
    add eax, velocityY
    mov ball.bottom, eax
    add velocityY, gravity

    ; 檢查碰撞地板
    mov eax, ball.bottom
    cmp eax, initialground
    jl no_collision

    ; 停止運動並固定球位置
    mov velocityY, 0  ; 停止運動
    mov move, FALSE

no_collision:
    ret
Update_move ENDP

initializeCake3 PROC
    mov cakeX, initialcakeX
    mov cakeY, initialcakeY
    mov ground, initialground
    mov cVelocityX, initialvelocityX
    mov cVelocityY, 0
    mov TriesRemaining, maxCakes
    dec TriesRemaining
    mov groundMoveCount, 0
    mov needMove, 0
    mov currentCakeIndex, 1
    mov gameover, FALSE
initializeCake3 ENDP

; 更新蛋糕位置
update_cake3 PROC
    cmp cVelocityX, 0
    je end_update
    mov eax, cakeX
    cmp eax, border_left
    jne end_update
    add eax, cVelocityX
    mov cakeX, eax
end_update:
    ret
update_cake3 ENDP

; 判斷是否可放下，是return eax TRUE
check_collision3 PROC
    LOCAL cr:RECT
    LOCAL lr:RECT

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

    mov ebx, cakes[eax - 16].bottom
    mov lr.bottom, ebx
    mov ebx, cakes[eax - 16].top
    mov lr.top, ebx
    mov ebx, cakes[eax - 16].left
    mov lr.left, ebx
    mov ebx, cakes[eax - 16].right
    mov lr.right, ebx

check_left:
    mov eax, lr.left
    cmp cr.left, eax
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
    ret
check_ball ENDP

Update3 PROC
    invoke SetBkMode, hdcMem, TRANSPARENT

    mov bl, 10
    xor ah, ah
    mov al, [TriesRemaining]       ; 將 TriesRemaining 的值載入 eax
    div bl
    mov byte ptr [RemainingTriesText + 11], ' '
    cmp al, 0
    je nextdigit
    add al, '0'                     ; 將數字轉換為 ASCII (單位數)
    mov byte ptr [RemainingTriesText + 11], al ; 將字元寫入字串
    nextdigit:
    add ah, '0'                     ; 將數字轉換為 ASCII (單位數)
    mov byte ptr [RemainingTriesText + 12], ah ; 將字元寫入字串
    invoke DrawText, hdcMem, addr RemainingTriesText, -1, addr line1Rect,DT_CENTER

    mov eax, currentCakeIndex
draw_cakes:
    push eax
    push ecx
    invoke SelectObject, hdcMem, brushes[eax * 4]
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
    cmp edi, maxCakes
    je end_brushesloop
    cmp esi, colors_count
    jne brushesloop
    mov esi, 0
    jmp brushesloop
end_brushesloop:
    ret
SetBrushes3 ENDP
end
