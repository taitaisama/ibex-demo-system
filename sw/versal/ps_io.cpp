#include <stdint.h>
#include <stdio.h>
#include <optional>

#define NUM_OUTPUT_STREAMS          2

#define GPIO_BASE_PHYS_ADDR         0x80000000
#define MEM_BASE_PHYS_ADDR          0x30000000

#define PROG_OFFSET                 0x000000

#define BUFFER_SIZE                 0x100000
#define BUFFER_NUM                  0x4

#define PROG_ADDR_OFFSET            0x10008
#define PS_FLUSH_RST_OFFSET         0x10000

#define RVFI_START_ADDR             0x100000
#define RVFI_CSR_START_ADDR         0x400000

#define RVFI_HW_IDX_OFFSET          0x20000
#define RVFI_BASE_ADDR_OFFSET       0x30000
#define RVFI_SW_IDX_OFFSET          0x40000

#define RVFI_CSR_HW_IDX_OFFSET      0x20008
#define RVFI_CSR_BASE_ADDR_OFFSET   0x30008
#define RVFI_CSR_SW_IDX_OFFSET      0x40008

// when write pointer reaches end of a buffer, hw_idx is incremented
// when  read pointer reaches end of a buffer, sw_idx is incremented
// let n be the number of buffers
// hw: I can write as long as I am not writing over somthing not read
//     so when incrementing hw_idx, if hw_idx + 1 == sw_idx + n, I stop
// sw: I can read as long as I am not going ahead of hw_idx
//     so when incrementing sw_idx, if sw_idx + 1 == hw_idx,     I stop
// need > 2 buffers for this to work

enum STREAMS {
  RVFI_STREAM = 0,
  RVFI_CSR_STREAM = 1
};

extern uint32_t MEM_VIRT_ADDR;
extern uint32_t GPIO_VIRT_ADDR;

typedef uint32_t bits_t;

struct mem_ptr_t {

  uint32_t phys_addr;

  mem_ptr_t (uint32_t of) : phys_addr(MEM_BASE_PHYS_ADDR + of) {}

  uint32_t in() {
    return *(volatile uint32_t*)(MEM_VIRT_ADDR + phys_addr);
  }

  void out(uint32_t val) {
    *(volatile uint32_t*)(MEM_VIRT_ADDR + phys_addr) = val;
  }

  void inc() {
    phys_addr += 4;
  }

  uint32_t get_abs() const {
    return phys_addr;
  }

  mem_ptr_t& operator=(const uint32_t of) {
    phys_addr = of;
    return *this;
  }

  bool operator>=(const mem_ptr_t &other) const {
    return phys_addr >= other.phys_addr;
  }

  mem_ptr_t operator+(const uint32_t add) {
    mem_ptr_t x;
    x.phys_addr = this->phys_addr + add;
    return x;
  }
};

struct gpio_ptr_t {

  uint32_t phys_addr;

  gpio_ptr_t (uint32_t of) : phys_addr(GPIO_BASE_PHYS_ADDR + of) {}

  uint32_t in() {
    return *(volatile uint32_t*)(GPIO_VIRT_ADDR + phys_addr);
  }

  void out(uint32_t val) {
    *(volatile uint32_t*)(GPIO_VIRT_ADDR + phys_addr) = val;
  }

  void out(mem_ptr_t addr) {
    *(volatile uint32_t*)(GPIO_VIRT_ADDR + phys_addr) = addr.phys_addr;
  }

  gpio_ptr_t& operator=(const uint32_t of) {
    phys_addr = of;
    return *this;
  }
};

struct stream_ctrl {

  mem_ptr_t base_addr;
  mem_ptr_t next_read_addr;

  bits_t    sw_idx;

  gpio_ptr_t sw_idx_ptr;
  gpio_ptr_t hw_idx_ptr;
  gpio_ptr_t base_addr_ptr;

  stream_ctrl (uint32_t sip, uint32_t hip, uint32_t bap, uint32_t sa) :
    base_addr(sa),
    next_read_addr(sa),
    sw_idx_ptr(sip),
    hw_idx_ptr(hip),
    base_addr_ptr(bap)
  { }

  void set_addrs() {
    base_addr_ptr.out(base_addr.get_abs());
  }

  mem_ptr_t curr_buff_end_addr() {
    return base_addr + (sw_idx+1) * BUFFER_SIZE;
  }

  mem_ptr_t curr_buff_start_addr() {
    return base_addr + sw_idx * BUFFER_SIZE;
  }

  std::optional<uint32_t> in() {
    if (next_read_addr >= curr_buff_end_addr()) {
      // increase sw_idx, if cant return nullopt
      uint32_t next_sw_idx = sw_idx == BUFFER_NUM-1 ? 0 : sw_idx + 1;
      if (hw_idx_ptr.in() == next_sw_idx) {
	return std::nullopt;
      } else {
	sw_idx = next_sw_idx;
	sw_idx_ptr.out(sw_idx);
	next_read_addr = curr_buff_start_addr();
      }
    }
    uint32_t ret = next_read_addr.in();
    next_read_addr.inc();
    return std::optional<uint32_t>(ret);
  }
  
};

struct ps_io_ctrl {

  bits_t rst_flush_bits;
  gpio_ptr_t rst_flush_bits_ptr;

  mem_ptr_t prog_base_addr;
  gpio_ptr_t prog_base_addr_ptr;

  stream_ctrl streams[NUM_OUTPUT_STREAMS];

  ps_io_ctrl() :
    rst_flush_bits(0),
    rst_flush_bits_ptr(PS_FLUSH_RST_OFFSET),
    prog_base_addr(PROG_OFFSET),
    prog_base_addr_ptr(PROG_ADDR_OFFSET),
    stream_ctrl[RVFI_STREAM](RVFI_START_ADDR,
			     RVFI_HW_IDX_OFFSET,
			     RVFI_BASE_ADDR_OFFSET,
			     RVFI_SW_IDX_OFFSET),
    stream_ctrl[RVFI_CSR_STREAM](RVFI_CSR_START_ADDR,
				 RVFI_CSR_HW_IDX_OFFSET,
				 RVFI_CSR_BASE_ADDR_OFFSET,
				 RVFI_CSR_SW_IDX_OFFSET): 
    { }		  
  
};





