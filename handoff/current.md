# 当前接力记录

- 状态：阶段 12（CP 收发硬件回环上板）
- 上一阶段：CP 插入和 CP 去除的 AXI-Stream 握手仿真均已通过
- 本阶段内容：在 `isac_top` 中连接测试帧源 → CP 插入 → CP 去除，形成硬件回环
- 验证结果：Vivado DRC 0 错误、bitstream 成功；PYNQ-Z2 `xc7z020` 已编程且启动状态 HIGH
- 板上观察：LED 显示时钟心跳，并叠加 QPSK 象限和 CP 回环帧计数
- 下一步：接入 64 点 FFT/IFFT IP，替换当前测试帧源
- 下一步：加入循环前缀插入/移除模块，再连接 AXI-Stream 数据握手
- 当前阻塞：无
