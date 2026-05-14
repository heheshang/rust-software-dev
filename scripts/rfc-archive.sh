#!/bin/bash
# ==============================================================================
# RFC 归档工具 v1.0
# 用途：T9 最终评审后归档已完成的 RFC
# 用法：./rfc-archive.sh [project_root]
# ==============================================================================

set -e

PROJECT_ROOT=${1:-.}

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                  📦 RFC 归档工具 v1.0                            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

cd "$PROJECT_ROOT"

RFC_DIR="docs/rfc"

if [ ! -d "$RFC_DIR" ]; then
    echo "⚠️  未找到 RFC 目录"
    exit 0
fi

# ==============================================================================
# 查找已实施可归档的 RFC
# ==============================================================================
echo "🔍 扫描可归档的 RFC..."
echo "───────────────────────────────────────────────────────────────"

ARCHIVE_CANDIDATES=()

while IFS= read -r file; do
    status=$(grep -i "^status:" "$file" 2>/dev/null | head -1 | sed 's/.*: *//' | tr -d ' ')
    rfc_num=$(grep -i "^rfc:" "$file" 2>/dev/null | head -1 | sed 's/.*: *//')
    title=$(grep -i "^title:" "$file" 2>/dev/null | head -1 | sed 's/.*: *//')

    if [ "$status" = "Implemented" ]; then
        echo "   ✅ RFC-$rfc_num: $title"
        echo "      路径: $file"
        ARCHIVE_CANDIDATES+=("$file")
    fi
done < <(find "$RFC_DIR" -name "RFC-*.md" -type f 2>/dev/null | sort)

echo ""

if [ ${#ARCHIVE_CANDIDATES[@]} -eq 0 ]; then
    echo "ℹ️  没有找到可归档的 RFC（状态需为 Implemented）"
    echo ""
    exit 0
fi

echo "📋 找到 ${#ARCHIVE_CANDIDATES[@]} 个可归档的 RFC"
echo ""

# ==============================================================================
# 确认归档
# ==============================================================================
read -p "❓ 是否确认归档这些 RFC? (y/N): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "   已取消归档"
    exit 0
fi

echo ""

# ==============================================================================
# 执行归档
# ==============================================================================
echo "📦 执行归档..."
echo "───────────────────────────────────────────────────────────────"

ARCHIVED_COUNT=0

for file in "${ARCHIVE_CANDIDATES[@]}"; do
    rfc_num=$(grep -i "^rfc:" "$file" 2>/dev/null | head -1 | sed 's/.*: *//')
    title=$(grep -i "^title:" "$file" 2>/dev/null | head -1 | sed 's/.*: *//')

    filename=$(basename "$file")
    target_dir="$RFC_DIR/archived"
    target_path="$target_dir/$filename"

    # 移动文件
    mv "$file" "$target_path"

    # 更新状态为 Archived
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^status: *Implemented$/status: Archived/" "$target_path"
    else
        sed -i "s/^status: *Implemented$/status: Archived/" "$target_path"
    fi

    # 更新更新日期
    today=$(date '+%Y-%m-%d')
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^updated: .*/updated: $today/" "$target_path"
    else
        sed -i "s/^updated: .*/updated: $today/" "$target_path"
    fi

    # 添加归档记录
    if ! grep -q "## 归档记录" "$target_path"; then
        echo "" >> "$target_path"
        echo "---" >> "$target_path"
        echo "" >> "$target_path"
        echo "## 归档记录" >> "$target_path"
        echo "" >> "$target_path"
    fi

    echo "- **$today**: 归档完成，T9 最终评审通过" >> "$target_path"

    echo "   ✅ RFC-$rfc_num 已归档"
    echo "      新路径: $target_path"
    ARCHIVED_COUNT=$((ARCHIVED_COUNT + 1))
done

echo ""
echo "✅ 归档完成！共归档 $ARCHIVED_COUNT 个 RFC"
echo ""
echo "📊 查看当前 RFC 状态: ./scripts/rfc-status.sh"
echo ""
