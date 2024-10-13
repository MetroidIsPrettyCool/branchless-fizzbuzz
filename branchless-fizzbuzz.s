; -*- mode: nasm; -*-

%define SYS_WRITE 1
%define SYS_EXIT 60
%define STDOUT_FILENO 1
%define NEWLINE 10

section .data
align 16, db 0

%define NUM_DIGITS 3            ; number of digits to use to represent numbers

str_itoa_result: db NUM_DIGITS dup (0), NEWLINE
len_itoa_result: equ $-str_itoa_result

align 16, db 0

str_fizz: db "Fizz", NEWLINE
len_fizz: equ $-str_fizz

align 16, db 0

str_buzz: db "Buzz", NEWLINE
len_buzz: equ $-str_buzz

align 16, db 0

str_fizzbuzz: db "FizzBuzz", NEWLINE
len_fizzbuzz: equ $-str_fizzbuzz

align 16, db 0

ptr_array_lengths: dq len_fizzbuzz, len_itoa_result, 0, 0, 0, 0, len_fizz, 0, 0, 0, len_buzz

align 16, db 0

str_array_strs: dq str_fizzbuzz, str_itoa_result, 0, 0, 0, 0, str_fizz, 0, 0, 0, str_buzz

section .text

global _start
_start:
        mov rcx, 1

        ; main loop
        call func_fizzorbuzzorbothorneither
%rep 999
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
        ; clobbers: rax, rcx, rdx, rdi, rsi
func_fizzorbuzzorbothorneither:
        push rcx

        ; precalculate itoa in case we use it
        call func_itoa

        ; do our stupid procedure from http://philcrissman.net/posts/eulers-fizzbuzz/
        xor rdx, rdx            ; zero upper half of rdx:rax
        mov rax, rcx            ; rdx:rax = rcx^1
        mul rcx                 ; rdx:rax = rcx^2
        mul rcx                 ; rdx:rax = rcx^3
        mul rcx                 ; rdx:rax = rcx^4
        mov rdi, 15
        div rdi                 ; remainder in RDX

        mov rsi, [rdx * 8 + str_array_strs]
        mov rdx, [rdx * 8 + ptr_array_lengths]

        mov rax, SYS_WRITE
        mov rdi, STDOUT_FILENO

        syscall

        pop rcx

        ret

        ; Converts an integer into a string (not null-terminated)
        ;
        ; arguments: rcx - unsigned number to convert from integer to string
        ;
        ; results: str_itoa_result - string representation of rcx, rsi - pointer to str_itoa_result (to align with
        ; ~write~)
        ;
        ; clobbers: rax, rdx, rsi, rdi
func_itoa:
        push rcx

        ; setup
        mov rsi, str_itoa_result

        mov rdi, 10             ; to be held constant for the duration of the subroutine

        mov rax, rcx

%define i NUM_DIGITS-1
        ; division
        xor rdx, rdx
        div rdi                 ; div 10
        add rdx, '0'
        mov [i + str_itoa_result], dl
%rep NUM_DIGITS-1
%assign i i-1
        xor rdx, rdx
        div rdi                 ; div 10
        add rdx, '0'
        mov [i + str_itoa_result], dl
%endrep

        pop rcx

        ret
