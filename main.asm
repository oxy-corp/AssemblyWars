section .data
    String_AngelDust db "Angel Dust", 0xA, 0
    String_Code db "AD", 0xA, 0
    String_Description db "Developed as a dissociative anesthetic, Angel Dust gained popularity in the 1960s. Discontinued for medical use due to its unpredictable and severe side effects.", 0xA, 0
    String_Effects db "Hallucination, distorted perceptions of reality, increased strength, and a dissociative state.", 0xA, 0
    Float_PriceMultiplier dq 1.5       ; Define the floating-point value
    Prompt db "Enter offset (0, 8, 16, 24, 32, 40, 48): ", 0
    InvalidOffset db "Invalid offset.", 10, 0xA, 0

section .bss 
    InputBuffer resb 8             ; Buffer for user input
    DrugInstance resq 7

section .text
global _start

_start:
    ; Allocate memory for the Drug struct using mmap system call
    mov rdi, 0                  ; addr = 0 (let kernel choose address)
    mov rsi, 56                 ; length = 56 bytes
    mov rdx, 3                  ; prot = PROT_READ | PROT_WRITE
    mov r10, 34                 ; flags = MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1                  ; fd = -1 (no file descriptor)
    mov r9, 0                   ; offset = 0
    mov rax, 9                  ; syscall: mmap
    syscall

    test rax, rax
    js .exit_error              ; Exit if mmap fails

    mov rbx, rax                ; Save allocated address in rbx

    ; Populate struct fields
    lea rsi, [String_AngelDust] ; Load address of Name
    mov [rbx], rsi              ; Store in struct offset 0

    lea rsi, [String_Code]      ; Load address of Code
    mov [rbx + 8], rsi          ; Store in struct offset 8

    lea rsi, [String_Description]
    mov [rbx + 16], rsi         ; Store in struct offset 16

    mov dword [rbx + 24], 1000  ; BasePrice (int) at offset 24

    lea rsi, [String_Effects]   ; Load address of Effects
    mov [rbx + 32], rsi         ; Store in struct offset 32

    ; Load the PriceMultiplier (float) from data section
    lea rsi, [Float_PriceMultiplier]
    movq xmm0, [rsi]            ; Load 64-bit float into xmm0 register
    movq [rbx + 40], xmm0       ; Store into struct offset 40

    mov dword [rbx + 48], 10    ; Quantity (int) at offset 48

.input_loop:
    ; Display the prompt
    lea rsi, [Prompt]
    mov rdi, 1                  ; stdout
    xor rdx, rdx
.count_prompt_length:
    mov al, byte [rsi + rdx]
    test al, al
    jz .done_prompt_length
    inc rdx
    jmp .count_prompt_length
.done_prompt_length:
    mov rax, 1                  ; syscall: write
    syscall

    ; Read user input
    mov rdi, 0                  ; stdin
    lea rsi, [InputBuffer]      ; Buffer for input
    mov rdx, 8                  ; Max input size
    mov rax, 0                  ; syscall: read
    syscall

    ; Parse input as an integer
    xor r8, r8                ; r8 = final offset
    mov rcx, 0                ; rcx = current index
    xor rdx, rdx              ; rdx = power of 10 (multiplier)
.parse_input:
    mov al, byte [InputBuffer + rcx]
    cmp al, 10                ; Check for newline
    je .done_parsing
    test al, al               ; End of string?
    jz .done_parsing
    sub al, '0'               ; Convert ASCII to integer
    jl .invalid_input         ; If not a digit, invalid input
    cmp al, 9
    jg .invalid_input

    imul r8, r8, 10           ; Shift left (multiply by 10)
    add r8, rax               ; Add current digit
    inc rcx                   ; Next character
    jmp .parse_input
.done_parsing:

    ; Validate the offset
    cmp r8, 0
    je .print_field
    cmp r8, 8
    je .print_field
    cmp r8, 16
    je .print_field
    cmp r8, 24
    je .print_field
    cmp r8, 32
    je .print_field
    cmp r8, 40
    je .print_field
    cmp r8, 48
    je .print_field
    jmp .invalid_input


.print_field:
    ; Load the value at rbx + r8 and print it
    add r8, rbx
    mov rsi, [r8]
    mov rdi, 1                  ; stdout
    xor rdx, rdx
.count_field_length:
    mov al, byte [rsi + rdx]
    test al, al
    jz .done_field_length
    inc rdx
    jmp .count_field_length
.done_field_length:
    mov rax, 1                  ; syscall: write
    syscall
    jmp .input_loop

.invalid_input:
    lea rsi, [InvalidOffset]
    mov rdi, 1
    mov rdx, 16
    mov rax, 1                  ; syscall: write
    syscall
    jmp .input_loop

.exit_error:
    mov rax, 60                 ; syscall: exit
    mov rdi, 1                  ; status: 1
    syscall
