//good at 120 and 150 MHz

module SRAM_Controller(
	input			clk,				//  Clock 150MHz
	input			reset,					//  System reset
	inout	[15:0]	SRAM_DQ,				//	SRAM Data bus (only) 8 Bits
	output reg[17:0]	SRAM_ADDR,			//	SRAM Address bus 18 Bits
	output reg			SRAM_LB_N,				//	SRAM Low-byte Data Mask 
	output reg			SRAM_UB_N,				//	SRAM High-byte Data Mask
	output	reg		SRAM_WE_N,				//	SRAM Write Enable
	output		SRAM_OE_N,				//	SRAM Output Enable
	output			SRAM_CE_N,				//	SRAM Chip Enable
	input	[17:0] iaddr,
	input	[15:0] dataw,
	output reg[15:0] datar,
	input ilb_n,
	input iub_n,
	input			rd,
	input			we_n
);

parameter ST_RESET = 4'd0;
parameter ST_IDLE   = 4'd1;
parameter ST_PRERW   = 4'd2;
parameter ST_READ0  = 4'd3;
parameter ST_READ1  = 4'd4;
parameter ST_READ2  = 4'd5;
parameter ST_WRITE0 = 4'd6;
parameter ST_WRITE1 = 4'd7;
parameter ST_WRITE2 = 4'd8;
parameter ST_READV0  = 4'd9;
parameter ST_READV1  = 4'd10;
parameter ST_READV2  = 4'd11;
parameter ST_READV3  = 4'd12;

//assign iodata[7:0]=(rd&&~ilb_n)?idata[7:0]:8'bz;
//assign iodata[15:8]=(rd&&~iub_n)?idata[15:8]:8'bz;
reg[3:0] state;
reg[17:0] addr;
//reg[15:0] odata,idata;
reg[15:0] odata;
reg exrd,exwen,lb_n,ub_n;

assign SRAM_DQ[7:0] = (state==ST_WRITE1) ? odata[7:0] : 8'bZZZZZZZZ;
assign SRAM_DQ[15:8] = (state == ST_WRITE1) ? odata[15:8] : 8'bZZZZZZZZ;
assign SRAM_OE_N = 0;
//assign SRAM_CE_N = reset;
assign SRAM_CE_N=1'b0;


always @(posedge clk) begin
	if (reset) begin
//	if (0) begin
		state <= ST_RESET; exrd <= 0; exwen <= 1'b1;
	end else begin
		case (state)
		ST_RESET: {state,SRAM_WE_N} <= {ST_IDLE,1'b1};
		ST_IDLE: begin
			{addr[17:0],odata,ub_n,lb_n}<={iaddr[17:0],dataw,iub_n,ilb_n};
//			{addr[17:0],ub_n,lb_n}<={iaddr[17:0],iub_n,ilb_n};
			SRAM_WE_N <= 1'b1;
			{exrd,exwen} <= {rd,we_n};
			casex ({rd,exrd,we_n,exwen})
			4'b1011: {state} <= {ST_PRERW};
			4'b0001: {state} <= {ST_PRERW};
			default: state <= ST_IDLE;
			endcase
		end
		ST_PRERW:
			casex ({exrd,exwen})
			2'b11: {state,SRAM_ADDR,SRAM_UB_N,SRAM_LB_N} <= {ST_READ0,addr,ub_n,lb_n};
			2'b00: {state,SRAM_ADDR,SRAM_WE_N,SRAM_UB_N,SRAM_LB_N} <= {ST_WRITE0,addr,1'b0,ub_n,lb_n};
			default: state <= ST_IDLE;
			endcase
		ST_READ0: state <= ST_READ1;
		ST_READ1: state <= ST_READ2;
		ST_READ2:
		begin
			state<=ST_IDLE;
			if(lb_n==1'b0)datar[7:0]<=SRAM_DQ[7:0];
			if(ub_n==1'b0)datar[15:8]<=SRAM_DQ[15:8];
		end
		ST_WRITE0: state <= ST_WRITE1;
		ST_WRITE1: state <= ST_WRITE2;
		ST_WRITE2: state <= ST_IDLE;
		default: state <= ST_IDLE;
		endcase
	end
end

endmodule
