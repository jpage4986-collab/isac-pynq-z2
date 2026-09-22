# 定点化和 FPGA 测试向量

FPGA 通常使用定点整数，而 Python 模型使用浮点复数。`model/fixed_point.py` 用 Q1.15 表示有符号实数：1 位符号、15 位小数，范围约为 -1 到 1。

在量化前先对 OFDM 时域波形做峰值归一化，避免溢出；随后分别保存 I（实部）和 Q（虚部）两个 `int16` 数组。`complex_mul_q15` 的乘法规则与后续 RTL 中的乘法器一致。

生成可供 Verilog 仿真读取的确定性向量：

```powershell
cd D:\pynqz2\isac-pynq-z2
.\.venv\Scripts\python.exe scripts\generate_ofdm_vector.py
```

输出文件：

```text
fpga/vectors/ofdm_q15_smoke.json
```

验证命令：

```powershell
.\.venv\Scripts\python.exe -m pytest
```
