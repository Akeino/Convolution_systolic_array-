`timescale 1ns / 1ps
module CNN(
	input clk,
	input rst,
	
	input start,
	output reg complete,
	
	output [31:0] I_ram_addr,
    output I_ram_clk,
    output [31:0] I_ram_din,
    input [31:0] I_ram_dout,
    output I_ram_en,
    output I_ram_rst,
    output [3:0] I_ram_we,
        
    output [31:0] W_ram_addr,
    output W_ram_clk,
    output [31:0] W_ram_din,
    input [31:0] W_ram_dout,
    output W_ram_en,
    output W_ram_rst,
    output [3:0] W_ram_we,
        
    output [31:0] B_ram_addr,
    output B_ram_clk,
    output [31:0] B_ram_din,
    input [31:0] B_ram_dout,
    output B_ram_en,
    output B_ram_rst,
    output [3:0] B_ram_we,
        
    output [31:0] O_ram_addr,
    output O_ram_clk,
    output [31:0] O_ram_din,
    input [31:0] O_ram_dout,
    output O_ram_en,
    output O_ram_rst,
    output [3:0] O_ram_we
);
parameter N = 3;
parameter M = 3;
parameter R = 28;
parameter C = 28;
parameter S = 1;
parameter K = 4;
parameter Rprime = R*S-K+1;
parameter Cprime = C*S-K+1;

//RAM Controller
reg [31:0] O_din;
reg O_wren, O_wren_next;
reg [31:0] O_addr=0;

reg [31:0] W_addr=0, W_addr_next=0;
reg [31:0] I_i_addr=0, I_i_addr_next=0;
reg [31:0] I_j_addr=0, I_j_addr_next=0;
reg [31:0] I_n_addr=0, I_n_addr_next=0;
reg [31:0] I_addr;
reg [31:0] B_addr=0, B_addr_next=0;

wire [31:0] I_dout, W_dout, B_dout;
integer j;

assign I_ram_addr = I_addr << 2;
assign I_ram_clk = clk;
assign I_ram_din = 32'b0;
assign I_dout = I_ram_dout;
assign I_ram_en = 1'b1;
assign I_ram_rst = 1'b0;
assign I_ram_we = 4'h0;

assign W_ram_addr = W_addr << 2;
assign W_ram_clk = clk;
assign W_ram_din = 32'b0;
assign W_dout = W_ram_dout;
assign W_ram_en = 1'b1;
assign W_ram_rst = 1'b0;
assign W_ram_we = 4'h0;

assign B_ram_addr = B_addr << 2;
assign B_ram_clk = clk;
assign B_ram_din = 32'b0;
assign B_dout = B_ram_dout;
assign B_ram_en = 1'b1;
assign B_ram_rst = 1'b0;
assign B_ram_we = 4'h0;

assign O_ram_addr = O_addr << 2;
assign O_ram_clk = clk;
assign O_ram_din = O_din;
assign O_ram_en = 1'b1;
assign O_ram_rst = 1'b0;
assign O_ram_we = 4'hF;

always @(posedge clk)
begin
	if (rst)
		O_addr <= 0;
	else
	if (O_wren)
		begin
			O_addr <= O_addr + 1;
		end
end

//PE Archiecture (Data path)
genvar i;
reg [31:0] S_in[0:K*K*N/4-1], W_in[0:K*K*N/4-1], X_in[0:K*K*N/4-1];
wire [31:0] S_out[0:K*K*N/4-1];
generate 
	for (i = 0; i < K*K*N/4; i = i + 1)
        begin
            PE PE_inst(clk, S_in[i], W_in[i], X_in[i], S_out[i]);
        end
endgenerate

reg [3:0] state=0, state_next=0;
reg [31:0] cur_addr=0, cur_addr_next=0;

reg [31:0] r_out=0, r_out_next=0;
reg [31:0] c_out=0, c_out_next=0;
reg [31:0] m_out=0, m_out_next=0;

reg [31:0] cur_out=0, cur_out_next=0;

always @(posedge clk)
begin
	if (rst)
		begin
			state <= 0;
			
			W_addr <= 0;
			B_addr <= 0;
			
			I_i_addr <= 0;
			I_j_addr <= 0;
			I_n_addr <= 0;
			
			cur_addr <= 0;
			
			r_out <= 0;
			c_out <= 0;
			m_out <= 0;
			
			cur_out <= 0;
			
			O_wren <= 0;
		end
	else
		begin
			state <= state_next;
			
			W_addr <= W_addr_next;
			B_addr <= B_addr_next;
			
			I_i_addr <= I_i_addr_next;
			I_j_addr <= I_j_addr_next;
			I_n_addr <= I_n_addr_next;
			
			cur_addr <= cur_addr_next;
			
			r_out <= r_out_next;
			c_out <= c_out_next;
			m_out <= m_out_next;
			
			cur_out <= cur_out_next;
			
			O_wren <= O_wren_next;
		end
end

always @*
begin
	state_next = state;
	complete = 0;
	
	W_addr_next = W_addr;
	B_addr_next = B_addr;
	I_i_addr_next = I_i_addr;
	I_j_addr_next = I_j_addr;
	I_n_addr_next = I_n_addr;
	
	I_addr = I_n_addr*R*C+(r_out+I_i_addr)*R+(c_out+I_j_addr);
	
	cur_addr_next = cur_addr;
	
	r_out_next = r_out;
	c_out_next = c_out;
	m_out_next = m_out;
	
	cur_out_next = cur_out;
	
	O_din = S_out[11];
	O_wren_next = 0;
	
	
	for (j = 0; j < 12; j = j + 1)
		begin
			S_in[j] = 0;
			W_in[j] = 0;
			X_in[j] = 0;
		end
	
	case (state)
		0: 
			if (start)
				begin
					state_next = 1;
	
					W_addr_next = W_addr + 1;
					
					I_n_addr_next = I_n_addr;
					I_i_addr_next = I_i_addr;
					I_j_addr_next = I_j_addr + 1;
				end
		1:
			begin
				S_in[0] = B_dout;
				W_in[0] = W_dout;
				X_in[0] = I_dout;
	
				W_addr_next = W_addr + 1;
					
				I_n_addr_next = I_n_addr;
				I_i_addr_next = I_i_addr;
				I_j_addr_next = I_j_addr + 1;
				
				cur_addr_next = cur_addr + 1;
				
				state_next = state + 1;
			end
		2:
			begin
				if (cur_addr == K*K*N/4)
					begin
						S_in[0] = S_out[cur_addr-1];
						W_in[0] = W_dout;
						X_in[0] = I_dout;
					end
				else
				if (cur_addr == K*K*N/2)
					begin
						S_in[0] = S_out[cur_addr-K*K*N/4-1];
						W_in[0] = W_dout;
						X_in[0] = I_dout;
					end
				else
				if (cur_addr == K*K*N*3/4)
					begin
						S_in[0] = S_out[cur_addr-K*K*N/2-1];
						W_in[0] = W_dout;
						X_in[0] = I_dout;
					end
				else
				if (cur_addr < K*K*N/4)
					begin
						S_in[cur_addr] = S_out[cur_addr-1];
						W_in[cur_addr] = W_dout;
						X_in[cur_addr] = I_dout;
					end
				else
				if (cur_addr < K*K*N/2)
					begin
						S_in[cur_addr-K*K*N/4] = S_out[cur_addr-K*K*N/4-1];
						W_in[cur_addr-K*K*N/4] = W_dout;
						X_in[cur_addr-K*K*N/4] = I_dout;
					end
				else
				if (cur_addr < K*K*N*3/4)
					begin
						S_in[cur_addr-K*K*N/2] = S_out[cur_addr-K*K*N/2-1];
						W_in[cur_addr-K*K*N/2] = W_dout;
						X_in[cur_addr-K*K*N/2] = I_dout;
					end
				else
					begin
						S_in[cur_addr-K*K*N*3/4] = S_out[cur_addr-K*K*N*3/4-1];
						W_in[cur_addr-K*K*N*3/4] = W_dout;
						X_in[cur_addr-K*K*N*3/4] = I_dout;
					end
				
				W_addr_next = W_addr + 1;
				if (cur_addr == K*K*N-2)
					begin						
						W_addr_next = B_addr*N*K*K;
						if (r_out == Rprime-1 && c_out == Cprime-1)
							begin
								W_addr_next = (B_addr+1)*N*K*K;
								if (B_addr == M-1)
									begin
										B_addr_next = 0;
									end
								else
									begin
										B_addr_next = B_addr + 1;
									end
							end
							
						if (c_out == Cprime-1)
							begin
								c_out_next = 0;
								if (r_out == Rprime-1)
									r_out_next = 0;
								else
									r_out_next = r_out + 1;
							end
						else
							begin
								c_out_next = c_out + 1;
							end
					end
				
				if (I_j_addr == K-1)
					begin
						I_j_addr_next = 0;
						
						if (I_i_addr == K-1)
							begin
								I_i_addr_next = 0;
								if (I_n_addr == N-1)
									I_n_addr_next = 0;
								else
									I_n_addr_next = I_n_addr + 1;
							end
						else
							I_i_addr_next = I_i_addr + 1;
					end
				else
					I_j_addr_next = I_j_addr + 1;
				
				if (cur_addr == K*K*N-1)
					begin
						cur_addr_next = 0;
						O_wren_next = 1;
						state_next = 1;
							
						if (cur_out == Rprime*Cprime*M-1)
							begin
								state_next = 3;
								cur_out_next = 0;
							end
						else
							begin
								cur_out_next = cur_out + 1;
							end
					end
				else
					begin
						cur_addr_next = cur_addr + 1;
					end
			end
		3:
			begin
				complete = 1;
			end
		endcase
end


endmodule
///////////////////////////////////////
module PE(
	input clk,
	
	input signed [31:0] S_in,
	input signed [31:0] W_in,
	input signed [31:0] X_in,
	
	output reg signed [31:0] S_out
);
wire signed [63:0] temp = X_in * W_in;

always @(posedge clk)
begin
	S_out <= temp[31:0] + S_in;
end

endmodule
