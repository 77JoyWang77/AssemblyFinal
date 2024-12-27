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
border_right EQU 180
ballSize EQU 20           ; 球的大小
updateInterval EQU 30     ; 計時器更新間隔 (ms)
initialVelocity EQU -20   ; 初始速度 (負值向上)
gravity EQU 2             ; 模擬重力加速度
initialground EQU 250     ; 地板高度
radius EQU 10             ; 半徑
cakeWidth EQU 60          ; 蛋糕寬度
cakeHeight EQU 20         ; 蛋糕高度
initialcakeX EQU 240      ; 初始 X 座標
initialcakeY EQU 230      ; 初始 Y 座標
initialvelocityX EQU -3   ; X 方向速度
initialcakeX1 EQU 0       ; 初始 X 座標
initialvelocityX1 EQU 3   ; X 方向速度
dropSpeed EQU 10
maxCakes EQU 100
cakeMoveSize EQU 5

.DATA
ClassName db "SimpleWinClass8", 0
AppName  db "Tofu", 0
RemainingTriesText db "Remaining:   ", 0
EndGame  db "Game Over", 0

hBackBitmapName db "bmp/tofu_background.bmp",0
hitOpenCmd db "open wav/hit.wav type mpegvideo alias hitMusic", 0
hitVolumeCmd db "setaudio hitMusic volume to 100", 0
hitPlayCmd db "play hitMusic from 0", 0

line1Rect RECT <30, 30, 280, 50>
initialball RECT <140, 230, 160, 250>
ball RECT <140, 230, 160, 250> ; 球的初始位置
firstcake RECT <120, 250, 180, 270>
cakes RECT <120, 250, 180, 270>, 99 DUP(<0, 0, 0, 0>)
colors DWORD 07165FBh, 0A5B0F4h, 0F0EBC4h, 0B2C61Fh, 0D3F0B8h, 0C3CC94h, 0E9EFA8h, 0D38A92h, 094C9E4h, 0B08DDDh, 0E1BFA2h, 09B97D8h, 09ADFCBh, 0A394D1h, 0BF95DCh, 09CE1D6h, 0E099C1h, 0DCD0A0h, 09B93D9h, 0D3D1B2h
colors_count EQU ($ - colors) / 4
winPosX DWORD 400
winPosY DWORD 0
gameover BOOL 1

.DATA?
hInstance HINSTANCE ?
hBitmap HBITMAP ?
hBackBitmap HBITMAP ?
hBackBitmap2 HBITMAP ?
hdc HDC ?
hdcMem HDC ?
hdcBack HDC ?
hBallBrush HBRUSH ?
brushes HBRUSH maxCakes DUP(?)

velocityY DWORD ?              ; 球的垂直速度
tempWidth DWORD ?
tempHeight DWORD ?
cakeX DWORD ?                        ; X 座標
cakeY DWORD ?                        ; Y 座標
cVelocityX DWORD ?                   ; X 方向速度
currentCakeIndex DWORD ?             ; 當前蛋糕索引
TriesRemaining BYTE ?                ; 剩餘次數
groundMoveCount DWORD ?              ; 記錄地面已移動的像素總數
needMove DWORD ?
ground DWORD ?
canDrop BOOL ?
valid BOOL ?
way BOOL ?
move BOOL ?

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
           winPosX, winPosY, tempWidth, tempHeight, NULL, NULL, hInstance, NULL
    mov hwnd,eax
    invoke SetTimer, hwnd, 1, updateInterval, NULL
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
    .ELSEIF uMsg == WM_TIMER
        invoke GetAsyncKeyState, VK_UP
        test eax, 8000h ; 測試最高位
        jz skip_space_key

        cmp ball.bottom, initialground
        jl skip_space_key

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
        cmp ball.bottom, initialcakeY
        jl move_ground

        call check_ball
        cmp gameover, TRUE
        je game_over
        cmp valid, TRUE
        je next

        cmp way, TRUE
        jne from_left
        cmp cakeX, border_left
        jg move_ground
        jmp next1

    from_left:
        cmp cakeX, border_left
        jl move_ground
    next1:
        call check_collision3
        cmp canDrop, FALSE
        je move_ground

    next:
        invoke mciSendString, addr hitOpenCmd, NULL, 0, NULL
        invoke mciSendString, addr hitVolumeCmd, NULL, 0, NULL
        invoke mciSendString, addr hitPlayCmd, NULL, 0, NULL
        mov move, FALSE
        mov valid,FALSE
        mov eax, cakeHeight
        add needMove, eax
        
        inc currentCakeIndex  ; 下一個蛋糕
        invoke GetTickCount
        mov ebx, 2
        cdq
        idiv ebx
        cmp edx, 0
        jne Next
        mov way, TRUE
        mov cakeX, initialcakeX
        invoke GetTickCount
        mov ebx, 5
        cdq
        idiv ebx
        add edx, 2
        neg edx
        mov cVelocityX, edx
        jmp Next1
    Next:
        mov way, FALSE
        mov cakeX, initialcakeX1
        invoke GetTickCount
        mov ebx, 5
        cdq
        idiv ebx
        add edx, 2
        mov cVelocityX, edx
    Next1:
        mov cakeY, initialcakeY
        dec TriesRemaining
        invoke InvalidateRect, hWnd, NULL, FALSE

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
        add ball.top, cakeMoveSize
        add ball.bottom, cakeMoveSize

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
        invoke InvalidateRect, hWnd, NULL, FALSE
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
        mov gameover, 1
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

initializeCake3 PROC
    mov cakeX, initialcakeX
    mov cakeY, initialcakeY
    mov ground, initialground
    mov cVelocityX, initialvelocityX
    mov TriesRemaining, maxCakes
    dec TriesRemaining
    mov groundMoveCount, 0
    mov needMove, 0
    mov currentCakeIndex, 1
    mov velocityY, 0
    mov move, FALSE
    mov gameover, FALSE
    mov valid, FALSE
    mov way, TRUE
    mov edi, OFFSET cakes
    mov ecx, maxCakes
    imul ecx, 4
    xor eax, eax
    rep stosd
    mov eax, firstcake.top
    mov cakes.top, eax
    mov eax, firstcake.bottom
    mov cakes.bottom, eax
    mov eax, firstcake.left
    mov cakes.left, eax
    mov eax, firstcake.right
    mov cakes.right, eax
    mov eax, initialball.top
    mov ball.top, eax
    mov eax, initialball.bottom
    mov ball.bottom, eax
    mov eax, initialball.left
    mov ball.left, eax
    mov eax, initialball.right
    mov ball.right, eax
initializeCake3 ENDP

Update_move PROC
    ; 更新球的位置
    mov eax, velocityY
    add ball.top, eax
    mov eax, velocityY
    add ball.bottom, eax
    add velocityY, gravity
    cmp velocityY, 0
    jl no_collision

    mov eax, ball.bottom
    cmp eax, initialground
    je stop_move

    ; 檢查碰撞地板
    mov eax, ball.bottom
    cmp eax, initialcakeY
    jl no_collision

    cmp way, TRUE
    jne check_way
    mov eax, ball.right
    cmp cakeX, eax
    jg no_collision
    jmp stop_move
check_way:
    mov eax, ball.left
    cmp cakeX, eax
    jl no_collision
    jmp stop_move
stop_move:
    ; 停止運動並固定球位置
    mov velocityY, 0  ; 停止運動
    mov move, FALSE

no_collision:
    ret
Update_move ENDP

; 更新蛋糕位置
update_cake3 PROC
    cmp cVelocityX, 0
    je end_update
    cmp way, TRUE
    jne left
    mov eax, cakeX
    cmp eax, border_left
    jle end_update
    add eax, cVelocityX
    mov cakeX, eax
    ret
left:
    mov eax, cakeX
    cmp eax, border_left
    jge end_update
    add eax, cVelocityX
    mov cakeX, eax
    ret
end_update:
    mov cVelocityX, 0
    ret
update_cake3 ENDP

; 判斷是否可放下，是return eax TRUE
check_collision3 PROC
    LOCAL cr:RECT
    LOCAL lr:RECT

    mov eax, currentCakeIndex
    mov ebx, SIZEOF RECT
    imul ebx
    mov ebx, cakes[eax].left
    mov cr.left, ebx
    mov ebx, cakes[eax].right
    mov cr.right, ebx

    mov ebx, cakes[eax - 16].left
    mov lr.left, ebx
    mov ebx, cakes[eax - 16].right
    mov lr.right, ebx

check_left:
    mov eax, lr.left
    cmp cr.right, eax
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
    Local cr:RECT

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
    
    cmp ball.bottom, initialcakeY
    jne check_side

    cmp way, TRUE
    jne left_way

    cmp cr.left, 150
    jg ball_not_collision
    jmp valid_collision

left_way:
    cmp cr.right, 150
    jl ball_not_collision
    jmp valid_collision

check_side:
    mov eax, ball.bottom
    cmp eax, initialground
    jl ball_not_collision

    cmp way, TRUE
    jne left_way2

    ; 檢查球是否與蛋糕相撞
    mov eax, ball.right
    cmp eax, cr.left
    jl ball_not_collision
    mov ebx, cr.left
    sub eax, ebx
    add cr.left, eax
    add cr.right, eax
    mov gameover, TRUE
    jmp valid_collision

left_way2:
    mov eax, ball.left
    cmp eax, cr.right
    jg ball_not_collision
    mov ebx, cr.right
    sub ebx, eax
    sub cr.left, ebx
    sub cr.right, ebx
    mov gameover, TRUE

valid_collision:
    mov ebx, SIZEOF RECT
    imul ebx, currentCakeIndex
    mov eax, cr.left
    mov cakes[ebx].left, eax
    mov eax, cr.right
    mov cakes[ebx].right, eax
    mov valid, TRUE
ball_not_collision:
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

getTofuGame PROC
    mov eax, gameover
    ret
getTofuGame ENDP
end
