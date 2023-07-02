`timescale 1ns/10ps    //cycle

/*-----------------------------------------------------------------------------

Proprietary and Confidential Information

Module: TC.v
Author: Xiaoguang Li
Date  : 06/2/2019

Description: Top-level module simulation. 

			 
Issues:  

-----------------------------------------------------------------------------*/

//-----------------------------------------------------------------------------
// Module Port Definition
//-----------------------------------------------------------------------------
module TC();

//-----------------------------------------------------------------------------
// Include Files
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Register and Wire Declarations
//-----------------------------------------------------------------------------
reg            clk;
reg            arst_n;

integer        seed;
integer        R;
reg            push;
reg            pop;
reg [7:0]      push_data;
reg [1:0]      tree_id;
integer        data_gen [49:0];
integer        i;
wire [7:0]      pop_data;
//-----------------------------------------------------------------------------
// Instantiations
//-----------------------------------------------------------------------------
PIFO_SRAM_TOP 
#(
   .PTW   (8),
   .MTW   (0),
   .CTW   (8),
   .LEVEL (4)
) u_PIFO_TOP (
   .i_clk       ( clk            ),
   .i_arst_n    ( arst_n         ),
   
   .i_tree_id   ( tree_id        ),
   .i_push      ( push           ),
   .i_push_data ( push_data[7:0] ),
   
   .i_pop       ( pop            ),
   .o_pop_data  ( pop_data       )      
);

//-----------------------------------------------------------------------------
// Clocks
//-----------------------------------------------------------------------------
always #4 begin clk = ~clk; end
  
//-----------------------------------------------------------------------------
// Initial
//-----------------------------------------------------------------------------  

initial begin            
   $dumpfile("wave.vcd"); // 指定用作dumpfile的文件
   $dumpvars; // dump all vars
end

initial begin
    for (i=0;i<50;i=i+1) begin
      data_gen[i] = $dist_uniform(seed,0,256);
    end
end

initial
begin
   clk    = 1'b0;
   arst_n = 1'b0;    
   seed   = 1;
   push   = 1'b0;
   pop    = 1'b0;
   tree_id = '0;
 
   #400;
   arst_n = 1'b1;
   for (i=0; i<24; i=i+1) begin
     @ (posedge clk);
       fork 
          push           = 1'b1;
          push_data[7:0] = data_gen[i] - 1;
          tree_id = (2*i) % 4;
       join
    end   


   @ (posedge clk);
   fork 
     push           = 1'b0;
     push_data[7:0] = 'd0;
     tree_id = '0;
   join
   @ (posedge clk);
   fork 
     push           = 1'b0;
     push_data[7:0] = 'd0;
     tree_id = '0;
   join
   @ (posedge clk);
   fork 
     push           = 1'b0;
     push_data[7:0] = 'd0;
     tree_id = '0;
   join
   @ (posedge clk);
   fork 
     push           = 1'b0;
     push_data[7:0] = 'd0;
     tree_id = '0;
   join
   @ (posedge clk);
   fork 
     push           = 1'b0;
     push_data[7:0] = 'd0;
     tree_id = '0;
   join

   @ (posedge clk);
   for (i=0; i<24; i=i+1) begin
      pop = 1'b1;
      // tree_id = (4*i) % 4; // pop tree 0
      tree_id = (4*i+2) % 4; // pop tree 2
      @ (posedge clk);
      pop = 1'b0;
      // tree_id = 2'b00; // pop tree 0
      tree_id = 2'b10; // pop tree 2
      @ (posedge clk);
   end   
  
   #1000;   
   $stop;

  end
//-----------------------------------------------------------------------------
// Functions and Tasks
//-----------------------------------------------------------------------------

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
