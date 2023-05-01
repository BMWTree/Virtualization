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
module PIFO_SRAM_TOP
#(
   parameter PTW    = 16,       // Payload data width
   parameter MTW    = 0,        // Metdata width
   parameter CTW    = 10,       // Counter width
   parameter ADW    = 20,       // Address width
   parameter LEVEL  = 8         // Sub-tree level
)(
   // Clock and Reset
   input                            i_clk,
   input                            i_arst_n,
   
   // Push and Pop port to the whole PIFO tree
   input                            i_push,
   input [(MTW+PTW)-1:0]            i_push_data,
   
   input                            i_pop,
   output [(MTW+PTW)-1:0]           o_pop_data      
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


function integer find_level;
input integer a;
integer i,j,k;
begin
k=0;
find_level=0;
for (i=0;i<LEVEL;i=i+1) begin
   for (j=0;j<4**i;j=j+1) begin
      if (a==k) begin
		 find_level = i;
      end else begin
		 find_level = find_level;
      end
      k=k+1;     
   end
end
end
endfunction

function integer addr_idx_high;
input integer pifo_level;
integer i,j,k;
begin
   j=0;
   k=0;
   for (i=0;i<pifo_level;i=i+1) begin
      if (i==0) begin
         k=0;
	   end else begin
	     k=$clog2(4**i);
	   end
	   j=j+k;
   end
   addr_idx_high = j;
end
endfunction

function integer addr_idx_low;
input integer pifo_level;
integer i,j,k;
begin
   j=0;
   k=0;
   for (i=0;i<pifo_level;i=i+1) begin
      if (i==0) begin
         k=0;
	  end else begin
	     k=$clog2(4**(i-1));
	  end
	  j=j+k;
   end
   if (pifo_level == 1) begin
      addr_idx_low = 0;
   end else begin
      addr_idx_low = j+1;
   end
end
endfunction



//-----------------------------------------------------------------------------
// Register and Wire Declarations
//-----------------------------------------------------------------------------

   wire                                push_ready;

   wire                                push_rpu_read;
   wire                                push_rpu_write;
   reg  [4*(CTW+MTW+PTW)-1:0]          push_read_data;
   wire [4*(CTW+MTW+PTW)-1:0]          push_write_data;
   wire [$clog2(LEVEL)-1:0]              push_read_level;
   wire [$clog2(LEVEL)-1:0]              push_write_level;
   wire [ADW-1:0]                      push_read_addr;
   wire [ADW-1:0]                      push_write_addr;


   wire                                pop_ready;

   wire [1:0]                          pop_rpu_read;
   wire [1:0]                          pop_rpu_write;
   reg  [4*(CTW+MTW+PTW)-1:0]          pop_read_data [0:1];
   wire [4*(CTW+MTW+PTW)-1:0]          pop_write_data [0:1];
   wire [$clog2(LEVEL)-1:0]              pop_read_level [0:1];
   wire [$clog2(LEVEL)-1:0]              pop_write_level [0:1];
   wire [ADW-1:0]                      pop_read_addr [0:1];
   wire [ADW-1:0]                      pop_write_addr [0:1];
 
   
   wire [LEVEL-1:0]                    we;
   wire [addr_idx_high(LEVEL):0]       waddr;
   wire [4*(CTW+MTW+PTW)-1:0]          wdata        [0:LEVEL-1];
      
   wire [LEVEL-1:0]                    re;
   wire [addr_idx_high(LEVEL):0]       raddr;
   wire [4*(CTW+MTW+PTW)-1:0]          rdata        [0:LEVEL-1];   



//-----------------------------------------------------------------------------
// Instantiations
//-----------------------------------------------------------------------------
genvar i,j;
generate
         PUSH_RPU #(
            .PTW (PTW),
            .MTW (MTW),
            .CTW (CTW),
            .ADW (ADW),
            .LEVEL (LEVEL)
         ) u_PUSH_RPU (
            .i_clk           ( i_clk            ),
            .i_arst_n        ( i_arst_n         ),

            .ready           ( push_ready       ),

            .i_push          ( i_push           ),
            .i_push_data     ( i_push_data      ),
			
            .o_read          ( push_rpu_read    ), 
            .i_read_data     ( push_read_data   ), 
   
            .o_write         ( push_rpu_write   ), 
            .o_write_data    ( push_write_data ),

            .o_read_level    ( push_read_level  ),
            .o_write_level   ( push_write_level ),
            .o_read_addr     ( push_read_addr   ),
            .o_write_addr    ( push_write_addr  )		
         );

         POP_RPU_PAIR #(
            .PTW (PTW),
            .MTW (MTW),
            .CTW (CTW),
            .ADW (ADW),
            .LEVEL (LEVEL)
         ) u_POP_RPU_PAIR (
            .i_clk           ( i_clk            ),
            .i_arst_n        ( i_arst_n         ),

            .ready           ( pop_ready        ),

            .i_pop           ( i_pop            ),
            .o_pop_data      ( o_pop_data       ),
			
            .o_read          ( pop_rpu_read     ), 
            .i_read_data     ( pop_read_data    ), 
   
            .o_write         ( pop_rpu_write    ), 
            .o_write_data    ( pop_write_data   ),

            .o_read_level    ( pop_read_level   ),
            .o_write_level   ( pop_write_level  ),
            .o_read_addr     ( pop_read_addr    ),
            .o_write_addr    ( pop_write_addr   )		
         );
   

   for (i=1; i<LEVEL; i=i+1) begin : sram_inst
      INFER_SDPRAM #( 
	      .DATA_WIDTH ( 4 * (CTW + MTW + PTW)              ), 
         .ADDR_WIDTH ( 2 * i                              ), 
         .ARCH       ( 0                                  ), 
         .RDW_MODE   ( 1                                  ),
         .INIT_VALUE ( {4{{CTW{1'b0}},{(MTW+PTW){1'b1}}}} ) // Sub-tree size is zero. Pifo value are maximum initially.		 
	  ) u_INFER_SDPRAM 
	  (
         .i_clk      ( i_clk                                   ),     
         .i_arst_n   ( i_arst_n                                ),  

         .i_we       ( we[i]                                   ), 
         .i_waddr    ( waddr[addr_idx_high(i+1):addr_idx_low(i+1)] ),    //地址宽度
         .i_wdata    ( wdata[i]                                ), 

         .i_re       ( re[i]                                   ),                                        
         .i_raddr    ( raddr[addr_idx_high(i+1):addr_idx_low(i+1)] ),    
         .o_rdata    ( rdata[i]                                ) 
      );  

   end     
   
    
     INFER_SDPRAM #( 
	      .DATA_WIDTH ( 4 * (CTW + MTW + PTW)              ), 
         .ADDR_WIDTH ( 1                                  ), 
         .ARCH       ( 0                                  ), 
         .RDW_MODE   ( 1                                  ),
         .INIT_VALUE ( {4{{CTW{1'b0}},{(MTW+PTW){1'b1}}}} ) // Sub-tree size is zero. Pifo value are maximum initially.		 
	  ) root 
	  (
         .i_clk      ( i_clk                                   ),     
         .i_arst_n   ( i_arst_n                                ),  

         .i_we       ( we[0]                                   ), 
         .i_waddr    ( waddr[addr_idx_high(1):addr_idx_low(1)] ),    //地址宽度
         .i_wdata    ( wdata[0]                                ), 

         .i_re       ( re[0]                                   ),                                        
         .i_raddr    ( raddr[addr_idx_high(1):addr_idx_low(1)] ),    
         .o_rdata    ( rdata[0]                                ) 
      );   
   
   
   for (i=0;i<LEVEL;i=i+1) begin : loop
      assign re[i]    = (pop_rpu_read[0] & i == pop_read_level[0]) ? 1'b1 :
                        (pop_rpu_read[1] & i == pop_read_level[1]) ? 1'b1 :
                        (push_rpu_read   & i == push_read_level  ) ? 1'b1 : '0;
      assign we[i]    = (pop_rpu_write[0] & i == pop_write_level[0]) ? 1'b1 :
                        (pop_rpu_write[1] & i == pop_write_level[1]) ? 1'b1 :
                        (push_rpu_write   & i == push_write_level  ) ? 1'b1 : '0;


      assign waddr[addr_idx_high(i+1):addr_idx_low(i+1)] 
      = (pop_rpu_write[0] & i == pop_write_level[0]) ? pop_write_addr[0] :
        (pop_rpu_write[1] & i == pop_write_level[1]) ? pop_write_addr[1] :
        (push_rpu_write   & i == push_write_level  ) ? push_write_addr   : '0;

      assign raddr[addr_idx_high(i+1):addr_idx_low(i+1)] 
      = (pop_rpu_read[0] & i == pop_read_level[0]) ? pop_read_addr[0] :
        (pop_rpu_read[1] & i == pop_read_level[1]) ? pop_read_addr[1] :
        (push_rpu_read   & i == push_read_level  ) ? push_read_addr   : '0;      


      assign wdata[i] = (pop_rpu_write[0] & i == pop_write_level[0]) ? pop_write_data[0] :
                        (pop_rpu_write[1] & i == pop_write_level[1]) ? pop_write_data[1] :
                        (push_rpu_write   & i == push_write_level  ) ? push_write_data   : 
                        {4{{CTW{1'b0}},{(MTW+PTW){1'b1}}}};

   end

endgenerate

//-----------------------------------------------------------------------------
// Sequential Logic
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Combinatorial Logic / Continuous Assignments
//-----------------------------------------------------------------------------

   assign pop_read_data[0] = rdata[pop_write_level[0]];
   assign pop_read_data[1] = rdata[pop_write_level[1]];
   assign push_read_data   = rdata[push_write_level];

//-----------------------------------------------------------------------------
// Output Assignments
//-----------------------------------------------------------------------------

endmodule