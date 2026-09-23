# ISAC-PYNQ-Z2

面向结构微振动监测的 FPGA OFDM 通感一体化基带验证平台。

当前状态：阶段 19，已经把交替训练/QPSK 帧、4 个导频、PL 误码统计、`H=Y/X` 信道估计和 64 点距离 IFFT 合并到同一条接收 OFDM 流中。PYNQ-Z2 的 ILA 实测 1024 点显示累计 19,132,076 个 QPSK 比特 0 误码，且全部采样稳定得到第 5 距离格、强度 13318；详见[同链通信与测距验收](docs/integrated-isac.md)。尚未生成 PYNQ Overlay，也未接入射频或真实振动信号。

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

当前 Vivado 2024.1 安装在 `D:\pynqz2\tools\Vivado\2024.1\Vivado\2024.1`。`scripts/build_pynq_z2.tcl` 可从 RTL 重建普通通信 bitstream，`scripts/program_pynq_z2.tcl` 可通过 JTAG 下载到已连接的板。`scripts/build_integrated_demo.tcl` 与 `scripts/program_integrated_demo.tcl` 构建并下载同链通信/测距演示；要复现实板证据，运行 `scripts/build_integrated_demo_jtag.tcl`、`scripts/capture_integrated_demo_jtag.tcl` 和 `scripts/summarize_integrated_capture.py`。

## 接力规则

1. 每个任务先建 Issue，再从 `main` 建小分支。
2. 一个 PR 只解决一个模块或一个测试问题。
3. PR 必须写测试命令、结果、接口变化和已知限制。
4. `main` 保持可运行；未经审查不直接推送。
5. 每次交接更新 `handoff/current.md`。

## 当前可运行内容

PC 端的 OFDM 黄金模型、稀疏训练载波距离峰值和同链通信/感知测试可用 `python -m pytest` 验证。FPGA 端的 `isac_integrated_top` 让同一个 5 点数字回波同时服务通信和测距：XSim 检查到 96 bit、0 误码、第 5 距离格和强度 13318；PYNQ-Z2 的 ILA 实测到 19,132,076 bit、0 误码，1024 个样本均保持第 5 格和强度 13318。带 ILA bitstream 在 125 MHz 的建立时间裕量为 0.249 ns。带噪声 BER 曲线、目标门后的相位振动、PS/DMA 和真实感知仍是后续工作。

远程仓库：<https://github.com/jpage4986-collab/isac-pynq-z2>
