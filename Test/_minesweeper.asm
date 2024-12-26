.386 
.model flat,stdcall 
option casemap:none 

EXTERN getOtherGame@0: PROC
backBreakOut EQU getOtherGame@0

open_mine proto :DWORD,:DWORD
can_go_next proto :DWORD, :DWORD 

include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 
include winmm.inc

.DATA 
ClassName db "SimpleWinClass5", 0 
AppName  db "Minesweeper", 0 
ButtonClassName db "button", 0 
ButtonText0 db "-1", 0
ButtonText1 db "0", 0
ButtonText2 db "1", 0
ButtonText3 db "2", 0
ButtonText4 db "3", 0
ButtonText5 db "4", 0
ButtonText6 db "5", 0
ButtonText7 db "6", 0
ButtonText8 db "7", 0
ButtonText9 db "8", 0
RemainingFlagsText db "Flag:   ", 0
TimeText db "Time:     ", 0
WinGame  db "Win!", 0
LoseGame db "Game Over!", 0
ShowText db " ", 0

hMineBitmapName db "mine.bmp",0        ; 地雷圖案
hMineRedBitmapName db "mine_red.bmp",0 ; 地雷圖案(按到的)
hFlagBitmapName db "flag.bmp",0        ; 旗子圖案
hFlagRedBitmapName db "flag_red.bmp",0 ; 旗子圖案(插錯位置)
hBackBitmapName db "mine_background.bmp",0
boomOpenCmd db "open boom.wav type mpegvideo alias boomMusic", 0
boomVolumeCmd db "setaudio boomMusic volume to 100", 0
boomPlayCmd db "play boomMusic from 0", 0

winPosX DWORD 400
winPosY DWORD 0

borderX DWORD 80                   ; 初始 X 座標
borderY DWORD 160                  ; 初始 Y 座標
borderWidth DWORD 240              ; 平台寬度
borderHeight DWORD 240             ; 平台高度
winWidth DWORD 400                 ; 視窗寬度
winHeight DWORD 480                ; 視窗高度
line1Rect RECT <20, 60, 120, 140>  ; Remaining Flag Text 位置
line2Rect RECT <280, 60, 380, 140> ; Tine Text 位置
currentID DWORD 10                 ; 目前的按扭ID
mainh HWND ?                       ; 視窗句柄

mineWidth EQU 8                    ; 地圖的寬度(column數)
mineHeight EQU 8                   ; 地圖的高度(row數)
mineNum EQU 10                     ; 地雷數量(共有10個)
mineMapSize EQU 64                 ; 地圖按扭總數
minerandomSeed DWORD 0             ; 隨機數種子
MineX DWORD ?                      ; 按扭x座標(地圖最左上角為(0,0))
MineY DWORD ?                      ; 按扭y座標(地圖最左上角為(0,0))
DirX SDWORD ?                      ; x方向改變量
DirY SDWORD ?                      ; y方向改變量
endGamebool DWORD 1                ; 判定結束之varaible
hButton DWORD mineHeight DUP (mineWidth DUP(?))     ; 按扭句柄
mineMap SDWORD mineHeight DUP (mineWidth DUP (0))   ; 儲存地圖內容(-1:地雷.0~8:周遭地雷數量)
mineState SDWORD mineHeight DUP (mineWidth DUP (0)) ; 對應位置之狀態(0:未按開,1:已按開,2:插旗)
mineClicked SDWORD mineHeight DUP (mineWidth DUP(0)); 紀錄按扭是否已顯示按開(0:未按開,1:已顯示按開後狀態)
visited DWORD mineHeight DUP (mineWidth DUP(0))     ; 是否visit過此位置(0:無,1:有)
mineDir SBYTE -1,-1, 0,-1, 1,-1, -1,0, 1,0, -1,1, 0,1, 1,1 ; 遍歷時的所有方向(x,y)
flagRemaining db mineNum           ; 剩餘數量                     
fromBreakout DWORD 0 
Time db 0                          ; 累計秒數
winbool DWORD 0                    ; 是否獲勝


.DATA? 
hInstance HINSTANCE ? 
tempWidth DWORD ?
tempHeight DWORD ?
OriginalProc DWORD ?
hBitmap HBITMAP ?
hBackBitmap HBITMAP ?
hBackBitmap2 HBITMAP ?
hdcMem HDC ?
hdcBack HDC ?
hMineBitmap HBITMAP ?
hMineRedBitmap HBITMAP ?
hFlagBitmap HBITMAP ?
hFlagRedBitmap HBITMAP ?

.CODE 
ButtonSubclassProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    invoke GetWindowLong, hWnd, GWL_USERDATA
    mov OriginalProc, eax
    ; 按下滑鼠右鍵
    .IF uMsg == WM_RBUTTONDOWN
        invoke GetWindowLong, hWnd, GWL_ID
        sub eax, 10 ; 將按扭ID轉換為地圖上對應位置編號
        ; 若該位置未打開, setFlag
        cmp SDWORD PTR mineState[eax*4], 0
        je setFlag
        ; 若該位置有旗子, clearflag
        cmp SDWORD PTR mineState[eax*4], 2
        je clearFlag
        jmp EndRight ;已打開，跳過
    ; 插旗
    setFlag:
        ; 若旗子剩餘數量=0, 跳過
        cmp flagRemaining, 0
        je EndRight

        mov SDWORD PTR mineState[eax*4], 2 ; 改變狀態為插旗
        ; 將該按扭放上旗子圖案
        invoke GetWindowLong, hWnd, GWL_STYLE
        or eax, BS_BITMAP
        invoke SetWindowLong, hWnd, GWL_STYLE, eax
        invoke SendMessage, hWnd, BM_SETIMAGE, IMAGE_BITMAP, hFlagBitmap
        dec flagRemaining ; 旗子剩餘數量-1
        jmp EndRight

    ;拔旗
    clearFlag:
        mov SDWORD PTR mineState[eax*4], 0 ; 改變狀態為未打開
        ; 將該按鈕之旗子圖案移去
        invoke GetWindowLong, hWnd, GWL_STYLE
        and eax, Not BS_BITMAP
        invoke SetWindowLong, hWnd, GWL_STYLE, eax
        invoke SetWindowPos, hWnd, NULL, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOMOVE or SWP_NOSIZE
        inc flagRemaining ;旗子剩餘數量+1

    EndRight:
        ; 呼叫重繪
        invoke InvalidateRect, hWnd, NULL, TRUE
        invoke UpdateWindow, hWnd
        invoke InvalidateRect, mainh, NULL, TRUE
        xor eax, eax ; 阻止訊息傳遞
        ret
    ; 按下滑鼠左鍵
    .ELSEIF uMsg == WM_LBUTTONDOWN
        invoke GetWindowLong, hWnd, GWL_ID
        sub eax, 10 ; 將按扭ID轉換為地圖上對應位置編號 
        ; 若該位置是有旗子的,跳過
        cmp DWORD PTR mineState[eax*4], 2
        je isflag

        ; 將編號轉為xy座標, 並呼叫open_mine
        push eax
        mov ebx, mineMapSize
        xor edx, edx               
        div ebx                    
        mov eax, edx
        mov ebx, mineWidth
        xor edx, edx
        div ebx
        invoke open_mine, edx, eax
        pop eax

    ; 按下處理
    clicked:
        mov DWORD PTR mineClicked[eax*4], 1 ;將狀態改為按開
        ; 若該位置值為0 or -1, jmp clickMine
        mov eax, DWORD PTR [mineMap + eax*4] 
        cmp eax, 0
        jle clickMine
        ; 將對應文字顯示於按扭上
        push eax
        add al, '0'
        mov byte ptr [ShowText], al
        invoke SetWindowText, hWnd, ADDR ShowText
        pop eax
        jmp skip
  
    ; 按到地雷處理
    clickMine:
            ; 非地雷: 跳過
            cmp eax, 0
            je skip
            ; 播放按到地雷音效
            invoke mciSendString, addr boomOpenCmd, NULL, 0, NULL
            invoke mciSendString, addr boomVolumeCmd, NULL, 0, NULL
            invoke mciSendString, addr boomPlayCmd, NULL, 0, NULL
            mov endGamebool, 1 ;紀錄gameover成立
            ; 將按到地雷時的圖案顯示於按扭
            invoke GetWindowLong, hWnd, GWL_STYLE
            or eax, BS_BITMAP
            invoke SetWindowLong, hWnd, GWL_STYLE, eax
            invoke SendMessage, hWnd, BM_SETIMAGE, IMAGE_BITMAP, hMineRedBitmap
        
    skip:
        mov eax, WS_EX_CLIENTEDGE   ; 清除 WS_EX_CLIENTEDGE 樣式
        invoke SetWindowLong, hWnd, GWL_EXSTYLE, eax
        invoke SetWindowPos, hWnd, NULL, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOMOVE or SWP_NOSIZE

        invoke InvalidateRect, hWnd, NULL, TRUE
        invoke UpdateWindow, hWnd
        xor eax, eax ; 阻止訊息傳遞

        ; 判斷是否輸了
        cmp endGamebool, 1
        je lose
        call check ; 檢查獲勝條件
        ; 判斷是否贏了
        cmp endGamebool, 1
        je win
        ret
    isflag:
            ret
    win:
        mov winbool, 1 ; 紀錄是贏的結果
        call show_result ; 顯示結果時的地圖
        cmp fromBreakout, 1
        je skipMsgWin
        invoke MessageBox, mainh, addr WinGame, addr AppName, MB_OK ; 顯現win訊息
    skipMsgWin:
        jmp gameover
    lose:
        call show_result ; 顯示結果時的地圖
        cmp fromBreakout, 1
        je skipMsgLose
        invoke MessageBox, mainh, addr LoseGame, addr AppName, MB_OK ; 顯現lose訊息
    skipMsgLose:
        jmp gameover

     gameover:
        mov endGamebool, 1 
        ; 摧毀視窗
        invoke DestroyWindow, mainh
        invoke KillTimer, mainh, 1
        invoke PostQuitMessage, 0
            ret
        ret
    .ENDIF

    ; 調用預設窗口過程
    invoke CallWindowProc, OriginalProc, hWnd, uMsg, wParam, lParam
    ret
ButtonSubclassProc endp

WinMain5 proc
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT                   ; 定義 RECT 結構

    invoke GetModuleHandle, NULL 
    mov    hInstance,eax 

    ; 定義窗口類別
    mov   wc.cbSize,SIZEOF WNDCLASSEX 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc5
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
    invoke SetTimer, hwnd, 1, 1000, NULL  ;
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
WinMain5 endp

WndProc5 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hTarget:HWND
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 

     ; 遊戲結束,視窗摧毀
    .IF uMsg==WM_DESTROY 
        cmp fromBreakout, 0
        je getDestory
        cmp winbool, 1
        jne notWin
        mov eax, 4
        call backBreakOut
        jmp getDestory
    notWin:
        mov eax, -4
        call backBreakOut

    getDestory:
        mov winPosX, 400
        mov winPosY, 0
        mov fromBreakout, 0
        mov endGamebool, 1
        invoke KillTimer, hWnd, 1 ;摧毀計時器
        invoke PostQuitMessage,0

    ; Create Window
    .ELSEIF uMsg==WM_CREATE 

        call initialize ;初始化各variable
        call initialize_map ; 初始化地圖
        mov eax, hWnd 
        mov mainh, eax ;儲存視窗句柄
        mov currentID, 10 ; 起始按扭ID
        mov Time, 0 ; 計時歸零
        ; load image
        invoke LoadImage, hInstance, addr hFlagBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hFlagBitmap, eax

        invoke LoadImage, hInstance, addr hFlagRedBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hFlagRedBitmap, eax

        invoke LoadImage, hInstance, addr hMineBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hMineBitmap, eax

        invoke LoadImage, hInstance, addr hMineRedBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hMineRedBitmap, eax


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

        ; 創造按扭
        mov ecx, mineHeight
        mov edx, borderY
 
    Row:
        push ecx
        mov ecx, mineWidth
        mov ebx, borderX
    Col:
        push eax
        push ecx
        push edx
        invoke CreateWindowEx,NULL, ADDR ButtonClassName, NULL,\
                        WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_CENTER,\
                        ebx,edx,30,30,hWnd,currentID,hInstance,NULL
        push ebx
        mov ebx, currentID
        sub ebx, 10
        mov DWORD PTR hButton[ebx*4], eax
        mov hTarget, eax
        invoke SetWindowLong, hTarget, GWL_WNDPROC, OFFSET ButtonSubclassProc
        mov OriginalProc, eax
        invoke SetWindowLong, hTarget, GWL_USERDATA, eax
        pop ebx
        pop edx
        pop ecx
        pop eax
        dec ecx
        add ebx, 30
        inc currentID
        cmp ecx, 0
        jne Col
        
        pop ecx
        dec ecx
        add edx, 30
        
        cmp ecx, 0
        jne Row

    .ELSEIF uMsg == WM_TIMER
        ; 若gameover 不再更新時間
        cmp endGamebool, 1
        jne notskiptime
        ret

        notskiptime:
            inc Time ;更新時間
            ; 重繪Time Text
            invoke InvalidateRect, hWnd, addr line2Rect, TRUE
            invoke UpdateWindow, hWnd

    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        ;invoke ExcludeClipRect, hdc, 80, 160, 320, 400
        invoke BitBlt, hdcMem, 0, 0, winWidth, winHeight, hdcBack, 0, 0, SRCCOPY  ; 覆蓋位圖
        call update_Text ; 更新Remaining flag Text
        call update_Time ; 更新Time Text
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps

    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 
WndProc5 endp 

; 初始化各variable
initialize proc
    mov eax, 0
    mov ecx, mineHeight
   
InitialRow:
    push ecx
    mov ecx, mineWidth
InitialCol:
    mov SDWORD PTR mineMap[eax*4], 0
    mov SDWORD PTR mineState[eax*4], 0 
    mov DWORD PTR visited[eax*4], 0
    mov DWORD PTR mineClicked[eax*4], 0
    
    inc eax
    loop InitialCol
    pop ecx
    loop InitialRow
    mov winbool, 0
    mov endGamebool, 0
    mov flagRemaining, mineNum
    ret
initialize endp

;初始化map
initialize_map proc
    call GetRandomSeed_mine              ; 取得隨機種子
    mov eax, minerandomSeed
    mov esi, OFFSET mineMap           ; 初始化磚塊陣列指標
    mov ebx, mineMapSize
    mov ecx, mineNum

CreateMine:
    call RandomLocate            ; 獲得隨機地雷位置
    mov eax, MineY               ; eax = MineY
    imul eax, mineWidth          ; eax = MineY * mineWidth
    add eax, MineX               ; eax = MineY * mineWidth + MineX
    shl eax, 2                   ; eax = (MineY * mineWidth + MineX) * 4
    ; 判斷該位置是否已是地雷
    cmp SDWORD PTR [esi+eax], -1
    jne IsMine

Notmine:
    jmp CreateMine

IsMine:
    mov DWORD PTR [esi+eax], -1 ; 將該位設為地雷
    loop CreateMine

; 處理地雷外其他位置之數值
SetValue:
    mov eax, 0
    mov ecx, mineHeight
   
MineRow:
    push ecx
    mov ecx, mineWidth
MineCol:
    ; 轉換為xy座標
    push eax
    mov ebx, mineWidth
    xor edx, edx
    div ebx
    mov MineX, edx
    mov MineY, eax
    pop eax
    ; 若是地雷,跳過
    cmp DWORD PTR [esi+eax*4], -1
    je Continue
    call calculate_num ; 計算周遭地雷數
Continue:
    inc eax
    loop MineCol
    pop ecx
    loop MineRow
    ret
initialize_map endp

; 產生隨機位置
RandomLocate proc
    ; 線性同餘生成器: (a * seed + c) % m
    mov ebx, mineMapSize
    mov eax, minerandomSeed
    imul eax, eax, 1664525          ; 乘以係數 a（1664525 是常用值）
    add eax, 1013904223             ; 加上增量 c
    and eax, 7FFFFFFFh             ; 保證結果為正數
    mov minerandomSeed, eax             ; 更新隨機種子
    xor edx, edx                    ; 清除 edx
    div ebx                           ; 獲得隨機位置
    mov eax, edx
    ; 轉換為xy座標並儲存
    mov ebx, mineWidth
    xor edx, edx
    div ebx
    mov MineX, edx
    mov MineY, eax
    ret
RandomLocate endp

; 取得隨機種子
GetRandomSeed_mine proc
    invoke QueryPerformanceCounter, OFFSET minerandomSeed
    ret
GetRandomSeed_mine ENDP

;計算周遭地雷數量
calculate_num proc uses eax edx ecx esi
    mov edx, 0                   ; 初始化計數器，記錄地雷數量
    mov ecx, 8                   ; 8 個方向
    mov esi, OFFSET mineDir      ; 指向方向陣列
    
Calculate:
    mov bh, SBYTE PTR MineY               ; 取得當前格子的 Y 座標
    mov bl, SBYTE PTR MineX               ; 取得當前格子的 X 座標
    ; 取出周圍的相對位置
    mov al, [esi]      ; 取得相對位置 X 偏移量
    inc esi
    mov ah, [esi]  ; 取得相對位置 Y 偏移量

    ; 計算相對位置的實際座標
    add bl, al                  ; 計算相對 X 座標 (MineX + DirX)
    add bh, ah                  ; 計算相對 Y 座標 (MineY + DirY)

    ; 檢查該位置是否超出邊界
    cmp bl, 0 
    jl Skip
    cmp bl, mineWidth-1
    jg Skip
    cmp bh, 0
    jl Skip
    cmp bh, mineHeight-1
    jg Skip

    ; 檢查該位置是否為地雷 
    push edx
    movzx eax, bh              ; eax = MineY
    imul eax, mineWidth      ; eax = MineY * mineWidth
    movzx ebx, bl
    add eax, ebx              ; eax = MineY * mineWidth + MineX
    shl eax, 2               ; eax = (MineY * mineWidth + MineX) * 4
    pop edx
    cmp SDWORD PTR mineMap[eax], -1
    jne Skip
    ; 增加地雷數量
    inc edx
    
Skip:
    ; 計算下個相對位置
    inc esi
    loop Calculate

    mov bh, SBYTE PTR MineY               ; 取得當前格子的 Y 座標
    mov bl, SBYTE PTR MineX               ; 取得當前格子的 X 座標
    push edx
    movzx eax, bh              ; eax = MineY
    imul eax, mineWidth      ; eax = MineY * mineWidth
    movzx ebx, bl
    add eax, ebx              ; eax = MineY * mineWidth + MineX
    shl eax, 2               ; eax = (MineY * mineWidth + MineX) * 4
    pop edx
    mov SDWORD PTR mineMap[eax], edx
    ret
calculate_num endp

; 打開(為符合踩地雷規則,以遞迴處理)
open_mine proc,
    locateX: DWORD,                ; 現在位置之x座標
    locateY: DWORD                 ; 現在位置之y座標
    LOCAL now: DWORD               ; 現在位置之編號
    LOCAL next_l: DWORD            ; 下個位置之編號

    ; xy座標轉換為編號
    mov eax, locateY            
    imul eax, mineWidth        
    add eax, locateX             
    shl eax, 2
    mov now, eax

    push eax
    invoke SendMessage, hButton[eax], BM_CLICK, 0, 0 ; 將該位置之按扭按下
    pop eax

    mov DWORD PTR mineState[eax], 1 ; State改為已按下
    mov DWORD PTR visited[eax], 1   ; 已visit
    ; 若是按到地雷, 直接離開
    cmp SDWORD PTR mineMap[eax],-1
    je Exitopen_mine

    mov esi, OFFSET mineDir ;方向陣列
    mov ecx, 8              ;8個方向
; 判斷各位置是否可走
allDir:
    mov bh, SBYTE PTR locateY               ; 取得當前格子的 Y 座標
    mov bl, SBYTE PTR locateX               ; 取得當前格子的 X 座標
    ; 取出方向
    mov al, [esi]      ; 取得x方向之值
    inc esi
    mov ah, [esi]      ; 取得y方向之值

    ; 計算下個位置的座標
    add bl, al                  ; 計算下個 X 座標 (MineX + DirX)
    add bh, ah                  ; 計算下個 Y 座標 (MineY + DirY)

    ; 檢查該位置是否超出邊界
    cmp bl, 0     
    jl Skip
    cmp bl, mineWidth-1
    jg Skip
    cmp bh, 0
    jl Skip
    cmp bh, mineHeight-1
    jg Skip

    movzx eax, bh             ; eax = next_y
    imul eax, mineWidth      ; eax = next_y * mineWidth
    movzx edx, bl
    add eax, edx              ; eax = next_y * mineWidth + next_x
    shl eax, 2
    ; 若visit過,跳過(避免無限遞迴)
    cmp DWORD PTR visited[eax], 1 
    je Skip
    ; 若已打開或插旗,跳過(下個位置不能走)
    cmp DWORD PTR mineState[eax], 0
    jne Skip
    
    mov next_l, eax
    invoke can_go_next, now, next_l ;判斷下個位置是否可走
    ; 不行, 跳過
    cmp edx, 0
    je Skip
    push ecx
    push esi
    Invoke open_mine, bl, bh    ;可以,進入遞迴
    pop esi
    pop ecx
Skip:
    inc esi
    loop allDir
   
Exitopen_mine:
    mov eax, now
    mov DWORD PTR visited[eax], 0   ;設為未visit
    ret
 open_mine endp

; 判斷該位置是否可走
can_go_next proc,
    tempnow: DWORD,     ; 現位置
    tempnext: DWORD,    ; 下個位置

    xor edx, edx
    mov eax, tempnow

    ; 若現在這個位置是0, 則周遭皆可繼續走
    cmp SDWORD PTR mineMap[eax], 0
    mov eax,tempnext
    je Can
    jmp Cannot
Can:
    mov edx, 1
    jmp Exitcangonext
Cannot:
    mov edx, 0

Exitcangonext:
    ret
can_go_next endp

; 檢查Win條件(除地雷外皆被按開)
check proc
    mov eax, 0
    mov ecx, mineMapSize ;需檢查全地圖
checkloop:
    ; 若該位為地雷,檢查下一個
    cmp SDWORD PTR mineMap[eax*4],-1
    je Continuecheck

    ; 若該位非地雷,且非按開狀態=>win條件未達成
    cmp SDWORD PTR mineClicked[eax*4], 1
    jne gamenotEnd

Continuecheck:
    inc eax
    loop checkloop
    jmp gameEnd ; 若全部都遍歷過, win條件達成

gamenotEnd:
    mov endGamebool, 0 ;未贏
    jmp Exitcheck
gameEnd:
    mov endGamebool, 1 ;贏了
Exitcheck:
    ret
check endp

; 顯示結果(未被插旗的地雷全部顯現, 插錯的旗子要顯示)
show_result proc,
   
    mov ecx, mineMapSize
    mov ebx, 0
    Showloop:
        ; 若是插旗, 要去判斷是否為錯誤
        cmp SDWORD PTR mineState[ebx*4], 2
        je falseflag
        ;  若是已打開, 跳過
        cmp SDWORD PTR mineState[ebx*4],1
        je continueShow
        ; 若是地雷, 顯現(此時是未被按到的地雷才會進到mine)
        cmp SDWORD PTR mineMap[ebx*4], -1
        je mine
        jmp continueShow
    mine:
        call draw_mine ; 呼叫顯現地雷
        jmp continueShow
    falseflag:
        ; 若是地雷(正確的插旗) 跳過
        cmp SDWORD PTR mineMap[ebx*4], -1
        je continueShow
        call draw_falseflag ; 呼叫顯現錯誤的旗子
    continueShow:
        inc ebx
        loop Showloop
        ret
show_result endp

; 顯現地雷
draw_mine proc uses ebx ecx
    ; 在對應的按扭上顯現地雷圖案
    invoke GetWindowLong, hButton[ebx*4], GWL_STYLE
    or eax, BS_BITMAP
    invoke SetWindowLong, hButton[ebx*4], GWL_STYLE, eax
    invoke SendMessage, hButton[ebx*4], BM_SETIMAGE, IMAGE_BITMAP, hMineBitmap
    mov eax, WS_EX_CLIENTEDGE   ; 清除 WS_EX_CLIENTEDGE 樣式
    invoke SetWindowLong, hButton[ebx*4], GWL_EXSTYLE, eax
    invoke SetWindowPos, hButton[ebx*4], NULL, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOMOVE or SWP_NOSIZE
    invoke InvalidateRect, hButton[ebx*4], NULL, TRUE
    invoke UpdateWindow, hButton[ebx*4]
    ret
draw_mine endp

; 顯現旗子
draw_falseflag proc uses ebx ecx
     ; 在對應的按鈕上顯現錯誤旗子圖案   
     invoke GetWindowLong, hButton[ebx*4], GWL_STYLE
     or eax, BS_BITMAP
     invoke SetWindowLong, hButton[ebx*4], GWL_STYLE, eax
     invoke SendMessage, hButton[ebx*4], BM_SETIMAGE, IMAGE_BITMAP, hFlagRedBitmap
     invoke InvalidateRect, hButton[ebx*4], NULL, TRUE
     invoke UpdateWindow, hButton[ebx*4]
     ret
draw_falseflag endp

; 更新 Remaing Flag Text
update_Text proc
    invoke SetBkMode, hdcMem, TRANSPARENT
    mov bl, 10
    xor ah, ah
    mov al, [flagRemaining]       ; 將 flagemaining 的值載入 eax
    div bl
    mov byte ptr [RemainingFlagsText + 6], ' ' ; 十位數預設為空
    cmp al, 0
    je nextdigit
    add al, '0'                     ; 將數字轉換為 ASCII (單位數)
    mov byte ptr [RemainingFlagsText + 6], al ; 將字元寫入字串
    nextdigit:
        add ah, '0'                     ; 將數字轉換為 ASCII (單位數)
        mov byte ptr [RemainingFlagsText + 7], ah ; 將字元寫入字串
    invoke DrawText, hdcMem, addr RemainingFlagsText, -1, addr line1Rect,DT_CENTER
    ret
update_Text endp

; 更新Time Text
update_Time proc uses eax ebx edx
    invoke SetBkMode, hdcMem, TRANSPARENT
    mov bl, 100
    xor ah, ah
    mov al, Time      ; 將 Time的值載入 eax
    div bl
    mov byte ptr [TimeText + 6], ' ' ; 百位數預設為空
    mov byte ptr [TimeText + 7], ' ' ; 十位數預設為空

    ; Time<100
    cmp al, 0
    je lessthanhundred
    add al, '0'                     ; 將數字轉換為 ASCII (單位數)
    mov byte ptr [TimeText + 6], al ; 將字元寫入字串
    mov byte ptr [TimeText + 7], '0'; 十位數預設為0

    lessthanhundred:
        mov bl, 10
        mov al, ah
        xor ah, ah
        div bl
        ; 十位數為0, 直接處理個位數
        cmp al, 0
        je nextdigit
        add al, '0'                     ; 將數字轉換為 ASCII (單位數)
        mov byte ptr [TimeText + 7], al ; 將字元寫入字串

     nextdigit:
        add ah, '0'                     ; 將數字轉換為 ASCII (單位數)
        mov byte ptr [TimeText + 8], ah ; 將字元寫入字串
    invoke DrawText, hdcMem, addr TimeText, -1, addr line2Rect,DT_CENTER
    ret
update_Time endp

getMinesweeperGame PROC
    mov eax, endGamebool
    ret
getMinesweeperGame ENDP

MinesweeperfromBreakOut PROC
    mov winPosX, 1000
    mov winPosY, 430
    mov fromBreakout, 1
    ret
MinesweeperfromBreakOut ENDP

end
