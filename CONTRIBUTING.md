# 贡献指南

感谢你对 cc-weixin 的关注！欢迎提交 Issue 和 Pull Request。

## 开发环境

1. 安装 [Bun](https://bun.sh)
2. 克隆仓库并安装依赖：

```bash
git clone https://github.com/joekytc/cc-weixin.git
cd cc-weixin/plugins/weixin
bun install
```

3. 运行类型检查：

```bash
bun run typecheck
```

4. 运行测试：

```bash
bun test
```

## 提交规范

提交消息遵循 [Conventional Commits](https://www.conventionalcommits.org/)：

- `feat:` 新功能
- `fix:` 修复 Bug
- `docs:` 文档变更
- `refactor:` 代码重构
- `test:` 添加或修改测试
- `chore:` 构建/工具变更

示例：`feat: support group chat messages`

## Pull Request 流程

1. Fork 仓库并创建功能分支
2. 编写代码和测试
3. 确保类型检查和测试通过
4. 提交 PR 并描述变更内容

## 项目结构

```
plugins/weixin/
├── server.ts          # MCP Server 入口（平台适配层）
├── src/
│   ├── types.ts       # iLink Bot API 类型定义
│   ├── api.ts         # HTTP API 封装
│   ├── accounts.ts    # 凭证存储
│   ├── login.ts       # QR 登录流程
│   ├── monitor.ts     # 长轮询消息接收
│   ├── send.ts        # 消息发送
│   ├── media.ts       # CDN 媒体上传/下载/加密
│   ├── pairing.ts     # 配对码访问控制
│   └── cli-login.ts   # 独立登录脚本
├── skills/            # Claude Code Skills
└── docs/              # 设计文档和 API 参考
```

## 报告问题

提交 Issue 时请包含：

- 问题描述和复现步骤
- 运行环境（OS、Bun 版本、Claude Code 版本）
- 相关日志输出
