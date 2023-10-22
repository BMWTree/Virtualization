# 代码说明

## 参数说明

各个文件中的参数都大同小异，因此在这里集中说明。

### parameter

- PTW

> Payload data width，包的优先级会作为 Payload data

- MTW

> Meta data width，在 leaf PIFO 中该字段存放包的指针，在 non-leaf PIFO 中该字段存放下一级 PIFO 的 id

- CTW

> Counter width，BMW-Tree 中用于统计子树中包的个数的计数器

- LEVEL

> BMW-Tree 的层数

- TREE_NUM

> 当前系统中的 PIFO 数目

- FIFO_SIZE

> 系统中的 Task FIFO 的大小



## localparam

- FIFO_WIDTH

> FIFO_SIZE 所需要的位数

- LEVEL_BITS

> LEVEL 所需要的位数

- TREE_NUM_BITS

> TREE_NUM 所需要的位数

- ADW

> 在 BMW-Tree 每层内部寻址所需的最大地址宽度，例如 3 层的 BMW-Tree 每层的数据量为 1, 2, 4 因此最后一层（容量为 4 ）只需要 2 位寻址。

- TREE_SIZE

> 一棵 BMW-Tree 的容量大小，TREE_SIZE 刚好是 2^LEVEL^ -1 （对于二叉的情况）。

- SRAM_ADW

> SRAM 的地址宽度（SRAM 的容量是多棵 BMW-Tree 拼接起来的，假设 BMW-Tree 的数目是 SRAM 数目的倍数，整个系统中有 LEVEL 个 SRAM）。在设计中，所有 SRAM 大小一样，因此每个 SRAM 的容量为 TREE_NUM * TREE_SIZE / LEVEL。TREE_SIZE 刚好是 2^LEVEL^ -1 （对于二叉的情况），对上式取 log 即得到 SRAM 的地址宽度。

- TaskFIFO_DATA_BITS

> TaskFIFO 中的数据的位数，TaskFIFO 中数据格式为：*{ {1'b(push(1) or pop(0))}, TreeId, PushData(or '0 when pop)}*

- ROOT_TREE_ID

> 在 PIFO 树中（只考虑二层的情况），作为根节点的 PIFO 的 ID。

- ROOT_RPU_ID

> 根节点的 PIFO 的根（即 BMW-Tree 的根）所在的 RPU。

## IO_PORT.sv

只是简单的将 PIFO_SRAM_TOP 暴露出来的多个输入和输出捏到一起，为了防止在板子上 IO 爆炸。

### input

- i_clk

> 时钟

- i_arst_n

> 异步 reset 信号，0 代表进行 reset

- i_tree_id

> 输入的 PIFO ID

- i_push

> 输入的 push 信号

- push_data

> 输入的 push_data

- i_pop

> 输入的 pop 信号



### output

- o_task_fail

> 该周期的 push / pop 任务下发失败（Task FIFO 已经满了）

- o_pop_data

> pop 得到的 data