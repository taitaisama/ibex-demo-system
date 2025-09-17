module datamover_cmd #(
    parameter DATA_WIDTH   = 8,
    parameter ADDR_WIDTH   = 32,
    parameter THRESHOLD    = 32
)(
    input logic		clk,
    input logic		rstn,
  
    input logic [31:0]	start_addr,
    output logic [31:0]	end_addr,

    input logic		fifo_write,

    input logic		flush,

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

   logic [31:0] fifo_rd_data;
   logic	fifo_rd_en, fifo_wr_en;
   
   
   fifo_wrapper #(.WIDTH(32), .DEPTH(128)) u_addr_fifo
     (
      .clk (clk),
      .rst (~rstn),
      
      .fifo_read_rd_data (fifo_rd_data),
      .fifo_read_rd_en (fifo_rd_en),
      .fifo_write_wr_data (ADDR),
      .fifo_write_wr_en (fifo_wr_en)
      );


   always_comb begin
      fifo_rd_en = m_axis_sts_tready && m_axis_sts_tvalid;
      fifo_wr_en = m_axis_cmd_tready && m_axis_cmd_tvalid;
      m_axis_sts_tready = 1;
   end

   always @(posedge clk or negedge rstn) begin
      if (!rstn) begin
	 end_addr <= start_addr;
      end else begin
	 if (fifo_rd_en) begin
	    end_addr <= fifo_rd_data;
	 end
      end
   end

   always @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         m_axis_cmd_tvalid <= 0;
         m_axis_cmd_tdata  <= 0;
         fill_level <= 0;
         ADDR <= start_addr;
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
