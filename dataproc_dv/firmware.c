#include <stdint.h>

// Base addresses
#define ACCEL_BASE      0x04000000
#define UART_BASE       0x02000000
#define GPIO_BASE       0x03000000

// UART registers
#define REG_UART_DIV    (*(volatile uint32_t*)(UART_BASE + 0x04))
#define REG_UART_DATA   (*(volatile uint32_t*)(UART_BASE + 0x08))

// Accelerator registers
#define REG_MODE        (*(volatile uint32_t*)(ACCEL_BASE + 0x00))
#define REG_K00         (*(volatile int32_t*)(ACCEL_BASE + 0x04))
#define REG_K01         (*(volatile int32_t*)(ACCEL_BASE + 0x08))
#define REG_K02         (*(volatile int32_t*)(ACCEL_BASE + 0x0C))
#define REG_K10         (*(volatile int32_t*)(ACCEL_BASE + 0x10))
#define REG_K11         (*(volatile int32_t*)(ACCEL_BASE + 0x14))
#define REG_K12         (*(volatile int32_t*)(ACCEL_BASE + 0x18))
#define REG_K20         (*(volatile int32_t*)(ACCEL_BASE + 0x1C))
#define REG_K21         (*(volatile int32_t*)(ACCEL_BASE + 0x20))
#define REG_K22         (*(volatile int32_t*)(ACCEL_BASE + 0x24))
#define REG_RESULT      (*(volatile int32_t*)(ACCEL_BASE + 0x40))
#define REG_STATUS      (*(volatile uint32_t*)(ACCEL_BASE + 0x44))

// GPIO
#define GPIO_OUT        (*(volatile uint32_t*)(GPIO_BASE))

void putchar(char c) {
    if (c == '\n') putchar('\r');
    REG_UART_DATA = c;
}

void print_str(const char *s) {
    while (*s) putchar(*s++);
}

void print_dec(int32_t val) {
    char buf[12];
    int i = 0;
    if (val == 0) { putchar('0'); return; }
    if (val < 0) { putchar('-'); val = -val; }
    while (val) {
        buf[i++] = (val % 10) + '0';
        val /= 10;
    }
    while (--i >= 0) putchar(buf[i]);
}

void main() {
    
    REG_UART_DIV = 19;          // 5.26 Mbps

    // Edge‑detection kernel
    REG_K00 = 0;   REG_K01 = -1;  REG_K02 = 0;
    REG_K10 = -1;  REG_K11 =  4;  REG_K12 = -1;
    REG_K20 = 0;   REG_K21 = -1;  REG_K22 = 0;

    // Convolution mode
    REG_MODE = 0x02;            

    GPIO_OUT = 0;

    print_str("Convolution test\n");

    // Read and print 5 results
    for (int i = 0; i < 5; i++) {
        while ((REG_STATUS & 1) == 0);   // wait for result
        int32_t res = REG_RESULT;         // read and pop
        print_dec(res);
        putchar(' ');
        GPIO_OUT ^= 1;                     // toggle GPIO
    }

    print_str("\nTest complete.\n");
    while (1);
}