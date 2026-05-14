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

    if [ -f references/ui-checklist-template.md ]; then
      cp references/ui-checklist-template.md docs/qa/UI-Review-$DATE.md
      echo "   ✅ 已生成 UI 走查模板: docs/qa/UI-Review-$DATE.md"
      echo "   💡 请填写走查结果和签字确认"
    else
      echo "   ⚠️  未找到模板文件"
    fi
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
