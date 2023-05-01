`timescale 1ns / 10ps
/*-----------------------------------------------------------------------------

Proprietary and Confidential Information

Module: PIFO_SRAM.v
Author: Zhiyu Zhang
Date  : 03/10/2023

Description: Instead of using FFs to implement PIFO, this module uses SRAM
             so that the whole PIFO tree can be extended to more layers. 
			 
Issues:  

-----------------------------------------------------------------------------*/

//-----------------------------------------------------------------------------
// Module Port Definition
//-----------------------------------------------------------------------------
module PUSH_RPU 
#(
   parameter PTW  = 16,  // Payload data width
   parameter MTW  = 0,  // Metdata width
   parameter CTW  = 10,  // Counter width
   parameter ADW  = 20,   // Address width
   parameter LEVEL = 8    // Tree level
)(
   // Clock and Reset
   input                          i_clk,         // I - Clock
   input                          i_arst_n,      // I - Active Low Async Reset
  
   output                         ready,

   // From/To Parent 
   input                          i_push,        // I - Push Command from Parent
   input  [(MTW+PTW)-1:0]         i_push_data,   // I - Push Data from Parent
   
   // From/To SRAM
   output                         o_read,        // O - SRAM Read
   input  [4*(CTW+MTW+PTW)-1:0]   i_read_data,   // I - SRAM Read Data {sub_tree_size3,pifo_val3,sub_tree_size2,pifo_val2,sub_tree_size1,pifo_val1,sub_tree_size0,pifo_val0}
   
   output                         o_write,       // O - SRAM Write
   output [4*(CTW+MTW+PTW)-1:0]   o_write_data,  // O - SRAM Write Data {sub_tree_size3,pifo_val3,sub_tree_size2,pifo_val2,sub_tree_size1,pifo_val1,sub_tree_size0,pifo_val0}
   
   output [$clog2(LEVEL)-1:0]     o_read_level,
   output [$clog2(LEVEL)-1:0]     o_write_level,
   output [ADW-1:0]               o_read_addr,
   output [ADW-1:0]               o_write_addr
);

//-----------------------------------------------------------------------------
// Include Files
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------------------
localparam ST_IDLE     = 1'b0,
			  ST_PUSH     = 1'b1;

//-----------------------------------------------------------------------------
// Register and Wire Declarations
//-----------------------------------------------------------------------------
   // State Machine
   reg             fsm;

   wire            cur_continue;
   wire            done_before;
   
   // SRAM Read/Write
   wire                  read;
   reg                  write;
   reg [4*(CTW+MTW+PTW)-1:0] wdata;
   
   // Push to child
   reg [(MTW+PTW)-1:0]         push_data;
   reg [(MTW+PTW)-1:0]         push_data_nxt;
	  
   reg [1:0]             min_sub_tree;

	//for parent/child node
   reg [ADW-1:0]         addr;
   reg [ADW-1:0]         addr_nxt;

   // curent level ie write_level
   reg [$clog2(LEVEL)-1:0]             cur_level;
   
   

   
   

     
//-----------------------------------------------------------------------------
// Instantiations
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
// Functions and Tasks
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Sequential Logic
//-----------------------------------------------------------------------------
always @ (posedge i_clk or negedge i_arst_n)
    begin
        if (!i_arst_n) begin
            fsm     <= ST_IDLE;
            push_data <= '1;	
            addr      <= '0;
            cur_level <= '0;

        end else begin
            case (fsm)
                ST_IDLE: begin
                    if (i_push) begin
                        fsm     <= ST_PUSH;
                        push_data <= push_data_nxt;
                        addr      <= addr_nxt;
                        cur_level <= '0;
                    end else begin
                        fsm    <= ST_IDLE;
                        push_data <= '1;
                        addr      <= '0;
                        cur_level <= '0;
                    end
                end
                ST_PUSH: begin
                    if ((&cur_level) | done_before) begin // cur_level == '1 or done_before
                        fsm    <= i_push ? ST_PUSH : ST_IDLE;
                        push_data <= i_push ? push_data_nxt : '1;
                        addr      <= '0;
                        cur_level <= '0;
                    end else begin // cur_level != '1 or not done_before, continue push
                        fsm     <= ST_PUSH;
                        push_data <= push_data_nxt;
                        addr      <= addr_nxt;
                        cur_level <= cur_level+1;
                    end
                end
            endcase
        end	  
    end
   
//-----------------------------------------------------------------------------
// Combinatorial Logic / Continuous Assignments
//-----------------------------------------------------------------------------
always @ *
   begin
        if (fsm == ST_PUSH) begin
	     case (min_sub_tree[1:0])
		   2'b00: begin // push 0
			   write          = 1'b1;
			   addr_nxt     = cur_continue ? 4 * addr : '0;
			   if (i_read_data[PTW-1:0] != {PTW{1'b1}}) begin
				  if (push_data[PTW-1:0] < i_read_data[PTW-1:0]) begin
		            push_data_nxt = cur_continue ? i_read_data[MTW+PTW-1:0] : i_push_data;
					   wdata     = {i_read_data[4*(MTW+PTW+CTW)-1:(MTW+PTW+CTW)], i_read_data[(MTW+PTW+CTW)-1:(MTW+PTW)]+{{(CTW-1){1'b0}},1'b1}, push_data};					 
				  end else begin
		            push_data_nxt = cur_continue ? push_data : i_push_data;
				      wdata     = {i_read_data[4*(MTW+PTW+CTW)-1:(MTW+PTW+CTW)], i_read_data[(MTW+PTW+CTW)-1:(MTW+PTW)]+{{(CTW-1){1'b0}},1'b1}, i_read_data[(MTW+PTW)-1:0]};					 
                  end						
			   end else begin
		         push_data_nxt    = cur_continue ? '1 : i_push_data;
 				   wdata        = {i_read_data[4*(MTW+PTW+CTW)-1:(MTW+PTW+CTW)], i_read_data[(MTW+PTW+CTW)-1:(MTW+PTW)]+{{(CTW-1){1'b0}},1'b1}, push_data};					 
			   end
			end

			2'b01: begin // push 1
			   write           = 1'b1;
			   addr_nxt      = cur_continue ? 4 * addr + 1 : '0;
			   if (i_read_data[2*PTW+(MTW+CTW)-1:(MTW+PTW+CTW)] != {PTW{1'b1}}) begin
				  if (push_data[(PTW)-1:0] < i_read_data[2*PTW+MTW+CTW-1:(MTW+PTW+CTW)]) begin
 		             push_data_nxt = cur_continue ? i_read_data[(2*(MTW+PTW)+CTW)-1:(CTW+MTW+PTW)] : i_push_data;
					 wdata     = {i_read_data[4*(CTW+MTW+PTW)-1:2*(CTW+MTW+PTW)], i_read_data[2*(CTW+MTW+PTW)-1:2*(MTW+PTW)+CTW]+{{(CTW-1){1'b0}},1'b1}, push_data, i_read_data[(CTW+MTW+PTW)-1:0]};
				  end else begin
		             push_data_nxt = cur_continue ? push_data : i_push_data;
					 wdata     = {i_read_data[4*(CTW+MTW+PTW)-1:2*(CTW+MTW+PTW)], i_read_data[2*(CTW+MTW+PTW)-1:2*(MTW+PTW)+CTW]+{{(CTW-1){1'b0}},1'b1}, i_read_data[2*(MTW+PTW)+CTW-1:0]};
				  end
			   end else begin
		          push_data_nxt    = cur_continue ? '1 : i_push_data;
 				  wdata        = {i_read_data[4*(CTW+MTW+PTW)-1:2*(CTW+MTW+PTW)], i_read_data[2*(CTW+MTW+PTW)-1:2*(MTW+PTW)+CTW]+{{(CTW-1){1'b0}},1'b1}, push_data, i_read_data[(CTW+MTW+PTW)-1:0]};
			   end
			end

			2'b10: begin // push 2
			   write           = 1'b1;
			   addr_nxt      = cur_continue ? 4 * addr + 2 : '0;
			   if (i_read_data[(3*PTW+2*(MTW+CTW))-1:2*(MTW+PTW+CTW)] != {PTW{1'b1}}) begin
				  if (push_data[(PTW)-1:0] < i_read_data[(3*PTW+2*(MTW+CTW))-1:2*(MTW+PTW+CTW)]) begin
 		             push_data_nxt = cur_continue ? i_read_data[(3*(MTW+PTW)+2*CTW)-1:2*(CTW+MTW+PTW)] : i_push_data;
  					 wdata     = {i_read_data[4*(CTW+MTW+PTW)-1:3*(CTW+MTW+PTW)], i_read_data[3*(CTW+MTW+PTW)-1:3*(MTW+PTW)+2*CTW]+{{(CTW-1){1'b0}},1'b1}, push_data, i_read_data[2*(CTW+MTW+PTW)-1:0]};
				  end else begin
 		             push_data_nxt = cur_continue ? push_data : i_push_data;
  					 wdata     = {i_read_data[4*(CTW+MTW+PTW)-1:3*(CTW+MTW+PTW)], i_read_data[3*(CTW+MTW+PTW)-1:3*(MTW+PTW)+2*CTW]+{{(CTW-1){1'b0}},1'b1}, i_read_data[3*(MTW+PTW)+2*CTW-1:0]};
                  end						
			   end else begin
		          push_data_nxt    = cur_continue ? '1 : i_push_data;
 				  wdata        = {i_read_data[4*(CTW+MTW+PTW)-1:3*(CTW+MTW+PTW)], i_read_data[3*(CTW+MTW+PTW)-1:3*(MTW+PTW)+2*CTW]+{{(CTW-1){1'b0}},1'b1}, push_data, i_read_data[2*(CTW+MTW+PTW)-1:0]};
			   end
			end
			2'b11: begin // push 3
			   write           = 1'b1;
			   addr_nxt      = cur_continue ? 4 * addr + 3 : '0;
			   if (i_read_data[(4*PTW+3*(MTW+CTW))-1:3*(MTW+PTW+CTW)] != {PTW{1'b1}}) begin
				  if (push_data[(PTW)-1:0] < i_read_data[(4*PTW+3*(MTW+CTW))-1:3*(MTW+PTW+CTW)]) begin
		             push_data_nxt = cur_continue ? i_read_data[(4*(MTW+PTW)+3*CTW)-1:3*(CTW+MTW+PTW)] : i_push_data;
					 wdata     = {i_read_data[4*(CTW+MTW+PTW)-1:4*(MTW+PTW)+3*CTW]+{{(CTW-1){1'b0}},1'b1}, push_data, i_read_data[3*(CTW+MTW+PTW)-1:0]};
				  end else begin
		             push_data_nxt = cur_continue ? push_data : i_push_data;
					 wdata     = {i_read_data[4*(CTW+MTW+PTW)-1:4*(MTW+PTW)+3*CTW]+{{(CTW-1){1'b0}},1'b1}, i_read_data[4*(MTW+PTW)+3*CTW-1:0]};
                  end						
			   end else begin
		          push_data_nxt    = cur_continue ? '1 : i_push_data;
  				  wdata        = {i_read_data[4*(CTW+MTW+PTW)-1:4*(MTW+PTW)+3*CTW]+{{(CTW-1){1'b0}},1'b1}, push_data, i_read_data[3*(CTW+MTW+PTW)-1:0]};
			   end
		    end
		 endcase		
        end else begin
            push_data_nxt   = i_push_data;
            write       = 1'b0;
            wdata       = '1;
            addr_nxt  = '0;
        end	  
   end
   
always @ *
   begin
      // Find the minimum sub-tree. 
      if (i_read_data[(CTW+MTW+PTW)-1:(MTW+PTW)] <= i_read_data[2*(CTW+MTW+PTW)-1:2*(MTW+PTW)+CTW] &&
	      i_read_data[(CTW+MTW+PTW)-1:(MTW+PTW)] <= i_read_data[3*(CTW+MTW+PTW)-1:3*(MTW+PTW)+2*CTW] &&
		  i_read_data[(CTW+MTW+PTW)-1:(MTW+PTW)] <= i_read_data[4*(CTW+MTW+PTW)-1:4*(MTW+PTW)+3*CTW]) begin
	     min_sub_tree[1:0] = 2'b00;	  
      end else if (i_read_data[2*(CTW+MTW+PTW)-1:2*(MTW+PTW)+CTW] <= i_read_data[(CTW+MTW+PTW)-1:(MTW+PTW)] &&
	      i_read_data[2*(CTW+MTW+PTW)-1:2*(MTW+PTW)+CTW] <= i_read_data[3*(CTW+MTW+PTW)-1:3*(MTW+PTW)+2*CTW] &&
		  i_read_data[2*(CTW+MTW+PTW)-1:2*(MTW+PTW)+CTW] <= i_read_data[4*(CTW+MTW+PTW)-1:4*(MTW+PTW)+3*CTW]) begin
	     min_sub_tree[1:0] = 2'b01;	  
      end else if (i_read_data[3*(CTW+MTW+PTW)-1:3*(MTW+PTW)+2*CTW] <= i_read_data[(CTW+MTW+PTW)-1:(MTW+PTW)] &&
	      i_read_data[3*(CTW+MTW+PTW)-1:3*(MTW+PTW)+2*CTW] <= i_read_data[2*(CTW+MTW+PTW)-1:2*(MTW+PTW)+CTW] &&
		  i_read_data[3*(CTW+MTW+PTW)-1:3*(MTW+PTW)+2*CTW] <= i_read_data[4*(CTW+MTW+PTW)-1:4*(MTW+PTW)+3*CTW]) begin
	     min_sub_tree[1:0] = 2'b10;
      end else begin
	     min_sub_tree[1:0] = 2'b11;
      end	 		  	  
   end

//-----------------------------------------------------------------------------
// Continous Assignments
//-----------------------------------------------------------------------------
   assign read = ~((~i_push) & (fsm == ST_IDLE));
   assign done_before = (~(|i_read_data[(CTW+MTW+PTW)-1:(MTW+PTW)])) // if a sub tree count is 0, push done
                      | (~(|i_read_data[2*(CTW+MTW+PTW)-1:2*(MTW+PTW)+CTW]))
                      | (~(|i_read_data[3*(CTW+MTW+PTW)-1:3*(MTW+PTW)+2*CTW]))
                      | (~(|i_read_data[4*(CTW+MTW+PTW)-1:4*(MTW+PTW)+3*CTW]));
   assign cur_continue = (~(&cur_level)) & (~done_before);
   
      
//-----------------------------------------------------------------------------
// Output Assignments
//-----------------------------------------------------------------------------
   assign ready = ((fsm == ST_IDLE & (~i_push)) | (&cur_level) | done_before);
    // ie cur_level next
   assign o_read_level = (fsm == ST_IDLE) ? '0 
                       : (((&cur_level) | done_before) ? '0 : cur_level+1); 
   assign o_write_level = cur_level;
   assign o_read_addr   = addr_nxt;
   assign o_write_addr  = addr;

   assign o_read        = read;
   assign o_write       = write;
   assign o_write_data  = wdata;
   
endmodule
