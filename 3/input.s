bits 64

section .data

size equ 1024   

prompt:     db "Enter filename: ", 0
promptlen: equ $ - prompt

newline:    db 10

nofile:     db "No such file or directory", 10
nofilelen:  equ $ - nofile

permission: db "Permission denied", 10
permissionlen: equ $ - permission

unknown:    db "Unknown error", 10
unknownlen: equ $ - unknown

filename:
    times 256 db 0

delim:                     ; Массив разделителей: пробел и табуляция
    db ' ', 9, 0           ; Пробел и табуляция (9)

str:                       ; Буфер для ввода строки
    times size db 0        ; Выделяем буфер размером size

newstr:                    ; Буфер для нового отсортированного результата
    times size db 0        ; Выделяем буфер размером size


section .text
global _start

_start:
    ; write(prompt)
    mov eax, 1          ; syscall: write
    mov edi, 1          ; stdout
    mov rsi, prompt
    mov edx, promptlen
    syscall

    ; read(filename)
    mov eax, 0          ; syscall: read
    mov edi, 0          ; stdin
    mov rsi, filename
    mov edx, 256
    syscall
    test rax, rax
    jle .exit           ; если ничего не введено — выход

    ; удалить символ новой строки
    mov rcx, rax
    dec rcx
    cmp byte [filename + rcx], 10
    jne .open_file
    mov byte [filename + rcx], 0

.open_file:
    mov eax, 2          ; syscall: open
    mov rdi, filename
    xor esi, esi        ; O_RDONLY
    syscall
    cmp eax, 0
    jl .error_open
    mov ebx, eax        ; сохраняем fd

.read_loop:
    mov eax, 0          ; syscall: read
    mov edi, ebx        ; fd
    mov rsi, str
    mov edx, size
    syscall
    test eax, eax
    jle .close_file     ; если чтение вернуло 0 или меньше, значит, EOF или ошибка

    mov rdi, newstr     ; Адрес нового буфера для строки
    mov rsi, str        ; Адрес исходной строки
    mov rdx, delim      ; Адрес разделителей (пробел, табуляция)
    call work           ; Вызов функции для обработки строки

    ; write to stdout
    mov edx, eax
    mov eax, 1
    mov edi, 1
    mov rsi, newstr
    syscall
    jmp .read_loop      ; продолжение чтения строк

.close_file:
    ; write("\n")
    mov eax, 1
    mov edi, 1
    mov rsi, newline
    mov edx, 1
    syscall

    ; close(fd)
    mov eax, 3
    mov edi, ebx
    syscall
    jmp .exit


.error_open:
    mov eax, eax
    call writeerr

.exit:
    mov eax, 60         ; syscall: exit
    xor edi, edi
    syscall

; ------------------------------------------------------
; writeerr — вывод сообщения об ошибке по коду errno в eax
; ------------------------------------------------------
writeerr:
    cmp eax, -2
    jne .w1
    mov rsi, nofile
    mov edx, nofilelen
    jmp .wout

.w1:
    cmp eax, -13
    jne .w2
    mov rsi, permission
    mov edx, permissionlen
    jmp .wout

.w2:
    mov rsi, unknown
    mov edx, unknownlen

.wout:
    mov eax, 1
    mov edi, 2
    syscall
    ret



sou equ 8               ; Размер выделенной памяти для хранения указателя на начало строки
res equ sou + 8          ; Указатель на новый буфер для результата, который идет после "sou"
del equ res + 8          ; Указатель на массив разделителей (например, пробел и табуляция), после "res"
w equ del + 8 * size / 2 ; Указатель на память для хранения слов в строке (включая размер)
wl equ w + 4 * size / 2 ; Память для хранения длины слов
n equ wl + 4            ; Память для хранения количества слов в строке

work:
    push rbp               ; Сохраняем базовый указатель
    mov rbp, rsp           ; Настроим стек
    sub rsp, n             ; Выделим место на стеке
    and rsp, -8            ; Выравнивание по 8 байтов

    push rbx               ; Сохраняем регистр rbx

    mov [rbp - sou], rsi    ; Указатель на исходную строку
    mov [rbp - res], rdi    ; Указатель на новый буфер для результата
    mov [rbp - del], rdx    ; Указатель на разделители
    xor ebx, ebx           ; Счётчик для символов в словах
    xor ecx, ecx           ; Счётчик для слов

.another_symb:
    mov al, [rsi]          ; Берем символ из строки
    inc rsi                ; Инкрементируем указатель на символ
    cmp al, 10             ; Проверка на символ новой строки
    je .word_process                 ; Если символ новой строки, переходим к обработке слова

    mov rdi, [rbp - del]   ; Указатель на разделители
.delim_cycle:
    cmp byte [rdi], 0      ; Проверка на конец разделителей
    je .symb_is_not_del                 ; Если символ это не разделитель
    cmp byte [rdi], al     ; Сравниваем символ с разделителями
    je .word_process                 ; Если символ разделитель, переходим к обработке

    inc rdi                ; Переход к следующему разделителю
    jmp .delim_cycle

.symb_is_not_del:
    or ebx, ebx            ; Проверка на первый символ в слове
    jne .not_first_let_in_word                ; Если символ в слове не первый
    mov [rbp - w + rcx * 8], rsi ; Записываем начало слова
    dec qword [rbp - w + rcx * 8] ; Уменьшаем счетчик
.not_first_let_in_word:
    inc ebx                ; Увеличиваем количество букв в слове
    jmp .another_symb

.word_process:
    or ebx, ebx            ; Проверка на пустое слово
    je .empty_word                 ; Если слово пустое, пропускаем
    
    push rax               ; Сохраняем значение на стеке
    push rcx               ; Сохраняем счётчик
    push rdi               ; Сохраняем индекс
    push rsi               ; Сохраняем указатель на слово
    mov esi, ecx         ; Сохраняем индекс слова
    mov rdi, [rbp - w + rcx * 8]           ; Устанавливаем rdi для вызова compare
    mov esi, ebx           ; Устанавливаем esi для сравнения
    call is_digit_word           ; Сравниваем слова
    or eax, eax            ; Проверка на результат
    pop rsi                ; Восстанавливаем значения
    pop rdi
    pop rcx
    pop rax
    jnz .remove_word                ; Если результат не 0, то очищаем слово

    mov [rbp - wl + rcx * 4], ebx ; Записываем длину слова
    xor ebx, ebx           ; Обнуляем счётчик
    inc ecx                ; Увеличиваем количество слов
    jmp .empty_word

.remove_word:
    xor ebx, ebx ; не записываем длину, не увеличиваем количесвто слов

.empty_word:
    cmp al, 10             ; Проверка на конец строки
    jne .another_symb                ; Если не конец, продолжаем

;строка закончилась
    mov [rbp - n], ecx     ; Сохраняем количество слов
    dec ecx                ; Уменьшаем для последующей работы
    or ecx, ecx            ; Проверка на 0 слов
    je .one_word           ; Если слово одно, переходим к завершению
    jl .empty_row          ; Если слов нет, переходим к завершению

.one_word:
    mov rdi, [rbp - res]
    mov ecx, [rbp - n]      ; Количество слов
    xor ebx, ebx            ; Сброс счётчика

.insert_word:
    push rcx                ; Сохраняем счётчик оставшихся слов (ecx — сколько слов ещё нужно скопировать)
    or ebx, ebx             ; Если это не первое слово (ebx > 0)
    je .prepare_word            ; Если это первое слово — не добавляем пробел
    mov byte [rdi], ' '     ; Иначе — добавляем пробел в выходную строку
    inc rdi

.prepare_word:
    mov rsi, [rbp - w + rbx * 8]       ; Адрес слова
    mov ecx, [rbp - wl + rbx * 4]      ; Длина слова
    inc rbx                            ; Переход к следующему слову

.insert_words_letter:
    mov al, [rsi]          ; Копируем символ из исходного слова
    mov [rdi], al          ; Помещаем его в выходную строку
    inc rsi                ; Следующий символ в слове
    inc rdi                ; Следующая позиция в выходной строке
    loop .insert_words_letter              ; Повторяем для всех символов слова
    pop rcx                ; Восстанавливаем общее количество оставшихся слов
    loop .insert_word              ; Если ещё есть слова — повторяем

.empty_row:
    ;mov byte [rdi], 10     ; Завершаем строку символом новой строки
    pop rbx                ; Восстанавливаем rbx
    leave                  ; Восстанавливаем стек
    ret

is_digit_word:
    or esi, esi
    je .not_digit         ; Если длина 0 — не считаем словом из цифр
    xor eax, eax          ; По умолчанию — не цифры
.check_loop:
    mov al, [rdi]         ; Берём символ
    inc rdi
    sub al, '0'
    cmp al, 9
    ja .not_digit         ; Если не цифра — выходим
    dec esi
    jnz .check_loop       ; Если не конец слова — повторить
    mov eax, 1            ; Все символы — цифры
    ret
.not_digit:
    xor eax, eax
    ret
