#!/bin/bash
# ==============================================================================
# 文档索引自动生成 v1.0
# 用途：T7 文档阶段自动生成 docs/README.md 目录索引
# 用法：./generate-doc-index.sh [project_root]
# ==============================================================================

set -e

PROJECT_ROOT=${1:-.}

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              📚 文档索引自动生成 v1.0                             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

cd "$PROJECT_ROOT"

INDEX_FILE="docs/README.md"
mkdir -p "docs"

# ==============================================================================
# 收集文档信息
# ==============================================================================
echo "🔍 扫描文档文件..."
echo "───────────────────────────────────────────────────────────────"

TOTAL_DOCS=0
declare -a DOC_ENTRIES

# 扫描所有 md 文件
while IFS= read -r file; do
    TOTAL_DOCS=$((TOTAL_DOCS + 1))

    # 提取标题
    title=$(grep -m1 "^# " "$file" | sed 's/^# //')
    if [ -z "$title" ]; then
        title=$(basename "$file" .md)
    fi

    # 提取描述（如果有）
    description=""
    desc_line=$(grep -m1 "^> " "$file" | sed 's/^> //')
    if [ -n "$desc_line" ]; then
        description=$desc_line
    fi

    # 提取日期
    date=""
    date_line=$(grep -m1 "date:\|Date:\|日期:\|创建日期:" "$file" | head -1 | sed 's/.*:\s*//')
    if [ -n "$date_line" ]; then
        date=$date_line
    fi

    # 分类
    category="其他"
    if echo "$file" | grep -q "rfc"; then
        category="RFC 文档"
    elif echo "$file" | grep -q "architecture"; then
        category="架构设计"
    elif echo "$file" | grep -q "api"; then
        category="API 文档"
    elif echo "$file" | grep -q "qa\|test"; then
        category="测试文档"
    elif echo "$file" | grep -q "operations\|ops"; then
        category="运维文档"
    fi

    # 相对路径
    rel_path=$(echo "$file" | sed 's/^docs\///')

    DOC_ENTRIES+=("$category|$title|$rel_path|$date|$description")

    echo "   📄 $file"

done < <(find docs -name "*.md" -path "docs/*" ! -path "docs/README.md" 2>/dev/null | sort)

echo ""
echo "   共扫描 $TOTAL_DOCS 个文档"
echo ""

# ==============================================================================
# 生成索引文件
# ==============================================================================
echo "📝 生成文档索引..."

cat > "$INDEX_FILE" << EOF
# 📚 项目文档索引

**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')
**文档总数**: $TOTAL_DOCS 个

---

## 快速导航

| 分类 | 文档数 |
|------|--------|
EOF

# 按类别统计
declare -A CATEGORY_COUNTS
for entry in "${DOC_ENTRIES[@]}"; do
    IFS='|' read -r cat _ _ _ _ <<< "$entry"
    CATEGORY_COUNTS[$cat]=$((CATEGORY_COUNTS[$cat] + 1))
done

for cat in "${!CATEGORY_COUNTS[@]}"; do
    echo "| $cat | ${CATEGORY_COUNTS[$cat]} |" >> "$INDEX_FILE"
done

cat >> "$INDEX_FILE" << EOF

---

## 文档列表

EOF

# 按类别输出文档
for cat in "RFC 文档" "架构设计" "API 文档" "测试文档" "运维文档" "其他"; do
    has_docs=0
    category_content=""

    for entry in "${DOC_ENTRIES[@]}"; do
        IFS='|' read -r e_cat title path date description <<< "$entry"

        if [ "$e_cat" = "$cat" ]; then
            has_docs=1

            if [ -n "$date" ]; then
                date_str=" ($date)"
            else
                date_str=""
            fi

            if [ -n "$description" ]; then
                desc_str="  \n  > $description"
            else
                desc_str=""
            fi

            category_content+="- [$title]($path)$date_str$desc_str\n"
        fi
    done

    if [ $has_docs -eq 1 ]; then
        echo "### $cat" >> "$INDEX_FILE"
        echo "" >> "$INDEX_FILE"
        printf "$category_content" >> "$INDEX_FILE"
        echo "" >> "$INDEX_FILE"
    fi
done

cat >> "$INDEX_FILE" << EOF
---

## 文档规范

### 文档命名规范

1. 使用 kebab-case 命名：`my-document.md`
2. 文件名反映文档内容
3. RFC 文档遵循 `RFC-XXXX-title.md` 格式

### 文档元数据

每个文档应包含以下 Front Matter：

```markdown
---
title: 文档标题
author: 作者姓名
date: YYYY-MM-DD
version: 1.0
---
```

---

*本索引由脚本自动生成，运行 ./scripts/generate-doc-index.sh 更新*
EOF

echo "   ✅ 索引已生成: $INDEX_FILE"
echo ""

# ==============================================================================
# 最近更新文档
# ==============================================================================
echo "📅 最近更新的文档:"
echo "───────────────────────────────────────────────────────────────"

find docs -name "*.md" -type f -exec stat -f "%m %N" {} \; 2>/dev/null | sort -rn | head -5 | while read -r timestamp file; do
    date_str=$(date -r "$timestamp" '+%Y-%m-%d')
    echo "   $date_str - $(basename "$file")"
done

echo ""
echo "✅ 文档索引生成完成！"
echo ""
echo "📖 查看文档质量: ./scripts/document-quality-check.sh"
echo ""
