# IRIS Labs Hardware Recruitments - 2026


# Answers to Part A
 
1. This can lead to incorrect data transmission because the combinational logic responsible for the generation of each bit causes them to arrive at different times. This wouldn't be a problem if the entire circuit existed in a single clock domain. However, since the capturing is happening at a different rate in the new domain, wrong data may be captured due to these arrival times.

There is no *physical* problem when this occurs. The voltage level isn't floating somewhere, halfway between high and low. Instead, there is a *logical* issue where erroneous data is passed through. It’s not that the flip-flop physically breaks or asserts an intermediate voltage; rather, the voltage it settles to is inconsistent. In this case, as presented in the timing diagram, the flop settles to 1. Regardless of whether metastability occurred, the synchronizer for bit 0 captured a '1', and the synchronizers for bits 1 and 2 captured a '0'.

As a result, instead of the receiving domain waiting for the 1 cycle delay and then seeing a clean transition from 0 to 7, it sees a 0, then sees a 1 for the "delay" cycle, and then finally sees the 7. Eventually, the *correct* data (7) is passed along, but that incorrect '1' has already propagated, breaking the dependent logic (here, the decoder).


2. The problem is rooted in the independent capture of data by the 3 synchronizers. At timestamp 1, Aclk rises and the flops capture their respective data inputs. Due to the arrival skew, the flop for bit 0 captures a '1' (because the signal arrived slightly earlier), while the flip-flops for bit 1 and bit 2 capture a '0' (because they were slightly delayed).

Thus, the value actually passed to the internal logic is 001 instead of retaining the stable 000. Finally, the decoder incorrectly asserts aen[1] for one clock cycle.


3. The fundamental problem lies in transferring multiple data bits that are not grey-coded. Each bit may experience metastability independently and resolve at different times or suffer arrival skew. As a result, the destination domain may sample a mix of old and new values, leading to corrupted data.


4. While grey-code seems straightforward, it will not wholly solve the problem alone. Since it is a control signal that is being passed, the values need not consecutively increment or decrement. If the initial control signal is 100 (4) and changes to 110 (6), the grey-code equivalent would be 110 -> 101. The numbers do not differ by a single bit, and hence grey-coding does not serve its purpose.

Proposed solutions:

(a). Use a multi-cycle path with source enable:

Fundamentally, separate the data from the control. Assert data to the destination through direct wires. In the following cycle, assert a src_en signal to 1, this time passing through a 2-flop synchronizer. Once src_en is received at the destination after the cycle delays, the data is also accepted. This ensures that the data has *for sure* reached a stable value because it was asserted 1 cycle *before* src_en was. 

The drawback with this is that it is an open-loop system. Since the source receives no feedback from the destination, it does not know exactly when the capture occurred. Therefore, the source must hold the data stable for a pre-calculated number of cycles thereby exceeding the worst-case synchronization latency before it is safe to change the data. This limits throughput.

(b). Asynchronous FIFO:

Use a standard asynchronous FIFO that buffers the incoming data long enough for the destination to read. Only the read and write pointers (grey-coded) have to be synchronized between the domains.

A fundamental drawback in this approach is the FIFO is limited by its depth. If the input write speed exceeds the read speed for a prolonged period, it may lead to overflow and critical data loss. Therefore, writes should be asserted only if space is available.

(c). Full Handshake Protocol (Request/Acknowledge):

This method establishes a closed-loop communication channel. The source asserts a Request signal along with the data. The destination synchronizes this request, captures the data, and sends back an Acknowledge signal. The source must wait for this Acknowledge to be synchronized back into its own domain before it can complete the transaction. This ensures incredible robustness and works well even with variations in delays, clock frequencies etc.

In a tradeoff for robustness, we give up latency. This method takes roughly twice as long as method (a) as it requires the acknowledge signal to also travel back through the synchronizers.