// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdbool.h>

#include "demo_system.h"
#include "gpio.h"
#include "pwm.h"
#include "timer.h"

#define USE_GPIO_SHIFT_REG 0


int main(void) {

  // Reset green LEDs to having just one on
  set_outputs(GPIO_OUT, 0x0); // Bottom 4 bits are LCD control as you can see in top_artya7.sv

  while (1) {    
    uint32_t out_val = read_gpio(GPIO_OUT);
    out_val = ~out_val;
    set_outputs(GPIO_OUT, out_val);
    asm volatile("wfi");
  }
}
