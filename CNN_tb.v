`timescale 1ns / 1ps
module CNN_tb;

	// Inputs
	reg clk;
	reg rst;
	reg start;

	// Outputs
	wire complete;
	
	wire [31:0] I_addr;
	wire [31:0] W_addr;
	wire [31:0] B_addr;
	
	reg [31:0] I_dout;
	reg [31:0] W_dout;
	reg [31:0] B_dout;
	
	wire [31:0] O_din;
	wire O_wren;

	// Instantiate the Unit Under Test (UUT)
	CNN uut (
		.clk(clk), 
		.rst(rst), 
		.start(start), 
		.complete(complete),
		.I_addr(I_addr),
		.W_addr(W_addr),
		.B_addr(B_addr),
		.I_dout(I_dout),
		.W_dout(W_dout),
		.B_dout(B_dout),
		.O_din(O_din),
		.O_wren(O_wren)
	);

	parameter N = 3;
	parameter M = 3;
	parameter R = 28;
	parameter C = 28;
	parameter S = 1;
	parameter K = 4;
	parameter Rprime = R*S-K+1;
	parameter Cprime = C*S-K+1;


	reg [31:0] I_mem[0:N*R*C-1];
	reg [31:0] W_mem[0:N*M*R*C-1];
	reg [31:0] B_mem[0:M-1];
	reg [31:0] O_mem_expected[0:M*Rprime*Cprime-1];
	
	initial
	begin
		$readmemh("C:/Users/akein/Desktop/Test/ip_inputs.txt", I_mem);
		$readmemh("C:/Users/akein/Desktop/Test/ip_weights.txt", W_mem);
		$readmemh("C:/Users/akein/Desktop/Test/ip_biases.txt", B_mem);
		$readmemh("C:/Users/akein/Desktop/Test/op.txt", O_mem_expected);
	end
	
	reg error = 0;
	reg [31:0] O_addr=0;
	
	always @(posedge clk)
	begin
		I_dout <= I_mem[I_addr];
		W_dout <= W_mem[W_addr];
		B_dout <= B_mem[B_addr];
		
		if (rst)
			O_addr <= 0;
		else
		if (O_wren)
			begin
				O_addr <= O_addr + 1;
				if (O_din != O_mem_expected[O_addr])
					error <= 1;
				

			end
	end
	
	
	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 1;
		start = 0;

		// Wait 100 ns for global reset to finish
		#100;
		rst = 0;
		#100;
		start = 1;
		#20;
		start = 0;
        
		// Add stimulus here

	end
	
	always #10 clk = ~clk;
	
	
	always @(posedge clk)
	   if (O_wren)
	       $display("Outdata %x error = %x \n", O_din, error);
      
endmodule

