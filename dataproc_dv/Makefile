# ---------------------------------------------------------------------
# RISC-V Firmware Makefile
# ---------------------------------------------------------------------

# Toolchain prefix (adjust if needed)
CROSS   = riscv64-unknown-elf-
CC      = $(CROSS)gcc
OBJCOPY = $(CROSS)objcopy
OBJDUMP = $(CROSS)objdump

# Compiler flags (same as manual command)
CFLAGS  = -march=rv32im -mabi=ilp32 -ffreestanding -nostdlib \
          -Wl,-Bstatic,-T,sections.ld,--strip-debug

# Targets
all: firmware.hex firmware.asm
	@echo "-----------------------------------------------------------"
	@echo "SUCCESS: Firmware built."
	@echo "-----------------------------------------------------------"

# Link the ELF file
firmware.elf: start.S firmware.c sections.ld
	$(CC) $(CFLAGS) -o $@ start.S firmware.c

# Generate Verilog hex file (32‑bit words, one per line)
firmware.hex: firmware.elf
	$(OBJCOPY) -O verilog $< $@

# Generate disassembly for debugging
firmware.asm: firmware.elf
	$(OBJDUMP) -d $< > $@

clean:
	rm -f firmware.elf firmware.hex firmware.asm