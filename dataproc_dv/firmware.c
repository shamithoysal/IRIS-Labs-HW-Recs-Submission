#include <stdint.h>

#define ACCEL_BASE      0x04000000
#define UART_BASE       0x02000000
#define GPIO_BASE       0x03000000

#define REG_UART_DIV    (*(volatile uint32_t*)(UART_BASE + 0x04))
#define REG_UART_DATA   (*(volatile uint32_t*)(UART_BASE + 0x08))

#define REG_MODE        (*(volatile uint32_t*)(ACCEL_BASE + 0x00))
#define REG_RESULT      (*(volatile int32_t*)(ACCEL_BASE + 0x40))
#define REG_STATUS      (*(volatile uint32_t*)(ACCEL_BASE + 0x44))

#define GPIO_OUT        (*(volatile uint32_t*)(GPIO_BASE))

void putchar(char c) {
    if (c == '\n') putchar('\r');
    REG_UART_DATA = c;
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
    REG_MODE = 0x00;             // bypass mode

    GPIO_OUT = 0;                // initialise GPIO

    putchar('R'); putchar('e'); putchar('a'); putchar('d'); putchar('y'); putchar('\n');

    while (1) {
        while ((REG_STATUS & 1) == 0);   // wait for result
        int32_t res = REG_RESULT;
        print_dec(res);
        putchar(' ');
        GPIO_OUT ^= 1;                    // toggle GPIO bit 0
    }
}