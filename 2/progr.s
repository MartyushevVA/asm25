bits 64

; Пирамидальная сортировка строк матрицы по сумме элементов

section .data
    n: dd 10
    m: dd 10

    ;matr: dq 12, 7,  3,  9,  15
    ;      dq 5,  11, 8,  2,  14
    ;      dq 1,  10, 6,  13, 4
    ;      dq 18, 17, 16, 20, 19
    ;      dq 21, 25, 22, 23, 24
matr: dq  5,  14,  -8,  70,  20,  50,  -7,  30,  75,  15 ; 264 1
      dq 18,  40,  60,  85,  10,  32,  55,  72,  88,  12 ; 472 2
      dq -4,  25,  42,  65,  80,  15,  33,  58,  77,  85 ; 476 3
      dq 10,  30,  54,  76,  88,  13,  22,  44,  66,  87 ; 490 7
      dq 20,  42,  63,  82,  14,  36,  57,  74,  92,  10 ; 490 7
      dq -6,  24,  43,  68,  84,  16,  35,  59,  79,  86 ; 488 6
      dq 11,  33,  55,  77,  89,  12,  24,  46,  68,  88 ; 503 8
      dq 19,  41,  62,  81,  13,  35,  56,  73,  91,  12 ; 483 4
      dq -2,  22,  44,  66,  83,  17,  34,  57,  76,  89 ; 486 5
      dq 13,  35,  57,  79,  90,  14,  25,  47,  69,  88 ; 517 9

    res_m: dq 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
           dq 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
           dq 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
           dq 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
           dq 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
           dq 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
           dq 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
           dq 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
           dq 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
           dq 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

    row_ptrs: dq 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    row_sums: dq 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

section .text
    global _start

_start:
    mov rbx, matr
    mov ecx, [n]
	mov rdi, rcx
    dec rdi
	jle exit_program

    push rdi
    mov rdi, row_ptrs
    mov rdx, row_sums
    xor r8, r8

    mov r10d, [n]
    shl r10, 3

init_ptrs_n_sums:
    mov [rdi + r8 * 8], rbx
    call calc_sum ; вычисление суммы r8-й строки
    mov [rdx + r8 * 8], rax
    add rbx, r10
    inc r8
    loop init_ptrs_n_sums
    ; массивы указателей и сумм заполнены
    ; rsi - n
    ; rdx - sums
    ; r10 - n*8 - размер строки

heap_sort:
    pop rdi ; rdi - индекс последней строки
    mov rbx, row_ptrs
    ; rbx - ptrs

    mov esi, [n]
    shr rsi, 1

outer_cycle:
    or rsi, rsi
    jnz dec_rsi
    cmp rdi, 1
    jz first_second_comp

    mov rax, [rbx]
    xchg rax, [rbx + rdi * 8]
    mov [rbx], rax

    mov rax, [rdx]
    xchg rax, [rdx + rdi * 8]
    mov [rdx], rax

    dec rdi
    jmp next_elem

dec_rsi:
    dec rsi

next_elem:
    mov r11, [rbx + rsi * 8]
    mov r12, [rdx + rsi * 8]
    push rsi
    mov rcx, rsi

check:
    shl rcx, 1
    inc rcx ; rcx - на левом потомке
    cmp rcx, rdi
    je succ_comp
    jg curr_save

    mov r10, [rdx + rcx * 8]
    cmp r10, [rdx + rcx * 8 + 8]
    jle succ_comp
    inc rcx

succ_comp:
    cmp r12, [rdx + rcx * 8]
    jle curr_save

    mov r10, [rbx + rcx * 8]
    mov [rbx + rsi * 8], r10

    mov r10, [rdx + rcx * 8]
    mov [rdx + rsi * 8], r10

    mov rsi, rcx
    jmp check

curr_save:
    mov [rbx + rsi * 8], r11
    mov [rdx + rsi * 8], r12
    pop rsi
    jmp outer_cycle

calc_sum:
    push rbp
    mov rbp, rsp

    push rcx
    push rdx
    ; rax - результат
    ; rbx - начало строки
    ; rcx - количесвто элементов в строке
    ; rdx - индекс элемента
    xor rax, rax
    xor rdx, rdx
    mov ecx, [m]

sum_line:
    add rax, [rbx + rdx * 8]
    jo overflow_error
    inc rdx
    loop sum_line

    pop rdx
    pop rcx
    pop rbp
    ret

overflow_error:
    mov rax, 60
    mov rdi, 1
    syscall

first_second_comp:
    mov rax, [rdx]
    cmp rax, [rdx + 8]
    jge exit_program
    mov rax, [rbx]
    xchg rax, [rbx + 8]
    mov [rbx], rax

upload_matr:
    ; rbx - массив указателей на строки
    mov ecx, [n]
    mov r8, rcx
    shl r8, 3 ; r8 размер одной строки
    mov rsi, rbx 
    mov rdi, res_m
    ; rsi - массив адресов строк
    ; rdi - полученная матрица
upload_line:
    push rcx
    push rsi
    mov ecx, [m]
    mov rsi, [rsi]
upload_elem:
    ; rsi - адрес начала строки
    ; rax - индекс элемента в строке
    mov r9, [rsi]
    mov [rdi], r9
    add rdi, 8 ; увеличили адрес вставки
    add rsi, 8
    loop upload_elem
    pop rsi
    pop rcx
    add rsi, 8
    loop upload_line

exit_program:
    mov rax, 60
    xor rdi, rdi
    syscall