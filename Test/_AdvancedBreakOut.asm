.386 
.model flat,stdcall 
option casemap:none

include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 
include winmm.inc

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

.CONST
stepSize EQU 10                ; 每次移動的像素數量
winWidth EQU 600               ; 視窗寬度
winHeight EQU 600              ; 視窗高度
winPosX EQU 400                ; 視窗 X 位置
winPosY EQU 0                  ; 視窗 Y 位置
timer EQU 20                   ; 視窗更新時間
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
divisor DWORD 180              ; 計算除數
line1Rect RECT <50, 555, 150, 615>  ; 時間區域
line2Rect RECT <400, 560, 600, 600> ; 訊息區域

initialplatformX EQU 240       ; 平台初始 X 座標
platformY EQU 530              ; 平台 Y 座標
initialballX EQU 300           ; 小球初始 X 座標
initialballY EQU 400           ; 小球初始 Y 座標
initialvelocityX EQU 0         ; 小球初始 X 方向速度
initialvelocityY EQU 10        ; 小球初始 Y 方向速度
initialspeed EQU 10            ; 小球初始速度
initialBrickRow EQU 5          ; 初始磚塊行數
initialgameTypeCount EQU 2     ; 初始遊戲種類

.DATA 
ClassName db "SimpleWinClass7",0 
AppName  db "AdvancedBreakOut",0
Text db "Window", 0
EndGame db "Game Over!", 0
TimeText db "Time:         ", 0
OtherGameText db "                                  ", 0

hBackBitmapName db "breakout_background.bmp",0

; 訊息條
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

; 音效
fallBrickOpenCmd db "open fallBrick.wav type mpegvideo alias fallBrickMusic", 0
fallBrickVolumeCmd db "setaudio fallBrickMusic volume to 100", 0
fallBrickPlayCmd db "play fallBrickMusic from 0", 0

brickOpenCmd db "open brick.wav type mpegvideo alias brickMusic", 0
brickVolumeCmd db "setaudio brickMusic volume to 100", 0
brickPlayCmd db "play brickMusic from 0", 0

specialBrickOpenCmd db "open specialBrick.wav type mpegvideo alias specialBrickMusic", 0
specialBrickVolumeCmd db "setaudio specialBrickMusic volume to 100", 0
specialBrickPlayCmd db "play specialBrickMusic from 0", 0

platformOpenCmd db "open platform.wav type mpegvideo alias platformMusic", 0
platformVolumeCmd db "setaudio platformMusic volume to 100", 0
platformPlayCmd db "play platformMusic from 0", 0

breakOutLoseOpenCmd db "open breakOutLose.wav type mpegvideo alias breakOutLoseMusic", 0
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
speed DWORD ?                  ; 球移動速度

brick DWORD brickNumY DUP(brickNumX DUP(?)) ; 磚塊矩陣
fallTimeCount DWORD ?          ; 磚塊掉落計時器
specialTimeCount DWORD ?       ; 特殊磚塊計時器
time DWORD ?                   ; 時間
timeCounter DWORD ?            ; 時間計時器
countOtherGameText DWORD ?     ; 訊息條時間
gameTypeCount DWORD ?          ; 遊戲種類
randomSeed DWORD ?             ; 隨機數種子

.CODE 
WinMain7 proc
    LOCAL wc:WNDCLASSEX 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT
    LOCAL msg:MSG
    
    invoke GetModuleHandle, NULL 
    mov    hInstance,eax 

    ; 定義窗口類別
    mov   wc.cbSize,SIZEOF WNDCLASSEX 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc7
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
WinMain7 endp


WndProc7 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
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

    .ELSEIF uMsg == WM_TIMER
        cmp gameOver, 1         ; 遊戲結束
        je game_over
        
        ; 更新磚塊、小球和平台邏輯
        call check_brick_fall
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
        ; 判斷磚塊碰撞
        call brick_collision

        ; 重繪視窗
        invoke InvalidateRect, hWnd, NULL, FALSE
        xor eax, eax
        ret

    game_over:
        ; 遊戲結束音效
        invoke mciSendString, addr breakOutLoseOpenCmd, NULL, 0, NULL
        invoke mciSendString, addr breakOutLoseVolumeCmd, NULL, 0, NULL
        invoke mciSendString, addr breakOutLosePlayCmd, NULL, 0, NULL

        invoke InvalidateRect, hWnd, NULL, FALSE
        invoke KillTimer, hWnd, 1
        invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, 0

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

    .ELSE
        ; 處理預設消息
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
        ret
    .ENDIF
    xor eax, eax
    ret
WndProc7 endp

initializeBreakOut PROC         ; 遊戲初始化
    mov platformX, initialplatformX
    mov ballX, initialballX
    mov ballY, initialballY
    mov velocityX, initialvelocityX
    mov velocityY, initialvelocityY
    mov speed, initialspeed
    mov fallTimeCount, fallTime
    mov specialTimeCount, specialTime
    mov gameTypeCount, initialgameTypeCount
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

initializeBrush PROC                ; 畫刷初始化
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

initializeBrick proc                ; 磚塊初始化
    mov esi, OFFSET brick
    mov eax, brickNumX
    mov ecx, initialBrickRow
    mul ecx
    mov ecx, eax
    mov ebx, 2                      ; 磚塊種類 (0為無，1為白色磚塊)

    invoke GetTickCount             ; 獲取當前的系統計時器值
    mov eax, edx
    cdq
newRandomBrick:
    div ebx
    cmp edx, 0
    mov [esi], edx
    add esi, 4
    loop newRandomBrick

initializeBrick ENDP

updateTime proc                     ; 更新遊戲時間
    mov eax, timeCounter
    add eax, timer
    mov timeCounter, eax            ; 確認已達到 1000ms
    cmp timeCounter, 1000
    jl skipAddTime
    mov timeCounter, 0
    inc time
skipAddTime:
    invoke SetBkMode, hdcMem, TRANSPARENT

    lea edi, TimeText + 14
    mov ecx, 4
    mov eax, time
    mov ebx, 10

convert_loop:
    xor edx, edx
    div ebx
    add dl, '0'                    ; 將餘數轉為 ASCII
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

    invoke DrawText, hdcMem, addr TimeText, -1, addr line1Rect, DT_CENTER
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

check_brick_fall PROC           ; 更新磚塊和特殊磚邏輯
    cmp fallTimeCount, 0
    jne no_brick_fall

    ; 磚塊下落音效
    invoke mciSendString, addr fallBrickOpenCmd, NULL, 0, NULL
    invoke mciSendString, addr fallBrickVolumeCmd, NULL, 0, NULL
    invoke mciSendString, addr fallBrickPlayCmd, NULL, 0, NULL

    ; 磚塊下落
    call Fall
    call newBrick
    mov fallTimeCount, fallTime

    ; 特數磚塊
    dec specialTimeCount
    cmp specialTimeCount, 0
    jne no_brick_fall
    call specialBrick
    mov specialTimeCount, specialTime
no_brick_fall:
    ret
check_brick_fall ENDP

update_ball PROC                   ; 更新球位置
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

reverse_x_left:                   ; X 方向速度反轉
    neg velocityX
    mov eax, ballRadius
    mov ballX, eax
    jmp end_update

reverse_x_right:                  ; X 方向速度反轉
    neg velocityX
    mov eax, winWidth
    sub eax, ballRadius
    mov ballX, eax
    jmp end_update

reverse_y_top:                    ; Y 方向速度反轉
    neg velocityY
    mov eax, ballRadius
    mov ballY, eax
    jmp end_update

reverse_y_bottom:                 ; Y 方向速度反轉
    mov eax, winHeight
    sub eax, ballRadius
    mov ballY, eax
    mov velocityX, 0
    mov velocityY, 0
    mov gameOver, 1

end_update:
    ret
update_ball ENDP

check_platform_collision PROC   ; 平台碰撞
    LOCAL angle:DWORD           ; 反彈角度

    mov eax, ballY
    add eax, ballRadius
    mov ebx, platformY
    cmp eax, ebx
    jl no_collision             ; 超過平台上方

    mov eax, ballY
    add ebx, platformHeight
    add ebx, ballRadius
    cmp eax, ebx
    jg no_collision             ; 超過平台下方

    mov eax, ballX
    add eax, ballRadius
    mov ebx, platformX
    cmp eax, ebx
    jl no_collision             ; 超過平台左方

    mov eax, ballX
    sub eax, ballRadius
    mov ebx, platformX
    add ebx, platformWidth
    cmp eax, ebx
    jg no_collision             ; 超過平台右方

    mov eax, ballX
    mov ebx, platformX
    cmp eax, ebx
    jl side_collision           ; 平台左側方

    mov ebx, platformX
    add ebx, platformWidth
    cmp eax, ebx
    jg side_collision           ; 平台右側方

    mov ebx, platformY
    sub ebx, ballRadius
    mov ballY, ebx              ; 將球移置平台上方

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
    cmp ballY, platformY
    jl check_leftup_corner

    mov eax, platformY
    add eax, platformHeight
    cmp ballY, eax
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
    cmp velocityX, 0
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
    INVOKE corner_collision, eax, ebx
    cmp eax, 1
    jne check_rightup_corner
    jmp do_corner_collision

check_rightup_corner:           ; 平台右上角落 (速度向30度)
    mov angle, 30
    mov eax, platformX
    add eax, platformWidth
    mov ebx, platformY
    INVOKE corner_collision, eax, ebx
    cmp eax, 1
    jne no_collision
    jmp do_corner_collision

check_leftbottom_corner:        ; 平台左下角落 (速度向210度)
    mov angle, 210
    mov eax, platformX
    mov ebx, platformY
    add ebx, platformHeight
    INVOKE corner_collision, eax, ebx
    cmp eax, 1
    jne check_rightbottom_corner
    jmp do_corner_collision

check_rightbottom_corner:       ; 平台右下角落 (速度向330度)
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
    ; 平台碰撞音效
    invoke mciSendString, addr platformOpenCmd, NULL, 0, NULL
    invoke mciSendString, addr platformVolumeCmd, NULL, 0, NULL
    invoke mciSendString, addr platformPlayCmd, NULL, 0, NULL
    dec fallTimeCount
no_collision:
    ret
check_platform_collision ENDP

brick_collision PROC           ; 磚塊碰撞
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
    invoke goSpecialBrick, [esi]

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
    invoke goSpecialBrick, [esi]
    jmp leftup

leftup:
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

    Invoke corner_collision, tempX, tempY
    cmp eax, 0
    je leftbottom
    invoke goSpecialBrick, [esi]
    cmp velocityX, 0
    jge skipLeftupX         
    neg velocityX           ; X 方向速度為正
skipLeftupX:
    cmp velocityY, 0
    jge leftbottom
    neg velocityY           ; Y 方向速度為正

leftbottom:
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

    Invoke corner_collision, tempX, tempY
    cmp eax, 0
    je rightup
    invoke goSpecialBrick, [esi]
    cmp velocityX, 0
    jge skipLeftbottomX
    neg velocityX           ; X 方向速度為正
skipLeftbottomX:
    cmp velocityY, 0
    jle rightup
    neg velocityY           ; Y 方向速度為負

rightup:
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

    Invoke corner_collision, tempX, tempY
    cmp eax, 0
    je rightbottom
    invoke goSpecialBrick, [esi]
    cmp velocityX, 0
    jle skipRightupX
    neg velocityX           ; X 方向速度為負
skipRightupX:
    cmp velocityY, 0
    jge rightbottom
    neg velocityY           ; Y 方向速度為正

rightbottom:
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

    Invoke corner_collision, tempX, tempY
    cmp eax, 0
    je no_brick_collision
    invoke goSpecialBrick, [esi]
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
brick_collision ENDP

corner_collision PROC,          ; 角落碰撞
    corner_X : DWORD,
    corner_Y : DWORD
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

newBrick proc                       ; 生成新磚塊
    call GetRandomSeed              ; 取得隨機種子
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
newBrick ENDP

specialBrick proc                   ; 生成特殊磚塊
    call GetRandomSeed              ; 取得隨機種子
    mov eax, randomSeed
    mov esi, OFFSET brick

    mov ebx, brickNumX              ; 磚塊類型數
    imul eax, eax, 1664525          ; 乘以係數 a（1664525 是常用值）
    add eax, 1013904223             ; 加上增量 c
    and eax, 7FFFFFFFh              ; 保證結果為正數
    mov randomSeed, eax             ; 更新隨機種子
    xor edx, edx
    div ebx
    shl edx, 2
    add esi, edx                    ; 隨機位置

    mov ebx, gameTypeCount          ; 存入遊戲類型 (2 ~ 5)
    mov [esi], ebx

    inc gameTypeCount
    cmp gameTypeCount, 6
    je initializeGameType
    ret

initializeGameType:
    mov gameTypeCount, 2
    ret
specialBrick ENDP

GetRandomSeed proc                  ; 取得隨機種子
    invoke QueryPerformanceCounter, OFFSET randomSeed
    ret
GetRandomSeed ENDP

Fall proc                           ; 磚塊下落
    mov esi, OFFSET brick + ((brickNumY-1) * brickNumX-1) * 4 
    mov edi, OFFSET brick + (brickNumY * brickNumX-1) * 4
    std                                           
    mov ecx, (brickNumY-1) * brickNumX                               
    rep movsd                                    
    cld       
    call checkBrick
    ret
Fall endp
    
checkBrick PROC                     ; 判斷磚塊是否下降到超過平台
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
DrawScreen ENDP

goSpecialBrick PROC, brickType:DWORD        ; 特殊磚塊 (音效與加分)
    cmp brickType, 1
    je noGame
    ; 特殊磚塊音效
    invoke mciSendString, addr specialBrickOpenCmd, NULL, 0, NULL
    invoke mciSendString, addr specialBrickVolumeCmd, NULL, 0, NULL
    invoke mciSendString, addr specialBrickPlayCmd, NULL, 0, NULL
    cmp brickType, 2
    je StartGame1
    cmp brickType, 3
    je StartGame2
    cmp brickType, 4
    je StartGame3
    cmp brickType, 5
    je StartGame4

StartGame1:                     ; 紅色磚塊 
    call checkAdvanced1A2B      ; 判斷 1A2B 是否正在進行
    cmp eax, 1
    je goGame1
    mov eax, 11
    call getOtherGame
    mov gameOver, 1
    ret
goGame1:                        ; 進入1A2B
    mov DWORD PTR [esi], 0
    call goAdvanced1A2B
    call Advanced1A2B
    ret
StartGame2:                     ; 黃色磚塊
    call checkCake1             ; 判斷 Cake1 是否正在進行
    cmp eax, 1
    je goGame2
    mov eax, 12
    call getOtherGame
    mov gameOver, 1
    ret
goGame2:                        ; 進入Cake1
    mov DWORD PTR [esi], 0
    call goCake1
    call Cake1
    ret
StartGame3:                     ; 綠色磚塊
    call checkCake2             ; 判斷 Cake2 是否正在進行
    cmp eax, 1
    je goGame3
    mov eax, 13
    call getOtherGame
    mov gameOver, 1
    ret
goGame3:                        ; 進入Cake2
    mov DWORD PTR [esi], 0
    call goCake2
    call Cake2
    ret
StartGame4:                     ; 藍色磚塊
    call checkMinesweeper       ; 判斷 MineSweeper 是否正在進行
    cmp eax, 1
    je goGame4
    mov eax, 14
    call getOtherGame
    mov gameOver, 1
    ret
goGame4:                        ; 進入MineSweeper
    mov DWORD PTR [esi], 0
    call goMinesweeper
    call Minesweeper

noGame:
    ; 白色磚塊音效
    invoke mciSendString, addr brickOpenCmd, NULL, 0, NULL
    invoke mciSendString, addr brickVolumeCmd, NULL, 0, NULL
    invoke mciSendString, addr brickPlayCmd, NULL, 0, NULL
    mov DWORD PTR [esi], 0
    ret

goSpecialBrick ENDP

getAdvancedBreakOutGame PROC    ; 確認遊戲是否結束
    mov eax, gameOver           ; 存入eax (傳入home)
    ret
getAdvancedBreakOutGame ENDP

getOtherGame proc               ; 判斷別的遊戲的輸贏
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
    lea esi, WinText1A2B            ; "You Win 1A2B"
    call WriteOtherGameString
    ret
Cake1Win:
    lea esi, WinTextCake1           ; "You Win Cake1"
    call WriteOtherGameString
    ret
Cake2Win:
    lea esi, WinTextCake2           ; "You Win Cake2"
    call WriteOtherGameString
    ret
MinesweeperWin:
    lea esi, WinTextMinesweeper     ; "You Win Minesweeper"
    call WriteOtherGameString
    ret
Advanced1A2BLose:
    lea esi, LoseText1A2B           ; "You Lose 1A2B"
    call WriteOtherGameString
    ret
Cake1Lose:
    inc speed                       ; "You Lose Cake1"
    lea esi, LoseTextCake1
    call WriteOtherGameString
    ret
Cake2Lose:
    inc speed                       ; "You Lose Cake2"
    lea esi, LoseTextCake2
    call WriteOtherGameString
    ret
MinesweeperLose:
    inc speed                       ; "You Lose Minesweeper"
    lea esi, LoseTextMinesweeper
    call WriteOtherGameString
    ret
Advanced1A2BGoing:
    inc speed                       ; "You Lose 1A2B"
    lea esi, GoingText1A2B
    call WriteOtherGameString
    ret
Cake1Going:
    lea esi, GoingTextCake1         ; "You Lose Cake1"
    call WriteOtherGameString
    ret
Cake2Going:
    lea esi, GoingTextCake2         ; "You Lose Cake2"
    call WriteOtherGameString
    ret
MinesweeperGoing:
    lea esi, GoingTextMinesweeper   ; "You Lose Minesweeper"
    call WriteOtherGameString
    ret
getOtherGame endp

WriteOtherGameString proc          ;寫入訊息字串
    mov countOtherGameText, 100
    lea edi, OtherGameText
next_char:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    cmp al, 0                      ; 檢查是否是 null 終止符
    jne next_char
    ret
WriteOtherGameString endp
    
end
