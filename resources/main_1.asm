;;  -----------------------------------------------------------------
;;  Return 5
;;
;;  To compile this:
;;
;;      nasm -f elf64 -o main.o main.asm
;;      gcc -o main main.o
;;
;;  To run it:
;;
;;      ./main
;;
;;  -----------------------------------------------------------------

;;  Expose the following functions (include size for ELF symbol table):

        global main:function (main.end - main)

;;  -----------------------------------------------------------------
        SECTION .text
;;  -----------------------------------------------------------------

main:
        mov     rax, 0x5 ; Return 5
        ret
.end:
