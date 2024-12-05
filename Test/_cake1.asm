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
check_collision PROTO index:DWORD

.DATA 
ClassName db "SimpleWinClass", 0 
AppName  db "Cake", 0 
ButtonClassName db "button", 0 
cakeX DWORD 200           ; 初始 X 座標
cakeY DWORD 80           ; 初始 Y 座標
cakeWidth DWORD 50       ; 平台寬度
cakeHeight DWORD 20       ; 平台高度
stepSize DWORD 50              ; 每次移動的像素數量
winWidth DWORD 600              ; 視窗寬度
winHeight DWORD 600             ; 視窗高度
velocityX DWORD 5               ; 小球 X 方向速度
velocityY DWORD 0               ; 小球 Y 方向速度
border_right DWORD 450
border_left DWORD 150
maxCakes EQU 20                         ; 最大蛋糕數量
currentCakeIndex DWORD 0                   ; 當前蛋糕索引
cakes RECT maxCakes DUP(<0, 0, 0, 0>)      ; 蛋糕陣列，儲存每個蛋糕的邊界
falling BOOL FALSE                         ; 是否有蛋糕正在掉落
gameover BOOL FALSE
fallSpeed DWORD 5                          ; 蛋糕掉落速度

TriesRemaining  byte 20
RemainingTriesText db "Remaining:   ", 0
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
    mov tempWidth, eax

    mov eax, wr.bottom
    sub eax, wr.top
    mov tempHeight, eax

    ; 創建窗口
    invoke CreateWindowEx, NULL, ADDR ClassName, ADDR AppName, \
            WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, \
            0, 0, tempWidth, tempHeight, NULL, NULL, hInst, NULL
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
        invoke PostQuitMessage,0
    .ELSEIF uMsg==WM_CREATE 
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
        mov velocityY, 10

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
        cmp falling, TRUE
        jne skip_fall
        invoke check_collision, currentCakeIndex
        cmp eax, TRUE
        jne handle_collision

        ; 如果沒有碰撞，重繪蛋糕
        jmp skip_fall

    handle_collision:
        mov falling, FALSE
        inc currentCakeIndex  ; 下一個蛋糕
        dec TriesRemaining
        mov cakeX, 200
        mov cakeY, 80
        mov velocityX, 5
        mov velocityY, 0
        cmp gameover, TRUE
        je game_over
        cmp currentCakeIndex, maxCakes
        je game_over

    skip_fall:
        invoke InvalidateRect, hWnd, NULL, TRUE
        ret
    game_over:
        ; 顯示遊戲結束訊息
        invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, 0
        ret
    
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

        mov bl, 10
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
        invoke DrawText, hdc, addr RemainingTriesText, -1, addr line1Rect,DT_CENTER

        mov eax, currentCakeIndex
    draw_cakes:
        mov ebx, SIZEOF RECT
        imul ebx
        push eax
        invoke Rectangle, hdc, cakes[eax].left, cakes[eax].top, cakes[eax].right, cakes[eax].bottom
        pop eax
        idiv ebx
        dec eax
        cmp eax, 0
        jge draw_cakes

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
    cmp border_right, eax                ; 碰到右邊界
    jle reverse_x

movedown:
    mov eax, cakeY
    add eax, velocityY
    mov cakeY, eax
    jmp end_update                ; 若無碰撞，結束

reverse_x:
    neg velocityX

end_update:
    ret
update_cake ENDP

check_collision PROC index:DWORD
    LOCAL i:DWORD
    LOCAL cr:RECT

    mov eax, index
    mov ebx, SIZEOF RECT              ; 獲取每個 RECT 結構的大小
    imul ebx                   ; 計算 cakes[index] 的偏移量
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
    cmp ebx, winHeight
    jge collision_found

    cmp index, 0
    je check_end
check_other:
    ; 檢查是否碰到其他蛋糕
    mov ecx, index
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
    je game_not_over
    mov gameover, TRUE
game_not_over:
    mov eax, FALSE
    ret
check_collision ENDP
end
