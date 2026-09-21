$ErrorActionPreference = 'Continue'
Write-Host '== ISAC-PYNQ-Z2 tool check =='
git --version
py --version
python --version
if (Get-Command vivado -ErrorAction SilentlyContinue) { vivado -version } else { Write-Host 'Vivado: NOT FOUND (expected after AMD installation)' -ForegroundColor Yellow }
if (Get-Command xsdb -ErrorAction SilentlyContinue) { xsdb -version } else { Write-Host 'XSDB: NOT FOUND (expected after AMD installation)' -ForegroundColor Yellow }
if (Test-Path '.venv\Scripts\python.exe') { & '.venv\Scripts\python.exe' -m pytest } else { Write-Host 'Python venv: NOT FOUND; run scripts/setup_pc.ps1' -ForegroundColor Yellow }
