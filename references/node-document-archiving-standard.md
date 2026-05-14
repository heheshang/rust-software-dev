# 📦 节点文档归档标准 v1.0

> **核心原则**：每个节点完成时，必须产出可追溯的文档。一年后有人问「当时为什么这么决策」，可以快速找到答案。

---

## 🗂️ 统一的文档目录结构

```
docs/
├── prd/                      # T0-T1 需求文档
│   ├── T0-Checklist-YYYYMMDD.md      # T0 门禁检查结果
│   ├── PRD-XXX-YYYYMMDD.md           # PRD 需求文档
│   └── Gherkin-XXX-YYYYMMDD.md       # Gherkin 场景
│
├── architecture/             # T2-T3 架构文档
│   ├── ADR-001-XXX.md                # 架构决策记录
│   ├── OpenAPI-3.0-spec.yaml         # API 契约
│   ├── ER-Diagram.png                # 数据库 ER 图
│   ├── TechDesign-Backend.md         # 后端技术设计
│   ├── TechDesign-Frontend.md        # 前端技术设计
│   └── Architecture-Report-YYYYMMDD.md # 架构健康报告
│
├── rfc/                      # RFC 文档
│   ├── draft/                        # 草稿状态
│   ├── accepted/                     # 已接受
│   ├── implemented/                  # 已实施
│   └── archived/                     # 已归档
│
├── api/                      # T4.5 契约文档
│   ├── OpenAPI-3.0-spec.yaml         # API 规范
│   ├── Contract-Validation-Report-YYYYMMDD.md # 契约验证报告
│   └── change-impact/                # 契约变更影响分析
│
├── qa/                       # T5.5-T6 测试文档
│   ├── UI-Review-YYYYMMDD.md         # UI 走查报告
│   ├── Test-Case-XXX.md              # 测试用例
│   ├── Bug-Report-YYYYMMDD.md        # Bug 报告
│   └── Security-Scan-Report-YYYYMMDD.md # 安全扫描报告
│
├── operations/               # T8 运维文档
│   ├── Deployment-Guide.md           # 部署指南
│   ├── Healthcheck-Report-YYYYMMDD.md # 健康检查报告
│   └── Rollback-Playbook.md          # 回滚手册
│
└── t9/                       # T9 最终评审文档
    ├── Final-Review-Checklist.md     # 最终评审清单
    ├── Sign-Off-Record.md            # 签字确认记录
    └── Release-Note-YYYYMMDD.md      # 发布说明
```

---

## 📋 T0-T9 每个节点的归档标准

| 节点 | 归档时机 | 必须归档的文档 | 命名规范 | 归档位置 | 验证人 |
|------|---------|---------------|---------|---------|--------|
| **T0 需求门禁** | T0 检查通过后 1 小时内 | 1. T0 检查评分结果<br>2. 需求澄清记录<br>3. 风险点记录 | `T0-Checklist-YYYYMMDD.md` | `docs/prd/` | PM |
| **T1 PRD 输出** | PRD 评审通过后立即 | 1. 正式 PRD 文档<br>2. Gherkin 场景文件<br>3. 评审会议记录 | `PRD-{FeatureName}-YYYYMMDD.md` | `docs/prd/` | TechLead |
| **T2 架构设计** | 架构评审签字后立即 | 1. ADR 架构决策记录<br>2. OpenAPI Spec<br>3. ER 图 / 数据模型<br>4. RFC（如有） | `ADR-{序号}-{主题}.md`<br>`OpenAPI-3.0-spec.yaml` | `docs/architecture/`<br>`docs/rfc/` | TechLead |
| **T3 技术设计** | 前后端 TechDesign 评审通过 | 1. 后端 TechDesign<br>2. 前端 TechDesign<br>3. 评审意见记录 | `TechDesign-Backend.md`<br>`TechDesign-Frontend.md` | `docs/architecture/` | 前后端 TechLead |
| **T4 并行开发** | 开发完成自测通过后 | 1. 开发日志/变更记录<br>2. 自测报告<br>3. 数据库 Migration SQL | `Dev-Log-{FeatureName}.md`<br>`Migration-YYYYMMDD.sql` | `docs/architecture/`<br>`backend/migration/` | 开发负责人 |
| **T4.5 契约校验** | 契约检查通过后 | 1. 契约验证报告<br>2. 前后端对齐会议记录<br>3. 变更影响分析（如有） | `Contract-Validation-Report-YYYYMMDD.md` | `docs/api/` | 前后端联调负责人 |
| **T5 后端完成** | 后端测试全部通过后 | 1. 测试报告（单元/集成）<br>2. Migration 安全检查报告<br>3. 性能测试结果（如有） | `Backend-Test-Report-YYYYMMDD.md`<br>`Migration-Safety-Report-YYYYMMDD.md` | `docs/qa/` | 后端 TechLead |
| **T5.5 UI 走查** | 走查通过签字后 | 1. UI 走查清单（带标记）<br>2. 问题截图（如有）<br>3. 签字确认页 | `UI-Review-YYYYMMDD.md` | `docs/qa/` | 产品 / UI 设计师 |
| **T6 QA 测试** | QA 测试通过后 | 1. 完整测试报告<br>2. Bug 清单及状态<br>3. 安全扫描报告<br>4. 性能测试报告 | `QA-Test-Report-YYYYMMDD.md`<br>`Security-Scan-Report-YYYYMMDD.md` | `docs/qa/` | QA Lead |
| **T7 文档** | 文档质量检查通过后 | 1. 所有必选文档（README/API文档/部署指南等）<br>2. 文档质量检查报告<br>3. 文档索引 | `Document-Quality-Report-YYYYMMDD.md` | `docs/` | 文档负责人 |
| **T8 部署运维** | Staging 部署验证通过后 | 1. 部署日志<br>2. 健康检查报告<br>3. 配置文件（脱敏后）<br>4. 回滚手册 | `Deployment-Log-YYYYMMDD.md`<br>`Healthcheck-Report-YYYYMMDD.md` | `docs/operations/` | DevOps / 运维负责人 |
| **T9 最终评审** | 三方签字确认后 | 1. 最终评审清单<br>2. 架构健康报告<br>3. 签字确认记录<br>4. 发布说明<br>5. 完整交付物清单 | `Final-Review-Checklist-YYYYMMDD.md`<br>`Sign-Off-Record-YYYYMMDD.md`<br>`Release-Note-YYYYMMDD.md` | `docs/t9/` | 技术负责人 |

---

## 🔧 自动化归档脚本

### `scripts/archive-node-docs.sh` - 节点文档自动归档工具

```bash
#!/bin/bash
# ==============================================================================
# 节点文档自动归档工具 v1.0
# 用途：每个节点完成后，自动归档对应文档到正确位置
# 用法：./scripts/archive-node-docs.sh <节点名称> [功能名称]
# 示例：./scripts/archive-node-docs.sh T0 user-auth
# ==============================================================================

set -e

NODE_NAME=$1
FEATURE_NAME=$2
DATE=$(date +%Y%m%d)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║               📦 节点文档自动归档工具 v1.0                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📅 归档时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "🎯 节点名称: $NODE_NAME"
echo "📦 功能名称: $FEATURE_NAME"
echo ""

# 确保目录存在
mkdir -p docs/prd
mkdir -p docs/architecture
mkdir -p docs/rfc/draft
mkdir -p docs/rfc/accepted
mkdir -p docs/rfc/implemented
mkdir -p docs/rfc/archived
mkdir -p docs/api
mkdir -p docs/qa
mkdir -p docs/operations
mkdir -p docs/t9

# ==============================================================================
# 根据节点执行归档逻辑
# ==============================================================================

case $NODE_NAME in
  "T0")
    echo "🔍 归档 T0 需求门禁文档..."
    echo ""

    # 生成 T0 检查结果记录
    cat > docs/prd/T0-Checklist-$DATE.md << EOF
---
node: T0
feature: $FEATURE_NAME
date: $DATE
status: completed
---

# T0 需求门禁检查结果

**检查时间**: $(date '+%Y-%m-%d %H:%M:%S')
**功能名称**: $FEATURE_NAME
**检查人**: [填写检查人姓名]

## 评分明细

| 检查项 | 分值 | 得分 | 状态 |
|--------|------|------|------|
| 功能范围明确 | 25 | [填写] | ✅/❌ |
| 用户角色明确 | 20 | [填写] | ✅/❌ |
| 边界清晰 | 15 | [填写] | ✅/⚠️ |
| 数据来源明确 | 15 | [填写] | ✅/⚠️ |
| 非功能需求 | 10 | [填写] | ✅/⚠️ |
| 依赖关系 | 10 | [填写] | ✅/⚠️ |
| 验收标准 | 5 | [填写] | ✅/⚠️ |

## 总得分: X / 100

## 结论
☐ ✅ 优秀 (≥90)
☐ ✅ 通过 (70-89)
☐ ⚠️ 有风险 (50-69)
☐ ❌ 不通过 (<50)

## 风险点记录

[记录本次检查发现的风险点]

## 需求澄清记录

[记录本次检查中的需求澄清内容]

---

**检查人签字**: _______________
EOF

    echo "   ✅ 已生成: docs/prd/T0-Checklist-$DATE.md"
    ;;

  "T2")
    echo "🏗️  归档 T2 架构设计文档..."
    echo ""

    # 备份当前 OpenAPI Spec
    if [ -f docs/api/OpenAPI-3.0-spec.yaml ]; then
      cp docs/api/OpenAPI-3.0-spec.yaml docs/api/OpenAPI-3.0-spec-$DATE.yaml
      echo "   ✅ 已备份 API Spec: docs/api/OpenAPI-3.0-spec-$DATE.yaml"
    fi

    # 生成架构快照
    cat > docs/architecture/Architecture-Snapshot-$DATE.md << EOF
---
node: T2
feature: $FEATURE_NAME
date: $DATE
---

# T2 架构设计快照

**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')
**功能名称**: $FEATURE_NAME
**架构师**: [姓名]

## 关键决策记录

[记录本次架构设计的关键决策点]

## ADR 清单

- [ ] ADR-001: [决策1]
- [ ] ADR-002: [决策2]

## API 端点清单

本次设计新增/修改的端点：
- [ ] GET /api/v1/xxx
- [ ] POST /api/v1/xxx

## 数据库变更

本次设计涉及的表变更：
- [ ] 新增表: xxx
- [ ] 修改表: xxx
- [ ] 无变更

---

**TechLead 签字**: _______________
EOF

    echo "   ✅ 已生成架构快照: docs/architecture/Architecture-Snapshot-$DATE.md"
    ;;

  "T4.5")
    echo "🤝 归档 T4.5 契约校验文档..."
    echo ""

    # 运行契约检查并保存报告
    ./scripts/contract-validation.sh | tee docs/api/Contract-Validation-Report-$DATE.md

    echo "   ✅ 契约验证报告已保存"
    ;;

  "T5.5")
    echo "🎨 归档 T5.5 UI 走查文档..."
    echo ""

    cp references/ui-checklist-template.md docs/qa/UI-Review-$DATE.md
    echo "   ✅ 已生成 UI 走查模板: docs/qa/UI-Review-$DATE.md"
    echo "   💡 请填写走查结果和签字确认"
    ;;

  "T6")
    echo "🔒 归档 T6 QA 测试 & 安全扫描文档..."
    echo ""

    # 运行安全扫描并保存报告
    ./scripts/security-scan.sh | tee docs/qa/Security-Scan-Report-$DATE.md

    echo "   ✅ 安全扫描报告已保存"
    ;;

  "T9")
    echo "🎉 归档 T9 最终评审文档..."
    echo ""

    # 运行架构健康检查
    ./scripts/architecture-health-check.sh

    # 生成最终交付物清单
    cat > docs/t9/Final-Delivery-List-$DATE.md << EOF
---
node: T9
feature: $FEATURE_NAME
date: $DATE
---

# T9 最终交付物清单

**功能名称**: $FEATURE_NAME
**发布日期**: $DATE

## 交付物清单

### 代码类
- [ ] 后端代码已合并到 main
- [ ] 前端代码已合并到 main
- [ ] 数据库 Migration 已合并

### 文档类
- [ ] PRD 需求文档
- [ ] ADR 架构决策记录
- [ ] OpenAPI Spec
- [ ] 技术设计文档
- [ ] 部署指南
- [ ] 用户手册（如有）

### 测试类
- [ ] 单元测试报告
- [ ] 集成测试报告
- [ ] QA 测试报告
- [ ] 安全扫描报告

### 签署类
- [ ] TechLead 签字确认
- [ ] 产品经理签字确认
- [ ] QA Lead 签字确认

## 架构健康评分: X / 100

## 发布风险评估: 低 / 中 / 高

---

**技术负责人签字**: _______________
**产品负责人签字**: _______________
**QA 负责人签字**: _______________
EOF

    echo "   ✅ 交付物清单已生成: docs/t9/Final-Delivery-List-$DATE.md"
    ;;

  *)
    echo "⚠️  未定义归档逻辑的节点: $NODE_NAME"
    echo "   请手动归档文档，或更新归档脚本"
    ;;
esac

echo ""
echo "✅ 归档完成！"
echo ""
echo "📦 归档统计:"
echo "   节点: $NODE_NAME"
echo "   时间戳: $TIMESTAMP"
echo "   归档位置: docs/ 对应子目录"
echo ""
echo "💡 下一步:"
echo "   1. 检查生成的归档文件是否完整"
echo "   2. 补充签字确认信息"
echo "   3. git commit 提交归档文档"
echo ""
```

---

## ✅ 归档完整性检查清单

每个节点归档后，验证人必须确认以下三点：

| 验证项 | 要求 | 检查方法 |
|--------|------|---------|
| **完整性** | 该节点的所有必选文档都已归档 | 对照上表逐项打勾 |
| **可读性** | 文档内容清晰，第三方能看懂 | 随机找一个人，看能不能理解 |
| **可追溯** | 有日期、有签字、有版本 | 检查文档头的 meta 信息 |

### 归档质量评分标准

| 得分 | 等级 | 说明 |
|------|------|------|
| 100 | ✅ 完美 | 所有文档齐全，格式标准，有签字 |
| 80-99 | 🟡 良好 | 有 1-2 个非关键文档缺失 |
| 60-79 | 🟠 及格 | 有关键文档但不够详细 |
| <60 | 🔴 不合格 | 关键文档缺失，必须补充 |

---

## 🔍 归档检索指南

一年后，有人问「XXX 功能当时为什么这么设计？」，按以下步骤检索：

```bash
# Step 1：按功能名称搜索
find docs -name "*XXX*" | grep -i "feature-name"

# Step 2：查看 T2 架构快照
cat docs/architecture/Architecture-Snapshot-YYYYMMDD.md

# Step 3：查看 ADR 决策记录
cat docs/architecture/ADR-XXX.md

# Step 4：查看 T9 最终评审记录
cat docs/t9/Final-Review-Checklist-YYYYMMDD.md

# Step 5：查看 RFC（如有重大决策）
cat docs/rfc/archived/RFC-XXX.md
```

---

## 💡 归档最佳实践

### 1. **实时归档，不要攒着**
- ✅ 节点完成后 1 小时内完成归档
- ❌ 不要等到 T9 才回头补 T0 的文档（99% 会遗漏关键信息）

### 2. **命名要规范，方便搜索**
- ✅ `T0-Checklist-20240515.md`
- ❌ `新建文本文档.md` / `checklist.md` / `最终版-最终版.md`

### 3. **不仅要存结果，还要存过程**
- ✅ 不仅存最终 PRD，还要存评审记录和争议点
- ✅ 不仅存最终架构，还要存备选方案和为什么不选的理由

### 4. **定期清理和索引更新**
```bash
# 每月更新一次文档索引
./scripts/generate-doc-index.sh

# 每季度归档一次老版本的文档
# 移动到 docs/_archive/YYYYQN/ 目录
```

---

## 🎯 归档的价值

很多团队不重视文档归档，觉得「浪费时间」。但实际上：

| 场景 | 没有归档的成本 | 有归档的成本 |
|------|--------------|------------|
| 新人接手 | 3 天到处问人 | 1 小时看文档 |
| 线上故障排查 | 2 小时回忆当时为什么这么做 | 10 分钟查归档 |
| 功能重构 | 5 天重新梳理逻辑 | 1 天看历史决策 |
| 审计/合规 | 到处找证据，可能不过 | 一键导出所有文档 |

**归档 10 分钟，未来省 10 小时。**

---

> **归档的本质**：把团队的「集体记忆」固化下来。人会走、会忘，但文档永远在那里。
