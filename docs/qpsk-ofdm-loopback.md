# QPSK OFDM 板内通信基线（阶段 15）

FPGA 交替发送已知训练帧和 QPSK 数据帧。每帧有 64 个频点：-26…-1、1…26 为 52 个有效频点，0 和两侧保护带为零。训练帧的有效频点均为实数 16384。数据帧的 -21、-7、7、21 四个导频为实数 16384，其他 48 个频点由固定种子 `16'hACE1` 的 16 位 LFSR 产生两比特 Gray QPSK，I/Q 各为 ±11585。

收发链为：帧源 → 64 点 IFFT → 加 16 点 CP → 去 CP → 64 点 FFT → 检查器。FFT 与 IFFT 各按 `1/64` 缩放；检查器对训练/导频/保护频点做定点幅值检查，对 48 个数据频点做硬判决，并在 PL 中累积 `bit_count`、`bit_errors`、`frame_count` 和 `data_frame_count`。每个数据帧应贡献 96 bit。检查器同时监视帧尾 `TLAST`；计数器达到最大值后饱和，不回绕。

四个板上绿色 PL LED：LED0 为时钟心跳，LED1 表示已经收到数据帧且最近一帧通过、此前没有错误，LED2 表示收到过完整帧，LED3 表示复位后出现过任何频点/帧尾错误。按住 BTN0 复位，松开后重新开始。LED 只能显示通过/失败，**BER 数值目前还只能在仿真中读取内部寄存器**；PS/DMA 或 ILA 读出是后续工作。

本阶段的可重复验收是无噪声板内通信：XSim 连续 4 个数据帧共 384 bit，应为 0 bit 错误；测试台另对一个数据频点翻转 I 符号，独立检查器必须恰好记 1 bit 错误并置位错误灯。它验证映射、帧控、定点 FFT 回环和计数逻辑，**不代表**已经完成有噪声 BER 曲线、信道估计、均衡、同步或 20 MHz 连续吞吐。

从本目录所属仓库运行：

```powershell
$vivado = 'D:\pynqz2\tools\Vivado\2024.1\Vivado\2024.1\bin\vivado.bat'
& $vivado -mode batch -source scripts/run_fft_roundtrip_sim.tcl -notrace
& $vivado -mode batch -source scripts/build_pynq_z2.tcl -notrace
& $vivado -mode batch -source scripts/program_pynq_z2.tcl -notrace
```

JTAG 下载写入易失性 PL 配置，断电后需要重新下载。
