
module datamover_cmd #(
    parameter		   DATA_WIDTH = 8,
    parameter		   ADDR_WIDTH = 32,
    parameter		   THRESHOLD = 32,
    parameter int          LOG2_BUFFER_SIZE = 20
)(
    input wire                        clk,
    input wire                        rstn,
  
    input wire [31:0]                 base_addr,
    input wire [LOG2_BUFFER_SIZE-1:0] sw_idx,
    output logic [LOG2_BUFFER_SIZE:0] hw_idx,

    input wire                        fifo_write,

    input wire                        flush,

    output logic [71:0]               m_axis_cmd_tdata,
    output logic                      m_axis_cmd_tvalid,
    input wire                        m_axis_cmd_tready,

    input wire [7:0]                  m_axis_sts_tdata,
    input wire                        m_axis_sts_tvalid,
    output logic                      m_axis_sts_tready
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

   logic [LOG2_BUFFER_SIZE:0]   next_cmd_send_idx;
   logic [LOG2_BUFFER_SIZE:0]   cmd_send_idx;

   logic [LOG2_BUFFER_SIZE:0]   next_hw_idx;

   always_comb begin
      write_space_left = next_cmd_send_idx != sw_idx;
      
      write_amount = (flush ? fill_level : THRESHOLD);
      BTT = write_amount * (DATA_WIDTH/8);

      next_hw_idx = hw_idx + THRESHOLD * DATA_WIDTH/8;
      next_cmd_send_idx = cmd_send_idx + THRESHOLD * DATA_WIDTH/8;

      ADDR = cmd_send_idx + base_addr;
      
      m_axis_sts_tready = '1;
   end

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

   always @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         cmd_send_idx    <= 0;
         hw_idx          <= 0;
      end else begin
	 if (m_axis_cmd_tvalid && m_axis_cmd_tready) begin
            cmd_send_idx <= next_cmd_send_idx;
	 end
	 if (m_axis_sts_tvalid && m_axis_sts_tready) begin
            hw_idx       <= next_hw_idx;
	 end
      end
   end

   always @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         m_axis_cmd_tvalid <= 0;
         m_axis_cmd_tdata  <= 0;
         fill_level        <= 0;
      end else begin
         if (trigger && !m_axis_cmd_tvalid) begin
            // format: {RSVD:4, TAG:4, ADDR:32, DRR:1, EOF:1, DSA:6, TYPE:1, BTT:22}
            m_axis_cmd_tdata  <= {RSVD, TAG, ADDR, DRR, EOF, DSA, TYPE, BTT};
            m_axis_cmd_tvalid <= 1;
         end else if (m_axis_cmd_tvalid && m_axis_cmd_tready) begin
            m_axis_cmd_tvalid <= 0;
            fill_level = fill_level - write_amount;
         end
         if (fifo_write) begin
            fill_level = fill_level + 1;
         end
      end
   end

endmodule
