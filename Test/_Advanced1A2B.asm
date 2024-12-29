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

; ����/�I��
hBackBitmapName db "bmp/1A2B_background.bmp",0
clickOpenCmd db "open bmp/click.wav type mpegvideo alias clickMusic", 0
clickVolumeCmd db "setaudio clickMusic volume to 100", 0
clickPlayCmd db "play clickMusic from 0", 0

; �����m
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

winWidth DWORD 270             ; �O�s���f�e��
winHeight DWORD 400            ; �O�s���f����
winPosX DWORD 400              ; �ù���m X �y��
winPosY DWORD 0                ; �ù���m Y �y��
gameover BOOL TRUE             ; �C���������A
fromBreakout BOOL FALSE        ; �q Breakout �}�ҹC��

.DATA? 
hInstance HINSTANCE ?          ; �{����ҥy�`
hBitmap HBITMAP ?              ; ��ϥy�`
hBackBitmap HBITMAP ?          ; �I����ϥy�`
hBackBitmap2 HBITMAP ?         ; �ĤG�I����ϥy�`
hdcMem HDC ?                   ; �O����]�ƤW�U��
hdcBack HDC ?                  ; �I���]�ƤW�U��

SelectedCount DWORD ?          ; �H��Ʀr�ƥ�
TriesRemaining BYTE ?          ; �Ѿl����
SelectedNumbers db 4 dup(?)    ; �����w��Ʀr
Answer db 4 DUP(?)             ; �ؼмƦr
Acount byte ?                  ; A ���ƥ�
Bcount byte ?                  ; B ���ƥ�
tempWidth DWORD ?              ; �Ȧs�e��
tempHeight DWORD ?             ; �Ȧs����

.CODE 
; �Ыص���
WinMain1 proc

    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT

    invoke GetModuleHandle, NULL 
    mov hInstance,eax 

    ; ��l�Ƶ��f��
    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET WndProc1
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

    ; �]�m�Ȥ�Ϥj�p
    mov wr.left, 0
    mov wr.top, 0
    mov eax, winWidth
    mov wr.right, eax
    mov eax, winHeight
    mov wr.bottom, eax

    ; �վ㵡�f�j�p
    invoke AdjustWindowRect, ADDR wr, WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, FALSE
    mov eax, wr.right
    sub eax, wr.left
    mov tempWidth, eax
    mov eax, wr.bottom
    sub eax, wr.top
    mov tempHeight, eax

    ; �Ыص��f
    invoke CreateWindowEx, NULL, ADDR ClassName, ADDR AppName, \
            WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, \
            winPosX, winPosY, tempWidth, tempHeight, \
            NULL, NULL, hInstance, NULL
    mov   hwnd,eax 

    ; ��ܩM��s���f
    invoke ShowWindow, hwnd,SW_SHOWNORMAL 
    invoke UpdateWindow, hwnd 

    ; �D�����`��
    .WHILE TRUE 
        invoke GetMessage, ADDR msg,NULL,0,0 
    .BREAK .IF (!eax) 
        invoke TranslateMessage, ADDR msg 
        invoke DispatchMessage, ADDR msg 
    .ENDW 
    mov     eax,msg.wParam 
    ret 

WinMain1 endp

; �����B��
WndProc1 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT 

    .IF uMsg == WM_CREATE 

        ; ��l�ƹC���귽
        call Initialized

        ; �[�����
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap, eax
        invoke LoadImage, hInstance, addr hBackBitmapName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_DEFAULTCOLOR
        mov hBackBitmap2, eax

        ; ��l�Ƶe��
        invoke GetDC, hWnd              
        mov hdc, eax
        invoke CreateCompatibleDC,hdc  
        mov hdcMem, eax
        invoke CreateCompatibleDC,hdc 
        mov hdcBack, eax
        invoke SelectObject, hdcMem, hBackBitmap
        invoke SelectObject, hdcBack, hBackBitmap2
        invoke GetClientRect, hWnd, addr rect
        
        ; ��l�ƫ��s
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
        
        ; ���䭵��
        invoke mciSendString, addr clickOpenCmd, NULL, 0, NULL
        invoke mciSendString, addr clickVolumeCmd, NULL, 0, NULL
        invoke mciSendString, addr clickPlayCmd, NULL, 0, NULL

        mov eax, wParam
        ; �Ʀr���s
        .IF eax >= 10 && eax <= 19

            ; �T�{�O�_�w�ﺡ
            mov ecx, SelectedCount
            cmp ecx, 4
            jae skip_button

            ; �x�s����Ʀr
            sub eax, 10
            mov [SelectedNumbers + ecx], al
            add al, '0'
            mov [GuessLineText + 2* ecx], al
            inc SelectedCount

            ; �T�θӫ��s
            mov eax, wParam
            invoke GetDlgItem, hWnd, eax
            invoke EnableWindow, eax, FALSE

            invoke InvalidateRect, hWnd, NULL, FALSE    ; ��s�e��

        ; Delete ���s
        .ELSEIF eax == 21

            ; �ˬd�O�_���w��ܪ��Ʀr
            mov eax, SelectedCount
            cmp eax, 0
            je skip_button

            ; �R���̪񪺿��
            dec SelectedCount
            dec eax
            movzx ecx, [SelectedNumbers + eax]    ; ���X�̪�@�ӿ��
            mov [SelectedNumbers + eax], 0
            mov [GuessLineText + 2 * eax], ' '

            ; �ҥθӫ��s
            add ecx, 10
            invoke GetDlgItem, hWnd, ecx
            invoke EnableWindow, eax, TRUE

            ; ��s���
            invoke InvalidateRect, hWnd, NULL, FALSE    ; ��s�e��

        ; OK ���s
        .ELSEIF eax == 22
            
            ; �T�{�O�_�w�ﺡ
            mov eax, SelectedCount
            cmp eax, 4
            jne skip_button

            ; �p�⵲�G
            call CalculateResult
            dec TriesRemaining
            mov SelectedCount, 0

            ; ��s���v���
            invoke UpdateLineText, OFFSET Line1Text, 1, 7
            invoke UpdateLineText, OFFSET Line2Text, 1, 6
            invoke UpdateLineText, OFFSET Line3Text, 1, 5
            invoke UpdateLineText, OFFSET Line4Text, 1, 4
            invoke UpdateLineText, OFFSET Line5Text, 1, 3
            invoke UpdateLineText, OFFSET Line6Text, 1, 2
            invoke UpdateLineText, OFFSET Line7Text, 1, 1
            invoke UpdateLineText, OFFSET Line8Text, 1, 0

            ; ��l�Ʋq��������r
            mov edi, OFFSET GuessLineText
            mov ecx, 7
            mov al, ' '
            reset_loop:
            mov [edi], al
            inc edi
            loop reset_loop

            ; ���s�ҥΩҦ����s
            mov ecx, 10
            mov ebx, 10
            Reset:
                push ecx
                invoke GetDlgItem, hWnd, ebx
                invoke EnableWindow, eax, TRUE
                pop ecx
                inc ebx
                loop Reset
            
            ; ��l�Ʋq�������}�C
            mov byte ptr [SelectedNumbers], 0
            mov byte ptr [SelectedNumbers + 1], 0
            mov byte ptr [SelectedNumbers + 2], 0
            mov byte ptr [SelectedNumbers + 3], 0

            invoke InvalidateRect, hWnd, NULL, FALSE    ; ��s�e��

            cmp Acount, 4
            je game_over            ; �p�G Acount ���� 4�A�C������

            cmp TriesRemaining, 0
            je game_over            ; �p�G�Ѿl���|�Ƭ� 0�A�C������

            ret

        game_over:
            ; ��ܹC�������T��
            call Output
            cmp fromBreakout, TRUE
            je skipMsg
            invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
        skipMsg:
            invoke PostMessage, hWnd, WM_DESTROY, 0, 0
            ret
        .ENDIF

    .ELSEIF uMsg == WM_PAINT
        
        ; ø�s�e��
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke BitBlt, hdcMem, 0, 0, winWidth, winHeight, hdcBack, 0, 0, SRCCOPY
        call UpdateText
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps

    .ELSEIF uMsg==WM_DESTROY 

        cmp fromBreakout, FALSE
        je getDestory

        ; ��^���G
        cmp Acount, 4
        jne notWin
        mov eax, 1
        call backBreakOut
        jmp getDestory

    notWin:
        mov eax, -1
        call backBreakOut

    getDestory:
        ; �M�z�귽
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

; ��l�ƹC��
Initialized PROC

    call RandomNumber2
    mov gameover, FALSE
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
    
Initialized ENDP

; �p�⵲�G
CalculateResult PROC uses esi edi ecx

    mov esi, OFFSET Answer
    mov edi, OFFSET SelectedNumbers
    mov eax, 0
    mov ebx, 0

    ; �p�� A (�Ʀr�P��m�����T)
    mov ecx, 4
CountA:
    mov dl, [esi]
    cmp dl, [edi]
    jne SkipA
    inc eax
SkipA:
    inc esi
    inc edi
    loop CountA

    ; �p�� B (�Ʀr���T����m���~)
    mov edi, OFFSET SelectedNumbers
    mov ecx, 4
CountB:
    push ecx
    mov dl, [edi]
    mov esi, OFFSET Answer
    mov ecx, 4
CheckB:
    cmp dl, [esi]
    jne NotB
    inc ebx
NotB:
    inc esi
    loop CheckB
Next:
    pop ecx
    inc edi
    loop CountB

    ; ��������
    sub ebx, eax
    mov esi, OFFSET Acount
    mov [esi], al
    mov edi, OFFSET Bcount
    mov [edi], bl
    ret
CalculateResult ENDP

; ��s������r
UpdateLineText PROC, LineText:PTR DWORD, mode: Byte, do:byte
    mov al, do

    ; �������v�q���A�ھ� TriesRemaining�A��s�s���@��
    .IF mode == 1
        .IF TriesRemaining == al
            ; �g�J�q������
            mov esi, OFFSET GuessLineText
            mov edi, LineText
            mov ecx, 7
            rep movsb

            ; �g�J ACount
            mov al, Acount
            add al, '0'
            mov [edi + 6], al
            mov al, 'A'
            mov [edi + 8], al

            ; �g�J BCount
            mov al, Bcount
            add al, '0'
            mov [edi + 10], al
            mov al, 'B'
            mov [edi + 12], al
        .ENDIF
    
    ; ��l��
    .ELSE
        mov ecx, 20
        mov al, ' '
        mov edi, LineText
        rep stosb
    .ENDIF
    ret
UpdateLineText ENDP

; ��o 4 �Ӥ����ƪ��H���Ʀr
RandomNumber2 PROC USES eax ecx esi edi edx

    mov ecx, 4
    mov esi, OFFSET Answer
    mov edx, 0
Pushing:
    push ecx
GenerateLoop:
    push edx
    invoke GetTickCount       ; �ϥήɶ���ؤl
    mov ebx, 10
    cdq
    idiv ebx
    mov eax, edx              ; �H���Ʀr

    ; �ˬd�O�_����
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
    ; �s�J�r��
    mov [esi], al
    inc esi
    inc edx
    pop ecx
    loop Pushing
    ret

RandomNumber2 ENDP

; �N������r��üu�X����
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

; ��l�ƫ��s
CreateButton PROC Text:PTR DWORD, x:DWORD, y:DWORD, ID:DWORD, hWnd:HWND
    invoke CreateWindowEx,WS_EX_CLIENTEDGE, ADDR ButtonClassName, Text,\
                        WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_CENTER,\
                        x,y,30,30,hWnd,ID,hInstance,NULL 
    ret
CreateButton ENDP

; ��s�e��
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

; ��^�C�����A
getAdvanced1A2BGame PROC
    mov eax, gameover
    ret
getAdvanced1A2BGame ENDP

; �]�m�C���ӷ�
Advanced1A2BfromBreakOut PROC
    mov winPosX, 1000
    mov winPosY, 0
    mov fromBreakout, TRUE
    ret
Advanced1A2BfromBreakOut ENDP
end