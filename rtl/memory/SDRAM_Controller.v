//Dmitry Tselikov (b2m) http://bashkiria-2m.narod.ru/
//Modified by Ivan Gorodetsky 2014-2015

module SDRAM_Controller(
	input			clk,
	input			reset,
	inout	[15:0]	DRAM_DQ,
	output	reg[11:0]	DRAM_ADDR,
	output	reg		DRAM_LDQM,
	output	reg		DRAM_UDQM,
	output	reg		DRAM_WE_N,
	output	reg		DRAM_CAS_N,
	output	reg		DRAM_RAS_N,
	output			DRAM_CS_N,
	output			DRAM_BA_0,
	output			DRAM_BA_1,
	input	[21:0]	iaddr,
	input	[15:0]	dataw,
	input			rd,
	input			we_n,
	input ilb_n,
	input iub_n,
	output	reg [15:0]	datar,
	output reg membusy
);

parameter ST_RESET0 = 4'd0;
parameter ST_RESET1 = 4'd1;
parameter ST_IDLE   = 4'd2;
parameter ST_RAS0   = 4'd3;
parameter ST_RAS1   = 4'd4;
parameter ST_READ0  = 4'd5;
parameter ST_READ1  = 4'd6;
parameter ST_READ2  = 4'd7;
parameter ST_WRITE0 = 4'd8;
parameter ST_WRITE1 = 4'd9;
parameter ST_WRITE2 = 4'd10;
parameter ST_REFRESH0 = 4'd11;
parameter ST_REFRESH1 = 4'd12;
parameter ST_REFRESH2 = 4'd13;
parameter ST_REFRESH3 = 4'd14;

reg[3:0] state;
reg[9:0] refreshcnt;
reg[21:0] addr;
reg[15:0] odata;
reg refreshflg,exrd,exwen;
reg lb_n,ub_n;

assign DRAM_DQ = state == ST_WRITE0 ? odata : 16'bZZZZZZZZZZZZZZZZ;

assign DRAM_CS_N = reset;
assign DRAM_BA_0 = addr[20];
assign DRAM_BA_1 = addr[21];

always @(*) begin
	case (state)
	ST_RESET0: DRAM_ADDR = 12'b100000;
	ST_RAS0:   DRAM_ADDR = addr[19:8];
	ST_READ0:   DRAM_ADDR = {4'b0100,addr[7:0]};
	ST_WRITE0:   DRAM_ADDR = {4'b0100,addr[7:0]};
	endcase
	case (state)
	ST_RESET0:   {DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N} = 3'b000;
	ST_RAS0:     {DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N} = 3'b011;
	ST_READ0:    {DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N,DRAM_UDQM,DRAM_LDQM} = 5'b10100;
	ST_WRITE0:   {DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N,DRAM_UDQM,DRAM_LDQM} = {3'b100,ub_n,lb_n};
	ST_WRITE2:   {DRAM_UDQM,DRAM_LDQM} = 2'b00;
	ST_REFRESH0: {DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N} = 3'b001;
	default:     {DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N} = 3'b111;
	endcase
end

always @(posedge clk) begin
	refreshcnt <= refreshcnt + 10'b1;
	if (reset) begin
		state <= ST_RESET0; exrd <= 0; exwen <= 1'b1;
		membusy<=1'b0;
		refreshflg<=1'b0;
	end else begin
		case (state)
		ST_RESET0: state <= ST_RESET1;
		ST_RESET1: state <= ST_IDLE;
		ST_IDLE:
		if (refreshcnt[9]!=refreshflg) state <= ST_REFRESH0; else
		begin
			exrd <= rd; exwen <= we_n;
			membusy<=1'b0;
			{addr[17:0],odata,ub_n,lb_n}<={iaddr[17:0],dataw,iub_n,ilb_n};
			casex ({rd,exrd,we_n,exwen})
			4'b1011: state <= ST_RAS0;
			4'b0001: state <= ST_RAS0;
			default: state <= ST_IDLE;
			endcase
		end
		ST_RAS0: state <= ST_RAS1;
		ST_RAS1:
			casex ({exrd,exwen})
			2'b11: {state,membusy} <= {ST_READ0,1'b1};
			2'b00: {state,membusy} <= {ST_WRITE0,1'b1};
			default: state <= ST_IDLE;
			endcase
		ST_READ0: state <= ST_READ1;
		ST_READ1: state <= ST_READ2;
		ST_READ2:
		begin
			state<=ST_IDLE;
			if(lb_n==1'b0)datar[7:0]<=DRAM_DQ[7:0];
			if(ub_n==1'b0)datar[15:8]<=DRAM_DQ[15:8];
		end
		ST_WRITE0: state <= ST_WRITE1;
		ST_WRITE1: state <= ST_WRITE2;
		ST_WRITE2: state <= ST_IDLE;
		ST_REFRESH0: {state,refreshflg,membusy} <= {ST_REFRESH1,refreshcnt[9],1'b1};
		ST_REFRESH1: state <= ST_REFRESH3;
		ST_REFRESH2: state <= ST_REFRESH3;
		ST_REFRESH3: state <= ST_IDLE;
		default: state <= ST_IDLE;
		endcase
	end
end
	
endmodule
