`timescale 1ns / 10ps

// LEVEL == SRAM num, LEVEL == RPU num

module IO_PORT
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
    input [TREE_NUM_BITS-1:0]        i_tree_id,
    input                            i_push,
    input [(MTW+PTW)-1:0]            i_push_data,
    input                            i_pop,

    output                           o_task_fail,
    output [(MTW+PTW)-1:0]           o_pop_data,
    output                           o_pop_data_valid
);

reg [LEVEL-1:0] push;
reg [LEVEL-1:0] pop;
reg [PTW-1:0] push_data [0:LEVEL-1];
reg [TREE_NUM_BITS-1:0] tree_id [0:LEVEL-1];
wire [PTW-1:0] pop_data [0:LEVEL-1];
wire [LEVEL-1:0] task_fifo_full;
wire [LEVEL-1:0] root_id;

assign root_id = tree_id & {LEVEL_BITS{1'b1}};

for (genvar i = 0; i < LEVEL; i++) begin
    assign tree_id[i] = (root_id == i) ? i_tree_id : '0;
    assign push[i] = (root_id == i) ? i_push : '0;
    assign push_data[i] = (root_id == i) ? i_push_data : '0;
    assign pop[i] = (root_id == i) ? i_pop : '0;
end

// if task fifo full then task fail
// o_task_fail connect to all [LEVEL-1:0] task_fifo_full
assign o_task_fail = task_fifo_full[root_id];



PIFO_SRAM_TOP 
#(
    .PTW   (PTW),
    .MTW   (MTW),
    .CTW   (CTW),
    .LEVEL (LEVEL),
    .TREE_NUM (TREE_NUM),
    .FIFO_SIZE (FIFO_SIZE)
) u_PIFO_TOP (
    .i_clk       ( i_clk          ),
    .i_arst_n    ( i_arst_n       ),
    
    .i_tree_id   ( tree_id        ),
    .i_push      ( push           ),
    .i_push_data ( push_data      ),
    
    .i_pop       ( pop            ),
    .o_pop_data  ( pop_data       ),
    .o_task_fifo_full (task_fifo_full)      
);



endmodule