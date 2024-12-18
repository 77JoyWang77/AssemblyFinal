.386 
.model flat,stdcall 
option casemap:none 

EXTERN WinMain1@0: PROC
EXTERN WinMain2@0: PROC
EXTERN WinMain3@0: PROC
EXTERN WinMain4@0: PROC
EXTERN WinMain5@0: PROC
EXTERN WinMain6@0: PROC
Advanced1A2B EQU WinMain1@0
GameBrick EQU WinMain2@0
Cake1 EQU WinMain3@0
Cake2 EQU WinMain4@0
Minesweeper EQU WinMain5@0
Tofu EQU WinMain6@0

WinMain proto :DWORD

include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 

.DATA 
ClassName db "SimpleWinClass",0 
AppName  db "Home",0 
ButtonClassName db "button", 0 
ButtonText1 db "1A2B", 0
ButtonText2 db "Breakout", 0
ButtonText3 db "Cake1", 0
ButtonText4 db "Cake2", 0
ButtonText5 db "Minesweeper", 0
ButtonText6 db "Tofu", 0

hButton1BitmapName db "home_1A2B.bmp", 0
hButton2BitmapName db "home_BREAKOUT.bmp", 0
hButton3BitmapName db "home_cake1.bmp", 0
hButton4BitmapName db "home_cake2.bmp", 0
hButton5BitmapName db "home_minesweeper.bmp", 0
hButton6BitmapName db "home_tofu.bmp", 0
hBackBitmapName db "home_background.bmp", 0

winWidth EQU 400        ; 視窗寬度
winHeight EQU 600       ; 視窗高度
ButtonWidth EQU 200
ButtonHeight EQU 40

.DATA? 
hInstance HINSTANCE ? 
hBitmap HBITMAP ?
hBackBitmap HBITMAP ?
hButton1Bitmap HBITMAP ?
hButton2Bitmap HBITMAP ?
hButton3Bitmap HBITMAP ?
hButton4Bitmap HBITMAP ?
hButton5Bitmap HBITMAP ?
hButton6Bitmap HBITMAP ?
hdcMem HDC ?
tempWidth DWORD ?
tempHeight DWORD ?
OriginalProc DWORD ?

.CODE 
ButtonProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 
    LOCAL current:DWORD
    .IF uMsg == WM_PAINT
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
        ;cmp current, 6
        ;jne startDraw
        ;invoke SelectObject, hdcMem, hButton6Bitmap

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

Home PROC 
    invoke GetModuleHandle, NULL 
    mov    hInstance,eax 
    invoke WinMain, hInstance
    ret
Home ENDP

WinMain proc hInst:HINSTANCE
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT                   ; 定義 RECT 結構

    ; 定義窗口類別
    mov   wc.cbSize,SIZEOF WNDCLASSEX 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc
    mov   wc.cbClsExtra,NULL 
    mov    wc.cbWndExtra,NULL 
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
            0, 0, tempWidth, tempHeight, NULL, NULL, hInst, NULL
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


WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT
    LOCAL hTarget:HWND

    .IF uMsg==WM_DESTROY 
        ; 清理資源
        invoke DeleteObject, hBitmap
        invoke DeleteDC, hdcMem
        ; 發送退出訊息
        invoke PostQuitMessage, NULL
        ret
    .ELSEIF uMsg == WM_CREATE
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap, eax

        INVOKE  GetDC,hWnd              
        mov     hdc,eax
        INVOKE  CreateCompatibleDC,eax  
        mov     hdcMem,eax

        invoke SelectObject, hdcMem, hBackBitmap
        invoke GetClientRect, hWnd, addr rect

        invoke LoadImage, hInstance, addr hButton1BitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hButton1Bitmap, eax

        invoke CreateWindowEx, NULL,  ADDR ButtonClassName, NULL, \
               WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_OWNERDRAW, \
               100, 100, ButtonWidth, ButtonHeight, hWnd, 1, hInstance, NULL
        mov hTarget, eax
        invoke SetWindowLong, hTarget, GWL_WNDPROC, OFFSET ButtonProc
        mov OriginalProc, eax
        invoke SetWindowLong, hTarget, GWL_USERDATA, eax

        invoke LoadImage, hInstance, addr hButton2BitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hButton2Bitmap, eax

        invoke CreateWindowEx, NULL,  ADDR ButtonClassName, NULL, \
               WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_OWNERDRAW, \
               100, 170, ButtonWidth, ButtonHeight, hWnd, 2, hInstance, NULL
        mov hTarget, eax
        invoke SetWindowLong, hTarget, GWL_WNDPROC, OFFSET ButtonProc
        mov OriginalProc, eax
        invoke SetWindowLong, hTarget, GWL_USERDATA, eax

        invoke LoadImage, hInstance, addr hButton3BitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hButton3Bitmap, eax

        invoke CreateWindowEx, NULL,  ADDR ButtonClassName, NULL, \
               WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_OWNERDRAW, \
               100, 240, ButtonWidth, ButtonHeight, hWnd, 3, hInstance, NULL
        mov hTarget, eax
        invoke SetWindowLong, hTarget, GWL_WNDPROC, OFFSET ButtonProc
        mov OriginalProc, eax
        invoke SetWindowLong, hTarget, GWL_USERDATA, eax

        invoke LoadImage, hInstance, addr hButton4BitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hButton4Bitmap, eax

        invoke CreateWindowEx, NULL,  ADDR ButtonClassName, NULL, \
               WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_OWNERDRAW, \
               100, 310, ButtonWidth, ButtonHeight, hWnd, 4, hInstance, NULL
        mov hTarget, eax
        invoke SetWindowLong, hTarget, GWL_WNDPROC, OFFSET ButtonProc
        mov OriginalProc, eax
        invoke SetWindowLong, hTarget, GWL_USERDATA, eax

        invoke LoadImage, hInstance, addr hButton5BitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hButton5Bitmap, eax

        invoke CreateWindowEx, NULL,  ADDR ButtonClassName, NULL, \
               WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_OWNERDRAW, \
               100, 380, ButtonWidth, ButtonHeight, hWnd, 5, hInstance, NULL
        mov hTarget, eax
        invoke SetWindowLong, hTarget, GWL_WNDPROC, OFFSET ButtonProc
        mov OriginalProc, eax
        invoke SetWindowLong, hTarget, GWL_USERDATA, eax

        ;invoke LoadImage, hInstance, addr hButton6BitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        ;mov hButton6Bitmap, eax

        ;invoke CreateWindowEx, NULL,  ADDR ButtonClassName, NULL, \
        ;       WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_OWNERDRAW, \
        ;       100, 450, ButtonWidth, ButtonHeight, hWnd, 6, hInstance, NULL
        ;mov hTarget, eax
        ;invoke SetWindowLong, hTarget, GWL_WNDPROC, OFFSET ButtonProc
        ;mov OriginalProc, eax
        ;invoke SetWindowLong, hTarget, GWL_USERDATA, eax

        invoke ReleaseDC, hWnd, hdc
    .ELSEIF uMsg == WM_COMMAND
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
        ;cmp eax, 6
        ;je StartGame6

    .ELSEIF uMsg == WM_PAINT
        ; 先開始繪製
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        ; 使用 BitBlt 複製內存位圖到螢幕
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps

    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 
StartGame1:
    ; 呼叫遊戲啟動
    call Advanced1A2B
    ret
StartGame2:
    ; 呼叫遊戲啟動
    call GameBrick
    ret
StartGame3:
    ; 呼叫遊戲啟動
    call Cake1
    ret
StartGame4:
    ; 呼叫遊戲啟動
    call Cake2
    ret
StartGame5:
    ; 呼叫遊戲啟動
    call Minesweeper
    ret
;StartGame6:
    ; 呼叫遊戲啟動
    ;call Tofu
    ;ret
WndProc endp 

end
