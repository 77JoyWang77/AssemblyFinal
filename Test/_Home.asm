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

WinMain2 proto :DWORD,:DWORD,:DWORD,:DWORD 
include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc 

.DATA 
ClassName db "SimpleWinClass",0 
AppName  db "Home",0 
Text db "Window", 0
platform_X DWORD 350           ; ��l X �y��
platform_Y DWORD 550           ; ��l Y �y��
platform_Width DWORD 120       ; ���x�e��
platform_Height DWORD 20       ; ���x����
stepSize DWORD 10              ; �C�����ʪ������ƶq
winWidth DWORD 800              ; �����e��
winHeight DWORD 600             ; ��������
ballX DWORD 400                 ; �p�y X �y��
ballY DWORD 400                 ; �p�y Y �y��
velocityX DWORD 0               ; �p�y X ��V�t��
velocityY DWORD 10               ; �p�y Y ��V�t��
ballRadius DWORD 10             ; �p�y�b�|
brickNumX EQU 10
brickNumY EQU 8
brick DWORD brickNumY DUP(brickNumX DUP(1))
brickWidth EQU 80
brickHeight EQU 20
divisor DWORD 180
offset_center DWORD 0
speed DWORD 10
brickNum DWORD 10
controlsCreated DWORD 0

.DATA? 
hInstance1 HINSTANCE ? 
CommandLine LPSTR ? 
tempWidth DWORD ?
tempHeight DWORD ?
tempWidth1 DWORD ?
tempHeight1 DWORD ?
hBrush DWORD ?

.CODE 
Home PROC 
start: 
    
    invoke GetModuleHandle, NULL 
    mov    hInstance1,eax 
    invoke GetCommandLine
    mov CommandLine,eax
    invoke WinMain2, hInstance1,NULL,CommandLine, SW_SHOWDEFAULT 
    ret
Home ENDP

WinMain2 proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD 
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    LOCAL wr:RECT                   ; �w�q RECT ���c

    ; �w�q���f���O
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

    ; �]�m�ؼЫȤ�Ϥj�p
    mov wr.left, 0
    mov wr.top, 0
    mov wr.right, 800
    mov wr.bottom, 600

    ; �վ㵡�f�j�p
    invoke AdjustWindowRect, ADDR wr, WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, FALSE

    ; �p�ⵡ�f�e�שM����
    mov eax, wr.right
    sub eax, wr.left
    mov winWidth, eax

    mov eax, wr.bottom
    sub eax, wr.top
    mov winHeight, eax

    ; �Ыص��f
    invoke CreateWindowEx, NULL, ADDR ClassName, ADDR AppName, \
            WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, \
            0, 0, winWidth, winHeight, \
            NULL, NULL, hInst, NULL
    mov   hwnd,eax 
    invoke SetTimer, hwnd, 1, 50, NULL  ; ��s���j�q 50ms �אּ 10ms

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
WinMain2 endp


WndProc2 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    LOCAL hdc:HDC 
    LOCAL ps:PAINTSTRUCT 
    LOCAL rect:RECT
    LOCAL brickX, brickY:DWORD

    .IF uMsg==WM_DESTROY 
        invoke KillTimer, hWnd, 1
        ; �o�e�h�X�T��
        invoke PostQuitMessage, NULL
        ret
    .ELSEIF uMsg == WM_TIMER
        ; ��s�p�y��m
        call update_ball

        ; �˴����x�I��
        call check_platform_collision

            invoke GetAsyncKeyState, VK_LEFT
            test eax, 8000h ; ���ճ̰���
            jz skip_left
            mov eax, platform_X
            cmp eax, stepSize
            jl skip_left
            sub eax, stepSize
            mov platform_X, eax
        skip_left:

        invoke GetAsyncKeyState, VK_RIGHT
            test eax, 8000h ; ���ճ̰���
            jz skip_right
            mov eax, platform_X
            add eax, stepSize
            add eax, platform_Width
            cmp eax, winWidth
            jg skip_right
            mov eax, platform_X
            add eax, stepSize
            mov platform_X, eax
        skip_right:
        call brick_collision

        ; ��ø����
        invoke InvalidateRect, hWnd, NULL, TRUE

    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke GetClientRect, hWnd, addr rect
        RGB    200,200,50
        invoke CreateSolidBrush, eax  ; �Ыج��ⵧ��
        mov hBrush, eax                          ; �s����y�`
        invoke SelectObject, hdc, hBrush
        ; ø�s�p�y
        mov eax, ballX
        sub eax, ballRadius
        mov ecx, ballY
        sub ecx, ballRadius
        mov edx, ballX
        add edx, ballRadius
        mov esi, ballY
        add esi, ballRadius
        invoke Ellipse, hdc, eax, ecx, edx, esi

        ; ø�s���x
        mov eax, platform_X
        add eax, platform_Width
        mov edx, platform_Y
        add edx, platform_Height
        mov [tempWidth], eax
        mov [tempHeight], edx
        invoke Rectangle, hdc, platform_X, platform_Y, tempWidth, tempHeight

        ; ø�s�j��
        mov esi, OFFSET brick
        mov eax, 0              ; eax �Ω�C�`��
        mov ecx, brickNumY      ; ecx �Ω��`��
    DrawBrickRow:
        push ecx
        mov ecx, brickNumX      ; �C��j�����ƶq
    DrawBrickCol:
        xor edx, edx
	    push eax
	    mov ebx, brickNumX
	    div ebx

        push edx
        mov ebx, brickHeight
        mul ebx
        mov brickY, eax
        pop edx
        
        mov eax, edx
        mov ebx, brickWidth
        mul ebx
        mov brickX, eax

        pop eax
        cmp DWORD PTR [esi+eax*4], 1  ; �ˬd�O�_ø�s���j��
        je DrawBrick1
        jmp Continue

    DrawBrick1:
        push eax
        push edx
        mov eax, brickX
        add eax, brickWidth
        mov edx, brickY
        add edx, brickHeight
        mov [tempWidth], eax
        mov [tempHeight], edx
        pop edx
        pop eax
        push eax
        push ecx
        invoke Rectangle, hdc, brickX, brickY, tempWidth, tempHeight
        pop ecx
        pop eax
    Continue:
        
        inc eax
        loop DrawBrickCol
        pop ecx
        loop DrawBrickRow

    endDrawBrick:
        invoke EndPaint, hWnd, addr ps

    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret
    .ENDIF 
    xor   eax, eax 
    ret 
WndProc2 endp 

update_ball PROC
    ; ��s�p�y��m
    mov eax, ballX
    add eax, velocityX
    mov ballX, eax

    mov eax, ballY
    add eax, velocityY
    mov ballY, eax

    ; ��ɸI���˴��]�譱�Ϯg�^
    mov eax, ballX
    cmp eax, ballRadius           ; �I�쥪���
    jle reverse_x

    mov eax, winWidth
    sub eax, ballRadius
    cmp ballX, eax                ; �I��k���
    jae reverse_x

    mov eax, ballY
    cmp eax, ballRadius           ; �I��W���
    jle reverse_y

    mov eax, winHeight
    sub eax, ballRadius
    cmp ballY, eax                ; �I��U���
    jae reverse_y

    jmp end_update                ; �Y�L�I���A����

reverse_x:
    mov eax, velocityX
    neg eax
    mov velocityX, eax
    jmp end_update

reverse_y:
    mov eax, velocityY
    neg eax
    mov velocityY, eax

end_update:
    ret
update_ball ENDP

check_platform_collision PROC
    ; �ˬd�O�_�b���x�������d��
    mov eax, ballX
    mov ebx, platform_X
    cmp eax, ebx
    jl no_collision

    mov ecx, platform_Width
    add ebx, ecx
    cmp eax, ebx
    ja no_collision

    ; �ˬd�O�_�b���x�������d��
    mov eax, ballY
    mov ebx, platform_Y
    add eax, ballRadius
    cmp eax, ebx
    jl no_collision
    sub ebx, ballRadius
    mov ballY, ebx

    ; �I���B�z
    mov eax, 150
    add eax, platform_X
    sub eax, ballX
    mov offset_center, eax

    ; �p�⩷��
    fild offset_center           ; ���J���׭�            
    fldpi                        ; ���J �k
    fild divisor                 ; ���J 180
    fdiv                         ; �p�� �k / 180
    fmul                         ; �p�⩷��

    ; �p��t�פ��q
    fld st(0)                    ; ���׭�
    fcos                         ; �p�� cos(����)
    fild speed                   ; ���J�t�פj�p V
    fmul                         ; �p�� velocityX = cos(����) * V
    fistp DWORD PTR [velocityX]               ; �s�J velocityX

    fld st(0)                    ; ���׭�
    fsin                         ; �p�� sin(����)
    fild speed                   ; ���J�t�פj�p V
    fmul                         ; �p�� velocityY = sin(����) * V
    fistp DWORD PTR [velocityY]               ; �s�J velocityY
    
    ; ���� Y �t�ס]�ϼu�^
    neg velocityY

no_collision:
    ret
check_platform_collision ENDP

brick_collision PROC
    mov esi, OFFSET brick

    ; �p��C���ޡ]col = ballX / brickWidth�^
    mov eax, ballX
    xor edx, edx
    mov ecx, brickWidth
repeat_col:
    sub eax, ecx
    jl done_col
    inc edx
    jmp repeat_col
done_col:
    mov eax, edx  ; �C���ަs�J EAX

    ; �p�����ޡ]row = ballY / brickHeight�^
    mov edx, 0
    mov ecx, ballY
    xor ebx, ebx
    mov ebx, brickHeight
repeat_row:
    sub ecx, ebx
    jl done_row
    inc edx
    jmp repeat_row
done_row:
    mov ecx, edx  ; ����ަs�J ECX

    ; �p�ⰾ���q���ˬd���Ŀj��
    mov ebx, brickNumX
    imul ecx, ebx
    add ecx, eax
    cmp DWORD PTR [esi + ecx * 4], 1
    jne no_collision

    ; �I���B�z
    mov DWORD PTR [esi + ecx * 4], 0
    mov eax, velocityY
    neg eax
    mov velocityY, eax

no_collision:
    ret
brick_collision ENDP
end
