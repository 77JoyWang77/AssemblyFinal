.386 
.model flat,stdcall 
option casemap:none 

include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 

.CONST
cakeWidth EQU 50         ; 蛋糕寬度
cakeHeight EQU 20        ; 蛋糕高度
winWidth EQU 300         ; 視窗寬度
winHeight EQU 350        ; 視窗高度
border_left EQU 30
border_right EQU 270
maxCakes EQU 99          ; 最大蛋糕數量
initialcakeX EQU 50      ; 初始 X 座標
initialcakeY EQU 80      ; 初始 Y 座標
initialground EQU 300
initialvelocityX EQU 10  ; X 方向速度
dropSpeed EQU 10
time EQU 40              ; 更新速度，影響磚塊速度
cakeMoveSize EQU 5
heighest EQU 280

.DATA 
ClassName db "SimpleWinClass3", 0 
AppName  db "Cake", 0 
RemainingTriesText db "Remaining:   ", 0
EndGame db "Game Over!", 0

line1Rect RECT <20, 20, 280, 40>
cakes RECT maxCakes DUP(<0, 0, 0, 0>) ; 儲存蛋糕邊界

.DATA?
hInstance HINSTANCE ? 
hBitmap HBITMAP ?
hdcMem HDC ?
hBrush HBRUSH ?
blueBrush HBRUSH ?

tempWidth DWORD ?
tempHeight DWORD ?
cakeX DWORD ?                         ; X 座標
cakeY DWORD ?                         ; Y 座標
velocityX DWORD ?                     ; X 方向速度
velocityY DWORD ?                     ; Y 方向速度
currentCakeIndex DWORD ?              ; 當前蛋糕索引
gameover BOOL ?
TriesRemaining BYTE ?                ; 剩餘次數
groundMoveCount DWORD ?              ; 記錄地面已移動的像素總數
needMove DWORD ?
ground DWORD ?
moveDown BOOL ?
falling BOOL ?                       ; 是否有蛋糕正在掉落

.CODE 
WinMain3 proc
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT

    invoke GetModuleHandle, NULL 
    mov    hInstance,eax

    ; 初始化窗口類
    mov   wc.cbSize,SIZEOF WNDCLASSEX 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc3
    mov   wc.cbClsExtra,NULL 
    mov   wc.cbWndExtra,NULL 
    push  hInstance
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
            0, 0, tempWidth, tempHeight, NULL, NULL, hInstance, NULL
    mov   hwnd,eax 
    invoke SetTimer, hwnd, 1, time, NULL
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
        invoke KillTimer, hWnd, 1
        invoke DeleteObject, hBrush
        invoke DeleteObject, hBitmap
        invoke DeleteDC, hdcMem
        invoke ReleaseDC, hWnd, hdc
        invoke PostQuitMessage,NULL
    .ELSEIF uMsg==WM_CREATE 
        call initializeCake1
        INVOKE  GetDC,hWnd              
        mov     hdc,eax
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
        invoke ReleaseDC, hWnd, hdc
    .ELSEIF uMsg == WM_TIMER
        invoke GetAsyncKeyState, VK_SPACE
        test eax, 8000h ; 測試最高位
        jz skip_space_key

        ; 如果目前沒有正在掉落的蛋糕，啟動掉落邏輯
        cmp falling, TRUE
        je skip_space_key
        mov falling, TRUE

        ; 初始化新蛋糕位置
        mov velocityX, 0
        mov velocityY, dropSpeed

    skip_space_key:
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
        mov falling, FALSE
        dec TriesRemaining
        mov cakeX, initialcakeX
        mov cakeY, initialcakeY
        mov velocityX, initialvelocityX
        mov velocityY, 0
        
        cmp currentCakeIndex, 0
        je skip_move_ground
        cmp moveDown, FALSE
        je skip_move_ground
        mov eax, cakeHeight
        add needMove, eax

    skip_move_ground:
        invoke GetClientRect, hWnd, addr rect
        invoke FillRect, hdcMem, addr rect, hBrush
        call Update
        invoke InvalidateRect, hWnd, NULL, FALSE

        inc currentCakeIndex  ; 下一個蛋糕
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
        invoke GetClientRect, hWnd, addr rect
        invoke FillRect, hdcMem, addr rect, hBrush
        call Update
        invoke InvalidateRect, hWnd, NULL, FALSE
        ret
    game_over:
        ; 顯示遊戲結束訊息
        invoke KillTimer, hWnd, 1
        invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
        invoke DeleteObject, hBrush
        invoke DeleteObject, hBitmap
        invoke DeleteDC, hdcMem
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, 0
        ret
    
    .ELSEIF uMsg == WM_COMMAND
        mov eax, wParam

    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps
    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 
WndProc3 endp 

initializeCake1 PROC
    mov cakeX, initialcakeX
    mov cakeY, initialcakeY
    mov ground, initialground
    mov velocityX, initialvelocityX
    mov velocityY, 0
    mov TriesRemaining, maxCakes
    mov groundMoveCount, 0
    mov needMove, 0
    mov currentCakeIndex, 0
    mov gameover, FALSE
    mov falling, FALSE
initializeCake1 ENDP

; 更新蛋糕位置
update_cake PROC
    cmp velocityX, 0
    je movedown
    mov eax, cakeX
    add eax, velocityX
    mov cakeX, eax

    ; 邊界碰撞檢測（鏡面反射）
    mov eax, cakeX
    cmp eax, border_left           ; 碰到左邊界
    jle reverse_x

    add eax, cakeWidth
    cmp eax, border_right          ; 碰到右邊界
    jge reverse_x

movedown:
    mov eax, cakeY
    add eax, velocityY
    mov cakeY, eax
    jmp end_update                 ; 若無碰撞，結束

reverse_x:
    neg velocityX

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

    ; 檢查是否碰到地面
    mov ebx, cr.bottom
    cmp ebx, ground
    jge collision_found
    cmp ebx, winHeight
    jge collision_found

    cmp currentCakeIndex, 0
    je check_end
check_other:
    ; 檢查是否碰到其他蛋糕
    mov ecx, currentCakeIndex
    dec ecx
check_loop:
    cmp ecx, 0
    jl check_end

    ; 比較左邊界和右邊界是否重疊
    mov ebx, SIZEOF RECT
    imul ebx, ecx
check_left:
    mov eax, cakes[ebx].left
    cmp cr.right, eax
    jle next_check
    
check_right:
    mov eax, cakes[ebx].right
    cmp cr.left, eax
    jge next_check

check_bottom:
    mov eax, cakes[ebx].top
    cmp cr.bottom, eax
    jge game_not_over

next_check:
    dec ecx
    jmp check_loop

check_end:
    mov eax, TRUE
    ret

collision_found:
    cmp currentCakeIndex, 0
    je move_down_false
    mov gameover, TRUE
move_down_false:
    mov moveDown, FALSE
    mov eax, FALSE
    ret

game_not_over:
    cmp cr.top, heighest
    jge move_down_false
    mov moveDown, TRUE
    mov eax, FALSE
    ret
check_collision ENDP

; 更新畫面
Update PROC
    invoke CreateSolidBrush, 00c8c832h
    mov blueBrush, eax
    invoke SelectObject, hdcMem, blueBrush

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


end WinMain3