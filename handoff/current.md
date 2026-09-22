# 当前接力记录

- 状态：阶段 10（CP 的 AXI-Stream 握手）
- 上一阶段：CP 插入和 CP 去除两端 RTL 均已逐点验证
- 本阶段内容：给 CP 插入增加 `valid/ready/last` 握手，并验证下游暂停时数据保持不变
- 验证结果：AXI-Stream 仿真、CP 插入、CP 去除、QPSK 仿真均通过；Python 测试 11/11 通过
- 仿真命令：`scripts/run_cp_axis_sim.ps1`
- 下一步：加入循环前缀插入/移除模块，再连接 AXI-Stream 数据握手
- 当前阻塞：无
