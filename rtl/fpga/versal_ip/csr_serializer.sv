

module csr_serializer #(parameter int NUM_WORDS, parameter int WIDTH)
(
 input wire                            clk,
 input wire                            rstn,
 input wire [WIDTH-1:0]                data_i [NUM_WORDS],
 input wire                            valid_i,
 output logic [WIDTH-1:0]               data_o,
 output logic [$clog2(NUM_WORDS+1)-1:0] addr_o,
 output logic                           ready_o,
 output logic                           valid_o
 );

   logic [WIDTH-1:0]               prev_buffer [NUM_WORDS];
   logic [WIDTH-1:0]               buffer [NUM_WORDS];

   logic                           differ [NUM_WORDS];
   logic [$clog2(NUM_WORDS)-1:0]   first_differ;
   logic [$clog2(NUM_WORDS)-1:0]   differ_count;

   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         for (int i = 0; i < NUM_WORDS; i ++) begin
            prev_buffer[i] <= '0;
            buffer[i] <= '0;
            data_o <= 'x;
            addr_o <= 'x;
         end
      end else begin
         addr_o <= 'x;
         data_o <= 'x;
         if (valid_i) begin
            for (int i = 0; i < NUM_WORDS; i ++) begin
               buffer[i] <= data_i[i];
            end
         end
         if (differ_count > 0) begin // there is pending data
            addr_o <= first_differ;
            data_o <= buffer[first_differ];
            prev_buffer[first_differ] <= buffer[first_differ];
         end
	 valid_o <= (differ_count > 0);
      end
   end

   always_comb begin
      first_differ = 'x;
      differ_count = 0;
      for (int i = NUM_WORDS-1; i >= 0; i --) begin
         differ[i] = (prev_buffer[i] != buffer[i]);
         if (differ[i]) begin
            first_differ = i;
	    differ_count += 1;
         end
      end
      ready_o = (differ_count <= 1);
   end

endmodule
