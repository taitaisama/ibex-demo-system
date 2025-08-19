#!/bin/bash
# convert.sh -- Convert ELF to HEX (Xilinx-style word format)

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <elf-file>"
    exit 1
fi

INPUT="$1"
DIRNAME=$(dirname "$INPUT")
BASENAME=$(basename "$INPUT")

BINFILE="${DIRNAME}/${BASENAME}.bin"
HEXFILE="${DIRNAME}/${BASENAME}.hex"

# Extract .text section to raw binary
riscv32-unknown-elf-objcopy -O binary "$INPUT" "$BINFILE"

# Convert binary to hex (32-bit words, little endian swapped correctly)
xxd -p -c4 "$BINFILE" | awk '{ 
    word=$1;
    b1=substr(word,1,2);
    b2=substr(word,3,2);
    b3=substr(word,5,2);
    b4=substr(word,7,2);
    print b4 b3 b2 b1;
}' > "$HEXFILE"

echo "Generated $HEXFILE"
