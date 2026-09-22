param(
    [string]$VivadoInstall = $env:XILINX_VIVADO
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$candidates = @(
    (Join-Path $VivadoInstall 'Vivado\2024.1\bin'),
    (Join-Path $VivadoInstall 'bin')
)
$bin = $candidates | Where-Object { Test-Path (Join-Path $_ 'xvlog.bat') } | Select-Object -First 1
if (-not $bin) { throw "找不到 Vivado xvlog.bat，请检查 XILINX_VIVADO=$VivadoInstall" }
$sim = Join-Path $repo 'sim\qpsk'
New-Item -ItemType Directory -Force $sim | Out-Null
Push-Location $sim
try {
    & (Join-Path $bin 'xvlog.bat') -work qpsk_sim (Join-Path $repo 'fpga\rtl\qpsk_mapper.v') (Join-Path $repo 'fpga\tb\tb_qpsk_mapper.v')
    if ($LASTEXITCODE -ne 0) { throw 'xvlog failed' }
    & (Join-Path $bin 'xelab.bat') qpsk_sim.tb_qpsk_mapper -L qpsk_sim -s tb_qpsk_mapper_sim
    if ($LASTEXITCODE -ne 0) { throw 'xelab failed' }
    & (Join-Path $bin 'xsim.bat') tb_qpsk_mapper_sim -runall
    if ($LASTEXITCODE -ne 0) { throw 'xsim failed' }
} finally {
    Pop-Location
}
