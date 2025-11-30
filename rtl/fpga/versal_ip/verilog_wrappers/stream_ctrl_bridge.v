
module stream_ctrl_bridge(
     input ctrl_in_swidx,
     output ctrl_in_hwidx,
     input ctrl_in_baseaddr,
     
     output ctrl_out_swidx,
     input  ctrl_out_hwidx,
     output ctrl_out_baseaddr
     
    );
    
    assign ctrl_out_swidx = ctrl_in_swidx;
    assign ctrl_in_hwidx = ctrl_out_hwidx;
    assign ctrl_out_baseaddr = ctrl_in_baseaddr;
endmodule
