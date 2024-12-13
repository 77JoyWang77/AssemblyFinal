.386 
.model flat,stdcall 
option casemap:none 

open_mine proto :DWORD,:DWORD
can_go_next proto :DWORD, :DWORD
include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 

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
LabelText db "Minesweeper ", 0
EndGame db "Game Over!", 0
LeftButton db "Left", 0
RightButton db "Right", 0
ShowText db " ", 0
hMineBitmapName db "mine.bmp",0
hFlagBitmapName db "flag.bmp",0

borderX DWORD 80           ; 初始 X 座標
borderY DWORD 160           ; 初始 Y 座標
borderWidth DWORD 240       ; 平台寬度
borderHeight DWORD 240       ; 平台高度
winWidth DWORD 400              ; 視窗寬度
winHeight DWORD 480             ; 視窗高度
line1Rect RECT <20, 20, 380, 140>
currentID DWORD 10

mineWidth EQU 8                        
mineHeight EQU 8
mineTypeNum EQU 2
mineNum EQU 10
mineMapSize EQU 64
minerandomSeed DWORD 0                 ; 隨機數種子
MineX DWORD ?
MineY DWORD ?
DirX SDWORD ?
DirY SDWORD ?
mineMap SDWORD mineHeight DUP (mineWidth DUP (0))
mineState SDWORD mineHeight DUP (mineWidth DUP (0))
visited DWORD mineHeight DUP (mineWidth DUP(0))
mineDir SBYTE -1,-1, 0,-1, 1,-1, -1,0, 1,0, -1,1, 0,1, 1,1 

.DATA? 
hInstance HINSTANCE ? 
hBrush DWORD ?
tempWidth DWORD ?
tempHeight DWORD ?
OriginalProc DWORD ?
hBitmap HBITMAP ?
hMineBitmap HBITMAP ?
hFlagBitmap HBITMAP ?
hdcMem HDC ?

.CODE 
ButtonSubclassProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    invoke GetWindowLong, hWnd, GWL_USERDATA
    mov OriginalProc, eax
    .IF uMsg == WM_RBUTTONDOWN
        invoke GetWindowLong, hWnd, GWL_STYLE
        or eax, BS_BITMAP
        invoke SetWindowLong, hWnd, GWL_STYLE, eax
        invoke SendMessage, hWnd, BM_SETIMAGE, IMAGE_BITMAP, hFlagBitmap
        ;invoke MessageBox, hWnd, ADDR RightButton, ADDR LabelText, MB_OK
        xor eax, eax ; 阻止訊息傳遞
        ret
    .ELSEIF uMsg == WM_LBUTTONDOWN
        invoke GetWindowLong, hWnd, GWL_ID
        sub eax, 10

        push eax
        mov ebx, mineMapSize
        xor edx, edx                    ; 清除 edx
        div ebx                           ; 獲得隨機類型
        mov eax, edx
        mov ebx, mineWidth
        xor edx, edx
        div ebx
        invoke open_mine, edx, eax
        pop eax

        mov eax, DWORD PTR [mineMap + eax*4]
        cmp eax, 0
        jle show_icon
        push eax
        add al, '0'
        mov byte ptr [ShowText], al
        invoke SetWindowText, hWnd, ADDR ShowText
        pop eax
        jmp skip
    show_icon:
        cmp eax, 0
        je skip
        invoke GetWindowLong, hWnd, GWL_STYLE
        or eax, BS_BITMAP
        invoke SetWindowLong, hWnd, GWL_STYLE, eax
        invoke SendMessage, hWnd, BM_SETIMAGE, IMAGE_BITMAP, hMineBitmap
        
    skip:
        mov eax, WS_EX_CLIENTEDGE   ; 清除 WS_EX_CLIENTEDGE 樣式
        invoke SetWindowLong, hWnd, GWL_EXSTYLE, eax
        invoke SetWindowPos, hWnd, NULL, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOMOVE or SWP_NOSIZE
        ;invoke MessageBox, hWnd, ADDR LeftButton, ADDR LabelText, MB_OK

        invoke InvalidateRect, hWnd, NULL, TRUE
        invoke UpdateWindow, hWnd
        xor eax, eax ; 阻止訊息傳遞
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
            0, 0, tempWidth, tempHeight, NULL, NULL, hInstance, NULL
    mov   hwnd,eax 
    invoke SetTimer, hwnd, 1, 50, NULL  ; 更新間隔從 50ms 改為 10ms
    ; 顯示和更新窗口
    invoke ShowWindow, hwnd,SW_SHOWNORMAL 
    invoke UpdateWindow, hwnd 

    call initialize_map
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

    .IF uMsg==WM_DESTROY 
        invoke PostQuitMessage,0
    .ELSEIF uMsg==WM_CREATE 
        invoke LoadImage, hInstance, addr hFlagBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hFlagBitmap, eax

        invoke LoadImage, hInstance, addr hMineBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hMineBitmap, eax


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
        mov hTarget, eax
        invoke SetWindowLong, hTarget, GWL_WNDPROC, OFFSET ButtonSubclassProc
        mov OriginalProc, eax
        invoke SetWindowLong, hTarget, GWL_USERDATA, eax
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

    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke EndPaint, hWnd, addr ps
    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 
WndProc5 endp 

initialize_map proc
    call GetRandomSeed_mine              ; 取得隨機種子
    mov eax, minerandomSeed
    mov esi, OFFSET mineMap           ; 初始化磚塊陣列指標
    mov ebx, mineMapSize
    mov ecx, mineNum

CreateMine:
    call RandomLocate
    mov eax, MineY               ; eax = MineY
    imul eax, mineWidth          ; eax = MineY * mineWidth
    add eax, MineX               ; eax = MineY * mineWidth + MineX
    shl eax, 2                   ; eax = (MineY * mineWidth + MineX) * 4
    cmp SDWORD PTR [esi+eax], -1
    jne IsMine

Notmine:
    jmp CreateMine

IsMine:
    mov DWORD PTR [esi+eax], -1
    loop CreateMine

SetValue:
    mov eax, 0
    mov ecx, mineHeight
   
MineRow:
    push ecx
    mov ecx, mineWidth
MineCol:
    push eax
    mov ebx, mineWidth
    xor edx, edx
    div ebx
    mov MineX, edx
    mov MineY, eax
    pop eax
    cmp DWORD PTR [esi+eax*4], -1
    je Continue
    call calculate_num
Continue:
    inc eax
    loop MineCol
    pop ecx
    loop MineRow
    ret
initialize_map endp


RandomLocate proc
    ; 線性同餘生成器: (a * seed + c) % m
    mov ebx, mineMapSize
    mov eax, minerandomSeed
    imul eax, eax, 1664525          ; 乘以係數 a（1664525 是常用值）
    add eax, 1013904223             ; 加上增量 c
    and eax, 7FFFFFFFh             ; 保證結果為正數
    mov minerandomSeed, eax             ; 更新隨機種子
    xor edx, edx                    ; 清除 edx
    div ebx                           ; 獲得隨機類型
    mov eax, edx
    mov ebx, mineWidth
    xor edx, edx
    div ebx
    mov MineX, edx
    mov MineY, eax
    ret
RandomLocate endp

calculate_num proc uses eax edx ecx esi
    mov edx, 0                   ; 初始化計數器，記錄地雷數量
    mov ecx, 8                   ; 8 個方向
    mov esi, OFFSET mineDir

    
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
    cmp bl, 0                     ; 如果超出邊界就跳過
    jl Skip
    cmp bl, mineWidth-1
    jg Skip
    cmp bh, 0
    jl Skip
    cmp bh, mineHeight-1
    jg Skip

    ; 檢查該位置是否為地雷 (如果是 -1 就算地雷)
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


open_mine proc,
    locateX: DWORD,
    locateY: DWORD
    LOCAL now: DWORD
    LoCAL next_l: DWORD

    mov eax, locateY               ; eax = MineY
    imul eax, mineWidth          ; eax = MineY * mineWidth
    add eax, locateX               ; eax = MineY * mineWidth + MineX
    shl eax, 2
    mov now, eax
    mov DWORD PTR mineState[eax], 1
    mov DWORD PTR visited[eax], 1
    cmp SDWORD PTR mineMap[eax],-1
    je Exitopen_mine

    mov esi, OFFSET mineDir
    mov ecx, 8

allDir:
    mov bh, SBYTE PTR locateY               ; 取得當前格子的 Y 座標
    mov bl, SBYTE PTR locateX               ; 取得當前格子的 X 座標
    ; 取出周圍的相對位置
    mov al, [esi]      ; 取得相對位置 X 偏移量
    inc esi
    mov ah, [esi]  ; 取得相對位置 Y 偏移量

    ; 計算相對位置的實際座標
    add bl, al                  ; 計算相對 X 座標 (MineX + DirX)
    add bh, ah                  ; 計算相對 Y 座標 (MineY + DirY)

    ; 檢查該位置是否超出邊界
    cmp bl, 0                     ; 如果超出邊界就跳過
    jl Skip
    cmp bl, mineWidth-1
    jg Skip
    cmp bh, 0
    jl Skip
    cmp bh, mineHeight-1
    jg Skip

    movzx eax, bh              ; eax = next_y
    imul eax, mineWidth      ; eax = next_y * mineWidth
    movzx edx, bl
    add eax, edx              ; eax = next_y * mineWidth + next_x
    shl eax, 2
    cmp DWORD PTR visited[eax], 1 
    je Skip
    
    mov next_l, eax
    invoke can_go_next, now, next_l
    cmp edx, 0
    je Skip
    push ecx
    push esi
    Invoke open_mine, bl, bh
    pop esi
    pop ecx
Skip:
    inc esi
    loop allDir
   
Exitopen_mine:
    mov eax, now
    mov DWORD PTR visited[eax], 0
    ret
 open_mine endp

 

can_go_next proc,
    tempnow: DWORD,
    tempnext: DWORD,

    xor edx, edx

    mov eax, tempnow
    cmp SDWORD PTR mineMap[eax], 0
    mov eax,tempnext
    je Can
 
    ;mov bh, SBYTE PTR next_y             ; 取得下個格子的 Y 座標
    ;mov bl, SBYTE PTR next_x               ; 取得下個格子的 X 座標
    ;movzx eax, bh              ; eax = next_y
    ;imul eax, mineWidth      ; eax = next_y * mineWidth
    ;movzx ebx, bl
    ;add eax, ebx              ; eax = next_y * mineWidth + next_x
    ;shl eax, 2

    mov eax, tempnext
    cmp SDWORD PTR mineMap[eax], 0
    je Can
    jmp Cannot

Can:
    mov edx, 1
    jmp Exitcangonext
Cannot:
    mov edx, 0

Exitcangonext:
    ;mov DWORD PTR visited[eax], 1
    ret
can_go_next endp

GetRandomSeed_mine proc
    invoke QueryPerformanceCounter, OFFSET minerandomSeed
    ret
GetRandomSeed_mine ENDP

end
