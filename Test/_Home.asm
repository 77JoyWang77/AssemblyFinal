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

WinMain2 proto :DWORD,:DWORD,:DWORD,:DWORD 
include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 

.DATA 
ClassName db "SimpleWinClass",0 
AppName  db "Home",0 
Text db "Window", 0
platform_X DWORD 350           ; 初始 X 座標
platform_Y DWORD 550           ; 初始 Y 座標
platform_Width DWORD 120       ; 平台寬度
platform_Height DWORD 20       ; 平台高度
stepSize DWORD 10              ; 每次移動的像素數量
winWidth DWORD 800              ; 視窗寬度
winHeight DWORD 600             ; 視窗高度
ballX DWORD 400                 ; 小球 X 座標
ballY DWORD 400                 ; 小球 Y 座標
velocityX DWORD 0               ; 小球 X 方向速度
velocityY DWORD 10               ; 小球 Y 方向速度
ballRadius DWORD 10             ; 小球半徑
brickNumX EQU 10
brickNumY EQU 8
brick DWORD brickNumY DUP(brickNumX DUP(1))
brickWidth EQU 80
brickHeight EQU 20
divisor DWORD 180
offset_center DWORD 0
speed DWORD 10
brickNum DWORD 10
controlsCreated DWORD 0

.DATA? 
hInstance1 HINSTANCE ? 
CommandLine LPSTR ? 
tempWidth DWORD ?
tempHeight DWORD ?
tempWidth1 DWORD ?
tempHeight1 DWORD ?
hBrush DWORD ?

.CODE 
Home PROC 
start: 
    
    invoke GetModuleHandle, NULL 
    mov    hInstance1,eax 
    invoke GetCommandLine
    mov CommandLine,eax
    invoke WinMain2, hInstance1,NULL,CommandLine, SW_SHOWDEFAULT 
    ret
Home ENDP

WinMain2 proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD 
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT                   ; 定義 RECT 結構

    ; 定義窗口類別
    mov   wc.cbSize,SIZEOF WNDCLASSEX 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc2
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
    mov wr.right, 800
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
WinMain2 endp


WndProc2 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT
    LOCAL brickX, brickY:DWORD

    .IF uMsg==WM_DESTROY 
        invoke KillTimer, hWnd, 1
        ; 發送退出訊息
        invoke PostQuitMessage, NULL
        ret
    .ELSEIF uMsg == WM_TIMER
        ; 更新小球位置
        call update_ball

        ; 檢測平台碰撞
        call check_platform_collision

            invoke GetAsyncKeyState, VK_LEFT
            test eax, 8000h ; 測試最高位
            jz skip_left
            mov eax, platform_X
            cmp eax, stepSize
            jl skip_left
            sub eax, stepSize
            mov platform_X, eax
        skip_left:

        invoke GetAsyncKeyState, VK_RIGHT
            test eax, 8000h ; 測試最高位
            jz skip_right
            mov eax, platform_X
            add eax, stepSize
            add eax, platform_Width
            cmp eax, winWidth
            jg skip_right
            mov eax, platform_X
            add eax, stepSize
            mov platform_X, eax
        skip_right:
        call brick_collision

        ; 重繪視窗
        invoke InvalidateRect, hWnd, NULL, TRUE

    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke GetClientRect, hWnd, addr rect
        RGB    200,200,50
        invoke CreateSolidBrush, eax  ; 創建紅色筆刷
        mov hBrush, eax                          ; 存筆刷句柄
        invoke SelectObject, hdc, hBrush
        ; 繪製小球
        mov eax, ballX
        sub eax, ballRadius
        mov ecx, ballY
        sub ecx, ballRadius
        mov edx, ballX
        add edx, ballRadius
        mov esi, ballY
        add esi, ballRadius
        invoke Ellipse, hdc, eax, ecx, edx, esi

        ; 繪製平台
        mov eax, platform_X
        add eax, platform_Width
        mov edx, platform_Y
        add edx, platform_Height
        mov [tempWidth], eax
        mov [tempHeight], edx
        invoke Rectangle, hdc, platform_X, platform_Y, tempWidth, tempHeight

        ; 繪製磚塊
        mov esi, OFFSET brick
        mov eax, 0              ; eax 用於列循環
        mov ecx, brickNumY      ; ecx 用於行循環
    DrawBrickRow:
        push ecx
        mov ecx, brickNumX      ; 每行磚塊的數量
    DrawBrickCol:
        xor edx, edx
	    push eax
	    mov ebx, brickNumX
	    div ebx

        push edx
        mov ebx, brickHeight
        mul ebx
        mov brickY, eax
        pop edx
        
        mov eax, edx
        mov ebx, brickWidth
        mul ebx
        mov brickX, eax

        pop eax
        cmp DWORD PTR [esi+eax*4], 1  ; 檢查是否繪製此磚塊
        je DrawBrick1
        jmp Continue

    DrawBrick1:
        push eax
        push edx
        mov eax, brickX
        add eax, brickWidth
        mov edx, brickY
        add edx, brickHeight
        mov [tempWidth], eax
        mov [tempHeight], edx
        pop edx
        pop eax
        push eax
        push ecx
        invoke Rectangle, hdc, brickX, brickY, tempWidth, tempHeight
        pop ecx
        pop eax
    Continue:
        
        inc eax
        loop DrawBrickCol
        pop ecx
        loop DrawBrickRow

    endDrawBrick:
        invoke EndPaint, hWnd, addr ps

    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 
WndProc2 endp 

update_ball PROC
    ; 更新小球位置
    mov eax, ballX
    add eax, velocityX
    mov ballX, eax

    mov eax, ballY
    add eax, velocityY
    mov ballY, eax

    ; 邊界碰撞檢測（鏡面反射）
    mov eax, ballX
    cmp eax, ballRadius           ; 碰到左邊界
    jle reverse_x

    mov eax, winWidth
    sub eax, ballRadius
    cmp ballX, eax                ; 碰到右邊界
    jae reverse_x

    mov eax, ballY
    cmp eax, ballRadius           ; 碰到上邊界
    jle reverse_y

    mov eax, winHeight
    sub eax, ballRadius
    cmp ballY, eax                ; 碰到下邊界
    jae reverse_y

    jmp end_update                ; 若無碰撞，結束

reverse_x:
    mov eax, velocityX
    neg eax
    mov velocityX, eax
    jmp end_update

reverse_y:
    mov eax, velocityY
    neg eax
    mov velocityY, eax

end_update:
    ret
update_ball ENDP

check_platform_collision PROC
    ; 檢查是否在平台的水平範圍內
    mov eax, ballX
    mov ebx, platform_X
    cmp eax, ebx
    jl no_collision

    mov ecx, platform_Width
    add ebx, ecx
    cmp eax, ebx
    ja no_collision

    ; 檢查是否在平台的垂直範圍內
    mov eax, ballY
    mov ebx, platform_Y
    add eax, ballRadius
    cmp eax, ebx
    jl no_collision
    sub ebx, ballRadius
    mov ballY, ebx

    ; 碰撞處理
    mov eax, 150
    add eax, platform_X
    sub eax, ballX
    mov offset_center, eax

    ; 計算弧度
    fild offset_center           ; 載入角度值            
    fldpi                        ; 載入 π
    fild divisor                 ; 載入 180
    fdiv                         ; 計算 π / 180
    fmul                         ; 計算弧度

    ; 計算速度分量
    fld st(0)                    ; 弧度值
    fcos                         ; 計算 cos(角度)
    fild speed                   ; 載入速度大小 V
    fmul                         ; 計算 velocityX = cos(角度) * V
    fistp DWORD PTR [velocityX]               ; 存入 velocityX

    fld st(0)                    ; 弧度值
    fsin                         ; 計算 sin(角度)
    fild speed                   ; 載入速度大小 V
    fmul                         ; 計算 velocityY = sin(角度) * V
    fistp DWORD PTR [velocityY]               ; 存入 velocityY
    
    ; 反轉 Y 速度（反彈）
    neg velocityY

no_collision:
    ret
check_platform_collision ENDP

brick_collision PROC
    mov esi, OFFSET brick

    ; 計算列索引（col = ballX / brickWidth）
    mov eax, ballX
    xor edx, edx
    mov ecx, brickWidth
repeat_col:
    sub eax, ecx
    jl done_col
    inc edx
    jmp repeat_col
done_col:
    mov eax, edx  ; 列索引存入 EAX

    ; 計算行索引（row = ballY / brickHeight）
    mov edx, 0
    mov ecx, ballY
    xor ebx, ebx
    mov ebx, brickHeight
repeat_row:
    sub ecx, ebx
    jl done_row
    inc edx
    jmp repeat_row
done_row:
    mov ecx, edx  ; 行索引存入 ECX

    ; 計算偏移量並檢查有效磚塊
    mov ebx, brickNumX
    imul ecx, ebx
    add ecx, eax
    cmp DWORD PTR [esi + ecx * 4], 1
    jne no_collision

    ; 碰撞處理
    mov DWORD PTR [esi + ecx * 4], 0
    mov eax, velocityY
    neg eax
    mov velocityY, eax

no_collision:
    ret
brick_collision ENDP
end
