# 训练帧测距峰值

这一阶段把第 17 阶段的 5 点数字回波接到完整的感知接收链：已知训练符号经过 IFFT、16 点循环前缀、5 点延迟、去 CP 和 FFT 后，FPGA 得到接收频域值 `Y[k]`。训练载波的已知值是 `X[k]=16384`；在本项目的缩放配置下，无衰减时 `Y[k]` 约为 256，所以 `training_channel_estimator_axis` 用左移 6 位实现等效的常数除法，生成 Q14 格式的 `H[k]=Y[k]/X[k]`。

将 64 个 `H[k]` 输入第二个 64 点 IFFT，输出就是距离像。DC 与保护带没有训练值，因此保持 0；52 个有效子载波会让主峰约为满幅的 `52/64`。`range_peak_detector` 对每个距离单元计算 `|I|+|Q|`，记录最大值及其 bin，不需要乘法器。

本阶段的真值是 5 个采样点延迟。20 MHz 带宽下，它对应约 `5*c/(2*20 MHz)=37.47 m` 的两程距离示例。它仍是板内数字回波，不是对真实空间目标的测距。

## 可重复验证

```powershell
cd D:\pynqz2\isac-pynq-z2
& 'D:\pynqz2\tools\Vivado\2024.1\Vivado\2024.1\bin\vivado.bat' -mode batch -source scripts\run_training_range_sim.tcl -notrace
.\.venv\Scripts\python.exe -m pytest
```

XSim 的验收输出为：

```text
PASS training range: estimated strongest target at bin 5, magnitude 13318
```

`model.ofdm.range_profile_from_training` 用相同的 52 个有效子载波产生参考距离像；它的第 5 格主峰幅值应为反射幅值的 `52/64`。

## 板端演示

`scripts\build_range_demo.tcl` 生成专用 bitstream，`scripts\program_range_demo.tcl` 通过 USB-JTAG 下载。下载后：LED0 缓慢闪烁；LED1 亮表示至少完成了一帧距离像；LED2 亮表示峰值就是第 5 格且强度足够；LED3 亮表示结果不符合这个固定数字目标。按住 BTN0 可复位。

若需要从电脑直接读出板内结果，运行：

```powershell
& $vivado -mode batch -source scripts\build_range_demo_jtag.tcl -notrace
& $vivado -mode batch -source scripts\capture_range_demo_jtag.tcl -notrace
.\.venv\Scripts\python.exe scripts\summarize_range_capture.py ..\build\pynq_z2_range_demo_jtag\range_capture.csv
```

2026-09-23 的 PYNQ-Z2 实测采集包含 1024 个 ILA 样本：`range_frame_valid` 为高的样本为 1024 个，所有有效样本的 `peak_bin` 均为 5，`peak_magnitude` 均为 13318。该 ILA 版本在 125 MHz 下时序通过，最差建立时间裕量为 0.234 ns。
