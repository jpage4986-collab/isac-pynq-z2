# PYNQ-Z2 板内 OFDM 回环（阶段 14）

当前 bitstream 在 FPGA 内部产生测试数据，不需要天线或额外线缆。64 个频域点中，第 1、63 点送入实部 16384，其余点为零。数据经过 IFFT、16 点循环前缀插入和移除、FFT，最后由 FPGA 自己检查结果。IFFT 和 FFT 各缩放 1/64，因此正确输出的两个目标频点约为 256，其他点约为零；检查容差为 ±32。

板上四个绿色 PL LED 的含义：

| 指示灯 | 含义 |
| --- | --- |
| LED0（R14） | 约 1 秒量级的心跳，证明 PL 时钟在运行 |
| LED1（P14） | 最近收到的一整帧通过数值与帧尾检查 |
| LED2（N16） | 至少收到过一整帧 |
| LED3（M14） | 自上次复位起出现过任何数据/帧尾错误；正常应熄灭 |

按住 BTN0 会清除帧检查状态，松开后重新开始。BTN0 在本板上按下为高电平，[PYNQ-Z2 用户手册](https://pynq.tue.nl/doc/pynqz2_user_manual_v1_0.pdf)明确说明这一点。正常上电且 bitstream 下载完成后，应看到 LED0 闪烁、LED1 和 LED2 常亮、LED3 熄灭。LED2 未亮表示还没有完整帧，不能凭 LED0 判定回环成功；LED3 亮表示检查失败，应保留日志排查。

在 Windows PowerShell 中，从仓库根目录执行：

```powershell
$vivado = 'D:\pynqz2\tools\Vivado\2024.1\Vivado\2024.1\bin\vivado.bat'
& $vivado -mode batch -source scripts/run_fft_roundtrip_sim.tcl -notrace
& $vivado -mode batch -source scripts/build_pynq_z2.tcl -notrace
& $vivado -mode batch -source scripts/program_pynq_z2.tcl -notrace
```

烧录通过 JTAG 写入易失性配置，断电后需重新下载；若要断电保留，需要后续另做 QSPI 或 SD 启动流程。这个阶段证明的是数字基带模块连接、握手、帧边界和定点结果，并不证明无线通信或结构微振动感知性能。
