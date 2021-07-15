
//经过仿真得出此寻峰算法将在local_rdata开始输出和local_rdata_valid拉高的第六个时钟产生最大值
//在第六个时钟产生最大值的地址

module cmp(
	input phy_clk,
	input reset_phy_clk_n,
	input wire [63:0]local_rdata,
	input wire local_rdata_valid,
	input wire local_init_done,
//	output wire fo_big_1,
//	output wire fo_equal_1,
//	output wire fo_small_1,
//	output wire fo_big_2,
//	output wire fo_equal_2,
//	output wire fo_small_2,
//	output wire fo_big_3,
//	output wire fo_equal_3,
//	output wire fo_small_3,
//	output wire fo_big_4,
//	output wire fo_equal_4,
//	output wire fo_small_4,	
	output reg [15:0]data_big_1,//低位两个数据比较得出的最大值
	output reg [15:0]data_big_2,//高位两个数据比较得出的最大值
	output reg [15:0]data_big_best,//四个数据比较得出的最大值
//	output reg [15:0]data_big_best_reg,
	output reg [15:0]bestdata,
	output reg [15:0]addr_final,
	output reg [15:0]cnt,
	output reg [15:0]addr1,
	output reg [15:0]addr2,
	output reg [15:0]addr3,
	output reg [15:0]addr4
);
//	reg [15:0]cnt;
	reg cnt_fault;
//	reg [15:0]addr1;
//	reg [15:0]addr2;
//	reg [15:0]addr3;
//	reg [15:0]addr4;
	reg [15:0]addr_big_1;
	reg [15:0]addr_big_2;
	reg [15:0]addr_best;
//	reg [15:0]addr_best_reg;
	wire local_rdata_valid_reg/*synthesis keep*/;
	
//	reg [15:0]reg1;
//	reg [15:0]reg2;
//	reg [15:0]reg3;
//	reg [15:0]reg4;
	reg [15:0]data1;
	reg [15:0]data2;
	reg [15:0]data3;
	reg [15:0]data4;
	
(*noprune*) reg err;	
(*noprune*) reg [15:0]err_cnt;	
(*noprune*)	reg [15:0]data_top;
(*noprune*)	reg [15:0]addr_top;
	reg out;
	reg [15:0]cnt_delay;
//	reg [15:0]data_big_1;
//	reg [15:0]data_big_2;
	wire [2:0]state_1;
	wire [2:0]state_2;
	wire [2:0]state_3;
	wire [2:0]state_4;
	wire fo_big_1;
	wire fo_equal_1;
	wire fo_small_1;
	wire fo_big_2;
	wire fo_equal_2;
	wire fo_small_2;
	wire fo_big_3;
	wire fo_equal_3;
	wire fo_small_3;
	wire fo_big_4;
	wire fo_equal_4;
	wire fo_small_4;	
	
assign state_1 = {fo_big_1,fo_equal_1,fo_small_1};
assign state_2 = {fo_big_2,fo_equal_2,fo_small_2};
assign state_3 = {fo_big_3,fo_equal_3,fo_small_3};
assign state_4 = {fo_big_4,fo_equal_4,fo_small_4};
//test singal
always@(posedge phy_clk or negedge reset_phy_clk_n)
		if(!reset_phy_clk_n)
			err_cnt <= 16'd0;
		else if(bestdata != addr_final)
			err_cnt <= err_cnt + 16'd1;
		else
			err_cnt <= err_cnt;

always@(posedge phy_clk or negedge reset_phy_clk_n)
		if(!reset_phy_clk_n)
			err <= 1'b0;
		else if(err_cnt >= 16'd1)
			err <= 1'b1;
		else
			err <= err;
//

always@(posedge phy_clk or negedge reset_phy_clk_n)
		if(!reset_phy_clk_n)begin
			data1 <= 16'd0;
			data2 <= 16'd0;
			data3 <= 16'd0;
			data4 <= 16'd0;
		end
		else if(local_rdata_valid_reg && cnt_fault == 1'b1)begin
			data1 <= local_rdata[15:0];
			data2 <= local_rdata[31:16];
			data3 <= local_rdata[47:32];
			data4 <= local_rdata[63:48];
		end
		else begin
			data1 <= 16'd0;
			data2 <= 16'd0;
			data3 <= 16'd0;
			data4 <= 16'd0;
		end
		
//always@(posedge phy_clk or negedge reset_phy_clk_n)
//		if(!reset_phy_clk_n)
//			local_rdata_valid_reg <= 1'b0;
//		else
//			local_rdata_valid_reg <= local_rdata_valid && local_init_done;
assign 	local_rdata_valid_reg = local_rdata_valid && local_init_done;	
always@(posedge phy_clk or negedge reset_phy_clk_n)
		if(!reset_phy_clk_n)
			data_big_1 <= 16'd0;
		else begin
			case(state_1)
				3'b100:  data_big_1 <= data1;
				3'b010:  data_big_1 <= data1;
				3'b001:  data_big_1 <= data2;
				default: data_big_1 <= data_big_1;
			endcase
		end

always@(posedge phy_clk or negedge reset_phy_clk_n)
		if(!reset_phy_clk_n)
			data_big_2 <= 16'd0;
		else begin
			case(state_2)
				3'b100:  data_big_2 <= data3;
				3'b010:  data_big_2 <= data3;
				3'b001:  data_big_2 <= data4;
				default: data_big_2 <= data_big_2;
			endcase
		end

always@(posedge phy_clk or negedge reset_phy_clk_n)
		if(!reset_phy_clk_n)
			data_big_best <= 16'd0;
		else begin
			case(state_3)
				3'b100:  data_big_best <= data_big_1;
				3'b010:  data_big_best <= data_big_1;
				3'b001:  data_big_best <= data_big_2;
				default: data_big_best <= data_big_best;
			endcase
		end

//always@(posedge phy_clk or negedge reset_phy_clk_n)
//		if(!reset_phy_clk_n)
//			data_big_best_reg <= 16'd0;
//		else 
//			data_big_best_reg <= data_big_best;
		
always@(posedge phy_clk or negedge reset_phy_clk_n)
		if(!reset_phy_clk_n)
			bestdata <= 16'd0;
		else if(cnt_delay == 16'd3)
			bestdata <= 16'd0;
		else begin
			case(state_4)
				3'b100:  bestdata <= data_big_best;
				3'b010:  bestdata <= bestdata;
				3'b001:  bestdata <= bestdata;
				default: bestdata <= bestdata;
			endcase
		end

always@(posedge phy_clk or negedge reset_phy_clk_n)
		if(!reset_phy_clk_n)	
				out <= 1'b0;
		else if(cnt == 16'd3996)
				out <= 1'b1;
		else if(cnt == 16'd36)
				out <= 1'b0;
		else
				out <= out ;
				
always@(posedge phy_clk or negedge reset_phy_clk_n)
		if(!reset_phy_clk_n)		
			cnt_delay <= 16'd0;
		else if(out)
			cnt_delay <= cnt_delay + 16'd1;
		else
			cnt_delay <= 16'd0;
			
always@(posedge phy_clk or negedge reset_phy_clk_n)
		if(!reset_phy_clk_n)
			data_top <= 16'd0;
		else if(cnt_delay == 16'd3)
			data_top <= bestdata;
		else
			data_top <= data_top;

always@(posedge phy_clk or negedge reset_phy_clk_n)
		if(!reset_phy_clk_n)
			addr_top <= 16'd0;
		else if(cnt_delay == 16'd3)
			addr_top <= addr_final;
		else
			addr_top <= addr_top;
always@(posedge phy_clk or negedge reset_phy_clk_n)
		if(!reset_phy_clk_n)			
			cnt_fault <= 1'b0;
		else if(local_rdata_valid_reg)
			cnt_fault <= 1'b1;
		else
			cnt_fault <= cnt_fault;
			
always@(posedge phy_clk or negedge reset_phy_clk_n)
		if(!reset_phy_clk_n)
			cnt <= 16'd0;
		else if(cnt == 16'd3996)
		   cnt <= 16'd0;
		else if(local_rdata_valid_reg && cnt_fault == 1'b1)
			cnt <= cnt + 16'd4;
		else
			cnt <= cnt;

always@(posedge phy_clk or negedge reset_phy_clk_n)
		if(!reset_phy_clk_n)begin
			addr1 <= 16'd0;
			addr2 <= 16'd0;
			addr3 <= 16'd0;
			addr4 <= 16'd0;
		end
		else if(local_rdata_valid_reg && cnt_fault == 1'b1)begin
			addr1 <= cnt;
			addr2 <= cnt + 16'd1;
			addr3 <= cnt + 16'd2;
			addr4 <= cnt + 16'd3;
		end
		else begin
			addr1 <= addr1;
			addr2 <= addr2;
			addr3 <= addr3;
			addr4 <= addr4;
		end
			
always@(posedge phy_clk or negedge reset_phy_clk_n)
		if(!reset_phy_clk_n)
			addr_big_1 <= 16'd0;
		else begin
			case(state_1)
				3'b100:  addr_big_1 <= addr1;
				3'b010:  addr_big_1 <= addr1;
				3'b001:  addr_big_1 <= addr2;
				default: addr_big_1 <= addr_big_1;
			endcase
		end

always@(posedge phy_clk or negedge reset_phy_clk_n)
		if(!reset_phy_clk_n)
			addr_big_2 <= 16'd0;
		else begin
			case(state_2)
				3'b100:  addr_big_2 <= addr3;
				3'b010:  addr_big_2 <= addr3;
				3'b001:  addr_big_2 <= addr4;
				default: addr_big_2 <= addr_big_2;
			endcase
		end

always@(posedge phy_clk or negedge reset_phy_clk_n)
		if(!reset_phy_clk_n)
			addr_best <= 16'd0;
		else begin
			case(state_3)
				3'b100:  addr_best <= addr_big_1;
				3'b010:  addr_best <= addr_big_1;
				3'b001:  addr_best <= addr_big_2;
				default: addr_best <= addr_best;
			endcase
		end

//always@(posedge phy_clk or negedge reset_phy_clk_n)
//		if(!reset_phy_clk_n)
//			addr_best_reg <= 16'd0;
//		else 
//			addr_best_reg <= addr_best;

always@(posedge phy_clk or negedge reset_phy_clk_n)
		if(!reset_phy_clk_n)
			addr_final <= 16'd0;
		else begin
			case(state_4)
				3'b100:  addr_final <= addr_best;
				3'b010:  addr_final <= addr_final;
				3'b001:  addr_final <= addr_final;
				default: addr_final <= addr_final;
			endcase
		end
		
cmp_cnt cmp16_1(
     .a(data1),
     .b(data2),
     .fi_big(1'b0),
     .fi_equal(1'b1),
	  .fi_small(1'b0),
 
     .fo_big(fo_big_1),
	  .fo_equal(fo_equal_1),
     .fo_small(fo_small_1)
);

cmp_cnt cmp16_2(
      .a(data3),
      .b(data4),
      .fi_big(1'b0),
      .fi_equal(1'b1),
		.fi_small(1'b0),
		
      .fo_big(fo_big_2),
		.fo_equal(fo_equal_2),
      .fo_small(fo_small_2)
);

cmp_cnt cmp16_3(
      .a(data_big_1),
      .b(data_big_2),
      .fi_big(1'b0),
      .fi_equal(1'b1),
		.fi_small(1'b0),
		
      .fo_big(fo_big_3),
		.fo_equal(fo_equal_3),
      .fo_small(fo_small_3)
);

cmp_cnt cmp16_4(
      .a(data_big_best),
      .b(bestdata),
      .fi_big(1'b0),
      .fi_equal(1'b1),
		.fi_small(1'b0),
		
      .fo_big(fo_big_4),
		.fo_equal(fo_equal_4),
      .fo_small(fo_small_4)
		);
endmodule
