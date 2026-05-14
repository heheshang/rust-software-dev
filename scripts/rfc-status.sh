#!/bin/bash
# ==============================================================================
# RFC 状态总览看板 v1.0
# 用途：任意时间查看 RFC 整体状态与进度
# 用法：./rfc-status.sh [project_root]
# ==============================================================================

set -e

PROJECT_ROOT=${1:-.}

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                  📋 RFC 状态总览看板 v1.0                         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📂 项目根目录: $PROJECT_ROOT"
echo "📅 生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

cd "$PROJECT_ROOT"

RFC_DIR="docs/rfc"

if [ ! -d "$RFC_DIR" ]; then
    echo "⚠️  未找到 RFC 目录: $RFC_DIR"
    echo "   请先运行 ./scripts/rfc-create.sh 创建第一个 RFC"
    exit 0
fi

# ==============================================================================
# 统计函数
# ==============================================================================
count_rfcs_in_state() {
    local state=$1
    local count=0

    while IFS= read -r file; do
        status=$(grep -i "^status:" "$file" 2>/dev/null | head -1 | sed 's/.*: *//' | tr -d ' ')
        if echo "$status" | grep -qi "^$state"; then
            count=$((count + 1))
        fi
    done < <(find "$RFC_DIR" -name "RFC-*.md" -type f 2>/dev/null)

    echo $count
}

# ==============================================================================
# 统计各状态数量
# ==============================================================================
DRAFT_COUNT=$(count_rfcs_in_state "Draft")
DISCUSS_COUNT=$(count_rfcs_in_state "Discuss")
FINAL_CALL_COUNT=$(count_rfcs_in_state "Final")
ACCEPTED_COUNT=$(count_rfcs_in_state "Accepted")
IMPLEMENTED_COUNT=$(count_rfcs_in_state "Implemented")
ARCHIVED_COUNT=$(count_rfcs_in_state "Archived")
REJECTED_COUNT=$(count_rfcs_in_state "Rejected")

TOTAL_COUNT=$((DRAFT_COUNT + DISCUSS_COUNT + FINAL_CALL_COUNT + ACCEPTED_COUNT + IMPLEMENTED_COUNT + ARCHIVED_COUNT + REJECTED_COUNT))

# ==============================================================================
# 输出统计概览
# ==============================================================================
echo "📊 RFC 统计概览"
echo "───────────────────────────────────────────────────────────────"
printf "   📝 起草中 (Draft):       %2d 个\n" $DRAFT_COUNT
printf "   💬 讨论中 (Discuss):     %2d 个\n" $DISCUSS_COUNT
printf "   ⏳ 最终投票 (Final Call): %2d 个\n" $FINAL_CALL_COUNT
printf "   ✅ 已接受 (Accepted):    %2d 个\n" $ACCEPTED_COUNT
printf "   🚀 已实施 (Implemented): %2d 个\n" $IMPLEMENTED_COUNT
printf "   📦 已归档 (Archived):    %2d 个\n" $ARCHIVED_COUNT
printf "   ❌ 已拒绝 (Rejected):    %2d 个\n" $REJECTED_COUNT
echo ""
echo "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "   📈 总计:                 %2d 个 RFC\n" $TOTAL_COUNT
echo ""

# ==============================================================================
# 详细列表
# ==============================================================================
echo "📋 RFC 详细列表"
echo "───────────────────────────────────────────────────────────────"
echo ""
printf "   %-8s %-25s %-12s %-12s\n" "编号" "标题" "状态" "更新日期"
echo "   ───────────────────────────────────────────────────────────"

while IFS= read -r file; do
    rfc_num=$(grep -i "^rfc:" "$file" 2>/dev/null | head -1 | sed 's/.*: *//' | tr -d ' ')
    title=$(grep -i "^title:" "$file" 2>/dev/null | head -1 | sed 's/.*: *//')
    status=$(grep -i "^status:" "$file" 2>/dev/null | head -1 | sed 's/.*: *//' | tr -d ' ')
    updated=$(grep -i "^updated:" "$file" 2>/dev/null | head -1 | sed 's/.*: *//' | tr -d ' ')

    # 状态图标
    status_icon=""
    case $status in
        Draft) status_icon="📝" ;;
        Discuss) status_icon="💬" ;;
        Final*) status_icon="⏳" ;;
        Accepted) status_icon="✅" ;;
        Implemented) status_icon="🚀" ;;
        Archived) status_icon="📦" ;;
        Rejected) status_icon="❌" ;;
        *) status_icon="❓" ;;
    esac

    # 截断标题
    title_short=$(echo "$title" | cut -c1-24)
    [ ${#title} -gt 24 ] && title_short="${title_short}..."

    printf "   RFC-%-4s %-25s %s %-10s %-12s\n" "$rfc_num" "$title_short" "$status_icon" "$status" "$updated"
done < <(find "$RFC_DIR" -name "RFC-*.md" -type f 2>/dev/null | sort)

echo ""
echo "───────────────────────────────────────────────────────────────"

# ==============================================================================
# 提醒需要关注的 RFC
# ==============================================================================
HAS_DISCUSS=0
HAS_FINAL_CALL=0

if [ $DISCUSS_COUNT -gt 0 ]; then
    HAS_DISCUSS=1
    echo ""
    echo "💬 需要关注的讨论中 RFC:"
    while IFS= read -r file; do
        status=$(grep -i "^status:" "$file" 2>/dev/null | head -1 | sed 's/.*: *//' | tr -d ' ')
        if echo "$status" | grep -qi "^Discuss"; then
            rfc_num=$(grep -i "^rfc:" "$file" 2>/dev/null | head -1 | sed 's/.*: *//')
            title=$(grep -i "^title:" "$file" 2>/dev/null | head -1 | sed 's/.*: *//')
            echo "   - RFC-$rfc_num: $title"
        fi
    done < <(find "$RFC_DIR" -name "RFC-*.md" -type f 2>/dev/null)
fi

if [ $FINAL_CALL_COUNT -gt 0 ]; then
    HAS_FINAL_CALL=1
    echo ""
    echo "⏳ 正在最终投票的 RFC（请尽快投票）:"
    while IFS= read -r file; do
        status=$(grep -i "^status:" "$file" 2>/dev/null | head -1 | sed 's/.*: *//' | tr -d ' ')
        if echo "$status" | grep -qi "^Final"; then
            rfc_num=$(grep -i "^rfc:" "$file" 2>/dev/null | head -1 | sed 's/.*: *//')
            title=$(grep -i "^title:" "$file" 2>/dev/null | head -1 | sed 's/.*: *//')
            echo "   - RFC-$rfc_num: $title"
        fi
    done < <(find "$RFC_DIR" -name "RFC-*.md" -type f 2>/dev/null)
fi

# ==============================================================================
# 快速操作提示
# ==============================================================================
echo ""
echo "⚡ 快速操作:"
echo "   创建新 RFC: ./scripts/rfc-create.sh"

if [ $HAS_DISCUSS -eq 1 ] || [ $HAS_FINAL_CALL -eq 1 ]; then
    echo "   归档已实施 RFC: ./scripts/rfc-archive.sh"
fi

echo ""
