#include <stdint.h>
#include <stdio.h>

#define RESERVED_MEM_BASE_ADDR      0x30000000
#define RESERVED_MEM_SIZE           0x10000000

#define PROG_OFFSET                 0x00000000
#define RVFI_OFFSET                 0x01000000
#define RVFI_CSR_OFFSET             0x04000000


#define DEBUG_ADDR                  0x020100000000
#define DEBUG_SIZE                  0x00004000

void * DEBUG_mem;
void * reserved_mem;

int setup_mem(void** mem, uint64_t base_addr, uint64_t size);


int setup_reserved_mem() {
  return setup_mem(reserved_mem, RESERVED_MEM_BASE_ADDR, RESERVED_MEM_SIZE);
}

int setup_debug_mem() {
  return setup_mem(DEBUG_mem, DEBUG_ADDR, DEBUG_SIZE);
}

void set_addresses() {
  volatile uint32_t * virt_addr;
  virt_addr = (volatile uint32_t*) ((char*)GPIO_mem + GPIO_0_OFFSET + 8);
  *virt_addr = RESERVED_MEM_BASE_ADDR + PROG_OFFSET;
  virt_addr = (volatile uint32_t*) ((char*)GPIO_mem + GPIO_1_OFFSET);
  *virt_addr = RESERVED_MEM_BASE_ADDR + RVFI_OFFSET;
  virt_addr = (volatile uint32_t*) ((char*)GPIO_mem + GPIO_1_OFFSET + 8);
  *virt_addr = RESERVED_MEM_BASE_ADDR + RVFI_CSR_OFFSET;
}

void set_prog() {
  volatile uint32_t * virt_addr;
  virt_addr = (volatile uint32_t*) ((char*)reserved_mem + PROG_OFFSET);
  for (int i = 0; i < PROG_LEN; i ++) {
    virt_addr[i] = PROG[i];
  }
}

uint32_t get_rvfi_end_addr() {
  volatile uint32_t * virt_addr;
  virt_addr = (volatile uint32_t*) ((char*)GPIO_mem + GPIO_2_OFFSET);
  return *virt_addr;
}

void print_rvfi(int len) {
  volatile uint32_t * virt_addr;
  virt_addr = (volatile uint32_t*) ((char*)reserved_mem + PROG_OFFSET);
  for (int i = 0; i < len; i ++) {
    printf("%d, ", virt_addr[i]);
  }
  printf("\n");
}

void print_debug(int len) {
  volatile uint32_t * virt_addr;
  virt_addr = (volatile uint32_t*) ((char*)debug_mem + PROG_OFFSET);
  for (int i = 0; i < len; i ++) {
    printf("%d, ", virt_addr[i]);
  }
  printf("\n");
}

int main() {

  if (setup_gpio_mem() || setup_reserved_mem() || setup_debug_mem()) {
    return -1;
  }
  
  ps_rst();

  set_addresses();

  set_prog();

  ps_start();

  while (get_rvfi_end_addr() < RESERVED_MEM_BASE_ADDR + RVFI_OFFSET + 0x1000) {}

  ps_rst();

  print_rvfi(1024);
  print_debug(1024);
}
