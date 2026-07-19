#!/usr/bin/env python3
"""
A07 跨平台通用工具脚本

提供项目根目录解析、路径处理、环境检测、跨平台命令执行等能力。
可被 Python 代码、bash、PowerShell 调用（通过 `python -m scripts._common`）。

用法：
    python -m scripts._common project-root
    python -m scripts._common ensure-env backend
    python -m scripts._common open-file README.md
"""
from __future__ import annotations

import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path


def project_root() -> Path:
    """解析项目根目录（跨平台）。

    优先级：
        1. 环境变量 PROJECT_ROOT
        2. 当前工作目录向上找 pyproject.toml / .git
        3. 本文件所在目录向上两级
    """
    env = os.environ.get("PROJECT_ROOT")
    if env:
        return Path(env).expanduser().resolve()

    cwd = Path.cwd().resolve()
    for parent in [cwd, *cwd.parents]:
        if (parent / "pyproject.toml").exists() or (parent / ".git").exists():
            return parent

    return Path(__file__).resolve().parents[1]


def data_dir(name: str = "data") -> Path:
    """获取并确保数据目录存在。"""
    d = project_root() / name
    d.mkdir(parents=True, exist_ok=True)
    return d


def ensure_env(target_dir: Path | str) -> Path | None:
    """若 .env 不存在但 .env.example 存在，则复制。返回目标路径或 None。"""
    d = Path(target_dir).expanduser().resolve()
    example = d / ".env.example"
    target = d / ".env"
    if example.exists() and not target.exists():
        target.write_text(example.read_text(encoding="utf-8"), encoding="utf-8")
        print(f"[env] created {target} from {example}")
        return target
    return target if target.exists() else None


def open_in_editor(path: Path | str) -> None:
    """跨平台用系统默认应用打开文件。"""
    p = Path(path).expanduser().resolve()
    if not p.exists():
        raise FileNotFoundError(p)
    system = platform.system()
    if system == "Darwin":
        subprocess.run(["open", str(p)], check=False)
    elif system == "Windows":
        # Windows 关联到默认应用
        os.startfile(str(p))  # type: ignore[attr-defined]
    else:
        opener = shutil.which("xdg-open") or shutil.which("gio")
        if opener:
            subprocess.run([opener, str(p)], check=False)
        else:
            print(f"Cannot open: {p}")


def print_table(rows: list[tuple[str, ...]], headers: tuple[str, ...]) -> None:
    """简单表格打印。"""
    widths = [max(len(h), *(len(r[i]) for r in rows)) for i, h in enumerate(headers)]
    sep = "  ".join("-" * w for w in widths)
    print("  ".join(h.ljust(w) for h, w in zip(headers, widths)))
    print(sep)
    for r in rows:
        print("  ".join(c.ljust(w) for c, w in zip(r, widths)))


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(__doc__)
        return 0
    cmd = argv[1]
    if cmd == "project-root":
        print(project_root())
        return 0
    if cmd == "ensure-env":
        if len(argv) < 3:
            print("usage: ensure-env <subdir>", file=sys.stderr)
            return 2
        sub = argv[2]
        target = project_root() / sub
        ensure_env(target)
        return 0
    if cmd == "open-file":
        if len(argv) < 3:
            print("usage: open-file <path>", file=sys.stderr)
            return 2
        open_in_editor(argv[2])
        return 0
    if cmd == "info":
        rows = [
            ("OS", platform.platform()),
            ("Python", sys.version.split()[0]),
            ("CWD", str(Path.cwd())),
            ("Project root", str(project_root())),
        ]
        print_table(rows, ("key", "value"))
        return 0
    print(f"unknown command: {cmd}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
