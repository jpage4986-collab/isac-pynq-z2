# AXI-Stream 风格接口约定

`cp_insert_axis` 使用 `valid && ready` 作为传输条件，`last` 只在第 80 个输出样本传输时有效。下游可以拉低 `m_axis_tready` 暂停，模块会保持当前输出样本不变；这为后续 FFT IP、DMA 和 PS 端数据通路提供统一的帧接口。

仿真命令：

```powershell
cd D:\pynqz2\isac-pynq-z2
.\scripts\run_cp_axis_sim.ps1
```
