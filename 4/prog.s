section .data
    prompt:     db "Input x and epsilon: ", 0
    fmt_scan:   db "%lf %lf", 0
    fmt_print:  db "f(x) (formula): %.9lf", 10, 0
    fmt_print2: db "f(x) (series):  %.9lf", 10, 0
    fmt_term:   db "%d %.10g", 10, 0
    sqrt_fmt:   db "sqrt: domain error", 10, 0
    fopen_err:  db "Failed to open output file.", 10, 0

section .bss
    file_ptr resq 1
    x resq 1
    eps resq 1
    sum resq 1
    term resq 1

section .text
    extern printf, scanf, fopen, fprintf, fclose, pow, sqrt, fabs
    global main

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32             ; выделяем место для локальных переменных

    ; открываем файл для записи (argv[1])
    mov rdi, [rsi+8]        ; argv[1]
    mov rsi, mode_write
    call fopen
    test rax, rax
    jz .fopen_fail
    mov [file_ptr], rax

    ; выводим запрос на ввод x и epsilon
    mov rdi, prompt
    xor eax, eax
    call printf

    ; считываем x и epsilon
    mov rdi, fmt_scan
    lea rsi, [x]
    lea rdx, [eps]
    xor eax, eax
    call scanf

    ; вычисление точного значения f(x) = 1 / ((1 - x^2) * sqrt(1 - x^2))
    movsd xmm0, [x]
    mulsd xmm0, xmm0            ; xmm0 = x^2
    movsd xmm1, qword [one]
    subsd xmm1, xmm0            ; xmm1 = 1 - x^2
    movsd xmm2, xmm1
    call sqrt                   ; xmm0 = sqrt(1 - x^2)
    test eax, eax
    jp .sqrt_fail
    mulsd xmm0, xmm2            ; (1 - x^2)*sqrt(...)
    movsd xmm1, qword [one]
    divsd xmm1, xmm0
    movsd [sum], xmm1           ; сохраняем точное значение

    ; выводим точное значение
    mov rdi, fmt_print
    movsd xmm0, [sum]
    mov eax, 1
    call printf

    ; инициализация суммы ряда
    pxor xmm0, xmm0
    movsd [sum], xmm0           ; sum = 0.0

    ; инициализация первого члена ряда (term = 1.0)
    movsd xmm0, qword [one]
    movsd [term], xmm0

    ; инициализация факториалов
    mov rbx, 0                  ; n = 0
    mov r12, 1                  ; odd_fact = 1
    mov r13, 1                  ; even_fact = 1

.loop_series:
    cmp rbx, 500                ; ограничиваем количество итераций
    jge .done_series

    ; term_n = (odd_fact / even_fact) * x^(2n)
    cvtsi2sd xmm1, r12
    cvtsi2sd xmm2, r13
    divsd xmm1, xmm2            ; xmm1 = (2n+1)!! / (2n)!!

    ; pow(x, 2n)
    movsd xmm0, [x]
    cvtsi2sd xmm2, rbx
    addsd xmm2, xmm2            ; 2n
    call pow
    mulsd xmm1, xmm0            ; term = (odd_fact / even_fact) * x^(2n)

    ; fabs(term)
    movsd xmm0, xmm1
    call fabs
    movsd xmm3, [eps]
    ucomisd xmm0, xmm3
    jb .done_series

    ; суммируем текущий член в итоговую сумму
    movsd xmm0, [sum]
    addsd xmm0, xmm1
    movsd [sum], xmm0

    ; записываем в файл
    mov rdi, [file_ptr]         ; rdi = FILE*
    mov rsi, fmt_term           ; rsi = формат строки
    mov rdx, rbx                ; rdx = номер (int)
    movsd xmm0, xmm1            ; xmm0 = значение члена ряда
    mov eax, 2                  ; кол-во аргументов с плавающей точкой
    call fprintf

    ; обновляем факториалы
    mov r14, rbx                ; Загружаем n (rbx) в r14
    shl r14, 1                  ; Умножаем на 2, получаем 2n
    inc r14                     ; Получаем 2n + 1
    mov r12, 1                  ; Инициализируем odd_fact = 1
    mov r13, 1                  ; Инициализируем even_fact = 1
    imul r12, r14          ; odd_fact *= (2n+1)
    dec r14                     ; Уменьшаем r14 на 1, чтобы получить 2n
    imul r13, r14          ; even_fact *= (2n)

    inc rbx
    jmp .loop_series

.done_series:
    ; выводим приближённое значение (сумма ряда)
    mov rdi, fmt_print2
    movsd xmm0, [sum]
    mov eax, 1
    call printf

    ; закрываем файл
    mov rdi, [file_ptr]
    call fclose
    jmp .exit

.sqrt_fail:
    mov rdi, sqrt_fmt
    xor eax, eax
    call printf
    jmp .exit

.fopen_fail:
    mov rdi, fopen_err
    xor eax, eax
    call printf

.exit:
    leave
    xor eax, eax
    ret

section .data
    one: dq 1.0                  ; 1.0
    mode_write: db "w", 0         ; режим записи
