# 脚本目录说明

本目录包含 Rust 全栈开发流水线的所有自动化脚本。

---

## 📋 脚本清单

| 脚本 | 用途 | 执行阶段 | 阻塞性 |
|------|------|---------|--------|
| `pipeline-orchestrator.sh` | 🧠 流水线编排引擎（全自动 T0-T9） | 入口 | 引擎 |
| `architecture-health-check.sh` | Rust后端架构腐化检测 | T2 / T9 | 🔴 可阻塞 |
| `frontend-architecture-check.sh` | Vue+TS前端架构腐化检测 | T4 / T9 | 🔴 可阻塞 |
| `migration-safety-check.sh` | Migration 安全扫描 | T5 / T8 | 🔴 可阻塞 |
| `security-scan.sh` | 全栈安全扫描 | T6 / T9 | 🔴 可阻塞 |
| `rfc-create.sh` | RFC 文档创建脚手架 | T2 | 工具 |
| `rfc-status.sh` | RFC 状态总览看板 | 任意时间 | 工具 |
| `rfc-archive.sh` | RFC 归档工具 | T9 后 | 工具 |
| `contract-validation.sh` | API 契约一致性检查 | T4.5 | 🟡 警告 |
| `contract-change-impact.sh` | 契约变更影响分析 | T2 / 任意 | 工具 |
| `generate-doc-index.sh` | 文档索引自动生成 | T7 / 任意 | 工具 |
| `document-quality-check.sh` | 文档质量门禁 | T7 | 🟡 警告 |
| `archive-node-docs.sh` | 节点文档自动归档 | 每个节点完成后 | 工具 |
| `t0-check.sh` | 需求门禁评分 | T0 | 🔴 可阻塞 |
| `t1-prd-check.sh` | PRD 完整性检查 | T1 | 🟡 警告 |
| `t3-techdesign-check.sh` | 技术设计完整性检查 | T3 | 🟡 警告 |
| `t4-dev-check.sh` | 开发完成自检 | T4 | 🔴 可阻塞 |
| `t5.5-ui-review-check.sh` | UI 走查确认 | T5.5 | 🔴 可阻塞 |
| `t6-qa-check.sh` | QA 测试通过确认 | T6 | 🔴 可阻塞 |
| `t8-deployment-check.sh` | 部署健康检查 | T8 | 🟡 警告 |
| `t9-final-review-check.sh` | 最终评审清单检查 | T9 | 🔴 可阻塞 |

---

## 🚀 快速开始

```bash
# 给所有脚本添加执行权限
chmod +x scripts/*.sh

# ✨ 推荐：全自动启动流水线
./scripts/pipeline-orchestrator.sh <功能名称> [起始节点]
./scripts/pipeline-orchestrator.sh user-auth T0

# 1. 跑完整质量检查（CI 常用）
./scripts/quality-dashboard.sh .

# 2. 提交代码前检查（pre-commit）
./scripts/security-scan.sh .
./scripts/architecture-health-check.sh .

# 3. 创建新 RFC
./scripts/rfc-create.sh
```

---

## 🔄 执行顺序建议

### 新功能开发流程

```
T0 阶段
  ↓
./scripts/rfc-create.sh      # 如需重大架构变更
  ↓
T2 阶段
  ↓
./scripts/contract-change-impact.sh    # 分析契约变更影响
  ↓
T4.5 联调阶段
  ↓
./scripts/contract-validation.sh       # 检查契约一致性
  ↓
T5 后端完成
  ↓
./scripts/migration-safety-check.sh    # 检查数据库变更安全性
  ↓
T6 QA 阶段
  ↓
./scripts/security-scan.sh             # 全栈安全扫描
./scripts/architecture-health-check.sh # 架构健康检查
  ↓
T7 文档阶段
  ↓
./scripts/document-quality-check.sh     # 文档质量检查
./scripts/generate-doc-index.sh         # 更新文档索引
  ↓
T9 最终评审
  ↓
./scripts/rfc-status.sh                 # 查看 RFC 状态
./scripts/rfc-archive.sh                # 归档已完成 RFC
```

---

## 📊 各脚本详细说明

### 架构类脚本

#### architecture-health-check.sh

**5 大架构检测维度：**
1. 依赖方向检查（禁止反向依赖）
2. 循环依赖检测（DFS 算法）
3. 模块边界完整性检查
4. 代码复杂度分析
5. 技术债务统计（FIXME/TODO/HACK）

**输出：**
- 问题分级汇总表
- 详细问题列表
- 架构健康评分
- 自动生成 Markdown 报告

**使用场景：**
- T2 架构设计评审
- T9 最终评审
- 定期架构健康巡检

---

#### frontend-architecture-check.sh

**前端架构检测维度：**
1. 循环 import 检测
2. any 类型泛滥统计
3. Props 透传层级检查
4. 分层架构违规检测
5. Pinia Store 边界检查

**输出：**
- 前端架构健康评分
- 类型健康度指标
- 组件依赖关系报告

---

### 安全类脚本

#### security-scan.sh

**5 大安全检测维度：**
1. Rust 依赖漏洞（cargo audit）
2. NPM 依赖漏洞（npm audit）
3. 硬编码密钥/密码扫描
4. SQL 注入风险检测
5. CORS 配置安全检查

**输出：**
- 风险分级汇总（Critical/High/Medium/Low）
- 详细问题列表 + 修复建议
- 安全负责人签字确认栏

---

#### migration-safety-check.sh

**Migration 安全检测维度：**
1. DROP TABLE / DROP COLUMN 危险操作检测
2. ALTER COLUMN 锁表风险检测
3. 回滚函数检查（down() 函数是否存在）
4. CREATE INDEX CONCURRENTLY 最佳实践检查

**输出：**
- 危险操作预警
- 锁表风险评估
- 生产执行建议

---

### 契约测试类脚本

#### contract-validation.sh

**API 契约检测维度：**
1. OpenAPI spec 存在性检查
2. 前端类型文件生成检查
3. 后端路由与 spec 一致性对比
4. 错误码一致性检查

---

#### contract-change-impact.sh

**契约变更影响分析：**
1. 对比新旧 spec 差异
2. 列出新增/删除/修改的端点
3. 估算受影响的前后端文件范围
4. 给出测试范围建议

---

### RFC 管理类脚本

#### rfc-create.sh

**功能：**
- 自动分配 RFC 编号
- 使用标准模板生成文档
- 自动填充作者、创建日期等元信息

**使用方式：**
```bash
./scripts/rfc-create.sh
# 按提示输入：
#   1. RFC 标题
#   2. 作者姓名
```

---

#### rfc-status.sh

**功能：**
- 看板形式展示所有 RFC 状态
- 统计各状态数量
- 高亮显示讨论中的 RFC

**输出示例：**
```
📋 RFC 状态总览
═══════════════════════════════════════════════
RFC编号    标题                    状态              最后更新
───────────────────────────────────────────────
RFC-0001  SeaORM迁移方案         ✅ Accepted    2024-05-14
RFC-0002  缓存策略设计            💬 Discuss     2024-05-12
RFC-0003  API版本化方案           📝 Draft       2024-05-10

📊 统计:
  总计: 3 个 RFC
  📝 起草中: 1
  💬 讨论中: 1
  ✅ 已通过: 1
  🚀 已执行: 0
```

---

#### rfc-archive.sh

**功能：**
- 自动检测已执行完成的 RFC
- 检查是否有复盘记录
- 移动到归档目录
- 更新状态为 Archived

---

### 文档治理类脚本

#### document-quality-check.sh

**文档质量检查维度：**
1. 是否有完整的标题
2. 是否有版本/日期/作者信息
3. 是否有 TODO 占位符未填充
4. Markdown 格式规范检查

---

#### generate-doc-index.sh

**功能：**
- 扫描所有 md 文件
- 按阶段分类
- 生成 docs/README.md 总索引
- 列出最近更新文档

---

## 🔧 集成到 CI/CD

### GitHub Actions 示例

```yaml
# .github/workflows/quality-check.yml
name: Quality Checks

on: [pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: 安全扫描
        run: ./scripts/security-scan.sh .

  architecture:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: 架构健康检查
        run: ./scripts/architecture-health-check.sh .
```

### GitLab CI 示例

```yaml
# .gitlab-ci.yml
stages:
  - security
  - quality
  - deploy

security_scan:
  stage: security
  script:
    - ./scripts/security-scan.sh .
  allow_failure: false

architecture_check:
  stage: quality
  script:
    - ./scripts/architecture-health-check.sh .
  rules:
    - if: $CI_MERGE_REQUEST_LABELS =~ /architecture/
```

---

## 📝 最佳实践

1. **所有脚本在项目根目录执行**
   ```bash
   cd /path/to/project
   ./scripts/security-scan.sh .
   ```

2. **给脚本添加到 git**
   ```bash
   git add scripts/
   git commit -m "chore: 添加流水线脚本集"
   ```

3. **本地提交前运行**
   ```bash
   # 建议配置 pre-commit hook 运行关键检查
   ./scripts/security-scan.sh .
   ./scripts/architecture-health-check.sh .
   ```

4. **定期运行架构巡检**
   ```bash
   # 每月第一周周一执行全量检查
   ./scripts/quality-dashboard.sh .
   ./scripts/rfc-status.sh
   ```

---

## ⚠️ 注意事项

1. 所有脚本假设项目结构为：
   ```
   project-root/
   ├── backend/          # Rust 后端
   │   └── src/
   │   └── migration/
   ├── frontend/         # Vue 前端
   │   └── src/
   ├── docs/             # 文档目录
   │   ├── architecture/
   │   ├── rfc/
   │   └── qa/
   └── scripts/          # 本目录
   ```

2. 如项目结构不同，可修改脚本中的路径配置

3. 首次使用建议先在测试分支验证

4. 发现 bug 或有改进建议请更新脚本并同步到 SKILL 文档
