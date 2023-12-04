# Virtualization

生成 sram placement 的方法如下：

进到 gen_SRAM_layout 文件夹，运行 make ，执行 tests 中的测试，输出在 tests 文件夹下的 .tb 中

生成 leafNode to Root Path 的方法如下：

进到 compiler 文件夹下，运行 make run ，执行 compiler_test 中的三个测试，目前只有 test3.cpp 是有意义的（也就是你 PPT 上画的那个），输出在 compiler_test 的.tb 中
