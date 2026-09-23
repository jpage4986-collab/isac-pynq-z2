# 当前接力记录

- 阶段：21，在阶段 20 的 PC 黄金模型和已实板验证的固定目标同链演示上，将单目标微振动相位、距离门 IQ、100 Hz 慢时间采样和相邻样本相位差接入 FPGA。
- 数据帧采用 52 个有效子载波，其中 4 个固定导频、48 个 Gray QPSK 数据子载波；固定 LFSR 种子为 `16'hACE1`，每个数据帧产生 96 bit。
- PL 检查器比较训练/导频幅值、保护带、帧尾和 QPSK 硬判决，累积帧数、总比特数和误码数。LED0 心跳、LED1 数据帧通过、LED2 收到完整帧、LED3 历史错误。
- 验证：5 点延迟模块的 80 点帧、TLAST 和背压 XSim 通过；IFFT → CP → 延迟 → 去 CP → FFT 仿真在第 1 子载波得到约 `(226,-121)` 的预期相位。新的同链 `tb_isac_integrated` 报告 `bits=96 errors=0 peak_bin=5 magnitude=13318`，PC 端累计 14 项测试通过。普通综合实现的 125 MHz WNS 为 0.097 ns；带 ILA 实现的 WNS 为 0.249 ns，二者 TNS 均为 0。
- 板端：`isac_integrated_top` 交替发射已知训练帧和 QPSK 数据帧，经同一个板内 5 点数字目标。接收 FFT 后训练帧走 `H=Y/X`/距离 IFFT 支路，数据帧走 Q14 相位均衡/QPSK 硬判决支路。实际 ILA 采集 1024 点：`frame_count=398585`、`data_frame_count=199292`、`bit_count=19132076`、`bit_errors=0`，全部点都有 `range_frame_valid=1`、`peak_bin=5`、`peak_magnitude=13318`。脚本为 `scripts/build_integrated_demo_jtag.tcl`、`scripts/capture_integrated_demo_jtag.tcl`、`scripts/summarize_integrated_capture.py`。
- LED：LED0 心跳；LED1 表示数据帧已到达且累计 0 误码；LED2 表示同一条流上的训练帧稳定测到第 5 个距离格；LED3 表示通信或测距验收失败。
- PC 黄金模型：`model/digital_scene.py` 定义可配置整数延迟目标、微振动相位、多目标响应叠加、AWGN、训练符号估计/均衡、QPSK BER、距离峰值、目标门相位和相对位移。4096 点/100 Hz、500 μm、30 dB 的两种输入 2.40/2.05 Hz 分别恢复 2.392578/2.050781 Hz，位移 RMSE 为 20.30/16.78 μm；第 5 格峰值在两组各 4096 点中均正确。0–30 dB BER 扫描每点 98,304 bit，结果及输入详见 `reports/digital_scene_20260923.json`。累计 19 项 Python 测试通过。
- 阶段 21 离线验证：默认 FPGA 单目标在 5 点延迟上施加帧边界更新的 100 Hz/2.4 Hz/500 µm 数字相位，目标门 IQ 与相邻慢时间相位差可供 ILA 读出。4096 点 RTL NCO 仿真得到 2.392578 Hz 频谱峰和 500.07 µm 幅值；动态整链 XSim 报告 `slow_samples=5 bits=1152 errors=0 peak_bin=5`；19 项 Python 测试通过。三级流水复数旋转器使带 ILA 实现达到 125 MHz、WNS +0.457 ns、TNS 0。
- 阶段 21 实板验收：供电恢复后 JTAG startup HIGH；首个 1024 点 ILA 快照为 19,272,288 bit、0 误码、1024/1024 个第 5 格峰值、强度 14666。另 12 份分时快照显示 bit_count `22,708,032 → 61,449,120`、bit_errors 始终 0、slow_sample_count `107 → 291`、9 种目标门 IQ、12 种相位差虚部。详见 `reports/dynamic_vibration_board_20260923.json` 与 `docs/dynamic-vibration-board.md`。
- 当前限制：这些短 ILA 快照可证明板内数字目标随时间改变，但不能证明板端 4096 点 2.4 Hz 频谱或 500 µm 位移误差。FPGA 尚无多目标可配置回波、位移换算、4096 点频谱、PS/AXI 和 DMA。
- 下一步：实现可配置多目标数字回波和 4096 点板端慢时间记录/位移/频谱链，形成与 PC 黄金模型逐样本的数值对照。
