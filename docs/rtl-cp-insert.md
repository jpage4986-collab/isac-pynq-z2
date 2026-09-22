# 循环前缀插入 RTL

`cp_insert` 先缓存一个 64 点复数 OFDM 有效符号，再按“最后 16 点 + 全部 64 点”的顺序输出，总长度为 80 点。当前版本采用无输出反压的连续输出接口，先用于和 Python `ofdm_modulate` 的循环前缀规则逐点对照。

仿真命令：

```powershell
cd D:\pynqz2\isac-pynq-z2
.\scripts\run_cp_sim.ps1
```

通过标志：`PASS cp_insert: 16-sample prefix plus 64-sample symbol matched`。
