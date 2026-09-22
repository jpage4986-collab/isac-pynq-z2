# 当前接力记录

- 状态：阶段 6（QPSK 模块首次上板）
- 上一阶段：Verilog QPSK 映射器和 Vivado xsim 自检已完成并合并到 `main`
- 本阶段内容：QPSK 映射器接入 `isac_top`，自动构建 bitstream，并通过 PYNQ-Z2 USB-JTAG 烧录验证
- 验证结果：Vivado 综合、实现、bitstream 成功；xc7z020 启动状态 HIGH，器件已编程
- 构建命令：`vivado.bat -mode batch -source scripts/build_pynq_z2.tcl`
- 烧录命令：`vivado.bat -mode batch -source scripts/program_pynq_z2.tcl`
- 下一步：加入循环前缀插入/移除模块，再连接 AXI-Stream 数据握手
- 当前阻塞：无
