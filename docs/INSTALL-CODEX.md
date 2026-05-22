# Codex 安装与使用指南（实验性）

> **实验性支持**：Codex 集成存在已知平台限制，体验与 Claude Code 版本不同，请阅读下方说明再决定是否使用。

## 与 Claude Code 的体验差距

当前 Codex 集成已经可以正常接收微信消息、调用 AI 处理并自动回复，也支持接收图片等媒体附件并交给 Codex 侧理解处理。与 Claude Code 的差距主要在终端展示和插件安装体验，而不是消息处理能力本身。

我们持续跟踪以下 Codex 官方 Issue，一旦这些问题得到解决，本项目会同步更新以提供更接近 Claude Code 的终端内体验：

| 能力 | Claude Code | Codex 现状 | 跟踪 Issue |
|------|-------------|------------|------------|
| 微信消息处理与回复 | ✅ 支持 | ✅ 支持，后台桥接自动处理并回复 | - |
| 图片附件理解 | ✅ 支持 | ✅ 支持接收图片等媒体附件并交给 Codex 处理 | - |
| 终端/桌面端显示微信对话 | ✅ 消息直接出现在会话中 | ✅ 默认 WebSocket desktop 模式下可在 Codex 桌面端展示；stdio headless 模式只显示 bridge 日志 | [#15320](https://github.com/openai/codex/issues/15320) |
| MCP 通知推送到会话 | ✅ `notifications/claude/channel` | ⚠️ 无等效机制，需看 bridge 日志 | [#15299](https://github.com/openai/codex/issues/15299) |
| 社区插件远程安装 | ✅ marketplace URL 一键安装 | ❌ 仅支持本地路径 | 官方社区市场尚未开放 |

因此，Codex 版本的核心能力已经可用。默认 `start-codex.sh` 使用 WebSocket desktop 模式，微信对话可以进入 Codex 桌面端会话；如果显式使用 `WEIXIN_CODEX_MODE=stdio`，则只在 bridge 进程日志中显示。

## 已知限制

| 限制 | 说明 |
|------|------|
| 显示模式差异 | 默认 WebSocket desktop 模式会把微信 turn 注入到 Codex 桌面端会话；stdio headless 模式只在 bridge 终端日志中显示收到的微信消息、turn 注入、状态变化和回复内容（[Issue #15320](https://github.com/openai/codex/issues/15320)） |
| 无远程安装 | Codex 目前仅支持本地路径安装社区插件，不支持从 GitHub 等远程源直接安装（官方社区市场尚未开放） |
| 单用户路由 | 多用户同时发消息时可能出现回复串号 |
| Plugin 职责有限 | Plugin 仅提供 `weixin-configure` 和 `weixin-access` 两个配置命令，运行时桥接由独立脚本负责 |

## 工作原理

```
微信用户 → 微信服务器 → server-codex.ts → Codex App Server → AI → 回复微信
```

`server-codex.ts` 以 standalone 桥接模式运行：持续轮询微信消息，注入 Codex App Server 作为 turn，AI 处理后自动将回复发回微信。

默认启动方式使用 `ws://127.0.0.1:4500` WebSocket App Server，这样 Codex 桌面端可以展示微信对话。若需要无桌面/headless 模式，可使用 `WEIXIN_CODEX_MODE=stdio`。`start-codex.sh` 会自动定位 Codex 可执行文件：

- 优先使用环境变量 `CODEX_BIN`
- 其次使用 `$PATH` 中的 `codex`
- 最后回退到 macOS Codex App 内置路径 `/Applications/Codex.app/Contents/Resources/codex`


## 安装

### 第一步：Clone 仓库

```bash
git clone https://github.com/joekytc/cc-weixin.git ~/cc-weixin
```

> 可以 clone 到任意位置，后续配置中替换路径即可。

### 第二步：配置本地 Marketplace

创建或编辑 `~/.agents/plugins/marketplace.json`：

```json
{
  "name": "personal",
  "plugins": [{
    "name": "weixin",
    "source": { "source": "local", "path": "./cc-weixin/plugins/weixin" },
    "policy": { "installation": "AVAILABLE", "authentication": "ON_INSTALL" },
    "category": "messaging"
  }]
}
```

> `path` 必须以 `./` 开头（相对于 `~` 即 home 目录），**不能使用绝对路径**（Codex 会报错拒绝加载）。如果 clone 到了其他位置，对应修改 `./` 后面的部分。

### 第三步：在 Codex 中安装插件

打开 Codex TUI：

```bash
codex
```

输入 `/plugins`，搜索 `weixin` 并安装。安装成功后可以看到 `weixin-configure` 和 `weixin-access` 两个 skill。

## 配置

### 第四步：扫码登录微信

在 Codex TUI 中运行（只需一次）：

```
$weixin-configure
```

用微信扫描终端中显示的二维码，扫码成功后凭证自动保存到 `~/.claude/channels/weixin/`。

### 第五步：启动桥接服务

```bash
~/cc-weixin/plugins/weixin/start-codex.sh
```

这会启动微信桥接进程，并由桥接进程内部启动 Codex App Server。默认使用 WebSocket desktop 模式，Codex 桌面端会自动出现/更新对应会话。日志实时显示在终端。按 `Ctrl+C` 停止，或在另一个终端执行：

```bash
~/cc-weixin/plugins/weixin/stop-codex.sh
```

```
[weixin] Dependencies ready.
[weixin] Starting Weixin bridge...
[weixin] Codex binary: /Applications/Codex.app/Contents/Resources/codex
[weixin] Stop with: ~/.codex/plugins/weixin/stop-codex.sh
[weixin] Mode: desktop (WebSocket)
[weixin] Starting Codex App Server at ws://127.0.0.1:4500...
codex app-server (WebSockets)
[weixin] App Server ready.
[weixin-codex] Standalone bridge mode.
[weixin-codex] Connecting to Codex App Server at ws://127.0.0.1:4500...
[codex-bridge] Connected to Codex App Server: ws://127.0.0.1:4500
[weixin-codex] Thread resumed: ...       ← 有历史会话时
# 或
[weixin-codex] Thread created: ...       ← 首次启动时
[weixin-codex] App Server ready.          ← 或 "App Server ready (timeout)."
[weixin-codex] Starting WeChat poll loop...
[weixin] Starting message poll loop...    ← ✅ 出现这行表示完全就绪
```

运行期间，bridge 会输出 Codex 调用的命令和工具，便于排查：

```text
[weixin-codex] tool: shell started: rtk pwd
[weixin-codex] tool: mcp started: functions.exec_command
[weixin-codex] tool: shell completed status=completed exit=0: rtk pwd
```

如果不想显示工具日志，可以这样启动：

```bash
WEIXIN_CODEX_LOG_TOOLS=0 ~/cc-weixin/plugins/weixin/start-codex.sh
```

bridge 创建 Codex thread 时会注入 RTK 规则，要求 shell 命令使用 `rtk <original command>`。如果仍看到 `PreToolUse hook` 报错，通常是模型先尝试了未加 `rtk` 的命令，随后会按规则重试。

**等待这两行同时出现后，再从微信发消息：**

```
[weixin-codex] Starting WeChat poll loop...
[weixin] Starting message poll loop...
```

这两行表示桥接和轮询均已建立，此后发来的微信消息才会被 AI 处理并回复。

### 第六步：配对微信用户

首次从微信发消息后，会收到一个 6 位配对码。打开 Codex TUI，运行：

```
$weixin-access pair 123456
```

### 第七步（推荐）：锁定白名单

```
$weixin-access policy allowlist
```

配对完所有授权用户后执行，阻止新用户获取配对码。详见 [ACCESS.md](../plugins/weixin/ACCESS.md)。

## 日常使用

桥接服务启动后，日常只需：

1. 运行 `~/cc-weixin/plugins/weixin/start-codex.sh`
2. 从微信发消息，AI 自动处理并回复
3. 停止时运行 `~/cc-weixin/plugins/weixin/stop-codex.sh`

默认 WebSocket desktop 模式下，可以在 Codex 桌面端查看微信会话；如果使用 `WEIXIN_CODEX_MODE=stdio`，则只通过 bridge 日志观察。

### 恢复旧桌面会话

bridge 会把微信用户和 Codex thread 的绑定保存到：

```text
~/.claude/channels/weixin/codex-threads.json
```

后续重启 `start-codex.sh` 时，会优先 `thread/resume` 旧会话，日志会显示：

```text
[weixin-codex] Thread resumed: 019e...
```

如果需要手动指定某个微信用户继续进入旧 Codex 会话，可以这样启动一次，bridge 会自动写入绑定文件：

```bash
WEIXIN_CODEX_THREAD_ID=019e... \
WEIXIN_CODEX_THREAD_CHAT_ID=o9cq80_lbVQ0zxiaRUlUgPNttaSY@im.wechat \
~/cc-weixin/plugins/weixin/start-codex.sh
```

也可以直接编辑 `codex-threads.json`：

```json
{
  "defaultThreadId": "019e4da2-7960-7281-b2e1-5c7e1463edc0",
  "chats": {
    "o9cq80_lbVQ0zxiaRUlUgPNttaSY@im.wechat": "019e4da2-7960-7281-b2e1-5c7e1463edc0"
  }
}
```

### 后台运行

如果不想占用当前终端，可以用 `nohup` 后台启动：

```bash
nohup ~/cc-weixin/plugins/weixin/start-codex.sh > /private/tmp/weixin-codex-bridge.log 2>&1 &
```

查看日志：

```bash
tail -f /private/tmp/weixin-codex-bridge.log
```

停止后台服务：

```bash
~/cc-weixin/plugins/weixin/stop-codex.sh
```

### 常见问题

#### `Executable not found in $PATH: "codex"`

说明当前终端找不到 `codex` 命令。新版 `start-codex.sh` 已自动回退到 Codex App 内置可执行文件：

```text
/Applications/Codex.app/Contents/Resources/codex
```

如果你的 Codex 安装在其他位置，可以显式指定：

```bash
CODEX_BIN=/path/to/codex ~/cc-weixin/plugins/weixin/start-codex.sh
```

#### 看到 remote plugin 或 skill YAML 警告

启动时可能看到 remote plugin 同步失败、某些 skill YAML 解析失败等日志。只要后续出现以下两行，微信桥接仍然可用：

```text
[weixin-codex] Starting WeChat poll loop...
[weixin] Starting message poll loop...
```

## 卸载

停止桥接服务：

```bash
~/cc-weixin/plugins/weixin/stop-codex.sh
```

然后在 Codex TUI 中：

```
/plugins  # 找到 weixin，卸载
```

清理凭证：

```bash
rm -rf ~/.claude/channels/weixin/
```

删除 `~/.agents/plugins/marketplace.json` 中对应的插件条目。
