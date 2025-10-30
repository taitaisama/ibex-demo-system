module datamover_cmd #(
    parameter DATA_WIDTH   = 8,
    parameter ADDR_WIDTH   = 32,
    parameter THRESHOLD    = 32
)(
    input logic		clk,
    input logic		rstn,
  
    input logic [31:0]	start_addr,
    input logic [31:0]	end_addr,
    output logic [31:0]	curr_addr,

    input logic		fifo_write,

    input logic		flush,
    output logic	full,
    input logic		rst_addr_parity,	// reset address iff no space is left

    output logic [71:0]	m_axis_cmd_tdata,
    output logic	m_axis_cmd_tvalid,
    input logic		m_axis_cmd_tready,

    input logic [7:0]	m_axis_sts_tdata,
    input logic		m_axis_sts_tvalid,
    output logic	m_axis_sts_tready
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
      write_amount = (flush ? fill_level : THRESHOLD);
      BTT = write_amount * (DATA_WIDTH/8);
      write_space_left = (ADDR + BTT) < end_addr;
      full = !write_space_left && (curr_addr == ADDR);
   end

   logic [31:0] fifo_rd_data;
   logic	fifo_rd_en, fifo_wr_en;

   logic	m_axis_cmd_pending, fifo_almost_full, fifo_data_valid;

   logic	rst_addr_parity_d, rst_addr_pulse;

   always_ff @(posedge clk) begin
      rst_addr_parity_d <= rst_addr_parity;
   end

   always_comb rst_addr_pulse = rst_addr_parity_d ^ rst_addr_parity;
   
   fifo_wrapper #(.WIDTH(32), .DEPTH(128)) u_addr_fifo
     (
      .clk (clk),
      .rst (~rstn),

      .data_valid (fifo_data_valid),
      .fifo_almost_full (fifo_almost_full),
      .fifo_read_rd_data (fifo_rd_data),
      .fifo_read_rd_en (fifo_rd_en),
      .fifo_write_wr_data (ADDR),
      .fifo_write_wr_en (fifo_wr_en)
      );

   always_comb begin
      fifo_rd_en = m_axis_sts_tready && m_axis_sts_tvalid;
      fifo_wr_en = m_axis_cmd_tready && m_axis_cmd_tvalid;
      m_axis_sts_tready = fifo_data_valid;

      m_axis_cmd_tvalid = m_axis_cmd_pending && !fifo_almost_full;
   end

   always @(posedge clk or negedge rstn) begin
      if (!rstn) begin
	 curr_addr <= start_addr;
      end else begin
	 if (fifo_rd_en) begin
	    curr_addr <= fifo_rd_data;
	 end else if (!write_space_left && rst_addr_pulse) begin
	    curr_addr <= start_addr;
	 end
      end
   end

   always @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         m_axis_cmd_pending <= 0;
         m_axis_cmd_tdata  <= 0;
         fill_level <= 0;
         ADDR <= start_addr;
      end else begin
         if (trigger && !m_axis_cmd_pending) begin
            // format: {RSVD:4, TAG:4, ADDR:32, DRR:1, EOF:1, DSA:6, TYPE:1, BTT:22}
            m_axis_cmd_tdata  <= {RSVD, TAG, ADDR, DRR, EOF, DSA, TYPE, BTT};
            m_axis_cmd_pending <= 1;
         end else if (m_axis_cmd_tvalid && m_axis_cmd_tready) begin
            m_axis_cmd_pending <= 0;
            ADDR <= ADDR + BTT;
            fill_level = fill_level - write_amount;
         end else if (!write_space_left && rst_addr_pulse) begin
            ADDR <= start_addr;
	 end
         if (fifo_write) begin
            fill_level = fill_level + 1;
         end
      end
   end

endmodule
