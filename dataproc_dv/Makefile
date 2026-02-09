# ---------------------------------------------------------------------
# RISC-V Firmware Builder (Final Corrected)
# ---------------------------------------------------------------------

CROSS   = riscv64-unknown-elf-
CC      = $(CROSS)gcc
OBJCOPY = $(CROSS)objcopy
OBJDUMP = $(CROSS)objdump

# FORCE rv32im (No 'c') to prevent alignment traps
CFLAGS  = -march=rv32im -mabi=ilp32 -Wl,-Bstatic,-T,sections.ld,--strip-debug -ffreestanding -nostdlib

all: firmware.hex
	@echo "-----------------------------------------------------------"
	@echo "SUCCESS: Firmware Built."
	@echo "-----------------------------------------------------------"

firmware.elf: start.s firmware.c sections.ld
	$(CC) $(CFLAGS) -o $@ start.s firmware.c

# 1. Extract Raw Binary (Contains bytes 37 41 00 00)
firmware.bin: firmware.elf
	$(OBJCOPY) -O binary $< $@

# 2. Python flips them to 00004137
firmware.hex: firmware.bin
	python makehex.py $< $@

dump: firmware.elf
	$(OBJDUMP) -d firmware.elf > firmware.asm

clean:
	rm -f firmware.elf firmware.hex firmware.bin firmware.asm