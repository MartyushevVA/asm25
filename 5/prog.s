section .note.GNU-stack,"",@progbits  ; Добавляем секцию для отключения executable stack
section .text
global processImageASM

processImageASM:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    ; Аргументы:
    ; rdi - image pointer
    ; esi - width
    ; edx - height
    ; ecx - channel (0-R, 1-G, 2-B)

    mov r12, rdi        ; image pointer
    mov r13d, esi       ; width
    mov r14d, edx       ; height
    mov r15d, ecx       ; channel

    ; Вычисляем размер строки
    mov eax, r13d       ; width
    imul eax, 3         ; width * 3
    mov edx, eax
    and edx, 3          ; padding = (width * 3) % 4
    mov edi, 4
    sub edi, edx
    and edi, 3          ; padding = (4 - (width * 3) % 4) % 4
    add eax, edi        ; row_size = width * 3 + padding

    ; Основной цикл
    xor r9d, r9d        ; y = 0
height_loop:
    cmp r9d, r14d
    jge done

    xor r10d, r10d      ; x = 0
width_loop:
    cmp r10d, r13d
    jge next_row

    ; Вычисляем offset
    mov edx, r9d        ; y
    imul edx, eax       ; y * row_size
    mov ebx, r10d       ; x
    imul ebx, 3         ; x * 3
    add ebx, edx        ; offset = y*row_size + x*3

    ; Получаем значение канала
    movzx ecx, r15b     ; channel index
    add rbx, r12        ; image + offset
    mov dl, [rbx + rcx] ; image[offset + channel]

    ; Устанавливаем значения каналов
    mov [rbx], dl       ; B
    mov [rbx + 1], dl   ; G
    mov [rbx + 2], dl   ; R

    inc r10d
    jmp width_loop

next_row:
    inc r9d
    jmp height_loop

done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret