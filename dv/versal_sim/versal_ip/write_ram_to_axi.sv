`default_nettype none
// assuming no writes to same address while prev write is pending
// handled outside
module write_ram_to_axi
# (
   parameter int NUM_ID_BITS = 4,
   parameter int QUEUE_DELAY = 3
   )
(
  input logic			 clk,
  input logic			 rstn,
   
  input logic			 s_req,
  input logic [3:0]		 s_be,
  input logic [31:0]		 s_addr,
  input logic [31:0]		 s_wdata,
  output logic			 s_gnt,

  output logic			 m_awvalid,
  input logic			 m_awready,
  output logic [31:0]		 m_awaddr,
  output logic [2:0]		 m_awsize,
  output logic [1:0]		 m_awburst,
  output logic [NUM_ID_BITS-1:0] m_awid,
  output logic [7:0]		 m_awlen,

  output logic			 m_wvalid,
  input logic			 m_wready,
  output logic			 m_wlast,
  output logic [31:0]		 m_wdata,
  output logic [3:0]		 m_wstrb,
  output logic [NUM_ID_BITS-1:0] m_wid,

  input logic			 m_bvalid,
  output logic			 m_bready,
  input logic [1:0]		 m_bresp,
  input logic [NUM_ID_BITS-1:0]	 m_bid
);

   logic write_ack_pending [2**NUM_ID_BITS];

   logic [NUM_ID_BITS-1:0] write_counter;
   
   typedef struct packed {
      logic [NUM_ID_BITS-1:0] write_id;
      logic [3:0] write_strb;
      logic [31:0] write_value;
   } pending_write_t;

   logic [NUM_ID_BITS+35:0] write_send_fifo_trans;
   logic [NUM_ID_BITS+35:0] write_queue_fifo_trans;

   pending_write_t write_send_trans;
   pending_write_t write_queue_trans;

   always_comb begin
      write_send_trans.write_value = write_send_fifo_trans[31:0];
      write_send_trans.write_id = write_send_fifo_trans[NUM_ID_BITS+31:32];
      write_send_trans.write_strb = write_send_fifo_trans[NUM_ID_BITS+35 -: 4];

      write_queue_fifo_trans[31:0] = write_queue_trans.write_value;
      write_queue_fifo_trans[NUM_ID_BITS+31:32] = write_queue_trans.write_id;
      write_queue_fifo_trans[NUM_ID_BITS+35 -: 4] = write_queue_trans.write_strb;
   end
   
   logic					  push_write;
   logic					  push_write_d;
   logic					  push_write_delays [QUEUE_DELAY+1];

   logic					  pop_write;

   always_ff @(posedge clk) begin
      for (int i = 1; i <= QUEUE_DELAY; i ++) begin
	 push_write_delays[i-1] <= push_write_delays[i];
      end
   end

   always_comb begin
      push_write_delays[QUEUE_DELAY] = push_write;
      push_write_d = push_write_delays[0];
   end

   logic			  write_fifo_valid;
   logic			  fifo_busy;
   logic			  next_ack_is_pending;

   always_comb begin
      next_ack_is_pending = write_ack_pending[write_counter];
      s_gnt = (!next_ack_is_pending) && m_awready && (!fifo_busy);
   end

   always_comb begin
      write_queue_trans.write_id = write_counter;
      write_queue_trans.write_value = s_wdata;
      write_queue_trans.write_strb = s_be;
      push_write = s_req && s_gnt;
      pop_write = m_wvalid && m_wready;

      m_wlast = 1;
      m_wdata = write_send_trans.write_value;
      m_wid = write_send_trans.write_id;
      m_wstrb = write_send_trans.write_strb;
      m_wvalid = write_fifo_valid;

      m_awvalid = s_req && s_gnt;
      m_awaddr = s_addr;
      m_awsize = 4;
      m_awburst = 0;
      m_awid = write_counter;
      m_awlen = 1;

      m_bready = 1;
   end

   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
	 write_counter <= 0;
      end else begin
	 if (s_req && s_gnt) begin
	    write_counter <= write_counter + 1;
	 end
      end
   end

   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
	 for (int i = 0; i < 2**NUM_ID_BITS; i ++) begin
	    write_ack_pending[i] <= 0;
	 end
      end else begin
	 if (s_req && s_gnt) begin
	    write_ack_pending[write_counter] <= 1;
	 end
	 if (m_bvalid && m_bready) begin
	    write_ack_pending[m_bid] <= 0;
	 end
      end      
   end

   // size > 2**NUM_ID_BITS
   // fallthrough mode
    fifo_wrapper #(.WIDTH(NUM_ID_BITS+36), .DEPTH(128)) 
       u_pending_writes 
     (
      .clk (clk),
      .rst (~rstn),
      .data_valid (write_fifo_valid),
      .fifo_wr_busy (fifo_busy),
      .fifo_read_rd_data (write_send_fifo_trans),
      .fifo_read_rd_en (pop_write),
      .fifo_write_wr_data (write_queue_fifo_trans),
      .fifo_write_wr_en (push_write)
      );

endmodule
