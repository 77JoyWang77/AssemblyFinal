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

hMineBitmapName db "mine.bmp",0        ; �a�p�Ϯ�
hMineRedBitmapName db "mine_red.bmp",0 ; �a�p�Ϯ�(���쪺)
hFlagBitmapName db "flag.bmp",0        ; �X�l�Ϯ�
hFlagRedBitmapName db "flag_red.bmp",0 ; �X�l�Ϯ�(������m)
hBackBitmapName db "mine_background.bmp",0
boomOpenCmd db "open boom.wav type mpegvideo alias boomMusic", 0
boomVolumeCmd db "setaudio boomMusic volume to 100", 0
boomPlayCmd db "play boomMusic from 0", 0

winPosX DWORD 400
winPosY DWORD 0

borderX DWORD 80                   ; ��l X �y��
borderY DWORD 160                  ; ��l Y �y��
borderWidth DWORD 240              ; ���x�e��
borderHeight DWORD 240             ; ���x����
winWidth DWORD 400                 ; �����e��
winHeight DWORD 480                ; ��������
line1Rect RECT <20, 60, 120, 140>  ; Remaining Flag Text ��m
line2Rect RECT <280, 60, 380, 140> ; Tine Text ��m
currentID DWORD 10                 ; �ثe������ID
mainh HWND ?                       ; �����y�`

mineWidth EQU 8                    ; �a�Ϫ��e��(column��)
mineHeight EQU 8                   ; �a�Ϫ�����(row��)
mineNum EQU 10                     ; �a�p�ƶq(�@��10��)
mineMapSize EQU 64                 ; �a�ϫ����`��
minerandomSeed DWORD 0             ; �H���ƺؤl
MineX DWORD ?                      ; ����x�y��(�a�ϳ̥��W����(0,0))
MineY DWORD ?                      ; ����y�y��(�a�ϳ̥��W����(0,0))
DirX SDWORD ?                      ; x��V���ܶq
DirY SDWORD ?                      ; y��V���ܶq
endGamebool DWORD 1                ; �P�w������varaible
hButton DWORD mineHeight DUP (mineWidth DUP(?))     ; ����y�`
mineMap SDWORD mineHeight DUP (mineWidth DUP (0))   ; �x�s�a�Ϥ��e(-1:�a�p.0~8:�P�D�a�p�ƶq)
mineState SDWORD mineHeight DUP (mineWidth DUP (0)) ; ������m�����A(0:�����},1:�w���},2:���X)
mineClicked SDWORD mineHeight DUP (mineWidth DUP(0)); ��������O�_�w��ܫ��}(0:�����},1:�w��ܫ��}�᪬�A)
visited DWORD mineHeight DUP (mineWidth DUP(0))     ; �O�_visit�L����m(0:�L,1:��)
mineDir SBYTE -1,-1, 0,-1, 1,-1, -1,0, 1,0, -1,1, 0,1, 1,1 ; �M���ɪ��Ҧ���V(x,y)
flagRemaining db mineNum           ; �Ѿl�ƶq                     
fromBreakout DWORD 0 
Time db 0                          ; �֭p���
winbool DWORD 0                    ; �O�_���


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
    ; ���U�ƹ��k��
    .IF uMsg == WM_RBUTTONDOWN
        invoke GetWindowLong, hWnd, GWL_ID
        sub eax, 10 ; �N����ID�ഫ���a�ϤW������m�s��
        ; �Y�Ӧ�m�����}, setFlag
        cmp SDWORD PTR mineState[eax*4], 0
        je setFlag
        ; �Y�Ӧ�m���X�l, clearflag
        cmp SDWORD PTR mineState[eax*4], 2
        je clearFlag
        jmp EndRight ;�w���}�A���L
    ; ���X
    setFlag:
        ; �Y�X�l�Ѿl�ƶq=0, ���L
        cmp flagRemaining, 0
        je EndRight

        mov SDWORD PTR mineState[eax*4], 2 ; ���ܪ��A�����X
        ; �N�ӫ����W�X�l�Ϯ�
        invoke GetWindowLong, hWnd, GWL_STYLE
        or eax, BS_BITMAP
        invoke SetWindowLong, hWnd, GWL_STYLE, eax
        invoke SendMessage, hWnd, BM_SETIMAGE, IMAGE_BITMAP, hFlagBitmap
        dec flagRemaining ; �X�l�Ѿl�ƶq-1
        jmp EndRight

    ;�޺X
    clearFlag:
        mov SDWORD PTR mineState[eax*4], 0 ; ���ܪ��A�������}
        ; �N�ӫ��s���X�l�Ϯײ��h
        invoke GetWindowLong, hWnd, GWL_STYLE
        and eax, Not BS_BITMAP
        invoke SetWindowLong, hWnd, GWL_STYLE, eax
        invoke SetWindowPos, hWnd, NULL, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOMOVE or SWP_NOSIZE
        inc flagRemaining ;�X�l�Ѿl�ƶq+1

    EndRight:
        ; �I�s��ø
        invoke InvalidateRect, hWnd, NULL, TRUE
        invoke UpdateWindow, hWnd
        invoke InvalidateRect, mainh, NULL, TRUE
        xor eax, eax ; ����T���ǻ�
        ret
    ; ���U�ƹ�����
    .ELSEIF uMsg == WM_LBUTTONDOWN
        invoke GetWindowLong, hWnd, GWL_ID
        sub eax, 10 ; �N����ID�ഫ���a�ϤW������m�s�� 
        ; �Y�Ӧ�m�O���X�l��,���L
        cmp DWORD PTR mineState[eax*4], 2
        je isflag

        ; �N�s���ରxy�y��, �éI�sopen_mine
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

    ; ���U�B�z
    clicked:
        mov DWORD PTR mineClicked[eax*4], 1 ;�N���A�אּ���}
        ; �Y�Ӧ�m�Ȭ�0 or -1, jmp clickMine
        mov eax, DWORD PTR [mineMap + eax*4] 
        cmp eax, 0
        jle clickMine
        ; �N������r��ܩ����W
        push eax
        add al, '0'
        mov byte ptr [ShowText], al
        invoke SetWindowText, hWnd, ADDR ShowText
        pop eax
        jmp skip
  
    ; ����a�p�B�z
    clickMine:
            ; �D�a�p: ���L
            cmp eax, 0
            je skip
            ; �������a�p����
            invoke mciSendString, addr boomOpenCmd, NULL, 0, NULL
            invoke mciSendString, addr boomVolumeCmd, NULL, 0, NULL
            invoke mciSendString, addr boomPlayCmd, NULL, 0, NULL
            mov endGamebool, 1 ;����gameover����
            ; �N����a�p�ɪ��Ϯ���ܩ����
            invoke GetWindowLong, hWnd, GWL_STYLE
            or eax, BS_BITMAP
            invoke SetWindowLong, hWnd, GWL_STYLE, eax
            invoke SendMessage, hWnd, BM_SETIMAGE, IMAGE_BITMAP, hMineRedBitmap
        
    skip:
        mov eax, WS_EX_CLIENTEDGE   ; �M�� WS_EX_CLIENTEDGE �˦�
        invoke SetWindowLong, hWnd, GWL_EXSTYLE, eax
        invoke SetWindowPos, hWnd, NULL, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOMOVE or SWP_NOSIZE

        invoke InvalidateRect, hWnd, NULL, TRUE
        invoke UpdateWindow, hWnd
        xor eax, eax ; ����T���ǻ�

        ; �P�_�O�_��F
        cmp endGamebool, 1
        je lose
        call check ; �ˬd��ӱ���
        ; �P�_�O�_Ĺ�F
        cmp endGamebool, 1
        je win
        ret
    isflag:
            ret
    win:
        mov winbool, 1 ; �����OĹ�����G
        call show_result ; ��ܵ��G�ɪ��a��
        cmp fromBreakout, 1
        je skipMsgWin
        invoke MessageBox, mainh, addr WinGame, addr AppName, MB_OK ; ��{win�T��
    skipMsgWin:
        jmp gameover
    lose:
        call show_result ; ��ܵ��G�ɪ��a��
        cmp fromBreakout, 1
        je skipMsgLose
        invoke MessageBox, mainh, addr LoseGame, addr AppName, MB_OK ; ��{lose�T��
    skipMsgLose:
        jmp gameover

     gameover:
        mov endGamebool, 1 
        ; �R������
        invoke DestroyWindow, mainh
        invoke KillTimer, mainh, 1
        invoke PostQuitMessage, 0
            ret
        ret
    .ENDIF

    ; �եιw�]���f�L�{
    invoke CallWindowProc, OriginalProc, hWnd, uMsg, wParam, lParam
    ret
ButtonSubclassProc endp

WinMain5 proc
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT                   ; �w�q RECT ���c

    invoke GetModuleHandle, NULL 
    mov    hInstance,eax 

    ; �w�q���f���O
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
            winPosX, winPosY, tempWidth, tempHeight, NULL, NULL, hInstance, NULL
    mov   hwnd,eax 
    invoke SetTimer, hwnd, 1, 1000, NULL  ;
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
WinMain5 endp

WndProc5 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hTarget:HWND
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 

     ; �C������,�����R��
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
        invoke KillTimer, hWnd, 1 ;�R���p�ɾ�
        invoke PostQuitMessage,0

    ; Create Window
    .ELSEIF uMsg==WM_CREATE 

        call initialize ;��l�ƦUvariable
        call initialize_map ; ��l�Ʀa��
        mov eax, hWnd 
        mov mainh, eax ;�x�s�����y�`
        mov currentID, 10 ; �_�l����ID
        mov Time, 0 ; �p���k�s
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

        ; �гy����
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
        ; �Ygameover ���A��s�ɶ�
        cmp endGamebool, 1
        jne notskiptime
        ret

        notskiptime:
            inc Time ;��s�ɶ�
            ; ��øTime Text
            invoke InvalidateRect, hWnd, addr line2Rect, TRUE
            invoke UpdateWindow, hWnd

    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        ;invoke ExcludeClipRect, hdc, 80, 160, 320, 400
        invoke BitBlt, hdcMem, 0, 0, winWidth, winHeight, hdcBack, 0, 0, SRCCOPY  ; �л\���
        call update_Text ; ��sRemaining flag Text
        call update_Time ; ��sTime Text
        invoke BitBlt, hdc, 0, 0, winWidth, winHeight, hdcMem, 0, 0, SRCCOPY
        invoke EndPaint, hWnd, addr ps

    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 
WndProc5 endp 

; ��l�ƦUvariable
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

;��l��map
initialize_map proc
    call GetRandomSeed_mine              ; ���o�H���ؤl
    mov eax, minerandomSeed
    mov esi, OFFSET mineMap           ; ��l�ƿj���}�C����
    mov ebx, mineMapSize
    mov ecx, mineNum

CreateMine:
    call RandomLocate            ; ��o�H���a�p��m
    mov eax, MineY               ; eax = MineY
    imul eax, mineWidth          ; eax = MineY * mineWidth
    add eax, MineX               ; eax = MineY * mineWidth + MineX
    shl eax, 2                   ; eax = (MineY * mineWidth + MineX) * 4
    ; �P�_�Ӧ�m�O�_�w�O�a�p
    cmp SDWORD PTR [esi+eax], -1
    jne IsMine

Notmine:
    jmp CreateMine

IsMine:
    mov DWORD PTR [esi+eax], -1 ; �N�Ӧ�]���a�p
    loop CreateMine

; �B�z�a�p�~��L��m���ƭ�
SetValue:
    mov eax, 0
    mov ecx, mineHeight
   
MineRow:
    push ecx
    mov ecx, mineWidth
MineCol:
    ; �ഫ��xy�y��
    push eax
    mov ebx, mineWidth
    xor edx, edx
    div ebx
    mov MineX, edx
    mov MineY, eax
    pop eax
    ; �Y�O�a�p,���L
    cmp DWORD PTR [esi+eax*4], -1
    je Continue
    call calculate_num ; �p��P�D�a�p��
Continue:
    inc eax
    loop MineCol
    pop ecx
    loop MineRow
    ret
initialize_map endp

; �����H����m
RandomLocate proc
    ; �u�ʦP�l�ͦ���: (a * seed + c) % m
    mov ebx, mineMapSize
    mov eax, minerandomSeed
    imul eax, eax, 1664525          ; ���H�Y�� a�]1664525 �O�`�έȡ^
    add eax, 1013904223             ; �[�W�W�q c
    and eax, 7FFFFFFFh             ; �O�ҵ��G������
    mov minerandomSeed, eax             ; ��s�H���ؤl
    xor edx, edx                    ; �M�� edx
    div ebx                           ; ��o�H����m
    mov eax, edx
    ; �ഫ��xy�y�Ш��x�s
    mov ebx, mineWidth
    xor edx, edx
    div ebx
    mov MineX, edx
    mov MineY, eax
    ret
RandomLocate endp

; ���o�H���ؤl
GetRandomSeed_mine proc
    invoke QueryPerformanceCounter, OFFSET minerandomSeed
    ret
GetRandomSeed_mine ENDP

;�p��P�D�a�p�ƶq
calculate_num proc uses eax edx ecx esi
    mov edx, 0                   ; ��l�ƭp�ƾ��A�O���a�p�ƶq
    mov ecx, 8                   ; 8 �Ӥ�V
    mov esi, OFFSET mineDir      ; ���V��V�}�C
    
Calculate:
    mov bh, SBYTE PTR MineY               ; ���o��e��l�� Y �y��
    mov bl, SBYTE PTR MineX               ; ���o��e��l�� X �y��
    ; ���X�P�򪺬۹��m
    mov al, [esi]      ; ���o�۹��m X �����q
    inc esi
    mov ah, [esi]  ; ���o�۹��m Y �����q

    ; �p��۹��m����ڮy��
    add bl, al                  ; �p��۹� X �y�� (MineX + DirX)
    add bh, ah                  ; �p��۹� Y �y�� (MineY + DirY)

    ; �ˬd�Ӧ�m�O�_�W�X���
    cmp bl, 0 
    jl Skip
    cmp bl, mineWidth-1
    jg Skip
    cmp bh, 0
    jl Skip
    cmp bh, mineHeight-1
    jg Skip

    ; �ˬd�Ӧ�m�O�_���a�p 
    push edx
    movzx eax, bh              ; eax = MineY
    imul eax, mineWidth      ; eax = MineY * mineWidth
    movzx ebx, bl
    add eax, ebx              ; eax = MineY * mineWidth + MineX
    shl eax, 2               ; eax = (MineY * mineWidth + MineX) * 4
    pop edx
    cmp SDWORD PTR mineMap[eax], -1
    jne Skip
    ; �W�[�a�p�ƶq
    inc edx
    
Skip:
    ; �p��U�Ӭ۹��m
    inc esi
    loop Calculate

    mov bh, SBYTE PTR MineY               ; ���o��e��l�� Y �y��
    mov bl, SBYTE PTR MineX               ; ���o��e��l�� X �y��
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

; ���}(���ŦX��a�p�W�h,�H���j�B�z)
open_mine proc,
    locateX: DWORD,                ; �{�b��m��x�y��
    locateY: DWORD                 ; �{�b��m��y�y��
    LOCAL now: DWORD               ; �{�b��m���s��
    LOCAL next_l: DWORD            ; �U�Ӧ�m���s��

    ; xy�y���ഫ���s��
    mov eax, locateY            
    imul eax, mineWidth        
    add eax, locateX             
    shl eax, 2
    mov now, eax

    push eax
    invoke SendMessage, hButton[eax], BM_CLICK, 0, 0 ; �N�Ӧ�m��������U
    pop eax

    mov DWORD PTR mineState[eax], 1 ; State�אּ�w���U
    mov DWORD PTR visited[eax], 1   ; �wvisit
    ; �Y�O����a�p, �������}
    cmp SDWORD PTR mineMap[eax],-1
    je Exitopen_mine

    mov esi, OFFSET mineDir ;��V�}�C
    mov ecx, 8              ;8�Ӥ�V
; �P�_�U��m�O�_�i��
allDir:
    mov bh, SBYTE PTR locateY               ; ���o��e��l�� Y �y��
    mov bl, SBYTE PTR locateX               ; ���o��e��l�� X �y��
    ; ���X��V
    mov al, [esi]      ; ���ox��V����
    inc esi
    mov ah, [esi]      ; ���oy��V����

    ; �p��U�Ӧ�m���y��
    add bl, al                  ; �p��U�� X �y�� (MineX + DirX)
    add bh, ah                  ; �p��U�� Y �y�� (MineY + DirY)

    ; �ˬd�Ӧ�m�O�_�W�X���
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
    ; �Yvisit�L,���L(�קK�L�����j)
    cmp DWORD PTR visited[eax], 1 
    je Skip
    ; �Y�w���}�δ��X,���L(�U�Ӧ�m���ਫ)
    cmp DWORD PTR mineState[eax], 0
    jne Skip
    
    mov next_l, eax
    invoke can_go_next, now, next_l ;�P�_�U�Ӧ�m�O�_�i��
    ; ����, ���L
    cmp edx, 0
    je Skip
    push ecx
    push esi
    Invoke open_mine, bl, bh    ;�i�H,�i�J���j
    pop esi
    pop ecx
Skip:
    inc esi
    loop allDir
   
Exitopen_mine:
    mov eax, now
    mov DWORD PTR visited[eax], 0   ;�]����visit
    ret
 open_mine endp

; �P�_�Ӧ�m�O�_�i��
can_go_next proc,
    tempnow: DWORD,     ; �{��m
    tempnext: DWORD,    ; �U�Ӧ�m

    xor edx, edx
    mov eax, tempnow

    ; �Y�{�b�o�Ӧ�m�O0, �h�P�D�ҥi�~��
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

; �ˬdWin����(���a�p�~�ҳQ���})
check proc
    mov eax, 0
    mov ecx, mineMapSize ;���ˬd���a��
checkloop:
    ; �Y�Ӧ쬰�a�p,�ˬd�U�@��
    cmp SDWORD PTR mineMap[eax*4],-1
    je Continuecheck

    ; �Y�Ӧ�D�a�p,�B�D���}���A=>win���󥼹F��
    cmp SDWORD PTR mineClicked[eax*4], 1
    jne gamenotEnd

Continuecheck:
    inc eax
    loop checkloop
    jmp gameEnd ; �Y�������M���L, win����F��

gamenotEnd:
    mov endGamebool, 0 ;��Ĺ
    jmp Exitcheck
gameEnd:
    mov endGamebool, 1 ;Ĺ�F
Exitcheck:
    ret
check endp

; ��ܵ��G(���Q���X���a�p������{, �������X�l�n���)
show_result proc,
   
    mov ecx, mineMapSize
    mov ebx, 0
    Showloop:
        ; �Y�O���X, �n�h�P�_�O�_�����~
        cmp SDWORD PTR mineState[ebx*4], 2
        je falseflag
        ;  �Y�O�w���}, ���L
        cmp SDWORD PTR mineState[ebx*4],1
        je continueShow
        ; �Y�O�a�p, ��{(���ɬO���Q���쪺�a�p�~�|�i��mine)
        cmp SDWORD PTR mineMap[ebx*4], -1
        je mine
        jmp continueShow
    mine:
        call draw_mine ; �I�s��{�a�p
        jmp continueShow
    falseflag:
        ; �Y�O�a�p(���T�����X) ���L
        cmp SDWORD PTR mineMap[ebx*4], -1
        je continueShow
        call draw_falseflag ; �I�s��{���~���X�l
    continueShow:
        inc ebx
        loop Showloop
        ret
show_result endp

; ��{�a�p
draw_mine proc uses ebx ecx
    ; �b����������W��{�a�p�Ϯ�
    invoke GetWindowLong, hButton[ebx*4], GWL_STYLE
    or eax, BS_BITMAP
    invoke SetWindowLong, hButton[ebx*4], GWL_STYLE, eax
    invoke SendMessage, hButton[ebx*4], BM_SETIMAGE, IMAGE_BITMAP, hMineBitmap
    mov eax, WS_EX_CLIENTEDGE   ; �M�� WS_EX_CLIENTEDGE �˦�
    invoke SetWindowLong, hButton[ebx*4], GWL_EXSTYLE, eax
    invoke SetWindowPos, hButton[ebx*4], NULL, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOMOVE or SWP_NOSIZE
    invoke InvalidateRect, hButton[ebx*4], NULL, TRUE
    invoke UpdateWindow, hButton[ebx*4]
    ret
draw_mine endp

; ��{�X�l
draw_falseflag proc uses ebx ecx
     ; �b���������s�W��{���~�X�l�Ϯ�   
     invoke GetWindowLong, hButton[ebx*4], GWL_STYLE
     or eax, BS_BITMAP
     invoke SetWindowLong, hButton[ebx*4], GWL_STYLE, eax
     invoke SendMessage, hButton[ebx*4], BM_SETIMAGE, IMAGE_BITMAP, hFlagRedBitmap
     invoke InvalidateRect, hButton[ebx*4], NULL, TRUE
     invoke UpdateWindow, hButton[ebx*4]
     ret
draw_falseflag endp

; ��s Remaing Flag Text
update_Text proc
    invoke SetBkMode, hdcMem, TRANSPARENT
    mov bl, 10
    xor ah, ah
    mov al, [flagRemaining]       ; �N flagemaining ���ȸ��J eax
    div bl
    mov byte ptr [RemainingFlagsText + 6], ' ' ; �Q��ƹw�]����
    cmp al, 0
    je nextdigit
    add al, '0'                     ; �N�Ʀr�ഫ�� ASCII (����)
    mov byte ptr [RemainingFlagsText + 6], al ; �N�r���g�J�r��
    nextdigit:
        add ah, '0'                     ; �N�Ʀr�ഫ�� ASCII (����)
        mov byte ptr [RemainingFlagsText + 7], ah ; �N�r���g�J�r��
    invoke DrawText, hdcMem, addr RemainingFlagsText, -1, addr line1Rect,DT_CENTER
    ret
update_Text endp

; ��sTime Text
update_Time proc uses eax ebx edx
    invoke SetBkMode, hdcMem, TRANSPARENT
    mov bl, 100
    xor ah, ah
    mov al, Time      ; �N Time���ȸ��J eax
    div bl
    mov byte ptr [TimeText + 6], ' ' ; �ʦ�ƹw�]����
    mov byte ptr [TimeText + 7], ' ' ; �Q��ƹw�]����

    ; Time<100
    cmp al, 0
    je lessthanhundred
    add al, '0'                     ; �N�Ʀr�ഫ�� ASCII (����)
    mov byte ptr [TimeText + 6], al ; �N�r���g�J�r��
    mov byte ptr [TimeText + 7], '0'; �Q��ƹw�]��0

    lessthanhundred:
        mov bl, 10
        mov al, ah
        xor ah, ah
        div bl
        ; �Q��Ƭ�0, �����B�z�Ӧ��
        cmp al, 0
        je nextdigit
        add al, '0'                     ; �N�Ʀr�ഫ�� ASCII (����)
        mov byte ptr [TimeText + 7], al ; �N�r���g�J�r��

     nextdigit:
        add ah, '0'                     ; �N�Ʀr�ഫ�� ASCII (����)
        mov byte ptr [TimeText + 8], ah ; �N�r���g�J�r��
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
