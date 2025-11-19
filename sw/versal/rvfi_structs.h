struct __attribute__((packed)) rvfi {
  uint64_t mcycle;
  uint32_t rvfi_rd_wdata;
  uint32_t rvfi_pc_rdata;
  uint32_t rvfi_ext_pre_mip;
  uint32_t rvfi_ext_post_mip;
  uint8_t rvfi_rd_addr : 5;
  uint8_t rvfi_ext_nmi : 1;
  uint8_t rvfi_ext_nmi_int : 1;
  uint8_t rvfi_ext_debug_req : 1;
  uint8_t rvfi_ext_rf_wr_suppress : 1;
  uint8_t rvfi_ext_ic_scr_key_valid : 1;
  uint8_t rvfi_trap : 1;
  uint8_t unused : 5;
};
static_assert(sizeof(rvfi) == 26, "rvfi struct must be 26 bytes");

struct __attribute__((packed)) csr {
  uint64_t mcycle;
  uint8_t addr;
  uint32_t counter;
};
static_assert(sizeof(csr) == 13, "csr struct must be 13 bytes");
