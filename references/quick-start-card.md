# Rust 软件开发流水线 - Quick Start 卡片
> **A4 打印版 | 90% 常用场景覆盖**

---

## 🚀 5 分钟快速上手

### 第一步：启动流水线
```bash
# 1. 确认功能范围
# 问：你想做哪个功能模块？
# 例：策略管理 / 实盘交易 / K线数据 / 组合风控

# 2. 创建完整流水线（9个任务
hermes kanban create "T1: 需求分析 - [功能名]" --assignee pm

# 3. 查看流水线自动触发后续任务
```

---

## 📋 9 个阶段速查表

| 阶段 | 角色 | 完成条件 | 检查命令 |
|------|------|---------|---------|
| **T1** | PM | PRD + Gherkin | `ls docs/prd/*.md` |
| **T2** | TechLead | ADR + B1-B4 契约 | `ls docs/architecture/*.md` |
| **T3** | Designer | 原型 + UI 清单 | `ls docs/design/*.html` |
| **T4** | Frontend | `npm run build` ✅ | `cd frontend && npm run type-check` |
| **T5** | Backend | `cargo test` ✅ | `cd backend && cargo clippy` |
| **T4.5** | 双方 | 联调报告 | `curl localhost:8080/health` |
| **T5.5** | Designer | UI 走查 P0=0 | `check-ui` 脚本 |
| **T6** | QA | P0=0, P1≤3 | `quality-dashboard` |
| **T7/T8** | Writer/DevOps | 文档 + Docker | `docker compose up -d` |
| **T9** | TechLead | 评审通过 | `hermes kanban complete <t9_id>` |

---

## 🔴 质量门禁（必过）

### 后端必过检查（T5 complete 前执行：
```bash
cargo check                    # 编译 0 错误
cargo clippy -- -D warnings   # 0 警告
cargo test                     # 全通过
cargo tarpaulin               # 覆盖率 ≥70%
```

### 前端必过检查（T4 complete 前执行）：
```bash
npm run type-check          # TS 0 错误
npm run build                # 构建通过
vitest run --coverage      # 覆盖率 ≥60%
```

### QA 必过检查（进入 T7/T8 前）：
- P0 Bug = 0
- P1 Bug ≤ 3

---

## ⚠️ 常见错误速查

### E7 Protocol Violation（最常见）
```bash
# 检查 workspace 产出是否为空？
# → 有 → kanban complete
# 否 → 检查项目代码是否已有？
#   → 是 → kanban unblock → kanban complete
#   → 否 → kanban unblock（重新入队）
```

### 硬编码 Task ID？
```bash
# 正确解析 ID
hermes kanban create "测试" | grep "^Created t_" | awk '{print $2}'
```

### 前端构建失败？
```bash
# 先检查类型错误
cd frontend && npx vue-tsc -b --noEmit
# 修复所有 TS 错误后再 build
```

### 后端 EntityTrait 导入错误？
```bash
# SeaORM 常见陷阱：
# use entity::strategy::Entity 而非 use entity::strategy::*
# 检查：use entity 中的 DeriveActiveEnum 不要加 Serialize
```

---

## 🎯 质量仪表盘一键检查
```bash
# 一键执行所有质量检查
./quality-dashboard.sh /path/to/project
```

---

## 📞 需要帮助？

1. 先查：`references/e7-recovery-playbook.md`
2. 再查：`references/pipeline-health-check.md`
3. 最后：通知用户决策

---

> 💡 **记忆口诀**
> T1-T2-T3 设计先行
> T4-T5 并行开发
> T4.5 联调
> T5.5 走查
> T6 测试
> T7-T8 并行
> T9 评审
