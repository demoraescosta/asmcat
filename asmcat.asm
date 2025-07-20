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
    jl read_stdout

    dec rcx
    mov [num_args], rcx

    pop rdi
    pop rdi ; first argument at the top of the stack

    jmp open

parse_args:
    mov al, [rdi+1]

    mov ah, 'h'
    cmp al, ah
    je print_help

    jmp read_stdout
    
open: ; attempt to open file from rsi
    ; check if is argument
    mov al, [rdi+0]
    mov ah, '-'
    cmp al, ah
    je parse_args

    mov rax, sys_open
    ; rsi has pointer to the filename
    mov rsi, 0 ; readonly
    mov rdx, 0  
    syscall

    mov [filedesc], rax

    cmp rax, 0
    jl error_file_not_found

; call open and read continuosly until it exausts all arguments
main_loop:
    mov rax, [num_args]
    dec rax
    mov [num_args], rax
    call read
    pop rdi
   
    mov rax, [num_args]
    cmp rax, 0
    je main_loop
    jne open

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

=======
    jmp .return

    jmp read
.return:
    ret

read_stdout:
    mov rax, sys_read
    mov rdi, sys_stdout
    mov rsi, buffer
    mov rdx, buffer_sz
    syscall

    mov rdx, rax ; save byte count read
    mov rax, sys_write
    mov rdi, sys_stdout
    mov rsi, buffer
    syscall 

    cmp rax, rdx ; check if could write whole chunck
    jne exit

    jmp read_stdout ; infinte loop

print_help:
    mov rax, sys_write
    mov rdi, sys_stderr
    mov rsi, help_msg
    mov rdx, help_msg_sz
    mov rax, sys_write
    syscall

    call exit
>>>>>>> cf03e10 (new functionality for asmcat)

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

=======
    call exit

exit:
    call cleanup
    xor rdi, rdi
    mov rax, sys_exit
    syscall

cleanup:
    mov rax, sys_close
    mov rdi, [filedesc]
    syscall

    ret

segment readable writeable
    filedesc dq 0 

    buffer_sz dq page_size
    buffer    rb buffer_sz

    num_args dq 0

    error_file_not_found_msg db "asmcat: No such file or directory", 0xA
    error_file_not_found_msg_sz = $-error_file_not_found_msg

    error_file_couldnt_be_read_msg db "asmcat: File could not be read", 0xA
    error_file_couldnt_be_read_msg_sz = $-error_file_not_found_msg

    help_msg db 'Usage: asmcat [OPTION]... [FILE]...', 0xA
             db 'Concatenate FILE(s) to standard output.', 0xA
             db 'With no FILE, or when FILE is -, read standard input.', 0xA
             ; TODO: finish implementing the entirety of this list
             ; db '  -A, --show-all           equivalent to -vET', 0xA
             ; db '  -b, --number-nonblank    number nonempty output lines, overrides -n', 0xA
             ; db '  -e                       equivalent to -vE', 0xA
             ; db '  -E, --show-ends          display $ at end of each line', 0xA
             ; db '  -n, --number             number all output lines', 0xA
             ; db '  -s, --squeeze-blank      suppress repeated empty output lines', 0xA
             ; db '  -t                       equivalent to -vT', 0xA
             ; db '  -T, --show-tabs          display TAB characters as ^I', 0xA
             db '  -u                       (ignored)', 0xA
             ; db '  -v, --show-nonprinting   use ^ and M- notation, except for LFD and TAB', 0xA
             db ' -h   --help        display this help and exit', 0xA
             ; db '      --version     output version information and exit', 0xA, 0xA
    help_msg_sz = $-help_msg
>>>>>>> cf03e10 (new functionality for asmcat)

