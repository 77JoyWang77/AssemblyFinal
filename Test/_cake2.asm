.386 
.model flat,stdcall 
option casemap:none 

include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 

.CONST
cakeHeight EQU 20       ; 蛋糕高度
stepSize EQU 50         ; 每次移動的像素數量
winWidth EQU 600        ; 視窗寬度
winHeight EQU 600       ; 視窗高度
border_right EQU 450
border_left EQU 150
maxCakes EQU 20         ; 最大蛋糕數量
ground EQU 560
initialcakeX EQU 200    ; 初始 X 座標
initialcakeY EQU 80     ; 初始 Y 座標
initialvelocityX EQU 5  ; X 方向速度
dropSpeed EQU 10
time EQU 20             ; 更新速度，影響磚塊速度

.DATA 
ClassName db "SimpleWinClass4", 0 
AppName  db "Cake", 0 
RemainingTriesText db "Remaining:   ", 0
EndGame db "Game Over!", 0

cakeWidth DWORD 100       ; 蛋糕寬度
cakeX DWORD 200                       ; 初始 X 座標
cakeY DWORD 80                        ; 初始 Y 座標
velocityX DWORD 5                     ; X 方向速度
velocityY DWORD 0                     ; Y 方向速度
currentCakeIndex DWORD 0              ; 當前蛋糕索引
cakes RECT maxCakes DUP(<0, 0, 0, 0>) ; 儲存蛋糕邊界
falling BOOL FALSE                    ; 是否有蛋糕正在掉落
gameover BOOL FALSE
TriesRemaining BYTE 20                ; 剩餘次數
line1Rect RECT <20, 20, 580, 40>
initialcolor DWORD 00c8c832h
colors DWORD 07165FBh, 0A5B0F4h, 0F0EBC4h, 0B2C61Fh, 0D3F0B8h, 0C3CC94h, 0E9EFA8h, 0D38A92h, 094C9E4h, 0B08DDDh, 0E1BFA2h, 09B97D8h, 09ADFCBh, 0A394D1h, 0BF95DCh, 09CE1D6h, 0E099C1h, 0DCD0A0h, 09B93D9h, 0D3D1B2h

.DATA? 
hInstance HINSTANCE ? 
tempWidth DWORD ?
tempHeight DWORD ?
hBitmap HBITMAP ?
hdcMem HDC ?
hBrush HBRUSH ?
brushes HBRUSH 20 DUP(?)

.CODE 
WinMain4 proc
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT

    mov ebx, 0
brushesloop:
    mov eax, colors[ebx * 4]
    invoke CreateSolidBrush, eax
    mov brushes[ebx * 4], eax
    inc ebx
    cmp ebx, 20
    jne brushesloop

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
WinMain4 endp

WndProc4 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
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
        call initializeCake2
        INVOKE  GetDC,hWnd              
        mov     hdc,eax
        invoke CreateCompatibleDC, hdc
        mov hdcMem, eax
        invoke CreateCompatibleBitmap, hdc, winWidth, winHeight
        mov hBitmap, eax
        invoke SelectObject, hdcMem, hBitmap

        invoke CreateSolidBrush, 00FFFFFFh
        mov hBrush, eax
        
        ; 填充背景顏色
        invoke GetClientRect, hWnd, addr rect
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
        je skip_fall
        call check_collision2
        cmp eax, TRUE
        je skip_fall

    handle_collision:
        mov ebx, SIZEOF RECT
        imul ebx, currentCakeIndex
        mov eax, cakes[ebx].left
        mov ecx, cakes[ebx].right
        sub ecx, eax
        mov cakeWidth, ecx
        mov falling, FALSE
        inc currentCakeIndex  ; 下一個蛋糕
        dec TriesRemaining
        mov cakeX, initialcakeX
        mov cakeY, initialcakeY
        mov velocityX, initialvelocityX
        mov velocityY, 0
        cmp gameover, TRUE
        je game_over
        cmp TriesRemaining, 0
        je game_over

    skip_fall:
        invoke GetClientRect, hWnd, addr rect
        invoke FillRect, hdcMem, addr rect, hBrush
        call Update2
        invoke InvalidateRect, hWnd, NULL, FALSE
        ret
    game_over:
        ; 顯示遊戲結束訊息
        
        invoke KillTimer, hWnd, 1
        invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
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
WndProc4 endp 

initializeCake2 PROC
    mov eax, 200
    mov cakeX, eax
    mov eax, 80
    mov cakeY, eax
    mov eax, 100
    mov cakeWidth, eax
    mov eax, 0
    mov currentCakeIndex, eax
    mov eax, 20
    mov TriesRemaining, al
    mov eax, FALSE
    mov gameover, eax
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
    jge check_goal

next_check:
    dec ecx
    jmp check_loop

check_end:
    mov eax, TRUE
    ret

collision_found:
    cmp currentCakeIndex, 0
    je dont_cut
    mov gameover, TRUE
check_goal:
    mov edx, cr.bottom
    cmp gr.top, edx
    je game_not_over
    mov gameover, TRUE
    jmp dont_cut
game_not_over:
    cmp currentCakeIndex, 0
    je dont_cut
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
end