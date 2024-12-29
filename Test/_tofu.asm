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
tofu RECT <120, 250, 180, 270>, 99 DUP(<0, 0, 0, 0>)  ; 豆腐

; 筆刷顏色
colors DWORD 07165FBh, 0A5B0F4h, 0F0EBC4h, 0B2C61Fh, 0D3F0B8h, 0C3CC94h, 0E9EFA8h, 0D38A92h, 094C9E4h, 0B08DDDh, 0E1BFA2h, 09B97D8h, 09ADFCBh, 0A394D1h, 0BF95DCh, 09CE1D6h, 0E099C1h, 0DCD0A0h, 09B93D9h, 0D3D1B2h
colors_count EQU ($ - colors) / 4

winPosX DWORD 400              ; 螢幕位置 X 座標
winPosY DWORD 0                ; 螢幕位置 Y 座標
gameover BOOL TRUE             ; 遊戲結束狀態

.DATA?
hInstance HINSTANCE ?          ; 程式實例句柄
hBitmap HBITMAP ?              ; 位圖句柄
hBackBitmap HBITMAP ?          ; 背景位圖句柄
hBackBitmap2 HBITMAP ?         ; 第二背景位圖句柄
hdcMem HDC ?                   ; 記憶體設備上下文
hdcBack HDC ?                  ; 背景設備上下文

hBallBrush HBRUSH ?            ; 球筆刷
brushes HBRUSH maxTofu DUP(?)  ; 豆腐筆刷
tempWidth DWORD ?              ; 暫存寬度
tempHeight DWORD ?             ; 暫存高度

velocityY DWORD ?              ; 球 Y 方向速度
velocityX DWORD ?              ; 豆腐 X 方向速度
tofuX DWORD ?                  ; 豆腐 X 座標
tofuY DWORD ?                  ; 豆腐 Y 座標
currentTofuIndex DWORD ?       ; 當前豆腐索引
TriesRemaining BYTE ?          ; 剩餘次數
groundMoveCount DWORD ?        ; 地面已移動距離
needMove DWORD ?               ; 地面需移動距離
ground DWORD ?                 ; 地面
way BOOL ?                     ; 紀錄豆腐位置，TRUE 為右，FALSE 為左
move BOOL ?                    ; 球是否移動中

.CODE
WinMain6 proc
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    LOCAL hwnd:HWND
    LOCAL wr:RECT

    invoke GetModuleHandle, NULL
    mov    hInstance,eax

    ; 初始化窗口類
    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET WndProc6
    mov wc.cbClsExtra, NULL
    mov wc.cbWndExtra, NULL
    push hInstance
    pop wc.hInstance
    mov wc.hbrBackground, COLOR_WINDOW+1
    mov wc.lpszMenuName, NULL
    mov wc.lpszClassName, OFFSET ClassName
    invoke LoadIcon, NULL, IDI_APPLICATION
    mov wc.hIcon, eax
    mov wc.hIconSm, eax
    invoke LoadCursor, NULL, IDC_ARROW
    mov wc.hCursor, eax
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

        ; 初始化遊戲資源
        call SetBrushes3
        call initializetofu

        ; 加載位圖
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap, eax
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap2, eax

        ; 初始化畫面
        invoke GetDC,hWnd              
        mov hdc, eax
        invoke CreateCompatibleDC,hdc  
        mov hdcMem, eax
        invoke CreateCompatibleDC,hdc 
        mov hdcBack, eax
        invoke SelectObject, hdcMem, hBackBitmap
        invoke SelectObject, hdcBack, hBackBitmap2
        invoke ReleaseDC, hWnd, hdc

    .ELSEIF uMsg == WM_TIMER

        ; 偵測空白鍵
        invoke GetAsyncKeyState, VK_UP
        test eax, 8000h ; 測試最高位
        jz skip_space_key

        cmp ball.bottom, initialground    ; 如果球未在初始位置，略過空白鍵
        jl skip_space_key

        cmp move, TRUE                    ; 如果球在移動，略過空白鍵
        je skip_space_key
        mov velocityY, initialVelocity    ; 設置球初速
        mov move, TRUE                    ; 設置球狀態

    skip_space_key:
        ; 更新豆腐狀態
        call update_tofu
        mov ebx, SIZEOF RECT
        imul ebx, currentTofuIndex
        mov eax, tofuX
        mov tofu[ebx].left, eax
        add eax, tofuWidth
        mov tofu[ebx].right, eax
        mov eax, tofuY
        mov tofu[ebx].top, eax
        add eax, tofuHeight
        mov tofu[ebx].bottom, eax

        ; 更新球狀態
        call update_ball2
        cmp ball.bottom, initialtofuY      ; 如果球還未到豆腐的頂端，略過剩下的判斷
        jl move_ground

        ; 確認球與豆腐的碰撞
        call check_ball
        cmp gameover, TRUE                 ; 如果 gameover 為 TRUE，結束遊戲
        je game_over
        cmp eax, TRUE                      ; 如果碰撞，設置下一個豆腐
        je next

        ; 確認豆腐是否處於可放下位置
        call check_tofu
        cmp eax, FALSE
        je move_ground

    next:
        ; 碰撞音效
        invoke mciSendString, addr hitOpenCmd, NULL, 0, NULL
        invoke mciSendString, addr hitVolumeCmd, NULL, 0, NULL
        invoke mciSendString, addr hitPlayCmd, NULL, 0, NULL

        mov move, FALSE                    ; 球停止移動
        add needMove, tofuHeight           ; 增加地板需移動距離
        inc currentTofuIndex               ; 下一個豆腐
        dec TriesRemaining                 ; 減少剩餘豆腐數

        ; 獲取隨機 X 方向速度
        invoke GetTickCount
        mov ebx, 5
        cdq
        idiv ebx
        add edx, 2
        mov velocityX, edx
        
        ; 獲取隨機豆腐刷新位置
        invoke GetTickCount
        mov ebx, 2
        cdq
        idiv ebx
        cmp edx, 0
        jne from_left

        mov way, TRUE                     ; 刷新在右方
        mov tofuX, initialtofuX
        neg velocityX
        jmp end_update

    from_left:
        mov way, FALSE                    ; 刷新在左方
        mov tofuX, initialtofuX1

    end_update:
        invoke InvalidateRect, hWnd, NULL, FALSE      ; 刷新畫面

        cmp TriesRemaining, 0             ; 如果剩餘次數為 0，結束遊戲
        je game_over
        ret

    move_ground:
        ; 確認地板是否需要移動
        mov ebx, needMove
        cmp ebx, groundMoveCount
        jle skip_fall

        ; 地面和球移動
        add groundMoveCount, tofuMoveSize
        add ground, tofuMoveSize
        add ball.top, tofuMoveSize
        add ball.bottom, tofuMoveSize

        ; 豆腐移動
        mov ecx, currentTofuIndex
        dec ecx
    move_ground_loop:
        mov eax, ecx
        cmp eax, 0
        jl skip_fall
        mov ebx, SIZEOF RECT
        imul ebx
        add tofu[eax].top, tofuMoveSize
        add tofu[eax].bottom, tofuMoveSize
        dec ecx
        jmp move_ground_loop

    skip_fall:
        invoke InvalidateRect, hWnd, NULL, FALSE      ; 刷新畫面
        ret

    game_over:
        ; 顯示遊戲結束訊息
        invoke InvalidateRect, hWnd, NULL, FALSE
        invoke KillTimer, hWnd, 1
        invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
        invoke PostMessage, hWnd, WM_DESTROY, 0, 0
        ret

    .ELSEIF uMsg == WM_PAINT

        ; 繪製畫面
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke BitBlt, hdcMem, 0, 0, winWidth, winHeight, hdcBack, 0, 0, SRCCOPY
        call Update3
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps

    .ELSEIF uMsg == WM_DESTROY

        ; 清理資源
        mov gameover, TRUE
        invoke DeleteObject, hBitmap
        invoke DeleteObject, hBackBitmap
        invoke DeleteObject, hBackBitmap2
        invoke DeleteDC, hdcMem
        invoke DeleteDC, hdcBack
        invoke ReleaseDC, hWnd, hdc
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, NULL

    .ELSE
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
        ret
    .ENDIF
    xor eax, eax
    ret
WndProc6 endp

; 初始化遊戲
initializetofu PROC

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
    mov way, TRUE
    mov edi, OFFSET tofu
    mov ecx, maxTofu
    imul ecx, 4
    xor eax, eax
    rep stosd
    mov eax, firsttofu.top
    mov tofu.top, eax
    mov eax, firsttofu.bottom
    mov tofu.bottom, eax
    mov eax, firsttofu.left
    mov tofu.left, eax
    mov eax, firsttofu.right
    mov tofu.right, eax
    mov eax, initialball.top
    mov ball.top, eax
    mov eax, initialball.bottom
    mov ball.bottom, eax
    mov eax, initialball.left
    mov ball.left, eax
    mov eax, initialball.right
    mov ball.right, eax

initializetofu ENDP

; 更新球狀態
update_ball2 PROC

    cmp move, FALSE           ; 球未在移動，略過下列操作
    je no_collision

    ; 更新球的位置
    mov eax, velocityY
    add ball.top, eax
    mov eax, velocityY
    add ball.bottom, eax
    add velocityY, gravity
    cmp velocityY, 0          ; 球還在上升狀態，不會與地板碰撞，略過下列判斷
    jl no_collision

    mov eax, ball.bottom      ; 球已在初始高度，停止移動
    cmp eax, initialground
    je stop_move

    ; 檢查碰撞地板
    mov eax, ball.bottom
    cmp eax, initialtofuY
    jl no_collision

    cmp way, TRUE             ; 判斷豆腐方向
    jne from_left

    mov eax, ball.right       ; 豆腐在右方，如果碰到球的右邊，停止移動
    cmp tofuX, eax
    jg no_collision
    jmp stop_move

from_left:
    mov eax, ball.left        ; 豆腐在左方，如果碰到球的左邊，停止移動
    cmp tofuX, eax
    jl no_collision
    jmp stop_move

stop_move:
    mov velocityY, 0          ; 球速度歸零
    mov move, FALSE

no_collision:
    ret

update_ball2 ENDP

; 更新豆腐狀態
update_tofu PROC

    cmp velocityX, 0          ; 速度為 0，略過操作
    je end_update

    cmp way, TRUE             ; 判斷豆腐方向
    jne from_left

    mov eax, tofuX
    cmp eax, border_left      ; 豆腐在右方，如果小於左邊界，停止移動
    jle end_update
    add eax, velocityX        ; 更新豆腐位置
    mov tofuX, eax
    ret

from_left:
    mov eax, tofuX
    cmp eax, border_left      ; 豆腐在左方，如果大於左邊界，停止移動
    jge end_update
    add eax, velocityX        ; 更新豆腐位置
    mov tofuX, eax
    ret

end_update:
    mov velocityX, 0          ; 豆腐速度歸零
    ret

update_tofu ENDP

; 判斷豆腐是否可放下，是return eax TRUE
check_tofu PROC

    LOCAL cr:RECT
    LOCAL lr:RECT

    cmp way, TRUE             ; 判斷豆腐方向
    jne from_left

    cmp tofuX, border_left    ; 豆腐在右方，如果未到左邊界，return FALSE
    jg check_end
    jmp check_last_tofu

from_left:
    cmp tofuX, border_left    ; 豆腐在左方，如果未到左邊界，return FALSE
    jl check_end

check_last_tofu:              ; 確認現在的豆腐已在上個豆腐上方
    mov eax, currentTofuIndex
    mov ebx, SIZEOF RECT
    imul ebx
    mov ebx, tofu[eax].left
    mov cr.left, ebx
    mov ebx, tofu[eax].right
    mov cr.right, ebx

    mov ebx, tofu[eax - 16].left
    mov lr.left, ebx
    mov ebx, tofu[eax - 16].right
    mov lr.right, ebx

check_left:                   ; 現在的右邊界應小於等於上個的左邊界
    mov eax, lr.left
    cmp cr.right, eax
    jl check_end
    
check_right:                  ; 現在的左邊界應大於等於上個的右邊界
    mov eax, lr.right
    cmp cr.left, eax
    mov eax, TRUE
    ret

check_end:
    mov eax, FALSE
    ret

check_tofu ENDP

; 檢查是否與豆腐碰撞，是return eax TRUE
check_ball PROC

    Local cr:RECT

    mov eax, currentTofuIndex
    mov ebx, SIZEOF RECT
    imul ebx
    mov ebx, tofu[eax].left
    mov cr.left, ebx
    mov ebx, tofu[eax].right
    mov cr.right, ebx
    
    cmp ball.bottom, initialtofuY   ; 先檢查球底部已在豆腐頂部
    jne check_side

    cmp way, TRUE                   ; 判斷豆腐方向
    jne left_way

    cmp cr.left, 150                ; 豆腐在右方，豆腐邊界應至少小於球的中心點
    jg ball_not_collision
    jmp valid_collision

left_way:
    cmp cr.right, 150               ; 豆腐在左方，豆腐邊界應至少大於球的中心點
    jl ball_not_collision
    jmp valid_collision

check_side:
    mov eax, ball.bottom            ; 檢查球與豆腐在同一水平，如果碰撞，gameover 為 TRUE
    cmp eax, initialground
    jl ball_not_collision

    cmp way, TRUE                   ; 判斷豆腐方向
    jne left_way2

    mov eax, ball.right             ; 豆腐在右方，豆腐左邊界如小於等於球的右邊界，則碰撞
    cmp eax, cr.left
    jl ball_not_collision
    mov ebx, cr.left                ; 修正豆腐位置，避免出現重疊畫面
    sub eax, ebx
    add cr.left, eax
    add cr.right, eax
    mov gameover, TRUE
    jmp valid_collision

left_way2:
    mov eax, ball.left              ; 豆腐在左方，豆腐右邊界如大於等於球的右邊界，則碰撞
    cmp eax, cr.right
    jg ball_not_collision
    mov ebx, cr.right               ; 修正豆腐位置，避免出現重疊畫面
    sub ebx, eax
    sub cr.left, ebx
    sub cr.right, ebx
    mov gameover, TRUE

valid_collision:
    mov ebx, SIZEOF RECT            ; 將修正豆腐位置，存回陣列
    imul ebx, currentTofuIndex
    mov eax, cr.left
    mov tofu[ebx].left, eax
    mov eax, cr.right
    mov tofu[ebx].right, eax
    mov eax, TRUE
    ret

ball_not_collision:
    mov eax, FALSE
    ret

check_ball ENDP

; 更新畫面
Update3 PROC

    invoke SetBkMode, hdcMem, TRANSPARENT

    ; 文字
    mov bl, 10
    xor ah, ah
    mov al, [TriesRemaining]                       ; 將 TriesRemaining 的值載入 al
    div bl
    mov byte ptr [RemainingTriesText + 11], ' '    ; 先將十位數初始為空

    cmp al, 0
    je nextdigit
    add al, '0'                                    ; 將數字轉換為 ASCII (單位數)
    mov byte ptr [RemainingTriesText + 11], al     ; 寫入十位數

nextdigit:
    add ah, '0'                                    ; 將數字轉換為 ASCII (單位數)
    mov byte ptr [RemainingTriesText + 12], ah     ; 寫入個位數
    invoke DrawText, hdcMem, addr RemainingTriesText, -1, addr line1Rect,DT_CENTER

    ; 豆腐
    mov eax, currentTofuIndex
draw_tofus:
    push eax
    push ecx
    invoke SelectObject, hdcMem, brushes[eax * 4]  ; 選擇筆刷
    pop ecx
    pop eax
    mov ebx, SIZEOF RECT
    imul ebx
    push eax
    invoke Rectangle, hdcMem, tofu[eax].left, tofu[eax].top, tofu[eax].right, tofu[eax].bottom
    pop eax
    idiv ebx
    dec eax
    cmp eax, 0
    jge draw_tofus

    ; 球
    invoke SelectObject, hdcMem, hBallBrush
    invoke Ellipse, hdcMem, ball.left, ball.top, ball.right, ball.bottom
    ret

Update3 ENDP

; 設定筆刷
SetBrushes3 PROC

    invoke CreateSolidBrush, 00C9A133h
    mov hBallBrush, eax
    
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

; 返回遊戲狀態
getTofuGame PROC
    mov eax, gameover
    ret
getTofuGame ENDP
end
