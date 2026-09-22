$ErrorActionPreference = 'Stop'
$vivadoRoot = if ($env:XILINX_VIVADO) { $env:XILINX_VIVADO } else { 'D:\pynqz2\tools\Vivado\2024.1' }
$bin = Join-Path $vivadoRoot 'Vivado\2024.1\bin'
$simRoot = Join-Path $PSScriptRoot '..\sim\cp_axis'
New-Item -ItemType Directory -Force $simRoot | Out-Null
Push-Location $simRoot
try {
  & (Join-Path $bin 'xvlog.bat') -work cp_axis_sim (Join-Path $PSScriptRoot '..\fpga\rtl\cp_insert_axis.v') (Join-Path $PSScriptRoot '..\fpga\tb\tb_cp_insert_axis.v')
  & (Join-Path $bin 'xelab.bat') cp_axis_sim.tb_cp_insert_axis -L cp_axis_sim -s tb_cp_insert_axis_sim
  & (Join-Path $bin 'xsim.bat') tb_cp_insert_axis_sim -runall
} finally { Pop-Location }
