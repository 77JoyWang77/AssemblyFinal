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
stepSize DWORD 5              ; 每次移動的像素數量
winWidth DWORD 800              ; 視窗寬度
winHeight DWORD 600             ; 視窗高度
ballX DWORD 200                 ; 小球 X 座標
ballY DWORD 100                 ; 小球 Y 座標
velocityX DWORD 0               ; 小球 X 方向速度
velocityY DWORD 10               ; 小球 Y 方向速度
ballRadius DWORD 10             ; 小球半徑
divisor DWORD 180
offset_center DWORD 0
speed DWORD 10

.DATA? 
hInstance HINSTANCE ? 
CommandLine LPSTR ? 
tempWidth DWORD ?
tempHeight DWORD ?
hBrush DWORD ?

.CODE 
Home PROC 
start: 
    
    invoke GetModuleHandle, NULL 
    mov    hInstance,eax 
    invoke GetCommandLine
    mov CommandLine,eax
    invoke WinMain2, hInstance,NULL,CommandLine, SW_SHOWDEFAULT 
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

    .IF uMsg==WM_DESTROY 
        invoke PostQuitMessage,NULL 
        invoke KillTimer, hWnd, 1
    .ELSEIF uMsg == WM_TIMER
        ; 更新小球位置
        call update_ball

        ; 檢測平台碰撞
        call check_platform_collision

        ; 重繪視窗
        invoke InvalidateRect, hWnd, NULL, TRUE
        
    .ELSEIF uMsg == WM_KEYDOWN
        .IF wParam == VK_LEFT
            mov eax, platform_X
            cmp eax, stepSize
            jl skip_left          ; 避免平台移出左邊界
            mov eax, platform_X
            sub eax, stepSize
            mov platform_X, eax
        .ENDIF

        .IF wParam == VK_RIGHT
            mov eax, platform_X
            add eax, stepSize
            add eax, platform_Width
            mov ecx, 800           ; 視窗寬度
            cmp eax, ecx
            jg skip_right         ; 避免平台移出右邊界
            mov eax, platform_X
            add eax, stepSize
            mov platform_X, eax
        .ENDIF

        skip_left:
        skip_right:
        ; 重新繪製視窗
        invoke InvalidateRect, hWnd, NULL, TRUE

    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke GetClientRect, hWnd, addr rect
        RGB    200,200,50
        invoke SelectObject, hdc, eax
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

    ; 碰撞處理
    ; 計算接觸點的水平偏移（相對於平台中心）
    mov eax, ballX
    mov ebx, platform_X
    add ebx, platform_Width
    shr ebx, 1                   ; 平台中心點
    sub eax, ebx                 ; 偏移量 = ballX - 平台中心

    ; 根據偏移量計算反彈角度，平台寬度為 120，角度範圍從 30 度到 150 度
    ; 偏移量範圍是 [-60, 60]，對應角度範圍 [30, 150]
    mov ebx, platform_Width
    shr ebx, 1                   ; 半平台寬度
    imul eax, 60                 ; 計算偏移，放大因子
    idiv ebx                     ; 計算偏移比例 (-60 到 +60)

    ; 根據偏移量計算反彈角度
    add eax, 90                  ; 反彈角度範圍調整到 30 到 150 度
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
end
