# A07-enterprise-data-agent

> **企业数据底座智能问析 Agent 系统** — 面向杭州自动化技术研究院 / 图快数字科技比赛的参赛项目。
>
> 基于大语言模型实现"自然语言提问 → 智能分析 → 结果展示"完整闭环，覆盖制造业的生产 / 质量 / 设备 / 库存等典型自助分析场景。

---

## 项目结构

```
A07-enterprise-data-agent/
├── docs/                          # 项目文档
│   ├── collaboration/             # 协作规范
│   │   └── cross-platform.md      # ★ 跨平台协作规范（必读）
│   ├── data-dictionary.md         # 数据字典（a07-data-engineer 维护）
│   ├── er-diagram.md              # ER 图（Mermaid）
│   ├── business-knowledge.md      # 业务知识（a07-product-manager 维护）
│   └── design/                    # 设计稿（Figma 导出）
├── backend/                       # FastAPI + LangChain 后端
├── frontend/                      # Vue3 + ECharts 前端
├── scripts/                       # 跨平台脚本
│   ├── dev.sh                     # macOS / Linux 一键启动
│   ├── dev.ps1                    # Windows PowerShell 一键启动
│   └── _common.py                 # 跨平台工具（pathlib / 路径解析）
├── .github/workflows/             # CI（三平台矩阵）
├── .editorconfig                  # 编辑器规范
├── .gitattributes                 # 换行符 / 二进制锁定
├── .env.example                   # 环境变量样例
└── README.md
```

---

## 核心能力（按比赛命题）

| 能力 | 状态 | 负责智能体 |
|------|------|------------|
| 业务知识管理 | 🔧 规划中 | `a07-product-manager` + `a07-data-engineer` |
| 数据资源理解 | 🔧 规划中 | `a07-data-engineer` + `a07-frontend-dev` |
| 自然语言智能分析 | 🔧 规划中 | `a07-backend-dev`（LangChain Agent） |
| SQL / 脚本生成与执行 | 🔧 规划中 | `a07-backend-dev` + `a07-data-engineer` |
| ML 建模（6 大算法） | 🔧 规划中 | `a07-ml-engineer` |
| 分析结果展示（表格 + 图表） | 🔧 规划中 | `a07-frontend-dev`（ECharts） |

---

## 🤖 角色智能体（Trae Skills）

项目已配置 5 个角色智能体（基于 Trae Skill 系统），主控可按任务类型自动调用：

| 智能体 | 职责 | 调用场景 |
|--------|------|---------|
| `a07-product-manager` | 需求分析、PRD、功能拆解 | 提出新需求、梳理业务、写 PRD |
| `a07-backend-dev` | FastAPI、LangChain、API | 实现后端、API、Agent |
| `a07-frontend-dev` | Vue3、ECharts、UI、动画 | 页面、UI、组件、可视化 |
| `a07-data-engineer` | PostgreSQL、数据字典、ER | 表结构、SQL、样例数据 |
| `a07-ml-engineer` | 6 大 ML 算法、训练、推理 | 建模、预测、异常检测 |

智能体位置：`~/.trae/skills/a07-*/SKILL.md`（全局可见）

---

## 🍎🪟 跨平台协作（重要）

> 团队成员同时使用 **macOS** 与 **Windows**，**严禁**在源码 / 文档中硬编码本机绝对路径。
> 完整规范见 [docs/collaboration/cross-platform.md](docs/collaboration/cross-platform.md)

### 新成员 Onboarding（任一平台通用）

```bash
# 1. 克隆项目到任意位置（不要固定到桌面）
git clone https://github.com/0417yazeli/A07-enterprise-data-agent.git
cd A07-enterprise-data-agent

# 2. 配置 Git 换行符（关键）
git config --global core.autocrlf input
git config --global core.fileMode false

# 3. 一键启动
# macOS / Linux
bash scripts/dev.sh
# Windows PowerShell
powershell -ExecutionPolicy Bypass -File scripts\dev.ps1
```

### 路径占位符速查

| 占位符 | 含义 |
|--------|------|
| `${PROJECT_ROOT}` | 项目根目录（运行时自动解析） |
| `${BACKEND_DIR}` | `${PROJECT_ROOT}/backend` |
| `${FRONTEND_DIR}` | `${PROJECT_ROOT}/frontend` |
| `${DOCS_DIR}` | `${PROJECT_ROOT}/docs` |
| `${SCRIPTS_DIR}` | `${PROJECT_ROOT}/scripts` |

**禁止写法**：
- ❌ `/Users/rumi/Desktop/A07-enterprise-data-agent/...`
- ❌ `C:\Users\rumi\Desktop\A07-enterprise-data-agent\...`
- ❌ `~/Desktop/A07-enterprise-data-agent/...`

**正确写法**：
- ✅ `${PROJECT_ROOT}/backend`
- ✅ `Path(__file__).resolve().parents[2] / "backend"`（Python）
- ✅ `import.meta.env.VITE_API_BASE`（前端）

### 自检命令

```bash
# 扫描硬编码路径
git grep -nE '/Users/|C:\\\\' -- ':!*.lock' ':!*.svg'

# 校验换行符
git ls-files | xargs -I {} sh -c 'file "{}" | grep -q CRLF && echo {}'
```

CI 已配置三平台（macOS / Windows / Ubuntu）矩阵校验，违反规范的 PR 会被自动拒绝。

---

## 技术栈

- **后端**：Python 3.11+ / FastAPI / LangChain / SQLAlchemy 2.x / Pydantic / pytest
- **数据库**：PostgreSQL 14+（开发可降级 SQLite）
- **前端**：Vue 3.4 / Vite 5 / TypeScript / Pinia / Element Plus / ECharts 5
- **LLM**：DeepSeek / Qwen / ChatGLM（OpenAI 兼容协议）
- **CI**：GitHub Actions（macOS / Windows / Ubuntu 三平台）

---

## 开发规范

- **代码风格**：Python 用 `ruff format` + `ruff check`；前端用 ESLint + Prettier
- **类型检查**：Python `mypy`；前端 `tsc --noEmit`
- **测试**：后端 `pytest -q`；前端 `vitest run`
- **提交规范**：Conventional Commits（如 `feat: add NL2SQL endpoint`）
- **PR 流程**：feature 分支 → PR → CI 三平台绿 → 合并
- **路径规范**：见 [docs/collaboration/cross-platform.md](docs/collaboration/cross-platform.md)

---

## 比赛资料

- 比赛命题：杭州自动化技术研究院 / 图快数字科技(杭州)公司
- 题目：企业数据底座智能问析 Agent 系统（应用类 · 智能计算方向）
- 提交材料：项目概要、PPT、详细方案、演示视频、产品手册等

详细命题见 `docs/competition-brief.md`（待补充）

---

## 许可证

内部参赛项目，版权归参赛团队所有。
