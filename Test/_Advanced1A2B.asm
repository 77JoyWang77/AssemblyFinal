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

hBackBitmapName db "1A2B_background.bmp",0
clickOpenCmd db "open click.wav type mpegvideo alias clickMusic", 0
clickVolumeCmd db "setaudio clickMusic volume to 300", 0
clickPlayCmd db "play clickMusic from 0", 0

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

SelectedCount   dd 0
TriesRemaining  db 8
winWidth DWORD 270           ; 保存窗口寬度
winHeight DWORD 400          ; 保存窗口高度
fromBreakout DWORD 0
gameover DWORD 1
winPosX DWORD 400
winPosY DWORD 0

.DATA? 
hInstance HINSTANCE ? 
hBitmap HBITMAP ?
hBackBitmap HBITMAP ?
hBackBitmap2 HBITMAP ?
hdc HDC ?
hdcMem HDC ?
hdcBack HDC ?

SelectedNumbers db 4 dup(?)
Answer db 4 DUP(?)
Acount byte ? 
Bcount byte ? 
tempWidth DWORD ?
tempHeight DWORD ?


.CODE 
WinMain1 proc
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT

    invoke GetModuleHandle, NULL 
    mov    hInstance,eax 

    ; 定義窗口類別
    mov   wc.cbSize,SIZEOF WNDCLASSEX 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc1
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
            winPosX, winPosY, tempWidth, tempHeight, \
            NULL, NULL, hInstance, NULL
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
WinMain1 endp

WndProc1 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT 

    .IF uMsg==WM_DESTROY 
        cmp fromBreakout, 0
        je getDestory
        cmp Acount, 4
        jne notWin
        mov eax, 1
        call backBreakOut
        jmp getDestory
    notWin:
        mov eax, -1
        call backBreakOut

    getDestory:
        mov winPosX, 400
        mov winPosY, 0
        mov fromBreakout, 0
        mov gameover, 1
        invoke DeleteDC, hdcMem
        invoke DestroyWindow, hWnd
        invoke PostQuitMessage,0
        ret
    .ELSEIF uMsg==WM_CREATE 
        call Initialized
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap, eax
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap2, eax

        invoke GetDC, hWnd              
        mov hdc, eax
        
        invoke CreateCompatibleDC,hdc  
        mov hdcMem, eax
        invoke CreateCompatibleDC,hdc 
        mov hdcBack, eax
        invoke SelectObject, hdcMem, hBackBitmap
        invoke SelectObject, hdcBack, hBackBitmap2
        invoke GetClientRect, hWnd, addr rect
        
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
        invoke mciSendString, addr clickOpenCmd, NULL, 0, NULL
        invoke mciSendString, addr clickVolumeCmd, NULL, 0, NULL
        invoke mciSendString, addr clickPlayCmd, NULL, 0, NULL
        mov eax, wParam

        ; 按下數字按鈕
        .IF eax >= 10 && eax <= 19
            ; 確認是否已選滿
            mov ecx, SelectedCount
            cmp ecx, 4
            jae skip_button ; 若已選滿，跳過按鈕處理

            sub eax, 10

            ; 儲存選取數字並禁用按鈕
            mov [SelectedNumbers + ecx], al
            add al, '0'
            mov [GuessLineText + 2* ecx], al
            inc SelectedCount

            mov eax, wParam
            invoke GetDlgItem, hWnd, eax
            invoke EnableWindow, eax, FALSE
            ;invoke MessageBox, NULL, addr GuessLineText, NULL, MB_OK 

            invoke InvalidateRect, hWnd,  NULL, FALSE

        ; 按下 Delete 按鈕
        .ELSEIF eax == 21
            ; 檢查是否有已選擇的數字
            mov eax, SelectedCount
            cmp eax, 0
            je skip_button  ; 沒有選擇過數字，跳過

            ; 刪除最近的選擇
            dec SelectedCount
            dec eax
            movzx ecx, [SelectedNumbers + eax] ; 取出最近一個選擇
            mov [SelectedNumbers + eax], 0  ; 清除該選擇
            mov [GuessLineText + 2 * eax], ' '  ; 清除該選擇

            add ecx, 10
            ; 啟用該按鈕
            invoke GetDlgItem, hWnd, ecx
            invoke EnableWindow, eax, TRUE

            ; 更新顯示
            invoke InvalidateRect, hWnd,  NULL, FALSE
        .ELSEIF eax == 22
            mov eax, SelectedCount
            cmp eax, 4
            jne skip_button  ; 沒有選擇過數字，跳過
            call CalculateResult
            dec TriesRemaining

            invoke UpdateLineText, OFFSET Line1Text, 1, 7
            invoke UpdateLineText, OFFSET Line2Text, 1, 6
            invoke UpdateLineText, OFFSET Line3Text, 1, 5
            invoke UpdateLineText, OFFSET Line4Text, 1, 4
            invoke UpdateLineText, OFFSET Line5Text, 1, 3
            invoke UpdateLineText, OFFSET Line6Text, 1, 2
            invoke UpdateLineText, OFFSET Line7Text, 1, 1
            invoke UpdateLineText, OFFSET Line8Text, 1, 0

            mov edi, OFFSET GuessLineText
            mov ecx, 7
            mov al, ' '
            reset_loop:
            mov [edi], al             ; 設置當前字元為空格
            inc edi                   ; 移動到下一個字元
            loop reset_loop

            mov SelectedCount, 0
            ; 重新啟用所有按鈕
            mov ecx, 10                ; 設置循環次數為 10，表示啟用 10 個按鈕
            mov ebx, 10                 ; 設置按鈕 ID 從 0 開始
            Reset:
                push ecx
                invoke GetDlgItem, hWnd, ebx     ; 獲取按鈕的句柄
                invoke EnableWindow, eax, TRUE   ; 啟用該按鈕
                pop ecx
                inc ebx                 ; 增加按鈕 ID
                loop Reset              ; 循環直到 ecx 為 0

            mov byte ptr [SelectedNumbers], 0
            mov byte ptr [SelectedNumbers + 1], 0
            mov byte ptr [SelectedNumbers + 2], 0
            mov byte ptr [SelectedNumbers + 3], 0
            invoke InvalidateRect, hWnd, NULL, FALSE

            cmp Acount, 4
            je game_over            ; 如果 Acount 等於 4，遊戲結束

            cmp TriesRemaining, 0
            je game_over            ; 如果剩餘機會數為 0，遊戲結束

            ret

        game_over:
        ; 顯示遊戲結束訊息
            call Output
            cmp fromBreakout, 1
            je skipMsg
            invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
        skipMsg:
            invoke DeleteDC, hdcMem
            invoke DestroyWindow, hWnd
            invoke PostQuitMessage, 0
            ret
        .ENDIF
    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke BitBlt, hdcMem, 0, 0, rect.right, rect.right, hdcBack, 0, 0, SRCCOPY  ; 覆蓋位圖
        call UpdateText
        invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps
    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 
skip_button:
    ret
continue_game:
    ret
WndProc1 ENDP

Initialized PROC
    call RandomNumber2
    ;call Output
    mov gameover, 0
    mov SelectedCount, 0
    mov TriesRemaining, 8
    invoke UpdateLineText, OFFSET Line1Text, 0, 0
    invoke UpdateLineText, OFFSET Line2Text, 0, 0
    invoke UpdateLineText, OFFSET Line3Text, 0, 0
    invoke UpdateLineText, OFFSET Line4Text, 0, 0
    invoke UpdateLineText, OFFSET Line5Text, 0, 0
    invoke UpdateLineText, OFFSET Line6Text, 0, 0
    invoke UpdateLineText, OFFSET Line7Text, 0, 0
    invoke UpdateLineText, OFFSET Line8Text, 0, 0
    ret
Initialized ENDP

CalculateResult PROC uses esi edi ecx
    ; 初始化變數
    mov esi, OFFSET Answer  ; 指向隨機數字
    mov edi, OFFSET SelectedNumbers  ; 指向使用者猜測
    mov eax, 0               ; Acount = 0
    mov ebx, 0               ; Bcount = 0

    ; 計算 A (數字與位置都正確)
    mov ecx, 4
CountA:
    mov dl, [esi]              ; 讀取 Answer 的一個字元
    cmp dl, [edi]              ; 與 SelectedNumbers 的對應字元比較
    jne SkipA
    inc eax                    ; 若相同，增加 Acount
SkipA:
    inc esi                    ; 移動到下一個 Answer 字元
    inc edi                    ; 移動到下一個 SelectedNumbers 字元
    loop CountA                ; 重複 4 次

    ; 計算 B (數字正確但位置錯誤)
    mov edi, OFFSET SelectedNumbers  ; 重設 SelectedNumbers 的指標
    mov ecx, 4                 ; Bcount 迴圈次數
CountB:
    push ecx                   ; 儲存外層迴圈次數
    mov dl, [edi]              ; 取 SelectedNumbers 的當前字元
    mov esi, OFFSET Answer  ; 從 Answer 開始檢查
    mov ecx, 4                 ; 重設內層迴圈次數
CheckB:
    cmp dl, [esi]              ; 檢查數字是否正確
    jne NotB
    inc ebx                    ; 增加 Bcount
NotB:
    inc esi                    ; 移動到 Answer 的下一字元
    loop CheckB                ; 檢查所有 Answer 的字元
Next:
    pop ecx                    ; 恢復外層迴圈次數
    inc edi                    ; 移動到 SelectedNumbers 的下一字元
    loop CountB

    sub ebx, eax
    mov esi, OFFSET Acount
    mov [esi], al
    mov edi, OFFSET Bcount
    mov [edi], bl
    ret
CalculateResult ENDP

UpdateLineText PROC, LineText:PTR DWORD, mode: Byte, do:byte
    mov al, do
    .IF mode == 1
        .IF TriesRemaining == al
            mov esi, OFFSET GuessLineText ; 指向 SelectedNumbers
            mov edi, LineText               ; 指向 LineText
            mov ecx, 7                     ; 處理四個數字
            rep movsb

            ; 更新 ACount 到位置 9
            mov al, Acount
            add al, '0'                     ; 將 ACount 轉換成 ASCII 字元
            mov [edi + 6], al               ; 存入 Line1Text 的第 9 個字元位置
            mov al, 'A'
            mov [edi + 8], al
            ; 更新 BCount 到位置 11
            mov al, Bcount
            add al, '0'                     ; 將 BCount 轉換成 ASCII 字元
            mov [edi + 10], al              ; 存入 Line1Text 的第 11 個字元位置
            mov al, 'B'
            mov [edi + 12], al
        .ENDIF
    .ELSE
        mov ecx, 20
        mov al, ' '
        mov edi, LineText
        rep stosb
    .ENDIF
    ret
UpdateLineText ENDP

RandomNumber2 PROC USES eax ecx esi edi edx
    mov ecx, 4
    mov esi, OFFSET Answer ; 載入陣列地址
    mov edx, 0
Pushing:
    push ecx
GenerateLoop:
    push edx
    invoke GetTickCount                ; 生成隨機數
    mov ebx, 10       ; 計算範圍大小
    cdq                        ; 擴展 EAX 為 64 位
    idiv ebx                   ; 除以範圍大小，餘數在 EAX
    mov eax, edx               ; 這是隨機數

    pop edx
    mov edi, OFFSET Answer
    mov ecx, edx
    cmp ecx, 0
    je AddNumber

CheckDuplicate:
    cmp [edi], al
    je GenerateLoop
    inc edi
    loop CheckDuplicate

AddNumber:
    mov [esi], al      ; 存入字元
    inc esi
    inc edx
    pop ecx
    loop Pushing
    ret
RandomNumber2 ENDP

Output PROC
    mov edi, OFFSET Answer
    mov esi, OFFSET AnswerText
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

CreateButton PROC Text:PTR DWORD, x:DWORD, y:DWORD, ID:DWORD, hWnd:HWND
    invoke CreateWindowEx,WS_EX_CLIENTEDGE, ADDR ButtonClassName, Text,\
                        WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_CENTER,\
                        x,y,30,30,hWnd,ID,hInstance,NULL 
    ret
CreateButton ENDP

UpdateText PROC
    invoke SetBkMode, hdcMem, TRANSPARENT
    mov al, [TriesRemaining]       ; 將 TriesRemaining 的值載入 eax
    add al, '0'                     ; 將數字轉換為 ASCII (單位數)
    mov byte ptr [RemainingTriesText + 11], al ; 將字元寫入字串
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

getAdvanced1A2BGame PROC
    mov eax, gameover
    ret
getAdvanced1A2BGame ENDP

Advanced1A2BfromBreakOut PROC
    mov winPosX, 1000
    mov winPosY, 0
    mov fromBreakout, 1
    ret
Advanced1A2BfromBreakOut ENDP


end