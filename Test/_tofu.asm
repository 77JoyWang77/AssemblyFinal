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
border_left EQU 120       ; 豆腐下落左邊界
border_right EQU 180      ; 豆腐下落又邊界
updateInterval EQU 30     ; 計時器更新間隔 (ms)
initialVelocity EQU -20   ; 球初始速度 (負值向上)
gravity EQU 2             ; 模擬重力加速度
initialground EQU 250     ; 初始地板
tofuWidth EQU 60          ; 豆腐寬度
tofuHeight EQU 20         ; 豆腐高度
initialtofuX EQU 240      ; 豆腐初始 X 座標 1
initialvelocityX EQU -3   ; 豆腐初始 X 方向速度 1
initialtofuX1 EQU 0       ; 豆腐初始 X 座標 2
initialvelocityX1 EQU 3   ; 豆腐初始 X 方向速度 2
initialtofuY EQU 230      ; 豆腐初始 Y 座標
maxTofu EQU 100           ; 最多豆腐數
tofuMoveSize EQU 5        ; 下降高度

.DATA
ClassName db "SimpleWinClass8", 0
AppName db "Tofu", 0
RemainingTriesText db "Remaining:   ", 0
EndGame db "Game Over", 0

; 音效/背景
hBackBitmapName db "bmp/tofu_background.bmp",0
hitOpenCmd db "open wav/hit.wav type mpegvideo alias hitMusic", 0
hitVolumeCmd db "setaudio hitMusic volume to 100", 0
hitPlayCmd db "play hitMusic from 0", 0

; 物件位置
line1Rect RECT <30, 30, 280, 50>                       ; 文字
initialball RECT <140, 230, 160, 250>                  ; 球初始
ball RECT <140, 230, 160, 250>                         ; 球
firsttofu RECT <120, 250, 180, 270>                    ; 豆腐初始
tofus RECT <120, 250, 180, 270>, 99 DUP(<0, 0, 0, 0>)  ; 豆腐

; 筆刷顏色
colors DWORD 07165FBh, 0A5B0F4h, 0F0EBC4h, 0B2C61Fh, 0D3F0B8h, 0C3CC94h, 0E9EFA8h, 0D38A92h, 094C9E4h, 0B08DDDh, 0E1BFA2h, 09B97D8h, 09ADFCBh, 0A394D1h, 0BF95DCh, 09CE1D6h, 0E099C1h, 0DCD0A0h, 09B93D9h, 0D3D1B2h
colors_count EQU ($ - colors) / 4

winPosX DWORD 400              ; 螢幕位置 X 座標
winPosY DWORD 0                ; 螢幕位置 Y 座標
gameover BOOL FALSE            ; 遊戲結束狀態

.DATA?
hInstance HINSTANCE ?          ; 程式實例句柄
hBitmap HBITMAP ?              ; 位圖句柄
hBackBitmap HBITMAP ?          ; 背景位圖句柄
hBackBitmap2 HBITMAP ?         ; 第二背景位圖句柄
hdcMem HDC ?                   ; 記憶體設備上下文
hdcBack HDC ?                  ; 背景設備上下文

hBallBrush HBRUSH ?            ; 球筆刷
brushes HBRUSH maxTofu DUP(?)  ; 豆腐筆刷
tempWidth DWORD ?
tempHeight DWORD ?

velocityY DWORD ?              ; 球 Y 方向速度
velocityX DWORD ?              ; 豆腐 X 方向速度
tofuX DWORD ?                  ; 豆腐 X 座標
tofuY DWORD ?                  ; 豆腐 Y 座標
currentTofuIndex DWORD ?       ; 當前豆腐索引
TriesRemaining BYTE ?          ; 剩餘次數
groundMoveCount DWORD ?        ; 地面已移動距離
needMove DWORD ?               ; 地面需移動距離
ground DWORD ?                 ; 地面
canDrop BOOL ?                 ; 豆腐可放下
valid BOOL ?                   ;
way BOOL ?                     ;
move BOOL ?                    ;

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
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT

    .IF uMsg == WM_CREATE
        call SetBrushes3
        call initializetofu3

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
        call update_tofu3
        mov ebx, SIZEOF RECT
        imul ebx, currentTofuIndex
        mov eax, tofuX
        mov tofus[ebx].left, eax
        add eax, tofuWidth
        mov tofus[ebx].right, eax
        mov eax, tofuY
        mov tofus[ebx].top, eax
        add eax, tofuHeight
        mov tofus[ebx].bottom, eax

    start_move:
        cmp move, FALSE
        je skip_move
        call Update_move

    skip_move:
        cmp ball.bottom, initialtofuY
        jl move_ground

        call check_ball
        cmp gameover, TRUE
        je game_over
        cmp valid, TRUE
        je next

        cmp way, TRUE
        jne from_left
        cmp tofuX, border_left
        jg move_ground
        jmp next1

    from_left:
        cmp tofuX, border_left
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
        mov eax, tofuHeight
        add needMove, eax
        
        inc currentTofuIndex  ; 下一個豆腐
        invoke GetTickCount
        mov ebx, 2
        cdq
        idiv ebx
        cmp edx, 0
        jne Next
        mov way, TRUE
        mov tofuX, initialtofuX
        invoke GetTickCount
        mov ebx, 5
        cdq
        idiv ebx
        add edx, 2
        neg edx
        mov velocityX, edx
        jmp Next1
    Next:
        mov way, FALSE
        mov tofuX, initialtofuX1
        invoke GetTickCount
        mov ebx, 5
        cdq
        idiv ebx
        add edx, 2
        mov velocityX, edx
    Next1:
        mov tofuY, initialtofuY
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

        ; 地面和豆腐繼續移動
        add groundMoveCount, tofuMoveSize
        add ground, tofuMoveSize
        add ball.top, tofuMoveSize
        add ball.bottom, tofuMoveSize

        mov ecx, currentTofuIndex
        dec ecx
    move_ground_loop:
        mov eax, ecx
        cmp eax, 0
        jl skip_fall
        mov ebx, SIZEOF RECT
        imul ebx
        add tofus[eax].top, tofuMoveSize
        add tofus[eax].bottom, tofuMoveSize
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

initializetofu3 PROC
    mov tofuX, initialtofuX
    mov tofuY, initialtofuY
    mov ground, initialground
    mov velocityX, initialvelocityX
    mov TriesRemaining, maxTofu
    dec TriesRemaining
    mov groundMoveCount, 0
    mov needMove, 0
    mov currentTofuIndex, 1
    mov velocityY, 0
    mov move, FALSE
    mov gameover, FALSE
    mov valid, FALSE
    mov way, TRUE
    mov edi, OFFSET tofus
    mov ecx, maxTofu
    imul ecx, 4
    xor eax, eax
    rep stosd
    mov eax, firsttofu.top
    mov tofus.top, eax
    mov eax, firsttofu.bottom
    mov tofus.bottom, eax
    mov eax, firsttofu.left
    mov tofus.left, eax
    mov eax, firsttofu.right
    mov tofus.right, eax
    mov eax, initialball.top
    mov ball.top, eax
    mov eax, initialball.bottom
    mov ball.bottom, eax
    mov eax, initialball.left
    mov ball.left, eax
    mov eax, initialball.right
    mov ball.right, eax
initializetofu3 ENDP

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
    cmp eax, initialtofuY
    jl no_collision

    cmp way, TRUE
    jne check_way
    mov eax, ball.right
    cmp tofuX, eax
    jg no_collision
    jmp stop_move
check_way:
    mov eax, ball.left
    cmp tofuX, eax
    jl no_collision
    jmp stop_move
stop_move:
    ; 停止運動並固定球位置
    mov velocityY, 0  ; 停止運動
    mov move, FALSE

no_collision:
    ret
Update_move ENDP

; 更新豆腐位置
update_tofu3 PROC
    cmp velocityX, 0
    je end_update
    cmp way, TRUE
    jne left
    mov eax, tofuX
    cmp eax, border_left
    jle end_update
    add eax, velocityX
    mov tofuX, eax
    ret
left:
    mov eax, tofuX
    cmp eax, border_left
    jge end_update
    add eax, velocityX
    mov tofuX, eax
    ret
end_update:
    mov velocityX, 0
    ret
update_tofu3 ENDP

; 判斷豆腐是否可放下，是return eax TRUE
check_collision3 PROC
    LOCAL cr:RECT
    LOCAL lr:RECT

    mov eax, currentTofuIndex
    mov ebx, SIZEOF RECT
    imul ebx
    mov ebx, tofus[eax].left
    mov cr.left, ebx
    mov ebx, tofus[eax].right
    mov cr.right, ebx

    mov ebx, tofus[eax - 16].left
    mov lr.left, ebx
    mov ebx, tofus[eax - 16].right
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

    mov eax, currentTofuIndex
    mov ebx, SIZEOF RECT
    imul ebx
    mov ebx, tofus[eax].bottom
    mov cr.bottom, ebx
    mov ebx, tofus[eax].top
    mov cr.top, ebx
    mov ebx, tofus[eax].left
    mov cr.left, ebx
    mov ebx, tofus[eax].right
    mov cr.right, ebx
    
    cmp ball.bottom, initialtofuY
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

    ; 檢查球是否與豆腐相撞
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
    imul ebx, currentTofuIndex
    mov eax, cr.left
    mov tofus[ebx].left, eax
    mov eax, cr.right
    mov tofus[ebx].right, eax
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

    mov eax, currentTofuIndex
draw_tofus:
    push eax
    push ecx
    invoke SelectObject, hdcMem, brushes[eax * 4]
    pop ecx
    pop eax
    mov ebx, SIZEOF RECT
    imul ebx
    push eax
    invoke Rectangle, hdcMem, tofus[eax].left, tofus[eax].top, tofus[eax].right, tofus[eax].bottom
    pop eax
    idiv ebx
    dec eax
    cmp eax, 0
    jge draw_tofus

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
    cmp edi, maxTofu
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
