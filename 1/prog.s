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
    ;проверки пройдены

    mov eax, edi
    cdq
    idiv ebx ;результат 32 бита в eax, остаток в edx
    movsx rdi, edi
    imul rax, rsi
    jo overflow_error
    mov rsp, 0
    mov rsp, rax
    ;норм

    mov ax, r8w
    movsx cx, r9b
    cwd
    idiv cx ;результат 16 бит в ax
    cwde ;результат 32(16) бит в eax
    imul ebx ;результат в edx:eax
    mov ecx, eax
    sal rdx, 32
    or rdx, rcx ;результат 64(48) бит в rdx

    add rsp, rdx
    jo overflow_error
    ;норм

    mov eax, edi
    movsx ecx, r8w
    imul ecx ;результат 48 бит в edx:eax
    mov ecx, eax
    sal rdx, 32
    or rdx, rcx ;результат 64(48) бит в rdx
    mov r10, rdx
    mov rax, rsi
    cqo
    idiv r10 ;результат в rax
    imul rsi
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