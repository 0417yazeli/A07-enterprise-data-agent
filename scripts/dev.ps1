# =============================================================================
# A07 项目一键启动脚本（Windows PowerShell）
# 用法：powershell -ExecutionPolicy Bypass -File scripts\dev.ps1 [backend|frontend|all]
# =============================================================================
$ErrorActionPreference = "Stop"

# 跨平台：定位项目根目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$env:PROJECT_ROOT = $ProjectRoot

Write-Host "==> Project root: $ProjectRoot"

# 跨平台：检测工具
$PythonBin = if ($env:PYTHON_BIN) { $env:PYTHON_BIN } else { "python" }
$NodeBin = if ($env:NODE_BIN) { $env:NODE_BIN } else { "node" }
$PnpmBin = if ($env:PNPM_BIN) { $env:PNPM_BIN } else { "pnpm" }
$NpmBin = if ($env:NPM_BIN) { $env:NPM_BIN } else { "npm" }

function Ensure-Env($Dir) {
  $Example = Join-Path $Dir ".env.example"
  $Target = Join-Path $Dir ".env"
  if ((Test-Path $Example) -and -not (Test-Path $Target)) {
    Write-Host "==> Creating $Target from $Example"
    Copy-Item $Example $Target
  }
}

function Start-Backend {
  Write-Host "==> Starting backend..."
  Ensure-Env (Join-Path $ProjectRoot "backend")
  Push-Location (Join-Path $ProjectRoot "backend")
  try {
    if (-not (Test-Path ".venv")) {
      Write-Host "==> Creating venv..."
      & $PythonBin -m venv .venv
    }
    .\.venv\Scripts\Activate.ps1
    pip install -e . --quiet
    Write-Host "==> Backend on http://localhost:8000"
    uvicorn app.main:app --reload --port 8000
  } finally {
    Pop-Location
  }
}

function Start-Frontend {
  Write-Host "==> Starting frontend..."
  Ensure-Env (Join-Path $ProjectRoot "frontend")
  Push-Location (Join-Path $ProjectRoot "frontend")
  try {
    if (-not (Test-Path "node_modules")) {
      Write-Host "==> Installing dependencies..."
      if (Get-Command $PnpmBin -ErrorAction SilentlyContinue) {
        & $PnpmBin install
      } else {
        & $NpmBin install
      }
    }
    Write-Host "==> Frontend on http://localhost:5173"
    if (Get-Command $PnpmBin -ErrorAction SilentlyContinue) {
      & $PnpmBin dev
    } else {
      & $NpmBin run dev
    }
  } finally {
    Pop-Location
  }
}

switch ($args[0]) {
  "backend" { Start-Backend; break }
  "frontend" { Start-Frontend; break }
  default {
    # all: 并行启动
    $backendJob = Start-Job -ScriptBlock {
      Set-Location (Join-Path $using:ProjectRoot "backend")
      .\.venv\Scripts\Activate.ps1
      uvicorn app.main:app --reload --port 8000
    }
    try {
      Start-Frontend
    } finally {
      Stop-Job $backendJob -ErrorAction SilentlyContinue
      Remove-Job $backendJob -ErrorAction SilentlyContinue
    }
    break
  }
}
