# 单目标整数延迟数字回波

这一阶段先建立一个有明确真值的数字目标：每个带循环前缀的 80 点 OFDM 帧延迟 5 个采样。20 MHz 带宽下，一个往返延迟采样对应约 `c/(2B)=7.495 m`，所以第 5 个距离单元代表约 37.47 m。它是数字基带的距离示例，不代表板上已连接 5.8 GHz 射频前端。

`digital_delay_channel_axis` 先接收完整的 80 点帧，再输出 80 点：前 5 点为零，后面为原帧提前 5 点的内容，TLAST 仍落在第 80 点。由于 5 点小于 16 点循环前缀，接收端删除 CP 后看到的是 64 点有用符号的循环延迟；频域各子载波获得线性相位斜率，`H=Y/X` 后做 64 点 IFFT，峰值应出现在第 5 点。

```powershell
$vivado = 'D:\pynqz2\tools\Vivado\2024.1\Vivado\2024.1\bin\vivado.bat'
& $vivado -mode batch -source scripts/run_delay_channel_sim.tcl -notrace
.\.venv\Scripts\python.exe -m pytest
```

RTL 仿真检查 5 点延迟、80 点帧尾和 AXI-Stream 背压；Python 黄金模型检查第 5 个距离单元峰值和约 37.47 m 的换算。本阶段模块尚未插入普通板上 bitstream，因为原有通信检查器只接受零延迟直连信号。下一步应在带延迟链路中增加训练符号信道估计、均衡和距离 IFFT，再为 LED/ILA 定义新的验收状态。
