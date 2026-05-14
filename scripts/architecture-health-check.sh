#!/bin/bash
# ==============================================================================
# Rust 项目架构健康综合检查 v1.0
# 用途：T2 架构设计 + T9 最终评审阶段强制执行，检测架构腐化
# 用法：./architecture-health-check.sh [project_root]
# ==============================================================================

set -e

PROJECT_ROOT=${1:-.}
REPORT_DIR="$PROJECT_ROOT/docs/architecture"
REPORT_FILE="$REPORT_DIR/Architecture-Health-Report-$(date +%Y%m%d).md"

mkdir -p "$REPORT_DIR"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           🧱 Rust 项目架构健康综合检查 v1.0                      ║"
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

declare -A ISSUES_P0
declare -A ISSUES_P1
declare -A ISSUES_P2

# ==============================================================================
# 1. 依赖方向检查（分层架构验证）
# ==============================================================================
check_dependency_direction() {
    echo "🔍 1/5 依赖方向检查..."
    echo "───────────────────────────────────────────────────────────────"

    if [ ! -d "backend/src" ]; then
        echo "   ⚠️  未找到 backend/src 目录，跳过"
        echo ""
        return
    fi

    local p0_count=0
    local p1_count=0

    # 检查跨层依赖：handler 直接 use db 模块（应该通过 service 层）
    local handler_use_db=$(grep -rn "use crate::db\|use super::db" backend/src/handlers/ 2>/dev/null | wc -l)
    if [ $handler_use_db -gt 0 ]; then
        echo "   🟡 P1: 发现 $handler_use_db 处 handler 直接访问 db 层（建议通过 service 层）"
        p1_count=$((p1_count + handler_use_db))
        ISSUES_P1["handler直连db"]=$handler_use_db
    else
        echo "   ✅ 无跨层依赖"
    fi

    # 检查反向依赖：entity 层 use handler/service
    local reverse_dep=$(grep -rn "use crate::handlers\|use crate::services" backend/src/entity/ 2>/dev/null | wc -l)
    if [ $reverse_dep -gt 0 ]; then
        echo "   🔴 P0: 发现 $reverse_dep 处反向依赖！entity 层不应依赖 handler/service"
        p0_count=$((p0_count + reverse_dep))
        ISSUES_P0["反向依赖"]=$reverse_dep
    else
        echo "   ✅ 无反向依赖"
    fi

    TOTAL_P0=$((TOTAL_P0 + p0_count))
    TOTAL_P1=$((TOTAL_P1 + p1_count))

    echo ""
}

# ==============================================================================
# 2. 循环依赖检测
# ==============================================================================
check_cyclic_dependency() {
    echo "🔍 2/5 循环依赖检测..."
    echo "───────────────────────────────────────────────────────────────"

    if [ ! -d "backend/src" ]; then
        echo "   ⚠️  未找到 backend/src 目录，跳过"
        echo ""
        return
    fi

    local cycle_count=0

    # 简单检测：A use B 且 B use A 的情况
    while IFS= read -r -d '' file; do
        local mod_name=$(basename "$file" .rs)
        local deps=$(grep -E "use crate::[a-z_]+" "$file" 2>/dev/null | sed 's/.*use crate::\([a-z_:]*\).*/\1/' | cut -d: -f1 | sort -u)

        for dep in $deps; do
            local dep_file=$(find backend/src -name "${dep}.rs" -o -name "${dep}/mod.rs" 2>/dev/null | head -1)
            if [ -n "$dep_file" ]; then
                local reverse_ref=$(grep -c "use crate::${mod_name}" "$dep_file" 2>/dev/null || echo 0)
                if [ $reverse_ref -gt 0 ]; then
                    echo "   ⚠️  P2: 发现潜在循环依赖 ${mod_name} ↔ ${dep}"
                    cycle_count=$((cycle_count + 1))
                fi
            fi
        done
    done < <(find backend/src -name "*.rs" -type f -print0 2>/dev/null | head -30)

    if [ $cycle_count -eq 0 ]; then
        echo "   ✅ 未发现明显循环依赖"
    fi

    TOTAL_P2=$((TOTAL_P2 + cycle_count))
    echo ""
}

# ==============================================================================
# 3. 模块边界检查
# ==============================================================================
check_module_boundary() {
    echo "🔍 3/5 模块边界完整性检查..."
    echo "───────────────────────────────────────────────────────────────"

    if [ ! -d "backend/src" ]; then
        echo "   ⚠️  未找到 backend/src 目录，跳过"
        echo ""
        return
    fi

    local over_expose_total=0

    # 检查是否有模块直接 pub mod 暴露整个子模块
    for mod_file in $(find backend/src -name "mod.rs" -type f 2>/dev/null); do
        local over_expose=$(grep -n "^pub mod " "$mod_file" | wc -l)
        over_expose_total=$((over_expose_total + over_expose))
    done

    if [ $over_expose_total -gt 0 ]; then
        echo "   🟢 P2: 共 $over_expose_total 处 pub mod 暴露子模块（建议仅 pub use 需要导出的函数）"
        ISSUES_P2["模块暴露过宽"]=$over_expose_total
    else
        echo "   ✅ 模块边界良好"
    fi

    TOTAL_P2=$((TOTAL_P2 + over_expose_total))
    echo ""
}

# ==============================================================================
# 4. 代码复杂度与技术债务
# ==============================================================================
check_complexity_and_debt() {
    echo "🔍 4/5 代码复杂度与技术债务分析..."
    echo "───────────────────────────────────────────────────────────────"

    if [ ! -d "backend/src" ]; then
        echo "   ⚠️  未找到 backend/src 目录，跳过"
        echo ""
        return
    fi

    local p1_count=0
    local p2_count=0

    # 统计超长文件
    local long_files=0
    while IFS= read -r rs_file; do
        local lines=$(wc -l < "$rs_file")
        if [ $lines -gt 500 ]; then
            echo "   🟡 P1: $(basename "$rs_file") 超过 500 行（共 $lines 行），建议拆分"
            long_files=$((long_files + 1))
            p1_count=$((p1_count + 1))
        elif [ $lines -gt 300 ]; then
            echo "   🟢 P2: $(basename "$rs_file") 超过 300 行（共 $lines 行），关注复杂度"
            p2_count=$((p2_count + 1))
        fi
    done < <(find backend/src -name "*.rs" -type f 2>/dev/null)

    if [ $long_files -eq 0 ]; then
        echo "   ✅ 无超长文件"
    fi

    # 技术债务标记统计
    local fixme=$(grep -rn "FIXME" backend/src --include="*.rs" 2>/dev/null | wc -l)
    local todo=$(grep -rn "TODO" backend/src --include="*.rs" 2>/dev/null | wc -l)
    local hack=$(grep -rn "HACK\|XXX" backend/src --include="*.rs" 2>/dev/null | wc -l)
    local debt_score=$((fixme * 10 + todo * 3 + hack * 15))

    echo ""
    echo "   📊 技术债务统计:"
    echo "      FIXME: $fixme 个"
    echo "      TODO:  $todo 个"
    echo "      HACK:  $hack 个"
    echo "      债务评分: $debt_score 分（越低越好）"

    if [ $debt_score -gt 200 ]; then
        echo "   🟡 P1: 技术债务评分过高（>200），建议安排重构计划"
        p1_count=$((p1_count + 1))
        ISSUES_P1["技术债务过高"]=$debt_score
    fi

    TOTAL_P1=$((TOTAL_P1 + p1_count))
    TOTAL_P2=$((TOTAL_P2 + p2_count))

    echo ""
}

# ==============================================================================
# 5. 前端架构健康检查（如存在）
# ==============================================================================
check_frontend_architecture() {
    echo "🔍 5/5 前端架构健康检查..."
    echo "───────────────────────────────────────────────────────────────"

    if [ ! -d "frontend/src" ]; then
        echo "   ⚠️  未找到 frontend/src 目录，跳过"
        echo ""
        return
    fi

    local p1_count=0
    local p2_count=0

    # any 类型泛滥检查
    local any_count=$(grep -rn ": *any\|:any" frontend/src --include="*.ts" --include="*.vue" 2>/dev/null | grep -v "//" | wc -l)
    local total_types=$(grep -rn ": *\w\+" frontend/src --include="*.ts" --include="*.vue" 2>/dev/null | wc -l)
    local any_ratio=0

    if [ $total_types -gt 0 ]; then
        any_ratio=$((any_count * 100 / total_types))
    fi

    echo "   📊 any 类型检查:"
    echo "      总 any 数量: $any_count"
    echo "      any 占比: $any_ratio%"

    if [ $any_count -gt 50 ]; then
        echo "   🔴 P0: any 类型泛滥（>50 个），严重削弱类型保护"
        p1_count=$((p1_count + 1))
        ISSUES_P0["any类型泛滥"]=$any_count
    elif [ $any_count -gt 20 ]; then
        echo "   🟡 P1: any 类型较多（>20），建议逐步清理"
        p1_count=$((p1_count + 1))
        ISSUES_P1["any类型较多"]=$any_count
    fi

    # 组件文件大小检查
    local large_components=0
    while IFS= read -r vue_file; do
        local lines=$(wc -l < "$vue_file")
        if [ $lines -gt 500 ]; then
            echo "   🟡 P1: $(basename "$vue_file") 组件过大（$lines 行），建议拆分"
            large_components=$((large_components + 1))
            p1_count=$((p1_count + 1))
        fi
    done < <(find frontend/src -name "*.vue" -type f 2>/dev/null | head -20)

    if [ $any_count -le 20 ] && [ $large_components -eq 0 ]; then
        echo "   ✅ 前端架构健康"
    fi

    TOTAL_P0=$((TOTAL_P0 + (any_count > 50 ? 1 : 0)))
    TOTAL_P1=$((TOTAL_P1 + p1_count))

    echo ""
}

# ==============================================================================
# 计算健康评分
# ==============================================================================
calculate_health_score() {
    echo "📊 架构健康总评"
    echo "───────────────────────────────────────────────────────────────"

    local base_score=100

    # 扣分规则
    base_score=$((base_score - TOTAL_P0 * 20))  # 每个 P0 扣 20 分
    base_score=$((base_score - TOTAL_P1 * 5))   # 每个 P1 扣 5 分
    base_score=$((base_score - TOTAL_P2 * 1))   # 每个 P2 扣 1 分

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

    echo "   $color 架构健康评分: $base_score / 100 (等级 $grade)"
    echo ""
    echo "   问题汇总:"
    echo "      🔴 P0 严重问题: $TOTAL_P0 个"
    echo "      🟡 P1 警告问题: $TOTAL_P1 个"
    echo "      🟢 P2 建议优化: $TOTAL_P2 个"
    echo ""

    if [ $base_score -lt 60 ]; then
        echo "   🔴 结论：架构腐化严重，需要立即启动重构计划"
    elif [ $base_score -lt 75 ]; then
        echo "   🟡 结论：存在架构健康风险，建议安排 20% 时间偿还技术债务"
    elif [ $base_score -lt 90 ]; then
        echo "   🟢 结论：架构整体健康，注意持续监控"
    else
        echo "   ✅ 结论：架构非常健康！请继续保持"
    fi

    echo ""
}

# ==============================================================================
# 生成报告
# ==============================================================================
generate_report() {
    echo "📋 生成架构健康报告..."

    cat > "$REPORT_FILE" << EOF
# 🧱 架构健康检查报告

**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')
**检查范围**: 全项目

## 问题汇总

| 严重级别 | 数量 | 处理优先级 |
|---------|------|----------|
| 🔴 P0 (阻塞) | $TOTAL_P0 | 必须修复，阻塞发布 |
| 🟡 P1 (警告) | $TOTAL_P1 | 本迭代修复 |
| 🟢 P2 (建议) | $TOTAL_P2 | 技术债务，择机优化 |

---

## 架构健康评分

| 指标 | 得分 | 等级 |
|------|------|------|
| 架构健康度 | $base_score / 100 | $grade |

---

## 详细问题列表

### 🔴 P0 级严重问题（必须修复）

EOF

    if [ ${#ISSUES_P0[@]} -gt 0 ]; then
        for issue in "${!ISSUES_P0[@]}"; do
            echo "- [ ] **$issue**: ${ISSUES_P0[$issue]} 处" >> "$REPORT_FILE"
        done
    else
        echo "✅ 无 P0 级严重问题" >> "$REPORT_FILE"
    fi

    cat >> "$REPORT_FILE" << EOF

---

### 🟡 P1 级警告问题（建议修复）

EOF

    if [ ${#ISSUES_P1[@]} -gt 0 ]; then
        for issue in "${!ISSUES_P1[@]}"; do
            echo "- [ ] **$issue**: ${ISSUES_P1[$issue]}" >> "$REPORT_FILE"
        done
    else
        echo "✅ 无 P1 级警告问题" >> "$REPORT_FILE"
    fi

    cat >> "$REPORT_FILE" << EOF

---

### 🟢 P2 级建议优化

EOF

    if [ ${#ISSUES_P2[@]} -gt 0 ]; then
        for issue in "${!ISSUES_P2[@]}"; do
            echo "- [ ] **$issue**: ${ISSUES_P2[$issue]}" >> "$REPORT_FILE"
        done
    else
        echo "✅ 无 P2 级建议优化" >> "$REPORT_FILE"
    fi

    cat >> "$REPORT_FILE" << EOF

---

## 修复优先级建议

1. **立即修复**：所有 🔴 P0 级严重问题
2. **本迭代修复**：所有 🟡 P1 级警告问题
3. **技术债务池**：所有 🟢 P2 级建议优化

## TechLead 签字确认

- [ ] 已审阅所有架构问题
- [ ] P0 级问题修复计划已安排
- [ ] P1 级问题已列入迭代计划

签字: _______________ 日期: ___________

---

*本报告由架构健康检查工具自动生成*
EOF

    echo "   ✅ 报告已生成: $REPORT_FILE"
    echo ""
}

# ==============================================================================
# 输出最终结果
# ==============================================================================
print_final_result() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                      📊 检查结果汇总                              ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    printf "║  🔴 P0 级问题:  %-3d 个 【必须修复，阻塞 T9 评审】           ║\n" $TOTAL_P0
    printf "║  🟡 P1 级问题:  %-3d  个 【本迭代修复】                         ║\n" $TOTAL_P1
    printf "║  🟢 P2 级问题:  %-3d  个 【技术债务，择机优化】                ║\n" $TOTAL_P2
    echo "╠════════════════════════════════════════════════════════════════╣"

    if [ $TOTAL_P0 -gt 0 ]; then
        echo "║  ❌ 结论：存在 P0 级架构问题，必须修复后才能通过 T9 评审！       ║"
    else
        echo "║  ✅ 结论：架构健康检查通过！                                      ║"
    fi

    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📋 详细报告: $REPORT_FILE"
    echo ""

    if [ $TOTAL_P0 -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# ==============================================================================
# 主流程
# ==============================================================================
main() {
    check_dependency_direction
    check_cyclic_dependency
    check_module_boundary
    check_complexity_and_debt
    check_frontend_architecture
    calculate_health_score
    generate_report
    print_final_result
}

main "$@"
