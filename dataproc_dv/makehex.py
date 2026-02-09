#!/usr/bin/env python3
import sys
from struct import unpack

# Usage: python makehex.py firmware.bin firmware.hex

if len(sys.argv) < 3:
    print("Usage: makehex.py <bin> <hex>")
    sys.exit(1)

try:
    with open(sys.argv[1], "rb") as f:
        bindata = f.read()

    while len(bindata) % 4 != 0:
        bindata += b'\x00'

    with open(sys.argv[2], "w") as f:
        for i in range(0, len(bindata), 4):
            # <I unpacks as Little Endian (Flips bytes correctly)
            word = unpack("<I", bindata[i:i+4])[0]
            f.write(f"{word:08x}\n")

    print("Success: 32-bit Little Endian hex generated.")

except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)