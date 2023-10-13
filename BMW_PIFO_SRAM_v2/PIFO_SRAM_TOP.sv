`timescale 1ns / 10ps
/*-----------------------------------------------------------------------------

Proprietary and Confidential Information

Module: PIFO_SRAM_TOP.v
Author: Zhiyu Zhang
Date  : 03/10/2023

Description: Top-level module that contains n levels (n is parameterizable) 
             of PIFO components (In this version, PIFO storage elements are
			 SRAM instead of FFs. This makes the whole PIFO tree more expandable.). 
			 
Issues:  

-----------------------------------------------------------------------------*/

//-----------------------------------------------------------------------------
// Module Port Definition
//-----------------------------------------------------------------------------

// 目前的配置是有 LEVEL == SRAM 数，LEVEL == RPU 数

module PIFO_SRAM_TOP
#(
   parameter PTW    = 16,       // Payload data width
   parameter MTW    = 0,        // Metdata width
   parameter CTW    = 10,       // Counter width
   parameter LEVEL  = 4,         // Sub-tree level
   parameter TREE_NUM = 4,
   parameter FIFO_SIZE    = 8,
   parameter FIFO_WIDTH    = $clog2(FIFO_SIZE),
	parameter LEVEL_BITS = $clog2(LEVEL),
	parameter LEVEL_MASK ={LEVEL{1'b1}},    // Tree level
	parameter A_TREE ={LEVEL{1'b1}},
	parameter TREE_NUM_BITS = $clog2(TREE_NUM),
   parameter SRAM_ADW    = $clog2(TREE_NUM/LEVEL) + LEVEL,       // SRAM_Address width
   
   parameter ADW    = LEVEL       // Address width in a level
)(
   // Clock and Reset
   input                            i_clk,
   input                            i_arst_n,
   
   // Push and Pop port to the whole PIFO tree
   input [TREE_NUM_BITS-1:0]        i_tree_id [0:LEVEL-1],
   input [LEVEL-1:0]                i_push,
   input [(MTW+PTW)-1:0]            i_push_data [0:LEVEL-1],
   
   input [LEVEL-1:0]                i_pop,
   output [TREE_NUM_BITS-1:0]       o_tree_id [0:LEVEL-1],
   output [(MTW+PTW)-1:0]           o_pop_data [0:LEVEL-1],

   output [LEVEL-1:0]               o_is_level0_pop,
   output [LEVEL-1:0]               o_task_fifo_full
);
//-----------------------------------------------------------------------------
// Include Files
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Functions and Tasks
//-----------------------------------------------------------------------------

function get_rpu_id(
    input logic [TREE_NUM_BITS-1:0] tree_id,
    input logic [LEVEL_BITS-1:0] level,
    logic [LEVEL_BITS-1:0] ret = '0
    );
    ret = (tree_id + level) & {LEVEL_BITS{1'b1}};
    return ret;  
endfunction

function get_child_id(
    input logic [LEVEL_BITS-1:0] my_id,
    logic [LEVEL_BITS-1:0] child_id = '0
    );
    child_id = (my_id + 1) & {LEVEL_BITS{1'b1}};
    return child_id;   
endfunction


//-----------------------------------------------------------------------------
// Register and Wire Declarations
//-----------------------------------------------------------------------------

   wire [LEVEL-1:0]                    push_up;
   wire [LEVEL-2:0]                    test;
   wire [(MTW+PTW)-1:0]                push_data_up [0:LEVEL-1];
   wire [LEVEL-1:0]                    pop_up;
   wire [(MTW+PTW)-1:0]                pop_data_up  [0:LEVEL-1];
   wire [LEVEL-1:0]                    push_dn      ;
   wire [(MTW+PTW)-1:0]                push_data_dn [0:LEVEL-1];
   wire [LEVEL-1:0]                    pop_dn;
   wire [(MTW+PTW)-1:0]                pop_data_dn  [0:LEVEL-1];
   
   wire [LEVEL - 1:0]                  read;
   wire [LEVEL - 1:0]                  write;
   wire [2*(CTW+MTW+PTW)-1:0]          read_data    [0:LEVEL - 1];
   wire [2*(CTW+MTW+PTW)-1:0]          write_data   [0:LEVEL - 1];   

   wire [$clog2(LEVEL)-1:0]              level_up   [0:LEVEL - 1];
   wire [$clog2(LEVEL)-1:0]              level_dn   [0:LEVEL - 1];
   reg [$clog2(LEVEL)-1:0]              level_wb   [0:LEVEL - 1];

   wire [TREE_NUM_BITS-1:0]              tree_id_up  [0:LEVEL - 1];
   wire [TREE_NUM_BITS-1:0]              tree_id_dn  [0:LEVEL - 1];
   wire [LEVEL-1:0]                      is_level0_pop;
   
   wire [LEVEL-1:0]                    we;
   wire [SRAM_ADW-1:0]                   waddr        [0:LEVEL - 1];
   wire [2*(CTW+MTW+PTW)-1:0]          wdata        [0:LEVEL-1];
      
   wire [LEVEL-1:0]                    re;
   wire [SRAM_ADW-1:0]                   raddr        [0:LEVEL - 1];
   wire [2*(CTW+MTW+PTW)-1:0]          rdata        [0:LEVEL-1];   


   wire [SRAM_ADW-1:0]                      read_addr    [0:LEVEL-1];
   wire [SRAM_ADW-1:0]                      write_addr   [0:LEVEL-1];
   
   
   wire [ADW-1:0]                      my_addr      [0:LEVEL-1];
   wire [ADW-1:0]                      child_addr   [0:LEVEL-1];

   wire [LEVEL-1:0] pop_TaskFIFO;
   wire [PTW+TREE_NUM_BITS:0] TaskFIFO_pop_data [0:LEVEL-1];
   wire [LEVEL-1:0] TaskFIFO_empty;
   wire [1:0] rpu_state_nxt [0:LEVEL-1];

   wire [LEVEL-1:0] rpu_push;
   wire [LEVEL-1:0] rpu_pop;
   wire [PTW-1:0] rpu_push_data [0:LEVEL-1];
   wire [TREE_NUM_BITS-1:0] rpu_treeId [0:LEVEL-1];

   wire [LEVEL-1:0] push_TaskFIFO;
   wire [PTW+TREE_NUM_BITS:0] TaskFIFO_push_data [0:LEVEL-1];
   wire [LEVEL-1:0] TaskFIFO_full;
   wire [FIFO_WIDTH:0] fifo_counter [0:LEVEL-1]; 


   wire [1:0] rpu_state_nxt_0;
   wire [1:0] rpu_state_nxt_1;
   // wire [1:0] rpu_state_nxt_2;
   // wire [1:0] rpu_state_nxt_3;

   wire [PTW+TREE_NUM_BITS:0] TaskFIFO_push_data_0;
   wire [PTW+TREE_NUM_BITS:0] TaskFIFO_push_data_1;
   // wire [PTW+TREE_NUM_BITS:0] TaskFIFO_push_data_2;
   // wire [PTW+TREE_NUM_BITS:0] TaskFIFO_push_data_3;

   assign TaskFIFO_push_data_0 = TaskFIFO_push_data[0];
   assign TaskFIFO_push_data_1 = TaskFIFO_push_data[1];
   // assign TaskFIFO_push_data_2 = TaskFIFO_push_data[2];
   // assign TaskFIFO_push_data_3 = TaskFIFO_push_data[3];

   assign rpu_state_nxt_0 = rpu_state_nxt[0];
   assign rpu_state_nxt_1 = rpu_state_nxt[1];
   // assign rpu_state_nxt_2 = rpu_state_nxt[2];
   // assign rpu_state_nxt_3 = rpu_state_nxt[3];

   wire [PTW-1:0] rpu_push_data_0;
   wire [PTW-1:0] rpu_push_data_1;
   // wire [PTW-1:0] rpu_push_data_2;
   // wire [PTW-1:0] rpu_push_data_3;

   assign rpu_push_data_0 = rpu_push_data[0];
   assign rpu_push_data_1 = rpu_push_data[1];
   // assign rpu_push_data_2 = rpu_push_data[2];
   // assign rpu_push_data_3 = rpu_push_data[3];

   wire [TREE_NUM_BITS-1:0] rpu_treeId_0 = rpu_treeId[0];
   wire [TREE_NUM_BITS-1:0] rpu_treeId_1 = rpu_treeId[1];
   // wire [TREE_NUM_BITS-1:0] rpu_treeId_2 = rpu_treeId[2];
   // wire [TREE_NUM_BITS-1:0] rpu_treeId_3 = rpu_treeId[3];

   wire [TREE_NUM_BITS-1:0]              tree_id_dn_0;






//-----------------------------------------------------------------------------
// Instantiations
//-----------------------------------------------------------------------------
genvar i,j;
generate
   for (i=0;i<LEVEL;i=i+1) begin : pifo_loop
      PIFO_SRAM #(
		.PTW (PTW),
      .MTW (MTW),
		.CTW (CTW),
      .LEVEL (LEVEL),
      .TREE_NUM (TREE_NUM),
      .ADW (ADW)
		 ) u_PIFO (
            .i_clk           ( i_clk                        ),
            .i_arst_n        ( i_arst_n                     ),

            .i_push          ( push_up      [i] ),
            .i_push_data     ( push_data_up [i] ),
            .i_pop           ( pop_up       [i] ),
            .o_pop_data      ( pop_data_up  [i] ),

            .o_push          ( push_dn      [i] ),
            .o_push_data     ( push_data_dn [i] ),
            .o_pop           ( pop_dn       [i] ),
            .i_pop_data      ( pop_data_dn  [i] ),
			
            .o_read          ( read         [i] ), 
            .i_read_data     ( read_data    [i] ), 
   
            .o_write         ( write        [i] ), 
            .o_write_data    ( write_data   [i] ),

            .i_tree_id        ( tree_id_up[i] ), 
            .o_tree_id        ( tree_id_dn[i] ),

            .i_my_addr       ( my_addr      [i] ),
            .o_child_addr    ( child_addr   [i] ),

            .i_level     ( level_up[i] ),
            .o_level     ( level_dn[i] ),
            .o_is_level0_pop     ( is_level0_pop[i] ),

            .o_read_addr     ( read_addr    [i] ),
            .o_write_addr    ( write_addr    [i] ),
            .o_state_nxt(rpu_state_nxt[i])	
         );
   end
   
   assign tree_id_dn_0 = tree_id_dn[0];
   for (i=0;i<LEVEL;i=i+1) begin
      assign o_pop_data[i] = pop_data_up[i];
      assign o_task_fifo_full[i] = TaskFIFO_full[i];
      assign o_tree_id[i] = tree_id_dn[i];
      assign o_is_level0_pop[i] = is_level0_pop[i];
   end

   for (i = 0; i < LEVEL; i++) begin
      always @ (posedge i_clk or negedge i_arst_n) begin
         if (!i_arst_n) begin
            level_wb[i] <= '0;
         end else begin
            level_wb[i] <= level_up[i];
         end
    end
end


   for (i=0;i<LEVEL-1;i=i+1) begin : loop1
      assign push_up[i+1]            = push_dn[i] ? 1'b1 
                                       : ((rpu_treeId[i+1] & {LEVEL_BITS{1'b1}}) == i+1) ? rpu_push[i+1] : 1'b0;
      assign push_data_up[i+1]       = push_dn[i] ? push_data_dn[i] 
                                       : ((rpu_treeId[i+1] & {LEVEL_BITS{1'b1}}) == i+1) ? rpu_push_data[i+1] : '1;
      assign pop_up[i+1]             = pop_dn[i] ? 1'b1 
                                       : ((rpu_treeId[i+1] & {LEVEL_BITS{1'b1}}) == i+1) ? rpu_pop[i+1] : 1'b0;
      assign pop_data_dn[i]          = (level_wb[i] == (LEVEL - 1)) ? {(MTW+PTW){1'b1}} 
                                       : pop_data_up[i+1]; // 和 level 有关，弄成全一
      assign my_addr[i+1]            = (push_dn[i] | pop_dn[i]) ? child_addr[i] : '0;
      assign tree_id_up[i+1]         = (push_dn[i] | pop_dn[i]) ? tree_id_dn[i] 
                                       : ((rpu_treeId[i+1] & {LEVEL_BITS{1'b1}}) == i+1) ? rpu_treeId[i+1] : '0;
      assign level_up[i+1]           = (push_dn[i] | pop_dn[i]) ? level_dn[i] : '0;
   end

   assign push_up[0]            = push_dn[LEVEL-1] ? 1'b1 
                                 : ((rpu_treeId[0] & {LEVEL_BITS{1'b1}}) == 0) ? rpu_push[0] : 1'b0;
   assign push_data_up[0]       = push_dn[LEVEL-1] ? push_data_dn[LEVEL-1] 
                                 : ((rpu_treeId[0] & {LEVEL_BITS{1'b1}}) == 0) ? rpu_push_data[0] : '1;
   assign pop_up[0]             = pop_dn[LEVEL-1] ? 1'b1 
                                 : ((rpu_treeId[0] & {LEVEL_BITS{1'b1}}) == 0) ? rpu_pop[0] : 1'b0;
   assign pop_data_dn[LEVEL - 1]   = (level_wb[LEVEL - 1] == (LEVEL - 1)) ? {(MTW+PTW){1'b1}} 
                                 : pop_data_up[0]; // 和 level 有关，弄成全一
   assign my_addr[0]            = (push_dn[LEVEL-1] | pop_dn[LEVEL-1]) ? child_addr[LEVEL-1] : '0;
   assign tree_id_up[0]         = (push_dn[LEVEL-1] | pop_dn[LEVEL-1]) ? tree_id_dn[LEVEL-1] 
                                 : ((rpu_treeId[0] & {LEVEL_BITS{1'b1}}) == 0) ? rpu_treeId[0] : '0;
   assign level_up[0]           = (push_dn[LEVEL-1] | pop_dn[LEVEL-1]) ? level_dn[LEVEL-1] : '0; 
   

   for (i=0; i<LEVEL; i=i+1) begin : sram_inst
      INFER_SDPRAM #( 
	      .DATA_WIDTH ( 2 * (CTW + MTW + PTW)              ), 
         .ADDR_WIDTH ( SRAM_ADW                           ), 
         .ARCH       ( 0                                  ), 
         .RDW_MODE   ( 1                                  ),
         .INIT_VALUE ( {2{{CTW{1'b0}},{(MTW+PTW){1'b1}}}} ) // Sub-tree size is zero. Pifo value are maximum initially.		 
	  ) u_INFER_SDPRAM 
	  (
         .i_clk      ( i_clk                                   ),     
         .i_arst_n   ( i_arst_n                                ),  

         .i_we       ( we[i]                                   ), 
         .i_waddr    ( waddr[i] ),    //地址宽度
         .i_wdata    ( wdata[i]                                ), 

         .i_re       ( re[i]                                   ),                                        
         .i_raddr    ( raddr[i] ),    
         .o_rdata    ( rdata[i]                                ) 
      );  

      assign re[i]    = read[i];
      assign we[i]    = write[i];
      assign waddr[i] = write_addr[i];
      assign raddr[i] = read_addr[i];	       
      assign wdata[i] = write_data[i];
   end     
   
   for (i=0;i<LEVEL;i=i+1) begin : loop
      assign read_data[i] = rdata[i];
   end

   for (i=0;i<LEVEL;i=i+1) begin
      TaskFIFO #(
         .PTW(PTW),
         .TREE_NUM(TREE_NUM),
         .BUF_SIZE(FIFO_SIZE)
      )tf(
         .clk(i_clk),
         .rst(!i_arst_n),
         .wr_en(push_TaskFIFO[i]),
         .rd_en(pop_TaskFIFO[i]),
         .buf_in(TaskFIFO_push_data[i]),
         .buf_out(TaskFIFO_pop_data[i]),
         .buf_empty(TaskFIFO_empty[i]),
         .buf_full(TaskFIFO_full[i]),
         .o_fifo_counter(fifo_counter[i])
      );
   end

   for (i=0;i<LEVEL;i=i+1) begin
      assign push_TaskFIFO[i] = (i_push[i] && i_pop[i]) ? 1'b0 : (i_push[i] || i_pop[i]) ? 1'b1 : 0;
      assign TaskFIFO_push_data[i] = (i_push[i] && i_pop[i]) ? '0 
      : i_push[i] ? {{1'b1}, i_tree_id[i], i_push_data[i]} 
      : i_pop[i] ? {{1'b0}, i_tree_id[i], {((MTW+PTW)){1'b0}}} : '0;
   end

   TaskDistribute #(
      .PTW(PTW),
      .LEVEL(LEVEL),
      .TREE_NUM(TREE_NUM)
	)td(
      .i_clk(i_clk),
      .i_arst_n(i_arst_n),

      .o_pop_TaskFIFO(pop_TaskFIFO),
      .i_TaskFIFO_data(TaskFIFO_pop_data),
      .i_TaskFIFO_empty(TaskFIFO_empty),

      .o_rpu_push(rpu_push),
      .o_rpu_pop(rpu_pop),
      .o_rpu_treeId(rpu_treeId),
      .o_rpu_push_data(rpu_push_data)
   );

endgenerate

//-----------------------------------------------------------------------------
// Sequential Logic
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Combinatorial Logic / Continuous Assignments
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Output Assignments
//-----------------------------------------------------------------------------

endmodule