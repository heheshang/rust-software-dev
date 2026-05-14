#!/bin/bash
# ==============================================================================
# Vue + TypeScript 前端架构腐化检测 v1.0
# 用途：T9 评审阶段执行，监控前端架构健康度
# 用法：./frontend-architecture-check.sh [frontend_dir]
# ==============================================================================

set -e

FRONTEND_DIR=${1:-"frontend/src"}
REPORT_FILE="docs/architecture/Frontend-Architecture-Report-$(date +%Y%m%d).md"

mkdir -p "docs/architecture"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           🎨 前端架构腐化检测 v1.0 (Vue + TypeScript)            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📂 检查目录: $FRONTEND_DIR"
echo "📅 检查时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# ==============================================================================
# 全局变量
# ==============================================================================
TOTAL_P0=0
TOTAL_P1=0
TOTAL_P2=0
TOTAL_FILES=0

declare -a P0_ISSUES
declare -a P1_ISSUES
declare -a P2_ISSUES

# ==============================================================================
# 1. 循环 import 检测
# ==============================================================================
check_circular_import() {
    echo "🔍 1/5 循环 import 检测..."

    local total_files=0
    local circular_count=0
    declare -A visited

    # 收集所有 import 关系
    while IFS= read -r -d '' file; do
        total_files=$((total_files + 1))
        local filename=$(realpath "$file" 2>/dev/null || echo "$file")
        local imports=$(grep -E "^import.*from" "$file" 2>/dev/null | sed "s/.*from ['\"]//;s/['\"].*//")

        for imp in $imports; do
            # 解析相对路径
            local abs_imp=$(realpath "$(dirname "$file")/$imp" 2>/dev/null || echo "$imp")

            # 简单检测：A import B 且 B import A
            if [ -n "$abs_imp" ] && [ -f "$abs_imp" ]; then
                local reverse_import=$(grep -c -E "import.*from.*$(basename "$file" .vue)" "$abs_imp" 2>/dev/null || echo 0)
                if [ $reverse_import -gt 0 ]; then
                    local pair_key=$(echo "$filename <-> $abs_imp" | tr '[:upper:]' '[:lower:]')
                    if [ -z "${visited[$pair_key]}" ]; then
                        visited[$pair_key]=1
                        circular_count=$((circular_count + 1))
                        P1_ISSUES+=("🔄 循环依赖: $(basename "$file") ↔ $(basename "$abs_imp")")
                    fi
                fi
            fi
        done
    done < <(find "$FRONTEND_DIR" -name "*.vue" -o -name "*.ts" -type f 2>/dev/null -print0)

    TOTAL_FILES=$total_files

    if [ $circular_count -gt 0 ]; then
        echo "   ⚠️  发现 $circular_count 个循环依赖"
        TOTAL_P1=$((TOTAL_P1 + circular_count))
    else
        echo "   ✅ 未发现明显循环依赖"
    fi

    echo ""
}

# ==============================================================================
# 2. any 类型泛滥统计
# ==============================================================================
check_any_type() {
    echo "🔍 2/5 any 类型泛滥检测..."

    local total_any=0
    local files_with_any=0

    while IFS= read -r -d '' file; do
        local count=$(grep -n ": *any\|:any" "$file" 2>/dev/null | grep -v "//" | wc -l)
        if [ $count -gt 0 ]; then
            files_with_any=$((files_with_any + 1))
            total_any=$((total_any + count))

            if [ $count -gt 5 ]; then
                P1_ISSUES+=("📝 $(basename "$file"): $count 个 any 类型")
            fi
        fi
    done < <(find "$FRONTEND_DIR" -name "*.ts" -o -name "*.vue" -type f 2>/dev/null -print0)

    local any_percent=0
    if [ $TOTAL_FILES -gt 0 ]; then
        any_percent=$((files_with_any * 100 / TOTAL_FILES))
    fi

    echo "   📊 含 any 的文件数: $files_with_any / $TOTAL_FILES ($any_percent%)"
    echo "   📊 总 any 数量: $total_any"

    if [ $total_any -gt 50 ]; then
        echo "   🔴 P0: any 类型泛滥！超过 50 个需要集中治理"
        TOTAL_P0=$((TOTAL_P0 + 1))
    elif [ $total_any -gt 20 ]; then
        echo "   🟡 P1: any 类型超过 20 个，建议逐步清理"
        TOTAL_P1=$((TOTAL_P1 + 1))
    else
        echo "   ✅ any 类型控制良好"
    fi

    echo ""
}

# ==============================================================================
# 3. 组件 Props 透传层级检测
# ==============================================================================
check_props_drilling() {
    echo "🔍 3/5 Props 透传层级检测（简化版）..."

    local props_drill_count=0

    # 检测超过 3 层的 props 透传（简单启发式：组件嵌套深度）
    local component_nesting=$(find "$FRONTEND_DIR/components" -name "*.vue" -type f 2>/dev/null | head -20 | wc -l)

    # 统计 defineProps 次数
    local total_props=0
    while IFS= read -r -d '' file; do
        local has_props=$(grep -c "defineProps\|defineComponent.*props" "$file" 2>/dev/null || echo 0)
        total_props=$((total_props + has_props))
    done < <(find "$FRONTEND_DIR" -name "*.vue" -type f 2>/dev/null -print0)

    echo "   📊 组件总数: ~$component_nesting"
    echo "   📊 使用 Props 的组件: $total_props"

    # 检查 Pinia 状态 vs Props 使用比例
    local pinia_usage=$(grep -r "use[A-Z].*Store\|defineStore" "$FRONTEND_DIR" 2>/dev/null | wc -l)
    if [ $total_props -gt 20 ] && [ $pinia_usage -lt 5 ]; then
        echo "   ⚠️  P1: Props 使用较多但 Pinia 状态管理较少，可能存在 Props 透传问题"
        TOTAL_P1=$((TOTAL_P1 + 1))
    fi

    echo ""
}

# ==============================================================================
# 4. 跨层级 import 检测（架构分层检查）
# ==============================================================================
check_layer_import() {
    echo "🔍 4/5 架构分层 import 检查..."

    local bad_imports=0

    # 检查规则：
    # 1. views 只能 import components / composables / types
    # 2. components 不能 import views
    # 3. api 层不能 import UI 组件

    # 检测 components import views
    local component_import_view=$(grep -rn "from.*['\"]../views\|from.*['\"]@/views" "$FRONTEND_DIR/components" 2>/dev/null | wc -l)
    if [ $component_import_view -gt 0 ]; then
        P0_ISSUES+=("🏗  架构违规: components 层 import views 层文件 ($component_import_view 处)")
        TOTAL_P0=$((TOTAL_P0 + component_import_view))
        bad_imports=$((bad_imports + component_import_view))
    fi

    # 检测 api 层 import 组件
    local api_import_ui=$(grep -rn "import.*Component\|from.*['\"]\.\./components" "$FRONTEND_DIR/api" 2>/dev/null | wc -l 2>/dev/null || echo 0)
    if [ $api_import_ui -gt 0 ]; then
        P0_ISSUES+=("🏗  架构违规: api 层 import UI 组件 ($api_import_ui 处)")
        TOTAL_P0=$((TOTAL_P0 + api_import_ui))
        bad_imports=$((bad_imports + api_import_ui))
    fi

    if [ $bad_imports -gt 0 ]; then
        echo "   ❌ 发现 $bad_imports 处跨层级违规 import"
    else
        echo "   ✅ 架构分层良好"
    fi

    echo ""
}

# ==============================================================================
# 5. Pinia/Vuex 模块边界检查
# ==============================================================================
check_store_boundary() {
    echo "🔍 5/5 Pinia Store 模块边界检查..."

    local store_count=$(find "$FRONTEND_DIR/stores" -name "*.ts" -type f 2>/dev/null | wc -l)
    local store_dir="$FRONTEND_DIR/stores"

    if [ $store_count -eq 0 ]; then
        store_dir="$FRONTEND_DIR/store"
        store_count=$(find "$store_dir" -name "*.ts" -type f 2>/dev/null | wc -l)
    fi

    if [ $store_count -eq 0 ]; then
        echo "   ⚠️  未发现 Pinia Store 目录"
        echo ""
        return
    fi

    echo "   📊 Store 模块数: $store_count"

    # 检查跨 Store 引用
    local cross_store_imports=0
    for store_file in $(find "$store_dir" -name "*.ts" -type f 2>/dev/null); do
        local cross=$(grep -c "from.*['\"]\./\|from.*['\"]\.\./store" "$store_file" 2>/dev/null || echo 0)
        cross_store_imports=$((cross_store_imports + cross))
    done

    if [ $cross_store_imports -gt 3 ]; then
        echo "   🟡 P1: Store 之间存在 $cross_store_imports 处互相引用，检查边界是否清晰"
        TOTAL_P1=$((TOTAL_P1 + 1))
    else
        echo "   ✅ Store 边界清晰"
    fi

    # 检查 Store 大小
    local largest_store=0
    local largest_name=""
    for store_file in $(find "$store_dir" -name "*.ts" -type f 2>/dev/null); do
        local lines=$(wc -l < "$store_file")
        if [ $lines -gt $largest_store ]; then
            largest_store=$lines
            largest_name=$(basename "$store_file")
        fi
    done

    if [ $largest_store -gt 500 ]; then
        echo "   🟡 P1: $largest_name 超过 500 行，建议拆分模块"
        TOTAL_P1=$((TOTAL_P1 + 1))
    fi

    echo ""
}

# ==============================================================================
# 生成架构健康评分
# ==============================================================================
calculate_health_score() {
    echo "📊 前端架构健康度评分"
    echo "───────────────────────────────────────────────────────────────"

    local base_score=100

    # 扣分规则
    base_score=$((base_score - TOTAL_P0 * 20))  # 每个 P0 扣 20 分
    base_score=$((base_score - TOTAL_P1 * 5))   # 每个 P1 扣 5 分

    # 保证分数不低于 0
    if [ $base_score -lt 0 ]; then
        base_score=0
    fi

    # 评级
    local grade="?"
    local color="?"
    if [ $base_score -ge 90 ]; then
        grade="S"
        color="🟢"
    elif [ $base_score -ge 80 ]; then
        grade="A"
        color="🟢"
    elif [ $base_score -ge 70 ]; then
        grade="B"
        color="🟡"
    elif [ $base_score -ge 60 ]; then
        grade="C"
        color="🟡"
    else
        grade="D"
        color="🔴"
    fi

    echo "   $color 健康评分: $base_score / 100 (等级 $grade)"
    echo ""
    echo "   评分细项："
    echo "     - P0 违规数: $TOTAL_P0 (-20分/个)"
    echo "     - P1 警告数: $TOTAL_P1 (-5分/个)"
    echo ""

    if [ $base_score -lt 60 ]; then
        echo "   🔴 结论：架构腐化严重，需要立即启动重构计划"
    elif [ $base_score -lt 75 ]; then
        echo "   🟡 结论：架构存在健康风险，建议安排 20% 时间偿还技术债务"
    elif [ $base_score -lt 90 ]; then
        echo "   🟢 结论：架构整体健康，注意持续监控"
    else
        echo "   ✅ 结论：架构非常健康！请继续保持"
    fi

    echo ""
}

# ==============================================================================
# 生成 Markdown 报告
# ==============================================================================
generate_report() {
    cat > "$REPORT_FILE" << EOF
# 前端架构健康检查报告

**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')
**检查目录**: $FRONTEND_DIR
**检查文件数**: $TOTAL_FILES

## 问题汇总

| 严重级别 | 数量 | 处理方式 |
|---------|------|---------|
| 🔴 P0（阻塞级） | $TOTAL_P0 | 必须修复后才能通过 T9 |
| 🟡 P1（警告级） | $TOTAL_P1 | 列入技术债务计划 |
| 🟢 P2（建议级） | $TOTAL_P2 | 择机优化 |

## 详细问题列表

### 🔴 P0 级问题（必须修复）

EOF

    if [ ${#P0_ISSUES[@]} -gt 0 ]; then
        for issue in "${P0_ISSUES[@]}"; do
            echo "- $issue" >> "$REPORT_FILE"
        done
    else
        echo "✅ 无 P0 级问题" >> "$REPORT_FILE"
    fi

    cat >> "$REPORT_FILE" << EOF

### 🟡 P1 级问题（需要处理）

EOF

    if [ ${#P1_ISSUES[@]} -gt 0 ]; then
        for issue in "${P1_ISSUES[@]}"; do
            echo "- $issue" >> "$REPORT_FILE"
        done
    else
        echo "✅ 无 P1 级问题" >> "$REPORT_FILE"
    fi

    cat >> "$REPORT_FILE" << EOF

## 前端架构健康评分

| 评分项 | 得分 |
|--------|------|
| 健康评分 | $base_score / 100 |
| 等级 | $grade |

## 技术债务偿还建议

- [ ] P0 级问题已全部修复
- [ ] P1 级问题已列入下一个迭代计划
- [ ] 已安排 10-20% 时间专门处理技术债务

## TechLead 签字确认

签字: _______________ 日期: ___________

---

*本报告由前端架构腐化检测工具自动生成*
EOF

    echo "📋 报告已生成: $REPORT_FILE"
    echo ""
}

# ==============================================================================
# 主流程
# ==============================================================================
main() {
    if [ ! -d "$FRONTEND_DIR" ]; then
        echo "❌ 未找到前端目录: $FRONTEND_DIR"
        exit 1
    fi

    check_circular_import
    check_any_type
    check_props_drilling
    check_layer_import
    check_store_boundary
    calculate_health_score
    generate_report

    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                        📊 最终检查结果                            ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    printf "║  🔴 P0 级问题:  %-3d 个 【必须修复】                          ║\n" $TOTAL_P0
    printf "║  🟡 P1 级问题:  %-3d  个 【建议处理】                          ║\n" $TOTAL_P1
    echo "╠════════════════════════════════════════════════════════════════╣"

    if [ $TOTAL_P0 -gt 0 ]; then
        echo "║  ❌ 结论: 存在 P0 级架构违规，必须修复后才能通过 T9！            ║"
    else
        echo "║  ✅ 结论: 前端架构检查通过！                                     ║"
    fi

    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    if [ $TOTAL_P0 -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

main "$@"
