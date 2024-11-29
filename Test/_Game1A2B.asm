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
    ; 隨機生成 4 位不重複數字
    call Randomize
    call RandomNumber
    ;mov edx, OFFSET randomNum
    ;call WriteString
    ;call Crlf

    ; 歡迎信息
    mov edx, OFFSET message1
    call WriteString
    call Crlf

    ; 遊戲主循環
    mov ecx, 10          ; 最多嘗試 10 次
GameLoop:
    ; 提示玩家輸入
    mov edx, OFFSET message2
    call WriteString
    call Crlf
    mov edx, OFFSET userGuess
    push ecx
    mov ecx, 100           ; 限制輸入 4 位
    call ReadString
    pop ecx
    call CheckUserInput
    cmp eax, 0
    je GameLoop

    ; 比較輸入與隨機數字
    call Compare

    ; 顯示結果
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

    ; 判斷是否猜中
    cmp Acount, 4
    je WinGame

    ; 減少嘗試次數
    
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

; 隨機生成不重複的 4 位數字
RandomNumber PROC USES eax ecx esi edi edx
    mov ecx, 4
    mov esi, OFFSET randomNum ; 載入陣列地址
    mov edx, 0
Pushing:
    push ecx
GenerateLoop:
    mov eax, 10
    call RandomRange
    add al, '0'        ; 轉換為 ASCII 字元

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
    mov [esi], al      ; 存入字元
    inc esi
    inc edx
    pop ecx
    loop Pushing
    ret
RandomNumber ENDP

CheckUserInput PROC USES ebx ecx edi esi
    ; 檢查玩家輸入的長度
    mov ecx, 4               ; 期望輸入的字符數量
    mov edi, OFFSET userGuess ; 玩家猜測的指針
    xor eax, eax             ; 清除 EAX，用來計數字符數量
CheckLength:
    cmp byte ptr [edi], 0    ; 檢查字符是否為結束符 (0)
    je CheckLengthDone       ; 如果是結束符，長度檢查結束
    inc edi                  ; 移動到下一個字符
    inc eax                  ; 計數
    loop CheckLength         ; 重複檢查直到長度滿 4
    cmp byte ptr [edi], 0    ; 檢查字符是否為結束符 (0)
    jne InvalidInput         ; 如果不是，跳轉到錯誤處理

CheckLengthDone:
    cmp eax, 4               ; 檢查長度是否為 4
    jne InvalidInput         ; 如果不是，跳轉到錯誤處理

    ; 檢查每個字符是否為有效數字 ('0' 到 '9')
    mov edi, OFFSET userGuess ; 玩家猜測的指針
    mov ecx, 4               ; 檢查 4 個字符
CheckDigits:
    mov al, [edi]            ; 讀取當前字符
    cmp al, '0'              ; 檢查是否是有效數字
    jl InvalidInput          ; 如果小於 '0'，跳轉到錯誤處理
    cmp al, '9'              ; 檢查是否是有效數字
    jg InvalidInput          ; 如果大於 '9'，跳轉到錯誤處理
    inc edi                  ; 移動到下一個字符
    loop CheckDigits         ; 檢查所有字符

    ; 檢查是否有重複的數字
    mov edi, OFFSET userGuess ; 玩家猜測的指針
    mov ecx, 4               ; 檢查 4 個字符
CheckDuplicates:
    mov al, [edi]            ; 讀取當前字符
    mov esi, edi             ; 移動到下一個字符
    inc esi
    mov ebx, ecx             ; 儲存剩餘循環次數
CheckDupInner:
    cmp al, [esi]            ; 檢查是否重複
    je InvalidInput          ; 如果重複，跳轉到錯誤處理
    inc esi                  ; 移動到下一個字符
    dec ebx
    jnz CheckDupInner        ; 如果還有字符，繼續檢查
    inc edi                  ; 移動到下一個字符
    loop CheckDuplicates     ; 檢查所有字符

    mov eax, 1
    ret                      ; 如果一切正確，返回
    
InvalidInput:
    mov eax, 0
    mov edx, OFFSET message6  ; 顯示錯誤信息
    call WriteString
    call Crlf
    ret
CheckUserInput ENDP


; 比較隨機數與玩家輸入
Compare PROC USES ecx esi edi edx
    ; 初始化變數
    mov esi, OFFSET randomNum  ; 指向隨機數字
    mov edi, OFFSET userGuess  ; 指向使用者猜測
    mov eax, 0               ; Acount = 0
    mov ebx, 0               ; Bcount = 0

    ; 計算 A (數字與位置都正確)
    mov ecx, 4
CountA:
    mov dl, [esi]              ; 讀取 randomNum 的一個字元
    cmp dl, [edi]              ; 與 userGuess 的對應字元比較
    jne SkipA
    inc eax                    ; 若相同，增加 Acount
SkipA:
    inc esi                    ; 移動到下一個 randomNum 字元
    inc edi                    ; 移動到下一個 userGuess 字元
    loop CountA                ; 重複 4 次

    ; 計算 B (數字正確但位置錯誤)
    mov edi, OFFSET userGuess  ; 重設 userGuess 的指標
    mov ecx, 4                 ; Bcount 迴圈次數
CountB:
    push ecx                   ; 儲存外層迴圈次數
    mov dl, [edi]              ; 取 userGuess 的當前字元
    mov esi, OFFSET randomNum  ; 從 randomNum 開始檢查
    mov ecx, 4                 ; 重設內層迴圈次數
CheckB:
    cmp dl, [esi]              ; 檢查數字是否正確
    jne NotB
    inc ebx                    ; 增加 Bcount
NotB:
    inc esi                    ; 移動到 randomNum 的下一字元
    loop CheckB                ; 檢查所有 randomNum 的字元
Next:
    pop ecx                    ; 恢復外層迴圈次數
    inc edi                    ; 移動到 userGuess 的下一字元
    loop CountB

    sub ebx, eax
    mov esi, OFFSET Acount
    mov [esi], al
    mov edi, OFFSET Bcount
    mov [edi], bl
    ret                        ; 返回，Acount 在 EAX，Bcount 在 EBX
Compare ENDP
END