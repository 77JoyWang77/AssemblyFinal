INCLUDE Irvine32.inc
INCLUDELIB	user32.lib

EXTERN Game1A2B@0: PROC
EXTERN BreakOut@0: PROC
;EXTERN Advanced1A2B@0: PROC
EXTERN WinMain@0: PROC
EXTERN GameBrick@0: PROC
Game1A2B EQU Game1A2B@0
BreakOut EQU BreakOut@0
;Advanced1A2B EQU Advanced1A2B@0
WinMain EQU WinMain@0
GameBrick EQU GameBrick@0

.data
Option1 byte "1. 1A2B", 0
Option2 byte "2. BreakOut", 0
Option3 byte "3. Brick", 0
message7 byte "Please enter the game you choose:", 0
message8 byte "Invalid Input!", 0

.code
main PROC
    ;call Advanced1A2B
    ;call WinMain

Start:
    CALL ClrScr
    mov edx, OFFSET Option1
    call WriteString
    call Crlf
    mov edx, OFFSET Option2
    call WriteString
    call Crlf
    mov edx, OFFSET Option3
    call WriteString
    call Crlf
    mov edx, OFFSET message7
    call WriteString
    call Crlf
    call ReadDec
First:
    cmp eax, 1
    jne Second
    call Game1A2B  ; 呼叫 Game1A2B 程式
    jmp Next

Second:
    cmp eax, 2
    jne Third
    call BreakOut  ; 呼叫 Game1A2B 程式
    jmp Next

Third:
    cmp eax, 3
    jne Next
    call GameBrick  ; 呼叫 Game1A2B 程式
    jmp Next

InvalidInput:
    mov edx, OFFSET message8
    call WriteString
    call Crlf

Next:
    jmp Start
    exit
main ENDP
END main