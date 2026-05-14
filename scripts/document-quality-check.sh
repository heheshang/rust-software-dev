#!/bin/bash
# ==============================================================================
# 文档质量检查 v1.0
# 用途：T7 文档阶段检查文档完整性和规范性
# 用法：./document-quality-check.sh [project_root]
# ==============================================================================

set -e

PROJECT_ROOT=${1:-.}

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║               📝 文档质量检查 v1.0                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📂 项目根目录: $PROJECT_ROOT"
echo "📅 检查时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

cd "$PROJECT_ROOT"

# ==============================================================================
# 全局变量
# ==============================================================================
TOTAL_P0=0
TOTAL_P1=0
TOTAL_P2=0

declare -A ISSUES

# ==============================================================================
# 1. 必选文档存在性检查
# ==============================================================================
check_required_docs() {
    echo "🔍 1/5 必选文档存在性检查..."
    echo "───────────────────────────────────────────────────────────────"

    local missing=0

    REQUIRED_DOCS=(
        "README.md:项目说明文档"
        "docs/architecture/README.md:架构文档目录"
        "docs/api/README.md:API文档目录"
        "CONTRIBUTING.md:贡献指南"
        "CHANGELOG.md:变更日志"
    )

    for doc in "${REQUIRED_DOCS[@]}"; do
        path=$(echo "$doc" | cut -d':' -f1)
        desc=$(echo "$doc" | cut -d':' -f2)

        if [ ! -f "$path" ]; then
            echo "   🟡 P1: 缺少 $desc ($path)"
            missing=$((missing + 1))
        fi
    done

    if [ $missing -gt 0 ]; then
        TOTAL_P1=$((TOTAL_P1 + missing))
        ISSUES["缺少必选文档"]=$missing
    else
        echo "   ✅ 所有必选文档已存在"
    fi

    echo ""
}

# ==============================================================================
# 2. 文档标题完整性检查
# ==============================================================================
check_doc_titles() {
    echo "🔍 2/5 文档标题完整性检查..."
    echo "───────────────────────────────────────────────────────────────"

    local no_title=0

    while IFS= read -r file; do
        first_line=$(head -1 "$file")
        if ! echo "$first_line" | grep -q "^#"; then
            echo "   🟢 P2: $(basename "$file") 缺少一级标题"
            no_title=$((no_title + 1))
        fi
    done < <(find docs -name "*.md" -type f 2>/dev/null | head -30)

    if [ $no_title -gt 0 ]; then
        TOTAL_P2=$((TOTAL_P2 + no_title))
        ISSUES["缺少标题的文档"]=$no_title
    else
        echo "   ✅ 文档标题完整"
    fi

    echo ""
}

# ==============================================================================
# 3. 元数据检查 (版本/日期/作者)
# ==============================================================================
check_doc_metadata() {
    echo "🔍 3/5 文档元数据检查..."
    echo "───────────────────────────────────────────────────────────────"

    local missing_meta=0

    while IFS= read -r file; do
        has_date=$(grep -c "date:\|Date:\|日期:" "$file" 2>/dev/null || echo 0)
        has_version=$(grep -c "version:\|Version:\|版本:" "$file" 2>/dev/null || echo 0)
        has_author=$(grep -c "author:\|Author:\|作者:" "$file" 2>/dev/null || echo 0)

        if [ $has_date -eq 0 ] || [ $has_version -eq 0 ] || [ $has_author -eq 0 ]; then
            echo "   🟢 P2: $(basename "$file") 元数据不完整"
            missing_meta=$((missing_meta + 1))
        fi
    done < <(find docs/rfc docs/architecture -name "*.md" -type f 2>/dev/null | head -20)

    if [ $missing_meta -gt 0 ]; then
        TOTAL_P2=$((TOTAL_P2 + missing_meta))
        ISSUES["元数据不完整的文档"]=$missing_meta
    else
        echo "   ✅ 文档元数据完整"
    fi

    echo ""
}

# ==============================================================================
# 4. TODO 占位符检查
# ==============================================================================
check_todo_placeholders() {
    echo "🔍 4/5 TODO 占位符检查..."
    echo "───────────────────────────────────────────────────────────────"

    local todo_count=0

    while IFS= read -r file; do
        todos=$(grep -n "\[ \]\|TODO\|FIXME\|在此处填写\|\\[在此处" "$file" 2>/dev/null | head -5)
        count=$(echo "$todos" | grep -v '^$' | wc -l | tr -d ' ')

        if [ $count -gt 0 ]; then
            echo "   🟡 P1: $(basename "$file") 包含 $count 个待填项"
            todo_count=$((todo_count + count))
        fi
    done < <(find docs -name "*.md" -type f 2>/dev/null | head -30)

    if [ $todo_count -gt 0 ]; then
        TOTAL_P1=$((TOTAL_P1 + todo_count))
        ISSUES["文档待填项"]=$todo_count
    else
        echo "   ✅ 未发现 TODO 占位符"
    fi

    echo ""
}

# ==============================================================================
# 5. Markdown 格式规范检查
# ==============================================================================
check_markdown_format() {
    echo "🔍 5/5 Markdown 格式规范检查..."
    echo "───────────────────────────────────────────────────────────────"

    local format_issues=0

    while IFS= read -r file; do
        issues=0

        # 检查空链接
        empty_links=$(grep -c "\[.*\](\s*)" "$file" 2>/dev/null || echo 0)
        # 检查无效图片
        broken_images=$(grep -c "!\[.*\](\s*)" "$file" 2>/dev/null || echo 0)
        # 检查标题后紧跟内容（空行缺失）
        no_blank=$(grep -c "^#.*[a-zA-Z0-9]$" "$file" 2>/dev/null || echo 0)

        issues=$((empty_links + broken_images + no_blank))

        if [ $issues -gt 0 ]; then
            echo "   🟢 P2: $(basename "$file") 有 $issues 个格式问题"
            format_issues=$((format_issues + issues))
        fi
    done < <(find docs -name "*.md" -type f 2>/dev/null | head -30)

    if [ $format_issues -gt 0 ]; then
        TOTAL_P2=$((TOTAL_P2 + format_issues))
        ISSUES["格式问题"]=$format_issues
    else
        echo "   ✅ Markdown 格式良好"
    fi

    echo ""
}

# ==============================================================================
# 输出最终结果
# ==============================================================================
print_final_result() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                   📊 文档质量检查结果                             ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    printf "║  🔴 P0 级严重问题:  %-3d 个                                      ║\n" $TOTAL_P0
    printf "║  🟡 P1 级警告问题:  %-3d  个 【建议在发布前修复】               ║\n" $TOTAL_P1
    printf "║  🟢 P2 级建议优化:  %-3d  个 【技术债务】                       ║\n" $TOTAL_P2
    echo "╠════════════════════════════════════════════════════════════════╣"

    if [ ${#ISSUES[@]} -gt 0 ]; then
        echo "║  📋 问题详情:                                                    ║"
        for issue in "${!ISSUES[@]}"; do
            printf "║     - %s: %d 个\n" "$issue" "${ISSUES[$issue]}"
        done
    fi

    echo "╠════════════════════════════════════════════════════════════════╣"

    if [ $TOTAL_P1 -gt 5 ]; then
        echo "║  🟡 结论：存在较多文档问题，建议完善后发布                        ║"
    elif [ $TOTAL_P1 -gt 0 ]; then
        echo "║  ⚠️  结论：存在少量文档问题，建议补充完善                         ║"
    else
        echo "║  ✅ 结论：文档质量检查通过！                                      ║"
    fi

    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📚 生成文档索引: ./scripts/generate-doc-index.sh"
    echo ""

    if [ $TOTAL_P1 -gt 5 ]; then
        return 1
    else
        return 0
    fi
}

# ==============================================================================
# 主流程
# ==============================================================================
check_required_docs
check_doc_titles
check_doc_metadata
check_todo_placeholders
check_markdown_format
print_final_result
