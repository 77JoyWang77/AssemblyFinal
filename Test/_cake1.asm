.386 
.model flat,stdcall 
option casemap:none 

include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 
include winmm.inc

EXTERN getOtherGame@0: PROC
backBreakOut EQU getOtherGame@0

.CONST
winWidth EQU 300          ; 視窗寬度
winHeight EQU 350         ; 視窗高度
cakeWidth EQU 50          ; 蛋糕寬度
cakeHeight EQU 20         ; 蛋糕高度
border_left EQU 30        ; 蛋糕反彈左邊界
border_right EQU 270      ; 蛋糕反彈右邊界
initialcakeX EQU 50       ; 初始 X 座標 1
initialcakeX1 EQU 200     ; 初始 X 座標 2
initialcakeY EQU 80       ; 初始 Y 座標
initialvelocityX EQU 10   ; 初始 X 方向速度 1
initialvelocityX1 EQU -10 ; 初始 X 方向速度 2
initialground EQU 300     ; 初始地板
dropSpeed EQU 10          ; 蛋糕掉落速度
updateInterval EQU 30     ; 計時器更新間隔 (ms)
cakeMoveSize EQU 5        ; 下降高度
heighest EQU 280          ; 蛋糕最高高度

.DATA 
ClassName db "SimpleWinClass3", 0 
AppName  db "Cake", 0 
RemainingTriesText db "Remaining:   ", 0
EndGame db "Game Over!", 0

; 音效/背景
hBackBitmapName db "bmp/cake1_background.bmp",0
hitOpenCmd db "open wav/hit.wav type mpegvideo alias hitMusic", 0
hitVolumeCmd db "setaudio hitMusic volume to 100", 0
hitPlayCmd db "play hitMusic from 0", 0

line1Rect RECT <30, 30, 280, 50>
cakes RECT 99 DUP(<0, 0, 0, 0>) ; 儲存蛋糕邊界

; 筆刷顏色
colors DWORD 07165FBh, 0A5B0F4h, 0F0EBC4h, 0B2C61Fh, 0D3F0B8h, 0C3CC94h, 0E9EFA8h, 0D38A92h, 094C9E4h, 0B08DDDh, 0E1BFA2h, 09B97D8h, 09ADFCBh, 0A394D1h, 0BF95DCh, 09CE1D6h, 0E099C1h, 0DCD0A0h, 09B93D9h, 0D3D1B2h
colors_count EQU ($ - colors) / 4

winPosX DWORD 400              ; 螢幕位置 X 座標
winPosY DWORD 0                ; 螢幕位置 Y 座標
gameover BOOL TRUE             ; 遊戲結束狀態
fromBreakout BOOL FALSE        ; 從 Breakout 開啟遊戲

.DATA?
hInstance HINSTANCE ?          ; 程式實例句柄
hBitmap HBITMAP ?              ; 位圖句柄
hBackBitmap HBITMAP ?          ; 背景位圖句柄
hBackBitmap2 HBITMAP ?         ; 第二背景位圖句柄
hdcMem HDC ?                   ; 記憶體設備上下文
hdcBack HDC ?                  ; 背景設備上下文

brushes HBRUSH 99 DUP(?)       ; 蛋糕筆刷
tempWidth DWORD ?              ; 暫存寬度
tempHeight DWORD ?             ; 暫存高度

maxCakes DWORD ?               ; 最大蛋糕數量
cakeX DWORD ?                  ; 蛋糕 X 座標
cakeY DWORD ?                  ; 蛋糕 Y 座標
velocityX DWORD ?              ; 蛋糕 X 方向速度
velocityY DWORD ?              ; 蛋糕 Y 方向速度
currentCakeIndex DWORD ?       ; 當前豆腐索引
TriesRemaining BYTE ?          ; 剩餘次數
groundMoveCount DWORD ?        ; 地面已移動距離
needMove DWORD ?               ; 地面需移動距離
ground DWORD ?                 ; 地面
falling BOOL ?                 ; 是否有蛋糕正在掉落
moveDown BOOL ?                ; 是否需要下移地板

.CODE 
; 創建視窗
WinMain3 proc

    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT

    invoke GetModuleHandle, NULL 
    mov hInstance,eax

    ; 初始化窗口類
    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET WndProc3
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
    mov   hwnd,eax 
    invoke SetTimer, hwnd, 1, updateInterval, NULL
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

; 視窗運行
WndProc3 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 

    .IF uMsg == WM_CREATE 
        
        ; 初始化遊戲資源
        call initializeCake1
        call SetBrushes

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
        
        ; 偵測向下鍵
        invoke GetAsyncKeyState, VK_DOWN
        test eax, 8000h
        jz skip_down_key

        cmp falling, TRUE             ; 如果目前沒有正在掉落的蛋糕，啟動掉落邏輯
        je skip_down_key
        
        mov falling, TRUE
        mov velocityX, 0
        mov velocityY, dropSpeed

    skip_down_key:
        ; 更新蛋糕狀態
        call update_cake
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
        
        ; 檢查是否與其他蛋糕或地面接觸
        cmp falling, FALSE
        je move_ground
        call check_collision
        cmp eax, TRUE
        je move_ground

    handle_collision:

        ; 碰撞音效
        invoke mciSendString, addr hitOpenCmd, NULL, 0, NULL
        invoke mciSendString, addr hitVolumeCmd, NULL, 0, NULL
        invoke mciSendString, addr hitPlayCmd, NULL, 0, NULL
        
        mov falling, FALSE                 ; 停止落下
        dec TriesRemaining                 ; 減少剩餘蛋糕數
        mov cakeY, initialcakeY            ; 初始化蛋糕 Y 座標
        mov velocityY, 0                   ; 初始化蛋糕 Y 方向速度

        invoke GetTickCount                ; 生成隨機數
        mov ebx, 2
        cdq
        idiv ebx
        cmp edx, 0
        jne from_right

        mov cakeX, initialcakeX            ; 初始化蛋糕 X 座標（左）
        mov velocityX, initialvelocityX    ; 初始化蛋糕 X 方向速度
        jmp end_update

    from_right:
        mov cakeX, initialcakeX1           ; 初始化蛋糕 X 座標（右）
        mov velocityX, initialvelocityX1   ; 初始化蛋糕 X 方向速度

    end_update:
        cmp moveDown, FALSE                ; 判斷是否需移動地板
        je skip_move_ground

        mov eax, cakeHeight
        add needMove, eax

    skip_move_ground:
        invoke InvalidateRect, hWnd, NULL, FALSE      ; 刷新畫面
        inc currentCakeIndex                          ; 下一個蛋糕
        
        cmp gameover, TRUE
        je game_over

        cmp TriesRemaining, 0             ; 如果剩餘次數為 0，結束遊戲
        je game_over
        ret

    move_ground:
        ; 確認地板是否需要移動
        mov ebx, needMove
        cmp ebx, groundMoveCount
        jle skip_fall

        ; 地面移動
        add groundMoveCount, cakeMoveSize
        add ground, cakeMoveSize

        ; 蛋糕移動
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
        invoke InvalidateRect, hWnd, NULL, FALSE      ; 刷新畫面
        ret

    game_over:

        ; 顯示遊戲結束訊息
        invoke KillTimer, hWnd, 1
        cmp fromBreakout, TRUE
        je skipMsg
        invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
    skipMsg:
        invoke PostMessage, hWnd, WM_DESTROY, 0, 0
        ret

    .ELSEIF uMsg == WM_PAINT
        
        ; 繪製畫面
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke BitBlt, hdcMem, 0, 0, winWidth, winHeight, hdcBack, 0, 0, SRCCOPY  ; 覆蓋位圖
        call Update
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps

    .ELSEIF uMsg == WM_DESTROY 

        cmp fromBreakout, FALSE
        je getDestory

        ; 返回結果
        cmp TriesRemaining, 0
        jne notWin
        cmp gameover, FALSE
        jne notWin
        mov eax, 2
        call backBreakOut
        jmp getDestory
    notWin:
        mov eax, -2
        call backBreakOut

        ; 清理資源
    getDestory:
        mov winPosX, 400
        mov winPosY, 0
        mov fromBreakout, FALSE
        mov gameover, TRUE
        invoke KillTimer, hWnd, 1
        invoke DeleteObject, hBitmap
        invoke DeleteObject, hBackBitmap
        invoke DeleteObject, hBackBitmap2
        invoke DeleteDC, hdcMem
        invoke DeleteDC, hdcBack
        invoke ReleaseDC, hWnd, hdc
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, NULL
    
    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 

WndProc3 endp 

; 初始化遊戲
initializeCake1 PROC

    cmp fromBreakout, TRUE
    je skipMaxcakes
    mov maxCakes, 99
skipMaxcakes:
    mov cakeX, initialcakeX
    mov cakeY, initialcakeY
    mov ground, initialground
    mov velocityX, initialvelocityX
    mov velocityY, 0
    mov eax, maxCakes
    mov TriesRemaining, al
    mov groundMoveCount, 0
    mov needMove, 0
    mov currentCakeIndex, 0
    mov gameover, FALSE
    mov falling, FALSE
    mov edi, OFFSET cakes
    mov ecx, maxCakes
    imul ecx, 4
    xor eax, eax
    rep stosd

initializeCake1 ENDP

; 更新蛋糕位置
update_cake PROC

    cmp velocityX, 0               ; 無 X 方向速度，略過下列操作
    je movedown

    mov eax, cakeX                 ; 更新蛋糕 X 座標
    add eax, velocityX
    mov cakeX, eax

    mov eax, cakeX
    cmp eax, border_left           ; 蛋糕碰到左邊界
    jle reverse_x

    add eax, cakeWidth
    cmp eax, border_right          ; 蛋糕碰到右邊界
    jge reverse_x

movedown:
    mov eax, cakeY                 ; 更新蛋糕 Y 座標
    add eax, velocityY
    mov cakeY, eax
    jmp end_update

reverse_x:
    neg velocityX                  ; 反轉 X 方向速度

end_update:
    ret

update_cake ENDP

; 判斷是否持續下落，是return eax TRUE
check_collision PROC

    LOCAL cr:RECT

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

    mov ebx, cr.bottom              ; 檢查是否碰到地面
    cmp ebx, ground
    jge collision_found

    cmp ebx, winHeight              ; 檢查是否碰到螢幕底部
    jge collision_found

    cmp currentCakeIndex, 0         ; 如果還未有蛋糕，略過以下操作
    je check_end

check_other:
    mov ecx, currentCakeIndex       ; 檢查是否碰到其他蛋糕
    dec ecx

check_loop:
    cmp ecx, 0
    jl check_end

    mov ebx, SIZEOF RECT
    imul ebx, ecx

    mov eax, cakes[ebx].left        ; 現在的右邊界應大於等於之前的左邊界
    cmp cr.right, eax
    jle next_check
    
    mov eax, cakes[ebx].right       ; 現在的左邊界應小於等於之前的右邊界
    cmp cr.left, eax
    jge next_check

    mov eax, cakes[ebx].top         ; 如現在的底部在之前的頂部，發生碰撞
    cmp cr.bottom, eax
    jge game_not_over

next_check:
    dec ecx
    jmp check_loop

check_end:
    mov eax, TRUE                   ; 繼續落下
    ret

collision_found:
    cmp currentCakeIndex, 0         ; 如果為首個蛋糕，地板不用移動
    je move_down_false

    mov gameover, TRUE

move_down_false:
    mov moveDown, FALSE
    mov eax, FALSE
    ret

game_not_over:
    cmp cr.top, heighest         ; 如果沒有落在最上面的蛋糕，地板不用移動
    jge move_down_false

    mov moveDown, TRUE
    mov eax, FALSE
    ret

check_collision ENDP

; 更新畫面
Update PROC

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
    invoke DrawText, hdcMem, addr RemainingTriesText, -1, addr line1Rect, DT_CENTER

    ; 蛋糕
    mov eax, currentCakeIndex
    draw_cakes:
    push eax
    push ecx
    invoke SelectObject, hdcMem, brushes[eax * 4]  ; 選擇筆刷
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
    ret

Update ENDP

; 設定筆刷
SetBrushes PROC

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

SetBrushes ENDP

; 返回遊戲狀態
getCake1Game PROC
    mov eax, gameover
    ret
getCake1Game ENDP

; 設置遊戲來源
Cake1fromBreakOut PROC
    mov maxCakes, 10
    mov fromBreakout, 1
    mov winPosX, 1270
    mov winPosY, 0
    ret
Cake1fromBreakOut ENDP
end