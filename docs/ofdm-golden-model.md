# OFDM 黄金模型

本阶段先不连接射频。模型使用 64 点 OFDM、16 点循环前缀、QPSK 和 4 个导频，构造一个简单的慢时间相位信道：每个 OFDM 符号乘以一个相位旋转，代表结构微振动造成的传播路径变化。

## 运行测试

```powershell
cd D:\pynqz2\isac-pynq-z2
.\.venv\Scripts\python.exe -m pytest
```

测试覆盖：

- QPSK 映射/解调；
- OFDM IFFT/FFT 与循环前缀；
- 导频相位估计；
- 相位到位移的恢复；
- 带噪声时的 QPSK 恢复。

`model/ofdm.py` 是浮点黄金参考，后续 FPGA 定点模块必须用相同测试向量对比它。当前信道是公共相位模型，不代表完整多径或 RIS；多径、同步误差和定点量化将在后续阶段逐步加入。
