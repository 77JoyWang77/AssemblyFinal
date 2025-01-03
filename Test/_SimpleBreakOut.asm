.386 
.model flat,stdcall 
option casemap:none 

include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 
include winmm.inc

goSpecialBrick1 proto :DWORD
corner_collision1 proto :DWORD,:DWORD

.CONST
stepSize EQU 10                ; 每次移動的像素數量
winWidth EQU 600               ; 視窗寬度
winHeight EQU 600              ; 視窗高度
winPosX EQU 400                ; 視窗 X 位置
winPosY EQU 0                  ; 視窗 Y 位置
timer EQU 15                   ; 視窗更新時間
platformWidth EQU 120          ; 平台寬度
platformHeight EQU 15          ; 平台高度
brickNumX EQU 10               ; 磚塊列數
brickNumY EQU 27               ; 磚塊行數
brickTypeNum EQU 6             ; 磚塊種類數量
brickWidth EQU 60              ; 磚塊寬度
brickHeight EQU 20             ; 磚塊高度
fallTime EQU 3                 ; 掉落計時（秒）
specialTime EQU 1              ; 特殊計時（秒）
ballRadius EQU 10              ; 小球半徑
OFFSET_BASE EQU 150            ; 平台反彈角度
speed DWORD 10                 ; 移動速度
divisor DWORD 180              ; 計算除數
line1Rect RECT <50, 555, 150, 615> ; 分數區域

initialplatformX EQU 240       ; 平台初始 X 座標
platformY EQU 530              ; 平台 Y 座標
initialballX EQU 300           ; 小球初始 X 座標
initialballY EQU 400           ; 小球初始 Y 座標
initialvelocityX EQU 0         ; 小球初始 X 方向速度
initialvelocityY EQU 10        ; 小球初始 Y 方向速度
initialBrickRow EQU 5          ; 初始磚塊行數

.DATA 
ClassName db "SimpleWinClass2",0 
AppName  db "BreakOut",0 
Text db "Window", 0
EndGame db "Game Over!", 0
ScoreText db "Score:         ", 0

hBackBitmapName db "bmp/simplebreakout_background.bmp",0

; 音效
fallBrickOpenCmd db "open wav/fallBrick.wav type mpegvideo alias fallBrickMusic", 0
fallBrickVolumeCmd db "setaudio fallBrickMusic volume to 100", 0
fallBrickPlayCmd db "play fallBrickMusic from 0", 0

brickOpenCmd db "open wav/brick.wav type mpegvideo alias brickMusic", 0
brickVolumeCmd db "setaudio brickMusic volume to 100", 0
brickPlayCmd db "play brickMusic from 0", 0

specialBrickOpenCmd db "open wav/specialBrick.wav type mpegvideo alias specialBrickMusic", 0
specialBrickVolumeCmd db "setaudio specialBrickMusic volume to 100", 0
specialBrickPlayCmd db "play specialBrickMusic from 0", 0

platformOpenCmd db "open wav/platform.wav type mpegvideo alias platformMusic", 0
platformVolumeCmd db "setaudio platformMusic volume to 100", 0
platformPlayCmd db "play platformMusic from 0", 0

breakOutLoseOpenCmd db "open wav/breakOutLose.wav type mpegvideo alias breakOutLoseMusic", 0
breakOutLoseVolumeCmd db "setaudio breakOutLoseMusic volume to 100", 0
breakOutLosePlayCmd db "play breakOutLoseMusic from 0", 0

gameOver DWORD 1               ; 遊戲結束

.DATA? 
hInstance HINSTANCE ?          ; 程式實例句柄
hBitmap HBITMAP ?              ; 位圖句柄
hBackBitmap HBITMAP ?          ; 背景位圖句柄
hBackBitmap2 HBITMAP ?         ; 第二背景位圖句柄
hdcMem HDC ?                   ; 記憶體設備上下文
hdcBack HDC ?                  ; 背景設備上下文

tempWidth DWORD ?              ; 視窗修正寬度
tempHeight DWORD ?             ; 視窗修正高度
whiteBrush DWORD ?             ; 白色畫刷
redBrush DWORD ?               ; 紅色畫刷
yellowBrush DWORD ?            ; 黃色畫刷
greenBrush DWORD ?             ; 綠色畫刷
blueBrush DWORD ?              ; 藍色畫刷
purpleBrush DWORD ?            ; 紫色畫刷
blackBrush DWORD ?             ; 黑色畫刷

brickX DWORD ?                 ; 磚塊 X 座標
brickY DWORD ?                 ; 磚塊 Y 座標
platformX DWORD ?              ; 平台 X 座標
offset_center DWORD ?          ; 平台中心偏移量

ballX DWORD ?                  ; 球 X 座標
ballY DWORD ?                  ; 球 Y 座標
velocityX DWORD ?              ; 球 X 方向速度
velocityY DWORD ?              ; 球 Y 方向速度

brick DWORD brickNumY DUP(brickNumX DUP(?)) ; 磚塊矩陣

fallTimeCount DWORD ?          ; 磚塊掉落計時器
specialTimeCount DWORD ?       ; 特殊磚塊計時器
score DWORD ?                  ; 分數
randomSeed DWORD ?             ; 隨機數種子


.CODE 
WinMain2 PROC
    LOCAL wc:WNDCLASSEX 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT                   ; 定義 RECT 結構
    LOCAL msg:MSG
    
    invoke GetModuleHandle, NULL 
    mov hInstance,eax 

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

    ; 設置目標客戶區大小
    mov wr.left, 0
    mov wr.top, 0
    mov eax, winWidth
    mov wr.right, eax
    mov eax, winHeight
    mov wr.bottom, eax

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
WinMain2 ENDP

WndProc2 PROC hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 

    .IF uMsg==WM_DESTROY 

        ; 設定遊戲結束旗標並釋放資源
        mov gameOver, 1
        invoke KillTimer, hWnd, 1
        invoke DeleteObject, hBitmap
        invoke DeleteDC, hdcMem
        invoke ReleaseDC, hWnd, hdc
        invoke PostQuitMessage, NULL

    .ELSEIF uMsg == WM_CREATE
        ; 初始化遊戲資源
        CALL initializeBreakOut1
        CALL initializeBrick1
        CALL initializeBrush1

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
    .ELSEIF uMsg == WM_TIMER
        cmp gameOver, 1     ; 遊戲結束
        je game_over
        ; 更新磚塊、小球和平台邏輯
        call check_brick_fall1
        call update_ball1
        call check_platform_collision1

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
        ; 判斷磚塊碰撞
        call brick_collision1

        ; 重繪視窗
        invoke InvalidateRect, hWnd, NULL, FALSE
        ret

    game_over:
        ; 遊戲結束音效
        invoke mciSendString, addr breakOutLoseOpenCmd, NULL, 0, NULL
        invoke mciSendString, addr breakOutLoseVolumeCmd, NULL, 0, NULL
        invoke mciSendString, addr breakOutLosePlayCmd, NULL, 0, NULL

        invoke KillTimer, hWnd, 1
        invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, 0

    .ELSEIF uMsg == WM_PAINT
        ; 處理視窗繪圖
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke BitBlt, hdcMem, 0, 0, winWidth, winHeight, hdcBack, 0, 0, SRCCOPY
        call DrawScreen1
        call updateScore
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps

    .ELSE
        ; 處理預設消息
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 
WndProc2 ENDP 

; 遊戲初始化
initializeBreakOut1 PROC        
    mov platformX, initialplatformX
    mov ballX, initialballX
    mov ballY, initialballY
    mov velocityX, initialvelocityX
    mov velocityY, initialvelocityY
    mov fallTimeCount, fallTime
    mov specialTimeCount, specialTime
    mov gameOver, 0
    mov score, 0
    
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
initializeBreakOut1 ENDP

; 畫刷初始化
initializeBrush1 PROC           
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
initializeBrush1 ENDP

; 磚塊初始化
initializeBrick1 PROC           
    mov esi, OFFSET brick
    mov eax, brickNumX
    mov ecx, initialBrickRow
    mul ecx
    mov ecx, eax
    mov ebx, 2                  ; 磚塊種類 (0為無，1為白色磚塊)

    invoke GetTickCount         ; 獲取當前的系統計時器值
    mov eax, edx
    cdq
newRandomBrick:
    div ebx
    cmp edx, 0
    mov [esi], edx
    add esi, 4
    loop newRandomBrick

initializeBrick1 ENDP

; 更新磚塊和特殊磚邏輯
check_brick_fall1 PROC          
    cmp fallTimeCount, 0
    jne no_brick_fall

    ; 磚塊下落音效
    invoke mciSendString, addr fallBrickOpenCmd, NULL, 0, NULL
    invoke mciSendString, addr fallBrickVolumeCmd, NULL, 0, NULL
    invoke mciSendString, addr fallBrickPlayCmd, NULL, 0, NULL

    ; 磚塊下落
    call Fall1
    call newBrick1
    mov fallTimeCount, fallTime

    ; 特數磚塊
    dec specialTimeCount
    cmp specialTimeCount, 0
    jne no_brick_fall
    call specialBrick1
    mov specialTimeCount, specialTime
no_brick_fall:
    ret
check_brick_fall1 ENDP

; 更新球位置
update_ball1 PROC                  
    mov eax, ballX
    add eax, velocityX
    mov ballX, eax

    mov eax, ballY
    add eax, velocityY
    mov ballY, eax

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
update_ball1 ENDP

; 平台碰撞
check_platform_collision1 PROC      
    LOCAL angle:DWORD       ; 反彈角度

    mov eax, ballY
    add eax, ballRadius
    mov ebx, platformY
    cmp eax, ebx
    jl no_collision         ; 超過平台上方

    mov eax, ballY
    add ebx, platformHeight
    add ebx, ballRadius
    cmp eax, ebx
    jg no_collision         ; 超過平台下方

    mov eax, ballX
    add eax, ballRadius
    mov ebx, platformX
    cmp eax, ebx
    jl no_collision         ; 超過平台左方

    mov eax, ballX
    sub eax, ballRadius
    mov ebx, platformX
    add ebx, platformWidth
    cmp eax, ebx
    jg no_collision         ; 超過平台右方

    mov eax, ballX
    mov ebx, platformX
    cmp eax, ebx
    jl side_collision       ; 平台左側方

    mov ebx, platformX
    add ebx, platformWidth
    cmp eax, ebx
    jg side_collision       ; 平台右側方

    mov ebx, platformY
    sub ebx, ballRadius
    mov ballY, ebx          ; 將球移置平台上方

above_collision:
    ; 碰撞處理 (速度向30~150度)
    mov eax, OFFSET_BASE
    add eax, platformX
    sub eax, ballX
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
    fistp DWORD PTR [velocityX]  ; 存入 velocityX

    fld st(0)                    ; 弧度值
    fsin                         ; 計算 sin(角度)
    fild speed                   ; 載入速度大小 V
    fmul                         ; 計算 velocityY = sin(角度) * V
    fistp DWORD PTR [velocityY]  ; 存入 velocityY
    
    ; 反轉 Y 速度（反彈）
    neg velocityY
    jmp has_collision

side_collision:                 ; 平台側方
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

check_left_side_collision:      ; 平台左側方 (速度X向右)
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
    
check_right_side_collision:     ; 平台右側方 (速度X向左)
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

check_leftup_corner:            ; 平台左上角落 (速度向150度)
    mov angle, 150
    mov eax, platformX
    mov ebx, platformY
    INVOKE corner_collision1, eax, ebx
    cmp eax, 1
    jne check_rightup_corner
    jmp do_corner_collision

check_rightup_corner:           ; 平台右上角落 (速度向30度)
    mov angle, 30
    mov eax, platformX
    add eax, platformWidth
    mov ebx, platformY
    INVOKE corner_collision1, eax, ebx
    cmp eax, 1
    jne no_collision
    jmp do_corner_collision

check_leftbottom_corner:        ; 平台左下角落 (速度向210度)
    mov angle, 210
    mov eax, platformX
    mov ebx, platformY
    add ebx, platformHeight
    INVOKE corner_collision1, eax, ebx
    cmp eax, 1
    jne check_rightbottom_corner
    jmp do_corner_collision

check_rightbottom_corner:       ; 平台右下角落 (速度向330度)
    mov angle, 330
    mov eax, platformX
    add eax, platformWidth
    mov ebx, platformY
    add ebx, platformHeight
    INVOKE corner_collision1, eax, ebx
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
    ; 平台碰撞音效
    invoke mciSendString, addr platformOpenCmd, NULL, 0, NULL
    invoke mciSendString, addr platformVolumeCmd, NULL, 0, NULL
    invoke mciSendString, addr platformPlayCmd, NULL, 0, NULL
    dec fallTimeCount
no_collision:
    ret
check_platform_collision1 ENDP

; 磚塊碰撞
brick_collision1 PROC           
    Local brickIndexX : DWORD       ; 球所在的磚塊 X 方向位置
    Local brickIndexY : DWORD       ; 球所在的磚塊 Y 方向位置
    Local brickRemainderX : DWORD   ; 球與上方磚塊的距離
    Local brickRemainderY : DWORD   ; 球與左方磚塊的距離
    Local tempX : DWORD             ; 暫存磚塊 X 方向位置
    Local tempY : DWORD             ; 暫存磚塊 Y 方向位置

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

    mov eax, brickNumY
    cmp eax, brickIndexY
    jle no_brick_collision

up_brick_collision:           ; brick + brickIndexX * 4 + (brickIndexY - 1) * brickNumX * 4
    cmp brickIndexY, 0
    jle bottom_brick_collision
    cmp brickRemainderY, ballRadius
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
    neg velocityY             ; 反轉 Y 方向速度
    invoke goSpecialBrick1, [esi]

left_brick_collision:         ; brick + (brickIndexX - 1) * 4 + brickIndexY * brickNumX * 4
    cmp brickIndexX, 0
    jle right_brick_collision
    cmp brickRemainderX, ballRadius
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
    jge leftup
    mov eax, brickWidth
    sub eax, brickRemainderX
    cmp eax, ballRadius
    jg leftup
    
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
    jmp leftup

brick_collisionX:
    neg velocityX             ; 反轉 X 方向速度
    invoke goSpecialBrick1, [esi]
    jmp leftup

leftup:                     ; 球撞擊左上方磚塊
    mov esi, OFFSET brick
    mov eax, brickIndexX
    dec eax
    cmp eax, 0
    jl rightup
    shl eax, 2
    add esi, eax
    mov eax, brickIndexY
    dec eax
    cmp eax, 0
    jl leftbottom
    mov ebx, brickNumX
    mul ebx
    shl eax, 2
    add esi, eax
    cmp DWORD PTR [esi], 0
    je leftbottom

    mov eax, brickIndexX
    mov ebx, brickWidth
    mul ebx
    mov tempX, eax          ; tempX = brickIndexX * brickWidth

    mov eax, brickIndexY
    mov ebx, brickHeight
    mul ebx
    mov tempY, eax          ; tempY = brickIndexY * brickHeight

    Invoke corner_collision1, tempX, tempY
    cmp eax, 0
    je leftbottom
    invoke goSpecialBrick1, [esi]
    cmp velocityX, 0
    jge skipLeftupX         
    neg velocityX           ; X 方向速度為正
skipLeftupX:
    cmp velocityY, 0
    jge leftbottom
    neg velocityY           ; Y 方向速度為正

leftbottom:                 ; 球撞擊左下方磚塊
    mov esi, OFFSET brick
    mov eax, brickIndexX
    dec eax
    shl eax, 2
    add esi, eax
    mov eax, brickIndexY
    inc eax
    cmp eax, brickNumY
    jge rightup
    mov ebx, brickNumX
    mul ebx
    shl eax, 2
    add esi, eax
    cmp DWORD PTR [esi], 0
    je rightup

    mov eax, brickIndexX
    mov ebx, brickWidth
    mul ebx
    mov tempX, eax          ; tempX = brickIndexX * brickWidth

    mov eax, brickIndexY
    inc eax
    mov ebx, brickHeight
    mul ebx
    mov tempY, eax          ; tempY = (brickIndexY + 1) * brickHeight

    Invoke corner_collision1, tempX, tempY
    cmp eax, 0
    je rightup
    invoke goSpecialBrick1, [esi]
    cmp velocityX, 0
    jge skipLeftbottomX
    neg velocityX           ; X 方向速度為正
skipLeftbottomX:
    cmp velocityY, 0
    jle rightup
    neg velocityY           ; Y 方向速度為負

rightup:                    ; 球撞擊右上方磚塊
    mov esi, OFFSET brick
    mov eax, brickIndexX
    inc eax
    cmp eax, brickNumX
    jge no_brick_collision
    shl eax, 2
    add esi, eax
    mov eax, brickIndexY
    dec eax
    cmp eax, 0
    jl rightbottom
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
    mov tempX, eax          ; tempX = (brickIndexX + 1) * brickWidth

    mov eax, brickIndexY
    mov ebx, brickHeight
    mul ebx
    mov tempY, eax          ; tempY = brickIndexY * brickHeight

    Invoke corner_collision1, tempX, tempY
    cmp eax, 0
    je rightbottom
    invoke goSpecialBrick1, [esi]
    cmp velocityX, 0
    jle skipRightupX
    neg velocityX           ; X 方向速度為負
skipRightupX:
    cmp velocityY, 0
    jge rightbottom
    neg velocityY           ; Y 方向速度為正

rightbottom:                ; 球撞擊右下方磚塊
    mov esi, OFFSET brick
    mov eax, brickIndexX
    inc eax
    shl eax, 2
    add esi, eax
    mov eax, brickIndexY
    inc eax
    cmp eax, brickNumY
    jge no_brick_collision
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
    mov tempX, eax          ; tempX = (brickIndexX + 1) * brickWidth

    mov eax, brickIndexY
    inc eax
    mov ebx, brickHeight
    mul ebx
    mov tempY, eax          ; tempY = (brickIndexY + 1) * brickHeight

    Invoke corner_collision1, tempX, tempY
    cmp eax, 0
    je no_brick_collision
    invoke goSpecialBrick1, [esi]
    mov eax, velocityX
    cmp eax, 0
    jle skipRightbottomX
    neg velocityX           ; X 方向速度為負
skipRightbottomX:
    mov eax, velocityY
    cmp eax, 0
    jle no_brick_collision
    neg velocityY           ; Y 方向速度為負

no_brick_collision:
    ret
brick_collision1 ENDP

; 角落碰撞
corner_collision1 PROC,    
    corner_X : DWORD,       ; 磚塊角落 X 方向座標
    corner_Y : DWORD        ; 磚塊角落 Y 方向座標
    LOCAL square_X : DWORD
    LOCAL square_Y : DWORD

    mov eax, ballX
    sub eax, corner_X
    imul eax, eax
    mov square_X, eax       ; square_X = (ballX - cornerX) ** 2

    mov eax, ballY
    sub eax, corner_Y
    imul eax, eax
    mov square_Y, eax       ; square_Y = (ballY - cornerY) ** 2
    
    mov eax, ballRadius
    imul eax, eax           ; eax = ballRadius ** 2
    mov edx, square_X
    add edx, square_Y       ; edx = square_X + square_Y
    cmp edx, eax
    jg no_corner_collision
    mov eax, 1
    jmp end_corner_collision

no_corner_collision:
    mov eax, 0
end_corner_collision:
    ret
corner_collision1 ENDP

; 更新分數
updateScore PROC
    invoke SetBkMode, hdcMem, TRANSPARENT

    lea edi, ScoreText + 14
    mov ecx, 4                      ; 最大數字位數
    mov eax, score
    mov ebx, 10
    cmp ebx, 0
    je div_error                    ; 如果除數為 0，跳到錯誤處理

convert_loop:
    xor edx, edx
    div ebx
    add dl, '0'                     ; 將餘數轉為 ASCII
    dec edi
    mov [edi], dl
    dec ecx
    test eax, eax
    jnz convert_loop

    mov al, ' '                    ; 設置前置空格
fill_spaces:
    dec edi
    mov [edi], al
    dec ecx
    jnz fill_spaces

    invoke DrawText, hdcMem, addr ScoreText, -1, addr line1Rect, DT_CENTER
    ret

div_error:
    ret
updateScore ENDP

; 生成新磚塊
newBrick1 PROC                      
    call GetRandomSeed1             ; 取得隨機種子
    mov eax, randomSeed
    mov esi, OFFSET brick
    mov ecx, brickNumX
    mov ebx, 2                      ; 磚塊類型 (0為無，1為白色)

newRandomBrick:
    imul eax, eax, 1664525          ; 乘以係數 a（1664525 是常用值）
    add eax, 1013904223             ; 加上增量 c
    and eax, 7FFFFFFFh              ; 保證結果為正數
    mov randomSeed, eax             ; 線性同餘生成器: (a * seed + c) % m
    xor edx, edx
    div ebx
    mov [esi], edx
    add esi, 4
    loop newRandomBrick

    ret
newBrick1 ENDP

; 生成特殊磚塊
specialBrick1 PROC                  
    call GetRandomSeed1             ; 取得隨機種子
    mov eax, randomSeed
    mov esi, OFFSET brick

    mov ebx, brickNumX              ; 磚塊數量
    imul eax, eax, 1664525          ; 乘以係數 a（1664525 是常用值）
    add eax, 1013904223             ; 加上增量 c
    and eax, 7FFFFFFFh              ; 保證結果為正數
    mov randomSeed, eax             ; 線性同餘生成器: (a * seed + c) % m
    xor edx, edx
    div ebx
    shl edx, 2
    add esi, edx                    ; 隨機位置
    
    mov ebx, brickTypeNum           ; 磚塊類型數
    imul eax, eax, 1664525          ; 乘以係數 a（1664525 是常用值）
    add eax, 1013904223             ; 加上增量 c
    and eax, 7FFFFFFFh              ; 保證結果為正數
    mov randomSeed, eax             ; 線性同餘生成器: (a * seed + c) % m
    xor edx, edx
    div ebx
    mov [esi], edx

    ret
specialBrick1 ENDP

; 取得隨機種子
GetRandomSeed1 PROC                 
    invoke QueryPerformanceCounter, OFFSET randomSeed
    ret
GetRandomSeed1 ENDP

; 磚塊下落
Fall1 PROC                          
    mov esi, OFFSET brick + ((brickNumY-1) * brickNumX-1) * 4   ; 倒數第二行磚塊
    mov edi, OFFSET brick + (brickNumY * brickNumX-1) * 4       ; 倒數第一行磚塊
    std                                           
    mov ecx, (brickNumY-1) * brickNumX                               
    rep movsd                                                   ; 複製磚塊資料到下一行
    cld       
    call checkBrick1
    ret
Fall1 ENDP

; 判斷磚塊是否下降到超過平台
checkBrick1 PROC                    
    mov esi, OFFSET brick + ((brickNumY-1) * brickNumX) * 4
    mov ecx, brickNumX
Loopcheck:
    cmp DWORD PTR [esi], 0
    jne hasBrick
    add esi, 4
    loop Loopcheck
    jmp noBrick

hasBrick:
    mov gameOver, 1
noBrick:
    ret
checkBrick1 ENDP

; 繪製畫面
DrawScreen1 PROC
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

    ; 判斷磚塊顏色
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

WBrick:                     ; 白色磚塊
    push eax
    push ecx
    invoke SelectObject, hdcMem, whiteBrush
    pop ecx
    pop eax
    jmp startDrawBrick
RBrick:                     ; 紅色磚塊
    push eax
    push ecx
    invoke SelectObject, hdcMem, redBrush
    pop ecx
    pop eax
    jmp startDrawBrick
YBrick:                     ; 黃色磚塊
    push eax
    push ecx
    invoke SelectObject, hdcMem, yellowBrush
    pop ecx
    pop eax
    jmp startDrawBrick
GBrick:                     ; 綠色磚塊
    push eax
    push ecx
    invoke SelectObject, hdcMem, greenBrush
    pop ecx
    pop eax
    jmp startDrawBrick
BBrick:                     ; 藍色磚塊
    push eax
    push ecx
    invoke SelectObject, hdcMem, blueBrush
    pop ecx
    pop eax
    jmp startDrawBrick
    
startDrawBrick:             ; 繪製磚塊
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
DrawScreen1 ENDP

; 特殊磚塊 (音效與加分)
goSpecialBrick1 PROC, brickType:DWORD       
    mov DWORD PTR [esi], 0
    cmp brickType, 1
    je brick1
    ; 特殊磚塊音效
    invoke mciSendString, addr specialBrickOpenCmd, NULL, 0, NULL
    invoke mciSendString, addr specialBrickVolumeCmd, NULL, 0, NULL
    invoke mciSendString, addr specialBrickPlayCmd, NULL, 0, NULL
    cmp brickType, 2
    je brick2
    cmp brickType, 3
    je brick3
    cmp brickType, 4
    je brick4
    cmp brickType, 5
    je brick5

brick1:                     ; 白色磚塊 (分數 + 1)
    ;白色磚塊音效
    invoke mciSendString, addr brickOpenCmd, NULL, 0, NULL
    invoke mciSendString, addr brickVolumeCmd, NULL, 0, NULL
    invoke mciSendString, addr brickPlayCmd, NULL, 0, NULL
    add score, 1
    ret
brick2:                     ; 紅色磚塊 (分數 + 6)
    add score, 6
    ret
brick3:                     ; 黃色磚塊 (分數 + 10)
    add score, 10
    ret
brick4:                     ; 綠色磚塊 (分數 + 18)
    add score, 18
    ret
brick5:                     ; 藍色磚塊 (分數 + 30)
    add score, 30
    ret

goSpecialBrick1 ENDP

; 返回遊戲狀態
getBreakOutGame PROC        
    mov eax, gameOver
    ret
getBreakOutGame ENDP

end