.386 
.model flat,stdcall 
option casemap:none 

EXTERN WinMain1@0: PROC
EXTERN WinMain2@0: PROC
EXTERN WinMain3@0: PROC
EXTERN WinMain4@0: PROC
EXTERN WinMain5@0: PROC
EXTERN WinMain6@0: PROC

EXTERN getAdvanced1A2BGame@0: PROC
EXTERN getCake1Game@0: PROC
EXTERN getCake2Game@0: PROC
EXTERN getMinesweeperGame@0: PROC

EXTERN Advanced1A2BfromBreakOut@0: PROC
EXTERN Cake1fromBreakOut@0: PROC
EXTERN Cake2fromBreakOut@0: PROC
EXTERN MinesweeperfromBreakOut@0: PROC

Advanced1A2B EQU WinMain1@0
GameBrick EQU WinMain2@0
Cake1 EQU WinMain3@0
Cake2 EQU WinMain4@0
Minesweeper EQU WinMain5@0
Tofu EQU WinMain6@0

checkAdvanced1A2B EQU getAdvanced1A2BGame@0
checkCake1 EQU getCake1Game@0
checkCake2 EQU getCake2Game@0
checkMinesweeper EQU getMinesweeperGame@0

goAdvanced1A2B EQU Advanced1A2BfromBreakOut@0
goCake1 EQU Cake1fromBreakOut@0
goCake2 EQU Cake2fromBreakOut@0
goMinesweeper EQU MinesweeperfromBreakOut@0

goSpecialBrick proto :DWORD
corner_collision proto :DWORD,:DWORD

include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 
include winmm.inc

.CONST
platformWidth EQU 120       ; 平台寬度
platformHeight EQU 15       ; 平台高度
stepSize DWORD 10             ; 每次移動的像素數量
winWidth EQU 600              ; 視窗寬度
winHeight EQU 600             ; 視窗高度
initialBrickRow EQU 5
brickNumX EQU 10
brickNumY EQU 27
brickTypeNum EQU 6
brickWidth EQU 60
brickHeight EQU 20
fallTime EQU 3
specialTime EQU 1
ballRadius EQU 10             ; 小球半徑
OFFSET_BASE EQU 150
timer EQU 20
speed DWORD 10
divisor DWORD 180
line1Rect RECT <20, 560, 120, 600>
line2Rect RECT <400, 560, 600, 600>

.DATA 
ClassName db "SimpleWinClass2",0 
AppName  db "AdvancedBreakOut",0
Text db "Window", 0
EndGame db "Game Over!", 0
TimeText db "Time:         ", 0
OtherGameText db "                                  ", 0

hBackBitmapName db "bitmap5.bmp",0

WinText1A2B db "You Win 1A2B", 0
WinTextCake1 db "You Win Cake1", 0
WinTextCake2 db "You Win Cake2", 0
WinTextMinesweeper db "You Win Minesweeper", 0
LoseText1A2B db "You Lose 1A2B", 0
LoseTextCake1 db "You Lose Cake1", 0
LoseTextCake2 db "You Lose Cake2", 0
LoseTextMinesweeper db "You Lose Minesweeper", 0
GoingText1A2B db "1A2B is still going !", 0
GoingTextCake1 db "Cake1 is still going !", 0
GoingTextCake2 db "Cake2 is still going !", 0
GoingTextMinesweeper db "Minesweeper is still going !", 0

offset_center DWORD 0
controlsCreated DWORD 0
platformX DWORD 270           ; 初始 X 座標
platformY DWORD 530           ; 初始 Y 座標
ballX DWORD 300               ; 小球 X 座標
ballY DWORD 400               ; 小球 Y 座標
velocityX DWORD 0             ; 小球 X 方向速度
velocityY DWORD 10            ; 小球 Y 方向速度
brick DWORD brickNumY DUP(brickNumX DUP(0))
fallTimeCount DWORD 5
specialTimeCount DWORD 5
gameOver DWORD 1
gameTypeCount DWORD 2
time DWORD 0
timeCounter DWORD 0
countOtherGameText DWORD 0
winPosX DWORD 400
winPosY DWORD 0

randomNum DWORD 0
randomSeed DWORD 0                 ; 隨機數種子


.DATA? 
hInstance HINSTANCE ? 
hBitmap HBITMAP ?
hBackBitmap HBITMAP ?
hBackBitmap2 HBITMAP ?
hdcMem HDC ?
hdcBack HDC ?

tempWidth DWORD ?
tempHeight DWORD ?
whiteBrush DWORD ?
redBrush DWORD ?
yellowBrush DWORD ?
greenBrush DWORD ?
blueBrush DWORD ?
purpleBrush DWORD ?
blackBrush DWORD ?
brickX DWORD ?
brickY DWORD ?

.CODE 
WinMain2 proc
    LOCAL wc:WNDCLASSEX 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT                   ; 定義 RECT 結構
    LOCAL msg:MSG
    
    invoke GetModuleHandle, NULL 
    mov    hInstance,eax 

    ; 定義窗口類別
    mov   wc.cbSize,SIZEOF WNDCLASSEX 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc2
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
    invoke SetTimer, hwnd, 1, timer, NULL
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

    .IF uMsg == WM_DESTROY 
        
        ; 設定遊戲結束旗標並釋放資源
        mov gameOver, 1
        invoke KillTimer, hWnd, 1
        invoke DeleteObject, hBitmap
        invoke DeleteDC, hdcMem
        invoke DeleteDC, hdcBack
        invoke ReleaseDC, hWnd, hdc
        invoke PostQuitMessage, NULL
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_CREATE
        ; 初始化遊戲資源
        call initializeBreakOut
        call initializeBrick
        call initializeBrush

        ; 加載位圖
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap, eax
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap2, eax

        ; 設置內存 DC
        invoke GetDC, hWnd
        mov hdc, eax
        invoke CreateCompatibleDC, hdc
        mov hdcMem, eax
        invoke CreateCompatibleDC, hdc
        mov hdcBack, eax
        invoke SelectObject, hdcMem, hBackBitmap
        invoke SelectObject, hdcBack, hBackBitmap2
        invoke ReleaseDC, hWnd, hdc
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_TIMER
        ; 處理定時器事件
        cmp gameOver, 1
        je game_over

        ; 更新遊戲計時器
        mov eax, timeCounter
        add eax, timer
        mov timeCounter, eax
        cmp eax, 1000
        jl skipAddTime
        mov timeCounter, 0
        inc time
    skipAddTime:

        ; 更新磚塊和特殊磚邏輯
        cmp fallTimeCount, 0
        jne no_brick_fall
        call Fall
        call newBrick
        mov eax, fallTime
        mov fallTimeCount, eax

        mov eax, specialTimeCount
        dec eax
        mov specialTimeCount, eax
        cmp eax, 0
        jne no_brick_fall
        call specialBrick
        mov eax, specialTime
        mov specialTimeCount, eax
    no_brick_fall:

        ; 更新小球和平台邏輯
        call update_ball
        call check_platform_collision

        ; 處理左鍵移動
        invoke GetAsyncKeyState, VK_LEFT
        test eax, 8000h
        jz skip_left
        mov eax, platformX
        cmp eax, stepSize
        jl skip_left
        sub eax, stepSize
        mov platformX, eax
    skip_left:

        ; 處理右鍵移動
        invoke GetAsyncKeyState, VK_RIGHT
        test eax, 8000h
        jz skip_right
        mov eax, platformX
        add eax, stepSize
        add eax, platformWidth
        cmp eax, winWidth
        jg skip_right
        mov eax, platformX
        add eax, stepSize
        mov platformX, eax
    skip_right:

        call brick_collision

        ; 重繪視窗
        invoke InvalidateRect, hWnd, NULL, FALSE
        xor eax, eax
        ret

    game_over:
        invoke InvalidateRect, hWnd, NULL, FALSE
        invoke KillTimer, hWnd, 1
        invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, 0
        ret

    .ELSEIF uMsg == WM_PAINT
        ; 處理視窗繪圖
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke BitBlt, hdcMem, 0, 0, winWidth, winHeight, hdcBack, 0, 0, SRCCOPY
        call DrawScreen
        call updateTime
        call updateOtherGameText
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps
        xor eax, eax
        ret

    .ELSE
        ; 處理預設消息
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
        ret
    .ENDIF
    xor eax, eax
    ret
WndProc2 endp


initializeBreakOut PROC
    mov platformX, 240
    mov ballX, 300
    mov ballY, 200
    mov velocityX, 0
    mov velocityY, 10
    mov fallTimeCount, 1
    mov specialTimeCount, 1
    mov gameOver, 0
    mov time, 0
    mov timeCounter, 0
    mov countOtherGameText, 0
    
    mov eax, brickNumX
    mov ebx, brickNumY
    mul ebx
    mov ecx, eax
    mov esi, OFFSET brick
LoopBrick:
    mov DWORD PTR [esi], 0
    add esi, 4
    loop LoopBrick
    ret
initializeBreakOut ENDP

initializeBrush PROC
   
    invoke CreateSolidBrush, 00FFFFFFh
    mov whiteBrush, eax

    invoke CreateSolidBrush, 003c14dch
    mov redBrush, eax

    invoke CreateSolidBrush, 0032C8C8h
    mov yellowBrush, eax

    invoke CreateSolidBrush, 00009100h
    mov greenBrush, eax

    invoke CreateSolidBrush, 00ff901eh
    mov blueBrush, eax

    invoke CreateSolidBrush, 00CC6699h
    mov purpleBrush, eax

    invoke CreateSolidBrush, 00000000h
    mov blackBrush, eax

    
    ret
initializeBrush ENDP

updateTime proc
    invoke SetBkMode, hdcMem, TRANSPARENT

    ; 初始化指標與變數
    lea edi, TimeText + 14        ; 定位到數字起始位址
    mov ecx, 4                     ; 預期最大數字位數
    mov eax, time                 ; 載入 score 的值
    mov ebx, 10                    ; 設置除數，確認非零

    ; 確保分母非零
    cmp ebx, 0
    je div_error                   ; 如果除數為 0，跳到錯誤處理

    ; 從右到左處理數字
convert_loop:
    xor edx, edx
    div ebx                        ; EDX:EAX / EBX，餘數存入 EDX
    add dl, '0'                    ; 將餘數轉為 ASCII
    dec edi                        ; 移到前一個位置
    mov [edi], dl                  ; 存入字元
    dec ecx                        ; 處理下一位數
    test eax, eax                  ; 如果 EAX 為 0，停止
    jnz convert_loop

    ; 填充前置空格
    mov al, ' '                    ; ASCII 空格
fill_spaces:
    dec edi                        ; 移到前一個位置
    mov [edi], al                  ; 填充空格
    dec ecx                        ; 減少剩餘空間
    jnz fill_spaces                ; 直到填滿

    ; 繪製文字
    invoke DrawText, hdcMem, addr TimeText, -1, addr line1Rect, DT_CENTER
    ret

div_error:
    ; 處理除以零錯誤（可以記錄日誌或調試）
    ret

updateTime ENDP

updateOtherGameText PROC
    cmp countOtherGameText, 0
    jle skip
    dec countOtherGameText
    invoke SetBkMode, hdcMem, TRANSPARENT
    invoke DrawText, hdcMem, addr OtherGameText, -1, addr line2Rect, DT_CENTER
skip:
    ret
updateOtherGameText ENDP

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
    jge reverse_x_right

    mov eax, ballY
    cmp eax, ballRadius           ; 碰到上邊界
    jle reverse_y_top

    mov eax, winHeight
    sub eax, ballRadius
    cmp ballY, eax                ; 碰到下邊界
    jge reverse_y_bottom

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
    mov eax, winHeight
    sub eax, ballRadius
    mov ballY, eax
    mov velocityX, 0
    mov velocityY, 0
    mov gameOver, 1

end_update:
    ret
update_ball ENDP

check_platform_collision PROC
    LOCAL angle:DWORD

    mov eax, ballY
    add eax, ballRadius
    mov ebx, platformY
    cmp eax, ebx
    jl no_collision

    mov eax, ballY
    add ebx, platformHeight
    add ebx, ballRadius
    cmp eax, ebx
    jg no_collision

    ; 檢查是否在平台的水平範圍內
    mov eax, ballX
    add eax, ballRadius
    mov ebx, platformX
    cmp eax, ebx
    jl no_collision

    mov eax, ballX
    sub eax, ballRadius
    mov ebx, platformX
    add ebx, platformWidth
    cmp eax, ebx
    jg no_collision

    mov eax, ballX
    mov ebx, platformX
    cmp eax, ebx
    jl side_collision

    mov ebx, platformX
    add ebx, platformWidth
    cmp eax, ebx
    jg side_collision
    mov ebx, platformY
    sub ebx, ballRadius
    mov ballY, ebx

above_collision:

    ; 碰撞處理
    
    mov eax, platformX
    sub eax, ballX
    add eax, OFFSET_BASE
    mov offset_center, eax

    ; 計算弧度
    fstp st(0)
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
    jmp has_collision

side_collision:
    mov eax, ballY
    mov ebx, platformY
    cmp eax, ebx
    jl check_leftup_corner

    mov eax, ballY
    mov ebx, platformY
    add ebx, platformHeight
    cmp eax, ebx
    jg check_leftbottom_corner

    mov eax, platformX
    add eax, platformWidth
    cmp eax, ballX
    jl check_right_side_collision

check_left_side_collision:
    mov eax, platformX
    sub eax, ballX
    cmp eax, ballRadius
    jle left_side_collision
    jmp no_collision

left_side_collision:
    mov eax, platformX
    sub eax, ballRadius
    mov ballX, eax
    mov eax, velocityX
    cmp eax, 0
    jl no_collision
    neg velocityX
    jmp has_collision
    
check_right_side_collision:
    mov eax, ballX
    sub eax, platformX
    sub eax, platformWidth
    cmp eax, ballRadius
    jle right_side_collision
    jmp no_collision

right_side_collision:

    mov eax, platformX
    add eax, platformWidth
    add eax, ballRadius
    mov ballX, eax
    mov eax, velocityX
    cmp eax, 0
    jg no_collision
    neg velocityX
    jmp has_collision

check_leftup_corner:
    mov angle, 150
    mov eax, platformX
    mov ebx, platformY
    INVOKE corner_collision, eax, ebx
    cmp eax, 1
    jne check_rightup_corner
    jmp do_corner_collision

check_rightup_corner:
    mov angle, 30
    mov eax, platformX
    add eax, platformWidth
    mov ebx, platformY
    INVOKE corner_collision, eax, ebx
    cmp eax, 1
    jne no_collision
    jmp do_corner_collision

check_leftbottom_corner:
    mov angle, 210
    mov eax, platformX
    mov ebx, platformY
    add ebx, platformHeight
    INVOKE corner_collision, eax, ebx
    cmp eax, 1
    jne check_rightbottom_corner
    jmp do_corner_collision

check_rightbottom_corner:
    mov angle, 330
    mov eax, platformX
    add eax, platformWidth
    mov ebx, platformY
    add ebx, platformHeight
    INVOKE corner_collision, eax, ebx
    cmp eax, 1
    jne no_collision

do_corner_collision:
    ; 將角度轉換為弧度：angle * π / 180
    fild angle              ; 載入角度
    fldpi                   ; 載入 π
    fmul                    ; angle * π
    fild divisor            ; 載入 180
    fdiv                    ; 完成弧度轉換

    ; 計算 velocityX = speed * cos(angle)
    fld st(0)               ; 將弧度載入堆疊
    fcos
    fild speed
    fmul
    fistp velocityX

    ; 計算 velocityY = speed * sin(angle)
    fld st(0)               ; 再次載入弧度
    fsin
    fild speed
    fmul
    fistp velocityY

has_collision:
    dec fallTimeCount
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

    ;這邊會突然有bug
    mov eax, brickNumY
    cmp eax, brickIndexY
    jle no_brick_collision

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
    cmp ebx, brickNumY
    jge left_brick_collision
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
    neg velocityY                  ; 反轉 Y 方向速度
    invoke goSpecialBrick, [esi]
    mov DWORD PTR [esi], 0         ; 移除磚塊

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
    neg velocityX                  ; 反轉 X 方向速度
    invoke goSpecialBrick, [esi]
    mov DWORD PTR [esi], 0         ; 移除磚塊
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

    Invoke corner_collision, tempX, tempY
    cmp eax, 0
    je leftbottom
    invoke goSpecialBrick, [esi]
    mov DWORD PTR [esi], 0
    cmp velocityX, 0
    jge skipLeftupX
    neg velocityX
skipLeftupX:
    cmp velocityY, 0
    jge leftbottom
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

    Invoke corner_collision, tempX, tempY
    cmp eax, 0
    je rightup
    invoke goSpecialBrick, [esi]
    mov DWORD PTR [esi], 0
    cmp velocityX, 0
    jge skipLeftbottomX
    neg velocityX
skipLeftbottomX:
    cmp velocityY, 0
    jle rightup
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

    Invoke corner_collision, tempX, tempY
    cmp eax, 0
    je rightbottom
    invoke goSpecialBrick, [esi]
    mov DWORD PTR [esi], 0
    cmp velocityX, 0
    jle skipRightupX
    neg velocityX
skipRightupX:
    cmp velocityY, 0
    jge rightbottom
    neg velocityY

rightbottom:
    mov esi, OFFSET brick
    mov eax, brickIndexX
    inc eax
    mov tempX, eax
    shl eax, 2
    add esi, eax
    mov eax, brickIndexY
    inc eax
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

    Invoke corner_collision, tempX, tempY
    cmp eax, 0
    je no_brick_collision
    invoke goSpecialBrick, [esi]
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


corner_collision PROC,
    corner_X : DWORD,
    corner_Y : DWORD
    LOCAL square_X : DWORD
    LOCAL square_Y : DWORD

    mov eax, ballX
    sub eax, corner_X
    imul eax, eax
    mov square_X, eax

    mov eax, ballY
    sub eax, corner_Y
    imul eax, eax
    mov square_Y, eax
    
    mov eax, ballRadius
    imul eax, eax
    mov edx, square_X
    add edx, square_Y
    cmp edx, eax
    jg no_corner_collision
    mov eax, 1
    jmp end_corner_collision

no_corner_collision:
    mov eax, 0
end_corner_collision:
    ret
corner_collision ENDP


initializeBrick proc
    mov esi, OFFSET brick

    mov eax, brickNumX
    mov ecx, initialBrickRow
    mul ecx
    mov ecx, eax
    mov ebx, 2

    invoke GetTickCount
    mov eax, edx
    cdq
initializenewRandomBrick:
    div ebx
    cmp edx, 0
    mov [esi], edx
    add esi, 4
    loop initializenewRandomBrick

initializeBrick ENDP

newBrick proc
    call GetRandomSeed              ; 取得隨機種子
    mov eax, randomSeed
    mov esi, OFFSET brick           ; 初始化磚塊陣列指標
    mov ecx, brickNumX              ; 磚塊數量
    mov ebx, 2           ; 磚塊類型數

newRandomBrick:
    ; 線性同餘生成器: (a * seed + c) % m
    imul eax, eax, 1664525          ; 乘以係數 a（1664525 是常用值）
    add eax, 1013904223             ; 加上增量 c
    and eax, 7FFFFFFFh             ; 保證結果為正數
    mov randomSeed, eax             ; 更新隨機種子
    xor edx, edx                    ; 清除 edx
    div ebx                         ; 獲得隨機類型
    mov [esi], edx                  ; 將類型存入陣列
    add esi, 4                      ; 移動到下一個位置
    loop newRandomBrick             ; 重複

    ret

newBrick ENDP

specialBrick proc
    call GetRandomSeed              ; 取得隨機種子
    mov eax, randomSeed
    mov esi, OFFSET brick           ; 初始化磚塊陣列指標

    mov ebx, brickNumX           ; 磚塊類型數
    
    mov ebx, brickTypeNum
    imul eax, eax, 1664525          ; 乘以係數 a（1664525 是常用值）
    add eax, 1013904223             ; 加上增量 c
    and eax, 7FFFFFFFh             ; 保證結果為正數
    mov randomSeed, eax             ; 更新隨機種子
    xor edx, edx                    ; 清除 edx
    div ebx                         ; 獲得隨機類型
    shl edx, 2
    add esi, edx

    mov ebx, gameTypeCount
    mov [esi], ebx

    inc gameTypeCount
    cmp gameTypeCount, 6
    je initializeGameType
    ret

initializeGameType:
    mov gameTypeCount, 2

    ret
specialBrick ENDP

GetRandomSeed proc
    invoke QueryPerformanceCounter, OFFSET randomSeed
    ret
GetRandomSeed ENDP


Fall proc
    mov esi, OFFSET brick + ((brickNumY-1) * brickNumX-1) * 4 
    mov edi, OFFSET brick + (brickNumY * brickNumX-1) * 4
    std                                           
    mov ecx, (brickNumY-1)*brickNumX                               
    rep movsd                                    
    cld       
    call checkBrick
    ret
Fall endp
    
checkBrick PROC
    mov esi, OFFSET brick + ((brickNumY-1) * brickNumX) * 4
    mov ecx, brickNumX
Loopcheck:
    cmp DWORD PTR [esi], 0
    jne hasBrick
    add esi, 4
    loop Loopcheck
    jmp noBrick

hasBrick:
    mov eax, 1
    mov gameOver, eax
noBrick:
    ret
checkBrick ENDP

DrawScreen PROC

    invoke SelectObject, hdcMem, purpleBrush

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
    mov eax, platformX
    add eax, platformWidth
    mov edx, platformY
    add edx, platformHeight
    mov [tempWidth], eax
    mov [tempHeight], edx
    invoke Rectangle, hdcMem, platformX, platformY, tempWidth, tempHeight

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

    cmp DWORD PTR [esi+eax*4], 1
    je WBrick
    cmp DWORD PTR [esi+eax*4], 2
    je RBrick
    cmp DWORD PTR [esi+eax*4], 3
    je YBrick
    cmp DWORD PTR [esi+eax*4], 4
    je GBrick
    cmp DWORD PTR [esi+eax*4], 5
    je BBrick

    jmp Continue

WBrick:
    push eax
    push ecx
    invoke SelectObject, hdcMem, whiteBrush
    pop ecx
    pop eax
    jmp startDrawBrick
RBrick:
    push eax
    push ecx
    invoke SelectObject, hdcMem, redBrush
    pop ecx
    pop eax
    jmp startDrawBrick
YBrick:
    push eax
    push ecx
    invoke SelectObject, hdcMem, yellowBrush
    pop ecx
    pop eax
    jmp startDrawBrick
GBrick:
    push eax
    push ecx
    invoke SelectObject, hdcMem, greenBrush
    pop ecx
    pop eax
    jmp startDrawBrick
BBrick:
    push eax
    push ecx
    invoke SelectObject, hdcMem, blueBrush
    pop ecx
    pop eax
    jmp startDrawBrick
PBrick:
    push eax
    push ecx
    invoke SelectObject, hdcMem, purpleBrush
    pop ecx
    pop eax
    
startDrawBrick:
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

goSpecialBrick PROC, brickType:DWORD
    cmp brickType, 2
    je StartGame1
    cmp brickType, 3
    je StartGame2
    cmp brickType, 4
    je StartGame3
    cmp brickType, 5
    je StartGame4
    jmp noGame

StartGame1:
    call checkAdvanced1A2B
    cmp eax, 1
    je goGame1
    mov eax, 11
    call getOtherGame
    mov gameOver, 1
    ret
goGame1:
    mov DWORD PTR [esi], 0
    call goAdvanced1A2B
    call Advanced1A2B
    ret
StartGame2:
    call checkCake1
    cmp eax, 1
    je goGame2
    mov eax, 12
    call getOtherGame
    mov gameOver, 1
    ret
goGame2:
    mov DWORD PTR [esi], 0
    call goCake1
    call Cake1
    ret
StartGame3:
    call checkCake2
    cmp eax, 1
    je goGame3
    mov eax, 13
    call getOtherGame
    mov gameOver, 1
    ret
goGame3:
    mov DWORD PTR [esi], 0
    call goCake2
    call Cake2
    ret
StartGame4:
    call checkMinesweeper
    cmp eax, 1
    je goGame4
    mov eax, 14
    call getOtherGame
    mov gameOver, 1
    ret
goGame4:
    mov DWORD PTR [esi], 0
    call goMinesweeper
    call Minesweeper

noGame:
    mov DWORD PTR [esi], 0
    ret

goSpecialBrick ENDP

getAdvancedBreakOutGame PROC
    mov eax, gameOver
    ret
getAdvancedBreakOutGame ENDP

getOtherGame proc
    mov countOtherGameText, 100
    lea edi, OtherGameText + 20      ; 設定字串的開始位置

    cmp eax, 1
    je Advanced1A2BWin
    cmp eax, 2
    je Cake1Win
    cmp eax, 3
    je Cake2Win
    cmp eax, 4
    je MinesweeperWin

    cmp eax, -1
    je Advanced1A2BLose
    cmp eax, -2
    je Cake1Lose
    cmp eax, -3
    je Cake2Lose
    cmp eax, -4
    je MinesweeperLose

    cmp eax, 11
    je Advanced1A2BGoing
    cmp eax, 12
    je Cake1Going
    cmp eax, 13
    je Cake2Going
    cmp eax, 14
    je MinesweeperGoing
    ret

Advanced1A2BWin:
    ; 寫入字串 "You Win 1A2B" 至 OtherGameText
    lea esi, WinText1A2B
    call WriteOtherGameString
    ret

Cake1Win:
    ; 寫入字串 "You Win Cake1" 至 OtherGameText
    lea esi, WinTextCake1
    call WriteOtherGameString
    ret

Cake2Win:
    ; 寫入字串 "You Win Cake2" 至 OtherGameText
    lea esi, WinTextCake2
    call WriteOtherGameString
    ret

MinesweeperWin:
    ; 寫入字串 "You Win Minesweeper" 至 OtherGameText
    lea esi, WinTextMinesweeper
    call WriteOtherGameString
    ret

Advanced1A2BLose:
    ; 寫入字串 "You Lose 1A2B" 至 OtherGameText
    lea esi, LoseText1A2B
    call WriteOtherGameString
    ret

Cake1Lose:
    ; 寫入字串 "You Lose Cake1" 至 OtherGameText
    lea esi, LoseTextCake1
    call WriteOtherGameString
    ret

Cake2Lose:
    ; 寫入字串 "You Lose Cake2" 至 OtherGameText
    lea esi, LoseTextCake2
    call WriteOtherGameString
    ret

MinesweeperLose:
    ; 寫入字串 "You Lose Minesweeper" 至 OtherGameText
    lea esi, LoseTextMinesweeper
    call WriteOtherGameString
    ret

Advanced1A2BGoing:
    ; 寫入字串 "You Lose 1A2B" 至 OtherGameText
    lea esi, GoingText1A2B
    call WriteOtherGameString
    ret

Cake1Going:
    ; 寫入字串 "You Lose Cake1" 至 OtherGameText
    lea esi, GoingTextCake1
    call WriteOtherGameString
    ret

Cake2Going:
    ; 寫入字串 "You Lose Cake2" 至 OtherGameText
    lea esi, GoingTextCake2
    call WriteOtherGameString
    ret

MinesweeperGoing:
    ; 寫入字串 "You Lose Minesweeper" 至 OtherGameText
    lea esi, GoingTextMinesweeper
    call WriteOtherGameString
    ret
getOtherGame endp

; 一個簡單的 WriteOtherGameString 函數來寫入字串
WriteOtherGameString proc
    ; 輸入：ESI = 字串地址
    lea edi, OtherGameText    ; 開始位置
next_char:
    mov al, [esi]                 ; 載入字串的當前字元
    mov [edi], al                 ; 存入記憶體
    inc esi                        ; 移至下一個字元
    inc edi                        ; 移至下一個位置
    cmp al, 0                      ; 檢查是否是 null 終止符
    jne next_char                 ; 如果不是，繼續寫入
    ret
WriteOtherGameString endp
    
end
