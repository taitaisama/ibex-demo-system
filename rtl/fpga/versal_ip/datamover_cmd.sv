module datamover_cmd #(
    parameter DATA_WIDTH   = 8,
    parameter ADDR_WIDTH   = 32,
    parameter START_ADDR   = 32'hC000_0000,
    parameter THRESHOLD    = 32
)(
    input logic         clk,
    input logic         rstn,
  
    input logic         fifo_write,

    input logic         flush,

    output logic [71:0] m_axis_cmd_tdata,
    output logic        m_axis_cmd_tvalid,
    input logic         m_axis_cmd_tready
);

   logic trigger;
   logic [31:0] fill_level;
   logic [31:0]	write_amount;

   always @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         trigger <= 0;
      end else if (!trigger && (fill_level >= THRESHOLD)) begin
         trigger <= 1;
      end else if (trigger && m_axis_cmd_tvalid && m_axis_cmd_tready) begin
         trigger <= 0;
      end else if (flush && (fill_level > 0) && !trigger) begin
         trigger <= 1;
      end
   end

   localparam logic [3:0]       RSVD = 0;
   localparam logic [3:0]       TAG = 0;
   localparam logic             DRR = 0;
   localparam logic             EOF = 0;
   localparam logic [5:0]       DSA = 0;
   localparam logic             TYPE = 1;

   logic [22:0]                 BTT;
   logic [ADDR_WIDTH-1:0]       ADDR;
   always_comb begin
      write_amount = (flush ? fill_level : THRESHOLD);
      BTT = write_amount * (DATA_WIDTH/8);
   end

   always @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         m_axis_cmd_tvalid <= 0;
         m_axis_cmd_tdata  <= 0;
         fill_level <= 0;
         ADDR <= START_ADDR;
      end else begin
         if (trigger && !m_axis_cmd_tvalid) begin
            // format: {RSVD:4, TAG:4, ADDR:32, DRR:1, EOF:1, DSA:6, TYPE:1, BTT:22}
            m_axis_cmd_tdata  <= {RSVD, TAG, ADDR, DRR, EOF, DSA, TYPE, BTT};
            m_axis_cmd_tvalid <= 1;
         end else if (m_axis_cmd_tvalid && m_axis_cmd_tready) begin
            m_axis_cmd_tvalid <= 0;
            ADDR <= ADDR + BTT;
            fill_level = fill_level - write_amount;
         end
         if (fifo_write) begin
            fill_level = fill_level + 1;
         end
      end
   end

endmodule
