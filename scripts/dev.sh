#!/usr/bin/env bash
# =============================================================================
# A07 项目一键启动脚本（macOS / Linux）
# 用法：bash scripts/dev.sh [backend|frontend|all]
# =============================================================================
set -euo pipefail

# 跨平台：定位项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export PROJECT_ROOT

echo "==> Project root: ${PROJECT_ROOT}"

# 跨平台：检测 Python 与 Node
PYTHON_BIN="${PYTHON_BIN:-python3}"
NODE_BIN="${NODE_BIN:-node}"
PNPM_BIN="${PNPM_BIN:-pnpm}"
NPM_BIN="${NPM_BIN:-npm}"

# 复制 .env.example → .env（仅当 .env 不存在时）
ensure_env() {
  local dir="$1"
  local example="${dir}/.env.example"
  local target="${dir}/.env"
  if [[ -f "${example}" && ! -f "${target}" ]]; then
    echo "==> Creating ${target} from ${example}"
    cp "${example}" "${target}"
  fi
}

start_backend() {
  echo "==> Starting backend..."
  ensure_env "${PROJECT_ROOT}/backend"
  cd "${PROJECT_ROOT}/backend"

  if [[ ! -d ".venv" ]]; then
    echo "==> Creating venv..."
    "${PYTHON_BIN}" -m venv .venv
  fi
  # shellcheck disable=SC1091
  source .venv/bin/activate
  pip install -e . --quiet

  echo "==> Backend on http://localhost:8000"
  uvicorn app.main:app --reload --port 8000
}

start_frontend() {
  echo "==> Starting frontend..."
  ensure_env "${PROJECT_ROOT}/frontend"
  cd "${PROJECT_ROOT}/frontend"

  if [[ ! -d "node_modules" ]]; then
    echo "==> Installing dependencies..."
    if command -v "${PNPM_BIN}" >/dev/null 2>&1; then
      "${PNPM_BIN}" install
    else
      "${NPM_BIN}" install
    fi
  fi

  echo "==> Frontend on http://localhost:5173"
  if command -v "${PNPM_BIN}" >/dev/null 2>&1; then
    "${PNPM_BIN}" dev
  else
    "${NPM_BIN}" run dev
  fi
}

case "${1:-all}" in
  backend)
    start_backend
    ;;
  frontend)
    start_frontend
    ;;
  all)
    # 同时启动两个服务
    start_backend &
    BACK_PID=$!
    trap 'echo "==> Stopping..."; kill ${BACK_PID} 2>/dev/null || true' EXIT INT TERM
    start_frontend
    ;;
  *)
    echo "Usage: $0 [backend|frontend|all]"
    exit 1
    ;;
esac
