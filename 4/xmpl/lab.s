bits 64

; Сравнение экспоненты из mathlib и моей реализации

section .data
msg1:  db "Input x", 10, 0       ; Сообщение: "Input x"
msg2:  db "%lf", 0               ; Формат для ввода: ожидаем число с плавающей запятой
msg3:  db "exp(%.10g)=%.10g", 10, 0  ; Сообщение для вывода экспоненты: "exp(%.10g)=%.10g"
msg4:  db "myexp(%.10g)=%.10g", 10, 0 ; Сообщение для вывода результата моей экспоненты: "myexp(%.10g)=%.10g"

section .text

one:   dq 1.0  ; Значение 1.0, которое будем использовать в расчетах

; Функция для вычисления экспоненты с помощью ряда
myexp:
    movsd xmm1, [one]    ; xmm1 = 1.0 (стартовое значение для суммы)
    movsd xmm2, [one]    ; xmm2 = 1.0 (для отслеживания изменений суммы)
    movsd xmm3, [one]    ; xmm3 = 1.0 (для отслеживания чисел в знаменателе)
    movsd xmm4, [one]    ; xmm4 = 1.0 (для отслеживания чисел в числителе)

.m0:  
    movsd xmm5, xmm2     ; xmm5 = xmm2 (предыдущая сумма для сравнения)
    mulsd xmm1, xmm0     ; xmm1 = xmm1 * xmm0 (умножаем на x)
    divsd xmm1, xmm3     ; xmm1 = xmm1 / xmm3 (делим на фактор)
    addsd xmm2, xmm1     ; xmm2 = xmm2 + xmm1 (добавляем в сумму)
    addsd xmm3, xmm4     ; xmm3 = xmm3 + 1 (увеличиваем степень для знаменателя)
    ucomisd xmm2, xmm5   ; Сравниваем xmm2 и xmm5 (проверяем, изменилась ли сумма)
    jne .m0              ; Если суммы не равны, продолжаем вычисления

    movsd xmm0, xmm2     ; Возвращаем результат в xmm0
    ret                  ; Выход из функции

x equ 8      ; Размер переменной x (8 байт)
y equ x + 8  ; Размер переменной y (8 байт)

extern printf   ; Экспонента из библиотеки
extern scanf    ; Ввод данных
extern exp      ; Экспонента из стандартной библиотеки

global main     ; Основная функция

main:
    push rbp              ; Сохраняем старое значение rbp
    mov rbp, rsp          ; Устанавливаем новый фрейм стека
    sub rsp, y            ; Выделяем место для переменных x и y

    mov rdi, msg1         ; Выводим сообщение "Input x"
    xor eax, eax          ; Обнуляем регистр eax (для вызова printf)
    call printf

    mov rdi, msg2         ; Ожидаем ввод числа с плавающей запятой
    lea rsi, [rbp-x]      ; Адрес x (куда будет записан результат)
    xor eax, eax          ; Обнуляем регистр eax (для вызова scanf)
    call scanf

    movsd xmm0, [rbp-x]   ; Загружаем значение x в xmm0
    call exp              ; Вызываем стандартную экспоненту (exp)
    movsd [rbp-y], xmm0   ; Сохраняем результат в y

    mov rdi, msg3         ; Выводим "exp(%.10g)=%.10g"
    movsd xmm0, [rbp-x]   ; Загружаем x в xmm0
    movsd xmm1, [rbp-y]   ; Загружаем y в xmm1
    mov eax, 2            ; Указываем количество аргументов для printf
    call printf

    movsd xmm0, [rbp-x]   ; Загружаем x в xmm0
    call myexp            ; Вызываем свою реализацию экспоненты
    movsd [rbp-y], xmm0   ; Сохраняем результат в y

    mov rdi, msg4         ; Выводим "myexp(%.10g)=%.10g"
    movsd xmm0, [rbp-x]   ; Загружаем x в xmm0
    movsd xmm1, [rbp-y]   ; Загружаем y в xmm1
    mov eax, 2            ; Указываем количество аргументов для printf
    call printf

    leave                 ; Восстанавливаем стек
    xor eax, eax          ; Возвращаем 0 (успешное завершение программы)
    ret                   ; Выход из программы
