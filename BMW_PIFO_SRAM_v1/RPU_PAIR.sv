`timescale 1ns / 10ps

    
module RPU_PAIR 
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
  
   // From/To Parent 
   input                          i_push,        // I - Push Command from Parent
   input  [(MTW+PTW)-1:0]         i_push_data,   // I - Push Data from Parent
   
   input                          i_pop,         // I - Pop Command from Parent
   output [(MTW+PTW)-1:0]         o_pop_data,    // O - Pop Data from Parent
   
   // From/To Child
   output                         o_push,        // O - Push Command to Child
   output [(MTW+PTW)-1:0]         o_push_data,   // O - Push Data to Child
   
   output                         o_pop,         // O - Pop Command to Child   
   input  [(MTW+PTW)-1:0]         i_pop_data,    // I - Pop Data from Child
   
   // From/To SRAM
   output                         o_read,        // O - SRAM Read
   input  [4*(CTW+MTW+PTW)-1:0]   i_read_data,   // I - SRAM Read Data {sub_tree_size3,pifo_val3,sub_tree_size2,pifo_val2,sub_tree_size1,pifo_val1,sub_tree_size0,pifo_val0}
   
   output                         o_write,       // O - SRAM Write
   output [4*(CTW+MTW+PTW)-1:0]   o_write_data,  // O - SRAM Write Data {sub_tree_size3,pifo_val3,sub_tree_size2,pifo_val2,sub_tree_size1,pifo_val1,sub_tree_size0,pifo_val0}

   input  [ADW-1:0]               i_my_addr,
   output [ADW-1:0]               o_child_addr,

   output [ADW-1:0]               o_read_addr,
   output [ADW-1:0]               o_write_addr
);

//-----------------------------------------------------------------------------
// Register and Wire Declarations
//-----------------------------------------------------------------------------

    wire [1:0]                          push_up;
    wire [(MTW+PTW)-1:0]                push_data_up [0:1];
    wire [1:0]                          pop_up;
    wire [(MTW+PTW)-1:0]                pop_data_up  [0:1];
    wire                                push_dn      [0:1];
    wire [(MTW+PTW)-1:0]                push_data_dn [0:1];
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

// 首先把 up 的输出接到 down 的输入上吧

// up 的输入来自 pair 的输入或 down 的输出
// up 的输出永远是 down 的输入

    PIFO_SRAM #(
        .PTW (PTW),
        .MTW (MTW),
        .CTW (CTW),
        .ADW (ADW)
    ) u_PIFO_0 (
        .i_clk           ( i_clk            ),
        .i_arst_n        ( i_arst_n         ),
        .i_push          ( push_up      [0] ),
        .i_push_data     ( push_data_up [0] ),
        .i_pop           ( pop_up       [0] ),
        .o_pop_data      ( pop_data_up  [0] ),
        .o_push          ( push_dn      [0] ),
        .o_push_data     ( push_data_dn [0] ),
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

// down 的输入永远是 up 的输出
// down 的输出做完 up 的输入或 pair 的输出
    assign push_up[1]            = push_dn[0];
    assign push_data_up[1]       = push_data_dn[0];
    assign pop_up[1]             = pop_dn[0];
    assign pop_data_dn[0]        = pop_data_up[1];
    assign my_addr[1]            = child_addr[0];

    PIFO_SRAM #(
        .PTW (PTW),
        .MTW (MTW),
        .CTW (CTW),
        .ADW (ADW)
    ) u_PIFO_1 (
        .i_clk           ( i_clk            ),
        .i_arst_n        ( i_arst_n         ),
        .i_push          ( push_up      [1] ),
        .i_push_data     ( push_data_up [1] ),
        .i_pop           ( pop_up       [1] ),
        .o_pop_data      ( pop_data_up  [1] ),
        .o_push          ( push_dn      [1] ),
        .o_push_data     ( push_data_dn [1] ),
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