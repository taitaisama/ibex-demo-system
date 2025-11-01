module datamover_cmd #(
    parameter		   DATA_WIDTH = 8,
    parameter		   ADDR_WIDTH = 32,
    parameter		   THRESHOLD = 32,
    parameter logic [31:0] BUFFER_SIZE = 0x100000,
    parameter int	   NUM_BUFFERS = 4
)(
    input logic				   clk,
    input logic				   rstn,
  
    input logic [31:0]			   base_addr,
    input logic [$clog2(NUM_BUFFERS)-1:0]  sw_idx,
    output logic [$clog2(NUM_BUFFERS)-1:0] hw_idx,

    input logic				   fifo_write,

    input logic				   flush,

    output logic [71:0]			   m_axis_cmd_tdata,
    output logic			   m_axis_cmd_tvalid,
    input logic				   m_axis_cmd_tready,

    input logic [7:0]			   m_axis_sts_tdata,
    input logic				   m_axis_sts_tvalid,
    output logic			   m_axis_sts_tready
);
   
   logic trigger;
   logic [31:0] fill_level;
   logic [31:0]	write_amount;

   localparam logic [3:0]       RSVD = 0;
   localparam logic [3:0]       TAG = 0;
   localparam logic             DRR = 0;
   localparam logic             EOF = 0;
   localparam logic [5:0]       DSA = 0;
   localparam logic             TYPE = 1;

   logic [22:0]                 BTT;
   logic [ADDR_WIDTH-1:0]       ADDR;
   logic			write_space_left;

   logic [31:0]			buffer_end_addr;
   logic			buffer_full;

   logic [31:0]			pending_cmds_count;

   logic [$clog2(NUM_BUFFERS)-1:0] next_hw_idx;

   always @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         trigger <= 0;
      end else if (!trigger && (fill_level >= THRESHOLD) && write_space_left) begin
         trigger <= 1;
      end else if (trigger && m_axis_cmd_tvalid && m_axis_cmd_tready) begin
         trigger <= 0;
      end else if (flush && (fill_level > 0) && !trigger && write_space_left) begin
         trigger <= 1;
      end
   end

   always_comb begin
      buffer_end_addr = base_addr + (hw_idx)*BUFFER_SIZE + BUFFER_SIZE;
      write_amount = (flush ? fill_level : THRESHOLD);
      BTT = write_amount * (DATA_WIDTH/8);
      write_space_left = (ADDR + BTT) < buffer_end_addr;
      buffer_full = !write_space_left && (pending_cmds_count == 0);
      next_hw_idx = hw_idx == NUM_BUFFERS-1 ? 0 : hw_idx + 1;
   end

   always_comb begin
      m_axis_sts_tready = '1;
   end
   
   always @(posedge clk or negedge rstn) begin
      if (!rstn) begin
	 pending_cmds_count    = '0;
      end else begin
	 if (m_axis_cmd_tvalid && m_axis_cmd_tready) begin
	    pending_cmds_count = pending_cmds_count + 1;
	 end
	 if (m_axis_sts_tvalid && m_axis_sts_tready) begin
	    pending_cmds_count = pending_cmds_count - 1;
	 end
      end
   end

   always @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         m_axis_cmd_tvalid <= 0;
         m_axis_cmd_tdata  <= 0;
         fill_level        <= 0;
	 hw_idx            <= 0;
         ADDR              <= base_addr;
      end else begin
         if (trigger && !m_axis_cmd_tvalid) begin
            // format: {RSVD:4, TAG:4, ADDR:32, DRR:1, EOF:1, DSA:6, TYPE:1, BTT:22}
            m_axis_cmd_tdata  <= {RSVD, TAG, ADDR, DRR, EOF, DSA, TYPE, BTT};
            m_axis_cmd_tvalid <= 1;
         end else if (m_axis_cmd_tvalid && m_axis_cmd_tready) begin
            m_axis_cmd_tvalid <= 0;
            ADDR <= ADDR + BTT;
            fill_level = fill_level - write_amount;
         end else if (buffer_full && next_hw_idx != sw_idx) begin
            ADDR <= base_addr + (next_hw_idx)*BUFFER_SIZE;
	    hw_idx <= next_hw_idx;
	 end
         if (fifo_write) begin
            fill_level = fill_level + 1;
         end
      end
   end

endmodule
