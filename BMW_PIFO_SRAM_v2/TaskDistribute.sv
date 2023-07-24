

module TaskDistribute 
#(
	parameter PTW    = 16,       // Payload data width
	parameter LEVEL  = 4,         // Sub-tree level ie RPU num
	parameter TREE_NUM = 4,
	parameter TREE_NUM_BITS = $clog2(TREE_NUM)
)
(
    // Clock and Reset
    input i_clk,         // I - Clock
    input i_arst_n,      // I - Active Low Async Reset

    // TaskFIFO
    output [LEVEL-1:0] o_pop_TaskFIFO,
    // { {1'b(push(1) or pop(0))}, TreeId, PushData(or '0 when pop)}
    input [PTW+TREE_NUM_BITS:0] i_TaskFIFO_data [0:LEVEL-1], 
    input [LEVEL-1:0] i_TaskFIFO_empty,

    // RPU state
    input [1:0] i_rpu_state_nxt [0:LEVEL-1],

    // output push pop task
    output [LEVEL-1:0] o_rpu_push,
    output [LEVEL-1:0] o_rpu_pop,
    output [TREE_NUM_BITS-1:0] o_rpu_treeId [0:LEVEL-1],
    output [PTW-1:0] o_rpu_push_data [0:LEVEL-1]
);

localparam  ST_IDLE     = 2'b00,
            ST_PUSH     = 2'b01,
            ST_POP      = 2'b11,
            ST_WB       = 2'b10;

// { 1'b(valid), {1'b(push(1) or pop(0))}, TreeId, PushData(or '0 when pop)}
reg [PTW+TREE_NUM_BITS+1:0] TaskHead_last [0:LEVEL-1];
reg [PTW+TREE_NUM_BITS+1:0] TaskHead [0:LEVEL-1];
reg [PTW+TREE_NUM_BITS+1:0] TaskHead_after [0:LEVEL-1];
reg [LEVEL-1:0] pop_TaskFIFO_last;
reg [LEVEL-1:0] i_TaskFIFO_empty_last;

wire [LEVEL-1:0] TaskHead_valid;
wire [LEVEL-1:0] TaskHead_after_valid;
wire [LEVEL-1:0] TaskHead_type; // 1 is push 0 is pop
wire [TREE_NUM_BITS-1:0] TaskHead_treeId [0:LEVEL-1];
wire [PTW-1:0] TaskHead_PushData [0:LEVEL-1];

reg [LEVEL-1:0] rpu_push, rpu_push_nxt;
reg [LEVEL-1:0] rpu_pop, rpu_pop_nxt;
reg [TREE_NUM_BITS-1:0] rpu_treeId [0:LEVEL-1];
reg [PTW-1:0] rpu_PushData [0:LEVEL-1];


for (genvar i = 0; i < LEVEL; i++) begin    
    assign TaskHead[i] = (!i_arst_n) ? '0 // reset
    : (!pop_TaskFIFO_last[i]) ?  TaskHead_last[i] // not pop
    : i_TaskFIFO_empty_last[i] ? {1'b0, i_TaskFIFO_data[i]} : {1'b1, i_TaskFIFO_data[i]}; // if empty
end

for (genvar i = 0; i < LEVEL; i++) begin
    always_ff @( posedge i_clk ) begin
        pop_TaskFIFO_last[i] <= o_pop_TaskFIFO[i];
        i_TaskFIFO_empty_last[i] <= i_TaskFIFO_empty[i];
        TaskHead_last[i] <= TaskHead_after[i];
    end
end

for (genvar i = 0; i < LEVEL; i++) begin    
    assign TaskHead_valid[i] = TaskHead[i][PTW+TREE_NUM_BITS+1];
    assign TaskHead_after_valid[i] = TaskHead_after[i][PTW+TREE_NUM_BITS+1];
    assign TaskHead_type[i] = TaskHead[i][PTW+TREE_NUM_BITS];
    assign TaskHead_treeId[i] = TaskHead[i][PTW+:TREE_NUM_BITS];
    assign TaskHead_PushData[i] = TaskHead[i][0+:PTW];
end

for (genvar i = 0; i < LEVEL; i++) begin
    assign o_pop_TaskFIFO[i] = (!TaskHead_after_valid[i]) && (!i_TaskFIFO_empty[i]);
end

for (genvar i = 2; i < LEVEL; i++) begin
    assign rpu_push_nxt[i] = (i_rpu_state_nxt[i] != ST_IDLE) ? 1'b0 : TaskHead_valid[i] ? (TaskHead_type[i] == 1'b1) : 1'b0;
    assign rpu_pop_nxt[i] = (i_rpu_state_nxt[i] != ST_IDLE || i_rpu_state_nxt[i-1] != ST_IDLE || (rpu_pop_nxt[i-1] | rpu_push_nxt[i-1])) ? 1'b0 : TaskHead_valid[i] ? (TaskHead_type[i] == 1'b0) : 1'b0;
end

assign rpu_push_nxt[1] = (i_rpu_state_nxt[1] != ST_IDLE) ? 1'b0 : TaskHead_valid[1] ? (TaskHead_type[1] == 1'b1) : 1'b0;
assign rpu_pop_nxt[1] = (i_rpu_state_nxt[1] != ST_IDLE || i_rpu_state_nxt[0] != ST_IDLE) ? 1'b0 : TaskHead_valid[1] ? (TaskHead_type[1] == 1'b0) : 1'b0;

assign rpu_push_nxt[0] = (i_rpu_state_nxt[0] != ST_IDLE) ? 1'b0 
: (rpu_pop_nxt[1] == 1'b1) ? 1'b0 
: TaskHead_valid[0] ? (TaskHead_type[0] == 1'b1) : 1'b0;
assign rpu_pop_nxt[0] = (i_rpu_state_nxt[0] != ST_IDLE) ? 1'b0 
: (rpu_pop_nxt[1] == 1'b1) ? 1'b0 
: (i_rpu_state_nxt[LEVEL-1] != ST_IDLE || (rpu_pop_nxt[LEVEL-1] | rpu_push_nxt[LEVEL-1])) ? 1'b0 
: TaskHead_valid[0] ? (TaskHead_type[0] == 1'b0) : 1'b0;

for (genvar i = 0; i < LEVEL; i++) begin 
    assign TaskHead_after[i] = (rpu_push_nxt[i] | rpu_pop_nxt[i]) ? '0 : TaskHead[i];
end

always_ff @( posedge i_clk ) begin
    rpu_pop <= rpu_pop_nxt;
    rpu_push <= rpu_push_nxt;
end

for (genvar i = 0; i < LEVEL; i++) begin
    always_ff @( posedge i_clk ) begin
        rpu_PushData[i] <= TaskHead_PushData[i];
        rpu_treeId[i] <= TaskHead_treeId[i];
    end
end

assign o_rpu_push = rpu_push;
assign o_rpu_pop = rpu_pop;

for (genvar i = 0; i < LEVEL; i++) begin
    assign o_rpu_push_data[i] = rpu_PushData[i];
    assign o_rpu_treeId[i] = rpu_treeId[i];
end





endmodule