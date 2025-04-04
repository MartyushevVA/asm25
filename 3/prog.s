bits 64
; Лексикографическая сортировка слов в строке
section .data
size equ 1024              ; Размер буфера для ввода/вывода строк

msg1:                      ; Сообщение для запроса ввода строки
    db "Enter string: "
msg1len equ $ - msg1       ; Длина сообщения

msg2:                      ; Сообщение перед результатом
    db "Result: "
msg2len equ $ - msg2       ; Длина сообщения

delim:                     ; Массив разделителей: пробел и табуляция
    db ' ', 9, 0           ; Пробел и табуляция (9)

str:                       ; Буфер для ввода строки
    times size db 0        ; Выделяем буфер размером size

newstr:                    ; Буфер для нового отсортированного результата
    times size db 0        ; Выделяем буфер размером size

section .text
global _start              ; Точка входа программы

_start:
    ; Печать приглашения к вводу строки
    mov eax, 1             ; sys_write
    mov edi, 1             ; stdout
    mov rsi, msg1          ; Адрес сообщения
    mov edx, msg1len       ; Длина сообщения
    syscall

    ; Ввод строки с клавиатуры
    xor eax, eax           ; Очищаем eax (счётчик)
    xor edi, edi           ; Очищаем edi (для использования в sys_read)
    mov rsi, str           ; Адрес буфера для строки
    mov edx, size          ; Размер буфера
    syscall

    or eax, eax            ; Проверяем результат ввода
    jl .m2                 ; Если ввод был ошибочен, переходим к завершению
    je .m1                 ; Если строка пустая, переходим к завершению

    cmp eax, size          ; Если длина строки превышает размер буфера
    je .m2                 ; Переходим к завершению

    ; Обработка строки (разбиение на слова)
    mov rdi, newstr        ; Адрес нового буфера для строки
    mov rsi, str           ; Адрес исходной строки
    mov rdx, delim         ; Адрес разделителей (пробел, табуляция)
    call work              ; Вызов функции для обработки строки

    ; Печать результата
    mov eax, 1             ; sys_write
    mov edi, 1             ; stdout
    mov rsi, msg2          ; Сообщение "Result:"
    mov edx, msg2len       ; Длина сообщения
    syscall

    ; Печать отсортированной строки
    mov eax, 1             ; sys_write
    mov rsi, newstr        ; Адрес отсортированной строки
    xor edx, edx           ; Инициализация счётчика
.m0:
    inc rdx                ; Инкремент счётчика
    cmp byte [rsi + rdx - 1], 10 ; Проверка на конец строки
    jne .m0                ; Если не конец строки, продолжаем

    syscall                ; Вывод строки
    jmp _start             ; Возврат к началу программы

.m1:
    xor edi, edi           ; Если строка пуста, выводим пустой результат
    jmp .m3

.m2:
    mov edi, 1             ; Завершаем программу
.m3:
    mov eax, 60            ; sys_exit
    syscall                ; Завершаем выполнение программы


sou equ 8               ; Размер выделенной памяти для хранения указателя на начало строки
res equ sou + 8          ; Указатель на новый буфер для результата, который идет после "sou"
del equ res + 8          ; Указатель на массив разделителей (например, пробел и табуляция), после "res"
w equ del + 8 * size / 2 ; Указатель на память для хранения слов в строке (включая размер)
wl equ w + 4 * size / 2 ; Память для хранения длины слов
n equ wl + 4            ; Память для хранения количества слов в строке

; Основная работа по обработке строки (разбиение на слова и их сортировка)


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
    mov [rbp - wl + rcx * 4], ebx ; Записываем длину слова
    xor ebx, ebx           ; Обнуляем счётчик
    inc ecx                ; Увеличиваем количество слов

.empty_word:
    cmp al, 10             ; Проверка на конец строки
    jne .another_symb                ; Если не конец, продолжаем

;строка закончилась
    mov [rbp - n], ecx     ; Сохраняем количество слов
    dec ecx                ; Уменьшаем для последующей работы
    or ecx, ecx            ; Проверка на 0 слов
    je .empty_row                 ; Если слов нет, переходим к завершению
    jl .end_row                ; Если одно слово, переходим к завершению

    xor edi, edi           ; Сброс счётчика
.main_loop:
    inc edi                ; Инкрементируем индекс
    mov rax, [rbp - w + rdi * 8] ; Берем указатель на слово
    mov ebx, [rbp - wl + rdi * 4] ; Берем длину слова
    mov esi, edi
.check_prev_word:
    dec esi                ; Декрементируем индекс
    js .save_value                 ; Если индекс меньше нуля, переходим к обработке
    push rax               ; Сохраняем значение на стеке
    push rcx               ; Сохраняем счётчик
    push rdi               ; Сохраняем индекс
    push rsi               ; Сохраняем указатель на слово
    mov rdx, [rbp - w + rsi * 8] ; Загружаем указатель на слово
    mov ecx, [rbp - wl + rsi * 4] ; Загружаем длину слова
    mov rdi, rax           ; Устанавливаем rdi для вызова compare
    mov esi, ebx           ; Устанавливаем esi для сравнения
    call compare           ; Сравниваем слова
    or eax, eax            ; Проверка на результат
    pop rsi                ; Восстанавливаем значения
    pop rdi
    pop rcx
    pop rax
    jge .save_value                ; Если результат больше или равен, то выходим

    ; Перемещаем слова в правильный порядок
    mov r8, [rbp - w + rsi * 8]
    mov [rbp - w + rsi * 8 + 8], r8
    mov edx, [rbp - wl + rsi * 4]
    mov [rbp - wl + rsi * 4 + 4], edx
    jmp .check_prev_word

.save_value:
    inc esi                ; Увеличиваем индекс
    mov [rbp - w + rsi * 8], rax
    mov [rbp - wl + rsi * 4], ebx
    loop .main_loop

.empty_row:
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

.end_row:
    mov byte [rdi], 10     ; Завершаем строку символом новой строки
    pop rbx                ; Восстанавливаем rbx
    leave                  ; Восстанавливаем стек
    ret


    

compare:
    or esi, esi            ; Проверка: длина слов 0?
    jne .get_symb                ; Если не 0, идем дальше
    xor al, al             ; Если длина 0, то строки равны
    jmp .m1
.get_symb:
    mov al, [rdi]          ; Берем символ из первого слова
    inc rdi                ; Указатель на след. символ
.m1:
    jecxz .exit              ; Если ecx == 0 (длина второго слова == 0), выходим
    sub al, [rdx]          ; Вычитаем символ из второго слова
    inc rdx                ; Двигаем указатель второго слова
    or al, al              ; Равны ли символы?
    jne .exit                ; Если не равны, выходим — результат уже в al

    or esi, esi            ; Проверка длины снова
    je .exit                 ; Если длина закончилась — строки равны
    dec esi                ; Уменьшаем длину
    dec ecx                ; Странно — неясно зачем ecx уменьшается
    jmp compare            ; Повторно сравниваем следующий символ
.exit:
    cbw                    ; Расширение AL → AX (под знак)
    cwde                   ; AX → EAX
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
