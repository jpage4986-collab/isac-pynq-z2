# AXI-Stream CP 去除

`cp_remove_axis` 接收 80 点带 CP 符号，按 `valid/ready` 规则丢弃前 16 点，并把 64 点有效数据逐点送出。下游拉低 `ready` 时，当前输出会保持不变；最后一点输出带 `last`。

仿真：

```powershell
cd D:\pynqz2\isac-pynq-z2
.\scripts\run_cp_remove_axis_sim.ps1
```
