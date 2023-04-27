总的信号：输入 发起事务，输出 下一周期可以执行新的事务

修改：从父节点的输入和向字节点的输出合并成相同的寄存器（push, pop, push_data, pop_data, addr）（data 到后面可以都换成一组线（因为不能同时 push pop））



fsm 会根据次态变化，所以其实记住了 push 和 pop 的现态，不用再加寄存器了



o_push = (fsm == ST_PUSH && iread PTW 不是 '1)

iread PTW '1 是什么意思，为啥不行（应该是 CTW '1 吧，这样是子树满了）确认一下

i_push，o_push 是次态

边界条件：发起事务的时候，应该是下一个周期进入工作状态，所以次态应该还和事务的发起有关

当到达层数最大值后，停止 push，push_nxt 变为0

push_nxt = ((fsm == ST_PUSH && iread PTW 不是 '1) || (事务发起)) && (没到最大层数)



o_pop= (fsm == ST_POP || fsm == ST_WB)

i_pop，o_pop 是次态

边界条件：发起事务的时候，应该是下一个周期进入工作状态，所以次态应该还和事务的发起有关

当到达层数最大值后，停止 pop，pop_nxt 变为0

pop_nxt = ((fsm == ST_POP || fsm == ST_WB) || (事务发起)) && (没到最大层数)



push_data, o_push_data（这两个其实是一个），ipushd_latch, i_push_data 合并成一个寄存器

push_data, o_push_data，i_push_data 是次态，ipushd_latch 是现态

赋值逻辑看代码吧

需要能够接受外来输入（根据当前的状态是否空闲来接受数据）



o_pop_data（去掉）

pop_data 变成 pop_data_nxt，i_pop_data 变成 pop_data

赋值逻辑看代码吧

卡在状态机这里，pop_data 何时变为 pop_data_nxt