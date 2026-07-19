# LLM API Key 申请与使用指南

> 🎯 **目标**：在 M1（第一周）结束前，3 个成员都拿到 **DeepSeek** + **Qwen** 双供应商的 API Key，确保 LangChain Agent 任何时候都有可用兜底。

---

## 为什么需要双供应商

| 风险 | 概率 | 影响 |
|------|------|------|
| DeepSeek 当天 API 限额耗尽 | 中 | 高 |
| DeepSeek 服务临时维护 | 低 | 致命 |
| Qwen（通义千问）服务异常 | 低 | 中 |
| 单供应商突然涨价 | 中 | 中 |

**双供应商策略**：
- **主用**：DeepSeek（性价比高，V3 / R1 可选）
- **备用**：Qwen（通义千问 turbo，开通快、文档全）
- **切换条件**：主供应商连续 2 次失败 / 响应 > 10s

---

## 1. DeepSeek 申请

### 步骤
1. 访问 https://platform.deepseek.com/
2. 点击右上角「注册」（支持手机号 + 微信 + 邮箱）
3. 完成实名认证（学生可上传学生证，通常 5 分钟内审核通过）
4. 进入「API Keys」页面：https://platform.deepseek.com/api_keys
5. 点击「创建新 Key」，命名（如 `a07-A`），复制保存（**仅显示一次！**）
6. 充值：建议先充 10-50 元（个人比赛够用，请使用本人实名账户）

### 模型选择
- `deepseek-chat`（V3，推荐日常用，¥1/M tokens）
- `deepseek-reasoner`（R1，复杂推理场景，¥4/M tokens）
- 默认用 `deepseek-chat`

### 配置文件（已就绪）
在 `${PROJECT_ROOT}/backend/.env` 中设置：
```bash
LLM_API_KEY=<YOUR_DEEPSEEK_API_KEY>
LLM_BASE_URL=https://api.deepseek.com/v1
LLM_MODEL=deepseek-chat
```

### 验证
```bash
curl -X POST https://api.deepseek.com/v1/chat/completions \
  -H "Authorization: Bearer $LLM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-chat",
    "messages": [{"role":"user","content":"你好"}],
    "max_tokens": 50
  }'
```

---

## 2. Qwen（通义千问）申请

### 步骤
1. 访问 https://dashscope.aliyun.com/
2. 用 **阿里云账号** 登录（可用支付宝 / 淘宝一键登录）
3. 完成实名认证（学生可上传学生证）
4. 进入「API-KEY 管理」：https://dashscope.console.aliyun.com/apiKey
5. 点击「创建我的 API-KEY」，复制保存
6. 开通模型：进入「模型广场」→ 开通 `qwen-turbo`（免费额度 100 万 tokens）
7. 充值：可先不充，免费额度足够演示

### 模型选择
- `qwen-turbo`（推荐，速度快、价格低）
- `qwen-plus`（更强，中等价位）
- `qwen-max`（最强，价格高）

### 配置文件
```bash
# 当 DeepSeek 失败时切换到 Qwen
LLM_API_KEY=<YOUR_DEEPSEEK_API_KEY>
LLM_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
LLM_MODEL=qwen-turbo
```

### 验证
```bash
curl -X POST https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions \
  -H "Authorization: Bearer $LLM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-turbo",
    "messages": [{"role":"user","content":"你好"}],
    "max_tokens": 50
  }'
```

---

## 3. 在项目中的使用（LangChain）

### 后端 fallback 模板

```python
# backend/app/services/llm_factory.py
from __future__ import annotations
from langchain_openai import ChatOpenAI
from app.core.config import settings


def get_llm(timeout: int = 30) -> ChatOpenAI:
    """获取主用 LLM。"""
    return ChatOpenAI(
        model=settings.LLM_MODEL,
        openai_api_key=settings.LLM_API_KEY,
        openai_api_base=settings.LLM_BASE_URL,
        timeout=timeout,
        max_retries=2,
    )


def get_fallback_llm(timeout: int = 30) -> ChatOpenAI:
    """备用 LLM（与主用不同供应商）。"""
    return ChatOpenAI(
        model=settings.FALLBACK_LLM_MODEL,
        openai_api_key=settings.FALLBACK_LLM_API_KEY,
        openai_api_base=settings.FALLBACK_LLM_BASE_URL,
        timeout=timeout,
        max_retries=2,
    )


def chat_with_fallback(messages: list[dict]) -> str:
    """主用失败时自动切换备用。"""
    try:
        llm = get_llm()
        return llm.invoke(messages).content
    except Exception as e:
        import structlog
        log = structlog.get_logger()
        log.warning("primary_llm_failed_try_fallback", error=str(e))
        return get_fallback_llm().invoke(messages).content
```

### `.env` 双供应商配置

```bash
# 主用：DeepSeek
LLM_API_KEY=sk-deepseek-xxx
LLM_BASE_URL=https://api.deepseek.com/v1
LLM_MODEL=deepseek-chat

# 备用：Qwen
FALLBACK_LLM_API_KEY=sk-qwen-xxx
FALLBACK_LLM_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
FALLBACK_LLM_MODEL=qwen-turbo
```

---

## 4. 成本估算（4 周 / 3 人 / 演示场景）

| 场景 | 每次 tokens | 演示次数 | 累计 |
|------|-------------|----------|------|
| 自然语言问数 | ~2k | 200 | 400k |
| 业务问题生成 | ~1.5k | 100 | 150k |
| ML 解释 | ~2k | 50 | 100k |
| 开发调试 | ~5k | 200 | 1M |
| **合计** | | | **~1.6M tokens** |

- DeepSeek chat：约 ¥1.6
- Qwen turbo：免费额度 100 万 tokens（够用）

**结论**：3 人 4 周演示全部成本 < ¥10（DeepSeek 价）/ ¥0（Qwen 免费）。

---

## 5. 申请 Checklist

| 成员 | DeepSeek 申请 | DeepSense 充值 | Qwen 申请 | Qwen 验证调用 |
|------|---------------|---------------|-----------|---------------|
| A | ☐ | ☐ | ☐ | ☐ |
| B | ☐ | ☐ | ☐ | ☐ |
| C | ☐ | ☐ | ☐ | ☐ |

**截止时间**：M1 验收日（T+7）前全部完成

---

## 6. 紧急情况

### 申请遇到困难
- 实名认证不通过：用家人身份（需要确认合规性）
- 充值失败：换微信 / 支付宝 / 银行卡
- 余额用完：紧急切换到 Qwen 免费版

### 服务宕机
- DeepSeek 状态页：https://status.deepseek.com/
- Qwen 状态：阿里云控制台首页

### 速率限制
- DeepSeek：默认 60 RPM，可在后台申请提升
- Qwen：默认 60 QPS，免费版足够

---

## 7. 安全提醒

⚠️ **绝对禁止**：
- 把 API Key 提交到 Git
- 把 API Key 写到文档/截图中
- 多人共享一个 Key（限额共享易冲突）

✅ **正确做法**：
- Key 存到 `.env`（已在 `.gitignore`）
- `.env.example` 中保留占位符（已就绪）
- 团队成员各自申请独立 Key
- 定期轮换 Key（每月一次）

---

> **M1 必做**：3 人在 T+7 之前完成 DeepSeek + Qwen 申请 + 验证调用 + `.env` 配好。
> 没完成则 M2 MVP 无法跑通。
