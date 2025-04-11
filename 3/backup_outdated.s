bits 64

section .data

size equ 4096

prompt:     db "Enter filename: ", 0
promptlen: equ $ - prompt

newline:    db 10

nofile:     db "No such file or directory", 10
nofilelen:  equ $ - nofile

permission: db "Permission denied", 10
permissionlen: equ $ - permission

unknown:    db "Unknown error", 10
unknownlen: equ $ - unknown

filename:
    times 256 db 0

delim:
    db ' ', 9, 0

str:
    times size db 0

newstr:
    times size db 0

section .text
global _start

_start:
    mov eax, 1
    mov edi, 1
    mov rsi, prompt
    mov edx, promptlen
    syscall

    mov eax, 0
    mov edi, 0
    mov rsi, filename
    mov edx, 256
    syscall
    test rax, rax
    jle .exit

    mov rcx, rax
    dec rcx
    cmp byte [filename + rcx], 10
    jne .open_file
    mov byte [filename + rcx], 0

.open_file:
    mov eax, 2
    mov rdi, filename
    xor esi, esi
    syscall
    cmp eax, 0
    jl .error_open
    mov ebx, eax

.read_loop:
    mov eax, 0
    mov edi, ebx
    mov rsi, str
    mov edx, size
    syscall
    test eax, eax
    jle .close_file

    mov rdi, newstr
    mov rsi, str
    mov rdx, delim
    call work

    mov edx, eax
    mov eax, 1
    mov edi, 1
    mov rsi, newstr
    syscall
    jmp .read_loop

.close_file:
    mov eax, 1
    mov edi, 1
    mov rsi, newline
    mov edx, 1
    syscall

    mov eax, 3
    mov edi, ebx
    syscall
    jmp .exit

.error_open:
    mov eax, eax
    call writeerr

.exit:
    mov eax, 60
    xor edi, edi
    syscall

writeerr:
    cmp eax, -2
    jne .w1
    mov rsi, nofile
    mov edx, nofilelen
    jmp .wout

.w1:
    cmp eax, -13
    jne .w2
    mov rsi, permission
    mov edx, permissionlen
    jmp .wout

.w2:
    mov rsi, unknown
    mov edx, unknownlen

.wout:
    mov eax, 1
    mov edi, 2
    syscall
    ret

sou equ 8
res equ sou + 8
del equ res + 8
w equ del + 8 * size / 2
wl equ w + 4 * size / 2
n equ wl + 4

work:
    push rbp
    mov rbp, rsp
    sub rsp, n
    and rsp, -8

    push rbx

    mov [rbp - sou], rsi
    mov [rbp - res], rdi
    mov [rbp - del], rdx
    mov r8d, eax
    xor r9d, r9d
    xor ebx, ebx
    xor ecx, ecx

.another_symb:
    mov al, [rsi]
    inc r9d
    inc rsi

    mov rdi, [rbp - del]
.delim_cycle:
    cmp byte [rdi], 0
    je .symb_is_not_del
    cmp byte [rdi], al
    je .word_process
    inc rdi
    jmp .delim_cycle

.symb_is_not_del:
    or ebx, ebx
    jne .not_first_let_in_word
    mov [rbp - w + rcx * 8], rsi
    dec qword [rbp - w + rcx * 8]
.not_first_let_in_word:
    inc ebx
    cmp r9d, r8d
    jne .another_symb

.word_process:
    or ebx, ebx
    je .empty_word

    push rax
    push rcx
    push rdi
    push rsi
    mov esi, ecx
    mov rdi, [rbp - w + rcx * 8]
    mov esi, ebx
    call is_digit_word
    or eax, eax
    pop rsi
    pop rdi
    pop rcx
    pop rax
    jnz .remove_word

    mov [rbp - wl + rcx * 4], ebx
    xor ebx, ebx
    inc ecx
    jmp .empty_word

.remove_word:
    xor ebx, ebx

.empty_word:
    cmp r9d, r8d
    jne .another_symb

    mov [rbp - n], ecx
    dec ecx
    or ecx, ecx
    je .one_word
    jl .empty_row

.one_word:
    mov rdi, [rbp - res]
    mov ecx, [rbp - n]
    xor ebx, ebx

.insert_word:
    push rcx
    or ebx, ebx
    je .prepare_word
    mov byte [rdi], ' '
    inc rdi

.prepare_word:
    mov rsi, [rbp - w + rbx * 8]
    mov ecx, [rbp - wl + rbx * 4]
    inc rbx

.insert_words_letter:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    loop .insert_words_letter
    pop rcx
    loop .insert_word

.empty_row:
    pop rbx
    leave
    ret

is_digit_word:
    or esi, esi
    je .not_digit
    xor eax, eax
.check_loop:
    mov al, [rdi]
    inc rdi
    sub al, '0'
    cmp al, 9
    ja .not_digit
    jb .not_digit
    dec esi
    jnz .check_loop
    mov eax, 1
    ret
.not_digit:
    xor eax, eax
    ret
