# 板内微振动相位链

本阶段在同一条 OFDM 发射、数字回波和接收链中加入随时间变化的目标相位。开发板仍通过 USB-JTAG 下载，无需射频板、天线或 PYNQ 系统镜像；它证明的是**数字基带链路**，不是空中测量。

`vibration_phasor_q14` 使用 125 MHz 时钟计数得到约 100 Hz 的慢时间节拍，并在一帧数字回波的最后一个采样被接收后更新相位。这样单帧内的复增益保持不变。默认相位步进对应 2.4 Hz 正弦位移、500 µm 幅值和 5.8 GHz 假设载频。`axis_complex_rotator` 将这个 Q14 复增益施加在 5 点延迟目标上。接收端的训练帧形成距离像后，`range_gate_sampler` 取第 5 格复数值；`slow_time_sampler` 每个慢时间节拍保存一次；`slow_phase_product` 计算相邻样本的 `z[m]·conj(z[m-1])`，为后续相位解缠和位移读数提供输入。

先运行 `scripts/run_vibration_phasor_sim.ps1` 检查相位发生器、距离门及相位差；该脚本还从 RTL 导出 4096 个慢时间相位样本，以 Python 检查 2.4 Hz 频谱峰和 500 µm 幅值。工作树中没有 `.venv` 时可先设置 `PYTHON_EXE` 指向项目环境的 `python.exe`。再运行 `scripts/run_integrated_isac_sim.tcl` 检查整条 OFDM 链。`scripts/build_integrated_demo_jtag.tcl` 构建 125 MHz 带 ILA 的 bitstream，并在 WNS 为负时拒绝通过；`scripts/capture_integrated_demo_jtag.tcl` 烧录后导出一份普通快照和 12 份间隔约 100 ms 的慢时间快照；最后用 `scripts/summarize_dynamic_capture.py` 检查计数递增、零误码、第 5 格峰值和复数目标门的变化。

2026-09-23 的离线验收：两个模块级 RTL 仿真、固定和动态 OFDM 整链仿真通过；4096 个 RTL 慢时间样本给出 2.392578 Hz 频谱峰（FFT 格距 0.024414 Hz）和 500.07 µm 幅值；带 ILA 的实现以 125 MHz 通过时序检查，WNS = +0.457 ns。最初因供电不足，两次下载报 `End of startup status: LOW`。供电恢复后重新下载，Vivado 报 `End of startup status: HIGH`，并取得本版本的 ILA 数据。

实板首个 1024 时钟样本中，通信累计 19,272,288 bit、0 误码；1024/1024 个样本的距离峰值均在第 5 格，峰值强度 14666。其后 12 份分时快照中，累计比特数从 22,708,032 增至 61,449,120，误码保持 0；慢时间采样计数从 107 增至 291，目标门 IQ 有 9 种不同取值，相邻样本相位差的虚部有 12 种不同取值。这证明**实际 FPGA 上的数字目标相位随时间变化，且同链通信和测距仍工作**。机器可读摘要见 `reports/dynamic_vibration_board_20260923.json`；原始 CSV 位于本机 `D:\pynqz2\worktrees\build\pynq_z2_integrated_demo_jtag\`。

这些快照只用于确认板上信号随时间变化，不足以估计板端 2.4 Hz 的频谱峰或 500 µm 的位移误差。完整 4096 点慢时间记录、位移换算、频谱和多目标数字回波仍需后续板端采集与处理链验收。
