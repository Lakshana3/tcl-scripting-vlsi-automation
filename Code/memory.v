// Define a module named 'memory' with ports: CLK (clock), ADDR (address), DIN (data input), DOUT (data output)
module memory (CLK, ADDR, DIN, DOUT);

// Define parameters: wordSize (width of data) and addressSize (number of address bits)
// These can be overridden during module instantiation
parameter wordSize = 1;
parameter addressSize = 1;

// Declare input signals:
// ADDR: address to access memory
// CLK : clock signal to trigger memory operations
input ADDR, CLK;

// DIN: input data of width [wordSize - 1:0]
input [wordSize-1:0] DIN;

// DOUT: output data, declared as 'reg' since it is assigned in always block
output reg [wordSize-1:0] DOUT;

// Declare memory: an array of 2^addressSize locations
// Each location stores [wordSize:0] bits
reg [wordSize:0] mem [0:(1<<addressSize)-1];

// Always block triggered on the rising edge of CLK
// This simulates synchronous memory behavior (write and read on clock edge)
always @(posedge CLK) begin
    mem[ADDR] <= DIN;   // Write input data (DIN) to memory at address ADDR
    DOUT <= mem[ADDR];  // Read data from memory at address ADDR and output it
end

endmodule


// Add this file inside the verilog module directory
