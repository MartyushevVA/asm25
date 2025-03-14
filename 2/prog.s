bits 64

; Пирамидальная сортировка строк матрицы по сумме элементов

section .data
    n: dd 5
    m: dd 5
    sort_order dd 1  ; 1 - по возрастанию, 0 - по убыванию

    matr: dq 12, 7,  3,  9,  15
          dq 5,  11, 8,  2,  14
          dq 1,  10, 6,  13, 4
          dq 18, 17, 16, 20, 19
          dq 21, 25, 22, 23, 24

    res_m: dq 0, 0, 0, 0, 0
         dq 0, 0, 0, 0, 0
         dq 0, 0, 0, 0, 0
         dq 0, 0, 0, 0, 0
         dq 0, 0, 0, 0, 0

    row_ptrs: dq 0, 0, 0, 0, 0
    row_sums: dq 0, 0, 0, 0, 0

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
    jge succ_comp
    inc rcx

succ_comp:
    cmp r12, [rdx + rcx * 8]
    jge curr_save

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
    jle exit_program
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
    pop rcx
    pop rsi
    add rsi, r8
    loop upload_line

exit_program:
    mov rax, 60
    xor rdi, rdi
    syscall