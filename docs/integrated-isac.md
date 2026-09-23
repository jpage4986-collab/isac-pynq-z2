# 同一 OFDM 流的通信与测距

此前通信回环和固定数字目标测距是两份独立演示。本阶段的 `isac_integrated_top` 把它们接成同一条接收流：发射端交替输出已知训练帧和 QPSK 数据帧；带 16 点循环前缀的信号经过同一个 5 点数字目标；接收 FFT 后，一份数据同时进入通信均衡/误码统计和训练帧感知支路。

通信支路的 `delay5_equalizer_axis` 使用 64 个 Q14 查表系数去除该数字目标造成的线性频域相位斜率，随后由既有 QPSK 检查器统计 BER。感知支路只接收交替帧中的已知训练帧，按 `H=Y/X` 形成信道响应、做距离 IFFT，并寻找最大距离 bin。`ofdm_training_broadcaster` 在训练帧让两个支路共同握手，因此它们观察的是同一个 FFT 结果，而不是两份独立测试数据。

XSim 的验收输出为：

```text
PASS integrated ISAC: bits=96 errors=0 peak_bin=5 magnitude=13318
```

板端构建和下载：

```powershell
$vivado = 'D:\pynqz2\tools\Vivado\2024.1\Vivado\2024.1\bin\vivado.bat'
& $vivado -mode batch -source scripts\build_integrated_demo.tcl -notrace
& $vivado -mode batch -source scripts\program_integrated_demo.tcl -notrace
```

LED0 是心跳；LED1 表示共享数据流上的 QPSK 数据帧已出现且当前累计 0 误码；LED2 表示同一流的训练帧测距结果为第 5 格；LED3 表示通信或测距验收失败。此版本仍使用固定相位的数字目标；慢时间微振动相位、位移和频谱将在其上继续加入。

## PYNQ-Z2 实板验收（2026-09-23）

为避免把 LED 亮灭当作唯一证据，仓库还提供了一个带 ILA（片上逻辑分析仪）的构建。它把通信帧计数、QPSK 累计比特数和误码数，以及训练帧的距离峰值同时导出为 CSV：

```powershell
$vivado = 'D:\pynqz2\tools\Vivado\2024.1\Vivado\2024.1\bin\vivado.bat'
& $vivado -mode batch -source scripts\build_integrated_demo_jtag.tcl -notrace
& $vivado -mode batch -source scripts\capture_integrated_demo_jtag.tcl -notrace
& .\.venv\Scripts\python.exe scripts\summarize_integrated_capture.py `
  ..\worktrees\build\pynq_z2_integrated_demo_jtag\integrated_capture.csv
```

在连接的 PYNQ-Z2 上，ILA 的 1024 个采样点给出了以下结果：

```text
frame_count:       398585
data_frame_count:  199292
bit_count:       19132076
bit_errors:             0
range_frame_valid: 1024/1024
peak_bin:              [5]
peak_magnitude: 13318..13318
```

该带 ILA 的实现通过 125 MHz 时序检查（WNS = +0.249 ns，TNS = 0）。因此这里已经实板证明：同一条 OFDM 接收流可以一边恢复 QPSK 数据并保持 0 误码，一边用相邻训练帧稳定得到正确的数字目标距离峰值。
