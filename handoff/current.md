# 当前接力记录

- 状态：阶段 13（64 点 FFT IP 上板）
- 上一阶段：CP 收发硬件回环已在 PYNQ-Z2 上编程验证
- 本阶段内容：生成 64 点、16 位定点 XFFT 9.1 IP，并接入 CP 去除后的 AXI-Stream
- 验证结果：Vivado DRC 0 错误、bitstream 成功；PYNQ-Z2 `xc7z020` 已编程且启动状态 HIGH
- 板上观察：LED 显示时钟心跳，并叠加 QPSK 象限和 FFT 输出帧计数
- 下一步：加入 IFFT 发射支路、训练符号和可观测的 FFT 频谱寄存器
- 下一步：加入循环前缀插入/移除模块，再连接 AXI-Stream 数据握手
- 当前阻塞：无
