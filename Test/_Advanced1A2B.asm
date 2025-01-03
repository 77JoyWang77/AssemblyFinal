.386 
.model flat,stdcall 
option casemap:none 

include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 
include winmm.inc

EXTERN getOtherGame@0: PROC
backBreakOut EQU getOtherGame@0

UpdateLineText PROTO, LineText:PTR DWORD, mode: Byte, do:byte
CreateButton PROTO Text:PTR DWORD, x:DWORD, y:DWORD, ID:DWORD, hWnd:HWND

.DATA 
ClassName db "SimpleWinClass1", 0 
AppName  db "1A2B", 0 
ButtonClassName db "button", 0 
ButtonText1 db "1", 0 
ButtonText2 db "2", 0 
ButtonText3 db "3", 0 
ButtonText4 db "4", 0 
ButtonText5 db "5", 0 
ButtonText6 db "6", 0 
ButtonText7 db "7", 0 
ButtonText8 db "8", 0 
ButtonText9 db "9", 0 
ButtonText0 db "0", 0 
DeleteText db "C", 0 
OKText db "OK", 0 
RemainingTriesText db "Remaining:  ", 0
EndGame db "Game Over!", 0
AnswerText db "The answer is     ", 0
GuessLineText db "       ", 0
Line1Text db "                    ", 0
Line2Text db "                    ", 0
Line3Text db "                    ", 0
Line4Text db "                    ", 0
Line5Text db "                    ", 0
Line6Text db "                    ", 0
Line7Text db "                    ", 0
Line8Text db "                    ", 0

; 音效/背景
hBackBitmapName db "bmp/1A2B_background.bmp",0
clickOpenCmd db "open bmp/click.wav type mpegvideo alias clickMusic", 0
clickVolumeCmd db "setaudio clickMusic volume to 100", 0
clickPlayCmd db "play clickMusic from 0", 0

; 物件位置
line1Rect RECT <20, 20, 250, 40>
line2Rect RECT <20, 50, 250, 70> 
line3Rect RECT <20, 80, 250, 100>
line4Rect RECT <20, 110, 250, 130>
line5Rect RECT <20, 140, 250, 160>
line6Rect RECT <20, 170, 250, 190>
line7Rect RECT <20, 200, 250, 220>
line8Rect RECT <20, 230, 250, 250>
line9Rect RECT <20, 260, 250, 380>
line0Rect RECT <20, 280, 250, 300>

winWidth DWORD 270             ; 保存窗口寬度
winHeight DWORD 400            ; 保存窗口高度
winPosX DWORD 400              ; 螢幕位置 X 座標
winPosY DWORD 0                ; 螢幕位置 Y 座標
gameover BOOL TRUE             ; 遊戲結束狀態
fromBreakout BOOL FALSE        ; 從 Breakout 開啟遊戲

.DATA? 
hInstance HINSTANCE ?          ; 程式實例句柄
hBitmap HBITMAP ?              ; 位圖句柄
hBackBitmap HBITMAP ?          ; 背景位圖句柄
hBackBitmap2 HBITMAP ?         ; 第二背景位圖句柄
hdcMem HDC ?                   ; 記憶體設備上下文
hdcBack HDC ?                  ; 背景設備上下文

SelectedCount DWORD ?          ; 以選數字數目
TriesRemaining BYTE ?          ; 剩餘次數
SelectedNumbers db 4 dup(?)    ; 紀錄已選數字
Answer db 4 DUP(?)             ; 目標數字
Acount byte ?                  ; A 的數目
Bcount byte ?                  ; B 的數目
tempWidth DWORD ?              ; 暫存寬度
tempHeight DWORD ?             ; 暫存高度

.CODE 
; 創建視窗
WinMain1 proc

    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT

    invoke GetModuleHandle, NULL 
    mov hInstance,eax 

    ; 初始化窗口類
    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, offset WndProc1
    mov wc.cbClsExtra, NULL
    mov wc.cbWndExtra, NULL
    push hInstance
    pop wc.hInstance
    mov wc.hbrBackground, COLOR_WINDOW + 1
    mov wc.lpszMenuName, NULL
    mov wc.lpszClassName, offset ClassName
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
    invoke AdjustWindowRect, addr wr, WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, FALSE
    mov eax, wr.right
    sub eax, wr.left
    mov tempWidth, eax
    mov eax, wr.bottom
    sub eax, wr.top
    mov tempHeight, eax

    ; 創建窗口
    invoke CreateWindowEx, NULL, addr ClassName, addr AppName, \
            WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, \
            winPosX, winPosY, tempWidth, tempHeight, NULL, NULL, hInstance, NULL
    mov   hwnd, eax 

    ; 顯示和更新窗口
    invoke ShowWindow, hwnd, SW_SHOWNORMAL 
    invoke UpdateWindow, hwnd 

    ; 主消息循環
    .WHILE TRUE 
        invoke GetMessage, addr msg, NULL, 0, 0 
    .BREAK .IF (!eax) 
        invoke TranslateMessage, addr msg 
        invoke DispatchMessage, addr msg 
    .ENDW 
    mov     eax,msg.wParam 
    ret 
WinMain1 endp

; 視窗運行
WndProc1 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 

    .IF uMsg == WM_CREATE 

        ; 初始化遊戲資源
        call Initialized

        ; 加載位圖
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap, eax
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap2, eax

        ; 初始化畫面
        invoke GetDC, hWnd              
        mov hdc, eax
        invoke CreateCompatibleDC, hdc  
        mov hdcMem, eax
        invoke CreateCompatibleDC, hdc 
        mov hdcBack, eax
        invoke SelectObject, hdcMem, hBackBitmap
        invoke SelectObject, hdcBack, hBackBitmap2
        
        ; 初始化按鈕
        invoke CreateButton, addr ButtonText1, 20, 310, 11, hWnd
        invoke CreateButton, addr ButtonText2, 60, 310, 12, hWnd
        invoke CreateButton, addr ButtonText3, 100, 310, 13, hWnd
        invoke CreateButton, addr ButtonText4, 140, 310, 14, hWnd
        invoke CreateButton, addr ButtonText5, 180, 310, 15, hWnd
        invoke CreateButton, addr ButtonText6, 20, 350, 16, hWnd
        invoke CreateButton, addr ButtonText7, 60, 350, 17, hWnd
        invoke CreateButton, addr ButtonText8, 100, 350, 18, hWnd
        invoke CreateButton, addr ButtonText9, 140, 350, 19, hWnd
        invoke CreateButton, addr ButtonText0, 180, 350, 10, hWnd
        invoke CreateButton, addr DeleteText, 220, 310, 21, hWnd
        invoke CreateButton, addr OKText, 220, 350, 22, hWnd
        invoke ReleaseDC, hWnd, hdc

    .ELSEIF uMsg == WM_COMMAND
        
        ; 按鍵音效
        invoke mciSendString, addr clickOpenCmd, NULL, 0, NULL
        invoke mciSendString, addr clickVolumeCmd, NULL, 0, NULL
        invoke mciSendString, addr clickPlayCmd, NULL, 0, NULL

        mov eax, wParam

        ; 數字按鈕
        .IF eax >= 10 && eax <= 19

            ; 確認是否已選滿
            mov ecx, SelectedCount
            cmp ecx, 4
            jae skip_button

            ; 儲存選取數字
            sub eax, 10
            mov [SelectedNumbers + ecx], al
            add al, '0'
            mov [GuessLineText + 2* ecx], al
            inc SelectedCount

            ; 禁用該按鈕
            mov eax, wParam
            invoke GetDlgItem, hWnd, eax
            invoke EnableWindow, eax, FALSE

            invoke InvalidateRect, hWnd, NULL, FALSE    ; 更新畫面

        ; Delete 按鈕
        .ELSEIF eax == 21

            ; 檢查是否有已選擇的數字
            mov eax, SelectedCount
            cmp eax, 0
            je skip_button

            ; 刪除最近的選擇
            dec SelectedCount
            dec eax
            movzx ecx, [SelectedNumbers + eax]    ; 取出最近一個選擇
            mov [SelectedNumbers + eax], 0
            mov [GuessLineText + 2 * eax], ' '

            ; 啟用該按鈕
            add ecx, 10
            invoke GetDlgItem, hWnd, ecx
            invoke EnableWindow, eax, TRUE

            ; 更新顯示
            invoke InvalidateRect, hWnd, NULL, FALSE    ; 更新畫面

        ; OK 按鈕
        .ELSEIF eax == 22
            
            ; 確認是否已選滿
            mov eax, SelectedCount
            cmp eax, 4
            jne skip_button

            ; 計算結果
            call CalculateResult
            dec TriesRemaining
            mov SelectedCount, 0

            ; 更新歷史資料
            invoke UpdateLineText, addr Line1Text, 1, 7
            invoke UpdateLineText, addr Line2Text, 1, 6
            invoke UpdateLineText, addr Line3Text, 1, 5
            invoke UpdateLineText, addr Line4Text, 1, 4
            invoke UpdateLineText, addr Line5Text, 1, 3
            invoke UpdateLineText, addr Line6Text, 1, 2
            invoke UpdateLineText, addr Line7Text, 1, 1
            invoke UpdateLineText, addr Line8Text, 1, 0

            ; 初始化猜測紀錄文字
            mov edi, offset GuessLineText
            mov ecx, 7
            mov al, ' '
        reset_loop:
            mov [edi], al
            inc edi
            loop reset_loop

            ; 重新啟用所有按鈕
            mov ecx, 10
            mov ebx, 10
        reset:
            push ecx
            invoke GetDlgItem, hWnd, ebx
            invoke EnableWindow, eax, TRUE
            pop ecx
            inc ebx
            loop reset
            
            ; 初始化猜測紀錄陣列
            mov byte ptr [SelectedNumbers], 0
            mov byte ptr [SelectedNumbers + 1], 0
            mov byte ptr [SelectedNumbers + 2], 0
            mov byte ptr [SelectedNumbers + 3], 0

            invoke InvalidateRect, hWnd, NULL, FALSE    ; 更新畫面

            cmp Acount, 4
            je game_over            ; 如果 Acount 等於 4，遊戲結束

            cmp TriesRemaining, 0
            je game_over            ; 如果剩餘機會數為 0，遊戲結束

            ret

        game_over:
            ; 顯示遊戲結束訊息
            call Output
            cmp fromBreakout, TRUE
            je skipMsg
            invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
        skipMsg:
            invoke PostMessage, hWnd, WM_DESTROY, 0, 0
            ret

        .ENDIF

        skip_button:
            ret

    .ELSEIF uMsg == WM_PAINT
        
        ; 繪製畫面
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke BitBlt, hdcMem, 0, 0, winWidth, winHeight, hdcBack, 0, 0, SRCCOPY
        call UpdateText
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps

    .ELSEIF uMsg==WM_DESTROY 

        cmp fromBreakout, FALSE
        je getDestory

        ; 返回結果
        cmp Acount, 4
        jne notWin
        mov eax, 1
        call backBreakOut
        jmp getDestory

    notWin:
        mov eax, -1
        call backBreakOut

    getDestory:
        ; 清理資源
        mov winPosX, 400
        mov winPosY, 0
        mov fromBreakout, FALSE
        mov gameover, TRUE
        invoke DeleteObject, hBitmap
        invoke DeleteObject, hBackBitmap
        invoke DeleteObject, hBackBitmap2
        invoke DeleteDC, hdcMem
        invoke DeleteDC, hdcBack
        invoke ReleaseDC, hWnd, hdc
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, NULL

    .ELSE 
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam 
        ret
    .ENDIF 

    xor   eax, eax 
    ret 

WndProc1 ENDP

; 初始化遊戲
Initialized PROC
    call RandomNumber2
    mov gameover, FALSE
    mov SelectedCount, 0
    mov TriesRemaining, 8
    invoke UpdateLineText, addr Line1Text, 0, 0
    invoke UpdateLineText, addr Line2Text, 0, 0
    invoke UpdateLineText, addr Line3Text, 0, 0
    invoke UpdateLineText, addr Line4Text, 0, 0
    invoke UpdateLineText, addr Line5Text, 0, 0
    invoke UpdateLineText, addr Line6Text, 0, 0
    invoke UpdateLineText, addr Line7Text, 0, 0
    invoke UpdateLineText, addr Line8Text, 0, 0

    ; 初始化猜測紀錄文字
    mov edi, offset GuessLineText
    mov ecx, 7
    mov al, ' '
reset_loop:
    mov [edi], al
    inc edi
    loop reset_loop

    ; 初始化猜測紀錄陣列
    mov byte ptr [SelectedNumbers], 0
    mov byte ptr [SelectedNumbers + 1], 0
    mov byte ptr [SelectedNumbers + 2], 0
    mov byte ptr [SelectedNumbers + 3], 0
Initialized ENDP

; 計算結果
CalculateResult PROC
    mov esi, offset Answer
    mov edi, offset SelectedNumbers
    mov eax, 0
    mov ebx, 0

    ; 計算 A (數字與位置都正確)
    mov ecx, 4
countA:
    mov dl, [esi]
    cmp dl, [edi]
    jne skipA
    inc eax
skipA:
    inc esi
    inc edi
    loop countA

    ; 計算 B (數字正確但位置錯誤)
    mov edi, offset SelectedNumbers
    mov ecx, 4
countB:
    push ecx
    mov dl, [edi]
    mov esi, offset Answer
    mov ecx, 4
checkB:
    cmp dl, [esi]
    jne notB
    inc ebx
notB:
    inc esi
    loop checkB
    pop ecx
    inc edi
    loop countB

    ; 紀錄答案
    sub ebx, eax
    mov esi, offset Acount
    mov [esi], al
    mov edi, offset Bcount
    mov [edi], bl
    ret
CalculateResult ENDP

; 更新紀錄文字
UpdateLineText PROC, LineText:PTR DWORD, mode: Byte, do:byte
    mov al, do

    ; 紀錄歷史猜測，根據 TriesRemaining，更新新的一行
    .IF mode == 1
        .IF TriesRemaining == al
            ; 寫入猜測紀錄
            mov esi, offset GuessLineText
            mov edi, LineText
            mov ecx, 7
            rep movsb

            ; 寫入 ACount
            mov al, Acount
            add al, '0'
            mov [edi + 6], al
            mov al, 'A'
            mov [edi + 8], al

            ; 寫入 BCount
            mov al, Bcount
            add al, '0'
            mov [edi + 10], al
            mov al, 'B'
            mov [edi + 12], al
        .ENDIF
    
    ; 初始化
    .ELSE
        mov ecx, 20
        mov al, ' '
        mov edi, LineText
        rep stosb
    .ENDIF
    ret
UpdateLineText ENDP

; 獲得 4 個不重複的隨機數字
RandomNumber2 PROC
    mov ecx, 4
    mov esi, offset Answer
    mov edx, 0
pushing:
    push ecx
generateLoop:
    push edx
    invoke GetTickCount       ; 使用時間當種子
    mov ebx, 10
    cdq
    idiv ebx
    mov eax, edx              ; 隨機數字

    ; 檢查是否重複
    pop edx
    mov edi, offset Answer
    mov ecx, edx
    cmp ecx, 0
    je addNumber

checkDuplicate:
    cmp [edi], al
    je generateLoop
    inc edi
    loop checkDuplicate

addNumber:
    ; 存入字元
    mov [esi], al
    inc esi
    inc edx
    pop ecx
    loop pushing
    ret
RandomNumber2 ENDP

; 將答案轉字串並彈出視窗
Output PROC
    mov edi, offset Answer
    mov esi, offset AnswerText
    mov ecx, 4
move:
    mov al, [edi]
    add al, '0'
    mov byte ptr[esi + 14], al
    inc edi
    inc esi
    loop move
    invoke MessageBox, NULL, addr AnswerText, addr AppName, MB_OK 
    ret
Output ENDP

; 初始化按鈕
CreateButton PROC Text:PTR DWORD, x:DWORD, y:DWORD, ID:DWORD, hWnd:HWND
    invoke CreateWindowEx,WS_EX_CLIENTEDGE, addr ButtonClassName, Text,\
                        WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_CENTER,\
                        x, y, 30, 30, hWnd, ID, hInstance, NULL 
    ret
CreateButton ENDP

; 更新畫面
UpdateText PROC
    invoke SetBkMode, hdcMem, TRANSPARENT
    mov al, [TriesRemaining]
    add al, '0'
    mov byte ptr [RemainingTriesText + 11], al
    invoke DrawText, hdcMem, addr RemainingTriesText, -1, addr line1Rect,DT_CENTER
    invoke DrawText, hdcMem, addr GuessLineText, -1, addr line0Rect,DT_CENTER
    invoke DrawText, hdcMem, addr Line1Text, -1, addr line2Rect,DT_CENTER
    invoke DrawText, hdcMem, addr Line2Text, -1, addr line3Rect,DT_CENTER
    invoke DrawText, hdcMem, addr Line3Text, -1, addr line4Rect,DT_CENTER
    invoke DrawText, hdcMem, addr Line4Text, -1, addr line5Rect,DT_CENTER
    invoke DrawText, hdcMem, addr Line5Text, -1, addr line6Rect,DT_CENTER
    invoke DrawText, hdcMem, addr Line6Text, -1, addr line7Rect,DT_CENTER
    invoke DrawText, hdcMem, addr Line7Text, -1, addr line8Rect,DT_CENTER
    invoke DrawText, hdcMem, addr Line8Text, -1, addr line9Rect,DT_CENTER
    ret
UpdateText ENDP

; 返回遊戲狀態
getAdvanced1A2BGame PROC
    mov eax, gameover
    ret
getAdvanced1A2BGame ENDP

; 設置遊戲來源
Advanced1A2BfromBreakOut PROC
    mov winPosX, 1000
    mov winPosY, 0
    mov fromBreakout, TRUE
    ret
Advanced1A2BfromBreakOut ENDP
end