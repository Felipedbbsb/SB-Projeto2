# Makefile at SB-Projeto2 (root)

CC       = gcc
CFLAGS   = -m32 -Wall -fno-pie
LDFLAGS  = -m32 -no-pie

PROGRAM = carregador

# Folders
C_DIR   = Carregador
ASM_DIR = Assembly

# Sources
CSRC    = $(C_DIR)/carregador.c
ASMSRC  = $(ASM_DIR)/allocator.asm $(ASM_DIR)/printer.asm

# Object files
COBJ    = $(CSRC:.c=.o)
ASMOBJ  = $(ASMSRC:.asm=.o)
OBJS    = $(COBJ) $(ASMOBJ)

all: $(PROGRAM)

$(PROGRAM): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJS)

# Compile C sources
$(C_DIR)/%.o: $(C_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

# Assemble NASM sources
$(ASM_DIR)/%.o: $(ASM_DIR)/%.asm
	nasm -f elf32 $< -o $@

clean:
	rm -f $(PROGRAM) $(C_DIR)/*.o $(ASM_DIR)/*.o
