bits 64

; Пирамидальная сортировка строк матрицы по сумме элементов

section .data
    align 8
    n: db 5
    m: db 5
    sort_order db 1  ; 1 - по возрастанию, 0 - по убыванию

    matr: dq 12, 7,  3,  9,  15
          dq 5,  11, 8,  2,  14
          dq 1,  10, 6,  13, 4
          dq 18, 17, 16, 20, 19
          dq 21, 25, 22, 23, 24

    ; Массив указателей на строки матрицы
    row_ptrs: dq 0, 0, 0, 0, 0

section .text
    global _start

_start:
    ; Шаг 1: Инициализация массива указателей на строки
    mov rbx, matr  ; Указатель на начало матрицы
    lea rdi, [row_ptrs]  ; Указатель на массив указателей на строки
    movzx rcx, byte[n]  ; Количество строк
	dec rcx
	jle exit_program
	inc rcx
    xor r8, r8  ; Индекс строки

	movzx rax, byte [m]  ; Загружаем значение m в rax
    shl rax, 3           ; Умножаем rax на 8

init_ptrs:
    mov [rdi + r8 * 8], rbx  ; Сохраняем адрес строки
    add rbx, rax         ; Добавляем результат к rbx
    inc r8
    loop init_ptrs

    ; Шаг 2: Пирамидальная сортировка
    lea rsi, [row_ptrs]  ; Указатель на массив указателей на строки
    movzx rcx, byte[n]  ; Количество строк
    call heap_sort

    ; Шаг 3: Завершение программы
exit_program:
    mov rax, 60  ; syscall: exit
    xor rdi, rdi  ; код возврата 0
    syscall

; Процедура для построения кучи (Heapify)
heapify:
    ; Входные параметры:
    ; rsi - массив указателей на строки
    ; rcx - размер кучи
    ; rdx - индекс корня

    push rbp
    mov rbp, rsp

	push rbx       ; Сохраняем rbx, так как он используется
    push r12       ; Сохраняем r12

    mov rax, rdx   ; Индекс наибольшего элемента (корень)
    mov rbx, rax   ; Левый потомок
    shl rbx, 1
    inc rbx
    mov r12, rbx   ; Правый потомок
    inc r12

    ; Сравниваем корень с левым потомком
    cmp rbx, rcx   ; Проверяем, существует ли левый потомок
    jge .no_left_child
    mov r8, [rsi + rax * 8]  ; Загружаем указатель на строку корня
    mov r9, [rsi + rbx * 8]  ; Загружаем указатель на строку левого потомка
    call cmp_lines           ; Сравниваем строки
    test al, al              ; Проверяем результат сравнения
    jz .no_left_child        ; Если корень больше, переходим к правому потомку
    mov rax, rbx             ; Иначе обновляем индекс наибольшего элемента

.no_left_child:
    ; Сравниваем корень с правым потомком
    cmp r12, rcx             ; Проверяем, существует ли правый потомок
    jge .no_right_child
    mov r8, [rsi + rax * 8]  ; Загружаем указатель на строку корня
    mov r9, [rsi + r12 * 8]  ; Загружаем указатель на строку правого потомка
    call cmp_lines           ; Сравниваем строки
    test al, al              ; Проверяем результат сравнения
    jz .no_right_child       ; Если корень больше, переходим к завершению
    mov rax, r12             ; Иначе обновляем индекс наибольшего элемента

.no_right_child:
    ; Если наибольший элемент не корень, меняем их местами
    cmp rax, rdx             ; Сравниваем индекс наибольшего элемента с корнем
    je .done                 ; Если они равны, завершаем

    ; Меняем указатели на строки
    mov r8, [rsi + rdx * 8]  ; Загружаем указатель на строку корня
    mov r9, [rsi + rax * 8]  ; Загружаем указатель на строку наибольшего элемента
    mov [rsi + rdx * 8], r9  ; Обмениваем их местами
    mov [rsi + rax * 8], r8

    ; Рекурсивно вызываем heapify для поддерева
    mov rdx, rax             ; Новый корень — это индекс наибольшего элемента
    call heapify             ; Рекурсивный вызов

.done:
    pop r12                  ; Восстанавливаем r12
    pop rbx                  ; Восстанавливаем rbx
    pop rbp                  ; Восстанавливаем rbp
    ret

; Основная процедура пирамидальной сортировки
heap_sort:
    ; Входные параметры:
    ; rsi - массив указателей на строки
    ; rcx - количество строк

    push rbp
    mov rbp, rsp

    ; Построение кучи (перегруппировка массива)
    mov rdx, rcx
    shr rdx, 1
    dec rdx

.build_heap:
    cmp rdx, 0
    jl .heap_built
    call heapify
    dec rdx
    jmp .build_heap

.heap_built:
    ; Извлечение элементов из кучи
    mov rdx, rcx
    dec rdx

.extract:
    cmp rdx, 0
    jle .done

    ; Меняем корень кучи с последним элементом
    mov r8, [rsi]
    mov r9, [rsi + rdx * 8]
    mov [rsi], r9
    mov [rsi + rdx * 8], r8

    ; Уменьшаем размер кучи и вызываем heapify для корня
    dec rdx
    call heapify

    jmp .extract

.done:
    pop rbp
    ret

; Сравнение строк по сумме элементов
cmp_lines:
    ; Входные параметры:
    ; r8 - указатель на первую строку
    ; r9 - указатель на вторую строку
    ; Возвращает:
    ; al = 1, если сумма первой строки > суммы второй строки, иначе 0

    push rcx
    push rdx
	push rbx

    ; Вычисляем сумму элементов первой строки
    movzx rcx, byte [m]
    xor rax, rax
	xor rbx, rbx
    xor rdx, rdx
sum_line1:
    add rax, [r8 + rdx * 8]
    inc rdx
    loop sum_line1

    ; Вычисляем сумму элементов второй строки
    movzx rcx, byte [m]
    xor rdx, rdx
sum_line2:
    add rbx, [r9 + rdx * 8]
	inc rdx
    loop sum_line2

    ; Сравниваем суммы
    cmp rax, rbx
    jg .greater
    jl .less
    xor al, al
    jmp .done_cmp

.greater:
    mov al, [sort_order]  ; 1 - по возрастанию, 0 - по убыванию
    jmp .done_cmp

.less:
    mov al, 1
    sub al, [sort_order]  ; Инвертируем порядок, если sort_order = 0

.done_cmp:
	pop rbx
    pop rdx
    pop rcx
    ret