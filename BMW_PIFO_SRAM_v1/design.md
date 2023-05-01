## TOP 模块

里面例化一个 PUSH_RPU 和一个 POP_RPU_PAIR，一个 PUSH_RPU 和一个 POP_RPU_PAIR 产生的吞吐量大致相当

TOP 模块中还有一颗 SRAM 树，PUSH_RPU 和 POP_RPU_PAIR 在这颗树上移动

## PUSH_RPU

只具有 push 功能的 RPU，大致思想就是将 push_data 踢给自己，然后一直向下直到 push 完成。为了表示 RPU 的工作情况增加了输出 ready ，为了连接 SRAM 增加了输出 level。

代码中一些烦人的细节，就不详细介绍了。

## POP_RPU_PAIR

只具有 pop 功能的 RPU，大致思想就是将 pop_data 踢给伙伴，然后一直向下直到 pop 完成。同样，为了表示 RPU_PAIR 的工作情况增加了输出 ready ，为了连接 SRAM 增加了输出 level。

代码中一些烦人的细节，就不详细介绍了。
