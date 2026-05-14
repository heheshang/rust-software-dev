# Rust 软件开发流水线 - 文档治理规范 v1.0

> 本文档定义了 T1~T9 各阶段各角色的文档产出标准、目录结构、归档规范、生命周期管理。

---

## 📂 统一文档目录结构

```
docs/
├── README.md                          # 文档总索引（自动生成）
│
├── requirements/                      # T1 PM 产出
│   ├── PRD-<feature>.md              # 产品需求文档
│   ├── Gherkin-<feature>.md          # 功能用例描述
│   └── T0-Checklist-<date>.md        # T0 需求准入检查报告
│
├── architecture/                      # T2 TechLead 产出
│   ├── ADR-<number>-<title>.md       # 架构决策记录
│   ├── B1-B4-Contract-<feature>.md   # API 契约设计
│   ├── Tech-Selection-<topic>.md      # 技术选型说明
│   ├── Architecture-Health-<date>.md  # 架构健康度报告
│   ├── Migration-Safety-<date>.md     # Migration 安全报告
│   └── Frontend-Architecture-<date>.md # 前端架构报告
│
├── design/                            # T3 Designer 产出
│   ├── Design-Spec-<feature>.md      # 设计规范说明
│   ├── Prototype-<feature>.html       # HTML 可交互原型
│   ├── UI-Checklist-<feature>.md      # UI 走查清单
│   └── T5.5-Walkthrough-<date>.md     # T5.5 UI 走查报告
│
├── api/                               # T7 TechWriter 产出
│   ├── OpenAPI-<version>.json/yaml    # OpenAPI 3.0 规范
│   ├── API-Documentation.md           # API 使用文档
│   └── Pact-Contracts/                # Pact 契约测试文件
│
├── qa/                                # T6 QA 产出
│   ├── Test-Plan-<version>.md         # 测试计划
│   ├── Test-Cases.md                  # 测试用例库
│   ├── QA-Report-<date>.md            # 质量验收报告
│   ├── Bug-List-<date>.md             # Bug 汇总清单
│   └── Security-Scan-Report.md        # 安全扫描报告
│
├── operations/                        # T8 DevOps 产出
│   ├── Deployment-Guide.md            # 部署手册
│   ├── Docker-Build-Guide.md          # Docker 构建指南
│   ├── CI-CD-Pipeline.md              # 流水线说明
│   ├── Healthcheck-Spec.md            # 健康检查规范
│   └── Runbook-Production.md          # 生产运维手册
│
├── guides/                            # T7 TechWriter 产出
│   ├── User-Manual.md                 # 用户使用手册
│   ├── Developer-Onboarding.md         # 开发者新手指南
│   └── Troubleshooting-Guide.md       # 问题排查指南
│
└── changelog/                         # 版本变更记录
    ├── CHANGELOG-<version>.md         # 每个版本的变更日志
    └── Migration-Log-<version>.md      # 数据迁移记录
```

---

## 📋 各角色文档产出清单

| 阶段 | 角色 | 文档类型 | 必选/可选 | 质量标准 |
|------|------|---------|----------|---------|
| **T0** | PM/TechLead | 需求准入检查报告 | ✅ 必选 | P0=0，总分 ≥70 |
| **T1** | PM | 产品需求文档 (PRD) | ✅ 必选 | 包含：用户故事、流程图、边界条件 |
| **T1** | PM | Gherkin 功能用例 | ✅ 必选 | Given-When-Then 格式，覆盖核心场景 |
| **T2** | TechLead | 架构决策记录 (ADR) | ✅ 必选 | 包含：背景、决策、后果、替代方案 |
| **T2** | TechLead | API 契约设计 | ✅ 必选 | B1-B4 完整，字段类型/错误码统一 |
| **T2** | TechLead | 技术选型说明 | ⚪ 可选 | 重要技术选型需记录 |
| **T3** | Designer | 设计规范说明 | ✅ 必选 | 包含：交互逻辑、样式规范、异常状态 |
| **T3** | Designer | HTML 可交互原型 | ✅ 必选 | 可点击跳转，覆盖主要流程 |
| **T3** | Designer | UI 走查清单 | ✅ 必选 | 与实现比对用 |
| **T4** | Frontend | TypeScript 类型定义 | ✅ 必选 | 从 OpenAPI 自动生成，提交到代码库 |
| **T5** | Backend | Rust Doc 注释 | ✅ 必选 | 所有 pub 函数有 doc 注释 |
| **T5.5** | Designer | UI 走查报告 | ✅ 必选 | P0=0，所有差异记录 |
| **T6** | QA | 测试计划 | ✅ 必选 | 范围、策略、风险、资源 |
| **T6** | QA | 测试用例库 | ✅ 必选 | TC-A/B/C 分级 |
| **T6** | QA | 质量验收报告 | ✅ 必选 | P0=0, P1≤3 |
| **T6** | QA | 安全扫描报告 | ✅ 必选 | 高危漏洞=0 |
| **T7** | TechWriter | API 文档 | ✅ 必选 | 所有端点有示例请求/响应 |
| **T7** | TechWriter | 用户手册 | ✅ 必选 | 新手可独立完成核心操作 |
| **T7** | TechWriter | CHANGELOG | ✅ 必选 | 每个版本都记录，可追溯 |
| **T8** | DevOps | 部署手册 | ✅ 必选 | 步骤可复制，含回滚方案 |
| **T8** | DevOps | 运维手册 | ✅ 必选 | 监控告警、故障排查 |
| **T9** | TechLead | 架构健康报告 | ✅ 必选 | 3 份扫描报告 + 签字确认 |
| **T9** | TechLead | 最终评审记录 | ✅ 必选 | 通过/驳回 + 原因 |

---

## 🔍 文档索引与查找机制

### 自动生成文档索引脚本

```bash
#!/bin/bash
# scripts/generate-doc-index.sh
# 自动生成 docs/README.md 索引文件

cd docs/

cat > README.md << 'EOF'
# 📚 项目文档总索引

> 最后生成时间: $(date '+%Y-%m-%d %H:%M:%S')

## 📊 文档统计

| 目录 | 文档数量 |
|------|---------|
EOF

for dir in requirements architecture design api qa operations guides changelog; do
    count=$(find $dir -name "*.md" -o -name "*.html" -o -name "*.json" 2>/dev/null | wc -l)
    echo "| $dir/ | $count |" >> README.md
done

cat >> README.md << 'EOF'

---

## 📑 按阶段索引

### 🎯 T1 - 需求分析
EOF

# 自动列出需求文档
for file in requirements/*.md; do
    if [ -f "$file" ]; then
        title=$(head -1 "$file" | sed 's/^# //')
        echo "- [$title]($file)" >> README.md
    fi
done

cat >> README.md << 'EOF'

---

### 🏗️ T2 - 架构设计
EOF

for file in architecture/*.md; do
    if [ -f "$file" ]; then
        title=$(head -1 "$file" | sed 's/^# //')
        echo "- [$title]($file)" >> README.md
    fi
done

# ... 其他目录类似处理

cat >> README.md << 'EOF'

---

## 🔍 按标签查找

| 标签 | 说明 |
|------|------|
| `#review` | 需要评审的文档 |
| `#archived` | 已归档的历史文档 |
| `#wip` | 编写中的草稿 |

---

## 📅 最近更新

EOF

# 列出最近修改的 10 个文档
find . -name "*.md" -mtime -30 -exec ls -lt {} \; 2>/dev/null | head -10 | awk '{print "- [" $9 "]("$9") - " $6 " " $7 " " $8}' >> README.md

echo ""
echo "✅ 文档索引已生成: docs/README.md"
```

---

## 🎨 文档质量标准

### Markdown 格式规范
- ✅ 一级标题 `#` 与文件名一致
- ✅ 使用 `---` 分隔主要章节
- ✅ 代码块必须指定语言 ```rust / ```typescript
- ✅ 表格必须有表头
- ✅ 关键信息使用 **加粗** 或 > 引用
- ❌ 禁止出现空段落、无意义的占位符
- ❌ 禁止使用中文标点的全角空格

### 文档完整性检查清单

每个文档必须包含：
- [ ] 标题（清晰说明文档内容）
- [ ] 版本/日期（在页眉或页脚）
- [ ] 作者/责任人
- [ ] 文档状态（草稿/评审中/已发布/已归档）
- [ ] 目录（超过 5 个章节时）

### 文档质量门禁（T7 阶段检查）

```bash
#!/bin/bash
# scripts/doc-quality-check.sh

echo "📝 文档质量检查"
echo "────────────────────────"

FAILED=0

# 检查每个 md 文件
for file in $(find docs -name "*.md"); do
    # 检查是否有标题
    has_title=$(head -1 "$file" | grep -c "^# ")
    if [ $has_title -eq 0 ]; then
        echo "❌ $file - 缺少一级标题"
        FAILED=$((FAILED + 1))
    fi

    # 检查是否有日期/版本
    has_date=$(grep -c "20[0-9][0-9]-[0-1][0-9]-[0-3][0-9]\|v[0-9]\.[0-9]" "$file")
    if [ $has_date -eq 0 ]; then
        echo "⚠️  $file - 建议添加日期或版本号"
    fi

    # 检查是否有 TODO 标记
    has_todo=$(grep -c -i "todo\|placeholder\|待补充" "$file")
    if [ $has_todo -gt 0 ]; then
        echo "⚠️  $file - 包含 $has_todo 个待补充内容"
    fi
done

echo ""
echo "📊 检查结果：发现 $FAILED 个必须修复的问题"

if [ $FAILED -gt 0 ]; then
    echo "❌ 文档质量检查未通过，请修复后再继续 T7"
    exit 1
else
    echo "✅ 文档质量检查通过"
    exit 0
fi
```

---

## 📅 文档生命周期管理

### 状态流转

```
草稿 (WIP)
   ↓
评审中 (REVIEW) ← 修正
   ↓
已发布 (PUBLISHED)
   ↓
已归档 (ARCHIVED)
   ↓
已废弃 (DEPRECATED)
```

### 状态标记规范

每个文档开头必须添加 Front Matter：

```markdown
---
title: 策略管理模块 PRD
version: v1.2
status: PUBLISHED | REVIEW | WIP | ARCHIVED | DEPRECATED
author: [姓名/角色]
date: YYYY-MM-DD
tags: [策略, backend, T1]
---
```

### 归档与清理策略

| 文档类型 | 保留期限 | 处理方式 |
|---------|---------|---------|
| PRD/ADR | 永久 | 版本化归档 |
| API 文档 | 永久 | 版本化，旧版本标记 deprecated |
| 测试报告 | 2 年 | 超期自动归档到 archive/ 目录 |
| 走查报告 | 1 年 | 超期自动归档 |
| 临时草稿 | 30 天 | 自动清理 |

### 自动归档脚本

```bash
#!/bin/bash
# scripts/archive-old-docs.sh

# 归档超过 365 天的旧文档
find docs/qa docs/design -name "*.md" -mtime +365 -exec mv {} docs/archive/ \;

# 删除超过 30 天的草稿
find docs/ -name "*DRAFT*" -o -name "*草稿*" -mtime +30 -delete

echo "✅ 文档归档清理完成"
```

---

## 🔄 文档与代码同步机制

### Git 提交规范

**提交时必须附带文档变更：**
- feat: 新功能 → 必须更新 API 文档 + CHANGELOG
- fix: Bug 修复 → 必须更新测试用例文档
- refactor: 重构 → 必须更新架构文档/ADR
- docs: 文档变更 → 单独提交

### 自动文档生成触发点

| 事件 | 自动生成的文档 |
|------|--------------|
| 后端代码变更 | `cargo doc` → Rust API 文档 |
| 前端代码变更 | TypeDoc → 类型文档 |
| 数据库 migration | 自动更新数据字典 |
| 发版前 | 自动生成 CHANGELOG（从 Git log） |

---

## 📊 文档健康度指标

每月生成文档健康度报告：

```
📊 文档健康度月报
═══════════════════════════════════

📈 文档总数: 42
📈 本月新增: 5
📈 本月更新: 8

🔍 质量检查:
  ✅ 通过: 38
  ⚠️  警告: 3
  ❌ 未通过: 1

🔖 标签分布:
  #published: 32
  #review: 4
  #wip: 5
  #archived: 1

📝 空白文档/占位符: 2
⚠️  超过 3 个月未更新: 5
❌ 缺少作者/日期: 1

⭐ 健康评分: 85 / 100
💡 建议: 清理 2 份空白文档，安排评审 4 份待审文档
```

---

## 🎯 最佳实践 Checklist

- [ ] 新建功能时，先在 `docs/` 下创建对应目录结构
- [ ] T1 阶段结束时，必须有 `requirements/` 下的 2 份文档
- [ ] T2 阶段结束时，必须有 `architecture/` 下的 2 份文档
- [ ] T7 阶段必须通过文档质量检查
- [ ] T9 评审时，检查所有文档完整性
- [ ] 每月执行一次文档索引更新 + 健康度检查

---

> 💡 **文档原则**：代码是写给机器看的，文档是写给人看的。好的文档能让新人 30 分钟上手，老人半年不写代码还能记得当初为什么那么做。
