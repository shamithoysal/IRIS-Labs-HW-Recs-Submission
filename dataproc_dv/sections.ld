MEMORY
{
    /* One unified block of RAM. Starts at 0. Size 16KB. */
    MEM (rwx) : ORIGIN = 0x00000000, LENGTH = 0x4000
}

SECTIONS
{
    /* 1. Code (.text) goes at the very beginning (Address 0) */
    .text :
    {
        . = ALIGN(4);
        *(.text)           /* Instructions */
        *(.text*)
        *(.rodata)         /* Read-only data (Strings) */
        *(.rodata*)
        *(.srodata)
        *(.srodata*)
        . = ALIGN(4);
        _etext = .;        /* Symbol: End of Text */
    } > MEM

    /* 2. Initialized Data (.data) follows immediately */
    .data :
    {
        . = ALIGN(4);
        _sdata = .;        /* Symbol: Start of Data */
        *(.data)
        *(.data*)
        *(.sdata)
        *(.sdata*)
        . = ALIGN(4);
        _edata = .;        /* Symbol: End of Data */
    } > MEM

    /* 3. Uninitialized Data (.bss) follows Data */
    .bss :
    {
        . = ALIGN(4);
        _sbss = .;         /* Symbol: Start of BSS */
        *(.bss)
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;         /* Symbol: End of BSS */
    } > MEM
}