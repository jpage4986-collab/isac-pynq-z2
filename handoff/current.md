# 当前接力记录

- 状态：阶段 8（循环前缀插入 RTL）
- 上一阶段：QPSK 映射器已接入 `isac_top`，bitstream 已通过 USB-JTAG 烧录到 PYNQ-Z2
- 本阶段内容：实现 64 点复数符号的 16 点 CP 插入，并用 Vivado xsim 逐点验证
- 验证结果：CP 仿真通过；Python 测试 11/11 通过
- 仿真命令：`scripts/run_cp_sim.ps1`
- 下一步：加入循环前缀插入/移除模块，再连接 AXI-Stream 数据握手
- 当前阻塞：无
