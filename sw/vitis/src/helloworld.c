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
extern "C" {
#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xil_cache.h"
#include <sleep.h>
}

void run();
int main()
{

    init_platform();

    xil_printf("Hello World %d\n\r", 100);
    for (int i = 0; i < 1024; i ++) {
        Xil_Out32(0x30000000 + 0x100000 + i*4, 0x0);
    }
    
    Xil_DCacheFlushRange(0x30000000 + 0x100000, 131072);
    print("Successfully ran Hello World application\n\r");
    run();
    // xil_printf("waiting %d\n\r", 100);
    // xil_printf("waiting %d\n\r", 100);
    // xil_printf("waiting %d\n\r", 100);
    // print("ok");
    sleep(1);
    Xil_DCacheFlushRange(0x30000000 + 0x100000, 131072);
    xil_printf("waiting %d\n\r", 100);
    xil_printf("waiting %d\n\r", 100);
    for (int i = 0; i < 1024; i ++) {
        xil_printf("\"%x\", ", Xil_In32(0x20100000000 + i*4));
    }
    xil_printf("\n\n");
    for (int i = 0; i < 1024; i ++) {
        xil_printf("\"%x\", ", Xil_In32(0x30000000 + 0x100000 + i*4));
    }
    
    xil_printf("\n\n");
    for (int i = 12; i < 16; i ++) {
        xil_printf("\"%x\", ", Xil_In32(0x20180000000 + i*4));
    }
    // xil_printf("\"%x\"", Xil_In32(0x60000080));
    cleanup_platform();
    return 0;
}
