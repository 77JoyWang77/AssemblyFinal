.386 
.model flat,stdcall 
option casemap:none 

WinMain2 proto :DWORD,:DWORD,:DWORD,:DWORD 

include windows.inc 
include user32.inc 
include kernel32.inc 

.DATA 
ClassName db "SimpleWinClass",0 
AppName  db "Home",0 
Text db "Window", 0

.DATA? 
hInstance HINSTANCE ? 
CommandLine LPSTR ? 


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
    LOCAL winWidth:DWORD            ; 保存窗口寬度
    LOCAL winHeight:DWORD           ; 保存窗口高度

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
    mov wr.right, 400
    mov wr.bottom, 400

    ; 調整窗口大小
    invoke AdjustWindowRect, ADDR wr, WS_OVERLAPPEDWINDOW, FALSE

    ; 計算窗口寬度和高度
    mov eax, wr.right
    sub eax, wr.left
    mov winWidth, eax

    mov eax, wr.bottom
    sub eax, wr.top
    mov winHeight, eax

    ; 創建窗口
    invoke CreateWindowEx, NULL, ADDR ClassName, ADDR AppName, \
           WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, \
           winWidth, winHeight, NULL, NULL, hInst, NULL
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
WinMain2 endp


WndProc2 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT 

    .IF uMsg==WM_DESTROY 
        invoke PostQuitMessage,NULL 
        
    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke GetClientRect, hWnd, addr rect
        
        invoke DrawText, hdc, addr Text, -1, ADDR rect,DT_CENTER

        invoke EndPaint, hWnd, addr ps
    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 
WndProc2 endp 

end
