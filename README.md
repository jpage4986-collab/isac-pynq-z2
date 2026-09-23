# ISAC-PYNQ-Z2

面向结构微振动监测的 FPGA OFDM 通感一体化基带验证平台。

当前状态：阶段 18，已在 64 点 IFFT/FFT 与 16 点循环前缀的板内回环上接入交替训练/QPSK 帧、4 个导频和 PL 误码计数器；可用 [USB-JTAG/ILA 读取四个计数器](docs/jtag-counter-readout.md)。[5 点数字延迟回波](docs/digital-delay-channel.md) 已接入独立的训练帧感知链，完成 `H=Y/X`、64 点距离 IFFT 和峰值检测；RTL 仿真和 PYNQ-Z2 的 1024 个 ILA 实测样本均报告第 5 距离格、强度 13318，并提供可下载的 [板端演示](docs/training-range-peak.md)。尚未生成 PYNQ Overlay，也未接入射频或真实振动信号。

## 目标

在 PYNQ-Z2 上完成同一 OFDM 接收流的通信与感知闭环：QPSK、64 点 IFFT/FFT、16 点 CP、数字多径/延迟/载波相位振动信道、训练符号信道估计、距离 IFFT、相位增量、位移和慢时间频谱。PL 承担实时核心算法，PS/PYNQ 负责寄存器、DMA、记录和界面。

项目边界：当前是数字基带验证平台，不包含 5.8 GHz 射频前端、天线、RIS 硬件或桥梁现场实测。5.8 GHz 只作为数字回波相位模型参数。

## 目录

- `model/`：浮点黄金模型和参数定义
- `fpga/rtl/`：可综合 RTL（后续按模块加入）
- `fpga/tb/`：RTL 仿真测试
- `fpga/constraints/`：PYNQ-Z2 引脚与时钟约束；XFFT IP 由脚本生成
- `pynq/`：Overlay 加载、寄存器、DMA 和 Notebook
- `scripts/`：环境检查、模型测试、Vivado 构建入口
- `docs/`：接口、定点、实验和交接文档
- `handoff/`：三人接力记录

## Windows 快速开始

```powershell
cd D:\pynqz2\isac-pynq-z2
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\setup_pc.ps1
.\.venv\Scripts\Activate.ps1
python -m pytest
```

当前 Vivado 2024.1 安装在 `D:\pynqz2\tools\Vivado\2024.1\Vivado\2024.1`。`scripts/build_pynq_z2.tcl` 可从 RTL 重建普通通信 bitstream，`scripts/program_pynq_z2.tcl` 可通过 JTAG 下载到已连接的板。`scripts/build_range_demo.tcl` 与 `scripts/program_range_demo.tcl` 构建并下载固定 5 点数字目标的测距演示。要从电脑读取板内通信计数器，运行 `scripts/build_jtag_counters.tcl`、`scripts/capture_jtag_counters.tcl` 和 `scripts/summarize_counter_capture.py`。

## 接力规则

1. 每个任务先建 Issue，再从 `main` 建小分支。
2. 一个 PR 只解决一个模块或一个测试问题。
3. PR 必须写测试命令、结果、接口变化和已知限制。
4. `main` 保持可运行；未经审查不直接推送。
5. 每次交接更新 `handoff/current.md`。

## 当前可运行内容

PC 端的 OFDM 黄金模型、稀疏训练载波距离峰值和相位到位移测试可用 `python -m pytest` 验证。FPGA 端已完成交替训练/QPSK 数据帧的无噪声通信回环，并用 XSim 检查帧尾、定点频点值和 PL 误码统计。ILA 实板采集到 2 个数据帧、192 bit、0 误码。独立的训练帧感知链在 XSim 中从 5 点数字回波找到第 5 个距离峰值（强度 13318），并在 PYNQ-Z2 的 1024 个 ILA 采样中保持该结果；该 ILA bitstream 在 125 MHz 的建立时间裕量为 0.234 ns。带噪声 BER 曲线、目标门后的相位振动、PS/DMA 和真实感知仍是后续工作。

远程仓库：<https://github.com/jpage4986-collab/isac-pynq-z2>
