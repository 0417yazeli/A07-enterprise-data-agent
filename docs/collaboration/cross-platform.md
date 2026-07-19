# 跨平台协作规范

> 团队成员同时使用 macOS 与 Windows，本文档是**所有代码与文档**必须遵守的路径与平台兼容规范。
> 任何 PR 若违反此规范，CI 校验将直接拒绝。

---

## 1. 核心原则

1. **零硬编码绝对路径**：禁止在源码、配置、文档中写 `/Users/xxx`、`C:\xxx`、`~/Desktop/xxx`。
2. **一切走环境**：路径、密钥、URL 全部走 `.env` + 配置中心。
3. **跨平台 API 优先**：Python 用 `pathlib.Path`，Node 用 `path.posix`/`path.win32` 适配。
4. **路径分隔符统一 `/`**：Python 与 Node 内部都接受 `/`，无需 `os.path.join` 拼接反斜杠。
5. **本地信息不入库**：个人配置（IDE 路径、虚拟环境路径、用户目录）一律不提交。

---

## 2. 路径占位符约定

文档与代码注释中需要引用路径时，使用以下占位符（**禁止**写真实路径）：

| 占位符 | 含义 | 运行时如何解析 |
|--------|------|----------------|
| `${PROJECT_ROOT}` | 项目根目录 | `git rev-parse --show-toplevel` 或 `Path(__file__).resolve().parents[N]` |
| `${BACKEND_DIR}` | 后端目录 | `${PROJECT_ROOT}/backend` |
| `${FRONTEND_DIR}` | 前端目录 | `${PROJECT_ROOT}/frontend` |
| `${DOCS_DIR}` | 文档目录 | `${PROJECT_ROOT}/docs` |
| `${SCRIPTS_DIR}` | 脚本目录 | `${PROJECT_ROOT}/scripts` |
| `~` | 用户主目录 | `Path.home()`（Python） / `os.homedir()`（Node） |

**实际示例**：
- ✅ `请将代码放在 \`\${PROJECT_ROOT}/backend\` 目录下`
- ❌ `请将代码放在 \`/Users/rumi/Desktop/A07-enterprise-data-agent/backend\` 目录下`
- ❌ `请将代码放在 \`C:\\Users\\rumi\\Desktop\\A07-enterprise-data-agent\\backend\` 目录下`

---

## 3. Python 路径处理规范

### 3.1 必须使用 `pathlib.Path`

```python
# ✅ 正确
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
BACKEND_DIR = PROJECT_ROOT / "backend"
CONFIG_FILE = BACKEND_DIR / "config" / "settings.yaml"

# ❌ 错误
PROJECT_ROOT = "/Users/rumi/Desktop/A07-enterprise-data-agent"
CONFIG_FILE = BACKEND_DIR + "/config/settings.yaml"  # 反斜杠混用
```

### 3.2 路径拼接

```python
# ✅
data_file = BACKEND_DIR / "data" / "raw" / "production.csv"

# ❌
data_file = BACKEND_DIR + "/data/raw/production.csv"
data_file = os.path.join(BACKEND_DIR, "data", "raw", "production.csv")  # 也能用，但不推荐
```

### 3.3 环境变量（pydantic-settings）

```python
# app/core/config.py
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # 数据库
    DATABASE_URL: str = "postgresql://user:pass@localhost:5432/a07"

    # LLM
    LLM_API_KEY: str = ""
    LLM_BASE_URL: str = "https://api.deepseek.com/v1"
    LLM_MODEL: str = "deepseek-chat"

    # 路径（运行时计算，不要写死）
    @property
    def project_root(self) -> Path:
        return Path(__file__).resolve().parents[2]

    @property
    def data_dir(self) -> Path:
        d = self.project_root / "data"
        d.mkdir(parents=True, exist_ok=True)
        return d

settings = Settings()
```

### 3.4 用户主目录

```python
# ✅
from pathlib import Path
home = Path.home()
config_dir = home / ".a07-agent"
config_dir.mkdir(parents=True, exist_ok=True)

# ❌
home = "/Users/rumi"  # macOS
home = "C:\\Users\\rumi"  # Windows
```

### 3.5 路径大小写处理

```python
# macOS 默认不敏感，Linux 敏感，Windows 不敏感
# 跨平台安全的目录名：全小写 + 短横线
# ✅ a07-agent, backend, frontend, docs, scripts
# ❌ A07-Agent, Backend, FrontEnd
```

---

## 4. 前端（Vue3 + Vite）路径规范

### 4.1 `vite.config.ts` 用相对 base

```ts
// ✅
export default defineConfig({
  base: './',  // 相对路径，部署到任意子目录都能跑
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: import.meta.env.VITE_API_BASE || 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
})
```

### 4.2 路径常量

```ts
// src/constants/paths.ts
export const PATHS = {
  ROOT: '/',
  KNOWLEDGE: '/knowledge',
  DATA: '/data',
  CHAT: '/chat',
  ANALYTICS: '/analytics',
} as const
```

### 4.3 资源引用

```vue
<!-- ✅ 相对路径 -->
<img src="@/assets/logo.png" />
<img :src="require('@/assets/icons/' + icon + '.png')" />

<!-- ❌ 绝对路径 -->
<img src="/Users/rumi/Desktop/A07-enterprise-data-agent/frontend/src/assets/logo.png" />
```

### 4.4 环境变量

```bash
# .env.development
VITE_API_BASE=http://localhost:8000

# .env.production
VITE_API_BASE=/api
```

```ts
// 使用
const apiBase = import.meta.env.VITE_API_BASE
```

---

## 5. 配置文件位置

### 5.1 不入库的文件

- `.env`（真实密钥、个性化配置）
- `.venv/`、`venv/`、`node_modules/`
- IDE 配置：`.idea/`、`.vscode/`（建议 `.vscode/settings.json` 入库共享）
- 系统垃圾：`.DS_Store`、`Thumbs.db`、`desktop.ini`

### 5.2 入库的配置

- `.env.example`（示例，**无真实密钥**）
- `pyproject.toml` / `package.json` / `vite.config.ts`
- `tsconfig.json` / `.eslintrc.*` / `.prettierrc.*`
- 共享 IDE 配置：`.editorconfig`、`.vscode/extensions.json`、`.vscode/settings.json`（去个人化）

### 5.3 `.editorconfig`（强烈建议加入）

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 2
insert_final_newline = true
trim_trailing_whitespace = true

[*.py]
indent_size = 4

[*.md]
trim_trailing_whitespace = false
```

---

## 6. 启动脚本

提供两个等价脚本，团队成员按平台选择：

| 平台 | 脚本 | 启动方式 |
|------|------|---------|
| macOS / Linux | `${SCRIPTS_DIR}/dev.sh` | `bash scripts/dev.sh` 或 `./scripts/dev.sh` |
| Windows | `${SCRIPTS_DIR}/dev.ps1` | `powershell -ExecutionPolicy Bypass -File scripts\dev.ps1` |

两个脚本功能等价：拉依赖 → 启动后端 → 启动前端。

---

## 7. Shell 命令兼容

### 7.1 README 与文档

- 默认给出 **macOS/Linux 写法**（bash/zsh）
- 如必须支持 Windows，给出 PowerShell 等价命令
- 避免使用 `sed -i`（Mac BSD sed 与 Windows 行为差异），改用 Python 脚本

### 7.2 跨平台命令封装

把平台相关命令封装到 `${SCRIPTS_DIR}/_common.py`，Python 调用：

```python
# scripts/_common.py
import platform
import subprocess
from pathlib import Path

def open_in_editor(path: Path) -> None:
    """跨平台打开文件"""
    system = platform.system()
    if system == "Darwin":
        subprocess.run(["open", str(path)])
    elif system == "Windows":
        subprocess.run(["start", str(path)], shell=True)
    else:
        subprocess.run(["xdg-open", str(path)])
```

---

## 8. 数据库连接字符串

### 8.1 走环境变量

```bash
# .env.example
DATABASE_URL=postgresql://user:pass@localhost:5432/a07
```

### 8.2 各平台本地开发

**macOS（Homebrew PostgreSQL）**：
```
DATABASE_URL=postgresql://postgres@localhost:5432/a07
```

**Windows（PostgreSQL Installer）**：
```
DATABASE_URL=postgresql://postgres:yourpassword@localhost:5432/a07
```

**Docker（两平台一致）**：
```
DATABASE_URL=postgresql://a07:a07@localhost:5432/a07
```

### 8.3 跨平台 PG 客户端

后端使用 `psycopg[binary]`（兼容 Mac/Linux/Windows 的预编译包），不要用 `psycopg2-binary`（Windows 安装困难）。

---

## 9. CI 校验

`.github/workflows/ci.yml` 必须包含：

1. **OS 矩阵**：`strategy.matrix.os: [macos-latest, windows-latest, ubuntu-latest]`
2. **换行符校验**：`! git ls-files | xargs -I {} sh -c 'file {} | grep -q CRLF && exit 1'`
3. **路径扫描**：检查源码中是否出现 `/Users/` 或 `C:\\` 硬编码
4. **构建测试**：三平台均能 `npm install` + `pnpm build` + `pytest`

---

## 10. 团队成员 Onboarding Checklist

新成员加入时：

- [ ] 安装 Git、Node 20+、Python 3.11+、PostgreSQL 14+
- [ ] `git config --global core.autocrlf input`（**关键**）
- [ ] `git config --global core.fileMode false`（避免 Windows 上文件权限差异）
- [ ] 克隆项目到任意位置，**禁止**固定到桌面
- [ ] 复制 `.env.example` 为 `.env` 并填入本地配置
- [ ] 运行 `bash scripts/dev.sh` 或 `scripts\dev.ps1` 验证启动
- [ ] 阅读本规范全文

---

## 11. 常见踩坑

| 现象 | 原因 | 解决 |
|------|------|------|
| Windows 检出后脚本 `\r` 报错 | 换行符 CRLF | 设置 `core.autocrlf input` + 重新检出 |
| `chmod +x` 在 Windows 无效 | Windows 无 Unix 权限位 | 用 `git update-index --chmod=+x` 显式设置 |
| `os.path.expanduser("~")` 拿到错误值 | 环境变量被覆盖 | 优先用 `Path.home()` |
| Python `open("file.txt", "r")` 路径含中文乱码 | Windows 默认 GBK | 显式 `encoding="utf-8"` |
| `subprocess.run("ls")` 在 Windows 失败 | `ls` 是 Unix 命令 | 用 `subprocess.run(["dir"], shell=True)` 或跨平台库 |
| Vite 构建后路径错乱 | `base: '/'` 绝对路径 | 改 `base: './'` |
| 前端读取环境变量 `undefined` | 变量名必须 `VITE_` 开头 | 重命名为 `VITE_API_BASE` |

---

## 12. 提 PR 前的自检

- [ ] 全文搜索 `git grep -E '/Users/|C:\\\\' -- ':!*.lock' ':!*.svg'` 无结果
- [ ] 全文搜索 `git grep -E 'TODO|FIXME|XXX' -- '*.py' '*.ts' '*.vue'` 已处理或登记
- [ ] `.env` 未被 `git add`
- [ ] 启动脚本在两平台都跑过
- [ ] CI 三平台绿

---

> **最后一条铁律**：如果你提交了一段含本机绝对路径的代码，请立刻 `git commit --amend` 修改。
> 维护者有权直接拒绝合并。
