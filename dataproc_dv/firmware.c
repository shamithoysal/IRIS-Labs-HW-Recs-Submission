#include <stdint.h>
#include <stdbool.h>

#define ACCEL_BASE 0x03000000
#define UART_BASE  0x02000000

#define REG_UART_CLKDIV (*(volatile uint32_t*)(UART_BASE + 0x04))
#define REG_UART_DATA   (*(volatile uint32_t*)(UART_BASE + 0x08))
#define REG_MODE (*(volatile uint32_t*)(ACCEL_BASE + 0x00))

#define REG_K00  (*(volatile int32_t*)(ACCEL_BASE + 0x04))
#define REG_K01  (*(volatile int32_t*)(ACCEL_BASE + 0x08))
#define REG_K02  (*(volatile int32_t*)(ACCEL_BASE + 0x0C))
#define REG_K10  (*(volatile int32_t*)(ACCEL_BASE + 0x10))
#define REG_K11  (*(volatile int32_t*)(ACCEL_BASE + 0x14))
#define REG_K12  (*(volatile int32_t*)(ACCEL_BASE + 0x18))
#define REG_K20  (*(volatile int32_t*)(ACCEL_BASE + 0x1C))
#define REG_K21  (*(volatile int32_t*)(ACCEL_BASE + 0x20))
#define REG_K22  (*(volatile int32_t*)(ACCEL_BASE + 0x24))

#define REG_STATUS (*(volatile uint32_t*)(ACCEL_BASE + 0x44))
#define REG_RESULT (*(volatile int32_t*)(ACCEL_BASE + 0x40))

void putchar(char c) {
    if (c == '\n') putchar('\r');
    REG_UART_DATA = c;
}

void print_dec(int val) {
    char buffer[12];
    int i = 0;
    if (val == 0) { putchar('0'); return; }
    if (val < 0) { putchar('-'); val = -val; }
    while (val > 0) {
        buffer[i++] = (val % 10) + '0';
        val /= 10;
    }
    while (--i >= 0) putchar(buffer[i]);
}

void main() {
    // 1. REVERT TO 104 (Sync with Testbench)
    REG_UART_CLKDIV = 19; 

    putchar('A');
    putchar('\n');

    uint32_t val = REG_MODE;
    print_dec(val);
    putchar('\n');
    
    // 2. Load Weights (These were failing before due to the Ghost File!)
    REG_K00 = -1; REG_K01 = -1; REG_K02 = -1;
    REG_K10 = -1; REG_K11 =  8; REG_K12 = -1;
    REG_K20 = -1; REG_K21 = -1; REG_K22 = -1;

    // Enable
    REG_MODE = 0x82;

    // 4. Processing Loop
    while (1) {
        while ((REG_STATUS & 1) == 0);
        int32_t result = REG_RESULT;
        print_dec(result);
        putchar('\n'); 
    }
}