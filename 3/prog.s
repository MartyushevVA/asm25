bits 64

section .data
size equ 4096

prompt:     db "Enter filename: ", 0
promptlen:  equ $ - prompt

newline:    db 10
nofile:     db "No such file or directory", 10
nofilelen:  equ $ - nofile

filename:   times 256 db 0

section .bss
chr: resb 1
str:        resb size

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

    dec rax
    cmp byte [filename + rax], 10
    jne .open_file
    mov byte [filename + rax], 0

.open_file:
    mov eax, 2
    mov rdi, filename
    xor esi, esi
    syscall
    cmp eax, 0
    jl .error_open
    mov edi, eax

.next_line:
    xor rbx, rbx

.read_char:
    mov eax, 0
    mov rsi, chr
    mov edx, 1
    syscall
    
    test rax, rax
    jle .process_line
    push rax
    mov al, byte [chr]
    mov [str + rbx], al
    inc rbx
    cmp al, 10
    pop rax
    je .process_line
    cmp rbx, size
    jb .read_char

.process_line:
    cmp rbx, 1
    jne .normal_line
    cmp byte [str], 10
    jne .normal_line

    push rdi
    mov eax, 1
    mov edi, 1
    mov rsi, newline
    mov edx, 1
    syscall
    pop rdi
    jmp .next_line

.normal_line:
    mov rsi, str
    mov rdx, rbx
    push rdi
    push rax
    call work

    mov edx, eax
    mov eax, 1
    mov edi, 1
    mov rsi, str
    syscall

    mov eax, 1
    mov edi, 1
    mov rsi, newline
    mov edx, 1
    syscall
    pop rax
    pop rdi

    cmp rax, 0
    jg .next_line

    mov eax, 3
    mov edi, edi
    syscall
    jmp .exit

.error_open:
    mov eax, 1
    mov edi, 2
    mov rsi, nofile
    mov edx, nofilelen
    syscall

.exit:
    mov eax, 60
    xor edi, edi
    syscall

; rsi - адрес строки
; rdx - длина строки
; rax - новая длина строки

work:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rbx
    push rdi
    push rcx
    push rdx

    mov rdi, rsi
    lea rbx, [rsi]
    mov rcx, rdx
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11

.next_char:
    
    cmp rcx, 0
    je .maybe_flush
    mov al, [rdi]
    inc rdi
    dec rcx
    push rcx

    cmp al, ' '
    je .delim
    cmp al, 9
    je .delim
    cmp al, 10
    je .delim

    cmp r8, 0
    jne .add_char
    lea r9, [rdi-1]

.add_char:
    inc r8
    jmp .next_char

.delim:
    cmp r8, 0
    je .maybe_add_delim

    mov rsi, r9
    mov ecx, r8d
    call is_digit_word
    test eax, eax
    jnz .skip_word

    cmp r11, 0
    je .no_space
    mov byte [rbx + r10], ' '
    inc r10
.no_space:
    mov rsi, r9
    mov ecx, r8d
.copy_word:
    mov al, [rsi]
    mov [rbx + r10], al
    inc rsi
    inc r10
    loop .copy_word
    mov r11, 1

.skip_word:
    xor r8, r8

.maybe_add_delim:
    cmp al, 10
    je .maybe_flush
    pop rcx
    jmp .next_char

.maybe_flush:
    cmp r8, 0
    je .done
    mov rsi, r9
    mov ecx, r8d
    call is_digit_word
    test eax, eax
    jnz .done

    cmp r11, 0
    je .done_word
    mov byte [rbx + r10], ' '
    inc r10
.done_word:
    mov rsi, r9
    mov ecx, r8d
.copy_last:
    mov al, [rsi]
    mov [rbx + r10], al
    inc rsi
    inc r10
    loop .copy_last

.done:
    mov rax, r10
    pop rdx
    pop rcx
    pop rdi
    pop rbx
    leave
    ret

; rsi — указатель на слово
; ecx — длина

is_digit_word:
    test ecx, ecx
    je .not_digit
.next:
    mov al, [rsi]
    inc rsi
    cmp al, '0'
    jb .not_digit
    cmp al, '9'
    ja .not_digit
    dec ecx
    jnz .next
    mov eax, 1
    ret
.not_digit:
    xor eax, eax
    ret