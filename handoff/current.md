# 当前接力记录

- 阶段：18，在独立训练帧感知链中实现固定 5 点数字回波的信道估计、距离 IFFT 与峰值检测。
- 数据帧采用 52 个有效子载波，其中 4 个固定导频、48 个 Gray QPSK 数据子载波；固定 LFSR 种子为 `16'hACE1`，每个数据帧产生 96 bit。
- PL 检查器比较训练/导频幅值、保护带、帧尾和 QPSK 硬判决，累积帧数、总比特数和误码数。LED0 心跳、LED1 数据帧通过、LED2 收到完整帧、LED3 历史错误。
- 验证：5 点延迟模块的 80 点帧、TLAST 和背压 XSim 通过；IFFT → CP → 延迟 → 去 CP → FFT 仿真在第 1 子载波得到约 `(226,-121)` 的预期相位；完整训练帧链的 XSim 报告峰值为 bin 5、强度 13318。Python 稀疏训练载波距离像同样在第 5 格达峰，累计 Python 测试为 13 项。PYNQ-Z2 上带 ILA 的 range demo 已实际编程并采集 1024 个样本：全部 `range_frame_valid=1`、`peak_bin=5`、`peak_magnitude=13318`；125 MHz 时序 WNS 为 0.234 ns。阶段 16 的 ILA 通信回环读数仍有效。
- 板端：`range_demo_top` 只发送已知训练帧，并在 PL 内注入 5 点数字目标；构建/下载脚本为 `scripts/build_range_demo.tcl` 与 `scripts/program_range_demo.tcl`。LED0 心跳，LED1 有完整距离像，LED2 表示峰值=5 且足够强，LED3 表示该固定验收失败。
- 当前限制：这条感知链使用板内固定数字目标，与交替训练/QPSK 通信顶层分开；尚无可变目标门、载波相位振动、噪声、同步、均衡、PS/AXI 和 DMA。
- 下一步：为 range demo 加 JTAG/ILA 实测读数，再把训练帧感知支路与通信帧调度合并，随后实现目标门后的慢时间相位与位移链。
