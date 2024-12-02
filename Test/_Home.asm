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
stepSize DWORD 5              ; �C�����ʪ������ƶq
winWidth DWORD 800              ; �����e��
winHeight DWORD 600             ; ��������
ballX DWORD 200                 ; �p�y X �y��
ballY DWORD 100                 ; �p�y Y �y��
velocityX DWORD 0               ; �p�y X ��V�t��
velocityY DWORD 10               ; �p�y Y ��V�t��
ballRadius DWORD 10             ; �p�y�b�|
divisor DWORD 180
offset_center DWORD 0
speed DWORD 10

.DATA? 
hInstance HINSTANCE ? 
CommandLine LPSTR ? 
tempWidth DWORD ?
tempHeight DWORD ?
hBrush DWORD ?

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

    .IF uMsg==WM_DESTROY 
        invoke PostQuitMessage,NULL 
        invoke KillTimer, hWnd, 1
    .ELSEIF uMsg == WM_TIMER
        ; ��s�p�y��m
        call update_ball

        ; �˴����x�I��
        call check_platform_collision

        ; ��ø����
        invoke InvalidateRect, hWnd, NULL, TRUE
        
    .ELSEIF uMsg == WM_KEYDOWN
        .IF wParam == VK_LEFT
            mov eax, platform_X
            cmp eax, stepSize
            jl skip_left          ; �קK���x���X�����
            mov eax, platform_X
            sub eax, stepSize
            mov platform_X, eax
        .ENDIF

        .IF wParam == VK_RIGHT
            mov eax, platform_X
            add eax, stepSize
            add eax, platform_Width
            mov ecx, 800           ; �����e��
            cmp eax, ecx
            jg skip_right         ; �קK���x���X�k���
            mov eax, platform_X
            add eax, stepSize
            mov platform_X, eax
        .ENDIF

        skip_left:
        skip_right:
        ; ���sø�s����
        invoke InvalidateRect, hWnd, NULL, TRUE

    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke GetClientRect, hWnd, addr rect
        RGB    200,200,50
        invoke SelectObject, hdc, eax
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

    ; �I���B�z
    ; �p�ⱵĲ�I�����������]�۹�󥭥x���ߡ^
    mov eax, ballX
    mov ebx, platform_X
    add ebx, platform_Width
    shr ebx, 1                   ; ���x�����I
    sub eax, ebx                 ; �����q = ballX - ���x����

    ; �ھڰ����q�p��ϼu���סA���x�e�׬� 120�A���׽d��q 30 �ר� 150 ��
    ; �����q�d��O [-60, 60]�A�������׽d�� [30, 150]
    mov ebx, platform_Width
    shr ebx, 1                   ; �b���x�e��
    imul eax, 60                 ; �p�ⰾ���A��j�]�l
    idiv ebx                     ; �p�ⰾ����� (-60 �� +60)

    ; �ھڰ����q�p��ϼu����
    add eax, 90                  ; �ϼu���׽d��վ�� 30 �� 150 ��
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
end
