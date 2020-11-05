PROG_1 = main_1
SRC_1 = main_1.asm
PROG_2 = main_2
SRC_2 = main_2.asm


#####################################################
# DEFAULT
#####################################################

.DEFAULT_GOAL = all
all: clean build


#####################################################
# BUILD
#####################################################

build: $(PROG_1) $(PROG_2)

$(PROG_1): $(SRC_1)
	nasm -f elf64 -o $(PROG_1).o $(SRC_1)
	gcc -o $(PROG_1) $(PROG_1).o
	rm -rf $(PROG_1).o

$(PROG_2): $(SRC_2)
	nasm -f elf64 -o $(PROG_2).o $(SRC_2)
	gcc -o $(PROG_2) $(PROG_2).o
	rm -rf $(PROG_2).o

#####################################################
# CLEAN
#####################################################

.PHONY: clean
clean:
	rm -rf $(PROG_1).o $(PROG_2).o
	rm -rf $(PROG_1) $(PROG_2)
