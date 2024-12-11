.386 
.model flat,stdcall 
option casemap:none 

corner_brick_collision proto :DWORD,:DWORD
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
platform_Width EQU 120       ; 平台寬度
platform_Height EQU 20       ; 平台高度
stepSize DWORD 10              ; 每次移動的像素數量
winWidth EQU 800              ; 視窗寬度
winHeight EQU 600             ; 視窗高度
ballX DWORD 400                 ; 小球 X 座標
ballY DWORD 500                 ; 小球 Y 座標
velocityX DWORD 0               ; 小球 X 方向速度
velocityY DWORD 10               ; 小球 Y 方向速度
ballRadius DWORD 10             ; 小球半徑
initialBrickRow EQU 20
brickNumX EQU 10
brickNumY EQU 28
brickTypeNum EQU 2
brick DWORD brickNumY DUP(brickNumX DUP(0))
brickWidth EQU 80
brickHeight EQU 20
divisor DWORD 180
offset_center DWORD 0
speed DWORD 10
brickNum DWORD 10
controlsCreated DWORD 0
fallTime DWORD 30
fallTimeCount DWORD 30
randomNum DWORD 0

.DATA? 
hInstance1 HINSTANCE ? 
CommandLine LPSTR ? 
tempWidth DWORD ?
tempHeight DWORD ?
tempWidth1 DWORD ?
tempHeight1 DWORD ?
hBrush DWORD ?
yellowBrush HBRUSH ?
hBitmap HBITMAP ?
hdcMem HDC ?
brickX DWORD ?
brickY DWORD ?

.CODE 
WinMain2 proc
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT                   ; 定義 RECT 結構
    LOCAL tempWinWidth:DWORD
    LOCAL tempWinHeight:DWORD

    CALL initializeBrick
    invoke GetModuleHandle, NULL 
    mov    hInstance1,eax 

    ; 定義窗口類別
    mov   wc.cbSize,SIZEOF WNDCLASSEX 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc2
    mov   wc.cbClsExtra,NULL 
    mov   wc.cbWndExtra,NULL 
    push  hInstance1
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
    mov tempWinWidth, eax

    mov eax, wr.bottom
    sub eax, wr.top
    mov tempWinHeight, eax

    ; 創建窗口
    invoke CreateWindowEx, NULL, ADDR ClassName, ADDR AppName, \
            WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, \
            0, 0, tempWinWidth, tempWinHeight, NULL, NULL, hInstance1, NULL
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
        invoke KillTimer, hWnd, 1
        ; 發送退出訊息
        
        ; 清理資源
        invoke DeleteObject, hBrush
        invoke DeleteObject, hBitmap
        invoke DeleteDC, hdcMem
        invoke ReleaseDC, hWnd, hdc
        invoke PostQuitMessage, NULL
        ret
    .ELSEIF uMsg == WM_CREATE
        ; 創建內存設備上下文 (hdcMem) 和位圖
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

        invoke CreateSolidBrush, 0032c8c8h  ; 創建紅色筆刷
        mov yellowBrush, eax                          ; 存筆刷句柄
        invoke ReleaseDC, hWnd, hdc
    .ELSEIF uMsg == WM_TIMER
        mov eax, fallTimeCount
        dec eax
        mov fallTimeCount, eax
        cmp eax, 0
        jne no_brick_fall

        CALL Fall
        CALL newBrick
        mov eax, fallTime
        mov fallTimeCount, eax
    no_brick_fall:
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

        invoke GetClientRect, hWnd, addr rect
        ;invoke FillRect, hdcMem, addr rect, hBrush
        call DrawScreen

        ; 重繪視窗
        invoke InvalidateRect, hWnd, NULL, FALSE

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
    jle reverse_x_left

    mov eax, winWidth
    sub eax, ballRadius
    cmp ballX, eax                ; 碰到右邊界
    jae reverse_x_right

    mov eax, ballY
    cmp eax, ballRadius           ; 碰到上邊界
    jle reverse_y_top

    mov eax, winHeight
    sub eax, ballRadius
    cmp ballY, eax                ; 碰到下邊界
    jae reverse_y_bottom

    jmp end_update                ; 若無碰撞，結束

reverse_x_left:
    neg velocityX
    mov eax, ballRadius
    mov ballX, eax
    jmp end_update

reverse_x_right:
    neg velocityX
    mov eax, winWidth
    sub eax, ballRadius
    mov ballX, eax
    jmp end_update

reverse_y_top:
    neg velocityY
    mov eax, ballRadius
    mov ballY, eax
    jmp end_update

reverse_y_bottom:
    neg velocityY
    mov eax, winHeight
    sub eax, ballRadius
    mov ballY, eax

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
    Local brickIndexX : DWORD
    Local brickIndexY : DWORD
    Local brickRemainderX : DWORD
    Local brickRemainderY : DWORD
    Local tempX : DWORD
    Local tempY : DWORD

    xor edx, edx
    mov eax, ballX
    mov ebx, brickWidth
    div ebx
    mov brickIndexX, eax
    mov brickRemainderX, edx

    xor edx, edx
    mov eax, ballY 
    mov ebx, brickHeight
    div ebx
    mov brickIndexY, eax
    mov brickRemainderY, edx

up_brick_collision:           ; brick + brickIndexX * 4 + (brickIndexY - 1) * brickNumX * 4
    cmp brickIndexY, 0
    jle bottom_brick_collision
    mov eax, brickRemainderY
    cmp eax, ballRadius
    jg bottom_brick_collision
    
    mov eax, brickIndexX
    shl eax, 2

    mov ebx, brickIndexY
    dec ebx
    imul ebx, brickNumX
    shl ebx, 2

    mov esi, OFFSET brick
    add esi, eax              ; esi += 水平偏移
    add esi, ebx              ; esi += 垂直偏移

    cmp DWORD PTR [esi], 0
    jne brick_collisionY


bottom_brick_collision:       ; brick + brickIndexX * 4 + (brickIndexY + 1) * brickNumX * 4
    mov ebx, brickNumY
    dec ebx
    cmp brickIndexY, ebx  
    jge left_brick_collision
    mov eax, brickHeight
    sub eax, brickRemainderY
    cmp eax, ballRadius
    jg left_brick_collision
    
    mov eax, brickIndexX
    shl eax, 2

    mov ebx, brickIndexY
    inc ebx
    imul ebx, brickNumX
    shl ebx, 2

    mov esi, OFFSET brick
    add esi, eax              ; esi += 水平偏移
    add esi, ebx              ; esi += 垂直偏移

    cmp DWORD PTR [esi], 0
    jne brick_collisionY
    jmp left_brick_collision

brick_collisionY:
    ; 碰撞處理
    mov DWORD PTR [esi], 0         ; 移除磚塊
    neg velocityY                  ; 反轉 Y 方向速度


left_brick_collision:         ; brick + (brickIndexX - 1) * 4 + brickIndexY * brickNumX * 4
    cmp brickIndexX, 0
    jle right_brick_collision
    mov eax, brickRemainderX
    cmp eax, ballRadius
    jg right_brick_collision
    
    mov eax, brickIndexX
    dec eax
    shl eax, 2

    mov ebx, brickIndexY

    imul ebx, brickNumX
    shl ebx, 2

    mov esi, OFFSET brick
    add esi, eax              ; esi += 水平偏移
    add esi, ebx              ; esi += 垂直偏移

    cmp DWORD PTR [esi], 0
    jne brick_collisionX


right_brick_collision:        ; brick + (brickIndexX + 1) * 4 + brickIndexY * brickNumX * 4
    mov ebx, brickNumX
    dec ebx
    cmp brickIndexX, ebx  
    jge corner_brick
    mov eax, brickWidth
    sub eax, brickRemainderX
    cmp eax, ballRadius
    jg corner_brick
    
    mov eax, brickIndexX
    inc eax
    shl eax, 2

    mov ebx, brickIndexY

    imul ebx, brickNumX
    shl ebx, 2

    mov esi, OFFSET brick
    add esi, eax              ; esi += 水平偏移
    add esi, ebx              ; esi += 垂直偏移

    cmp DWORD PTR [esi], 0
    jne brick_collisionX
    jmp corner_brick

brick_collisionX:
    ; 碰撞處理
    mov DWORD PTR [esi], 0         ; 移除磚塊
    neg velocityX                  ; 反轉 X 方向速度
    jmp corner_brick

corner_brick:

leftup:
    mov esi, OFFSET brick
    mov eax, brickIndexX
    dec eax
    cmp eax, 0
    jl rightup
    mov tempX, eax
    shl eax, 2
    add esi, eax
    mov eax, brickIndexY
    dec eax
    cmp eax, 0
    jl leftbottom
    mov tempY, eax
    mov ebx, brickNumX
    mul ebx
    shl eax, 2
    add esi, eax
    cmp DWORD PTR [esi], 0
    je leftbottom

    mov eax, brickIndexX
    mov ebx, brickWidth
    mul ebx
    mov tempX, eax

    mov eax, brickIndexY
    mov ebx, brickHeight
    mul ebx
    mov tempY, eax

    Invoke corner_brick_collision, tempX, tempY
    cmp eax, 0
    je leftbottom
    mov DWORD PTR [esi], 0
    mov eax, velocityX
    cmp eax, 0
    jge skipLeftupX
    neg velocityX
skipLeftupX:
    mov eax, velocityY
    cmp eax, 0
    jge no_brick_collision
    neg velocityY


leftbottom:
    mov esi, OFFSET brick
    mov eax, brickIndexX
    dec eax
    mov tempX, eax
    shl eax, 2
    add esi, eax
    mov eax, brickIndexY
    inc eax
    cmp eax, brickNumY
    jge rightup
    mov tempY, eax
    mov ebx, brickNumX
    mul ebx
    shl eax, 2
    add esi, eax
    cmp DWORD PTR [esi], 0
    je rightup

    mov eax, brickIndexX
    mov ebx, brickWidth
    mul ebx
    mov tempX, eax

    mov eax, brickIndexY
    inc eax
    mov ebx, brickHeight
    mul ebx
    mov tempY, eax

    Invoke corner_brick_collision, tempX, tempY
    cmp eax, 0
    je rightup
    mov DWORD PTR [esi], 0
    mov eax, velocityX
    cmp eax, 0
    jge skipLeftbottomX
    neg velocityX
skipLeftbottomX:
    mov eax, velocityY
    cmp eax, 0
    jle no_brick_collision
    neg velocityY

rightup:
    mov esi, OFFSET brick
    mov eax, brickIndexX
    inc eax
    cmp eax, brickNumX
    jge no_brick_collision
    mov tempX, eax
    shl eax, 2
    add esi, eax
    mov eax, brickIndexY
    dec eax
    cmp eax, 0
    jl rightbottom
    mov tempY, eax
    mov ebx, brickNumX
    mul ebx
    shl eax, 2
    add esi, eax
    cmp DWORD PTR [esi], 0
    je rightbottom

    mov eax, brickIndexX
    inc eax
    mov ebx, brickWidth
    mul ebx
    mov tempX, eax

    mov eax, brickIndexY
    mov ebx, brickHeight
    mul ebx
    mov tempY, eax

    Invoke corner_brick_collision, tempX, tempY
    cmp eax, 0
    je rightbottom
    mov DWORD PTR [esi], 0
    mov eax, velocityX
    cmp eax, 0
    jle skipRightupX
    neg velocityX
skipRightupX:
    mov eax, velocityY
    cmp eax, 0
    jge no_brick_collision
    neg velocityY

rightbottom:
    mov esi, OFFSET brick
    mov eax, brickIndexX
    inc eax
    mov tempX, eax
    shl eax, 2
    add esi, eax
    mov eax, brickIndexY
    dec eax
    cmp eax, brickNumY
    jge no_brick_collision
    mov tempY, eax
    mov ebx, brickNumX
    mul ebx
    shl eax, 2
    add esi, eax
    cmp DWORD PTR [esi], 0
    je no_brick_collision

    mov eax, brickIndexX
    inc eax
    mov ebx, brickWidth
    mul ebx
    mov tempX, eax

    mov eax, brickIndexY
    inc eax
    mov ebx, brickHeight
    mul ebx
    mov tempY, eax

    Invoke corner_brick_collision, tempX, tempY
    cmp eax, 0
    je no_brick_collision
    mov DWORD PTR [esi], 0
    mov eax, velocityX
    cmp eax, 0
    jle skipRightbottomX
    neg velocityX
skipRightbottomX:
    mov eax, velocityY
    cmp eax, 0
    jle no_brick_collision
    neg velocityY

no_brick_collision:
    ret
brick_collision ENDP



corner_brick_collision PROC,
    brick_X : DWORD,
    brick_Y : DWORD

    LOCAL square_X : DWORD
    LOCAL square_Y : DWORD


    mov eax, ballX
    sub eax, brick_X
    imul eax, eax
    mov square_X, eax

    mov eax, ballY
    sub eax, brick_Y
    imul eax, eax
    mov square_Y, eax
    
    mov eax, ballRadius
    imul eax, eax
    mov edx, square_X
    add edx, square_Y
    cmp edx, eax
    jg no_corner_brick_collision
    mov eax, 1
    jmp end_corner_brick_collision
   
no_corner_brick_collision:
    mov eax, 0

end_corner_brick_collision:
    ret

corner_brick_collision ENDP


initializeBrick proc
    mov esi, OFFSET brick

    mov eax, brickNumX
    mov ecx, initialBrickRow
    mul ecx
    mov ecx, eax
    mov ebx, brickTypeNum

    invoke GetTickCount
    mov eax, edx
    cdq
initializenewRandomBrick:
    div ebx
    mov [esi], edx
    add esi, 4
    loop initializenewRandomBrick

initializeBrick ENDP

newBrick proc
    mov esi, OFFSET brick
    mov ecx, brickNumX
    mov ebx, brickTypeNum
    invoke GetTickCount
    mov eax, edx
    cdq
newRandomBrick:
    div ebx
    mov [esi], edx
    add esi, 4
    loop newRandomBrick
    ret
newBrick ENDP

Fall proc
    mov esi, OFFSET brick + ((brickNumY-1) * brickNumX-1) * 4 
    mov edi, OFFSET brick + (brickNumY * brickNumX-1) * 4
    std                                           
    mov ecx, (brickNumY-1)*brickNumX                               
    rep movsd                                    
    cld       
    ret
Fall endp

DrawScreen PROC

    invoke SelectObject, hdcMem, yellowBrush

    ; 繪製小球
    mov eax, ballX
    sub eax, ballRadius
    mov ecx, ballY
    sub ecx, ballRadius
    mov edx, ballX
    add edx, ballRadius
    mov esi, ballY
    add esi, ballRadius
    invoke Ellipse, hdcMem, eax, ecx, edx, esi

    ; 繪製平台
    mov eax, platform_X
    add eax, platform_Width
    mov edx, platform_Y
    add edx, platform_Height
    mov [tempWidth], eax
    mov [tempHeight], edx
    invoke Rectangle, hdcMem, platform_X, platform_Y, tempWidth, tempHeight

    ; 繪製磚塊
    mov esi, OFFSET brick
    mov eax, 0
    mov ecx, brickNumY
DrawBrickRow:
    push ecx
    mov ecx, brickNumX
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
    invoke Rectangle, hdcMem, brickX, brickY, tempWidth, tempHeight
    pop ecx
    pop eax
    Continue:
        
    inc eax
    dec ecx
    cmp ecx, 0
    jne DrawBrickCol
    pop ecx
    dec ecx
    cmp ecx, 0
    jne DrawBrickRow
    ret
DrawScreen ENDP
end
