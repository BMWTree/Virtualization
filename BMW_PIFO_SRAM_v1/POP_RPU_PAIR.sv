`timescale 1ns / 10ps

    
module POP_RPU_PAIR 
#(
   parameter PTW  = 16,  // Payload data width
   parameter MTW  = 0,  // Metdata width
   parameter CTW  = 10,  // Counter width
   parameter ADW  = 20,   // Address width
   parameter LEVEL = 8    // Sub-tree level
)(
   // Clock and Reset
   input                          i_clk,         // I - Clock
   input                          i_arst_n,      // I - Active Low Async Reset

   output                         ready,         // O - if ready, next clock it will be idle
  
   // From/To Parent 
   input                          i_pop,         // I - Pop Command from Parent
   output [(MTW+PTW)-1:0]         o_pop_data,    // O - Pop Data from Parent
   
   // From/To SRAM
   output [0:1]                   o_read,        // O - SRAM Read
   input  [4*(CTW+MTW+PTW)-1:0]   i_read_data [0:1],  // I - SRAM Read Data {sub_tree_size3,pifo_val3,sub_tree_size2,pifo_val2,sub_tree_size1,pifo_val1,sub_tree_size0,pifo_val0}
   
   output [0:1]                   o_write,       // O - SRAM Write
   output [4*(CTW+MTW+PTW)-1:0]   o_write_data [0:1],  // O - SRAM Write Data {sub_tree_size3,pifo_val3,sub_tree_size2,pifo_val2,sub_tree_size1,pifo_val1,sub_tree_size0,pifo_val0}

   output [$clog2(LEVEL)-1:0]     o_read_level [0:1],
   output [$clog2(LEVEL)-1:0]     o_write_level [0:1],
   output [ADW-1:0]               o_read_addr [0:1],
   output [ADW-1:0]               o_write_addr [0:1]
);

//-----------------------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------------------
localparam    ST_IDLE     = 2'b00,
              ST_POP      = 2'b11,
	 	 	     ST_WB       = 2'b10;

//-----------------------------------------------------------------------------
// Register and Wire Declarations
//-----------------------------------------------------------------------------

    wire [1:0]                          pop_up;
    wire [(MTW+PTW)-1:0]                pop_data_up  [0:1];
    wire                                pop_dn       [0:1];
    wire [(MTW+PTW)-1:0]                pop_data_dn  [0:1];
    
    wire [1:0]                          read;
    wire [1:0]                          write;
    wire [4*(CTW+MTW+PTW)-1:0]          read_data    [0:1];
    wire [4*(CTW+MTW+PTW)-1:0]          write_data   [0:1];   
    
    wire [1:0]                          we;
    wire [addr_idx_high(LEVEL):0]       waddr;
    wire [4*(CTW+MTW+PTW)-1:0]          wdata        [0:1];
        
    wire [1:0]                          re;
    wire [addr_idx_high(LEVEL):0]       raddr;
    wire [4*(CTW+MTW+PTW)-1:0]          rdata        [0:1];   


    wire [ADW-1:0]                      read_addr    [0:1];
    wire [ADW-1:0]                      write_addr   [0:1];
    
    
    wire [ADW-1:0]                      my_addr      [0:1];
    wire [ADW-1:0]                      child_addr   [0:1];

    wire [1:0]                          fsm          [0:1];

    // curent level ie write_level
    reg [$clog2(LEVEL)-1:0]             cur_level    [0:1];



always @ (posedge i_clk or negedge i_arst_n)
   begin
      if (!i_arst_n) begin
         cur_level[0] <= '0;
      end else begin
	     case (fsm[0])
            ST_IDLE: begin
               cur_level[0] <= '0;
            end  
            ST_POP: begin
               cur_level[0] <= cur_level[0];
            end		  
            ST_WB: begin
                  if (cur_level[0] < LEVEL-2) begin
                        cur_level[0] <= cur_level[0]+2;
                  end else begin
                        cur_level[0] <= '0;
                  end
            end
            default: begin // you should not hit here
               cur_level[0] <= '0;
            end		
 	     endcase
      end	  
   end

always @ (posedge i_clk or negedge i_arst_n)
   begin
      if (!i_arst_n) begin
         cur_level[1] <= {{($clog2(LEVEL)-1){1'b0}}, 1'b1};
      end else begin
	     case (fsm[1])
            ST_IDLE: begin
               cur_level[1] <= {{($clog2(LEVEL)-1){1'b0}}, 1'b1};
            end  
            ST_POP: begin
               cur_level[1] <= cur_level[1];
            end		  
            ST_WB: begin
                  if (cur_level[1] < LEVEL-2) begin
                        cur_level[1] <= cur_level[1]+2;
                  end else begin
                        cur_level[1] <= {{($clog2(LEVEL)-1){1'b0}}, 1'b1};
                  end
            end
            default: begin // you should not hit here
               cur_level[1] <= {{($clog2(LEVEL)-1){1'b0}}, 1'b1};
            end	
 	     endcase
      end	  
   end


    POP_RPU #(
        .PTW (PTW),
        .MTW (MTW),
        .CTW (CTW),
        .ADW (ADW)
    ) u_POP_RPU_0 (
        .i_clk           ( i_clk            ),
        .i_arst_n        ( i_arst_n         ),
        .o_fsm           ( fsm[0]           ),
        .i_pop           ( pop_up       [0] ),
        .o_pop_data      ( pop_data_up  [0] ),
        .o_pop           ( pop_dn       [0] ),
        .i_pop_data      ( pop_data_dn  [0] ),
		
        .o_read          ( read         [0] ), 
        .i_read_data     ( read_data    [0] ), 

        .o_write         ( write        [0] ), 
        .o_write_data    ( write_data   [0] ),
        .i_my_addr       ( my_addr      [0] ),
        .o_child_addr    ( child_addr   [0] ),
        .o_read_addr     ( read_addr    [0] ),
        .o_write_addr    ( write_addr   [0] )
    );


    assign pop_up[1]             = pop_dn[0];
    assign pop_data_dn[0]        = pop_data_up[1];
    assign my_addr[1]            = child_addr[0];

    
    assign my_addr[0]            = (cur_level[1] < LEVEL-2) ? child_addr[1] : '0;
    assign pop_up[0]             = (cur_level[1] < LEVEL-2) ? pop_dn[1] : i_pop;
    assign pop_data_dn[1]        = (cur_level[1] < LEVEL-2) ? pop_data_up[0] : {(MTW+PTW){1'b1}};

    POP_RPU #(
        .PTW (PTW),
        .MTW (MTW),
        .CTW (CTW),
        .ADW (ADW)
    ) u_POP_RPU_1 (
        .i_clk           ( i_clk            ),
        .i_arst_n        ( i_arst_n         ),
        .o_fsm           ( fsm[1]           ),
        .i_pop           ( pop_up       [1] ),
        .o_pop_data      ( pop_data_up  [1] ),
        .o_pop           ( pop_dn       [1] ),
        .i_pop_data      ( pop_data_dn  [1] ),
		
        .o_read          ( read         [1] ), 
        .i_read_data     ( read_data    [1] ), 

        .o_write         ( write        [1] ), 
        .o_write_data    ( write_data   [1] ),
        .i_my_addr       ( my_addr      [1] ),
        .o_child_addr    ( child_addr   [1] ),
        .o_read_addr     ( read_addr    [1] ),
        .o_write_addr    ( write_addr   [1] )
    );



//-----------------------------------------------------------------------------
// Continous Assignments
//-----------------------------------------------------------------------------

   assign read_data = i_read_data;

//-----------------------------------------------------------------------------
// Output Assignments
//-----------------------------------------------------------------------------
    assign ready = (fsm[0] == ST_IDLE);
    assign o_pop_data = pop_data_up  [0];
    assign o_read = read;
    assign o_write = write;
    assign o_write_data = write_data;

    assign o_read_level[0] = (fsm[0] == ST_IDLE) ? '0
                           : (fsm[0] == ST_POP) ? cur_level[0]
                           // ST_WB
                           : (cur_level[0] < LEVEL-2) ? cur_level[0]+2
                           : '0;

    assign o_read_level[1] = (fsm[1] == ST_IDLE) ? {{($clog2(LEVEL)-1){1'b0}}, 1'b1};
                           : (fsm[1] == ST_POP) ? cur_level[1]
                           // ST_WB
                           : (cur_level[1] < LEVEL-2) ? cur_level[1]+2
                           : {{($clog2(LEVEL)-1){1'b0}}, 1'b1};
    
    assign o_write_level = cur_level;
    assign o_read_addr = read_addr;
    assign o_write_addr = write_addr;



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


endmodule