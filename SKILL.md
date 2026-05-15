---
name: rust-software-dev
description: "Rust + Vue 3 全栈开发流水线 - T0 到 T9 模块化编排"
version: 4.1.0
category: pipeline
modular: true

# 模块化加载入口
loader:
  type: directory
  path: "./skill/"

# 触发条件
triggers:
  - command: "启动流水线"
  - command: "rust pipeline"
  - pr_comment: "/start-pipeline"
  - kanban: "卡片移至「开发中」"
---

# 🚀 Rust 全栈开发流水线 v4.0

## 📌 重要说明

**本文件仅为入口指针**，完整的模块化定义在 `skill/` 目录下。

```
skill/
├── SKILL.md              # 主编排配置（73 行纯配置）
├── meta/                 # 全局常量、通知配置
├── nodes/                # 13 个节点 T0–T9（含 T4.6 Dev 部署 + QA 测试）
├── checks/               # 4 个质量检查配置
├── rollback/             # 回滚矩阵与处理逻辑
├── archive/              # 归档标准与自动化
└── README.md             # 架构设计说明
```

## 节点流水线（v4.1）

```
T0 → T1 → T2 → T3 → T4(并行开发) → T4.5(契约校验) → T4.6(Dev部署+QA测试) → T5 → T5.5 → T6 → T7 → T8 → T9
```

**T4.6 关键设计：QA 人工测试与 T6 自动化门禁并行执行，不串行等待。**

## 🚀 快速开始

```bash
# 启动流水线
./scripts/pipeline-orchestrator.sh <功能名称> [起始节点]

# 示例
./scripts/pipeline-orchestrator.sh user-auth T0
```

## 📚 文档指引

| 文档 | 位置 | 说明 |
|------|------|------|
| 模块化架构说明 | `skill/README.md` | 设计原则、目录结构、最佳实践 |
| 流水线脚本说明 | `scripts/README.md` | 11 个自动化脚本的使用说明 |
| 回滚机制设计 | `skill/rollback/matrix.yaml` | 每个节点的回滚规则 |
| 全自动执行指南 | `references/skill-full-auto-execution-guide.md` | 编排引擎设计 |

---

*本流水线采用正交模块化架构设计，v4.1 稳定版（T4.6 新增 Dev 部署 + QA 测试节点）*
