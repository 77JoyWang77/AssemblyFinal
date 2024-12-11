INCLUDE Irvine32.inc
INCLUDELIB	user32.lib

EXTERN Game1A2B@0: PROC
EXTERN BreakOut@0: PROC
EXTERN Home@0: PROC
EXTERN WinMain1@0: PROC
EXTERN WinMain2@0: PROC
EXTERN WinMain3@0: PROC
EXTERN WinMain4@0: PROC
Game1A2B EQU Game1A2B@0
BreakOut EQU BreakOut@0
Home EQU Home@0
Advanced1A2B EQU WinMain1@0
GameBrick EQU WinMain2@0
Cake1 EQU WinMain3@0
Minesweeper EQU WinMain4@0

.data
Option1 byte "1. Home", 0
Option2 byte "2. BreakOut", 0
Option3 byte "3. Cake1", 0
Option4 byte "4. 1A2B", 0
Option5 byte "5. Minesweeper", 0
Option6 byte "6. Minesweeper", 0
message7 byte "Please enter the game you choose:", 0
message8 byte "Invalid Input!", 0

.code
main PROC
    ;call Home
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
    mov edx, OFFSET Option4
    call WriteString
    call Crlf
    mov edx, OFFSET Option5
    call WriteString
    call Crlf
    ;mov edx, OFFSET Option6
    ;call WriteString
    ;call Crlf
    mov edx, OFFSET message7
    call WriteString
    call Crlf
    call ReadDec
First:
    cmp eax, 1
    jne Second
    call Home
    jmp Next

Second:
    cmp eax, 2
    jne Third
    call GameBrick  ; ©I¥s Game1A2B µ{¦¡
    jmp Next

Third:
    cmp eax, 3
    jne Forth
    call Cake1  ; ©I¥s Game1A2B µ{¦¡
    jmp Next

Forth:
    cmp eax, 4
    jne Fifth
    call Advanced1A2B  ; ©I¥s Game1A2B µ{¦¡
    jmp Next

Fifth:
    cmp eax, 5
    jne Sixth
    call Minesweeper  ; ©I¥s Game1A2B µ{¦¡
    jmp Next

Sixth:
    ;cmp eax, 6
    ;jne Next
    ;call Minesweeper  ; ©I¥s Game1A2B µ{¦¡
    ;jmp Next

InvalidInput:
    mov edx, OFFSET message8
    call WriteString
    call Crlf

Next:
    jmp Start
    exit
main ENDP
END main