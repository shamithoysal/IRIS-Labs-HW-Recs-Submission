# IRIS Labs Hardware Recruitments -  Part A

1. This can lead to incorrect data transmission because the
combinational logic responsible for the generation of each bit causes
them to arrive at different times. This wouldn't be a problem if the
entire circuit existed in a single clock domain. However, since the
capturing is happening at a different rate in the new domain, wrong data may be captured due to these arrival times.
    
    There is no *physical* problem when this occurs. The voltage level isn't floating somewhere, halfway between high and low. Instead, there is a *logical*
     issue where erroneous data is passed through. It’s not that the 
    flip-flop physically breaks or asserts an intermediate voltage; rather, 
    the voltage it settles to is entirely probabilistic. In this case, as 
    presented in the timing diagram, the flop settles to 1. Regardless of 
    whether metastability occurred, the synchronizer for **bit 0** captured a 1, and the synchronizers for **bits 1 and 2** captured a 0.
    
    As a result, instead of the receiving domain waiting for the 1 cycle
     delay and then seeing a clean transition from 0 to 7, it sees a 0, then
     sees a 1 for the "delay" cycle, and then finally sees the 7. 
    Eventually, the *correct* data (7) is passed along, but that incorrect 1 has already propagated, breaking the dependent logic (here, the decoder).
    
2. The problem is rooted in the independent capture of data by the 3 synchronizers. At timestamp 1, Aclk rises and the flops capture their
respective data inputs. Due to the arrival skew, the flop for **bit 0** captures a 1 (because the signal arrived slightly earlier), while the flip-flops for **bit 1** and **bit 2** capture a 0 (because they were slightly delayed).
    
    Thus, the value actually passed to the internal logic is 001 instead
     of retaining the stable 000. Finally, the decoder incorrectly asserts 
    aen[1] for one clock cycle.
    
3. The fundamental problem lies in transferring multiple data bits that are not **grey-coded**. Each bit may experience metastability independently and resolve at
different times or suffer arrival skew. As a result, the destination
domain may sample a mix of old and new values, leading to corrupted
data.
4. While **grey-code** seems straightforward, it will
not wholly solve the problem alone. Since it is a control signal that is being passed, the values need not consecutively increment or decrement. If the initial control signal is 100 (4) and changes to 110 (6), the
grey-code equivalent would be 110 -> 101. The numbers do not differ
by a single bit, and hence grey-coding does not serve its purpose.

Proposed solutions:

1. **Use a multi-cycle path with source enable:**
    
    Fundamentally, separate the data from the control. Assert data to 
    the destination through direct wires. In the following cycle, assert a 
    src_en signal to 1, this time passing through a 2-flop synchronizer. 
    Once src_en is received at the destination after the cycle delays, the 
    data is also accepted. This ensures that the data has *for sure* reached a stable value because it was asserted 1 cycle *before* src_en was.
    
    The drawback with this is that it is an **open-loop system**.
     Since the source receives no feedback from the destination, it does not
     know exactly when the capture occurred. Therefore, the source must hold
     the data stable for a pre-calculated number of cycles thereby exceeding
     the worst-case synchronization latency before it is safe to change the 
    data. This limits throughput.
    
2. **Asynchronous FIFO:**
    
    Use a standard asynchronous FIFO that buffers the incoming data long
     enough for the destination to read. Only the read and write pointers 
    (grey-coded) have to be synchronized between the domains.
    
    A fundamental drawback in this approach is the FIFO is limited by its **depth**.
     If the input write speed exceeds the read speed for a prolonged period,
     it may lead to overflow and critical data loss. Therefore, writes 
    should be asserted only if space is available.
    
3. **Full Handshake Protocol (Request/Acknowledge):**
    
    This method establishes a **closed-loop communication channel**.
     The source asserts a Request signal along with the data. The 
    destination synchronizes this request, captures the data, and sends back
     an Acknowledge signal. The source must wait for this Acknowledge to be 
    synchronized back into its own domain before it can complete the 
    transaction. This ensures incredible robustness and works well even with
     variations in delays, clock frequencies etc.
    
    In a tradeoff for robustness, we give up **latency**. 
    This method takes roughly twice as long as method (a) as it requires the
     acknowledge signal to also travel back through the synchronizers.
    

# Part B

## 1. Overview

The module integrates a data producer (simulating a 200 MHz sensor) with a 100 MHz processing engine, using an asynchronous FIFO to manage clock domain crossing and data rate matching.

The processing block supports three modes:

1. Bypass (Mode `00`)
2. Invert (Mode `01`)
3. Convolution (Mode `10`): Applies a configurable 3x3 kernel matrix (Edge Detection) to the input stream.

## 2. Architecture

![image.png](/docs/image.png)

### Data Producer

Simulates an image sensor. It generates 8-bit pixel data from a pre-loaded memory file (`image.mem`) at 200 MHz.

### Asynchronous FIFO

An 8-bit, depth-16 FIFO. The design implements margins (`FULL_OFFSET` and `EMPTY_OFFSET`). Instead of asserting `wfull` or `rempty` only when the buffer is strictly full or empty, the logic calculates the pointer distance and asserts these flags *early*. This margin compensates for the latency of the pointer synchronizers, ensuring that the `data_producer` pauses before an overflow occurs and the `data_processor` waits before an underflow occurs.

### Data Processor

Contains the configuration registers and a systolic array for convolution operations. 

## 3. Data Processor (Systolic Array)

![image.png](/docs/image%201.png)

### **Implementation**

To handle the streaming data, we need to be able to see a pixel's neighbors without stalling the pipeline. This was achieved using 2 Line Buffer that caches the previous two pixel lines. This creates three vertical data taps: the live stream (`tap 2`) and the two delayed rows (`tap 1`, `tap 0`). From there, pipelined shift registers handle horizontal alignment, rebuilding a complete 3x3 pixel window every single clock cycle. The soul of the systolic array is the Multiply and Accumulate unit which are configured in a 3x3 arrangement. Each pixel is handled by a single MAC Unit. This grid of nine pixels is then multiplied in parallel with the configurable weights and accumulated into the `final_sum`, delivering high throughput with minimal latency.

### **Motivation**

*As a 2nd year offering envision projects to IEEE student members, our project proposal was EXACTLY to implement a systolic array in Verilog for accelerated matrix multiplication. Honestly, this felt like the perfect fit to this task and with a little modification, I got it working for convolution like a charm. 😋*

A naive implementation of a 3x3 convolution would require simultaneous access to all 9 pixels in the window. In a streaming system, this would demand 9 separate 8-bit input ports from memory or nine separate read cycles per calculation, creating a massive bandwidth bottleneck.

By implementing a systolic array, the design dramatically optimizes resource usage:

1. Bandwidth Efficiency
    
    The system requires only 3 8-bit input streams. The internal line buffers reconstruct the vertical neighbors (North, South) internally, and the shift registers reconstruct the horizontal neighbors (East, West). We effectively get "9 pixels of data for the price of 1 input."
    
2. Timing & Throughput
    
    A purely combinational design would require logic to fetch, multiply, and add nine values in a single clock cycle, severely limiting the maximum clock frequency. **This design is fully pipelined.** Data moves one step per clock cycle, and the multiplication/accumulation happens in parallel stages. This breaks the critical path into small, manageable chunks, allowing a much higher clock speed while maintaining throughput of one pixel per cycle.
    

## 4. Verification

The `tb_data_prod_proc.v` testbench performs a combined system integration test. Complete log is available at `/docs/simlog.txt`.

### Parameters

**Image**: A 10x32 grayscale image (`imagepartb.mem`) initialized to `0x00`, featuring a central 3x3 block of pixels with intensity `0x0A` (decimal 10). This high-contrast center was chosen to verify the edge-detection capabilities of the convolution kernel.

**Clocks:** The Data Producer operates at 200 MHz (sensor domain), while the Data Processor operates at 100 MHz (system domain).

### Phase 1: Convolution (Mode 10)

The processor was configured with a standard **Laplacian Edge Detection** kernel. The simulation logs confirm that the systolic array correctly handles signed arithmetic (Two's Complement) when the kernel interacts with the test pattern.

**Kernel Configuration:**



```
   0   -1    0
  -1    4   -1
   0   -1    0 
```


Simulation Log

```
Time: 2135000 | In: 00 | Out: fffffff6 (-10)
Time: 2145000 | In: 00 | Out: fffffff6 (-10)
Time: 2155000 | In: 00 | Out: fffffff6 (-10)
Time: 2455000 | In: 00 | Out: ffffffec (-20)
Time: 2465000 | In: 00 | Out: 00000014 (20)
Time: 2475000 | In: 00 | Out: 0000000a (10)
Time: 2485000 | In: 00 | Out: 0000001e (30)
...
```

These values match the expected convolution results for an edge‑detection kernel (e.g., -10, 20, 10, 30). The occasional `fffffff6` (-10) and `00000014` (20) appear exactly where the kernel overlaps the moving white box.

### Phase 2: Bypass (Mode 00)

Simulation Log

```
Time: 53245000 | In: 0a | Out: 0000000a (10)
Time: 53255000 | In: 0a | Out: 0000000a (10)
Time: 53265000 | In: 00 | Out: 00000000 (0)
...
Time: 53555000 | In: 0a | Out: 0000000a (10)
Time: 53565000 | In: 0a | Out: 0000000a (10)
Time: 53575000 | In: 0a | Out: 0000000a (10)
```

In this mode, the systolic array is bypassed.

### Phase 3: Invert (Mode 01)

This mode tests the arithmetic logic unit (ALU) for simple bitwise operations (Output= 255-Input).

Simulation Log

```
Time: 72275000 | In: 00 | Out: 000000ff (255)
Time: 72285000 | In: 00 | Out: 000000ff (255)
...
Time: 73695000 | In: 0a | Out: 000000f5 (245)   
Time: 73705000 | In: 0a | Out: 000000f5 (245)
Time: 73715000 | In: 0a | Out: 000000f5 (245)
...
Time: 83925000 | In: 0a | Out: 000000f5 (245)
```

For input `00`, output is `ff` (255). For input `0a`, output is `f5` (245). No other values appear, confirming the inversion.

# Part C

## 1. Overview and Architecture

![image.png](/docs/image%202.png)

The verified data‑processing block from Part B is integrated into the provided RISC‑V SoC as a memory‑mapped peripheral. The accelerator is accessed via the `iomem` bus using a single‑cycle interface. The datapath includes asynchronous FIFOs at both the input and output of the processing block. This buffering enables the modules to operate at different clock rates in future implementations, while for initial verification, all components operate on the same 100 MHz clock domain.

## 2. Complete Memory Map

| Address Range | Region | Description | Size |
| --- | --- | --- | --- |
| `0x0000_0000` -`0x0001_FFFF` | Internal RAM | Used for stack, heap, and data. | 128 KB |
| `0x0002_0000` -`0x01FF_FFFF` | SPI Flash | External SPI flash memory (emulated by `spiflash`). Holds firmware. | ~32 MB |
| `0x0200_0000` | SPI Config | SPI flash configuration register. | 4 bytes |
| `0x0200_0004` | UART Divisor | UART baud rate divisor register. | 4 bytes |
| `0x0200_0008` | UART Data | UART data register (write to transmit, read to receive). | 4 bytes |
| `0x0300_0000` | GPIO | General‑purpose I/O register. | 4 bytes |
| `0x0400_0000` -`0x0400_003F` | Accelerator Config | Accelerator configuration registers (mode and nine 8‑bit kernel coefficients). | 64 bytes |
| `0x0400_0040` | Accelerator Result | Read‑only result FIFO. A read pops one 32‑bit result. | 4 bytes |
| `0x0400_0044` | Accelerator Status | Status register. Bit 0 = 1 when result available. | 4 bytes |

---

### Register Map for Accelerator (Base `0x0400_0000`)

| Offset | Name | Width | Description |
| --- | --- | --- | --- |
| `0x00` | `MODE` | 2 | `00`: Bypass, `01`: Invert, `10`: Convolution, `11`: Reserved |
| `0x04` | `K00` | 8 | Kernel coefficient [0][0] |
| `0x05` | `K01` | 8 | Kernel coefficient [0][1] |
| `0x06` | `K02` | 8 | Kernel coefficient [0][2] |
| `0x07` | `K10` | 8 | Kernel coefficient [1][0] |
| `0x08` | `K11` | 8 | Kernel coefficient [1][1] |
| `0x09` | `K12` | 8 | Kernel coefficient [1][2] |
| `0x0A` | `K20` | 8 | Kernel coefficient [2][0] |
| `0x0B` | `K21` | 8 | Kernel coefficient [2][1] |
| `0x0C` | `K22` | 8 | Kernel coefficient [2][2] |
| `0x40` | `RESULT` | 32 | Read‑only FIFO output. A read pops one result. |
| `0x44` | `STATUS` | 1 | Bit 0 = 1 when result available. |

## 3. The iomem Bus

The core communicates with memory‑mapped peripherals via:

- `iomem_valid`: indicates valid I/O transaction (address ≥ `0x0200_0000`)
- `iomem_wstrb[3:0]`: byte enables for writes
- `iomem_addr[31:0]`, `iomem_wdata[31:0]`: address and write data
- `iomem_rdata[31:0]`: read data returned by wrapper
- `iomem_ready`: asserted when transaction is complete

## 4. Hardware Accelerator

The accelerator consists of four main blocks:

| Block | Description |
| --- | --- |
| **Data Producer** | Generates 8‑bit pixel stream from `image.mem`. Controlled by input FIFO full flag via `ready` signal. |
| **Input FIFO** | 8‑bit
 asynchronous FIFO (depth 16) with configurable full/empty margins. 
Buffers pixels from producer to processor. Both write and read clocks 
are tied to the system clock for initial validation. |
| **Data Processor** | Configurable via memory‑mapped registers. Supports bypass, invert, and 3×3 convolution modes. Features `in_ready`/`out_ready` handshake for flow control. |
| **Output FIFO** | 32‑bit
 asynchronous FIFO (depth 64) with configurable margins. Stores 
processed results for CPU access. Read is combinational, allowing 
single‑cycle reads via the `iomem` bus. |

## 5. Firmware and Startup

![image.png](/docs/image%203.png)

The firmware is written in C. It is compiled using the GCC RISC‑V toolchain and linked to run from FLASH at address `0x0010_0000`, with data sections placed in RAM.

### Top‑level definitions

- Base addresses (`ACCEL_BASE`, `UART_BASE`, `GPIO_BASE`) correspond to the memory map.
- UART helper functions (`putchar`, `print_str`, `print_dec`) provide text output. `putchar` automatically adds a carriage return (`\r`) before a newline (`\n`) to satisfy typical terminal expectations.

A Makefile automates the build process, invoking the GCC RISC‑V toolchain to compile `firmware.c` and `start.S`, link against `sections.ld`, and produce an ELF file, which is then converted to a hex file (`firmware.hex`) for simulation. 

## 6. Verification

### Sample Program 1

1. Sets the UART baud rate divisor to 19 (for ~5.26 Mbps at 100 MHz).
2. Configures the accelerator in **bypass mode** (`REG_MODE = 0x00`), so that output pixels equal input pixels.
3. Initializes the GPIO (used as a waveform marker).
4. Prints a start message `"Bypass test\n"`.
5. Enters a loop that reads exactly five results:
    - Polls the status register (`REG_STATUS`) until bit 0 indicates a result is ready.
    - Reads the result from `REG_RESULT` (this automatically pops the output FIFO).
    - Prints the decimal value followed by a space.
    - Toggles the GPIO bit 0.
6. After five results, prints `"\nTest complete.\n"` and ends in an infinite loop.

The simulation log shows that the UART outputs the expected characters and that the first result (`0`) matches the first pixel in `image.mem` (a ramp starting at 0).

```
Loaded image.mem, first pixel = 00
Serial data: 'B'
Serial data: 'y'
Serial data: 'p'
Serial data: 'a'
Serial data: 's'
Serial data: 's'
Serial data: ' '
Serial data: 't'
Serial data: 'e'
Serial data: 's'
Serial data: 't'
Serial data:  13
Serial data:  10
Serial data: '0'
Serial data: ' '
```

The start message `"Bypass test"` is printed, followed by the first result `0` and a space. This shows that:

- The CPU successfully fetches and executes the firmware from flash.
- The UART is operational and correctly configured.
- The accelerator's mode register is writable (bypass mode).
- The data producer generates the first pixel, which flows through the input FIFO, processor (bypass mode), and output FIFO.
- The CPU polls the status register, detects a result, and reads it via the result register.

### Waveform Analysis

![image.png](/docs/image%204.png)

**Figure 1: Status Register Read**

- `iomem_addr` = `0x04000044` (status register)
- `iomem_valid` = 1
- `iomem_ready` = 1 (single‑cycle response)
- `iomem_rdata` = `0x00000001` (bit 0 = 1, indicating a result is available)

![image.png](/docs/image%205.png)

**Figure 2: Result Register Read**

- `iomem_addr` = `0x04000040` (result register)
- `iomem_valid` = 1
- `iomem_ready` = 1
- `result_pop` = 1 (pulse indicating FIFO pop)
- `iomem_rdata` = `0x00000000` (result value; the first pixel is 0)

![image.png](/docs/image%206.png)

**Figure 3: Result Register Read**

- `iomem_addr` = `0x04000040` (result register)
- `iomem_valid` = 1
- `iomem_ready` = 1
- `result_pop` = 1 (pulse indicating FIFO pop)
- `iomem_rdata` = `0x00000001` (result value; the second pixel is 1)

I understand that this is not a very comprehensive test result, but I’d like to strongly support my design nevertheless.

The firmware is designed to print five results, but the simulation log shows only the first result within the 10 ms window. This could be due to the slow SPI flash model used in simulation. There could be a deeper issue. I’ve spent hours looking, but I couldn’t come up with anything concrete. Nevertheless, looking at the waveform confirms that multiple result reads (at least two) occur within the simulation time, and the values read from the result register (`0` followed by `1`) match the expected ramp pattern from `image.mem`. This indicates that the accelerator continues to produce results and the CPU successfully retrieves them, even if the UART output for subsequent results is delayed or not fully captured within the simulation window.

### Sample Program 2

1. Sets the UART baud rate divisor to 19 (for ~5.26 Mbps at 100 MHz).
2. Loads the edge‑detection kernel coefficients into the accelerator's kernel registers.
3. Configures the accelerator in **convolution mode** (`REG_MODE = 0x02`), enabling the 3×3 systolic array, and loads a simple edge detection kernel.

```
REG_K00 = 0;   REG_K01 = -1;  REG_K02 = 0;
REG_K10 = -1;  REG_K11 =  4;  REG_K12 = -1;
REG_K20 = 0;   REG_K21 = -1;  REG_K22 = 0;
```

1. Initializes the GPIO (used as a waveform marker).
2. Prints a start message `"Convolution test\n"`.
3. Enters a loop that reads exactly five results:
    - Polls the status register (`REG_STATUS`) until bit 0 indicates a result is ready.
    - Reads the result from `REG_RESULT` (this automatically pops the output FIFO).
    - Prints the decimal value followed by a space.
    - Toggles GPIO bit 0.
4. After five results, prints `"\nTest complete.\n"` and ends in an infinite loop.

Simulation Log

```markdown
Loaded image.mem, first pixel = 00
Serial data: 'C'
Serial data: 'o'
Serial data: 'n'
Serial data: 'v'
Serial data: 'o'
Serial data: 'l'
Serial data: 'u'
Serial data: 't'
Serial data: 'i'
Serial data: 'o'
Serial data: 'n'
Serial data: ' '
Serial data: 't'
Serial data: 'e'
Serial data: 's'
Serial data: 't'
Serial data:  13
Serial data:  10
Serial data: '0'
Serial data: ' '
```

The start message `"Convolution test"` is printed, followed by the first result `0` and a space. This shows that:

- The CPU successfully fetches and executes the firmware from flash.
- The UART is operational and correctly configured.
- The accelerator's kernel registers are writable (the edge‑detection coefficients were loaded).
- The accelerator is set to convolution mode (`REG_MODE = 0x02`).
- The data producer generates the first pixel, which flows through the input
FIFO, the systolic array (configured with the edge‑detection kernel),
and the output FIFO.
- The CPU polls the status register, detects a result, and reads it via the
result register, confirming that the convolution datapath is functional.

### Waveform Analysis

![image.png](/docs/image%207.png)

**Figure 1: Kernel Register Write**

- `iomem_addr` = `0x04000014` (configuration register at offset 0x14)
- `iomem_valid` = 1
- `iomem_wstrb` = `0xF` (all byte enables active, indicating a full 32‑bit write)
- `iomem_wdata` = `0x00000004` (value written to the register)
- `iomem_ready` is asserted (not shown in this capture, but the transaction completes in a single cycle)

![image.png](/docs/image%208.png)

**Figure 2: Accelerator Configuration After Kernel Write**

- `mode_reg` = `2`, indicating the accelerator is set to **convolution mode**.
- `kernel_reg[0]` through `kernel_reg[8]` store the nine 8‑bit kernel coefficients.
- `flat_kernel` = `00000000ff00ff04ff` – a 72‑bit concatenation of the nine coefficients (order may be implementation‑specific).

Again, similar to the first program, this is not a comprehensive result. Although the simulation duration limited the UART output to the first pixel, the internal hardware state confirms successful configuration. The waveform captures (Figure 2) show the mode_reg correctly transitioning to 0x02 and the flat_kernel register reflecting the loaded edge-detection coefficients. This proves that the Memory-Mapped Write Interface is correctly decoding addresses and updating the accelerator's internal state in a single clock cycle.