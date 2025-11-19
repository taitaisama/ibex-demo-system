`default_nettype none
module read_ram_to_axi
# (
   parameter int NUM_ID_BITS = 4,
   parameter int READ_BURST_BITS = 2
   )
(
  input logic			     clk,
  input logic			     rstn,
   
  input logic			     s_req,
  input logic [31:0]		     s_addr,
  output logic			     s_rvalid,
  output logic [31:0]		     s_rdata,
  output logic			     s_gnt,

  output logic [NUM_ID_BITS-1:0]     info_rid,
  output logic [READ_BURST_BITS-1:0] info_rburst,

  output logic			     m_arvalid,
  input logic			     m_arready,
  output logic [31:0]		     m_araddr,
  output logic [2:0]		     m_arsize,
  output logic [1:0]		     m_arburst,
  output logic [NUM_ID_BITS-1:0]     m_arid,
  output logic [7:0]		     m_arlen,

  input logic			     m_rvalid,
  output logic			     m_rready,
  input logic			     m_rlast,
  input logic [31:0]		     m_rdata,
  input logic [1:0]		     m_rresp,
  input logic [NUM_ID_BITS-1:0]	     m_rid
);

   localparam int READ_BURST_LEN = 2**READ_BURST_BITS;

   logic [31:0]	s_addr_burst_masked;
   logic [READ_BURST_BITS-1:0] s_addr_burst_idx;

   always_comb begin
      s_addr_burst_masked = s_addr & (~(2**(READ_BURST_BITS+2)-1));
      s_addr_burst_idx = s_addr[READ_BURST_BITS+1:2];
   end

   typedef struct packed {
      logic [31:0] value;
      logic        recv_pending;
      logic	   send_pending;
   } read_t;
   
   read_t read_buffer [READ_BURST_LEN][2**NUM_ID_BITS];

   logic last_read_valid;
   logic [31:0]	last_read_addr_burst_masked;

   logic [NUM_ID_BITS-1:0] last_read_counter;
   logic [NUM_ID_BITS-1:0] this_read_counter;
   logic [NUM_ID_BITS-1:0] next_read_counter;

   typedef struct packed {
      logic [NUM_ID_BITS-1:0] read_id;
      logic [READ_BURST_BITS-1:0] read_burst_idx;
   } pending_read_t;

   pending_read_t read_send_trans;
   pending_read_t read_queue_trans;

   logic					  push_read;
   logic					  pop_read;

   logic					  read_fits_in_last_burst;
   logic					  next_read_counter_is_busy;

   logic					  read_fifo_valid;
   logic					  fifo_busy;   

   always_comb begin
      read_fits_in_last_burst = last_read_valid && (!read_buffer[s_addr_burst_idx][last_read_counter].send_pending) && read_buffer[s_addr_burst_idx][last_read_counter].recv_pending && (last_read_addr_burst_masked == s_addr_burst_masked);

      next_read_counter_is_busy = 0;
      for (int i = 0; i < READ_BURST_LEN; i ++) begin
	 if (read_buffer[i][next_read_counter].send_pending) begin
	    next_read_counter_is_busy = 1;
	 end
      end

      s_gnt = (!next_read_counter_is_busy) && m_arready && (!fifo_busy);

   end

   always_comb begin
      next_read_counter = this_read_counter + 1;
      if (read_fits_in_last_burst) begin
	 this_read_counter = last_read_counter;
      end else begin
	 this_read_counter = last_read_counter + 1;
      end
   end

   always_comb begin
      read_queue_trans.read_id = this_read_counter;
      read_queue_trans.read_burst_idx = s_addr_burst_idx;
      push_read = s_gnt && s_req;
      pop_read = s_rvalid;
   end


   // size > 2**NUM_ID_BITS * READ_BURST_LEN
   // fallthrough mode
   fifo_wrapper
     #(.WIDTH(NUM_ID_BITS+READ_BURST_BITS), .DEPTH(128))
   u_pending_reads 
     (
      .clk (clk),
      .rst (~rstn),
      .data_valid (read_fifo_valid),
      .fifo_wr_busy (fifo_busy),
      .fifo_read_rd_data (read_send_trans),
      .fifo_read_rd_en (pop_read),
      .fifo_write_wr_data (read_queue_trans),
      .fifo_write_wr_en (push_read)
      );


   logic [READ_BURST_BITS-1:0] recv_burst_idx;
   logic		       send_ready;

   always_comb begin
      send_ready = read_fifo_valid && !read_buffer[read_send_trans.read_burst_idx][read_send_trans.read_id].recv_pending;
      s_rvalid = send_ready;
      info_rid = read_send_trans.read_id;
      info_rburst = read_send_trans.read_burst_idx;
      s_rdata = read_buffer[read_send_trans.read_burst_idx][read_send_trans.read_id].value;
   end

   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
	 for (int i = 0; i < READ_BURST_LEN; i ++) begin
	    for (int j = 0; j < 2**NUM_ID_BITS; j ++) begin
	       read_buffer[i][j].value <= 'x;
	       read_buffer[i][j].recv_pending <= 0;
	       read_buffer[i][j].send_pending <= 0;
	    end
	 end
      end else begin
	 if (s_gnt && s_req) begin
	    read_buffer[s_addr_burst_idx][this_read_counter].send_pending <= 1;
	    if (!read_fits_in_last_burst) begin // send another axi req, in read_buffer set recv_pending
	       for (int i = 0; i < READ_BURST_LEN; i ++) begin
		  read_buffer[i][this_read_counter].recv_pending <= 1;
	       end
	    end
	 end
	 if (m_rvalid && m_rready) begin
	    read_buffer[recv_burst_idx][m_rid].value <= m_rdata;
	    read_buffer[recv_burst_idx][m_rid].recv_pending <= 0;
	 end
	 if (send_ready) begin
	    read_buffer[read_send_trans.read_burst_idx][read_send_trans.read_id].send_pending <= 0;
	 end
      end
   end

   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
	 recv_burst_idx <= 0;
      end else begin
	 if (m_rready && m_rvalid) begin
	    if (m_rlast) begin
	       recv_burst_idx <= 0;
	    end else begin
	       recv_burst_idx <= recv_burst_idx + 1;
	    end
	 end
      end
   end

   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
	 last_read_counter <= (2**NUM_ID_BITS)-1;
	 last_read_valid <= 0;
	 last_read_addr_burst_masked <= 'x;
      end else begin
	 if (s_gnt && s_req) begin
	    last_read_counter <= this_read_counter;
	    last_read_valid <= 1;
	    last_read_addr_burst_masked <= s_addr_burst_masked;
	 end
      end
   end

   always_comb begin
      m_arlen = READ_BURST_LEN-1;
      m_arid = this_read_counter;
      m_arburst = 1;
      m_arsize = 2;
      m_araddr = s_addr;
      m_arvalid = s_gnt && s_req && !read_fits_in_last_burst;
      m_rready = 1;
   end
   
endmodule
