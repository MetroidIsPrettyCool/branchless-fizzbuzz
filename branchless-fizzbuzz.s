; -*- mode: nasm; -*-

%define START_NUM 1
%define END_NUM 1000

%define SYS_WRITE 1
%define SYS_EXIT 60
%define STDOUT_FILENO 1
%define NEWLINE 10
%define QWORD_SIZE 8

section .rodata
align 16, db 0

str_fizz: db "Fizz", NEWLINE    ; "Fizz\n"
len_fizz: equ $-str_fizz

align 16, db 0

str_buzz: db "Buzz", NEWLINE    ; "Buzz\n"
len_buzz: equ $-str_buzz

align 16, db 0

str_fizzbuzz: db "FizzBuzz", NEWLINE ; "FizzBuzz\n"
len_fizzbuzz: equ $-str_fizzbuzz


section .data
align 16, db 0

%define NUM_DIGITS 20           ; $\lciel \log_{10} (2^{64} - 1) \rciel$ = 20 -- the maximum possible string length of a
                                ; 64-bit number in base 10

str_itoa_result: db NUM_DIGITS dup (0), NEWLINE ; buffer for writing the result of func_itoa to
len_itoa_result_max: equ $-str_itoa_result      ; length of said buffer + the newline

align 16, db 0

        ; array of qwords containing the lengths of ~str_fizz~, ~str_buzz~, ~str_fizzbuzz~, and
        ; ~str_itoa_result~. ~len_itoa_result~ is an alias for ~int_array_lengths[1]~.
int_array_lengths: dq len_fizzbuzz, len_itoa_result_max, 0, 0, 0, 0, len_fizz, 0, 0, 0, len_buzz
len_itoa_result: equ int_array_lengths + QWORD_SIZE

align 16, db 0

        ; array of pointers (qwords) to the strings ~str_fizz~, ~str_buzz~, ~str_fizzbuzz~ and
        ; ~str_itoa_result~. str_ptr_to_itoa_result is an alias for ~str_array_strings[1]~.
str_array_strings: dq str_fizzbuzz, str_itoa_result, 0, 0, 0, 0, str_fizz, 0, 0, 0, str_buzz
str_ptr_to_itoa_result: equ str_array_strings + QWORD_SIZE

align 16, db 0

byte_array_digit_is_0: db 1, 9 dup (0)


section .text

global _start
_start:
        mov rcx, START_NUM

        ; main loop
        call func_fizzorbuzzorbothorneither
%rep END_NUM - START_NUM
        inc rcx
        call func_fizzorbuzzorbothorneither
%endrep

        ; exit
        mov rax, SYS_EXIT
        xor rdi, rdi
        syscall


        ; Takes a number and prints "Fizz" if it's divisible by 3, or "Buzz" if it's divisible by 5, or "FizzBuzz" if
        ; it's divisible by 15, or else prints the number
        ;
        ; arguments: rcx - number to determine if it's fizz or buzz or both or neither
        ;
        ; results: none
        ;
        ; clobbers: rax, rdx, rdi, rsi
func_fizzorbuzzorbothorneither:
        push rcx                ; preserve rcx so as not to clobber it. I typically prefer to save registers from the
                                ; caller, but that'd inflate my binary something tremendous if I did it here.

        ; compute itoa of rcx
        call func_itoa

        ; do our stupid procedure from http://philcrissman.net/posts/eulers-fizzbuzz/
        xor rdx, rdx            ; zero upper half of rdx:rax
        mov rax, rcx            ; rdx:rax = rcx^1
        mul rcx                 ; rdx:rax = rcx^2
        mul rcx                 ; rdx:rax = rcx^3
        mul rcx                 ; rdx:rax = rcx^4
        mov rdi, 15
        div rdi                 ; final remainder is now in RDX

        ; print our result (string at str_array_strings[rdx], length at int_array_lengths[rdx])
        mov rax, SYS_WRITE
        mov rdi, STDOUT_FILENO
        mov rsi, [rdx * 8 + str_array_strings]
        mov rdx, [rdx * 8 + int_array_lengths]
        syscall

        pop rcx                 ; restore

        ret


        ; Converts an integer into a string (not null-terminated)
        ;
        ; arguments: rcx - unsigned number to convert from integer to string
        ;
        ; results: str_itoa_result - string representation of rcx, int_array_lengths[1] (AKA len_itoa_result) - length
        ; of the string, str_array_strings[1] (AKA str_ptr_to_itoa_result) - pointer to the start of str_itoa_result
        ;
        ; clobbers: rax, rdx, rdi, rsi, str_itoa_result, int_array_lengths[1], str_array_strings[1]
func_itoa:
        ; perform conversion
        mov rdi, 10             ; to be held constant for the duration of the subroutine

        mov rax, rcx

        ; iterate backwards through our buffer (~str_itoa_result~) storing the cumulative remainder of rax / 10 plus '0'
%define i NUM_DIGITS-1
%rep NUM_DIGITS
        xor rdx, rdx
        div rdi                 ; div 10
        add rdx, '0'
        mov [i + str_itoa_result], dl
%assign i i-1
%endrep

        ; determine the /actual/ length of the string (w/o any of the zero-padding)
        ;
        ; it'd be far easier to just precompute these offsets but I think that's cheating. Like at that point why not
        ; just do all the fizzbuzz stuff in the preprocessor and create a binary that's just one big ~write~ syscall and
        ; an array of text. Or heck just a text file. No thank you. I will limit my use of the preprocessor to rep loops
        ; and symbol defines.
        mov rdx, 1              ; store if all previous bytes have been '0'
        mov rdi, str_itoa_result ; pointer to the start of the string
        mov rsi, len_itoa_result_max ; length of the string

        ; iterate through ~str_itoa_result~, decrementing the length and incrementing the start pointer for every
        ; leading '0'.
%assign i 0
%rep NUM_DIGITS
        movzx rax, byte [str_itoa_result + i]
        movzx rax, byte [rax + byte_array_digit_is_0 - '0']
        and rdx, rax
        add rdi, rdx
        sub rsi, rdx
%assign i i+1
%endrep

        ; store results into the relevant tables
        mov [str_ptr_to_itoa_result], rdi
        mov [len_itoa_result], rsi

        ret
