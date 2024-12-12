.386 
.model flat,stdcall 
option casemap:none 

include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 

.DATA 
ClassName db "SimpleWinClass", 0 
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

borderX DWORD 80           ; 初始 X 座標
borderY DWORD 160           ; 初始 Y 座標
borderWidth DWORD 240       ; 平台寬度
borderHeight DWORD 240       ; 平台高度
winWidth DWORD 400              ; 視窗寬度
winHeight DWORD 480             ; 視窗高度
line1Rect RECT <20, 20, 380, 140>
currentID DWORD 10

.DATA? 
hInstance HINSTANCE ? 
hBrush DWORD ?
tempWidth DWORD ?
tempHeight DWORD ?
OriginalProc DWORD ?


.CODE 
ButtonSubclassProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    invoke GetWindowLong, hWnd, GWL_USERDATA
    mov OriginalProc, eax
    .IF uMsg == WM_RBUTTONDOWN
        ; 處理右鍵邏輯
        invoke MessageBox, hWnd, ADDR RightButton, ADDR LabelText, MB_OK
        xor eax, eax ; 阻止訊息傳遞
        ret
    .ELSEIF uMsg == WM_LBUTTONDOWN
        ; 處理右鍵邏輯
        invoke MessageBox, hWnd, ADDR LeftButton, ADDR LabelText, MB_OK
        xor eax, eax ; 阻止訊息傳遞
        ret
    .ENDIF

    ; 調用預設窗口過程
    invoke CallWindowProc, OriginalProc, hWnd, uMsg, wParam, lParam
    ret
ButtonSubclassProc endp

WinMain4 proc
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT                   ; 定義 RECT 結構

    invoke GetModuleHandle, NULL 
    mov    hInstance,eax 

    ; 定義窗口類別
    mov   wc.cbSize,SIZEOF WNDCLASSEX 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc4
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

    ; 主消息循環
    .WHILE TRUE 
        invoke GetMessage, ADDR msg,NULL,0,0 
        .BREAK .IF (!eax) 
        invoke TranslateMessage, ADDR msg 
        invoke DispatchMessage, ADDR msg 
    .ENDW 
    mov     eax,msg.wParam 
    ret 
WinMain4 endp

WndProc4 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hTarget:HWND
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 

    .IF uMsg==WM_DESTROY 
        invoke PostQuitMessage,0
    .ELSEIF uMsg==WM_CREATE 
        mov ecx, 8
        mov edx, borderY
    Row:
        push ecx
        mov ecx, 8
        mov ebx, borderX
    Col:
        push eax
        push ecx
        push edx
        invoke CreateWindowEx,WS_EX_CLIENTEDGE, ADDR ButtonClassName, NULL,\
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
        mov eax, borderX
        add eax, borderWidth
        mov edx, borderY
        add edx, borderHeight
        mov [tempWidth], eax
        mov [tempHeight], edx
        invoke Rectangle, hdc, borderX, borderY, tempWidth, tempHeight
        invoke EndPaint, hWnd, addr ps
    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 
WndProc4 endp 


end
