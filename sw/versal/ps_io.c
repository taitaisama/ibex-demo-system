#include <stdint.h>
#include <stdio.h>

#define GPIO_BASE_ADDR              0x80000000
#define GPIO_0_OFFSET               0x0
#define GPIO_1_OFFSET               0x10000
#define GPIO_2_OFFSET               0x20000
#define GPIO_3_OFFSET               0x30000
#define GPIO_SIZE                   0x40000

#define PS_CTRL_FLUSH                 1
#define PS_CTRL_RSTN                  2
#define PS_CTRL_RST_RVFI_ADDR         4
#define PS_CTRL_RST_RVFI_CSR_ADDR     8

#define NUM_OUTPUT_STREAMS            2

typedef uint32_t addr_t;
typedef uint32_t bit_t;

int setup_mem(void** mem, uint64_t base_addr, uint64_t size);

struct stream_ctrl {
  addr_t next_read_addr;
  addr_t last_curr_addr;

  volatile addr_t* start_addr_ptr;
  volatile addr_t* end_addr_ptr;
  volatile addr_t* curr_addr_ptr; // you cannot read curr_addr, you can read before curr_addr

  bit_t  rst_addr;
  volatile bit_t* rst_addr_ptr;
  volatile bit_t* is_full_ptr;
};

struct ps_io_ctrl {

  volatile void* base_addr;

  struct stream_ctrl streams[NUM_OUTPUT_STREAMS];

  bit_t rst_fulsh_bits;;  
  volatile bit_t* rst_flush_bits_ptr;
};

struct ps_io_ctrl gpic;

bool is_stream_full(int s_num) {
  return *gpic.streams[s_num].is_full_ptr;
}

void stream_rst_addr(int s_num) {
  // is_stream_full() should be true
  gpic.stream[s_num].rst_addr ^= 1;
  *gpic.stream[s_num].rst_addr_ptr = gpic.stream[s_num].rst_addr;
}

bool stream_in32(int s_num, uint32_t* ret) {
  if (gpic.streams[s_num].next_read_addr >= gpic.streams[s_num].last_curr_addr) {
    gpic.streams[s_num].last_curr_addr = *gpic.streams[s_num].curr_addr;    
    if (gpic.streams[s_num].next_read_addr >= gpic.streams[s_num].last_curr_addr) {
      return false;
    } 
  }
  *ret = *((volatile uint32_t*)gpic.streams[s_num].next_read_addr);
  gpic.streams[s_num].next_read_addr += 4;
  return true;
}

