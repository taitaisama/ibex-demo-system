import sys

def generate_axi_mem_init(hex_data, data_width=32, depth=14530, prefix="mem_init"):
    """
    Splits a list of N-bit hex values into byte-lane files.
    
    Args:
        hex_data (list): List of integers (32-bit values).
        data_width (int): Total width of the AXI bus in bits.
        depth (int): Depth of the RAM (number of addresses).
        prefix (str): Filename prefix.
    """
    num_bytes = data_width // 8
    
    # Create the files for each byte lane
    for byte_lane in range(num_bytes):
        filename = f"{prefix}_{byte_lane}.mem"
        
        with open(filename, "w") as f:
            for i in range(depth):
                if i < len(hex_data):
                    # Extract the specific 8-bit chunk for this lane
                    # Byte 0 is the LSB (bits 7:0)
                    byte_val = (hex_data[i] >> (8 * byte_lane)) & 0xFF
                    f.write(f"{byte_val:02x}\n")
                else:
                    # Fill remaining memory with 00
                    f.write("00\n")
        
        print(f"Generated: {filename}")

# --- CONFIGURATION ---
# Define your 32-bit values here (max 16 entries for your current BRAM)

if len(sys.argv) < 2:
    print("give file name")
    assert(False)

file_name = sys.argv[1]

my_data = [int(x, 16) for x in open(file_name).readlines()]

generate_axi_mem_init(my_data, data_width=32, depth=14530)
