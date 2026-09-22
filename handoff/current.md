# 当前接力记录

- 状态：阶段 4（Q1.15 定点化和 FPGA 测试向量）
- 上一阶段：多径信道、训练均衡和 BER 已完成并合并到 `main`
- 本阶段内容：Q1.15 I/Q 量化、复数乘法、EVM 测试、确定性 OFDM 向量
- 验证命令：`.\.venv\Scripts\python.exe -m pytest`
- 向量生成：`.\.venv\Scripts\python.exe scripts\generate_ofdm_vector.py`
- 下一步：使用该向量编写 RTL 仿真，并设计 AXI-Stream 数据接口
- 当前阻塞：无
