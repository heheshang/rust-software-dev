# 🏗️ Rust 全栈软件开发流水线

> 企业级软件质量保障体系 - 从架构设计到上线发布的完整质量门禁

---

## 📋 项目简介

本项目提供一套完整的 Rust + Vue 全栈软件开发质量保障流水线，覆盖从 T2 架构设计到 T9 最终评审的全流程自动化检查工具，确保软件架构健康、代码安全、文档规范。

---

## ✨ 核心特性

### 🏗️ 架构健康保障
- **5维度后端架构检查** - 依赖方向、循环依赖、模块边界、复杂度、技术债务
- **5维度前端架构检查** - 循环import、any类型泛滥、props透传、架构分层、Store边界
- **自动化健康评分** - 0-100分评级系统，S/A/B/C/D五档评分

### 🔒 全栈安全扫描
- Rust 依赖漏洞审计 (cargo audit)
- NPM 依赖漏洞审计 (npm audit)
- 硬编码密钥/密码扫描
- SQL注入风险检测
- CORS 配置安全检查

### 🗄️ 数据库迁移安全
- DROP TABLE/COLUMN 危险操作预警
- ALTER TABLE 锁表风险分析
- down() 回滚函数完整性检查
- CREATE INDEX 最佳实践验证

### 📜 RFC 架构决策管理
- 标准化 RFC 文档脚手架
- 状态看板与工作流管理
- 自动归档与版本追踪
- 6阶段状态流转（Draft → Discuss → Final Call → Accept → Implemented → Archived）

### 🤝 API 契约测试
- OpenAPI 3.0 规范一致性校验
- 前后端类型同步检查
- 契约变更影响范围分析
- Pact 消费者驱动契约测试集成

### 📚 文档治理体系
- 文档质量自动化门禁
- 文档索引自动生成
- 元数据完整性检查
- TODO 占位符扫描

---

## 🚀 快速开始

### 1. 一键运行所有检查
```bash
# T9 最终评审完整检查
./scripts/architecture-health-check.sh
./scripts/frontend-architecture-check.sh
./scripts/security-scan.sh
./scripts/migration-safety-check.sh
./scripts/document-quality-check.sh
```

### 2. 创建第一个 RFC
```bash
./scripts/rfc-create.sh
# 按提示输入 RFC 标题、作者、领域
```

### 3. API 契约检查
```bash
./scripts/contract-validation.sh
```

---

## 📁 项目结构

```
rust-software-dev/
├── README.md                          # 本文件 - 项目总览
├── SKILL.md                           # 完整技能图谱与流程说明
│
├── scripts/                           # 11个可执行脚本（质量门禁）
│   ├── README.md                      # 脚本使用手册
│   ├── architecture-health-check.sh   # 后端架构健康检查
│   ├── frontend-architecture-check.sh # 前端架构健康检查
│   ├── security-scan.sh               # 全栈安全扫描
│   ├── migration-safety-check.sh      # 数据库迁移安全
│   ├── rfc-create.sh                  # RFC 创建脚手架
│   ├── rfc-status.sh                  # RFC 状态看板
│   ├── rfc-archive.sh                 # RFC 归档工具
│   ├── contract-validation.sh         # API 契约一致性检查
│   ├── contract-change-impact.sh      # 契约变更影响分析
│   ├── document-quality-check.sh      # 文档质量门禁
│   └── generate-doc-index.sh          # 文档索引自动生成
│
└── references/                        # 13个参考文档模板
    ├── rfc-framework.md               # RFC 流程完整规范
    ├── api-contract-testing.md        # API 契约测试最佳实践
    ├── document-governance.md         # 文档治理规范
    ├── pipeline-health-check.md       # 流水线健康检查指南
    ├── e7-recovery-playbook.md        # P0 事故恢复手册
    ├── frontend-ts-pitfalls.md        # TypeScript 常见陷阱
    ├── qa-bug-report-template.md      # QA 缺陷报告模板
    └── ... 更多参考文档
```

---

## 📊 开发阶段流水线（T0 - T9）

| 阶段 | 核心活动 | 必执行脚本 | 门禁要求 |
|------|---------|-----------|---------|
| **T2** | 架构设计 | `rfc-create.sh` `architecture-health-check.sh` `contract-change-impact.sh` | RFC 评审通过 |
| **T4** | 前端开发 | `frontend-architecture-check.sh` | 前端架构评分 ≥70 |
| **T4.5** | 前后端联调 | `contract-validation.sh` | API 契约一致 |
| **T5** | 后端完成 | `migration-safety-check.sh` | 无 P0 级迁移风险 |
| **T6** | QA 测试 | `security-scan.sh` | 无 Critical/High 漏洞 |
| **T7** | 文档完成 | `document-quality-check.sh` `generate-doc-index.sh` | 文档完整性 ≥90% |
| **T8** | 预发布 | `migration-safety-check.sh` `security-scan.sh` | 生产环境验证 |
| **T9** | 最终评审 | 全部脚本 | 架构评分 ≥80，无 P0 问题 |

---

## 📈 架构健康评分标准

| 评分 | 等级 | 状态 | 建议 |
|------|------|------|------|
| 90-100 | S | ✅ 非常健康 | 保持现状 |
| 80-89 | A | ✅ 健康 | 持续监控 |
| 70-79 | B | 🟡 存在风险 | 安排 10% 时间还债 |
| 60-69 | C | 🟡 腐化迹象 | 安排 20% 时间还债 |
| <60 | D | 🔴 严重腐化 | 立即启动重构 |

### 扣分规则
- **P0 级问题** - 每项扣 20 分（如：架构分层违规、any类型泛滥）
- **P1 级问题** - 每项扣 5 分（如：循环依赖、组件过大）
- **P2 级问题** - 每项扣 1 分（如：模块暴露过宽）

---

## 🛠️ 脚本使用手册

### 架构类

```bash
# 后端架构健康检查
./scripts/architecture-health-check.sh [project_root]
# 输出：5维度检查报告 + 健康评分 + Markdown报告

# 前端架构健康检查
./scripts/frontend-architecture-check.sh [frontend_dir]
# 输出：5维度检查报告 + 健康评分 + Markdown报告
```

### 安全类

```bash
# 全栈安全扫描
./scripts/security-scan.sh [project_root]
# 输出：5维度安全报告 + 风险分级 + 修复建议清单
```

### 数据库类

```bash
# Migration 安全检查
./scripts/migration-safety-check.sh [project_root]
# 输出：危险操作预警 + 锁表风险分析 + 回滚完整性检查
```

### RFC 管理类

```bash
# 创建 RFC
./scripts/rfc-create.sh
# 输出：标准化 RFC 文档模板

# 查看 RFC 状态
./scripts/rfc-status.sh
# 输出：状态看板 + 统计数据 + 待处理事项

# 归档已完成 RFC
./scripts/rfc-archive.sh
# 输出：归档记录 + 状态更新
```

### API 契约类

```bash
# 契约一致性检查
./scripts/contract-validation.sh [project_root]
# 输出：Spec存在性 + 类型生成检查 + 路由一致性

# 契约变更影响分析
./scripts/contract-change-impact.sh [project_root]
# 输出：变更端点列表 + 影响范围估算 + 前后端文件清单
```

### 文档类

```bash
# 文档质量检查
./scripts/document-quality-check.sh [project_root]
# 输出：必选文档检查 + 元数据完整性 + 格式规范检查

# 生成文档索引
./scripts/generate-doc-index.sh [project_root]
# 输出：docs/README.md 索引文件
```

---

## 📚 参考文档

| 文档 | 说明 |
|------|------|
| [SKILL.md](SKILL.md) | 完整技能图谱、流程说明、检查清单 |
| [scripts/README.md](scripts/README.md) | 脚本详细使用说明 |
| [references/rfc-framework.md](references/rfc-framework.md) | RFC 流程完整规范文档 |
| [references/api-contract-testing.md](references/api-contract-testing.md) | API 契约测试最佳实践 |
| [references/e7-recovery-playbook.md](references/e7-recovery-playbook.md) | P0 级事故恢复操作手册 |

---

## 🎯 快速开始卡片

### 新成员入职 checklist
- [ ] 阅读 [SKILL.md](SKILL.md) 了解完整流程
- [ ] 浏览 `scripts/` 目录熟悉可用工具
- [ ] 运行 `./scripts/architecture-health-check.sh` 了解项目架构状态
- [ ] 查看 `references/rfc-framework.md` 学习 RFC 流程

### 新项目启动 checklist
- [ ] 复制本项目脚本到新项目
- [ ] 配置 `docs/` 目录结构
- [ ] 创建第一个架构 RFC
- [ ] 初始化 OpenAPI 3.0 Spec

---

## 🤝 贡献指南

1. 新增脚本请放在 `scripts/` 目录
2. 更新 `scripts/README.md` 添加使用说明
3. 通用模板请放在 `references/` 目录
4. 重大流程变更请先创建 RFC 讨论

---

## 📝 更新日志

### v1.0 (2024-05-14)
- ✅ 完整的后端架构健康检查（5维度）
- ✅ 完整的前端架构健康检查（5维度）
- ✅ 全栈安全扫描工具（5维度）
- ✅ 数据库迁移安全扫描
- ✅ RFC 管理工具链（创建/状态/归档）
- ✅ API 契约一致性检查与影响分析
- ✅ 文档质量门禁与索引自动生成
- ✅ 11个生产级脚本 + 13个参考文档

---

## 📄 许可证

本项目仅供内部学习与使用。

---

> 💡 **提示**：本流水线设计目标是「将问题发现尽可能向左移」，在开发早期发现架构问题，避免技术债务累积。建议将关键脚本集成到 CI/CD 流水线，作为合并代码的强制门禁。
