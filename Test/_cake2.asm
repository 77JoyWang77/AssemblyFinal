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
cakeHeight EQU 20         ; 蛋糕高度
winWidth EQU 300          ; 視窗寬度
winHeight EQU 350         ; 視窗高度
border_left EQU 30
border_right EQU 270
initialcakeX EQU 50       ; 初始 X 座標
initialcakeY EQU 80       ; 初始 Y 座標
initialvelocityX EQU 5    ; X 方向速度
initialvelocityX1 EQU -5  ; X 方向速度
initialcakeWidth EQU 100
initialground EQU 300
dropSpeed EQU 10
time EQU 30               ; 更新速度，影響磚塊速度
cakeMoveSize EQU 5
heighest EQU 280

.DATA 
ClassName db "SimpleWinClass4", 0 
AppName  db "Cake", 0 
RemainingTriesText db "Remaining:   ", 0
EndGame db "Game Over!", 0

hBackBitmapName db "cake2_background.bmp",0

hitOpenCmd db "open hit.wav type mpegvideo alias hitMusic", 0
hitVolumeCmd db "setaudio hitMusic volume to 100", 0
hitPlayCmd db "play hitMusic from 0", 0

maxCakes DWORD 99         ; 最大蛋糕數量
cakes RECT 99 DUP(<0, 0, 0, 0>) ; 儲存蛋糕邊界
line1Rect RECT <20, 20, 280, 40>
colors DWORD 07165FBh, 0A5B0F4h, 0F0EBC4h, 0B2C61Fh, 0D3F0B8h, 0C3CC94h, 0E9EFA8h, 0D38A92h, 094C9E4h, 0B08DDDh, 0E1BFA2h, 09B97D8h, 09ADFCBh, 0A394D1h, 0BF95DCh, 09CE1D6h, 0E099C1h, 0DCD0A0h, 09B93D9h, 0D3D1B2h
colors_count EQU ($ - colors) / 4
gameover BOOL TRUE
fromBreakout DWORD 0

winPosX DWORD 400
winPosY DWORD 0


.DATA? 
hInstance HINSTANCE ? 
hBitmap HBITMAP ?
hBackBitmap HBITMAP ?
hBackBitmap2 HBITMAP ?
hdcMem HDC ?
hdcBack HDC ?
brushes HBRUSH 99 DUP(?)

tempWidth DWORD ?
tempHeight DWORD ?
cakeWidth DWORD ?                   ; 蛋糕寬度
cakeX DWORD ?                       ; 初始 X 座標
cakeY DWORD ?                       ; 初始 Y 座標
velocityX DWORD ?                   ; X 方向速度
velocityY DWORD ?                   ; Y 方向速度
ground DWORD ?
currentCakeIndex DWORD ?            ; 當前蛋糕索引
TriesRemaining BYTE ?               ; 剩餘次數
groundMoveCount DWORD ? 
needMove DWORD ?
falling BOOL ?                  ; 是否有蛋糕正在掉落
moveDown BOOL ?

.CODE 
WinMain4 proc
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT

    invoke GetModuleHandle, NULL 
    mov    hInstance,eax

    ; 初始化窗口類
    mov   wc.cbSize,SIZEOF WNDCLASSEX 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc4
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
            winPosX, winPosY, tempWidth, tempHeight, NULL, NULL, hInstance, NULL
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
WinMain4 endp

WndProc4 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 

    .IF uMsg==WM_DESTROY 
        cmp fromBreakout, 0
        je getDestory
        cmp TriesRemaining, 0
        jne notWin
        cmp gameover, 0
        jne notWin
        mov eax, 3
        call backBreakOut
        jmp getDestory
    notWin:
        mov eax, -3
        call backBreakOut

    getDestory:
        mov winPosX, 400
        mov winPosY, 0
        mov fromBreakout, 0
        mov gameover, 1
        invoke KillTimer, hWnd, 1
        invoke DeleteObject, hBitmap
        invoke DeleteDC, hdcMem
        invoke ReleaseDC, hWnd, hdc
        invoke PostQuitMessage,NULL
    .ELSEIF uMsg==WM_CREATE 
        call SetBrushes2
        call initializeCake2

        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap, eax
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap2, eax
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
        call update_cake2
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
        call check_collision2
        cmp eax, TRUE
        je move_ground

    handle_collision:
        invoke mciSendString, addr hitOpenCmd, NULL, 0, NULL
        invoke mciSendString, addr hitVolumeCmd, NULL, 0, NULL
        invoke mciSendString, addr hitPlayCmd, NULL, 0, NULL
        mov ebx, SIZEOF RECT
        imul ebx, currentCakeIndex
        mov eax, cakes[ebx].left
        mov ecx, cakes[ebx].right
        sub ecx, eax
        mov cakeWidth, ecx
        mov falling, FALSE
        dec TriesRemaining
        mov cakeY, initialcakeY
        mov velocityY, 0
        invoke GetTickCount                ; 生成隨機數
        mov ebx, 2       ; 計算範圍大小
        cdq                        ; 擴展 EAX 為 64 位
        idiv ebx                   ; 除以範圍大小，餘數在 EAX
        cmp edx, 0
        jne Next
        mov cakeX, initialcakeX
        mov velocityX, initialvelocityX
        jmp Next1
    Next:
        mov eax, border_right
        sub eax, 20
        sub eax, cakeWidth
        mov cakeX, eax
        mov velocityX, initialvelocityX1
    Next1:

        cmp currentCakeIndex, 0
        je skip_move_ground
        cmp moveDown, FALSE
        je skip_move_ground
        mov eax, cakeHeight
        add needMove, eax

    skip_move_ground:
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
        invoke InvalidateRect, hWnd, NULL, FALSE
        ret
    game_over:
        invoke KillTimer, hWnd, 1
        cmp fromBreakout, 1
        je skipMsg
        invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
    skipMsg:
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, 0
        ret
    
    .ELSEIF uMsg == WM_COMMAND
        mov eax, wParam

    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke BitBlt, hdcMem, 0, 0, winWidth, winHeight, hdcBack, 0, 0, SRCCOPY  ; 覆蓋位圖
        call Update2
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps
    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 
WndProc4 endp 

initializeCake2 PROC
    cmp fromBreakout, 1
    je skipMaxcakes
    mov maxCakes, 99
skipMaxcakes:
    mov cakeX, initialcakeX
    mov cakeY, initialcakeY
    mov velocityX, initialvelocityX
    mov velocityY, 0
    mov ground, initialground
    mov cakeWidth, initialcakeWidth
    mov currentCakeIndex, 0
    mov eax, maxCakes
    mov TriesRemaining, al
    mov groundMoveCount, 0
    mov needMove, 0
    mov gameover, FALSE
    mov falling, FALSE
    mov edi, OFFSET cakes
    mov ecx, maxCakes
    imul ecx, 4
    xor eax, eax
    rep stosd
initializeCake2 ENDP

; 更新蛋糕位置
update_cake2 PROC
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
update_cake2 ENDP

; 判斷是否持續下落，是return eax TRUE
check_collision2 PROC
    LOCAL cr:RECT
    LOCAL goal:DWORD
    LOCAL gr:RECT

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
set_goal:
    mov eax, currentCakeIndex
    dec eax
    mov goal, eax
    mov ebx, SIZEOF RECT
    imul ebx
    mov ebx, cakes[eax].bottom
    mov gr.bottom, ebx
    mov ebx, cakes[eax].top
    mov gr.top, ebx
    mov ebx, cakes[eax].left
    mov gr.left, ebx
    mov ebx, cakes[eax].right
    mov gr.right, ebx

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
    jge collision_found

next_check:
    dec ecx
    jmp check_loop

check_end:
    mov eax, TRUE
    ret

collision_found:
    cmp currentCakeIndex, 0
    je dont_cut
    mov edx, cr.bottom
    cmp gr.top, edx
    je game_not_over
    mov gameover, TRUE
    mov moveDown, FALSE
    jmp dont_cut
game_not_over:
    mov moveDown, TRUE
    mov ebx, SIZEOF RECT
    imul ebx, goal
    mov eax, cakes[ebx].left
    cmp cr.left, eax
    jge check_right_cut
    mov cakes[ebx + 16].left, eax
check_right_cut:
    mov eax, cakes[ebx].right
    cmp cr.right, eax
    jle dont_cut
    mov cakes[ebx + 16].right, eax
dont_cut:
    mov eax, FALSE
    ret
check_collision2 ENDP

; 更新畫面
Update2 PROC
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
    ret
Update2 ENDP

SetBrushes2 PROC
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
SetBrushes2 ENDP

getCake2Game PROC
    mov eax, gameover
    ret
getCake2Game ENDP

Cake2fromBreakOut PROC
    mov winPosX, 1570
    mov winPosY, 0
    mov maxCakes, 10
    mov fromBreakout, 1
    ret
Cake2fromBreakOut ENDP

end