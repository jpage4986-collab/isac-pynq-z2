# 第一个 RTL 仿真模块

`fpga/rtl/qpsk_mapper.v` 把两个输入比特映射成 Q1.15 格式的 QPSK I/Q 符号，映射规则与 Python 黄金模型一致。`fpga/tb/tb_qpsk_mapper.v` 依次测试 00、01、10、11 四个点。

在 Vivado 2024.1 Tcl Shell 中运行：

```text
xvlog fpga/rtl/qpsk_mapper.v fpga/tb/tb_qpsk_mapper.v
xelab tb_qpsk_mapper -s tb_qpsk_mapper_sim
xsim tb_qpsk_mapper_sim -runall
```

期望看到：

```text
PASS qpsk_mapper: all four QPSK points matched Q1.15 reference
```
