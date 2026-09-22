# 循环前缀去除 RTL

`cp_remove` 接收一个 80 点 OFDM 符号，丢弃前 16 点循环前缀，输出后续 64 点有效样本。它和 `cp_insert` 的接口规则一致，便于后续接 FFT/IFFT 和 AXI-Stream 封装。

仿真命令：

```powershell
cd D:\pynqz2\isac-pynq-z2
.\scripts\run_cp_remove_sim.ps1
```
