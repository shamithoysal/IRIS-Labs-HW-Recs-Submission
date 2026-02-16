.section .text
.globl _start
.type _start, @function

_start:
    # Set stack pointer to the top of RAM (0x20000)
    li sp, 0x20000

    # Copy .data from flash (source) to RAM (destination)
    la a0, _sidata          # source address in flash
    la a1, _sdata           # destination address in RAM
    la a2, _edata           # end of .data in RAM
    bge a1, a2, 2f          # skip if no data
1:
    lw t0, 0(a0)
    sw t0, 0(a1)
    addi a0, a0, 4
    addi a1, a1, 4
    blt a1, a2, 1b
2:

    # Zero .bss
    la a0, _sbss
    la a1, _ebss
    bge a0, a1, 4f
3:
    sw zero, 0(a0)
    addi a0, a0, 4
    blt a0, a1, 3b
4:

    # Call main
    call main

    # If main returns, loop forever
    j .