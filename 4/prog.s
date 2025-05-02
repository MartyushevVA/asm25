section .data
    prompt:     db "Input x and epsilon: ", 0
    fmt_scan:   db "%lf %lf", 0
    fmt_print:  db "Formula: %.9lf", 10, 0
    fmt_print2: db "Series:  %.9lf", 10, 0
    fmt_term:   db "%d %.10g", 10, 0
    sqrt_fmt:   db "sqrt: value error", 10, 0
    fopen_err:  db "Failed to open output file.", 10, 0
    one: dq 1.0
    mode_write: db "w", 0

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
    sub rsp, 32

    mov rdi, [rsi+8]
    mov rsi, mode_write
    call fopen
    test rax, rax
    jz .fopen_fail
    mov [file_ptr], rax

    mov rdi, prompt
    xor eax, eax
    call printf

    mov rdi, fmt_scan
    lea rsi, [x]
    lea rdx, [eps]
    xor eax, eax
    call scanf

    movsd xmm1, [x]
    mulsd xmm1, xmm1
    movsd xmm0, qword [one]
    subsd xmm0, xmm1
    movsd xmm8, xmm0
    call sqrt
    test eax, eax
    jp .sqrt_fail
    mulsd xmm0, xmm8
    movsd xmm1, qword [one]
    divsd xmm1, xmm0
    movsd [sum], xmm1

    mov rdi, fmt_print
    movsd xmm0, [sum]
    mov eax, 1
    call printf

    pxor xmm0, xmm0
    movsd [sum], xmm0

    movsd xmm0, qword [one]
    movsd [term], xmm0

    mov rbx, 0
    mov r12, 1
    mov r13, 1

.loop_series:
    cmp rbx, 50000
    jge .done_series

    cvtsi2sd xmm1, r12
    cvtsi2sd xmm2, r13
    divsd xmm1, xmm2
    movsd xmm8, xmm1

    movsd xmm0, [x]
    cvtsi2sd xmm1, rbx
    addsd xmm1, xmm1
    sub rsp, 16
    movaps [rsp], xmm8
    call pow
    movaps xmm8, [rsp]
    add rsp, 16
    mulsd xmm0, xmm8

    movsd xmm1, [eps]
    ucomisd xmm0, xmm1
    jb .done_series

    movsd xmm1, [sum]
    addsd xmm1, xmm0
    movsd [sum], xmm1

    mov rdi, [file_ptr]
    mov rsi, fmt_term
    mov rdx, rbx
    mov eax, 2
    call fprintf

    inc rbx
    mov r14, rbx
    shl r14, 1
    imul r13, r14
    inc r14
    imul r12, r14
    jmp .loop_series

.done_series:
    mov rdi, fmt_print2
    movsd xmm0, [sum]
    mov eax, 1
    call printf

    ; mov rdi, [file_ptr]
    ; call fclose
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
    mov rdi, [file_ptr]
    call fclose
    leave
    xor eax, eax
    ret
