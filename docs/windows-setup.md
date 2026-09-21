# Windows开发环境路径

当前电脑的 D 盘工作目录约定如下：

- 项目仓库：`D:\pynqz2\isac-pynq-z2`
- AMD/Vivado安装目标：`D:\pynqz2\tools\Vivado\2024.1`
- 安装包下载目录：`D:\pynqz2\downloads`
- Vivado工程生成目录：`D:\pynqz2\build`

Vivado需要从AMD官方安装器下载，不能由仓库脚本代替。安装时选择 Vivado Design Suite、Zynq-7000器件支持、Vivado Simulator和Cable Drivers；暂时不安装PetaLinux。安装器的安装路径选择 `D:\pynqz2\tools\Vivado\2024.1`。

安装完成后重新打开终端，在仓库目录运行：

```powershell
& 'D:\pynqz2\isac-pynq-z2\scripts\check_tools.ps1'
```

如果找不到 `vivado`，可在当前终端临时加载：

```powershell
$env:XILINX_VIVADO = 'D:\pynqz2\tools\Vivado\2024.1'
& "$env:XILINX_VIVADO\bin\vivado.bat" -version
```

PYNQ-Z2镜像烧录不放进Git仓库。镜像文件和校验值放在 `D:\pynqz2\downloads`，烧录时确认MicroSD盘符，避免误写硬盘。
