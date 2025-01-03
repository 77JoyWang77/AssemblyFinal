.386 
.model flat,stdcall 
option casemap:none 

EXTERN WinMain1@0: PROC
EXTERN WinMain2@0: PROC
EXTERN WinMain3@0: PROC
EXTERN WinMain4@0: PROC
EXTERN WinMain5@0: PROC
EXTERN WinMain6@0: PROC
EXTERN WinMain7@0: PROC

EXTERN getAdvanced1A2BGame@0: PROC
EXTERN getBreakOutGame@0: PROC
EXTERN getCake1Game@0: PROC
EXTERN getCake2Game@0: PROC
EXTERN getMinesweeperGame@0: PROC
EXTERN getTofuGame@0: PROC
EXTERN getAdvancedBreakOutGame@0: PROC

Advanced1A2B EQU WinMain1@0
BreakOut EQU WinMain2@0
Cake1 EQU WinMain3@0
Cake2 EQU WinMain4@0
Minesweeper EQU WinMain5@0
Tofu EQU WinMain6@0
AdvancedBreakOut EQU WinMain7@0

checkAdvanced1A2B EQU getAdvanced1A2BGame@0
checkBreakOut EQU getBreakOutGame@0
checkCake1 EQU getCake1Game@0
checkCake2 EQU getCake2Game@0
checkMinesweeper EQU getMinesweeperGame@0
checkTofu EQU getTofuGame@0
checkAdvancedBreakOut EQU getAdvancedBreakOutGame@0

include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 
include winmm.inc

.DATA 
ClassName db "SimpleWinClass",0 
AppName  db "Home",0 
ButtonClassName db "button", 0 

; 按鈕/背景
hButton1BitmapName db "bmp/home_1A2B.bmp", 0
hButton2BitmapName db "bmp/home_BREAKOUT.bmp", 0
hButton3BitmapName db "bmp/home_cake1.bmp", 0
hButton4BitmapName db "bmp/home_cake2.bmp", 0
hButton5BitmapName db "bmp/home_minesweeper.bmp", 0
hButton6BitmapName db "bmp/home_tofu.bmp", 0
hButton7BitmapName db "bmp/bonus.bmp", 0
hBackBitmapName db "bmp/home_background.bmp", 0

; 音效
bgOpenCmd db "open wav/merrychristmas.wav type mpegvideo alias bgMusic", 0
bgVolumeCmd db "setaudio bgMusic volume to 100", 0
bgPlayCmd db "play bgMusic repeat", 0
bgCloseCmd db "close bgMusic", 0
clickOpenCmd db "open wav/click.wav type mpegvideo alias clickMusic", 0
clickVolumeCmd db "setaudio clickMusic volume to 100", 0
clickPlayCmd db "play clickMusic from 0", 0

winWidth EQU 400               ; 視窗寬度
winHeight EQU 600              ; 視窗高度
ButtonWidth EQU 200            ; 按鈕寬度
ButtonHeight EQU 40            ; 按鈕高度

.DATA? 
hInstance HINSTANCE ?          ; 程式實例句柄
hBitmap HBITMAP ?              ; 位圖句柄
hBackBitmap HBITMAP ?          ; 背景位圖句柄
hButton1Bitmap HBITMAP ?       ; 按鈕位圖句柄 1
hButton2Bitmap HBITMAP ?       ; 按鈕位圖句柄 2
hButton3Bitmap HBITMAP ?       ; 按鈕位圖句柄 3
hButton4Bitmap HBITMAP ?       ; 按鈕位圖句柄 4
hButton5Bitmap HBITMAP ?       ; 按鈕位圖句柄 5
hButton6Bitmap HBITMAP ?       ; 按鈕位圖句柄 6
hButton7Bitmap HBITMAP ?       ; 按鈕位圖句柄 7
hdcMem HDC ?                   ; 記憶體設備上下文
tempWidth DWORD ?              ; 暫存寬度
tempHeight DWORD ?             ; 暫存高度
OriginalProc DWORD ?

.CODE 
; 按鈕運行
ButtonProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 
    LOCAL current:DWORD

    .IF uMsg == WM_PAINT
        ; 獲取 ID，根據對應 ID，繪製按鈕
        invoke GetWindowLong, hWnd, GWL_ID
        mov current, eax

        cmp current, 1
        jne Next1
        invoke SelectObject, hdcMem, hButton1Bitmap
        jmp startDraw

    Next1:
        cmp current, 2
        jne Next2
        invoke SelectObject, hdcMem, hButton2Bitmap
        jmp startDraw

    Next2:
        cmp current, 3
        jne Next3
        invoke SelectObject, hdcMem, hButton3Bitmap
        jmp startDraw

    Next3:
        cmp current, 4
        jne Next4
        invoke SelectObject, hdcMem, hButton4Bitmap
        jmp startDraw

    Next4:
        cmp current, 5
        jne Next5
        invoke SelectObject, hdcMem, hButton5Bitmap
        jmp startDraw

    Next5:
        cmp current, 6
        jne Next6
        invoke SelectObject, hdcMem, hButton6Bitmap
        jmp startDraw

    Next6:
        cmp current, 7
        jne startDraw
        invoke SelectObject, hdcMem, hButton7Bitmap

    startDraw:
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke BitBlt, hdc, 0, 0, ButtonWidth, ButtonHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps
        ret
    .ENDIF
    invoke CallWindowProc, OriginalProc, hWnd, uMsg, wParam, lParam
    ret

ButtonProc endp

WinMain proc
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT                   ; 定義 RECT 結構

    invoke GetModuleHandle, NULL 
    mov hInstance,eax 

    ; 定義窗口類別
    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET WndProc
    mov wc.cbClsExtra, NULL
    mov wc.cbWndExtra, NULL
    push hInstance
    pop wc.hInstance
    mov wc.hbrBackground, COLOR_WINDOW+1
    mov wc.lpszMenuName, NULL
    mov wc.lpszClassName, OFFSET ClassName
    invoke LoadIcon, NULL, IDI_APPLICATION
    mov wc.hIcon, eax
    mov wc.hIconSm, eax
    invoke LoadCursor, NULL, IDC_ARROW
    mov wc.hCursor, eax
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
WinMain endp

; 視窗運行
WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 

    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT
    LOCAL hTarget:HWND

    .IF uMsg == WM_CREATE

        ; 背景音樂
        invoke mciSendString, addr bgOpenCmd, NULL, 0, NULL    ; 開啟背景音樂
        invoke mciSendString, addr bgVolumeCmd, NULL, 0, NULL  ; 設定音量 (可調整為適合的範圍)
        invoke mciSendString, addr bgPlayCmd, NULL, 0, NULL    ; 播放背景音樂，並設置為循環播放

        ; 加載位圖
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap, eax

        ; 初始化畫面
        invoke GetDC,hWnd              
        mov hdc,eax
        invoke CreateCompatibleDC, eax  
        mov hdcMem, eax
        invoke SelectObject, hdcMem, hBackBitmap
        invoke GetClientRect, hWnd, addr rect

        ; 按鈕 1
        invoke LoadImage, hInstance, addr hButton1BitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hButton1Bitmap, eax

        invoke CreateWindowEx, NULL,  ADDR ButtonClassName, NULL, \
               WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_OWNERDRAW, \
               100, 100, ButtonWidth, ButtonHeight, hWnd, 1, hInstance, NULL
        mov hTarget, eax
        invoke SetWindowLong, hTarget, GWL_WNDPROC, OFFSET ButtonProc
        mov OriginalProc, eax
        invoke SetWindowLong, hTarget, GWL_USERDATA, eax

        ; 按鈕 2
        invoke LoadImage, hInstance, addr hButton2BitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hButton2Bitmap, eax

        invoke CreateWindowEx, NULL,  ADDR ButtonClassName, NULL, \
               WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_OWNERDRAW, \
               100, 170, ButtonWidth, ButtonHeight, hWnd, 2, hInstance, NULL
        mov hTarget, eax
        invoke SetWindowLong, hTarget, GWL_WNDPROC, OFFSET ButtonProc
        mov OriginalProc, eax
        invoke SetWindowLong, hTarget, GWL_USERDATA, eax

        ; 按鈕 3
        invoke LoadImage, hInstance, addr hButton3BitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hButton3Bitmap, eax

        invoke CreateWindowEx, NULL,  ADDR ButtonClassName, NULL, \
               WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_OWNERDRAW, \
               100, 240, ButtonWidth, ButtonHeight, hWnd, 3, hInstance, NULL
        mov hTarget, eax
        invoke SetWindowLong, hTarget, GWL_WNDPROC, OFFSET ButtonProc
        mov OriginalProc, eax
        invoke SetWindowLong, hTarget, GWL_USERDATA, eax

        ; 按鈕 4
        invoke LoadImage, hInstance, addr hButton4BitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hButton4Bitmap, eax

        invoke CreateWindowEx, NULL,  ADDR ButtonClassName, NULL, \
               WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_OWNERDRAW, \
               100, 310, ButtonWidth, ButtonHeight, hWnd, 4, hInstance, NULL
        mov hTarget, eax
        invoke SetWindowLong, hTarget, GWL_WNDPROC, OFFSET ButtonProc
        mov OriginalProc, eax
        invoke SetWindowLong, hTarget, GWL_USERDATA, eax

        ; 按鈕 5
        invoke LoadImage, hInstance, addr hButton5BitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hButton5Bitmap, eax

        invoke CreateWindowEx, NULL,  ADDR ButtonClassName, NULL, \
               WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_OWNERDRAW, \
               100, 380, ButtonWidth, ButtonHeight, hWnd, 5, hInstance, NULL
        mov hTarget, eax
        invoke SetWindowLong, hTarget, GWL_WNDPROC, OFFSET ButtonProc
        mov OriginalProc, eax
        invoke SetWindowLong, hTarget, GWL_USERDATA, eax

        ; 按鈕 6
        invoke LoadImage, hInstance, addr hButton6BitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hButton6Bitmap, eax

        invoke CreateWindowEx, NULL,  ADDR ButtonClassName, NULL, \
               WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_OWNERDRAW, \
               100, 450, ButtonWidth, ButtonHeight, hWnd, 6, hInstance, NULL
        mov hTarget, eax
        invoke SetWindowLong, hTarget, GWL_WNDPROC, OFFSET ButtonProc
        mov OriginalProc, eax
        invoke SetWindowLong, hTarget, GWL_USERDATA, eax

        ; 按鈕 7
        invoke LoadImage, hInstance, addr hButton7BitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hButton7Bitmap, eax
        invoke CreateWindowEx, NULL,  ADDR ButtonClassName, NULL, \
               WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_OWNERDRAW, \
               300, 500, 40, ButtonHeight, hWnd, 7, hInstance, NULL
        mov hTarget, eax
        invoke SetWindowLong, hTarget, GWL_WNDPROC, OFFSET ButtonProc
        mov OriginalProc, eax
        invoke SetWindowLong, hTarget, GWL_USERDATA, eax

        invoke ReleaseDC, hWnd, hdc

    .ELSEIF uMsg == WM_COMMAND
        
        ; 點擊音效
        invoke mciSendString, addr clickOpenCmd, NULL, 0, NULL
        invoke mciSendString, addr clickVolumeCmd, NULL, 0, NULL
        invoke mciSendString, addr clickPlayCmd, NULL, 0, NULL

        call checkGame
        cmp eax, 1
        je hasGame

        mov eax, wParam
        cmp eax, 1
        je StartGame1
        cmp eax, 2
        je StartGame2
        cmp eax, 3
        je StartGame3
        cmp eax, 4
        je StartGame4
        cmp eax, 5
        je StartGame5
        cmp eax, 6
        je StartGame6
        cmp eax, 7
        je StartGame7

    hasGame:
        ret

    .ELSEIF uMsg == WM_PAINT

        ; 繪製畫面
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps

    .ELSEIF uMsg==WM_DESTROY 

        ; 清理資源
        invoke DeleteObject, hBitmap
        invoke DeleteDC, hdcMem
        invoke DestroyWindow, hWnd
        invoke mciSendString, addr bgCloseCmd, NULL, 0, NULL
        invoke PostQuitMessage, NULL
        ret
    
    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 

StartGame1:
    call Advanced1A2B
    ret
StartGame2:
    call BreakOut
    ret
StartGame3:
    call Cake1
    ret
StartGame4:
    call Cake2
    ret
StartGame5:
    call Minesweeper
    ret
StartGame6:
    call Tofu
    ret
StartGame7:
    call AdvancedBreakOut
    ret

WndProc endp 

checkGame PROC
    call checkAdvanced1A2B
    cmp eax, 0
    je hasGame
    call checkBreakOut
    cmp eax, 0
    je hasGame
    call checkCake1
    cmp eax, 0
    je hasGame
    call checkCake2
    cmp eax, 0
    je hasGame
    call checkMinesweeper
    cmp eax, 0
    je hasGame
    call checkTofu
    cmp eax, 0
    je hasGame
    call checkAdvancedBreakOut
    cmp eax, 0
    je hasGame

    mov eax, 0
    ret

hasGame:
    mov eax, 1
    ret

checkGame ENDP
end