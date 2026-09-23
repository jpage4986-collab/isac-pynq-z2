# ISAC-PYNQ-Z2

面向结构微振动监测的 FPGA OFDM 通感一体化基带验证平台。

当前状态：阶段 21。PYNQ-Z2 已实板证明固定数字目标的同链 QPSK 零误码与第 5 距离格检测；详见[同链通信与测距验收](docs/integrated-isac.md)。PC 黄金模型具备可变单/多目标、4096 点慢时间位移/频谱和带噪声 BER 扫描。FPGA 已加入单目标的帧对齐微振动相位、距离门 IQ 和慢时间相位差，XSim 与 125 MHz 时序通过；[动态链验收记录](docs/dynamic-vibration-board.md)说明实板采集仍待供电恢复。FPGA 位移/频谱与多目标链、PYNQ Overlay、射频和真实振动信号尚未完成。

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

当前 Vivado 2024.1 安装在 `D:\pynqz2\tools\Vivado\2024.1\Vivado\2024.1`。`scripts/build_pynq_z2.tcl` 可从 RTL 重建普通通信 bitstream，`scripts/program_pynq_z2.tcl` 可通过 JTAG 下载到已连接的板。动态目标的仿真、构建和待供电恢复后的采集步骤见[板内微振动相位链](docs/dynamic-vibration-board.md)。

## 接力规则

1. 每个任务先建 Issue，再从 `main` 建小分支。
2. 一个 PR 只解决一个模块或一个测试问题。
3. PR 必须写测试命令、结果、接口变化和已知限制。
4. `main` 保持可运行；未经审查不直接推送。
5. 每次交接更新 `handoff/current.md`。

## 当前可运行内容

PC 端的 OFDM 黄金模型、可变单/多目标数字场景和带噪声 BER 扫描可用 `python -m pytest` 与 `scripts/report_digital_scene.py` 验证。旧版固定目标链的 PYNQ-Z2 ILA 实测到 19,132,076 bit、0 误码和第 5 格距离峰值。新版 FPGA 数字微振动链在 XSim 中记录 5 个慢时间样本、1152 bit 零错误；4096 点 RTL 相位样本的 2.4 Hz/500 µm 参数吻合，125 MHz 带 ILA bitstream 的 WNS 为 +0.457 ns。新版尚未完成供电恢复后的板端采集。FPGA 多目标、位移/频谱、PS/DMA 和真实感知仍是后续工作。

远程仓库：<https://github.com/jpage4986-collab/isac-pynq-z2>
