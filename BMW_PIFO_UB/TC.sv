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
reg [9:0]      push_data;

integer        data_gen [9:0];
integer        data_exp [9:0];
integer        sort_5 [4:0];
integer        i;
reg [3:0]      cnt;
integer        errors;



reg [9:0]      pop_data;
//-----------------------------------------------------------------------------
// Instantiations
//-----------------------------------------------------------------------------
PIFO_TOP 
#(
   .DWIDTH      ( 10             ),
   .LEVEL       ( 2              )
) u_PIFO_TOP (
   // Clock and Reset
   .i_clk       ( clk            ),
   .i_arst_n    ( arst_n         ),
   
   // Push and Pop port to the whole PIFO tree
   .i_push      ( push           ),
   .i_push_data ( push_data[9:0] ),
   
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
   for (i=0;i<10;i=i+1) begin
      data_gen[i] = $dist_uniform(seed,0,1023);
   end
   for (i=0;i<10;i=i+1) begin
      @ (posedge clk);
      if (i==0) begin
         data_exp[9] = sort_min(data_gen[9:5]);
         sort_5[4:0] = {sort_min(data_gen[9:5]), sort_middle_1(data_gen[9:5]), sort_middle_2(data_gen[9:5]), sort_middle_3(data_gen[9:5]), sort_max(data_gen[9:5])};
	  end else if (i==1) begin
         data_exp[8] = sort_min({sort_5[3:0],data_gen[4]});
         sort_5[4:0] = {sort_min({sort_5[3:0],data_gen[4]}), sort_middle_1({sort_5[3:0],data_gen[4]}), sort_middle_2({sort_5[3:0],data_gen[4]}), sort_middle_3({sort_5[3:0],data_gen[4]}), sort_max({sort_5[3:0],data_gen[4]})};
	  end else if (i==2) begin
         data_exp[7] = sort_min({sort_5[3:0],data_gen[3]});
         sort_5[4:0] = {sort_min({sort_5[3:0],data_gen[3]}), sort_middle_1({sort_5[3:0],data_gen[3]}), sort_middle_2({sort_5[3:0],data_gen[3]}), sort_middle_3({sort_5[3:0],data_gen[3]}), sort_max({sort_5[3:0],data_gen[3]})};
	  end else if (i==3) begin
         data_exp[6] = sort_min({sort_5[3:0],data_gen[2]});
         sort_5[4:0] = {sort_min({sort_5[3:0],data_gen[2]}), sort_middle_1({sort_5[3:0],data_gen[2]}), sort_middle_2({sort_5[3:0],data_gen[2]}), sort_middle_3({sort_5[3:0],data_gen[2]}), sort_max({sort_5[3:0],data_gen[2]})};
	  end else if (i==4) begin
         data_exp[5] = sort_min({sort_5[3:0],data_gen[1]});
         sort_5[4:0] = {sort_min({sort_5[3:0],data_gen[1]}), sort_middle_1({sort_5[3:0],data_gen[1]}), sort_middle_2({sort_5[3:0],data_gen[1]}), sort_middle_3({sort_5[3:0],data_gen[1]}), sort_max({sort_5[3:0],data_gen[1]})};
      end else if (i==5) begin
         data_exp[4] = sort_min({sort_5[3:0],data_gen[0]});
         sort_5[4:0] = {sort_min({sort_5[3:0],data_gen[0]}), sort_middle_1({sort_5[3:0],data_gen[0]}), sort_middle_2({sort_5[3:0],data_gen[0]}), sort_middle_3({sort_5[3:0],data_gen[0]}), sort_max({sort_5[3:0],data_gen[0]})};
      end else if (i==6) begin
         data_exp[3] = sort_min({sort_5[3:0],1024});
         sort_5[4:0] = {sort_min({sort_5[3:0],1024}), sort_middle_1({sort_5[3:0],1024}), sort_middle_2({sort_5[3:0],1024}), sort_middle_3({sort_5[3:0],1024}), sort_max({sort_5[3:0],1024})};
      end else if (i==7) begin
         data_exp[2] = sort_min({sort_5[3:0],1024});
         sort_5[4:0] = {sort_min({sort_5[3:0],1024}), sort_middle_1({sort_5[3:0],1024}), sort_middle_2({sort_5[3:0],1024}), sort_middle_3({sort_5[3:0],1024}), sort_max({sort_5[3:0],1024})};
      end else if (i==8) begin
         data_exp[1] = sort_min({sort_5[3:0],1024});
         sort_5[4:0] = {sort_min({sort_5[3:0],1024}), sort_middle_1({sort_5[3:0],1024}), sort_middle_2({sort_5[3:0],1024}), sort_middle_3({sort_5[3:0],1024}), sort_max({sort_5[3:0],1024})};
      end else if (i==9) begin
         data_exp[0] = sort_min({sort_5[3:0],1024});
         sort_5[4:0] = {sort_min({sort_5[3:0],1024}), sort_middle_1({sort_5[3:0],1024}), sort_middle_2({sort_5[3:0],1024}), sort_middle_3({sort_5[3:0],1024}), sort_max({sort_5[3:0],1024})};
      end	  
   end   
end

initial
begin
   // initial value
   clk    = 1'b0;
   arst_n = 1'b0;    
   seed   = 1;
   push   = 1'b0;
   pop    = 1'b0;
   
   
   #100;
   arst_n = 1'b1;
   
   // 1
   @ (posedge clk);
   fork 
      push           = 1'b1;
      push_data[9:0] = data_gen[9];
   join
   
   // 2
   @ (posedge clk);
   fork 
      push           = 1'b1;
      push_data[9:0] = data_gen[8];
   join

   // 3
   @ (posedge clk);
   fork 
      push           = 1'b1;
      push_data[9:0] = data_gen[7];
   join

   // 4
   @ (posedge clk);
   fork 
      push           = 1'b1;
      push_data[9:0] = data_gen[6];
   join

   // 5
   @ (posedge clk);
   fork 
      push           = 1'b1;
      push_data[9:0] = data_gen[5];
   join
   
   // 6
   @ (posedge clk);
   fork
      push           = 1'b1;
	  push_data[9:0] = data_gen[4];
   join

   // 7
   @ (posedge clk);
   fork
      push           = 1'b1;
	  push_data[9:0] = data_gen[3];
   join

   // 8
   @ (posedge clk);
   fork
      push           = 1'b1;
	  push_data[9:0] = data_gen[2];
   join

   // 9
   @ (posedge clk);
   fork
      push           = 1'b1;
	  push_data[9:0] = data_gen[1];
   join

   // 10
   @ (posedge clk);
   fork
      push           = 1'b1;
	  push_data[9:0] = data_gen[0];
   join
     
   @ (posedge clk);
   fork
      pop            = 1'b1;
      push           = 1'b0;
      push_data[9:0] = 'd0;
   join	  
   
   
   
//      @ (posedge clk);
//   fork
//      pop            = 1'b0;
//      push           = 1'b1;
//      push_data[9:0] = 'd488;
//   join	  
   
   
   
   
   
   //16
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	  
   
//      @ (posedge clk);
//   fork
//      pop            = 1'b0;
//      push           = 1'b1;
//      push_data[9:0] = 'd488;
//   join	  
   
   
   //17
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	 
   
//         @ (posedge clk);
//   fork
//      pop            = 1'b0;
//      push           = 1'b1;
//      push_data[9:0] = 'd488;
//   join	  
   
   //18
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	  
   
         @ (posedge clk);
   fork
      pop            = 1'b0;
      push           = 1'b1;
      push_data[9:0] = 'd488;
   join	  
   
   //19
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	   
   
         @ (posedge clk);
   fork
      pop            = 1'b0;
      push           = 1'b1;
      push_data[9:0] = 'd488;
   join	  
   
   //20
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	  
   
         @ (posedge clk);
   fork
      pop            = 1'b0;
      push           = 1'b1;
      push_data[9:0] = 'd488;
   join	  
   
        // 15
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	  
   
         @ (posedge clk);
   fork
      pop            = 1'b0;
      push           = 1'b1;
      push_data[9:0] = 'd488;
   join	  
   
   //16
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	  
   
         @ (posedge clk);
   fork
      pop            = 1'b0;
      push           = 1'b1;
      push_data[9:0] = 'd488;
   join	  
   
   //17
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	 
   
   
         @ (posedge clk);
   fork
      pop            = 1'b0;
      push           = 1'b1;
      push_data[9:0] = 'd488;
   join	  
   
   //18
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	  
   
         @ (posedge clk);
   fork
      pop            = 1'b0;
      push           = 1'b1;
      push_data[9:0] = 'd488;
   join	  
   
   //19
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	   
   
         @ (posedge clk);
   fork
      pop            = 1'b0;
      push           = 1'b1;
      push_data[9:0] = 'd488;
   join	  
   
   //20
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	  
   
        // 15
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	  
   
   //16
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	  
   
   //17
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	 
   
   //18
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	  
   
   //19
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	   
   
   //20
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	  
   
        // 15
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	  
   
   //16
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	  
   
   //17
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	 
   
   //18
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	  
   
   //19
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	   
   
   //20
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b1;
      push_data[9:0] = 'd0;
   join	  

   // 21 and up
   @ (posedge clk);
   fork
      push           = 1'b0;
      pop            = 1'b0;
      push_data[9:0] = 'd0;
   join	  

   #1000;
   if (errors == 0) begin
      $display("Info: The pop data match what it should be and the TC is passed.");   
   end else begin
      $display("Error: There are %d errors happened and the TC is failed.", errors);   
   end
   
   $stop;

  end
//-----------------------------------------------------------------------------
// Functions and Tasks
//-----------------------------------------------------------------------------
function integer sort_min;
input integer in [4:0];
integer i,j;
integer temp;
begin
   for (i=0; i<5; i=i+1) begin
      for (j=0;j<4-i;j=j+1) begin
	     if (in[j] > in[j+1]) begin
            temp    = in[j];
            in[j]   = in[j+1];
            in[j+1] = temp;			
		 end
	  end
   end
   sort_min = in[0];
end
endfunction

function integer sort_middle_1;
input integer in [4:0];
integer i,j;
integer temp;
begin
   for (i=0; i<5; i=i+1) begin
      for (j=0;j<4-i;j=j+1) begin
	     if (in[j] > in[j+1]) begin
            temp    = in[j];
            in[j]   = in[j+1];
            in[j+1] = temp;			
		 end
	  end
   end
   sort_middle_1 = in[1];
end
endfunction

function integer sort_middle_2;
input integer in [4:0];
integer i,j;
integer temp;
begin
   for (i=0; i<5; i=i+1) begin
      for (j=0;j<4-i;j=j+1) begin
	     if (in[j] > in[j+1]) begin
            temp    = in[j];
            in[j]   = in[j+1];
            in[j+1] = temp;			
		 end
	  end
   end
   sort_middle_2 = in[2];
end
endfunction

function integer sort_middle_3;
input integer in [4:0];
integer i,j;
integer temp;
begin
   for (i=0; i<5; i=i+1) begin
      for (j=0;j<4-i;j=j+1) begin
	     if (in[j] > in[j+1]) begin
            temp    = in[j];
            in[j]   = in[j+1];
            in[j+1] = temp;			
		 end
	  end
   end
   sort_middle_3 = in[3];
end
endfunction

function integer sort_max;
input integer in [4:0];
integer i,j;
integer temp;
begin
   for (i=0; i<5; i=i+1) begin
      for (j=0;j<4-i;j=j+1) begin
	     if (in[j] > in[j+1]) begin
            temp    = in[j];
            in[j]   = in[j+1];
            in[j+1] = temp;			
		 end
	  end
   end
   sort_max = in[4];
end
endfunction

//-----------------------------------------------------------------------------
// Sequential Logic
//-----------------------------------------------------------------------------
always @ (posedge clk or negedge arst_n)
begin
   if (!arst_n) begin
      cnt[3:0] <= 4'd9;  
      errors   <= 0;	  
   end else begin
      if (pop) #1 begin     
         if (u_PIFO_TOP.o_pop_data != data_exp[cnt]) begin
		    $display ("Error: The %d th data is not expected. Expected %h but received %h.", cnt[3:0], data_exp[cnt[3:0]], u_PIFO_TOP.o_pop_data);
			errors <= errors + 1;
		 end else begin
		    $display ("Info: The %d th data is expected. Expected %h and received %h.", cnt[3:0], data_exp[cnt[3:0]], u_PIFO_TOP.o_pop_data);
		 end
         cnt[3:0] <= cnt[3:0] - 4'd1;		 
	  end
	  
   end
end 
//-----------------------------------------------------------------------------
// Combinatorial Logic / Continuous Assignments
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Output Assignments
//-----------------------------------------------------------------------------  

endmodule
