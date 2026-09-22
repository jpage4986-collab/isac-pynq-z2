# 当前接力记录

- 状态：阶段 11（CP 收发两端 AXI-Stream）
- 上一阶段：CP 插入已具备 `valid/ready/last` 握手
- 本阶段内容：补上 CP 去除的 AXI-Stream 接口，验证接收端暂停时仍能恢复 64 点有效数据
- 验证结果：CP 插入/去除 AXI-Stream 仿真、基础 CP 仿真、QPSK 仿真均通过；Python 测试 11/11 通过
- 仿真命令：`scripts/run_cp_axis_sim.ps1`、`scripts/run_cp_remove_axis_sim.ps1`
- 下一步：加入循环前缀插入/移除模块，再连接 AXI-Stream 数据握手
- 当前阻塞：无
