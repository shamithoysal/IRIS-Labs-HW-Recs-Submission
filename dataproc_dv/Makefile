CROSS   = riscv64-unknown-elf-
CC      = $(CROSS)gcc
OBJCOPY = $(CROSS)objcopy
OBJDUMP = $(CROSS)objdump


CFLAGS  = -march=rv32im -mabi=ilp32 -ffreestanding -nostdlib \
          -Wl,-Bstatic,-T,sections.ld,--strip-debug


all: firmware.hex firmware.asm
	@echo "SUCCESS!"



firmware.elf: start.S firmware.c sections.ld
	$(CC) $(CFLAGS) -o $@ start.S firmware.c


firmware.hex: firmware.elf
	$(OBJCOPY) -O verilog $< $@


firmware.asm: firmware.elf
	$(OBJDUMP) -d $< > $@

clean:
	rm -f firmware.elf firmware.hex firmware.asm