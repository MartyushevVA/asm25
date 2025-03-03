section .data
    a dd 10
    b dd 3
    c dq 8
    d dw -6
    e db -2
    result dq 0

section .text
    global _start

_start:
    mov rsi, qword [c]
    mov ebx, dword [b]
    or ebx, ebx
    jz division_by_zero_error
    mov edi, dword [a]
    or edi, edi
    jz division_by_zero_error
    mov r8w, word [d]
    or r8w, r8w
    jz division_by_zero_error
    mov r9b, byte [e]
    or r9b, r9b
    jz division_by_zero_error

    mov rax, rsi
    cqo
    movsx rbx, ebx
    idiv rbx ;результат 64 бита в rax

    movsx rdi, edi
    imul rax, rdi
    jo overflow_error
    mov rsp, 0
    mov rsp, rax
    ;норм

    mov eax, ebx
    cdq
    movsx ecx, r9b
    idiv ecx ;результат 32 бита в eax

    cdqe ;результат в rax
    movsx rcx, r8w
    imul rcx ;результат не более 48 бит в rax

    add rsp, rax
    ;норм

    mov rax, rsi
    cqo
    movsx rcx, edi
    idiv rcx
    mov r11, rax ;результат 64 бита в r11

    mov rax, rsi
    cqo
    movsx rcx, r8w
    idiv rcx ;результат в rax

    imul r11;
    jo overflow_error

    sub rsp, rax
    ;норм

    mov qword [result], rsp

    mov rax, 60
    xor rdi, rdi
    syscall

division_by_zero_error:
    mov rax, 60
    mov rdi, 1
    syscall

overflow_error:
    mov rax, 60
    mov rdi, 2
    syscall