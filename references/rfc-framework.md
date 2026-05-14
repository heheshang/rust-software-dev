# RFC 文档管理框架 v1.0

> 灵感来源：Rust RFC Process + IETF Internet Draft Template
> 适用场景：重大架构决策、技术选型、核心模块设计、破坏性变更

---

## 🎯 什么时候需要写 RFC？

| 场景 | 示例 | 优先级 |
|------|------|-------|
| 引入新技术栈 | 从 Actix-web 迁移到 Axum | 🔴 必须 |
| 核心模块重构 | 重写数据持久层 | 🔴 必须 |
| 破坏性变更 | API 协议 v1 → v2 不兼容升级 | 🔴 必须 |
| 技术选型决策 | 数据库从 PostgreSQL 迁移到 CockroachDB | 🟡 建议 |
| 跨团队协作接口 | 与其他团队的服务契约 | 🟡 建议 |
| 性能优化方案 | 引入缓存层、查询优化 | 🟢 可选 |

**简单判断：影响超过 3 个人、超过 3 天工作量的变更，都应该写 RFC。**

---

## 📋 RFC 工作流程

```
  提出 RFC          公开讨论          修改完善        评审决策         执行落地     归档复盘
     │                  │                  │                │              │            │
     ├─ Draft ─────────► ◄──────── Discuss ─────────► ◄─ Final Call ──► ── Accept ──► Implemented ──► Archived
     │                  │                  │                │              │            │
     │              至少 3 天         采纳所有合理意见      2/3 同意       按 RFC 执行   记录实际效果
     │
     └─ Reject（理由不充分）
     └─ Postpone（时机不成熟）
```

### 各阶段准入标准

| 阶段 | 要求 |
|------|------|
| **Draft** | 完整的背景、方案、备选方案描述 |
| **Discuss** | 至少 3 天公开讨论期，所有相关人员参与 |
| **Final Call** | 所有评论已回复，分歧已缩小到可决策范围 |
| **Accept** | ≥ 2/3 评审成员同意，TechLead 最终签字 |
| **Implemented** | 代码已按 RFC 方案落地，关联 PR 已合并 |
| **Archived** | 复盘完成，记录实际效果与预期差异 |

---

## 📝 RFC 标准模板

```markdown
---
RFC: RFC-0001
Title: 使用 SeaORM 替换原生 SQL 作为数据持久层方案
Author: [作者姓名/角色]
Status: Draft | Discuss | Final Call | Accepted | Rejected | Implemented | Archived
Created: 2024-05-14
Last-Modified: 2024-05-14
---

# RFC-0001: 使用 SeaORM 替换原生 SQL

## 1. 背景与动机

### 1.1 现状描述

当前项目数据持久层使用纯手写 SQL + sqlx 实现，存在以下问题：

- 每个表的 CRUD 都需要手写大量重复代码
- 数据库迁移需要手动维护 SQL 文件
- 类型安全有限，字段名拼写错误运行时才能发现
- 缺少统一的查询构建器，复杂查询难以维护

### 1.2 要解决的问题

1. 减少 50% 以上的数据层重复代码
2. 编译时类型检查，消灭字段名拼写错误
3. 统一团队代码风格，降低新人上手成本
4. 支持多数据库类型，未来可能需要分库分表

### 1.3 非目标（明确不做什么）

- ❌ 不替换现有的所有 SQL（渐进式迁移）
- ❌ 不引入复杂的 ORM 特性，只使用核心功能
- ❌ 不对业务逻辑做任何变更

---

## 2. 详细设计方案

### 2.1 技术选型

| 对比项 | SeaORM | Diesel | sqlx (现状) |
|--------|--------|--------|------------|
| 类型安全 | ✅ 编译时 | ✅ 编译时 | ⚠️ 运行时 |
| 迁移工具 | ✅ 内置 | ✅ 内置 | ⚠️ 需自建 |
| 查询构建器 | ✅ 流式 | ✅ DSL | ❌ 字符串 |
| 社区活跃度 | 中 | 高 | 高 |
| 团队熟悉度 | 低 | 中 | 高 |
| Async 支持 | ✅ 原生 | ✅ 0.20+ | ✅ 原生 |

**结论：选择 SeaORM**

选择理由：
1. 与 Axum 生态兼容性好
2. 迁移工具开箱即用
3. 代码生成能力减少重复劳动
4. 商业支持有保障

### 2.2 架构设计

```
┌─────────────────────────────────────────────┐
│         Application Layer                   │
│  (handlers / services / domain logic)       │
└───────────────┬─────────────────────────────┘
                │
                ▼  依赖注入
┌─────────────────────────────────────────────┐
│         Repository Layer (NEW)              │
│  entity::strategy::Entity::find()           │
│  entity::strategy::ActiveModel::update()    │
└───────────────┬─────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────┐
│         SeaORM                              │
│  (Connection Pool / Query Builder / Migrations) │
└───────────────┬─────────────────────────────┘
                │
                ▼
        ┌───────────────┐
        │  PostgreSQL   │
        └───────────────┘
```

### 2.3 代码示例

```rust
// 旧方式（sqlx）
let strategy: Strategy = sqlx::query_as!(
    Strategy,
    "SELECT * FROM strategies WHERE id = $1",
    id
)
.fetch_one(&pool)
.await?;

// 新方式（SeaORM）
let strategy: strategy::Model = strategy::Entity::find_by_id(id)
    .one(&db)
    .await?;
```

### 2.4 迁移计划

| 阶段 | 内容 | 预计工时 |
|------|------|---------|
| 1 | 引入 SeaORM 依赖，配置连接池 | 0.5 天 |
| 2 | 迁移 strategy 表作为试点 | 1 天 |
| 3 | 团队代码评审，收集反馈 | 0.5 天 |
| 4 | 分批迁移剩余 8 张表 | 3 天 |
| 5 | 性能测试与优化 | 1 天 |
| **合计** | | **6 天** |

---

## 3. 备选方案分析

### 备选方案 A：继续使用 sqlx

**优点：**
- 无需学习成本
- 现有代码无需修改
- 对 SQL 有完全控制

**缺点：**
- 重复代码问题持续存在
- 新成员上手成本高
- 没有统一规范，代码风格容易分化

### 备选方案 B：使用 Diesel

**优点：**
- 成熟度更高，社区更大
- 编译时类型检查更严格

**缺点：**
- 异步支持不如 SeaORM 原生
- 迁移体验不如 SeaORM 直观
- 团队已有 SeaORM 经验

### 方案对比矩阵

| 维度 | 方案 A (sqlx) | 方案 B (Diesel) | 方案 C (SeaORM) |
|------|-------------|-----------------|-----------------|
| 开发效率 | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 学习成本 | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| 类型安全 | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 性能 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 社区支持 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **总分** | **14** | **17** | **19** |

---

## 4. 风险评估与应对

| 风险 | 概率 | 影响 | 应对措施 |
|------|------|------|---------|
| 学习曲线陡峭，团队上手慢 | 🔵 中 | 🟡 中 | 安排 1 天 workshop，写详细的最佳实践文档 |
| 性能退化，复杂查询变慢 | 🟢 低 | 🟡 中 | 先迁移简单查询，做性能基准测试，保留复杂 SQL 优化空间 |
| 与现有 sqlx 代码冲突 | 🟢 低 | 🟡 中 | 渐进式迁移，两者可共存，使用同一连接池 |
| 社区活跃度下降，维护中断 | 🔵 中 | 🔴 高 | 封装一层抽象，未来可替换；关注 SeaORM 商业化进展 |

---

## 5. 向后兼容性

### 5.1 API 兼容性

- ✅ 对外 HTTP API 完全不变
- ✅ 数据库 schema 完全不变
- ✅ 业务逻辑层接口不变

### 5.2 数据迁移

- 无 schema 变更，纯代码重构
- SeaORM 与 sqlx 可共享同一数据库连接池
- 可逐表迁移，随时可以回滚

### 5.3 回滚方案

如果迁移过程中发现严重问题：

1. 保留原 sqlx 代码不删除
2. 通过 feature flag 切换实现
3. 回滚只需修改一处配置，无需大改动

---

## 6. 未解决的问题

1. **多表复杂查询的性能表现**：需要实际 benchmark 验证
2. **事务嵌套的边界**：需要定义最佳实践
3. **软删除的统一处理**：是否需要统一封装

---

## 7. 参考资料

- [SeaORM 官方文档](https://www.sea-ql.org/SeaORM/)
- [Rust Web 开发最佳实践](链接)
- [相关技术讨论 Issue #123](链接)

---

## 📊 投票记录

| 成员 | 投票 | 理由 |
|------|------|------|
| @Alice | ✅ 同意 | 方案考虑周全，渐进式迁移风险可控 |
| @Bob | ✅ 同意 | SeaORM 迁移工具比 sqlx 好用太多 |
| @Charlie | ⚠️ 有保留同意 | 建议先做性能基准测试再全量迁移 |
| @Dave | ❌ 反对 | 学习成本太高，现有方案能用就行 |

**最终结果：3 同意 / 1 反对 / 0 弃权 → 通过 ✅**

---

## 📝 评审意见汇总

### 主要问题与回复

1. **Q: 性能会不会比手写 SQL 差？**
   A: 初步 benchmark 显示差异在 5% 以内，业务可接受。会补充完整的性能测试报告。

2. **Q: 现有代码怎么办？**
   A: 渐进式迁移，不强制一次性改完。旧代码继续工作，新功能用新方式。

3. **Q: 团队成员不会 SeaORM 怎么办？**
   A: 写详细的最佳实践文档 + 1 天 workshop，结对编程带入门。

---

## 🎯 执行追踪

- [x] RFC 提出（2024-05-14）
- [x] 公开讨论期（2024-05-14 ~ 2024-05-17）
- [x] 评审通过（2024-05-18）
- [ ] 阶段 1：依赖引入与配置
- [ ] 阶段 2：试点表迁移
- [ ] 阶段 3：全量迁移
- [ ] 阶段 4：性能测试与优化
- [ ] 执行完成与复盘

---

## 📈 复盘记录（执行后填写）

### 实际执行情况

- 实际用时：X 天（预计 6 天）
- 遇到的主要问题：
  1. ...
  2. ...

### 方案与实际差异

| 项 | 预期 | 实际 | 差异原因 |
|----|------|------|---------|
| 开发效率提升 | 50% | X% | ... |
| 代码行数变化 | -30% | X% | ... |
| Bug 数量 | 减少 | X | ... |

### 经验总结

1. ...
2. ...
3. ...

---

*最后更新: 2024-05-14*
```

---

## 🔧 RFC 工具链脚本

### 1. RFC 创建脚手架

```bash
#!/bin/bash
# scripts/rfc-create.sh
# 创建新的 RFC 文档

RFC_DIR="docs/rfc"
mkdir -p "$RFC_DIR"

# 找到最大的 RFC 编号
LAST_RFC=$(ls -1 $RFC_DIR/RFC-*.md 2>/dev/null | sort -V | tail -1 | grep -o '[0-9]\+' | tail -1)
NEXT_RFC=$((LAST_RFC + 1))
NEXT_RFC_PADDED=$(printf "%04d" $NEXT_RFC)

if [ -z "$LAST_RFC" ]; then
    NEXT_RFC_PADDED="0001"
fi

echo "📝 创建 RFC-$NEXT_RFC_PADDED"
echo ""

read -p "请输入 RFC 标题: " RFC_TITLE
read -p "请输入作者姓名: " RFC_AUTHOR

RFC_FILE="$RFC_DIR/RFC-${NEXT_RFC_PADDED}.md"
TODAY=$(date +%Y-%m-%d)

cat > "$RFC_FILE" << EOF
---
RFC: RFC-${NEXT_RFC_PADDED}
Title: ${RFC_TITLE}
Author: ${RFC_AUTHOR}
Status: Draft
Created: ${TODAY}
Last-Modified: ${TODAY}
---

# RFC-${NEXT_RFC_PADDED}: ${RFC_TITLE}

## 1. 背景与动机

### 1.1 现状描述

### 1.2 要解决的问题

### 1.3 非目标

---

## 2. 详细设计方案

### 2.1 技术选型

### 2.2 架构设计

### 2.3 代码示例

### 2.4 迁移计划

---

## 3. 备选方案分析

### 备选方案 A：

### 备选方案 B：

---

## 4. 风险评估与应对

| 风险 | 概率 | 影响 | 应对措施 |
|------|------|------|---------|
| | | | |

---

## 5. 向后兼容性

---

## 6. 未解决的问题

---

## 7. 参考资料

---

## 📊 投票记录

| 成员 | 投票 | 理由 |
|------|------|------|
| | | |

---

## 📝 评审意见汇总

---

## 🎯 执行追踪

- [ ] RFC 提出
- [ ] 公开讨论期
- [ ] 评审通过
- [ ] 执行完成
- [ ] 复盘归档

---

*最后更新: ${TODAY}*
EOF

echo ""
echo "✅ RFC 文件已创建: $RFC_FILE"
echo ""
echo "接下来的步骤："
echo "  1. 编辑 RFC 内容，补充完整方案"
echo "  2. 创建 PR/MR，标记为 RFC"
echo "  3. 通知相关人员参与讨论"
echo "  4. 讨论期至少 3 天"
```

### 2. RFC 状态检查脚本

```bash
#!/bin/bash
# scripts/rfc-status.sh
# 查看所有 RFC 的状态

RFC_DIR="docs/rfc"

echo "📋 RFC 状态总览"
echo "═══════════════════════════════════════════════════════════"
printf "%-8s %-30s %-12s %s\n" "RFC编号" "标题" "状态" "最后更新"
echo "─────────────────────────────────────────────────────────────"

for rfc_file in $(ls -1 $RFC_DIR/RFC-*.md 2>/dev/null | sort -V); do
    rfc_num=$(echo "$rfc_file" | grep -o 'RFC-[0-9]\+')
    title=$(grep "^Title:" "$rfc_file" | cut -d: -f2 | sed 's/^ //')
    status=$(grep "^Status:" "$rfc_file" | cut -d: -f2 | sed 's/^ //')
    last_mod=$(grep "^Last-Modified:" "$rfc_file" | cut -d: -f2 | sed 's/^ //')

    # 状态颜色
    case "$status" in
        *Draft*)      status_color="📝 Draft      " ;;
        *Discuss*)    status_color="💬 Discuss    " ;;
        *Final*)      status_color="📢 Final Call " ;;
        *Accepted*)   status_color="✅ Accepted   " ;;
        *Rejected*)   status_color="❌ Rejected   " ;;
        *Implemented*)status_color="🚀 Implemented" ;;
        *Archived*)   status_color="📦 Archived   " ;;
        *)            status_color="❓ $status   " ;;
    esac

    printf "%-8s %-30s %s %s\n" "$rfc_num" "${title:0:28}" "$status_color" "$last_mod"
done

echo ""
echo "📊 统计:"

total=$(ls -1 $RFC_DIR/RFC-*.md 2>/dev/null | wc -l)
draft=$(grep -l "Status:.*Draft" $RFC_DIR/RFC-*.md 2>/dev/null | wc -l)
discuss=$(grep -l "Status:.*Discuss" $RFC_DIR/RFC-*.md 2>/dev/null | wc -l)
accepted=$(grep -l "Status:.*Accepted" $RFC_DIR/RFC-*.md 2>/dev/null | wc -l)
implemented=$(grep -l "Status:.*Implemented" $RFC_DIR/RFC-*.md 2>/dev/null | wc -l)

echo "  总计: $total 个 RFC"
echo "  📝 起草中: $draft"
echo "  💬 讨论中: $discuss"
echo "  ✅ 已通过: $accepted"
echo "  🚀 已执行: $implemented"
```

### 3. RFC 归档脚本

```bash
#!/bin/bash
# scripts/rfc-archive.sh
# 归档已完成的 RFC

RFC_DIR="docs/rfc"
ARCHIVE_DIR="docs/rfc/archive"

mkdir -p "$ARCHIVE_DIR"

echo "📦 归档已完成的 RFC"
echo "═════════════════════════════════════════"

for rfc_file in $(grep -l "Status:.*Implemented" $RFC_DIR/RFC-*.md 2>/dev/null); do
    # 检查是否有复盘记录
    has_review=$(grep -c "复盘记录" "$rfc_file")

    if [ $has_review -gt 0 ]; then
        rfc_num=$(basename "$rfc_file" .md)
        echo "  归档: $rfc_num"

        # 修改状态为 Archived
        sed -i '' 's/Status:.*Implemented/Status: Archived/' "$rfc_file"

        # 移动到归档目录
        mv "$rfc_file" "$ARCHIVE_DIR/"
    else
        echo "  ⚠️  $(basename $rfc_file) 缺少复盘记录，先完成复盘"
    fi
done

echo ""
echo "✅ 归档完成"
```

---

## 📁 RFC 目录结构

```
docs/rfc/
├── README.md                          # RFC 索引与说明
├── RFC-0001-seaorm-migration.md      # 已通过的 RFC
├── RFC-0002-caching-strategy.md       # 讨论中的 RFC
├── RFC-0003-api-versioning.md         # 起草中的 RFC
│
└── archive/                           # 已执行完成的 RFC 归档
    ├── RFC-0000-template.md
    └── ...
```

---

## 🎯 RFC 质量门禁（T2 阶段）

**重大架构变更必须满足：**

- [ ] 有完整的 RFC 文档（背景/方案/备选/风险）
- [ ] 公开讨论期 ≥ 3 天
- [ ] 至少 3 位核心成员参与讨论
- [ ] 所有评论已得到回复
- [ ] ≥ 2/3 评审成员同意
- [ ] TechLead 最终签字确认
- [ ] 有明确的执行计划和时间表

---

## 💡 RFC 最佳实践

1. **一个 RFC 只讲一件事**：不要在一个 RFC 里讨论多个不相关的变更
2. **尽早讨论**：写代码前先写 RFC，不要等写完了才发现方向不对
3. **欢迎不同意见**：讨论越充分，决策越靠谱
4. **记录所有分歧**：不管采纳与否，讨论过的内容都要记录下来
5. **实事求是**：不要回避风险和问题，正视才能解决
6. **执行后一定要复盘**：实际 vs 预期的差异是团队最宝贵的财富

---

> **RFC 的本质不是审批流程，而是「让聪明的大脑并行思考」的工具。**
>
> 好的 RFC 会把所有人的经验和智慧汇聚在一起，最终方案往往比任何一个人单独想出来的都更周全。
