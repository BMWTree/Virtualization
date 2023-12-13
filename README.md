# Virtualization

生成 sram placement 的方法如下：

进到 gen_SRAM_layout 文件夹，运行 make ，执行 tests 中的测试，输出在 tests 文件夹下的 .tb 中

生成 leafNode to Root Path 的方法如下：

进到 compiler 文件夹下，运行 make run ，执行 compiler_test 中的三个测试，目前只有 test3.cpp 是有意义的（也就是你 PPT 上画的那个），输出在 compiler_test 的.tb 中

真机实验的3个trace在新添加的vPIFO_trace文件夹下面，这三个trace由compiler_test中同名.cpp文件生成（其中描述了PIFO Tree）

下面描述trace文件的格式：

type:0, idle_cycle:200199999

type:1, tree_id:1, meta:0, priority0:1, priority1:2

type:2

type 代表任务的类型：

type 0 代表空转，即从当前周期开始，空闲 idle_cycle 个周期

type 1 代表 push 操作，该周期会发生一个 push 操作，tree_id 表示该 push 作用于哪个 PIFO，meta 在 trace 中用作每个数据包的唯一ID，priority0 表示该包插入当前 PIFO 使用的优先级，priority1 表示插入上一级 PIFO 使用的优先级。

type 2 代表 pop 操作