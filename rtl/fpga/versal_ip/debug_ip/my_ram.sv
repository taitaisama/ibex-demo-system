`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/18/2025 08:24:33 PM
// Design Name: 
// Module Name: my_ram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module my_ram (
    input logic clk,
    input logic [12:0] addr,
    output logic [31:0] dout
);

    parameter DATA_WIDTH = 32;
    parameter DEPTH = 2048;

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Initialize RAM from file
    initial begin
        $readmemh("/home/ramanuj/dev/ibex-demo-system/sw/vitis/prog.mem", mem);
    end

    // RAM write operation
    always_ff @(posedge clk) begin
        dout <= mem[addr[12:2]];
    end

    // RAM read operation

endmodule