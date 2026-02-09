.section .text
.global _start

_start:
    # 1. Initialize Stack Pointer (Top of 16KB RAM)
    li sp, 0x4000
    j call_main
    # 2. Copy .data section from Flash to RAM
    # Linker symbols: 
    # _etext = End of Code (Start of Data in Flash)
    # _sdata = Start of Data in RAM
    # _edata = End of Data in RAM

    la a0, _etext   # Source (Flash)
    la a1, _sdata   # Destination (RAM)
    la a2, _edata   # End (RAM)

copy_loop:
    bge a1, a2, zero_bss    # If Dest == End, we are done
    lw t0, 0(a0)            # Load word from Flash
    sw t0, 0(a1)            # Store word to RAM
    addi a0, a0, 4          # Increment Flash pointer
    addi a1, a1, 4          # Increment RAM pointer
    j copy_loop

zero_bss:
    # 3. Clear .bss section (Zero out uninitialized vars)
    la a0, _sbss
    la a1, _ebss

zero_loop:
    bge a0, a1, call_main
    sw zero, 0(a0)
    addi a0, a0, 4
    j zero_loop

call_main:
    # 4. Jump to C
    call main

loop:
    j loop