.386 
.model flat,stdcall 
option casemap:none 

EXTERN Home@0: PROC
EXTERN WinMain1@0: PROC
EXTERN WinMain2@0: PROC
EXTERN WinMain3@0: PROC
EXTERN WinMain4@0: PROC
EXTERN WinMain5@0: PROC
EXTERN WinMain6@0: PROC

Home EQU Home@0
Advanced1A2B EQU WinMain1@0
GameBrick EQU WinMain2@0
Cake1 EQU WinMain3@0
Cake2 EQU WinMain4@0
Minesweeper EQU WinMain5@0
Tofu EQU WinMain6@0

include masm32rt.inc

.data
Option1 db "1. Home", 0
Option2 db "2. BreakOut", 0
Option3 db "3. Cake1", 0
Option4 db "4. 1A2B", 0
Option5 db "5. Cake2", 0
Option6 db "6. Minesweeper", 0
Option7 db "7. Tofu", 0
message7 db "Please enter the game you choose:", 0
message8 db "Invalid Input!", 0
choice dd ?

szClr db "cls", 0
szNewLine db 10, 0
szInputFormat db "%d", 0

.code
main PROC
    call Home

Start:
    ; 清屏
    invoke crt_system, addr szClr

    ; 列印選項
    invoke crt_printf, addr Option1
    invoke crt_printf, addr szNewLine

    invoke crt_printf, addr Option2
    invoke crt_printf, addr szNewLine

    invoke crt_printf, addr Option3
    invoke crt_printf, addr szNewLine

    invoke crt_printf, addr Option4
    invoke crt_printf, addr szNewLine

    invoke crt_printf, addr Option5
    invoke crt_printf, addr szNewLine

    invoke crt_printf, addr Option6
    invoke crt_printf, addr szNewLine

    invoke crt_printf, addr Option7
    invoke crt_printf, addr szNewLine

    invoke crt_printf, addr message7
    invoke crt_printf, addr szNewLine


    ; 讀取用戶輸入
    invoke crt_scanf, addr szInputFormat, addr choice

    ; 比較用戶輸入
First:
    mov eax, choice
    cmp eax, 1
    jne Second
    call Home
    jmp Next

Second:
    cmp eax, 2
    jne Third
    call GameBrick
    jmp Next

Third:
    cmp eax, 3
    jne Forth
    call Cake1
    jmp Next

Forth:
    cmp eax, 4
    jne Fifth
    call Advanced1A2B
    jmp Next

Fifth:
    cmp eax, 5
    jne Sixth
    call Cake2
    jmp Next

Sixth:
    cmp eax, 6
    jne Seventh
    call Minesweeper
    jmp Next

Seventh:
    cmp eax, 7
    jne InvalidInput
    call Tofu
    jmp Next

InvalidInput:
    invoke crt_printf, addr message8
    invoke crt_printf, addr szNewLine

Next:
    jmp Start

    ; 程序結束
    invoke ExitProcess, 0

main ENDP
END main
