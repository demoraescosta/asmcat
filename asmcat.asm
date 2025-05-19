format ELF64 executable

sys_stdout equ 1
sys_stderr equ 2

sys_exit equ 60

sys_read equ 0
sys_write equ 1
sys_open equ 2
sys_close equ 3

page_size equ 4096

segment readable executable

entry start

start:
    pop rcx
    cmp rcx, 2
    jl error_insufficient_args

    pop rdi
    pop rdi ; get the filename at the top of the stack

    mov rax, sys_open
    ; rsi has pointer to the filename
    mov rsi, 0 ; readonly
    mov rdx, 0  
    syscall

    mov [filedesc], rax

    cmp rax, 0
    jl error_file_not_found

read:
    mov rax, sys_read
    mov rdi, [filedesc]
    mov rsi, buffer
    mov rdx, buffer_sz
    syscall

    cmp rax, 0 
    js error_failed_to_read_file
    je exit
    
    mov rdx, rax ; save byte count read
    mov rax, sys_write
    mov rdi, sys_stdout
    mov rsi, buffer
    syscall 

    cmp rax, rdx ; check if could write whole chunck
    jne exit

    jmp read

cleanup:
    mov rax, sys_close
    mov rdi, [filedesc]
    syscall

    ret

exit:
    call cleanup
    xor rdi, rdi
    mov rax, sys_exit
    syscall

error_insufficient_args:
    mov rax, sys_write
    mov rdi, sys_stderr
    mov rsi, error_insufficient_args_msg
    mov rdx, error_insufficient_args_msg_sz
    mov rax, sys_write 

    syscall

    mov rdi, 1
    mov rax, sys_exit
    syscall


error_file_not_found:
    mov rax, sys_write
    mov rdi, sys_stderr
    mov rsi, error_file_not_found_msg
    mov rdx, error_file_not_found_msg_sz
    mov rax, sys_write 

    syscall

    mov rdi, 1
    mov rax, sys_exit
    syscall

error_failed_to_read_file:
    call cleanup
    mov rax, sys_write
    mov rdi, sys_stderr
    mov rsi, error_file_couldnt_be_read_msg
    mov rdx, error_file_couldnt_be_read_msg_sz
    mov rax, sys_write 

    syscall

    mov rdi, 1
    mov rax, sys_exit
    syscall

segment readable writeable

    filedesc dq 0 

    buffer_sz dq page_size
    buffer rb buffer_sz

    error_insufficient_args_msg db "Usage: asmcat <FILENAME>", 0xA
    error_insufficient_args_msg_sz = $-error_insufficient_args_msg

    error_file_not_found_msg db "ERROR: Failed to open file", 0xA
    error_file_not_found_msg_sz = $-error_file_not_found_msg

    error_file_couldnt_be_read_msg db "ERROR: File could not be read", 0xA
    error_file_couldnt_be_read_msg_sz = $-error_file_not_found_msg


