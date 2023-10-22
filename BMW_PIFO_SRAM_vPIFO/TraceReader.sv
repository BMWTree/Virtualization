`timescale 1ns / 10ps


`define MAX2(v1, v2) ((v1) > (v2) ? (v1) : (v2))


module TRACE_READER
#(
    parameter PTW             = 16, // Payload data width
    parameter MTW             = TREE_NUM_BITS, // Metdata width should not less than TREE_NUM_BITS, cause tree_id will be placed in MTW
    parameter CTW             = 10, // Counter width
    parameter LEVEL           = 4, // Sub-tree level
    parameter TREE_NUM        = 4,
    parameter FIFO_SIZE       = 8,
    parameter IDLECYCLE    = 1024, // idle cycles

    localparam FIFO_WIDTH       = $clog2(FIFO_SIZE),
    localparam LEVEL_BITS       = $clog2(LEVEL),
    localparam TREE_NUM_BITS    = $clog2(TREE_NUM),
    localparam IDLECYCLE_BITS   = $clog2(IDLECYCLE), // idle cycles
	localparam TRACE_DATA_BITS = `MAX2(IDLECYCLE, (PTW+TREE_NUM_BITS+MTW+PTW)) + 1,
)(
   // Clock and Reset
    input                            i_clk,
    input                            i_arst_n,
    
    input [TRACE_DATA_BITS-1:0]      i_trace_data,

    // Push and Pop port to the whole PIFO tree
    output                           o_push,
    output [PTW-1:0]       o_push_priority,
    output [TREE_NUM_BITS-1:0]       o_push_tree_id,
    output [(MTW+PTW)-1:0]           o_push_data,
    
    output                           o_pop,

    output                           o_read
);

// a trace is a push
// trace data format:
// {bit, priority, tree_id, data} or {bit, idle_cycle}
// bit is used to mark if this entry is a packet

// note
// if o_read is 0, i_trace_data should be '0

reg[IDLECYCLE_BITS+1:0] idle_cycle_counter;
reg push;
reg pop;
reg [PTW-1:0] push_priority;
reg [TREE_NUM_BITS-1:0] push_tree_id;
reg [(MTW+PTW)-1:0] push_data;

wire [IDLECYCLE_BITS+1:0] i_idle_cycle_counter;
wire i_push;
wire [PTW-1:0] i_push_priority;
wire [TREE_NUM_BITS-1:0] i_push_tree_id;
wire [(MTW+PTW)-1:0] i_push_data;

assign i_push = i_trace_data[TRACE_DATA_BITS-1];
assign i_push_priority = i_trace_data[TRACE_DATA_BITS-2:(MTW+PTW)+TREE_NUM_BITS]; // larger bits than priority
assign i_push_tree_id = i_trace_data[(MTW+PTW)+TREE_NUM_BITS-1:(MTW+PTW)];
assign i_push_data = i_trace_data[(MTW+PTW)-1:0];
assign i_idle_cycle_counter = i_trace_data[TRACE_DATA_BITS-2:0]; // larger bits than cycle counter


always @ (posedge i_clk or negedge i_arst_n)
begin
    if (!i_arst_n) begin
        push <= '0;
        pop <= '0;
        push_priority <= '1;
        push_tree_id <= '0;
        push_data <= '1;
    end else begin
        push <= i_push;
        pop <= !i_push;
        push_priority <= i_push ? i_push_priority : '1;
        push_tree_id <= i_push ? i_push_tree_id : '0;
        push_data <= i_push ? i_push_data : '1;
    end
end

always @ (posedge i_clk or negedge i_arst_n)
begin
    if (!i_arst_n) begin
        idle_cycle_counter <= '0;
    end else begin
        if ((!i_push) && o_read) begin // not push and trace_data is valid
            idle_cycle_counter <= i_idle_cycle_counter;
        end else begin
            idle_cycle_counter <= (idle_cycle_counter == '0) ? '0: idle_cycle_counter-1;
        end
    end
end

assign o_push = push;
assign o_push_priority = push_priority;
assign o_push_tree_id = push_tree_id;
assign o_push_data = push_data;
assign o_pop = pop;
assign o_read = (idle_cycle_counter == '0);

endmodule