# PYNQ-Z2 Verilog LED 闪烁入门

这是一个独立的 PL 入门练习：用板载 125 MHz 时钟驱动计数器，每半秒翻转一次 LED0。无需外接 LED、电阻或面包板。

## 文件

- `led_blink.v`：可综合的 Verilog 顶层模块。默认参数对应 125 MHz 时钟和 1 Hz 完整闪烁周期。
- `led_blink.xdc`：本例用到的时钟、BTN0 和 LED0 引脚约束。引脚来自 PYNQ-Z2 板卡资料，也与项目的 `fpga/constraints/pynq_z2.xdc` 一致。

## 用 Vivado 生成并下载 bitstream

1. 确认开发板已供电；用 Micro-USB 数据线连接板上标有 `PROG UART` 的接口，再连接电脑。
2. 打开 Vivado，选择 **Create Project**，项目类型选择 **RTL Project**。本例不需要添加 IP。
3. 器件选择 `xc7z020clg400-1`。如果 Vivado 已安装 TUL 的 PYNQ-Z2 板卡定义，也可以在 Board 页面选择 PYNQ-Z2。
4. 添加本目录的 `led_blink.v`，然后在 **Add Constraints** 步骤添加 `led_blink.xdc`。确认顶层模块是 `led_blink`。
5. 依次运行 **Run Synthesis**、**Run Implementation** 和 **Generate Bitstream**。
6. 打开 **Open Hardware Manager → Open Target → Auto Connect**，选择 FPGA 器件并点 **Program Device**，选择刚生成的 `.bit` 文件。
7. 下载后按住 BTN0 一小会儿再松开：LED0 会先熄灭，然后约每秒完成一次亮灭循环。

生成 bitstream 和通过 JTAG 下载只改变 FPGA 当前配置；断电后配置会消失，不会改写 SD 卡。重新上电后需再次下载 bitstream。

## 代码在做什么

- `always @(posedge clk)` 表示状态只在时钟上升沿更新。
- 125 MHz 时钟每秒产生 125,000,000 个周期；计满 62,500,000 个周期后翻转 LED，因此每半秒切换一次。
- BTN0 按下时同步清零计数器并熄灭 LED0。松开后计数重新开始。
- `.xdc` 把逻辑信号 `clk`、`btn0`、`led0` 连接到板上的 H16、D19、R14 引脚，并告诉 Vivado 时钟周期为 8 ns。
- `CLK_HZ` 和 `BLINK_HZ` 是 Verilog 参数；改变它们可以改变目标时钟频率或闪烁速度。真实板卡上时钟参数必须匹配硬件时钟。

## 两种点灯方式

PYNQ 系统也可以用板上预装的 `base` Overlay，从 Python 控制 LED：

```python
from pynq.overlays.base import BaseOverlay
from time import sleep

base = BaseOverlay("base.bit")
while True:
    base.leds[0].toggle()
    sleep(0.5)
```

这段 Python 使用预先构建的硬件 Overlay；本例则是自己编写 Verilog、生成 bitstream 并直接下载到 PL。两者都能让 LED 闪烁，但只有本例练习了 RTL 到 FPGA 配置的流程。

## 常见问题

- **综合通过但 LED 不亮**：检查器件型号、顶层模块、约束文件是否加入工程；下载后按 BTN0 一次，让同步复位确实被采样。
- **Vivado 找不到 FPGA**：确认连接的是 `PROG UART` Micro-USB 口、线缆支持数据传输，并安装 Vivado cable drivers。
- **闪烁速度不对**：确认 `CLK_HZ` 与板上 125 MHz 时钟相符，且约束中的时钟周期为 8 ns。

## 和 ISAC 项目的关系

这个例程验证的是最基础的开发环境链路：Verilog → 综合与实现 → bitstream → JTAG → 板载 PL 输出。它不包含 OFDM、测距或振动检测，也没有 PS/PYNQ 寄存器控制或 DMA。

完成它后，下一步可在现有 ISAC 工程中做 PS 到 PL 的 AXI-Lite 寄存器读写，再做 DMA 数据传输；那才开始把 PYNQ 软件接入项目数据链。
