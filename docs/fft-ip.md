# 64 点 FFT IP

工程通过 Vivado 2024.1 自带的 `xilinx.com:ip:xfft:9.1` 生成 `xfft_64`：

- 变换长度：64
- 输入/输出：16 位定点复数，AXI-Stream 32 位打包为 `{imag, real}`
- 输出顺序：自然顺序
- 单通道、非实时节流、缩放模式
- 配置字 `8'h55`：正向 FFT，`8'h54`：反向 IFFT。两者缩放计划均为 `[2,2,2]`，总比例 `1/64`
- 已启用 XFFT 的 `aresetn` 引脚，与 CP 模块和检查器由 BTN0 一起复位

`fft64_axis_wrapper` 把 XFFT 原生端口转换成项目使用的 I/Q `valid/ready/last` 接口。当前顶层链路是双频点测试帧 → 64 点 IFFT → 16 点 CP 插入 → CP 去除 → 64 点 FFT → 帧检查器。输入的第 1、63 频点实部各为 16384；两次 `1/64` 缩放后，输出两点应约为 256，其余频点约为 0。定点舍入容差为 ±32。尚未接到 PS/DMA。

构建脚本会自动生成 IP，不需要手动在 Vivado 图形界面创建：

```powershell
cd D:\pynqz2\isac-pynq-z2
& 'D:\pynqz2\tools\Vivado\2024.1\Vivado\2024.1\bin\vivado.bat' -mode batch -source scripts/build_pynq_z2.tcl -notrace
```
