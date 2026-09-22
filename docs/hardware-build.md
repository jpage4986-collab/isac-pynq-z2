# PYNQ-Z2 硬件构建与烧录

本阶段把 QPSK Q1.15 映射器接入 `isac_top`。板上的 LED 继续提供慢速心跳，同时由映射器的 I/Q 符号象限参与 LED 状态，便于确认新 bitstream 已运行。

在 PowerShell 中执行：

```powershell
cd D:\pynqz2\isac-pynq-z2
& "$env:XILINX_VIVADO\Vivado\2024.1\bin\vivado.bat" -mode batch -source scripts/build_pynq_z2.tcl -notrace
& "$env:XILINX_VIVADO\Vivado\2024.1\bin\vivado.bat" -mode batch -source scripts/program_pynq_z2.tcl -notrace
```

烧录前确认 PYNQ-Z2 电源打开，并将 USB 数据线接到 `PROG/UART` 口。脚本使用器件型号 `xc7z020clg400-1`，通过 `localhost:3121` 的 Vivado `hw_server` 查找 JTAG 设备。
