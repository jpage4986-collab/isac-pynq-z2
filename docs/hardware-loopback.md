# CP 收发硬件回环

当前 `isac_top` 用 7 位计数器产生 0 到 63 的测试样本，送入 CP 插入器，再通过 AXI-Stream 连接到 CP 去除器。去除器每完成一帧 64 点有效数据，就更新回环计数。LED 同时显示时钟心跳、QPSK 象限和回环计数状态。

重新构建和烧录：

```powershell
cd D:\pynqz2\isac-pynq-z2
& "$env:XILINX_VIVADO\Vivado\2024.1\bin\vivado.bat" -mode batch -source scripts/build_pynq_z2.tcl -notrace
& "$env:XILINX_VIVADO\Vivado\2024.1\bin\vivado.bat" -mode batch -source scripts/program_pynq_z2.tcl -notrace
```

这一步验证的是 PL 内部数据通路和帧握手，不代表已经完成 FFT、信道估计或微振动测量。
