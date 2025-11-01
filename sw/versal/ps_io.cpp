#include <stdint.h>
#include <stdio.h>
#include <optional>

#define NUM_OUTPUT_STREAMS          2

#define GPIO_BASE_PHYS_ADDR         0x80000000
#define MEM_BASE_PHYS_ADDR          0x30000000

#define PROG_OFFSET                 0x000000

#define BUFFER_SIZE                 0x100000
#define BUFFER_NUM                  0x4

// #define RVFI_START_OFFSET           0x100000
// #define RVFI_END_OFFSET             0x200000
// #define RVFI_CSR_START_OFFSET       0x200000
// #define RVFI_CSR_END_OFFSET         0x300000

// #define PROG_ADDR_OFFSET            0x10008
// #define PS_FLUSH_RST_OFFSET         0x10000
// #define RVFI_START_ADDR_OFFSET      0x40000
// #define RVFI_CSR_START_ADDR_OFFSET  0x40008
// #define RVFI_END_ADDR_OFFSET        0x30000
// #define RVFI_CSR_END_ADDR_OFFSET    0x30008
// #define RVFI_CURR_ADDR_OFFSET       0x20000
// #define RVFI_CSR_CURR_ADDR_OFFSET   0x20008
// #define RVFI_HW_IDX_OFFSET          0x50008
// #define RVFI_CSR_HW_IDX_OFFSET      0x00008
// #define RVFI_SW_IDX_OFFSET          0x50000
// #define RVFI_CSR_SW_IDX_OFFSET      0x00000

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

  mem_ptr_t& operator=(const uint32_t of) {
    phys_addr = of;
    return *this;
  }

  bool operator>=(const mem_ptr_t &other) const {
    return phys_addr >= other.phys_addr;
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

  mem_ptr_t next_read_addr;
  mem_ptr_t last_curr_addr;

  mem_ptr_t start_addr;
  mem_ptr_t end_addr;

  gpio_ptr_t start_addr_ptr;
  gpio_ptr_t end_addr_ptr;
  gpio_ptr_t curr_addr_ptr; // you cannot read at curr_addr, you can read before curr_addr

  bits_t  reset;
  gpio_ptr_t reset_ptr;
  gpio_ptr_t is_full_ptr;

  stream_ctrl (uint32_t sap, uint32_t eap, uint32_t cap,
	       uint32_t rp, uint32_t ifp, uint32_t sa, uint32_t ea) :
    next_read_addr(sa),
    last_curr_addr(sa),
    start_addr(sa),
    end_addr(ea),
    start_addr_ptr(sap),
    end_addr_ptr(eap),
    curr_addr_ptr(cap),
    reset(0),
    reset_ptr(rp),
    is_full_ptr(ifp)
  { }

  void set_addrs() {
    start_addr_ptr.out(start_addr);
    end_addr_ptr.out(end_addr);
  }

  bool is_full() {
    return (bool) is_full_ptr.in();
  }

  void reset() {
    // is_full() should be true
    reset ^= 1;
    reset_ptr.out(reset);
    last_curr_addr = start_addr;
    next_read_addr = start_addr;
  }

  std::optional<uint32_t> in() {
    if (next_read_addr >= last_curr_addr) {
      last_curr_addr = curr_addr_ptr.in();
      if (next_read_addr >= last_curr_addr) {
	return std::nullopt;
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
    stream_ctrl[RVFI_STREAM](RVFI_START_ADDR_OFFSET,
			     RVFI_END_ADDR_OFFSET,
			     RVFI_CURR_ADDR_OFFSET,
			     RVFI_RST_OFFSET,
			     RVFI_FULL_OFFSET,
			     RVFI_START_OFFSET,
			     RVFI_END_OFFSET),
    stream_ctrl[RVFI_CSR_STREAM](RVFI_CSR_START_ADDR_OFFSET,
				 RVFI_CSR_END_ADDR_OFFSET,
				 RVFI_CSR_CURR_ADDR_OFFSET,
				 RVFI_CSR_RST_OFFSET,
				 RVFI_CSR_FULL_OFFSET,
				 RVFI_CSR_START_OFFSET,
				 RVFI_CSR_END_OFFSET): 
    { }

  using check_stream = std::function<void(uint32_t)>;

  static void run_check(const check_stream& check,
			const stream_ctrl& stream ) {
    auto a = stream.in();
    if (a) {
      check(*a);
    } else if (stream.is_full()) {
      stream.reset();
    }
  }
		  
  
};





