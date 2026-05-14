#!/bin/bash
# ==============================================================================
# 数据库 Migration 安全检查 v1.0
# 用途：T5 后端完成阶段强制执行，检测危险数据库操作
# 用法：./migration-safety-check.sh [project_root]
# ==============================================================================

set -e

PROJECT_ROOT=${1:-.}

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           🛡️ 数据库 Migration 安全检查 v1.0                       ║"
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

declare -A ISSUES_FOUND

MIGRATION_DIRS=(
    "backend/migration"
    "backend/migrations"
    "backend/db/migrations"
    "migrations"
    "db/migrations"
)

# ==============================================================================
# 查找 Migration 目录
# ==============================================================================
find_migration_dir() {
    for dir in "${MIGRATION_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            echo "$dir"
            return 0
        fi
    done
    echo ""
    return 1
}

MIGRATION_DIR=$(find_migration_dir)

if [ -z "$MIGRATION_DIR" ]; then
    echo "⚠️  未找到 Migration 目录，跳过检查"
    echo ""
    echo "✅ 检查通过（无 migration 文件需要检查）"
    exit 0
fi

echo "📁 找到 Migration 目录: $MIGRATION_DIR"
echo ""

# ==============================================================================
# 1. 危险操作检测 (DROP TABLE / DROP COLUMN)
# ==============================================================================
check_dangerous_operations() {
    echo "🔍 1/5 危险操作检测..."
    echo "───────────────────────────────────────────────────────────────"

    local dangerous_count=0
    local drop_table_count=0
    local drop_column_count=0

    while IFS= read -r -d '' file; do
        drop_table=$(grep -i "DROP TABLE\|drop_table" "$file" | wc -l)
        drop_column=$(grep -i "DROP COLUMN\|drop_column" "$file" | wc -l)

        if [ $drop_table -gt 0 ] || [ $drop_column -gt 0 ]; then
            echo "   🔴 P0: $(basename "$file") 包含危险操作"
            if [ $drop_table -gt 0 ]; then
                echo "      - DROP TABLE 操作: $drop_table 处"
                dangerous_count=$((dangerous_count + drop_table))
            fi
            if [ $drop_column -gt 0 ]; then
                echo "      - DROP COLUMN 操作: $drop_column 处"
                dangerous_count=$((dangerous_count + drop_column))
            fi
        fi
    done < <(find "$MIGRATION_DIR" -name "*.rs" -o -name "*.sql" -type f -print0 2>/dev/null)

    if [ $dangerous_count -gt 0 ]; then
        TOTAL_P0=$((TOTAL_P0 + dangerous_count))
        ISSUES_FOUND["危险操作(DROP)"]=$dangerous_count
        echo ""
        echo "   ⚠️  警告: DROP 操作不可逆转，请确认已备份数据！"
    else
        echo "   ✅ 未发现危险 DROP 操作"
    fi

    echo ""
}

# ==============================================================================
# 2. ALTER TABLE 锁表风险分析
# ==============================================================================
check_alter_lock_risk() {
    echo "🔍 2/5 ALTER TABLE 锁表风险分析..."
    echo "───────────────────────────────────────────────────────────────"

    local high_risk=0
    local medium_risk=0

    while IFS= read -r -d '' file; do
        # 检测高风险 ALTER 操作
        alter_count=$(grep -i "ALTER TABLE\|alter_table" "$file" | wc -l)

        # 特定高风险操作
        rename_col=$(grep -i "RENAME COLUMN\|rename_column" "$file" | wc -l)
        change_type=$(grep -i "CHANGE TYPE\|change_column\|set_data_type" "$file" | wc -l)
        add_not_null=$(grep -i "NOT NULL\|set_not_null" "$file" | wc -l)

        if [ $rename_col -gt 0 ] || [ $change_type -gt 0 ]; then
            echo "   🔴 P0: $(basename "$file") 高风险 ALTER 操作"
            echo "      - 可能导致长时间锁表，建议在低峰期执行"
            high_risk=$((high_risk + 1))
        elif [ $add_not_null -gt 0 ]; then
            echo "   🟡 P1: $(basename "$file") 注意 NOT NULL 默认值问题"
            echo "      - 确保已有数据有默认值，否则会失败"
            medium_risk=$((medium_risk + 1))
        elif [ $alter_count -gt 0 ]; then
            echo "   🟢 P2: $(basename "$file") 包含 ALTER 操作"
            P2_count=$((P2_count + 1))
        fi
    done < <(find "$MIGRATION_DIR" -name "*.rs" -o -name "*.sql" -type f -print0 2>/dev/null)

    if [ $high_risk -gt 0 ]; then
        TOTAL_P0=$((TOTAL_P0 + high_risk))
        ISSUES_FOUND["高风险ALTER操作"]=$high_risk
    fi
    if [ $medium_risk -gt 0 ]; then
        TOTAL_P1=$((TOTAL_P1 + medium_risk))
        ISSUES_FOUND["中等风险ALTER操作"]=$medium_risk
    fi

    if [ $high_risk -eq 0 ] && [ $medium_risk -eq 0 ]; then
        echo "   ✅ 无高风险 ALTER 操作"
    fi

    echo ""
}

# ==============================================================================
# 3. 回滚函数检查 (down 函数是否存在)
# ==============================================================================
check_rollback_function() {
    echo "🔍 3/5 回滚函数检查..."
    echo "───────────────────────────────────────────────────────────────"

    local missing_rollback=0
    local migration_count=0

    while IFS= read -r -d '' file; do
        migration_count=$((migration_count + 1))

        if [[ "$file" == *.rs ]]; then
            has_down=$(grep -c "fn down\|fn revert" "$file" 2>/dev/null || echo 0)
            if [ $has_down -eq 0 ]; then
                echo "   🟡 P1: $(basename "$file") 缺少 down() 回滚函数"
                missing_rollback=$((missing_rollback + 1))
            fi
        fi
    done < <(find "$MIGRATION_DIR" -name "*.rs" -type f -print0 2>/dev/null)

    if [ $missing_rollback -gt 0 ]; then
        TOTAL_P1=$((TOTAL_P1 + missing_rollback))
        ISSUES_FOUND["缺少回滚函数"]=$missing_rollback
        echo ""
        echo "   💡 建议: 所有 migration 都应该实现 down() 函数支持回滚"
    else
        echo "   ✅ 回滚函数完整性良好"
    fi

    echo ""
}

# ==============================================================================
# 4. CREATE INDEX CONCURRENTLY 最佳实践检查
# ==============================================================================
check_index_best_practices() {
    echo "🔍 4/5 索引创建最佳实践检查..."
    echo "───────────────────────────────────────────────────────────────"

    local non_concurrent=0

    while IFS= read -r -d '' file; do
        create_index=$(grep -i "CREATE INDEX\|create_index" "$file" | grep -vi "CONCURRENTLY\|concurrently" | wc -l)

        if [ $create_index -gt 0 ]; then
            echo "   🟢 P2: $(basename "$file") 创建索引未使用 CONCURRENTLY"
            echo "      - 建议: 大表创建索引使用 CREATE INDEX CONCURRENTLY 避免锁表"
            non_concurrent=$((non_concurrent + create_index))
        fi
    done < <(find "$MIGRATION_DIR" -name "*.rs" -o -name "*.sql" -type f -print0 2>/dev/null)

    if [ $non_concurrent -gt 0 ]; then
        TOTAL_P2=$((TOTAL_P2 + non_concurrent))
        ISSUES_FOUND["未使用CONCURRENTLY索引"]=$non_concurrent
    else
        echo "   ✅ 索引创建遵循最佳实践"
    fi

    echo ""
}

# ==============================================================================
# 5. 数据迁移脚本复杂度分析
# ==============================================================================
check_migration_complexity() {
    echo "🔍 5/5 迁移脚本复杂度分析..."
    echo "───────────────────────────────────────────────────────────────"

    local large_migrations=0
    local total_migrations=0

    while IFS= read -r file; do
        lines=$(wc -l < "$file")
        total_migrations=$((total_migrations + 1))

        if [ $lines -gt 200 ]; then
            echo "   🟡 P1: $(basename "$file") 脚本过大 ($lines 行)"
            echo "      - 建议: 拆分为多个小 migration 便于回滚和审查"
            large_migrations=$((large_migrations + 1))
        fi
    done < <(find "$MIGRATION_DIR" -name "*.rs" -o -name "*.sql" -type f 2>/dev/null)

    if [ $large_migrations -gt 0 ]; then
        TOTAL_P1=$((TOTAL_P1 + large_migrations))
        ISSUES_FOUND["过大的Migration脚本"]=$large_migrations
    fi

    echo "   📊 总计 $total_migrations 个 migration 脚本"

    echo ""
}

# ==============================================================================
# 输出最终结果
# ==============================================================================
print_final_result() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    📊 Migration 检查结果汇总                      ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    printf "║  🔴 P0 级严重问题:  %-3d 个 【必须修复，阻塞发布】           ║\n" $TOTAL_P0
    printf "║  🟡 P1 级警告问题:  %-3d  个 【本迭代修复】                    ║\n" $TOTAL_P1
    printf "║  🟢 P2 级建议优化:  %-3d  个 【技术债务，择机优化】           ║\n" $TOTAL_P2
    echo "╠════════════════════════════════════════════════════════════════╣"

    if [ ${#ISSUES_FOUND[@]} -gt 0 ]; then
        echo "║  📋 问题详情:                                                    ║"
        for issue in "${!ISSUES_FOUND[@]}"; do
            printf "║     - %s: %d 处\n" "$issue" "${ISSUES_FOUND[$issue]}"
        done
    fi

    echo "╠════════════════════════════════════════════════════════════════╣"

    if [ $TOTAL_P0 -gt 0 ]; then
        echo "║  ❌ 结论：存在 P0 级安全风险，必须修复后才能发布！                ║"
    else
        echo "║  ✅ 结论：Migration 安全检查通过！                                ║"
    fi

    echo "╚════════════════════════════════════════════════════════════════╝"
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
check_dangerous_operations
check_alter_lock_risk
check_rollback_function
check_index_best_practices
check_migration_complexity
print_final_result
