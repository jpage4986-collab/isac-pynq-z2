# 用 USB-JTAG 读取板上 OFDM 计数器

这一阶段在既有通信回环上插入 Vivado ILA，采集 `frame_count`、`data_frame_count`、`bit_count` 和 `bit_errors` 四个 32 位计数器。它使用当前 USB-JTAG 线和 Vivado 2024.1，不依赖尚未建立的 PYNQ 系统镜像。ILA 是调试读数通道；正式系统仍需 PS/AXI 寄存器或 DMA。

在仓库目录打开 PowerShell：

```powershell
$vivado = 'D:\pynqz2\tools\Vivado\2024.1\Vivado\2024.1\bin\vivado.bat'
& $vivado -mode batch -source scripts/build_jtag_counters.tcl -notrace
& $vivado -mode batch -source scripts/capture_jtag_counters.tcl -notrace
.\.venv\Scripts\python.exe scripts\summarize_counter_capture.py D:\pynqz2\build\pynq_z2_jtag_counters\counter_capture.csv
```

构建脚本会生成独立的 `../build/pynq_z2_jtag_counters` 目录，不覆盖普通回环 bitstream。采集脚本会先下载含 ILA 的 bitstream，再写出 `counter_capture.csv`。如果 LED0 闪烁、LED1 与 LED2 亮、LED3 灭，并且 CSV 中 `bit_count` 增长、`bit_errors` 为零，就同时具备板上状态和板外计数证据。按住 BTN0 可清零，松开后重新计数。CSV 是约 1024 个连续时钟的短快照，不是长期记录；在完整 32 位计数器回绕前，应由将来的 PS 侧读数程序定期读取。

若脚本报告未发现 ILA，先检查板子供电、USB-JTAG、bitstream 与 `.ltx` 是否来自同一次构建。JTAG 配置断电即失效。

2026-09-23 的首次实板采集：1024 个时钟样本内，完整帧 `402221 → 402224`、数据帧 `201110 → 201112`、数据比特 `19306560 → 19306752`、误码 `0 → 0`，即 2 个完整数据帧贡献 192 bit。用修正后的独立构建脚本重新生成 bitstream 并再次采集，完整帧 `391548 → 391551`、数据帧 `195774 → 195775`、数据比特 `18794304 → 18794438`、误码 `0 → 0`；第二个窗口截到未结束的数据帧，因此新增的 134 bit 不必等于完整数据帧数乘以 96。脚本还校验累计比特数与完整数据帧数的差值在 0～96 bit 之间。所有计数都是**无噪声、板内数字回环**结果，不能当作有噪声通信链路的 BER 性能结论。两次 ILA 版本布线后 WNS 均为 +0.950 ns，JTAG startup HIGH。
