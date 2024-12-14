.386 
.model flat,stdcall 
option casemap:none 

RGB macro red,green,blue
	xor eax,eax
	mov ah,blue
	shl eax,8
	mov ah,green
	mov al,red
endm

include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 
include gdi32.inc
include gdiplus.inc
includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib
includelib gdiplus.lib

WinMain proto :DWORD
UpdateLineText PROTO, LineText:PTR SDWORD, mode: Byte, do:byte
CreateButton PROTO Text:PTR SDWORD, x:SDWORD, y:SDWORD, ID:SDWORD, hWnd:HWND

.DATA 
ClassName db "SimpleWinClass", 0 
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
SelectedCount   dd 0
TriesRemaining  db 8
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
line1Rect RECT <20, 20, 250, 40>
line2Rect RECT <20, 50, 250, 70> 
line3Rect RECT <20, 80, 250, 100>
line4Rect RECT <20, 110, 250, 130>
line5Rect RECT <20, 140, 250, 160>
line6Rect RECT <20, 170, 250, 190>
line7Rect RECT <20, 200, 250, 220>
line8Rect RECT <20, 230, 250, 250>
line9Rect RECT <20, 280, 250, 300>

bgImagePath db "picture\\Remaining.jpg", 0
hImage      DWORD ?

.DATA? 
hInstance HINSTANCE ? 
CommandLine LPSTR ? 
SelectedNumbers db 4 dup(?)
Answer db 4 DUP(?)
Acount byte ? 
Bcount byte ? 
hBrush DWORD ?

.CODE 
Advanced1A2B PROC 
start: 
    call RandomNumber2
    call Output
    invoke GetModuleHandle, NULL 
    mov    hInstance,eax 
    invoke GetCommandLine
    mov CommandLine,eax
    invoke WinMain, hInstance
    ret
Advanced1A2B ENDP

WinMain proc hInst:HINSTANCE
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT                   ; �w�q RECT ���c
    LOCAL winWidth:DWORD            ; �O�s���f�e��
    LOCAL winHeight:DWORD           ; �O�s���f����

    ; �w�q���f���O
    mov   wc.cbSize,SIZEOF WNDCLASSEX 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc 
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

    ; �]�m�ؼЫȤ�Ϥj�p
    mov wr.left, 0
    mov wr.top, 0
    mov wr.right, 270
    mov wr.bottom, 400

    ; �վ㵡�f�j�p
    invoke AdjustWindowRect, ADDR wr, WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, FALSE

    ; �p�ⵡ�f�e�שM����
    mov eax, wr.right
    sub eax, wr.left
    mov winWidth, eax

    mov eax, wr.bottom
    sub eax, wr.top
    mov winHeight, eax

    RGB    255,255,255
    invoke CreateSolidBrush, eax  ; �Ыج��ⵧ��
    mov hBrush, eax

    ; �Ыص��f
    invoke CreateWindowEx, NULL, ADDR ClassName, ADDR AppName, \
            WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, \
            CW_USEDEFAULT, CW_USEDEFAULT, winWidth, winHeight, \
            NULL, NULL, hInst, NULL
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
WinMain endp


WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT 

    .IF uMsg==WM_DESTROY 
        invoke PostQuitMessage,NULL 
        invoke DestroyWindow, hWnd
        ret
    .ELSEIF uMsg==WM_CLOSE
        invoke PostQuitMessage,NULL 
        invoke DestroyWindow, hWnd
        ret
    .ELSEIF uMsg==WM_CREATE 
        ; Create the buttons for numbers 1 to 9
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

        invoke GdiplusStartup, addr gdiPlusToken, addr gdiPlusStartupInput, NULL
    invoke GdipLoadImageFromFile, addr bgImagePath, addr hImage
    cmp eax, 0
    jne skip_loading

    .ELSEIF uMsg == WM_COMMAND
        mov eax, wParam

        ; ���U�Ʀr���s
        .IF eax >= 10 && eax <= 19
            ; �T�{�O�_�w�ﺡ
            mov ecx, SelectedCount
            cmp ecx, 4
            jae skip_button ; �Y�w�ﺡ�A���L���s�B�z

            sub eax, 10

            ; �x�s����Ʀr�øT�Ϋ��s
            mov [SelectedNumbers + ecx], al
            add al, '0'
            mov [GuessLineText + 2* ecx], al
            inc SelectedCount

            mov eax, wParam
            invoke GetDlgItem, hWnd, eax
            invoke EnableWindow, eax, FALSE
            ;invoke MessageBox, NULL, addr GuessLineText, NULL, MB_OK 

            invoke InvalidateRect, hWnd, NULL, TRUE

        ; ���U Delete ���s
        .ELSEIF eax == 21
            ; �ˬd�O�_���w��ܪ��Ʀr
            mov eax, SelectedCount
            cmp eax, 0
            je skip_button  ; �S����ܹL�Ʀr�A���L

            ; �R���̪񪺿��
            dec SelectedCount
            dec eax
            movzx ecx, [SelectedNumbers + eax] ; ���X�̪�@�ӿ��
            mov [SelectedNumbers + eax], 0  ; �M���ӿ��
            mov [GuessLineText + 2 * eax], ' '  ; �M���ӿ��

            add ecx, 10
            ; �ҥθӫ��s
            invoke GetDlgItem, hWnd, ecx
            invoke EnableWindow, eax, TRUE
            ;invoke MessageBox, NULL, addr GuessLineText, NULL, MB_OK

            ; ��s���
            invoke InvalidateRect, hWnd, NULL, TRUE
        .ELSEIF eax == 22
            mov eax, SelectedCount
            cmp eax, 4
            jne skip_button  ; �S����ܹL�Ʀr�A���L
            call CalculateResult
            dec TriesRemaining

            invoke UpdateLineText, OFFSET Line1Text, 1, 7
            invoke UpdateLineText, OFFSET Line2Text, 1, 6
            invoke UpdateLineText, OFFSET Line3Text, 1, 5
            invoke UpdateLineText, OFFSET Line4Text, 1, 4
            invoke UpdateLineText, OFFSET Line5Text, 1, 3
            invoke UpdateLineText, OFFSET Line6Text, 1, 2
            invoke UpdateLineText, OFFSET Line7Text, 1, 1

            mov edi, OFFSET GuessLineText
            mov ecx, 7
            mov al, ' '
            reset_loop:
            mov [edi], al             ; �]�m���e�r�����Ů�
            inc edi                   ; ���ʨ�U�@�Ӧr��
            loop reset_loop

            mov SelectedCount, 0
            ; ���s�ҥΩҦ����s
            mov ecx, 10                ; �]�m�`�����Ƭ� 10�A���ܱҥ� 10 �ӫ��s
            mov ebx, 10                 ; �]�m���s ID �q 0 �}�l
            Reset:
                push ecx
                invoke GetDlgItem, hWnd, ebx     ; ������s���y�`
                invoke EnableWindow, eax, TRUE   ; �ҥθӫ��s
                pop ecx
                inc ebx                 ; �W�[���s ID
                loop Reset              ; �`������ ecx �� 0

            mov byte ptr [SelectedNumbers], 0
            mov byte ptr [SelectedNumbers + 1], 0
            mov byte ptr [SelectedNumbers + 2], 0
            mov byte ptr [SelectedNumbers + 3], 0
            invoke InvalidateRect, hWnd, NULL, TRUE

            cmp Acount, 4
            je game_over            ; �p�G Acount ���� 4�A�C������

            cmp TriesRemaining, 0
            je game_over            ; �p�G�Ѿl���|�Ƭ� 0�A�C������

            ret

        game_over:
        ; ��ܹC�������T��
            call Output
            call Initialized
            invoke MessageBox, hWnd, addr EndGame, addr AppName, MB_OK
            invoke PostQuitMessage, 0
            invoke DestroyWindow, hWnd
            ret

        .ENDIF
    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        ; �ϥ� GDI+ ø�s�I���Ϲ�
        invoke GdipCreateFromHDC, hdc, addr graphics
        invoke GdipDrawImageRect, graphics, hImage, 0.0, 0.0, 270.0, 400.0
        invoke GdipDeleteGraphics, graphics
        invoke DrawText, hdc, addr RemainingTriesText, -1, addr line1Rect, DT_CENTER
        invoke GetClientRect, hWnd, addr rect
        mov al, [TriesRemaining]       ; �N TriesRemaining ���ȸ��J eax
        add al, '0'                     ; �N�Ʀr�ഫ�� ASCII (����)
        mov byte ptr [RemainingTriesText + 11], al ; �N�r���g�J�r��
        invoke DrawText, hdc, addr RemainingTriesText, -1, addr line1Rect,DT_CENTER
        invoke DrawText, hdc, addr GuessLineText, -1, addr line9Rect,DT_CENTER
        invoke DrawText, hdc, addr Line1Text, -1, addr line2Rect,DT_CENTER
        invoke DrawText, hdc, addr Line2Text, -1, addr line3Rect,DT_CENTER
        invoke DrawText, hdc, addr Line3Text, -1, addr line4Rect,DT_CENTER
        invoke DrawText, hdc, addr Line4Text, -1, addr line5Rect,DT_CENTER
        invoke DrawText, hdc, addr Line5Text, -1, addr line6Rect,DT_CENTER
        invoke DrawText, hdc, addr Line6Text, -1, addr line7Rect,DT_CENTER
        invoke DrawText, hdc, addr Line7Text, -1, addr line8Rect,DT_CENTER

        invoke EndPaint, hWnd, addr ps

    .ELSEIF uMsg == WM_DESTROY
    ; �M�z GDI+ �귽
        invoke GdipDisposeImage, hImage
        invoke GdiplusShutdown, gdiPlusToken
        invoke PostQuitMessage, 0
        ret

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
WndProc endp 

CalculateResult PROC uses esi edi ecx
    ; ��l���ܼ�
    mov esi, OFFSET Answer  ; ���V�H���Ʀr
    mov edi, OFFSET SelectedNumbers  ; ���V�ϥΪ̲q��
    mov eax, 0               ; Acount = 0
    mov ebx, 0               ; Bcount = 0

    ; �p�� A (�Ʀr�P��m�����T)
    mov ecx, 4
CountA:
    mov dl, [esi]              ; Ū�� Answer ���@�Ӧr��
    cmp dl, [edi]              ; �P SelectedNumbers �������r�����
    jne SkipA
    inc eax                    ; �Y�ۦP�A�W�[ Acount
SkipA:
    inc esi                    ; ���ʨ�U�@�� Answer �r��
    inc edi                    ; ���ʨ�U�@�� SelectedNumbers �r��
    loop CountA                ; ���� 4 ��

    ; �p�� B (�Ʀr���T����m���~)
    mov edi, OFFSET SelectedNumbers  ; ���] SelectedNumbers ������
    mov ecx, 4                 ; Bcount �j�馸��
CountB:
    push ecx                   ; �x�s�~�h�j�馸��
    mov dl, [edi]              ; �� SelectedNumbers �����e�r��
    mov esi, OFFSET Answer  ; �q Answer �}�l�ˬd
    mov ecx, 4                 ; ���]���h�j�馸��
CheckB:
    cmp dl, [esi]              ; �ˬd�Ʀr�O�_���T
    jne NotB
    inc ebx                    ; �W�[ Bcount
NotB:
    inc esi                    ; ���ʨ� Answer ���U�@�r��
    loop CheckB                ; �ˬd�Ҧ� Answer ���r��
Next:
    pop ecx                    ; ��_�~�h�j�馸��
    inc edi                    ; ���ʨ� SelectedNumbers ���U�@�r��
    loop CountB

    sub ebx, eax
    mov esi, OFFSET Acount
    mov [esi], al
    mov edi, OFFSET Bcount
    mov [edi], bl
    ret
CalculateResult ENDP

UpdateLineText PROC, LineText:PTR SDWORD, mode: Byte, do:byte
    mov al, do
    .IF mode == 1
        .IF TriesRemaining == al
            mov esi, OFFSET GuessLineText ; ���V SelectedNumbers
            mov edi, LineText               ; ���V LineText
            mov ecx, 7                     ; �B�z�|�ӼƦr
            rep movsb

            ; ��s ACount ���m 9
            mov al, Acount
            add al, '0'                     ; �N ACount �ഫ�� ASCII �r��
            mov [edi + 6], al               ; �s�J Line1Text ���� 9 �Ӧr����m
            mov al, 'A'
            mov [edi + 8], al
            ; ��s BCount ���m 11
            mov al, Bcount
            add al, '0'                     ; �N BCount �ഫ�� ASCII �r��
            mov [edi + 10], al              ; �s�J Line1Text ���� 11 �Ӧr����m
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
    mov esi, OFFSET Answer ; ���J�}�C�a�}
    mov edx, 0
Pushing:
    push ecx
GenerateLoop:
    push edx
    invoke GetTickCount                ; �ͦ��H����
    mov ebx, 10       ; �p��d��j�p
    cdq                        ; �X�i EAX �� 64 ��
    idiv ebx                   ; ���H�d��j�p�A�l�Ʀb EAX
    mov eax, edx               ; �o�O�H����

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
    mov [esi], al      ; �s�J�r��
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

Initialized PROC
    mov SelectedCount, 0
    mov TriesRemaining, 8
    invoke UpdateLineText, OFFSET Line1Text, 0, 0
    invoke UpdateLineText, OFFSET Line2Text, 0, 0
    invoke UpdateLineText, OFFSET Line3Text, 0, 0
    invoke UpdateLineText, OFFSET Line4Text, 0, 0
    invoke UpdateLineText, OFFSET Line5Text, 0, 0
    invoke UpdateLineText, OFFSET Line6Text, 0, 0
    invoke UpdateLineText, OFFSET Line7Text, 0, 0
    ret
Initialized ENDP

CreateButton PROC Text:PTR SDWORD, x:SDWORD, y:SDWORD, ID:SDWORD, hWnd:HWND
    invoke CreateWindowEx,WS_EX_CLIENTEDGE, ADDR ButtonClassName, Text,\
                        WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or BS_CENTER,\
                        x,y,30,30,hWnd,ID,hInstance,NULL 
    ret
CreateButton ENDP
end