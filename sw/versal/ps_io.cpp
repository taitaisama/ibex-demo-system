#include <stdint.h>
#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "rvfi_structs.h"

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

extern uint32_t MEM_VIRT_ADDR;
extern uint32_t GPIO_VIRT_ADDR;

typedef uint32_t bits_t;

struct mem_ptr_t {

  uint64_t phys_addr;

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

  bool operator>=(const mem_ptr_t &other) const {
    return phys_addr >= other.phys_addr;
  }

  mem_ptr_t operator+(const uint32_t add) {
    mem_ptr_t x(add);
    x.phys_addr = this->phys_addr + add;
    return x;
  }
};

struct gpio_ptr_t {

  uint64_t phys_addr;

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

template<typename T, uint32_t L>
struct stream_ctrl {

  mem_ptr_t base_addr;
  mem_ptr_t next_read_addr;

  bits_t    sw_idx;

  gpio_ptr_t sw_idx_ptr;
  gpio_ptr_t hw_idx_ptr;
  gpio_ptr_t base_addr_ptr;

  uint32_t data [L];
  uint32_t data_idx;

  stream_ctrl (uint32_t sip, uint32_t hip, uint32_t bap, uint32_t sa) :
    base_addr(sa),
    next_read_addr(sa),
    sw_idx_ptr(sip),
    hw_idx_ptr(hip),
    base_addr_ptr(bap),
    data_idx(0)
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

  bool in32(uint32_t &res) {
    if (next_read_addr >= curr_buff_end_addr()) {
      // increase sw_idx, if cant return false
      uint32_t next_sw_idx = sw_idx == BUFFER_NUM-1 ? 0 : sw_idx + 1;
      if (hw_idx_ptr.in() == next_sw_idx) {
        return false;
      } else {
        sw_idx = next_sw_idx;
        sw_idx_ptr.out(sw_idx);
        next_read_addr = curr_buff_start_addr();
      }
    }
    res = next_read_addr.in();
    next_read_addr.inc();
    return true;
  }

  T* read() {
    while (data_idx < L) {
      if (!in32(data[data_idx])) {
	return nullptr;
      }
      data_idx ++;
    }
    data_idx = 0;
    return reinterpret_cast<T*>(data);
  }
  
};

struct ps_io_ctrl {

  static constexpr int rst_bit = 1;
  static constexpr int flush_bit = 0;

  gpio_ptr_t rst_flush_ptr;

  mem_ptr_t prog_base_addr;
  gpio_ptr_t prog_base_addr_ptr;

  stream_ctrl<rvfi, 8> rvfi_stream;
  stream_ctrl<csr, 4> csr_stream;
  rvfi* curr_rvfi;
  csr* curr_csr;

  ps_io_ctrl() :
    rst_flush_ptr(PS_FLUSH_RST_OFFSET),
    prog_base_addr(PROG_OFFSET),
    prog_base_addr_ptr(PROG_ADDR_OFFSET),
    rvfi_stream(RVFI_START_ADDR,
                RVFI_HW_IDX_OFFSET,
                RVFI_BASE_ADDR_OFFSET,
                RVFI_SW_IDX_OFFSET),
    csr_stream(RVFI_CSR_START_ADDR,
               RVFI_CSR_HW_IDX_OFFSET,
               RVFI_CSR_BASE_ADDR_OFFSET,
               RVFI_CSR_SW_IDX_OFFSET)
    { }
  
  void start(uint32_t * prog_data, uint32_t size) {
    rst_flush_ptr.out(1 << rst_bit);
    mem_ptr_t curr_prog_addr = prog_base_addr;
    for (uint32_t i = 0; i < size; i ++) {
      curr_prog_addr.out(prog_data[i]);
      curr_prog_addr.inc();
    }
    prog_base_addr_ptr.out(prog_base_addr.get_abs());
    rvfi_stream.set_addrs();
    csr_stream.set_addrs();
    rst_flush_ptr.out(0);
  }
  
  void run() {
    for (int i = 0; i < 100; i ++) {
      curr_rvfi = rvfi_stream.read();
      if (!curr_rvfi) continue;
      if (!curr_csr) {
	curr_csr = csr_stream.read();
      }
      if (curr_csr && curr_csr->mcycle < curr_rvfi->mcycle) {
	xil_printf("csr:\n  mcycle: %ld\n  addr: %d\n  counter: %d\n", curr_csr->mcycle, curr_csr->addr, curr_csr->counter);
	// if (!csr_callback(*curr_csr)) {
	//   return;
	// }
	curr_csr = nullptr;
      }
      xil_printf("rvfi:\n  mcycle: %ld\n  rvfi_rd_wdata: %d\n  rvfi_pc_rdata: %d\n  rvfi_rd_addr: %d\n", curr_rvfi->mcycle, curr_rvfi->rvfi_rd_wdata, curr_rvfi->rvfi_rd_rdata, curr_rvfi->rvfi_rd_addr);
      // if (!rvfi_callback(*curr_rvfi)) {
      // 	return;
      // }
    }
  }
};

void run() {
    ps_io_ctrl ctrl;
    ctrl.start(PROG, PROG_LEN);
    ctrl.run();
}
