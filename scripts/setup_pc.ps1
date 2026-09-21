$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo
if (-not (Get-Command py -ErrorAction SilentlyContinue)) { throw '找不到 Python 启动器 py。请先安装 Python 3.10 或更高版本。' }
if (-not (Test-Path '.venv\Scripts\python.exe')) { py -3.12 -m venv .venv }
& '.venv\Scripts\python.exe' -m pip install --upgrade pip
& '.venv\Scripts\python.exe' -m pip install -r requirements.txt
& '.venv\Scripts\python.exe' -m pytest
Write-Host 'PC端模型环境已准备完成。' -ForegroundColor Green
Write-Host '激活命令：.\.venv\Scripts\Activate.ps1'
Write-Host 'Vivado建议安装目录：D:\AMD\Vivado\2024.1'
