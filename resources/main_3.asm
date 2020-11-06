;;  -----------------------------------------------------------------
;;  Return 3
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
        SECTION .data
;;  -----------------------------------------------------------------

loc_1   DB 0x3  ; Store 3 at an address called "loc_1"


;;  -----------------------------------------------------------------
        SECTION .text
;;  -----------------------------------------------------------------

main:
        mov rax, [loc_1] ; Return 3
        ret
.end:
