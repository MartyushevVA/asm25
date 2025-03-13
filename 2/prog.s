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

    row_ptrs: dq 0, 0, 0, 0, 0

section .text
    global _start

_start:
    mov rbx, matr
    lea rdi, [row_ptrs]
    movzx rcx, byte[n]
	dec rcx
	jle exit_program
	inc rcx
    xor r8, r8

	movzx rax, byte [m]
    shl rax, 3

init_ptrs:
    mov [rdi + r8 * 8], rbx
    add rbx, rax
    inc r8
    loop init_ptrs
    
    lea rsi, [row_ptrs]
    movzx rcx, byte[n]
    call heap_sort

exit_program:
    mov rax, 60
    xor rdi, rdi
    syscall


heapify:
    push rbp
    mov rbp, rsp

	push rbx
    push r12

    mov rax, rdx
    mov rbx, rax
    shl rbx, 1
    inc rbx
    mov r12, rbx
    inc r12

    cmp rbx, rcx
    jge .no_left_child
    mov r8, [rsi + rax * 8]
    mov r9, [rsi + rbx * 8]
    call cmp_lines
    test al, al
    jz .no_left_child
    mov rax, rbx

.no_left_child:
    cmp r12, rcx
    jge .no_right_child
    mov r8, [rsi + rax * 8]
    mov r9, [rsi + r12 * 8]
    call cmp_lines
    test al, al
    jz .no_right_child 
    mov rax, r12

.no_right_child:
    cmp rax, rdx
    je .done

    mov r8, [rsi + rdx * 8]
    mov r9, [rsi + rax * 8]
    mov [rsi + rdx * 8], r9
    mov [rsi + rax * 8], r8

    mov rdx, rax
    call heapify

.done:
    pop r12
    pop rbx
    pop rbp
    ret

heap_sort:
    push rbp
    mov rbp, rsp

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
    mov rdx, rcx
    dec rdx

.extract:
    cmp rdx, 0
    jle .done

    mov r8, [rsi]
    mov r9, [rsi + rdx * 8]
    mov [rsi], r9
    mov [rsi + rdx * 8], r8

    dec rdx
    call heapify

    jmp .extract

.done:
    pop rbp
    ret

cmp_lines:
    push rcx
    push rdx
	push rbx

    movzx rcx, byte [m]
    xor rax, rax
	xor rbx, rbx
    xor rdx, rdx
sum_line1:
    add rax, [r8 + rdx * 8]
    inc rdx
    loop sum_line1

    movzx rcx, byte [m]
    xor rdx, rdx
sum_line2:
    add rbx, [r9 + rdx * 8]
	inc rdx
    loop sum_line2

    cmp rax, rbx
    jg .greater
    jl .less
    xor al, al
    jmp .done_cmp

.greater:
    mov al, [sort_order]
    jmp .done_cmp

.less:
    mov al, 1
    sub al, [sort_order]

.done_cmp:
	pop rbx
    pop rdx
    pop rcx
    ret