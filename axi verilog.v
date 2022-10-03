`timescale 1ns / 1ps

module axi(

    //========== Для связи с frame_generator ==========//
    input [9:0]  DataFromCamera,
    input        WR,
    output reg   START_GEN = 0,


    //=================================================//
  
    input CLK100,
    
    input [57:0] M2S,
    output reg [32:0] S2M = 0,    
    // AXI FULL
    // ========== WRITE CHANNEL ==========================
    // ---------- ADDR CHANNEL ------------
    // ---------- DATA CHANNEL ------------
    // --------- RESPONSE CHANNEL --------- 
    
    // ========== READ CHANNEL ==========================
    // ---------- ADDR CHANNEL ------------
    // ---------- DATA & RESPONSE CHANNEL ---------
      
    // ---------- READ ADDR CHANNEL ------------
    output reg [31:0]S_AXI_GP0_0_araddr = 0,    // L
    output reg [1:0] S_AXI_GP0_0_arburst = 0,
    output reg [3:0] S_AXI_GP0_0_arcache = 0,
    output reg [5:0] S_AXI_GP0_0_arid = 0,
    output reg [3:0] S_AXI_GP0_0_arlen = 0,
    output reg [1:0] S_AXI_GP0_0_arlock = 0,
    output reg [2:0] S_AXI_GP0_0_arprot = 0,    // L
    output reg [3:0] S_AXI_GP0_0_arqos = 0,
    input            S_AXI_GP0_0_arready,   // L
    output reg [2:0] S_AXI_GP0_0_arsize = 0,
    output reg       S_AXI_GP0_0_arvalid = 0,   // L
  

    // ---------- WRITE ADDR CHANNEL ------------
    output reg [31:0]S_AXI_GP0_0_awaddr = 0,    // L
    output reg [1:0] S_AXI_GP0_0_awburst = 0,
    output reg [3:0] S_AXI_GP0_0_awcache = 0,
    output reg [5:0] S_AXI_GP0_0_awid = 0,
    output reg [3:0] S_AXI_GP0_0_awlen = 0,
    output reg [1:0] S_AXI_GP0_0_awlock = 0,
    output reg [2:0] S_AXI_GP0_0_awprot = 0,    // L
    output reg [3:0] S_AXI_GP0_0_awqos = 0,
    input            S_AXI_GP0_0_awready,   // L
    output reg [2:0] S_AXI_GP0_0_awsize = 0,
    output reg       S_AXI_GP0_0_awvalid = 0,   // L
   

    // --------- WRITE RESPONSE CHANNEL --------- 
    input [5:0]  S_AXI_GP0_0_bid,
    output reg   S_AXI_GP0_0_bready = 0,    // L
    input [1:0]  S_AXI_GP0_0_bresp,     // L
    input        S_AXI_GP0_0_bvalid,    // L
   
    
// ---------- READ DATA CHANNEL ------------
    input [31:0] S_AXI_GP0_0_rdata,
    input [5:0]  S_AXI_GP0_0_rid,
    input        S_AXI_GP0_0_rlast,
    output reg   S_AXI_GP0_0_rready = 0,    // L
    input [1:0]  S_AXI_GP0_0_rresp,     // L
    input        S_AXI_GP0_0_rvalid,    // L
   

    // ---------- WRITE DATA CHANNEL ------------
    output reg [31:0]S_AXI_GP0_0_wdata = 0,     // L
    output reg [5:0] S_AXI_GP0_0_wid = 0,
    output reg       S_AXI_GP0_0_wlast = 0,
    input            S_AXI_GP0_0_wready,    // L
    output reg [3:0] S_AXI_GP0_0_wstrb = 0,     // L
    output reg       S_AXI_GP0_0_wvalid = 0     // L
 
);

   reg          Global_reset = 0;
	reg [31:0]  brd_time_sek = 0;
	reg [23:0]  brd_time_mks = 0;

	reg [31:0]  brd_tick_sek = 0;
	reg [23:0]  brd_tick_mks = 0;

    reg         reset_mks = 0;
    reg         set_sek = 0;
    reg [31:0]  new_sek = 0;
    
	reg [31:0]  time_ms = 0;
	reg [31:0]  time_mks = 0;
	reg [9:0]   tick_mks = 0;
	reg [19:0]  tick_ms = 0;
	reg [31:0]  time_ms_c = 0;
	reg [31:0]  time_mks_c = 0;
	reg [9:0]   tick_mks_c = 0;
	reg [19:0]  tick_ms_c = 0;
    	
    reg TS_reset_reg = 0;
    reg TS_reset_reg2 = 0;
    
    reg [31:0]  TS_count = 0;

//========== Для связи с frame_generator ==========//
    wire [11:0] w_count;  // output wire [11 : 0] wr_data_count
    reg         RD;  // output wire [11 : 0] wr_data_count
    wire [31:0]  FifoData;
//=================================================//


//========================================================================================================//

    localparam C_S_AXI_DATA_WIDTH = 32;
    localparam C_S_AXI_ADDR_WIDTH = 32;
    localparam VID_W = 1024;
    localparam VID_H = 768;
    
//    reg [15:0] WD_BURST_GP = 64;   // VID_W / 16;
//    reg [19:0] COUNT_BURST_GP = 64*768; // WD_BURST * VID_H;
    reg [15:0] WD_BURST_GP = 64;   // VID_W / 16;
    reg [19:0] COUNT_BURST_GP = 10; // WD_BURST * VID_H;
    

//========================================================================================================//

    reg         reset_timer = 0;

    reg [31:0]  timer_gp_rd = 0;
    reg [31:0]  timer_gp_rd_stop = 0;
    reg [31:0]  timer_gp_wr = 0;
    reg [31:0]  timer_gp_wr_stop = 0;

//========================================================================================================//

    reg [7:0]   STATE_GP_RD = 0;
    reg [7:0]   STATE_GP_WR = 0;
    reg [7:0]   STATE_GP_WR_DATA = 0;
    
    reg [31:0]  ADDR_AXI_GP_RD = 0;
    reg [31:0]  ADDR_AXI_GP_WR = 0;

    reg [31:0]  START_ADDR_GP_RD = 0;
    reg [31:0]  START_ADDR_GP_WR = 0;

    reg [31:0]  DATA_AXI_GP_RD = 0;
    reg [31:0]  DATA_AXI_GP_WR = 0;

    reg [7:0]   LEN = 15;       // 16 in burst
    reg [1:0]   BURST = 1;      // BURST = INCR
    
    reg [2:0]   SIZE_GP = 3'b010;  // 4 байта
    
    reg [31:0]  NEXT_ADDR_GP_RD = 0;
    reg [31:0]  NEXT_ADDR_GP_WR = 0;

    reg [19:0]  count_bursts_gp_rd = 0;
    reg [31:0]  count_packets_gp_rd = 0;
    reg [19:0]  count_bursts_gp_wr = 0;
    reg [31:0]  count_packets_gp_wr = 0;

     
    reg [7:0]   wr_burst = 0;
    reg [31:0]  w_data = 0;
                       
//================================== M2S интерфейс блока =================================================//
	wire          M2S_RQ   = M2S[57];
	wire          M2S_RW   = M2S[56];
	wire  [23:0]  M2S_Addr = M2S[23:0];  
	wire  [31:0]  M2S_Data = M2S[55:24];

	reg           S2M_ACK  = 0;
	reg   [31:0]  S2M_Data = 0;	

	reg	[31:0]    testreg_A = 0;
	reg	[31:0]    testreg_B = 0;
	
	reg           RST = 0;
//================================== M2S интерфейс блока =================================================//
	
    reg           fifo_wr_gp = 0;
    wire          fifo_empty_gp;
    wire          fifo_afull_gp;
    wire [31:0]   fifo_dout_gp;

fifo_generator_0 fifo1 (
    .clk(CLK100),              // input wire clk
    .srst(RST),            // input wire srst
    .din(DATA_AXI_GP_RD),              // input wire [31 : 0] din
    .wr_en(fifo_wr_gp),          // input wire wr_en
    .rd_en(!fifo_empty_gp),          // input wire rd_en
    .dout(fifo_dout_gp),            // output wire [31 : 0] dout
    .full(),            // output wire full
    .empty(fifo_empty_gp),          // output wire empty
    .prog_full(fifo_afull_gp)  // output wire prog_full
);

    reg           fifo_wr_hp = 0;
    wire          fifo_empty_hp;
    wire          fifo_afull_hp;
    wire [63:0]   fifo_dout_hp;

    reg [4:0] STATE_FIFO = 0;
    reg [7:0] numOfReadFIFO = 0;
//=========================================================================================================//

	always @(posedge CLK100) begin 
	
	
    //=================================================//
     case (STATE_FIFO)
                0:  //Простой
                begin
                     
                end
                //--------
                1:  //Старт
                begin
                    START_GEN <= 0;
                    if (w_count >=64)
                    begin                        
                        STATE_FIFO <= 2;
                    end                    
                end
                //-------- 
                2:
                    begin
                        
                        if (S_AXI_GP0_0_awready)
                            begin
                                S_AXI_GP0_0_awaddr <= START_ADDR_GP_WR;
                                S_AXI_GP0_0_awvalid <= 1;
                                S_AXI_GP0_0_awsize <= SIZE_GP;   // 4 байта
                                S_AXI_GP0_0_awlen <= LEN;     // LEN раз
                                S_AXI_GP0_0_awburst <= BURST; // тип BURST'а
                                
                                
                                S_AXI_GP0_0_wstrb <= 4'b1111;
                                
                                wr_burst <= 0;
                                
                                NEXT_ADDR_GP_WR <= START_ADDR_GP_WR + 64; //5555555555555555555555555
                                count_bursts_gp_wr <= 0;
                                count_packets_gp_wr <= 0;
                                reset_timer <= 1;
                                STATE_FIFO <= 3;
                            end 
                    end
                //--------------------------------------
                3:
                    begin
                        if (count_bursts_gp_wr == COUNT_BURST_GP)
                            begin
                                S_AXI_GP0_0_awvalid <= 0;
                                timer_gp_wr_stop <= timer_gp_wr;
                                STATE_FIFO <= 0;
                            end
                        else
                            begin
                                if (S_AXI_GP0_0_awready)
                                    begin
                                        S_AXI_GP0_0_awvalid <= 1;
                                        S_AXI_GP0_0_awaddr <= NEXT_ADDR_GP_WR;
                                        NEXT_ADDR_GP_WR <= NEXT_ADDR_GP_WR + 64;
                                        count_bursts_gp_wr <= count_bursts_gp_wr + 1;
                                        STATE_FIFO <= 4;
                                    end
                                else
                                    S_AXI_GP0_0_awvalid <= 0;
                            end
                    end
                //--------------------------------------
                4:
                    begin
                        S_AXI_GP0_0_awvalid <= 0;
                        RD  <= 1; 
                        STATE_FIFO <= 5;
                    end
                //--------------------------------------
                5:
                    begin
                            RD <= 0; 
                            if (S_AXI_GP0_0_wready)
                                begin
                                    S_AXI_GP0_0_wvalid <= 1;//1;                                    
                                                   
                                    S_AXI_GP0_0_wdata <= {FifoData[7:0], FifoData[15:8], FifoData[23:16], FifoData[31:24]};
                                    RD  <= 1;  
                                     
                                    count_packets_gp_wr <= count_packets_gp_wr + 1;  
                                    wr_burst <= wr_burst + 1;
                                end
                            else
                                begin
                                 
                                    S_AXI_GP0_0_wvalid <= 0;
                                end
                        
                            if (S_AXI_GP0_0_wvalid & S_AXI_GP0_0_wready)
                                begin
                                    //count_packets_gp_wr <= count_packets_gp_wr + 1;            
                        
                                    //wr_burst <= wr_burst + 1;
                                    if (wr_burst == LEN)
                                        begin
                                            S_AXI_GP0_0_wlast <= 1;
                                            RD <= 0; 
                                            STATE_FIFO <= 6;
                                        end
                                    else
                                        S_AXI_GP0_0_wlast <= 0;                    
                                end
                        
                    end
                //--------------------------------------
                6:
                    begin
                        wr_burst <= 0;
                        S_AXI_GP0_0_wlast <= 0;
                        S_AXI_GP0_0_wvalid <= 0;
                        STATE_FIFO <= 7;
                    end
                //--------------------------------------
                7:
                    begin
                        S_AXI_GP0_0_wvalid <= 0;
                            if (S_AXI_GP0_0_bvalid)
                                begin
                                    S_AXI_GP0_0_bready <= 1;//1;
                                    STATE_FIFO <= 8;
                                end
                            else
                                begin
                                    S_AXI_GP0_0_bready <= 0;
                                end
                    end
                //--------------------------------------
                8:
                    begin
                        if (S_AXI_GP0_0_bvalid && S_AXI_GP0_0_bready)
                        begin
                            S_AXI_GP0_0_bready <= 0;
                            STATE_FIFO <= 9;
                        end
                    end           
                //--------------------------------------
                9:
                    begin
                        S_AXI_GP0_0_wstrb <= 0; 
                        
                        STATE_FIFO <= 1;
                    end       
                           
    endcase
    //=================================================//
 
    
			

			if (Global_reset == 1)
				Global_reset <= 0;



                       
            if (set_sek == 1)
                begin
                    brd_time_sek <= new_sek;
                    set_sek <= 0;
                end
            else
                begin

                    if (brd_tick_mks < 99)
                        begin
                            brd_tick_mks <= brd_tick_mks + 1;
                        end
                    else
                        begin
                            brd_tick_mks <= 0;
   
                            if (brd_time_mks < 999999)
                                begin
                                    brd_time_mks <= brd_time_mks + 1;
                                end
                            else
                                begin
                                    brd_time_mks <= 0;

                                    brd_time_sek <= brd_time_sek + 1;
                                end
                        end
                end                    



                
            if (tick_mks < 99)
                begin
                    tick_mks <= tick_mks + 1;
                end
            else
                begin
                    tick_mks <= 0;
                    time_mks <= time_mks + 1;
                end
			 
            if (tick_ms < 99999)
                begin
                    tick_ms <= tick_ms + 1;
                end
            else
                begin
                    tick_ms <= 0;
                    time_ms <= time_ms + 1;
                end
                
			 if (tick_mks_c < 99)
                begin
                    tick_mks_c <= tick_mks_c + 1;
                end
            else
                begin
                    tick_mks_c <= 0;
                    time_mks_c <= time_mks_c + 1;
                end 
            if (tick_ms_c < 99999)
                begin
                    tick_ms_c <= tick_ms_c + 1;
                end
            else
                begin
                    tick_ms_c <= 0;
                    time_ms_c <= time_ms_c + 1;
                end
			 
	
	
			S2M_ACK <= M2S_RQ;
			S2M     <= {S2M_ACK,S2M_Data};
			
			if (RST == 1)
			     RST <= 0;

            if (reset_timer == 1)
                begin
                    timer_gp_rd <= 0;
                    timer_gp_wr <= 0;
                    reset_timer <= 0;
                end
            else
                begin
                    timer_gp_rd <= timer_gp_rd + 1;
                    timer_gp_wr <= timer_gp_wr + 1;
                end

			if (M2S_RQ) begin
				if (M2S_RW) begin
					case (M2S_Addr) 
						0:  S2M_Data <= 32'h11223344;   //Версия-Дата
				      //1
						2:  S2M_Data <= testreg_A;      
						3:  S2M_Data <= ~testreg_B;
						4:  S2M_Data <= STATE_GP_RD;    
						5:  S2M_Data <= START_ADDR_GP_RD;    
						6:  S2M_Data <= count_bursts_gp_rd;    
						7:  S2M_Data <= count_packets_gp_rd;    
						8:  S2M_Data <= timer_gp_rd_stop;    
						9:  S2M_Data <= STATE_GP_WR;    
						10:  S2M_Data <= count_bursts_gp_wr;    
						11:  S2M_Data <= count_packets_gp_wr;    
                        12:  S2M_Data <= LEN;       // 16 in burst
                        13:  S2M_Data <= BURST;      // BURST = INCR
                        14:  S2M_Data <= SIZE_GP;  // 4 байта
                        
                        
                        
                        15:  S2M_Data <= time_ms;     
//                        15:  S2M_Data <= 32'h12344321;     
						16:  S2M_Data <= time_mks; 
						17:  S2M_Data <= time_ms_c;     
						18:  S2M_Data <= time_mks_c; 
						
						19:  S2M_Data <= brd_time_sek;     
						20:  S2M_Data <= brd_time_mks; 
						
						21:  S2M_Data <= new_sek;
						22:  S2M_Data <= TS_count;
						default:  S2M_Data <= 32'h00000BAD;
//						default:  S2M_Data <= M2S_Addr;
					endcase
				end
				else begin
					case (M2S_Addr)
					    1:  RST <= 1; 
						2:  testreg_A   <= M2S_Data[31:0];    //Фильтр вкл/выкл (1/0)
						3:  testreg_B   <= M2S_Data[31:0];  //Режим работы фильтра
						4:  
						  begin
						      if (STATE_GP_RD == 0) STATE_GP_RD <= 1;
						  end
						5:  START_ADDR_GP_RD <= M2S_Data[31:0];
//						
						9:  
						  begin
						      //if (STATE_GP_WR == 0) STATE_GP_WR <= 1;
						      START_GEN <= 1;
						      STATE_FIFO <= 1;
						  end
						12:  LEN <= M2S_Data[31:0];
						13:  BURST <= M2S_Data[31:0];
						14:  SIZE_GP <= M2S_Data[31:0];
						
						
					endcase	                      
				end

			end

//    case (STATE_GP_WR)
//        0:
//            begin
//            end

//        //--------------------------------------
//        1:
//            begin
//                START_GEN <= 0;
//                if (S_AXI_GP0_0_awready)
//                    begin
//                        S_AXI_GP0_0_awaddr <= START_ADDR_GP_WR;
//                        S_AXI_GP0_0_awvalid <= 1;
//                        S_AXI_GP0_0_awsize <= SIZE_GP;   // 4 байта
//                        S_AXI_GP0_0_awlen <= LEN;     // LEN раз
//                        S_AXI_GP0_0_awburst <= BURST; // тип BURST'а
                        
                        
//                        S_AXI_GP0_0_wstrb <= 4'b1111;
                        
//                        wr_burst <= 0;
                        
//                        NEXT_ADDR_GP_WR <= START_ADDR_GP_WR + 64;
//                        count_bursts_gp_wr <= 0;
//                        count_packets_gp_wr <= 0;
//                        reset_timer <= 1;
//                        STATE_GP_WR <= 2;
//                    end 
//            end
//        //--------------------------------------
//        2:
//            begin
//                if (count_bursts_gp_wr == COUNT_BURST_GP)
//                    begin
//                        S_AXI_GP0_0_awvalid <= 0;
//                        timer_gp_wr_stop <= timer_gp_wr;
//                        STATE_GP_WR <= 0;
//                    end
//                else
//                    begin
//                        if (S_AXI_GP0_0_awready)
//                            begin
//                                S_AXI_GP0_0_awvalid <= 1;
//                                S_AXI_GP0_0_awaddr <= NEXT_ADDR_GP_WR;
//                                NEXT_ADDR_GP_WR <= NEXT_ADDR_GP_WR + 64;
//                                count_bursts_gp_wr <= count_bursts_gp_wr + 1;
//                                STATE_GP_WR <= 3;
//                            end
//                        else
//                            S_AXI_GP0_0_awvalid <= 0;
//                    end
//            end
//        //--------------------------------------
//        3:
//            begin
//                S_AXI_GP0_0_awvalid <= 0;
//                STATE_GP_WR <= 4; 
//            end
//        //--------------------------------------
//        4:
//            begin
//                RD <= 0;
//                if (w_count >=64)
//                begin
//                    if (S_AXI_GP0_0_wready)
//                        begin
//                            S_AXI_GP0_0_wvalid <= 1;//1;
//                            RD <= 1;                        
//                            S_AXI_GP0_0_wdata <= FifoData;
                            
                            
//                            count_packets_gp_wr <= count_packets_gp_wr + 1;  
//                            wr_burst <= wr_burst + 1;
//                        end
//                    else
//                        begin
//                            S_AXI_GP0_0_wvalid <= 0;
//                        end
                
//                    if (S_AXI_GP0_0_wvalid & S_AXI_GP0_0_wready)
//                        begin
//                            //count_packets_gp_wr <= count_packets_gp_wr + 1;            
                
//                            //wr_burst <= wr_burst + 1;
//                            if (wr_burst == LEN)
//                                begin
//                                    S_AXI_GP0_0_wlast <= 1;
//                                    STATE_GP_WR <= 5;
//                                end
//                            else
//                                S_AXI_GP0_0_wlast <= 0;                    
//                    end
//                end
//            end
//        //--------------------------------------
//        5:
//            begin
//                wr_burst <= 0;
//                S_AXI_GP0_0_wlast <= 0;
//                S_AXI_GP0_0_wvalid <= 0;
//                STATE_GP_WR <= 6;
//            end
//        //--------------------------------------
//        6:
//            begin
//                S_AXI_GP0_0_wvalid <= 0;
//                    if (S_AXI_GP0_0_bvalid)
//                        begin
//                            S_AXI_GP0_0_bready <= 1;//1;
//                            STATE_GP_WR <= 7;
//                        end
//                    else
//                        begin
//                            S_AXI_GP0_0_bready <= 0;
//                        end
//            end
//        //--------------------------------------
//        7:
//            begin
//                if (S_AXI_GP0_0_bvalid && S_AXI_GP0_0_bready)
//                begin
//                    S_AXI_GP0_0_bready <= 0;
//                    STATE_GP_WR <= 2;
//                end
//            end           
//    endcase   
	end

fifo_generator_2 fifo_axi (
  .clk(CLK100),             // input wire clk
  .srst(0),            // input wire srst
  .din(DataFromCamera[7:0]),     // input wire [7 : 0] din
  .wr_en((DataFromCamera < 10'h3f1)),            // input wire wr_en
  .rd_en(RD),            // input wire rd_en
  .dout(FifoData),            // output wire [31 : 0] dout
  .full(),            // output wire full
  .empty(),          // output wire empty
  .wr_data_count(w_count)   // output wire [11 : 0] wr_data_count
);


ila_0 ila_axi_3 (
	.clk(CLK100), // input wire clk
	.probe0(S_AXI_GP0_0_awaddr), // input wire [31:0]  probe0  
	.probe1({STATE_GP_WR[2:0],S_AXI_GP0_0_awready,S_AXI_GP0_0_awvalid,S_AXI_GP0_0_awlen,S_AXI_GP0_0_awburst}), // input wire [31:0]  probe1 
	.probe2({S_AXI_GP0_0_wdata}), // input wire [31:0]  probe2 
	.probe3({RD,STATE_FIFO, STATE_GP_WR_DATA[2:0],S_AXI_GP0_0_wready,S_AXI_GP0_0_wvalid,S_AXI_GP0_0_wstrb, S_AXI_GP0_0_wlast,S_AXI_GP0_0_bready,S_AXI_GP0_0_bresp,S_AXI_GP0_0_bvalid}), // input wire [31:0]  probe3 
	.probe4(count_packets_gp_wr), // input wire [31:0]  probe4 
	.probe5(DATA_AXI_GP_WR), // input wire [31:0]  probe5 
	.probe6(wr_burst), // input wire [31:0]  probe6 
	.probe7(FifoData) // input wire [31:0]  probe6 
);  


endmodule
