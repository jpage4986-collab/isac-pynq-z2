# 64 点 FFT IP

工程通过 Vivado 2024.1 自带的 `xilinx.com:ip:xfft:9.1` 生成 `xfft_64`：

- 变换长度：64
- 输入/输出：16 位定点复数，AXI-Stream 32 位打包为 `{imag, real}`
- 输出顺序：自然顺序
- 单通道、非实时节流、缩放模式
- 配置字 `8'h01`：正向 FFT

`fft64_axis_wrapper` 把 XFFT 原生端口转换成项目使用的 I/Q `valid/ready/last` 接口。当前顶层链路是测试帧源 → CP 插入 → CP 去除 → 64 点 FFT；FFT 输出还没有接到 PS/DMA，LED 只用于帧完成心跳验证。

构建脚本会自动生成 IP，不需要手动在 Vivado 图形界面创建：

```powershell
cd D:\pynqz2\isac-pynq-z2
& "$env:XILINX_VIVADO\Vivado\2024.1\bin\vivado.bat" -mode batch -source scripts/build_pynq_z2.tcl -notrace
```
