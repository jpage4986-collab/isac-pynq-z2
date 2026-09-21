# ISAC-PYNQ-Z2

面向结构微振动监测的 FPGA OFDM 通感一体化基带验证平台。

当前状态：`bootstrap`，已建立仓库骨架和 PC 端黄金模型入口；尚未安装 Vivado，尚未生成 PYNQ Overlay。

## 目标

在 PYNQ-Z2 上完成同一 OFDM 接收流的通信与感知闭环：QPSK、64 点 IFFT/FFT、16 点 CP、数字多径/延迟/载波相位振动信道、训练符号信道估计、距离 IFFT、相位增量、位移和慢时间频谱。PL 承担实时核心算法，PS/PYNQ 负责寄存器、DMA、记录和界面。

项目边界：当前是数字基带验证平台，不包含 5.8 GHz 射频前端、天线、RIS 硬件或桥梁现场实测。5.8 GHz 只作为数字回波相位模型参数。

## 目录

- `model/`：浮点黄金模型和参数定义
- `rtl/`：可综合 RTL（后续按模块加入）
- `tb/`：仿真测试
- `ip/`、`constraints/`、`vivado/`：Vivado 工程源与约束
- `pynq/`：Overlay 加载、寄存器、DMA 和 Notebook
- `scripts/`：环境检查、模型测试、Vivado 构建入口
- `docs/`：接口、定点、实验和交接文档
- `handoff/`：三人接力记录

## Windows 快速开始

```powershell
cd C:\Users\28185\Documents\Codex\2026-09-21\w\isac-pynq-z2
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\setup_pc.ps1
.\.venv\Scripts\Activate.ps1
python -m pytest
```

以后迁移到 D 盘时，只需把整个仓库复制到例如 `D:\fpga\isac-pynq-z2`，在新目录重新运行 `setup_pc.ps1`。Vivado 安装路径由环境变量 `XILINX_VIVADO` 指定，默认建议 `D:\AMD\Vivado\2024.1`。

## 接力规则

1. 每个任务先建 Issue，再从 `main` 建小分支。
2. 一个 PR 只解决一个模块或一个测试问题。
3. PR 必须写测试命令、结果、接口变化和已知限制。
4. `main` 保持可运行；未经审查不直接推送。
5. 每次交接更新 `handoff/current.md`。

## 当前可运行内容

PC 端先验证相位到位移的数学约定和 2.40 Hz / 2.05 Hz 频率估计。运行 `python -m pytest` 可看到基础测试结果。RTL、Vivado 和 PYNQ 硬件闭环按 `docs/roadmap.md` 的阶段推进。
