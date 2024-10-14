;; -*- mode: nasm; -*-

%define START_NUM 1
%define END_NUM 1000

%define SYS_WRITE 1
%define SYS_EXIT 60
%define STDOUT_FILENO 1
%define LF 10
%define QWORD_SIZE 8

section .rodata
;; "Fizz\n"
align 16, db 0
str_fizz: db "Fizz", LF
LEN_FIZZ: equ $ - str_fizz

;; "Buzz\n"
align 16, db 0
str_buzz: db "Buzz", LF
LEN_BUZZ: equ $ - str_buzz

;; "FizzBuzz\n"
align 16, db 0
str_fizzbuzz: db "FizzBuzz", LF
LEN_FIZZBUZZ: equ $ - str_fizzbuzz


section .data
;; $\lceil \log_{10} (2^{64} - 1) \rceil$ = 20 -- the maximum possible string length of a 64-bit number in base 10
%define NUM_DIGITS 20

;; buffer for writing the result of func_itoa to
align 16, db 0
str_itoa_result: db NUM_DIGITS dup(0), LF
ITOA_RESULT_BUFFER_SIZE: equ $-str_itoa_result

;; array of qwords containing the lengths of ~str_fizz~, ~str_buzz~, ~str_fizzbuzz~, and
;; ~str_itoa_result~. ~len_itoa_result~ is an alias for ~int_array_lengths[1]~.
align 16, db 0
int_array_lengths: dq LEN_FIZZBUZZ, ITOA_RESULT_BUFFER_SIZE, 0, 0, 0, 0, LEN_FIZZ, 0, 0, 0, LEN_BUZZ
len_itoa_result: equ int_array_lengths + QWORD_SIZE

;; array of pointers (qwords) to the strings ~str_fizz~, ~str_buzz~, ~str_fizzbuzz~ and
;; ~str_itoa_result~. str_ptr_to_itoa_result is an alias for ~str_array_strings[1]~.
align 16, db 0
str_array_strings: dq str_fizzbuzz, str_itoa_result, 0, 0, 0, 0, str_fizz, 0, 0, 0, str_buzz
str_ptr_to_itoa_result: equ str_array_strings + QWORD_SIZE


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


;; Takes a number and prints "Fizz" if it's divisible by 3, or "Buzz" if it's divisible by 5, or "FizzBuzz" if it's
;; divisible by 15, or else prints the number
;;
;; arguments: rcx - number to determine if it's fizz or buzz or both or neither
;;
;; results: none
;;
;; clobbers: rax, rdx, rdi, rsi
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


;; Converts an integer into a string (not null-terminated)
;;
;; arguments: rcx - unsigned number to convert from integer to string
;;
;; results: str_itoa_result - string representation of rcx (zero-padded), int_array_lengths[1] (AKA len_itoa_result) -
;; length of the string (w/o zero-padding), str_array_strings[1] (AKA str_ptr_to_itoa_result) - pointer to the start of
;; the string (w/o zero-padding)
;;
;; clobbers: rax, rdx, rdi, rsi, str_itoa_result, int_array_lengths[1], str_array_strings[1]
func_itoa:
        ; 1. perform conversion

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

        ; 2. determine the /actual/ length of the string (w/o any of the zero-padding)
        ;
        ; It'd be far easier to just precompute these offsets, but I think that's cheating. Like, at that point why not
        ; just do all the fizzbuzz stuff in the preprocessor and create a binary that's just one big ~write~ syscall and
        ; an array of text? Or heck, just a text file. No thank you. I'll limit myself to rep loops and symbol defines.

        mov rdx, 1              ; store if all previous bytes have been '0'
        mov rdi, str_itoa_result ; pointer to the start of the string
        mov rsi, ITOA_RESULT_BUFFER_SIZE ; length of the string

        ; iterate through ~str_itoa_result~, decrementing the length and incrementing the start pointer for every
        ; leading '0'.
%assign i 0
%rep NUM_DIGITS
        movzx rax, byte [str_itoa_result + i]
        call func_is_ascii_zero
        and rdx, rax
        add rdi, rdx
        sub rsi, rdx
%assign i i+1
%endrep

        ; store results into the relevant tables
        mov [str_ptr_to_itoa_result], rdi
        mov [len_itoa_result], rsi

        ret

;; Returns 1 if ~rax~ == '0', else 0
;;
;; arguments: rax -- number to compare against
;;
;; returns: rax -- (rax == '0') ? 1 : 0
;;
;; clobbers: rax
func_is_ascii_zero:
        dec rax                 ; '0' - 1 = 0b00101111, all other ASCII digits have bit 4 set
        and rax, 0b00010000     ; if rax was '0' rax is now 0b00000000, else 0b00010000
        xor rax, 0b00010000     ; toggle that bit
        shr rax, 4              ; 0b00010000 >> 4 == 1, 0b00000000 >> 4 == 0
        ret
