$ErrorActionPreference = 'Stop'
$vivadoBin = 'D:\pynqz2\tools\Vivado\2024.1\Vivado\2024.1\bin'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$simRoot = Join-Path $repoRoot '..\build\vibration_phasor_sim'
$pythonExe = if ($env:PYTHON_EXE) { $env:PYTHON_EXE } else { Join-Path $repoRoot '.venv\Scripts\python.exe' }
if (-not (Test-Path $pythonExe)) { $pythonExe = 'python' }
New-Item -ItemType Directory -Force -Path $simRoot | Out-Null
Push-Location $simRoot
try {
    & (Join-Path $vivadoBin 'xvlog.bat') -work vibration_sim (Join-Path $repoRoot 'fpga\rtl\vibration_phasor_q14.v') (Join-Path $repoRoot 'fpga\tb\tb_vibration_phasor_q14.v')
    if ($LASTEXITCODE -ne 0) { throw 'xvlog failed' }
    & (Join-Path $vivadoBin 'xelab.bat') vibration_sim.tb_vibration_phasor_q14 -L vibration_sim -s tb_vibration_phasor_sim
    if ($LASTEXITCODE -ne 0) { throw 'xelab failed' }
    $firstOutput = & (Join-Path $vivadoBin 'xsim.bat') tb_vibration_phasor_sim -runall 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'xsim failed' }
    $firstOutput | Select-Object -Last 8
    if (($firstOutput -join "`n") -notmatch 'PASS vibration phasor' -or ($firstOutput -join "`n") -match 'Fatal:') { throw 'vibration phasor assertions failed' }
    & (Join-Path $vivadoBin 'xvlog.bat') -work vibration_sim (Join-Path $repoRoot 'fpga\rtl\range_gate_sampler.v') (Join-Path $repoRoot 'fpga\rtl\slow_time_sampler.v') (Join-Path $repoRoot 'fpga\rtl\slow_phase_product.v') (Join-Path $repoRoot 'fpga\tb\tb_slow_sensing.v')
    if ($LASTEXITCODE -ne 0) { throw 'slow sensing xvlog failed' }
    & (Join-Path $vivadoBin 'xelab.bat') vibration_sim.tb_slow_sensing -L vibration_sim -s tb_slow_sensing_sim
    if ($LASTEXITCODE -ne 0) { throw 'slow sensing xelab failed' }
    $secondOutput = & (Join-Path $vivadoBin 'xsim.bat') tb_slow_sensing_sim -runall 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'slow sensing xsim failed' }
    $secondOutput | Select-Object -Last 8
    if (($secondOutput -join "`n") -notmatch 'PASS slow sensing' -or ($secondOutput -join "`n") -match 'Fatal:') { throw 'slow sensing assertions failed' }
    & (Join-Path $vivadoBin 'xvlog.bat') -work vibration_sim (Join-Path $repoRoot 'fpga\tb\tb_vibration_nco_4096.v')
    if ($LASTEXITCODE -ne 0) { throw 'NCO xvlog failed' }
    & (Join-Path $vivadoBin 'xelab.bat') vibration_sim.tb_vibration_nco_4096 -L vibration_sim -s tb_vibration_nco_4096_sim
    if ($LASTEXITCODE -ne 0) { throw 'NCO xelab failed' }
    $thirdOutput = & (Join-Path $vivadoBin 'xsim.bat') tb_vibration_nco_4096_sim -runall 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'NCO xsim failed' }
    $thirdOutput | Select-Object -Last 8
    if (($thirdOutput -join "`n") -notmatch 'PASS vibration NCO' -or ($thirdOutput -join "`n") -match 'Fatal:') { throw '4096-sample NCO assertions failed' }
    & $pythonExe (Join-Path $repoRoot 'scripts\verify_vibration_nco.py') (Join-Path $simRoot 'vibration_nco_4096.csv')
    if ($LASTEXITCODE -ne 0) { throw '4096-sample RTL spectrum check failed' }
} finally {
    Pop-Location
}
