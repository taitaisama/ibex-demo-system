/******************************************************************************
 * Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 ******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include <xaxidma_hw.h>
#include <xstatus.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xaxidma.h"
#include "sleep.h"

#define PROG_LEN      613

unsigned PROG [PROG_LEN] = {0x0c70006f, 0x0c30006f, 0x0bf0006f, 0x0bb0006f, 0x0b70006f, 0x0b30006f, 0x0af0006f, 0x0ab0006f, 0x0a70006f, 0x0a30006f, 0x09f0006f, 0x09b0006f, 0x0970006f, 0x0930006f, 0x08f0006f, 0x08b0006f, 0x0870006f, 0x0830006f, 0x07f0006f, 0x07b0006f, 0x0770006f, 0x0730006f, 0x06f0006f, 0x06b0006f, 0x0670006f, 0x0630006f, 0x05f0006f, 0x05b0006f, 0x0570006f, 0x0530006f, 0x04f0006f, 0x04b0006f, 0x04b0006f, 0xd6067179, 0x1800d422, 0x5537230d, 0x0513004c, 0x4581b405, 0x2b692b65, 0xfea42423, 0xfeb42623, 0x05374581, 0x25398000, 0x20232361, 0x2223fea4, 0x2703feb4, 0x2783fe04, 0x1863fe84, 0x270300f7, 0x2783fe44, 0x0c63fec4, 0x270302f7, 0x2783fe04, 0x2423fe44, 0x2623fee4, 0x0537fef4, 0x2bdd8000, 0xfca42e23, 0xfdc42783, 0xfff7c793, 0xfcf42e23, 0xfdc42583, 0x80000537, 0x00732b75, 0xb76d1050, 0xce061101, 0x1000cc22, 0xfea42623, 0xfec42703, 0x166347a9, 0x45b500f7, 0x80001537, 0x27832635, 0xf793fec4, 0x85be0ff7, 0x80001537, 0x27832e31, 0x853efec4, 0x446240f2, 0x80826105, 0xc6061141, 0x0800c422, 0x80001537, 0x87aa24f9, 0x40b2853e, 0x01414422, 0x11018082, 0xcc22ce06, 0x26231000, 0xa819fea4, 0xfec42783, 0x00178713, 0xfee42623, 0x0007c783, 0x3769853e, 0xfec42783, 0x0007c783, 0x4781f3f5, 0x40f2853e, 0x61054462, 0x71798082, 0xd422d606, 0x2e231800, 0x2623fca4, 0xa091fe04, 0xfdc42783, 0x242383f1, 0x2703fef4, 0x47a5fe84, 0x00e7c963, 0xfe842783, 0x03078793, 0x3789853e, 0x2783a039, 0x8793fe84, 0x853e0377, 0x27833f15, 0x0792fdc4, 0xfcf42e23, 0xfec42783, 0x26230785, 0x2703fef4, 0x479dfec4, 0xfae7dce3, 0x00010001, 0x542250b2, 0x80826145, 0xc6221141, 0x07b70800, 0x07a10002, 0xc3984705, 0x44320001, 0x80820141, 0xce221101, 0x27f31000, 0x26233410, 0x2783fef4, 0x853efec4, 0x61054472, 0x11018082, 0x1000ce22, 0x342027f3, 0xfef42623, 0xfec42783, 0x4472853e, 0x80826105, 0xce221101, 0x27f31000, 0x26233430, 0x2783fef4, 0x853efec4, 0x61054472, 0x11018082, 0x1000ce22, 0xb00027f3, 0xfef42623, 0xfec42783, 0x4472853e, 0x80826105, 0xc6221141, 0x10730800, 0x0001b000, 0x01414432, 0x71798082, 0x1800d622, 0xfca42e23, 0xfcb42c23, 0xfdc42703, 0xf46347fd, 0x478500e7, 0x0797a879, 0x87930000, 0x43986e67, 0xfdc42783, 0x97ba078a, 0xfef42623, 0xfd842703, 0xfec42783, 0x40f707b3, 0xfef42423, 0xfe842703, 0x000807b7, 0x00f75863, 0xfe842703, 0xfff807b7, 0x00f75463, 0xa8b14789, 0xfe842783, 0xfef42223, 0xfe442783, 0x01479713, 0x7fe007b7, 0x27838f7d, 0x9693fe44, 0x07b70097, 0x8ff50010, 0x26838f5d, 0xf7b7fe44, 0x8ff5000f, 0x27838f5d, 0x9693fe44, 0x07b700b7, 0x8ff58000, 0xe7938fd9, 0x202306f7, 0x2783fef4, 0x2703fec4, 0xc398fe04, 0x0000100f, 0x853e4781, 0x61455432, 0x11018082, 0x1000ce22, 0xfea42623, 0xfec42783, 0x3047a073, 0x44720001, 0x80826105, 0xce221101, 0x26231000, 0x2783fea4, 0xb073fec4, 0x00013047, 0x61054472, 0x11018082, 0x1000ce22, 0xfea42623, 0xfec42783, 0x47a1c789, 0x3007a073, 0x47a1a021, 0x3007b073, 0x44720001, 0x80826105, 0xc6061141, 0x0800c422, 0x00000517, 0x59c50513, 0x0517334d, 0x05130000, 0x3b615a25, 0x00000517, 0x5a850513, 0x35993379, 0x853e87aa, 0x05173b7d, 0x05130000, 0x3bb55a25, 0x87aa35b9, 0x3375853e, 0x00000517, 0x59c50513, 0x3d9933ad, 0x853e87aa, 0x45293b69, 0xa0013321, 0xc6061141, 0x0800c422, 0x37916541, 0x3f954505, 0x40b20001, 0x01414422, 0x71798082, 0x1800d622, 0xfca42e23, 0x262357fd, 0x2783fef4, 0x07a1fdc4, 0x8b85439c, 0x2783e791, 0x439cfdc4, 0xfef42623, 0xfec42783, 0x5432853e, 0x80826145, 0xce221101, 0x26231000, 0x87aefea4, 0xfef405a3, 0x27830001, 0x07a1fec4, 0x8b89439c, 0x2783fbfd, 0x0791fec4, 0xfeb44703, 0x0001c398, 0x61054472, 0x11018082, 0x1000ce22, 0xfea42423, 0xfeb42623, 0x800026b7, 0x567d06a1, 0x2683c290, 0xd713fec4, 0x47810006, 0x800026b7, 0x87ba06b1, 0x27b7c29c, 0x07a18000, 0xfe842703, 0x0001c398, 0x61054472, 0x71798082, 0xd422d606, 0x2c231800, 0x2e23fca4, 0x28fdfcb4, 0xfea42423, 0xfeb42623, 0xfe842603, 0xfec42683, 0xfd842503, 0xfdc42583, 0x00a60733, 0x3833883a, 0x87b300c8, 0x06b300b6, 0x87b600f8, 0xfee42423, 0xfef42623, 0xfe842503, 0xfec42583, 0x00013f8d, 0x542250b2, 0x80826145, 0xc686715d, 0xc29ac496, 0xde22c09e, 0xda2edc2a, 0xd636d832, 0xd23ed43a, 0xce46d042, 0xca76cc72, 0xc67ec87a, 0x07970880, 0x87930000, 0x43984627, 0x853a43dc, 0x3f8585be, 0x00000797, 0x44878793, 0x43dc4398, 0x45814505, 0x00a70633, 0x38338832, 0x86b300e8, 0x07b300b7, 0x86be00d8, 0x87b68732, 0x00000697, 0x42068693, 0xc2dcc298, 0x40b60001, 0x431642a6, 0x54724386, 0x55d25562, 0x56b25642, 0x57925722, 0x48f25802, 0x4ed24e62, 0x4fb24f42, 0x00736161, 0x11413020, 0xc422c606, 0x05970800, 0x85930000, 0x451df625, 0x000131f9, 0x442240b2, 0x80820141, 0xce221101, 0x28371000, 0x08118000, 0x00082803, 0xff042623, 0x80002837, 0x00082803, 0xff042423, 0x80002837, 0x28030811, 0x28830008, 0x9ce3fec4, 0x2803fd08, 0x8542fec4, 0x17934581, 0x47010005, 0xfe842583, 0x4681862e, 0x00c765b3, 0xfeb42023, 0x22238fd5, 0x2703fef4, 0x2783fe04, 0x853afe44, 0x447285be, 0x80826105, 0xc6221141, 0x07970800, 0x87930000, 0x439835e7, 0x853a43dc, 0x443285be, 0x80820141, 0xce061101, 0x1000cc22, 0xfea42423, 0xfeb42623, 0x00000797, 0x33878793, 0x47014681, 0xc3d8c394, 0x00000697, 0x33068693, 0xfe842703, 0xfec42783, 0xc2dcc298, 0xfe842503, 0xfec42583, 0x05133d0d, 0x39750800, 0x31f54505, 0x40f20001, 0x61054462, 0x11418082, 0x0800c622, 0x08000793, 0x3047b073, 0x44320001, 0x80820141, 0xce221101, 0x26231000, 0x2423fea4, 0x2783feb4, 0x2703fec4, 0xc398fe84, 0x44720001, 0x80826105, 0xce221101, 0x26231000, 0x2783fea4, 0x439cfec4, 0x4472853e, 0x80826105, 0xd6067179, 0x1800d422, 0xfca42e23, 0xfcb42c23, 0xfcc42a23, 0xfd442783, 0x2a238b85, 0x2503fcf4, 0x37d9fdc4, 0xfea42623, 0xfd842783, 0x17b34705, 0xc79300f7, 0x873efff7, 0xfec42783, 0x26238ff9, 0x2783fef4, 0x2703fd84, 0x17b3fd44, 0x270300f7, 0x8fd9fec4, 0xfef42623, 0xfec42583, 0xfdc42503, 0x000137a5, 0x542250b2, 0x80826145, 0xd6067179, 0x1800d422, 0xfca42e23, 0xfcb42c23, 0xfdc42503, 0x262337a5, 0x2783fea4, 0x2703fd84, 0x57b3fec4, 0x262300f7, 0x2783fef4, 0x8b85fec4, 0xfef42623, 0xfec42783, 0x50b2853e, 0x61455422, 0x11018082, 0x1000ce22, 0xfea42623, 0xfeb42423, 0xfec42223, 0xfec42783, 0x27030791, 0xc398fe84, 0xfec42783, 0xfe442703, 0x0001c398, 0x61054472, 0x11018082, 0x1000ce22, 0xfea42623, 0xfeb42423, 0xfec42223, 0xfec42783, 0xfe842703, 0x2783c398, 0x2703fec4, 0xc3d8fe44, 0x44720001, 0x80826105, 0xce221101, 0x26231000, 0x87aefea4, 0xfef405a3, 0x27830001, 0x439cfec4, 0x439c0791, 0xfbf58b85, 0xfec42783, 0x4703439c, 0xc398feb4, 0x44720001, 0x80826105, 0xce221101, 0x26231000, 0x2783fea4, 0x439cfec4, 0x439c0791, 0x4472853e, 0x80826105, 0xce061101, 0x1000cc22, 0xfea42623, 0x25030001, 0x3fc9fec4, 0xf71387aa, 0x47890027, 0xfef719e3, 0x00010001, 0x446240f2, 0x80826105, 0xce061101, 0x1000cc22, 0xfea42623, 0xfeb42423, 0xfec42223, 0xfec42503, 0xa8293f75, 0xfe842783, 0x00178713, 0xfee42423, 0x0007c783, 0x250385be, 0x3f89fec4, 0xfe442783, 0xfff78713, 0xfee42223, 0x0001fff1, 0x40f20001, 0x61054462, 0xf06f8082, 0x0093ae3f, 0x81060000, 0x82068186, 0x83068286, 0x84068386, 0x85068486, 0x86068586, 0x87068686, 0x88068786, 0x89068886, 0x8a068986, 0x8b068a86, 0x8c068b86, 0x8d068c86, 0x8e068d86, 0x8f068e86, 0xf1178f86, 0x01130001, 0x0d176f61, 0x0d130000, 0x0d97086d, 0x8d930000, 0x576308ed, 0x202301bd, 0x0d11000d, 0xffaddde3, 0x45814501, 0xf50ff0ef, 0x000202b7, 0x430502a1, 0x0062a023, 0x10500073, 0x0000bff5, 0x45435845, 0x4f495450, 0x2121214e, 0x0000000a, 0x3d3d3d3d, 0x3d3d3d3d, 0x3d3d3d3d, 0x0000000a, 0x4350454d, 0x2020203a, 0x00007830, 0x41434d0a, 0x3a455355, 0x00783020, 0x56544d0a, 0x203a4c41, 0x00783020, 0x00100000};


#define MAX_PKT_LEN		0x300

#define RVFI_DMA_ADDR		0x201C0000000
#define RVFI_CSR_DMA_ADDR	0x20240000000
#define BRAM_CTRL_ADDR          0x20100000000
#define PS_IO_ADDR              0x20140000000
#define DEBUG_ADDR              0x202C0000000

#define MEM_BASE_ADDR		0x01000000

#define RVFI_ADDR		    (MEM_BASE_ADDR + 0x00100000)
#define RVFI_CSR_ADDR		(MEM_BASE_ADDR + 0x00300000)

u32 ps_io = 0;

int is_ps_ctrl() {
  return ps_io & 2;
}

void set_ps_ctrl() {
  ps_io = ps_io | 2;
  Xil_Out32(PS_IO_ADDR, ps_io);
}

void set_pl_ctrl() {
  ps_io = ps_io & (~2);
  Xil_Out32(PS_IO_ADDR, ps_io);
}

void ps_send_last() {
  ps_io = ps_io | 1;
  Xil_Out32(PS_IO_ADDR, ps_io);
  ps_io = ps_io & (~1);
  Xil_Out32(PS_IO_ADDR, ps_io);
}

u32 setup_dma(UINTPTR BaseAddress, XAxiDma* AxiDma)
{
  XAxiDma_Config *CfgPtr;

  CfgPtr = XAxiDma_LookupConfig(BaseAddress);
  if (!CfgPtr) {
    xil_printf("No config found for %d\r\n", BaseAddress);
    return XST_FAILURE;
  }
  u32 Status = XAxiDma_CfgInitialize(AxiDma, CfgPtr);
  if (Status != XST_SUCCESS) {
    xil_printf("Initialization failed %d\r\n", Status);
    return XST_FAILURE;
  }
  if (XAxiDma_HasSg(AxiDma)) {
    xil_printf("Device configured as SG mode \r\n");
    return XST_FAILURE;
  }
  return XST_SUCCESS;
}

void set_prog() {
  for (int i = 0; i < PROG_LEN; i ++){
    Xil_Out32(BRAM_CTRL_ADDR + (i*4), PROG[i]);
  }
}

u32 check_prog() {
  for (int i = 0; i < PROG_LEN; i ++){
    if (PROG[i] != Xil_In32(BRAM_CTRL_ADDR + (i*4))) {
      return XST_FAILURE;
    }
  }
  return XST_SUCCESS;
}

void print_rvfi_data() {
  printf("rvfi data\n");
  for (int i = 0; i < 10; i ++) {
    printf("%x, ", Xil_In32(RVFI_ADDR + i*4));
  }
  printf("\n\r");
}

#define DEBUG_LEN 19
void print_debug_data() {
  printf("debug data\n");
  
  int widths [DEBUG_LEN] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5, 5, 10, 28};
  int cumsum [DEBUG_LEN];
  u32 vals [DEBUG_LEN];

  cumsum[0] = widths[0];
  for (int i = 1; i < DEBUG_LEN; i ++) {
    cumsum[i] = cumsum[i-1] + widths[i];
  }

  const char* names [DEBUG_LEN] = {"rvfi_valid:%x, ", "rvfi_handler_tvalid:%x, ", "rvfi_handler_ready:%x, ", "fifo_1_empty:%x, ", "fifo_1_almost_full:%x, ", "fifo_1_wr_en:%x, ", "fifo_1_rd_en:%x, ", "fifo_2_empty:%x, ", "fifo_2_almost_full:%x, ", "fifo_2_wr_en:%x, ", "fifo_2_rd_en:%x, ", "fifo_3_empty:%x, ", "fifo_3_almost_full:%x, ", "fifo_3_wr_en:%x, ", "fifo_3_rd_en:%x, ", "rvfi_rd_addr:%x, ", "rvfi_tdata:%x, ", "ibex_ram_b_addr:%x, ", "rvfi_ext_mcycle:%x, "};
  
  for (int i = 0; i < 100; i ++) {
    unsigned long long d = Xil_In64(DEBUG_ADDR + i*8);
    
    for (int i = 0; i < DEBUG_LEN; i ++) {
      vals[i] = (d >> (64-cumsum[i])) & ((1ll << widths[i])-1);
      printf("%x, ", vals[i]);
    }
    printf("\n\r");

    /* printf("rvfi_valid:%x, rvfi_handler_tvalid:%x, rvfi_handler_ready:%x, fifo_1_empty:%x, fifo_1_almost_full:%x, fifo_1_wr_en:%x, fifo_1_rd_en:%x, fifo_2_empty:%x, fifo_2_almost_full:%x, fifo_2_wr_en:%x, fifo_2_rd_en:%x, fifo_3_empty:%x, fifo_3_almost_full:%x, fifo_3_wr_en:%x, fifo_3_rd_en:%x, rvfi_rd_addr:%x, rvfi_tdata:%x, ibex_ram_b_addr:%x, rvfi_ext_mcycle:%x", vals[0], vals[1], vals[2], vals[3], vals[4], vals */

    /* u32 rvfi_valid = (d >> 63) & 1; */
    /* u32 rvfi_tvalid = (d >> 62) & 1; */
    /* u32 rvfi_tready = (d >> 61) & 1; */


    /* u32 rvfi_rd_addr = (d >> 56) & ((1<<5)-1); */
    /* u32 rvfi_tdata = (d >> 51) & ((1<<5)-1); */
    /* u32 ibex_ram_b_addr = (d >> 41) & ((1<<10)-1); */
    /* u32 rvfi_ext_mcycle = (d >> 32) & ((1<<9)-1); */
    /* u32 ibex_ram_b_rdata = d & ((1ll << 32) - 1); */

    /* printf("rvfi_valid:%x, rvfi_tvalid:%x, rvfi_tready:%x, rvfi_rd_addr:%x rvfi_tdata:%x, ibex_ram_b_addr:%x, rvfi_ext_mcycle:%x, ibex_ram_b_rdata:%x\n\r", rvfi_valid, rvfi_tvalid, rvfi_tready, rvfi_rd_addr, rvfi_tdata, ibex_ram_b_addr, rvfi_ext_mcycle, ibex_ram_b_rdata); */
  }
  printf("\n\r");
}

int main()
{
  init_platform();

  XAxiDma rvfi_dma;
  XAxiDma rvfi_csr_dma;

  set_ps_ctrl();
  print_rvfi_data();
  if (setup_dma(RVFI_DMA_ADDR, &rvfi_dma) != XST_SUCCESS) {
    return XST_FAILURE;
  }
  if (setup_dma(RVFI_CSR_DMA_ADDR, &rvfi_csr_dma) != XST_SUCCESS) {
    return XST_FAILURE;
  }

  u32 tl = rvfi_dma.TxBdRing.MaxTransferLen;
  printf("hello\n");

  printf("max transfer len %x\n", tl);
  /* print_debug_data(); */
  set_prog();

  if (check_prog() != XST_SUCCESS){
    return XST_FAILURE;
  }

  Xil_DCacheFlushRange((UINTPTR)(RVFI_ADDR), MAX_PKT_LEN);
  Xil_DCacheFlushRange((UINTPTR)(RVFI_CSR_ADDR), MAX_PKT_LEN);

  if (XAxiDma_SimpleTransfer(&rvfi_dma, (UINTPTR)(RVFI_ADDR), MAX_PKT_LEN, XAXIDMA_DEVICE_TO_DMA) != XST_SUCCESS) {
    return XST_FAILURE;
  }

  if (XAxiDma_SimpleTransfer(&rvfi_csr_dma, (UINTPTR)(RVFI_CSR_ADDR), MAX_PKT_LEN, XAXIDMA_DEVICE_TO_DMA) != XST_SUCCESS) {
    return XST_FAILURE;
  }
  print_rvfi_data();
  set_pl_ctrl();
  
  printf("waiting\n");

  usleep(10000U);

  print_debug_data();
  print_rvfi_data();

  cleanup_platform();
  return 0;
}
