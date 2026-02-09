#include <stdint.h>
#include <stdbool.h>

// =========================================================
//  SYSTEM MEMORY MAP
// =========================================================
#define ACCEL_BASE 0x03000000
#define UART_BASE  0x02000000

// UART Registers
#define REG_UART_CLKDIV (*(volatile uint32_t*)(UART_BASE + 0x04))
#define REG_UART_DATA   (*(volatile uint32_t*)(UART_BASE + 0x08))

// Accelerator Configuration (Read/Write)
#define REG_MODE (*(volatile uint32_t*)(ACCEL_BASE + 0x00))

// Accelerator Weights (Read/Write)
#define REG_K00  (*(volatile int32_t*)(ACCEL_BASE + 0x04))
#define REG_K01  (*(volatile int32_t*)(ACCEL_BASE + 0x08))
#define REG_K02  (*(volatile int32_t*)(ACCEL_BASE + 0x0C))

#define REG_K10  (*(volatile int32_t*)(ACCEL_BASE + 0x10))
#define REG_K11  (*(volatile int32_t*)(ACCEL_BASE + 0x14))
#define REG_K12  (*(volatile int32_t*)(ACCEL_BASE + 0x18))

#define REG_K20  (*(volatile int32_t*)(ACCEL_BASE + 0x1C))
#define REG_K21  (*(volatile int32_t*)(ACCEL_BASE + 0x20))
#define REG_K22  (*(volatile int32_t*)(ACCEL_BASE + 0x24))

// Accelerator Status & Result (Read Only)
// Status Bit 0: 1 = Data Available
#define REG_STATUS (*(volatile uint32_t*)(ACCEL_BASE + 0x28))
// Reading this address POPS the FIFO!
#define REG_RESULT (*(volatile int32_t*)(ACCEL_BASE + 0x2C))

// =========================================================
//  HELPER FUNCTIONS
// =========================================================
void putchar(char c);
void print(const char *p);
void print_dec(int val);
void delay(int cycles);

// =========================================================
//  MAIN APPLICATION
// =========================================================
void main() {
    // 1. Setup UART (104 is standard for 9600 baud @ 1MHz clock)
    REG_UART_CLKDIV = 104;
    
    print("\n\n");
    print("================================\n");
    print("   RISC-V ACCELERATOR STARTup   \n");
    print("================================\n");

    // 2. Configure Accelerator Mode
    // 0 = Bypass, 1 = Invert, 2 = Convolution
    print("Configuring Mode: Convolution (2)...\n");
    REG_MODE = 2;

    // 3. Load Edge Detection Kernel
    // This kernel highlights boundaries between light and dark areas.
    // [ -1  -1  -1 ]
    // [ -1   8  -1 ]
    // [ -1  -1  -1 ]
    print("Loading Kernel Weights...\n");
    
    REG_K00 = -1; REG_K01 = -1; REG_K02 = -1;
    REG_K10 = -1; REG_K11 =  8; REG_K12 = -1;
    REG_K20 = -1; REG_K21 = -1; REG_K22 = -1;

    print("Setup Complete. Entering Processing Loop.\n");

    int count = 0;
    while (1) {
        // 4. POLL STATUS: Wait for Data
        // We spin here until Bit 0 of Status Register becomes 1
        while ((REG_STATUS & 1) == 0);

        // 5. READ & POP: Get the Result
        int32_t result = REG_RESULT;

        // 6. Print Output
        print("Pixel[");
        print_dec(count++);
        print("]: ");
        print_dec(result);
        print("\n");

        // Slow down so we can read the log
        delay(5000);
    }
}

// =========================================================
//  IMPLEMENTATIONS
// =========================================================
void putchar(char c) {
    if (c == '\n') putchar('\r');
    REG_UART_DATA = c;
}

void print(const char *p) {
    while (*p) putchar(*(p++));
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

void delay(int cycles) {
    for (int i = 0; i < cycles; i++) asm volatile("nop");
}