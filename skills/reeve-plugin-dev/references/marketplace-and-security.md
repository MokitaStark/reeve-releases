# Python / 二进制 Worker 协议、安全防线与自定义插件市场规范

## 1. Python 或原生二进制 Worker 原始 JSON-Line 协议

当 `reeve.plugin.json` 的 `entry` 为 `.py`（宿主调用 `python3` / `python`）或编译后的可执行文件时，不注入 JS Shim，子进程需直接从 `stdin` 按行读取 JSON，并向 `stdout` 按行输出 JSON（刷新缓冲区 `flush=True`）：

1. **初始化请求（`init`）**
   - 输入：`{"id":1,"type":"init","entry":"/abs/path/main.py","context":{"project":{"id":"proj_1","rootPath":"/workspace"}}}`
   - 输出：`{"id":1,"result":{"ready":true,"tools":["ping_service"],"slots":[]}}`
2. **工具调用请求（`call`）**
   - 输入：`{"id":2,"type":"call","name":"ping_service","args":{"target":"127.0.0.1"}}`
   - 成功输出：`{"id":2,"result":{"ok":true,"latencyMs":4}}`
   - 失败输出：`{"id":2,"error":"连接目标超时"}`
3. **动态插槽渲染与动作（`render_slot` / `slot_action`）**
   - 渲染输入：`{"id":3,"type":"render_slot","slotId":"panel","state":{},"context":{"projectId":"proj_1","dark":false}}`
   - 渲染输出：`{"id":3,"result":{"badgeText":"OK","state":{},"view":{"type":"text","text":"运行正常"}}}`
   - 动作输入：`{"id":4,"type":"slot_action","slotId":"panel","handler":"refresh","payload":{},"state":{},"context":{}}`
   - 动作输出：`{"id":4,"result":{"state":{"refreshed":true},"toast":"已刷新","view":{"type":"text","text":"已更新"}}}`
4. **优雅关闭（`close`）**
   - 输入：`{"id":5,"type":"close"}`
   - 输出：`{"id":5,"result":{"closed":true}}` 并立即以状态码 `0` 退出。

### Python 最小骨架示例

```python
import json
import sys

def handle_call(name, args, ctx):
    if name == "ping_service":
        return {"ok": True, "project": ctx.get("project", {}).get("rootPath", "")}
    raise ValueError(f"未知工具: {name}")

def main():
    ctx = {}
    for raw in sys.stdin:
        line = raw.strip()
        if not line:
            continue
        msg = json.loads(line)
        req_id = msg.get("id")
        msg_type = msg.get("type")
        try:
            if msg_type == "init":
                ctx = msg.get("context") or {}
                res = {"ready": True, "tools": ["ping_service"], "slots": []}
            elif msg_type == "call":
                res = handle_call(msg.get("name"), msg.get("args") or {}, ctx)
            elif msg_type == "close":
                sys.stdout.write(json.dumps({"id": req_id, "result": {"closed": True}}) + "\n")
                sys.stdout.flush()
                return
            else:
                raise ValueError(f"不支持的消息类型: {msg_type}")
            out = {"id": req_id, "result": res}
        except Exception as exc:
            out = {"id": req_id, "error": str(exc)}
        sys.stdout.write(json.dumps(out, ensure_ascii=False) + "\n")
        sys.stdout.flush()

if __name__ == "__main__":
    main()
```

---

## 2. 生产级安全自检清单

在交付任何连接外部系统或操作本地资源的插件前，逐项核对：

- **禁止工具参数覆写鉴权目标域名**：连接云服务（如 GitHub、Notion、Sentry、飞书、Slack 等）时，API 基准域名应固定或仅读取受信任环境变量，不要允许模型在单次工具参数中传入任意 `baseUrl` 将宿主环境变量里的 `API_TOKEN` 发送到攻击者服务器，且 `fetch` 必须加 `redirect: 'error'`。
- **禁止从仓库内未授信配置文件直接加载可执行路径**：若插件封装本地 CLI（如 `kubectl`、`docker`、游戏引擎编辑器），只从标准系统安装目录、`PATH` 或用户显式环境变量查找二进制，严禁读取项目仓库内 JSON/TOML 指定的任意脚本路径执行（防止恶意仓库诱导 RCE）。
- **敏感字段递归脱敏**：
  ```javascript
  const SENSITIVE_KEY_RE = /(password|passwd|secret|token|api[_-]?key|authorization|cookie|session|private[_-]?key)/i;
  export function redactObject(value, depth = 0) {
    if (depth > 8 || value === null || value === undefined) return value;
    if (Array.isArray(value)) return value.map((item) => redactObject(item, depth + 1));
    if (typeof value === 'object') {
      const out = {};
      for (const [k, v] of Object.entries(value)) {
        out[k] = SENSITIVE_KEY_RE.test(k) ? '[REDACTED]' : redactObject(v, depth + 1);
      }
      return out;
    }
    return value;
  }
  ```

---

## 3. 发布与托管自定义插件市场（`registry.json`）

团队可将多个插件集中托管在共享目录、Git 仓库或内网/GitHub Releases 静态站点中，通过一份 `registry.json` 供团队成员在 Reeve「设置 → 插件 → 插件市场 → 市场源管理」一键订阅与热升级。

### `registry.json` 标准结构

```json
{
  "schemaVersion": 1,
  "name": "团队工程插件市场",
  "description": "内部研发效能、部署与监控连接器集合",
  "updatedAt": "2026-11-24",
  "plugins": [
    {
      "id": "local-dev-helper",
      "name": "本地研发助手",
      "version": "1.0.0",
      "description": "通过本地相对路径分发的插件（适合共享目录或克隆仓库）",
      "category": "效率工具",
      "tags": ["dev", "workspace"],
      "author": "Platform Team",
      "kind": "worker",
      "path": "./local-dev-helper",
      "runtimeRequirements": ["Bun 或 Node.js >= 20"],
      "featured": true
    },
    {
      "id": "release-notifier",
      "name": "发布巡检通知",
      "version": "1.2.0",
      "description": "通过 HTTPS 压缩包分发的远端插件（强制 SHA-256 校验）",
      "category": "基础设施",
      "tags": ["release", "ops"],
      "author": "Platform Team",
      "kind": "worker",
      "downloadUrl": "https://example.com/reeve-plugins/release-notifier-1.2.0.tar.gz",
      "sha256": "填写 shasum -a 256 计算出的 64 位小写十六进制摘要",
      "permissions": ["network:http"],
      "runtimeRequirements": ["Bun 或 Node.js >= 20"]
    }
  ]
}
```

### 远端插件包打包与校验命令

```bash
# 打包时排除 .git 与 node_modules，单包解压后总大小不得超过 20 MB，禁止包含外部符号链接
tar --exclude='.git' --exclude='node_modules' -czf release-notifier-1.2.0.tar.gz release-notifier/
shasum -a 256 release-notifier-1.2.0.tar.gz
```
