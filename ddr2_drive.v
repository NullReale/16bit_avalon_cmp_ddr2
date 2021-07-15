`timescale 1ns / 1ps
// *********************************************************************************
// Project Name : DDR2_TEST
// Author       : KiriTo
// Email        : 
// Website      : 
// Module Name  : ddr2_drive.v
// Create Time  : 2020-03-06 13:14:59
// Editor       : sublime text3, tab size (4)
// CopyRight(c) : All Rights Reserved
//
// *********************************************************************************
// Modification History:
// Date             By              Version                 Change Description
// -----------------------------------------------------------------------
// XXXX           KiriTo          1.0                        Original
//  
// *********************************************************************************
//实现了50MHz信号通过FIFO传输至ddr2，FIFO读请求与DDR写请求同步，DDR2的读请求未开发，只实现了同一local_burstbegin时钟
//内将同一地址的数据发出
//此版本搭建了寻峰算法，得出的最大地址为addr_final-16'd4
//出现地址固定偏移的原因是ddr2进行local_rdata输出的时候发出的第一位数据为16'd0（此数据为废数据）
//此版本完成了板级实现，实现了50m数据导入FIFO传输至ddr2，并将ddr2数据实时导出至数据比较器模块内，最终得出了最大值的地址。
module ddr2_drive(
    //System Interfaces
    input                   sclk                ,
    input                   rst_n               ,
    //DDR2 Interfaces   
    output  wire      ddr2a_odt             ,
    output  wire      ddr2a_cs_n            ,
    output  wire      ddr2a_cke             ,
    output  wire    [12:0]  ddr2a_addr            ,
    output  wire    [ 2:0]  ddr2a_ba              ,
    output  wire            ddr2a_ras_n           ,
    output  wire            ddr2a_cas_n           ,
    output  wire            ddr2a_we_n            ,
    output  wire    [ 1:0]  ddr2a_dm              ,
    inout   wire      ddr2a_clk             ,
    inout   wire      ddr2a_clk_n           ,
    inout   wire    [15:0]  ddr2a_dq              ,
    inout   wire    [ 1:0]  ddr2a_dqs             
    //Debug
//    input                   test_start         
) ;/*synthesis, probe_port,keep*/ 

 
//========================================================================================\
//**************Define Parameter and  Internal Signals**********************************
//========================================================================================/
parameter       BL_LENGTH             =           8            ;
parameter       BL_NUM_END            =           2097152       ;
parameter       DELAY_10MS            =           21'd500000    ;
//pll_inst
wire                                         clk_50m           ;
wire                                         locked              ;
//ddr2_ctrl_inst 
wire                                         reset_phy_clk_n     ;
(*keep*)         wire                        phy_clk             ;
(*keep*)         wire                        local_init_done     ;
(*preserve*)     reg                 [23:0]  local_address       ;
(*preserve*)     reg                         local_write_req     ;
(*preserve*)     reg                         local_read_req      ;
(*preserve*)     reg                         local_burstbegin    ;
//(*preserve*)     wire                 [63:0]  local_wdata         ;
(*keep*)         wire                [ 7:0]  local_be            ;
(*keep*)         wire                [ 6:0]  local_size          ;
(*keep*)         wire                        local_ready         ;
(*keep*)         wire                [63:0]  local_rdata         ;
(*keep*)         wire                        local_rdata_valid   ;
(*preserve*)     reg                 [ 6:0]  wr_cnt              ;
(*preserve*)     reg                 [ 6:0]  rd_cnt              ;
(*preserve*)     reg                 [21:0]  bl_cnt              ;  
(* preserve *)   reg                 [63:0]  check_data          ;
//(*keep*)         wire                        test_start          ;
(* noprune *)    reg                 [63:0]  err_cnt             ;
(* noprune *)    reg                         test_done           ;  
reg                                          global_reset_n      ;

reg                                 [20:0]   delay_cnt           ;
(* noprune *)reg  test;
//========================================================================================\
//**************     FIFO      Code        **********************************
//========================================================================================/
reg [15:0]data;
wire [63:0]q/*synthesis keep*/;
wire rdreq;
wire wrreq;
reg wrreq_sys;
wire rdempty;
wire wrfull;
wire [15:0]wrusedw/*synthesis keep*/;
wire [13:0]rdusedw/*synthesis keep*/;
//========================================================================================\
//**************     CMP      Code        **********************************
//========================================================================================/
wire [15:0]data_big_1;
wire [15:0]data_big_2;
wire [15:0]data_big_best;
wire [15:0]bestdata/*synthesis keep*/;
wire [15:0]addr_final/*synthesis keep*/;
wire [15:0]cnt;
wire [15:0]addr1;
wire [15:0]addr2;
wire [15:0]addr3;
wire [15:0]addr4;

//wire test_start_delay;
//reg start_delay;
//reg start_delay_1;
//reg start_delay_2;
//reg	[3:0]start_cnt;
//========================================================================================\
//**************     Main      Code        **********************************
//========================================================================================/
assign      local_be        =       8'hff;
assign      local_size      =       BL_LENGTH;
//assign		q   =   local_wdata;
assign		rdreq  =  local_write_req && (!rdempty);
assign  		wrreq  =  wrreq_sys && (!wrfull);

//连接ddr2与AD数据
fifo_ddr2_ad	fifo_ddr2_ad_inst (
	.data ( data ),
	.rdclk ( phy_clk ),
	.rdreq ( rdreq ),
	.wrclk ( sclk ),
	.wrreq ( wrreq ),
	.q ( q ),
	.rdempty ( rdempty ),
	.wrfull ( wrfull ),
	.rdusedw (rdusedw),
	.wrusedw (wrusedw),
	.aclr(rst_n)
	);
		
always @(posedge sclk or posedge rst_n)
    if(rst_n == 1'b1)
        delay_cnt               <=      21'd0;
    else if(locked == 1'b0)
        delay_cnt               <=      21'd0;
    else if(delay_cnt >= DELAY_10MS)
        delay_cnt               <=      delay_cnt;
    else
        delay_cnt               <=      delay_cnt + 1'b1;
        
always @(posedge sclk or posedge rst_n)
    if(rst_n == 1'b1)
        global_reset_n          <=      1'b0;
    else if(locked == 1'b0)
        global_reset_n          <=      1'b0;
    else if(delay_cnt >= DELAY_10MS) 
        global_reset_n          <=      1'b1;
    else
        global_reset_n          <=      global_reset_n;
        
always @(posedge phy_clk or negedge reset_phy_clk_n)
    if(reset_phy_clk_n == 1'b0)
        local_write_req         <=      1'b0; 
//    else if(test_start_delay == 1'b1)
//        local_write_req         <=      1'b1;
    else if(rdusedw >= 14'd9 && wr_cnt == 7'd0 && local_ready == 1'b1 && local_rdata_valid == 1'b0) 
        local_write_req         <=      1'b1;
    else if(wr_cnt == (BL_LENGTH-1) && local_ready == 1'b1)
        local_write_req         <=      1'b0;
    else
        local_write_req         <=      local_write_req;

always @(posedge phy_clk or negedge reset_phy_clk_n)
    if(reset_phy_clk_n == 1'b0)
        local_burstbegin        <=      1'b0; 
//    else if(test_start_delay == 1'b1) 
//        local_burstbegin        <=      1'b1;
    else if(rdusedw >= 14'd9 && wr_cnt == 7'd0 && local_ready == 1'b1 && local_rdata_valid == 1'b0)
        local_burstbegin        <=      1'b1;
    else if(wr_cnt == (BL_LENGTH-1) && local_ready == 1'b1)
        local_burstbegin        <=      1'b1;
    else
        local_burstbegin        <=      1'b0;

always @(posedge phy_clk or negedge reset_phy_clk_n)
    if(reset_phy_clk_n == 1'b0)
        wr_cnt                  <=      7'd0;
    else if(local_write_req == 1'b1 && local_ready == 1'b1 && wr_cnt == (BL_LENGTH-1))
        wr_cnt                  <=      7'd0;
    else if(local_write_req == 1'b1 && local_ready == 1'b1)
        wr_cnt                  <=      wr_cnt + 1'b1;
    else 
        wr_cnt                  <=      wr_cnt;
//fifo测试数据//////////////////////////////////////
always @(posedge sclk or posedge rst_n)
    if(rst_n == 1'b1)
        data             <=      16'd0; 
	 else if(data == 16'd3999)
		  data 				<=  		16'd0;
    else	if(wrreq_sys)
        data             <=      data + 1'b1;

always @(posedge sclk or posedge rst_n)
    if(rst_n == 1'b1)
        wrreq_sys             <=      1'b0; 
    else	if(test_start)
        wrreq_sys             <=      1'b1;
	 else
		  wrreq_sys             <=      wrreq_sys;
		
///////////////////////////////////////////////////////////
always @(posedge phy_clk or negedge reset_phy_clk_n)
    if(reset_phy_clk_n == 1'b0)
        local_read_req          <=      1'b0; 
    else if(wr_cnt == (BL_LENGTH-1) && local_ready == 1'b1)
        local_read_req          <=      1'b1;
    else if(local_ready == 1'b1)
        local_read_req          <=      1'b0;
    else
        local_read_req          <=      local_read_req;

always @(posedge phy_clk or negedge reset_phy_clk_n)
    if(reset_phy_clk_n == 1'b0)
        rd_cnt                  <=      7'd0;
    else if(local_rdata_valid == 1'b1 && rd_cnt == (BL_LENGTH-1)) 
        rd_cnt                  <=      7'd0;
    else if(local_rdata_valid == 1'b1)
        rd_cnt                  <=      rd_cnt + 1'b1;
    else
        rd_cnt                  <=      rd_cnt;

always @(posedge phy_clk or negedge reset_phy_clk_n)
    if(reset_phy_clk_n == 1'b0)
        bl_cnt                  <=      22'd0;
    else if(test_start_delay == 1'b1)
        bl_cnt                  <=      22'd0;
    else if(local_rdata_valid == 1'b1 && rd_cnt == (BL_LENGTH-1))
        bl_cnt                  <=      bl_cnt + 1'b1;
    else
        bl_cnt                  <=      bl_cnt;

always @(posedge phy_clk or negedge reset_phy_clk_n)
    if(reset_phy_clk_n == 1'b0)
        local_address           <=      25'd0;
    else if(test_start_delay == 1'b1)
        local_address           <=      25'd0;
    else if(local_rdata_valid == 1'b1 && rd_cnt == (BL_LENGTH-1))
        local_address           <=      local_address + BL_LENGTH;
    else 
        local_address           <=      local_address; 
    
always @(posedge phy_clk or negedge reset_phy_clk_n)
    if(reset_phy_clk_n == 1'b0)
        check_data              <=      64'd0; 
    else if(local_rdata_valid == 1'b1)
        check_data              <=      check_data + 1'b1;
    else
        check_data              <=      check_data;
          
always @(posedge phy_clk or negedge reset_phy_clk_n)
    if(reset_phy_clk_n == 1'b0)
        err_cnt                 <=      64'd0;
    else if(local_rdata_valid == 1'b1 && check_data != local_rdata) 
        err_cnt                 <=      err_cnt + 1'b1;
    else
        err_cnt                 <=      err_cnt;    

always @(posedge phy_clk or negedge reset_phy_clk_n)
    if(reset_phy_clk_n == 1'b0)
        test_done               <=      1'b0;   
    else if(rd_cnt == (BL_LENGTH-1) && local_rdata_valid == 1'b1 && bl_cnt == (BL_NUM_END-1)) 
        test_done               <=      1'b1;
    else
        test_done               <=      1'b0;
                            
pll pll_inst(
    .areset                     (rst_n                     ),
    .inclk0                     (sclk                       ),
    .c0                         (clk_50m                   ),
    .locked                     (locked                     )
);

ddr2_ctrl ddr2_ctrl_inst(
    .pll_ref_clk                (clk_50m                   ),
    .global_reset_n             (global_reset_n             ),
    .soft_reset_n               (1'b1                       ),
    .local_address              (local_address              ),
    .local_write_req            (local_write_req            ),
    .local_read_req             (local_read_req             ),
    .local_burstbegin           (local_burstbegin           ),
    .local_wdata                (q                ),
    .local_be                   (local_be                   ),
    .local_size                 (local_size                 ),
    .local_ready                (local_ready                ),
    .local_rdata                (local_rdata                ),
    .local_rdata_valid          (local_rdata_valid          ),
    .local_refresh_ack          (                           ),
    .local_init_done            (local_init_done            ),
    .mem_odt                    (ddr2a_odt                    ),
    .mem_cs_n                   (ddr2a_cs_n                   ),
    .mem_cke                    (ddr2a_cke                    ),
    .mem_addr                   (ddr2a_addr                   ),
    .mem_ba                     (ddr2a_ba                     ),
    .mem_ras_n                  (ddr2a_ras_n                  ),
    .mem_cas_n                  (ddr2a_cas_n                  ),
    .mem_we_n                   (ddr2a_we_n                   ),
    .mem_dm                     (ddr2a_dm                     ),
    .mem_clk                    (ddr2a_clk                    ),
    .mem_clk_n                  (ddr2a_clk_n                  ),
    .mem_dq                     (ddr2a_dq                     ),
    .mem_dqs                    (ddr2a_dqs                    ),
    .phy_clk                    (phy_clk                    ),
    .reset_phy_clk_n            (reset_phy_clk_n            ),
    .reset_request_n            (                           ),
    .aux_full_rate_clk          (                           ),
    .aux_half_rate_clk          (                           )            
);

cmp cmp1(
	.phy_clk(phy_clk),
	.reset_phy_clk_n(reset_phy_clk_n),
	.local_rdata(local_rdata),
	.local_rdata_valid(local_rdata_valid),
// .fo_big_1,
// .fo_equal_1,
// .fo_small_1,
// .fo_big_2,
// .fo_equal_2,
// .fo_small_2,
// .fo_big_3,
// .fo_equal_3,
// .fo_small_3,
// .fo_big_4,
// .fo_equal_4,
// .fo_small_4,	
	.data_big_1(data_big_1),//低位两个数据比较得出的最大值
	.data_big_2(data_big_2),//高位两个数据比较得出的最大值
	.data_big_best(data_big_best),//四个数据比较得出的最大值
// .data_big_best_reg,
	.bestdata(bestdata),
	.addr_final(addr_final),
	.cnt(cnt),
	.addr1(addr1),
	.addr2(addr2),
	.addr3(addr3),
	.addr4(addr4),
	.local_init_done(local_init_done)
);
//========================================================================================\
//*******************************     Debug    **********************************
//========================================================================================/
wire                            source                  ;
wire test_start_delay;
reg start_delay;
reg start_delay_1;
reg start_delay_2;
reg	[9:0]start_cnt;
reg                             source_r                ;
reg                             source_r2               ;

assign  test_start      =       source_r && ~source_r2 ;
assign	test_start_delay = start_delay_1 && ~start_delay_2;
always @(posedge sclk or posedge rst_n)
	if(rst_n == 1'b1)
		start_cnt <= 10'd0;
	else if(wrreq_sys)
		start_cnt <= start_cnt + 1'b1;
	else if(start_cnt >= 10'd40)
		start_cnt <= start_cnt;
	else
		start_cnt <= start_cnt; 

always @(posedge phy_clk or negedge reset_phy_clk_n)
	if(reset_phy_clk_n == 1'b0 )
		start_delay <= 1'b0;
	else if(start_cnt == 10'd39)
		start_delay <= 1'b1;
	else
		start_delay <= start_delay;

always @(posedge phy_clk)begin
    start_delay_1            <=      start_delay;
    start_delay_2           <=      start_delay_1;
end

always @(posedge phy_clk)begin
    source_r            <=      source;
    source_r2           <=      source_r;
end

issp issp_inst(
    .probe                      (                           ),
    .source                     (source                     )
);
//test
always @(posedge phy_clk or negedge reset_phy_clk_n)
	if(reset_phy_clk_n == 1'b0 )
		test <= 1'b0;
	else if(local_address == 24'd40000)
		test <= 1'b1;
	else
		test <= test;
endmodule
