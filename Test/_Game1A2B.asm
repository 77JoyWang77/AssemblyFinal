INCLUDE Irvine32.inc
INCLUDELIB	user32.lib

.data
randomNum byte 4 DUP(?), 0
userGuess byte 100 DUP(?), 0
Acount byte ? 
Bcount byte ?
message1 byte "Welcome to 1A2B game!", 0
message2 byte "Please enter your 4-digit guess:", 0
message3 byte "You got ", 0
message4 byte "A", 0
message5 byte "B", 0
message6 byte "Your input is wrong.", 0
messageWin byte "Congratulations! You guessed correctly.", 0
messageLose byte "Sorry, you couldn't guess it. The number was: ", 0

.code
Game1A2B PROC
    CALL ClrScr
    ; �H���ͦ� 4 �줣���ƼƦr
    call Randomize
    call RandomNumber
    ;mov edx, OFFSET randomNum
    ;call WriteString
    ;call Crlf

    ; �w��H��
    mov edx, OFFSET message1
    call WriteString
    call Crlf

    ; �C���D�`��
    mov ecx, 10          ; �̦h���� 10 ��
GameLoop:
    ; ���ܪ��a��J
    mov edx, OFFSET message2
    call WriteString
    call Crlf
    mov edx, OFFSET userGuess
    push ecx
    mov ecx, 100           ; �����J 4 ��
    call ReadString
    pop ecx
    call CheckUserInput
    cmp eax, 0
    je GameLoop

    ; �����J�P�H���Ʀr
    call Compare

    ; ��ܵ��G
    mov edx, OFFSET message3
    call WriteString
    movzx eax, Acount
    call WriteDec
    mov edx, OFFSET message4
    call WriteString
    movzx eax, Bcount
    call WriteDec
    mov edx, OFFSET message5
    call WriteString
    call Crlf

    ; �P�_�O�_�q��
    cmp Acount, 4
    je WinGame

    ; ��ֹ��զ���
    
    loop GameLoop
    jmp LoseGame

WinGame:
    mov edx, OFFSET messageWin
    call WriteString
    call Crlf
    jmp EndGame

LoseGame:
    mov edx, OFFSET messageLose
    call WriteString
    mov edx, OFFSET randomNum
    call WriteString
    call Crlf

EndGame:
    ret
Game1A2B ENDP

; �H���ͦ������ƪ� 4 ��Ʀr
RandomNumber PROC USES eax ecx esi edi edx
    mov ecx, 4
    mov esi, OFFSET randomNum ; ���J�}�C�a�}
    mov edx, 0
Pushing:
    push ecx
GenerateLoop:
    mov eax, 10
    call RandomRange
    add al, '0'        ; �ഫ�� ASCII �r��

    mov edi, OFFSET randomNum
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
RandomNumber ENDP

CheckUserInput PROC USES ebx ecx edi esi
    ; �ˬd���a��J������
    mov ecx, 4               ; �����J���r�żƶq
    mov edi, OFFSET userGuess ; ���a�q�������w
    xor eax, eax             ; �M�� EAX�A�Ψӭp�Ʀr�żƶq
CheckLength:
    cmp byte ptr [edi], 0    ; �ˬd�r�ŬO�_�������� (0)
    je CheckLengthDone       ; �p�G�O�����šA�����ˬd����
    inc edi                  ; ���ʨ�U�@�Ӧr��
    inc eax                  ; �p��
    loop CheckLength         ; �����ˬd������׺� 4
    cmp byte ptr [edi], 0    ; �ˬd�r�ŬO�_�������� (0)
    jne InvalidInput         ; �p�G���O�A�������~�B�z

CheckLengthDone:
    cmp eax, 4               ; �ˬd���׬O�_�� 4
    jne InvalidInput         ; �p�G���O�A�������~�B�z

    ; �ˬd�C�Ӧr�ŬO�_�����ļƦr ('0' �� '9')
    mov edi, OFFSET userGuess ; ���a�q�������w
    mov ecx, 4               ; �ˬd 4 �Ӧr��
CheckDigits:
    mov al, [edi]            ; Ū����e�r��
    cmp al, '0'              ; �ˬd�O�_�O���ļƦr
    jl InvalidInput          ; �p�G�p�� '0'�A�������~�B�z
    cmp al, '9'              ; �ˬd�O�_�O���ļƦr
    jg InvalidInput          ; �p�G�j�� '9'�A�������~�B�z
    inc edi                  ; ���ʨ�U�@�Ӧr��
    loop CheckDigits         ; �ˬd�Ҧ��r��

    ; �ˬd�O�_�����ƪ��Ʀr
    mov edi, OFFSET userGuess ; ���a�q�������w
    mov ecx, 4               ; �ˬd 4 �Ӧr��
CheckDuplicates:
    mov al, [edi]            ; Ū����e�r��
    mov esi, edi             ; ���ʨ�U�@�Ӧr��
    inc esi
    mov ebx, ecx             ; �x�s�Ѿl�`������
CheckDupInner:
    cmp al, [esi]            ; �ˬd�O�_����
    je InvalidInput          ; �p�G���ơA�������~�B�z
    inc esi                  ; ���ʨ�U�@�Ӧr��
    dec ebx
    jnz CheckDupInner        ; �p�G�٦��r�šA�~���ˬd
    inc edi                  ; ���ʨ�U�@�Ӧr��
    loop CheckDuplicates     ; �ˬd�Ҧ��r��

    mov eax, 1
    ret                      ; �p�G�@�����T�A��^
    
InvalidInput:
    mov eax, 0
    mov edx, OFFSET message6  ; ��ܿ��~�H��
    call WriteString
    call Crlf
    ret
CheckUserInput ENDP


; ����H���ƻP���a��J
Compare PROC USES ecx esi edi edx
    ; ��l���ܼ�
    mov esi, OFFSET randomNum  ; ���V�H���Ʀr
    mov edi, OFFSET userGuess  ; ���V�ϥΪ̲q��
    mov eax, 0               ; Acount = 0
    mov ebx, 0               ; Bcount = 0

    ; �p�� A (�Ʀr�P��m�����T)
    mov ecx, 4
CountA:
    mov dl, [esi]              ; Ū�� randomNum ���@�Ӧr��
    cmp dl, [edi]              ; �P userGuess �������r�����
    jne SkipA
    inc eax                    ; �Y�ۦP�A�W�[ Acount
SkipA:
    inc esi                    ; ���ʨ�U�@�� randomNum �r��
    inc edi                    ; ���ʨ�U�@�� userGuess �r��
    loop CountA                ; ���� 4 ��

    ; �p�� B (�Ʀr���T����m���~)
    mov edi, OFFSET userGuess  ; ���] userGuess ������
    mov ecx, 4                 ; Bcount �j�馸��
CountB:
    push ecx                   ; �x�s�~�h�j�馸��
    mov dl, [edi]              ; �� userGuess ����e�r��
    mov esi, OFFSET randomNum  ; �q randomNum �}�l�ˬd
    mov ecx, 4                 ; ���]���h�j�馸��
CheckB:
    cmp dl, [esi]              ; �ˬd�Ʀr�O�_���T
    jne NotB
    inc ebx                    ; �W�[ Bcount
NotB:
    inc esi                    ; ���ʨ� randomNum ���U�@�r��
    loop CheckB                ; �ˬd�Ҧ� randomNum ���r��
Next:
    pop ecx                    ; ��_�~�h�j�馸��
    inc edi                    ; ���ʨ� userGuess ���U�@�r��
    loop CountB

    sub ebx, eax
    mov esi, OFFSET Acount
    mov [esi], al
    mov edi, OFFSET Bcount
    mov [edi], bl
    ret                        ; ��^�AAcount �b EAX�ABcount �b EBX
Compare ENDP
END