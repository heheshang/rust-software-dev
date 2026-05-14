#!/bin/bash
# ==============================================================================
# 🧠 Rust 全栈流水线编排引擎 v4.0
# 用途：全自动驱动 T0 → T9 全流程，自动检查、自动回滚、自动归档
# 用法：./scripts/pipeline-orchestrator.sh <功能名称> [起始节点]
# 示例：./scripts/pipeline-orchestrator.sh user-auth T0
# ==============================================================================

set -e

FEATURE_NAME=$1
START_NODE=${2:-T0}
STATE_FILE=".pipeline-state.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           🧠 Rust 全栈流水线编排引擎 v4.0                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "🚀 功能名称: $FEATURE_NAME"
echo "📍 起始节点: $START_NODE"
echo "📅 启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

cd "$PROJECT_ROOT"

# ==============================================================================
# 状态管理函数
# ==============================================================================

init_state() {
    if [ ! -f "$STATE_FILE" ]; then
        cat > "$STATE_FILE" << EOF
{
  "pipeline_id": "pipe-$(date +%Y%m%d)-$(openssl rand -hex 4)",
  "feature_name": "$FEATURE_NAME",
  "start_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "current_node": "$START_NODE",
  "current_status": "idle",
  "nodes_completed": {},
  "last_checkpoint": "",
  "rollback_count": 0,
  "total_duration_minutes": 0
}
EOF
        echo "✅ 初始化流水线状态: $STATE_FILE"
    fi
}

get_current_node() {
    if [ -f "$STATE_FILE" ]; then
        grep -o '"current_node": *"[^"]*"' "$STATE_FILE" 2>/dev/null | sed 's/.*: *"//;s/"$//'
    else
        echo "$START_NODE"
    fi
}

update_node_status() {
    local node=$1
    local status=$2
    local score=${3:-""}

    echo "📝 更新节点 $node 状态: $status"

    # 简单的 JSON 更新
    if [ -f "$STATE_FILE" ]; then
        # 使用 sed 更新当前节点
        sed -i.bak "s/\"current_node\": *\"[^\"]*\"/\"current_node\": \"$node\"/" "$STATE_FILE"
        sed -i.bak "s/\"current_status\": *\"[^\"]*\"/\"current_status\": \"$status\"/" "$STATE_FILE"
        rm -f "$STATE_FILE.bak"
    fi
}

increment_rollback() {
    if [ -f "$STATE_FILE" ]; then
        current=$(grep -o '"rollback_count": *[0-9]*' "$STATE_FILE" | sed 's/.*: *//')
        new_count=$((current + 1))
        sed -i.bak "s/\"rollback_count\": *[0-9]*/\"rollback_count\": $new_count/" "$STATE_FILE"
        rm -f "$STATE_FILE.bak"
        echo "🔄 回滚计数: $new_count"
    fi
}

# ==============================================================================
# 节点顺序定义 (使用函数确保 bash 3.2 兼容性)
# ==============================================================================
get_next_node() {
    case "$1" in
        "T0") echo "T1" ;;
        "T1") echo "T2" ;;
        "T2") echo "T3" ;;
        "T3") echo "T4" ;;
        "T4") echo "T4.5" ;;
        "T4.5") echo "T5" ;;
        "T5") echo "T5.5" ;;
        "T5.5") echo "T6" ;;
        "T6") echo "T7" ;;
        "T7") echo "T8" ;;
        "T8") echo "T9" ;;
        "T9") echo "DONE" ;;
        *) echo "T0" ;;
    esac
}

# 节点检查脚本映射
get_check_script() {
    case "$1" in
        "T0") echo "./scripts/t0-check.sh" ;;
        "T1") echo "./scripts/t1-prd-check.sh" ;;
        "T2") echo "./scripts/architecture-health-check.sh" ;;
        "T3") echo "./scripts/t3-techdesign-check.sh" ;;
        "T4") echo "./scripts/t4-dev-check.sh" ;;
        "T4.5") echo "./scripts/contract-validation.sh" ;;
        "T5") echo "./scripts/migration-safety-check.sh" ;;
        "T5.5") echo "./scripts/t5.5-ui-review-check.sh" ;;
        "T6") echo "./scripts/t6-qa-check.sh" ;;
        "T7") echo "./scripts/document-quality-check.sh" ;;
        "T8") echo "./scripts/t8-deployment-check.sh" ;;
        "T9") echo "./scripts/t9-final-review-check.sh" ;;
        *) echo "" ;;
    esac
}

# 节点类型
get_node_type() {
    case "$1" in
        "T0") echo "auto" ;;
        "T1") echo "human" ;;
        "T2") echo "hybrid" ;;
        "T3") echo "auto" ;;
        "T4") echo "human" ;;
        "T4.5") echo "auto" ;;
        "T5") echo "auto" ;;
        "T5.5") echo "human" ;;
        "T6") echo "hybrid" ;;
        "T7") echo "auto" ;;
        "T8") echo "auto" ;;
        "T9") echo "human" ;;
        *) echo "auto" ;;
    esac
}

# 节点负责人
get_node_owner() {
    case "$1" in
        "T0") echo "PM+TechLead" ;;
        "T1") echo "PM" ;;
        "T2") echo "TechLead" ;;
        "T3") echo "前后端负责人" ;;
        "T4") echo "前后端开发" ;;
        "T4.5") echo "前后端联调负责人" ;;
        "T5") echo "后端负责人" ;;
        "T5.5") echo "PM+UI+前端" ;;
        "T6") echo "QA Lead" ;;
        "T7") echo "所有人" ;;
        "T8") echo "DevOps" ;;
        "T9") echo "TechLead+PM+QA" ;;
        *) echo "" ;;
    esac
}

# ==============================================================================
# 节点执行函数
# ==============================================================================
execute_node() {
    local node=$1
    local node_start_time=$(date +%s)

    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "📍 执行节点: $node"
    echo "👤 负责人: $(get_node_owner "$node")"
    echo "🕐 开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    update_node_status "$node" "in_progress"

    # 1. 如果是人工节点，需要等待确认
    if [ "$(get_node_type "$node")" = "human" ] || [ "$(get_node_type "$node")" = "hybrid" ]; then
        echo "👤 $node 是人工节点，请完成以下工作后确认继续："
        echo ""

        case $node in
            "T1") echo "   - 完成 PRD 撰写和评审" ;;
            "T2") echo "   - 完成架构设计和评审" ;;
            "T4") echo "   - 前后端并行开发完成" ;;
            "T5.5") echo "   - 完成 UI 走查和签字确认" ;;
            "T6") echo "   - QA 测试完成" ;;
            "T9") echo "   - 完成最终评审和三方签字" ;;
        esac

        echo ""
        read -p "❓ 完成后按回车继续，或输入 'pause' 暂停流水线: " user_input

        if [ "$user_input" = "pause" ]; then
            echo "⏸️  流水线已暂停在节点 $node"
            echo "   恢复执行: ./scripts/pipeline-orchestrator.sh $FEATURE_NAME $node"
            update_node_status "$node" "paused"
            exit 0
        fi
    fi

    # 2. 运行节点检查脚本
    local check_script=$(get_check_script "$node")

    if [ -n "$check_script" ] && [ -f "$check_script" ]; then
        echo "🔍 运行节点检查: $check_script"
        echo ""

        if $check_script; then
            echo ""
            echo "✅ 节点 $node 检查通过！"
        else
            echo ""
            echo "❌ 节点 $node 检查未通过！"
            handle_node_failure "$node"
            return 1
        fi
    else
        echo "⚠️  节点 $node 暂无自动检查脚本，假设通过"
    fi

    # 3. 自动归档（如果有归档脚本）
    if [ -f "./scripts/archive-node-docs.sh" ]; then
        echo ""
        echo "📦 自动归档节点文档..."
        ./scripts/archive-node-docs.sh "$node" "$FEATURE_NAME" 2>/dev/null || true
    fi

    # 4. 更新状态
    update_node_status "$node" "completed"

    # 计算耗时
    local node_end_time=$(date +%s)
    local duration=$(( (node_end_time - node_start_time) / 60 ))

    echo ""
    echo "✅ 节点 $node 完成！耗时: $duration 分钟"

    # 5. 返回下一个节点
    local next_node=$(get_next_node "$node")
    echo "➡️  下一个节点: $next_node"

    return 0
}

# ==============================================================================
# 失败回滚处理
# ==============================================================================
handle_node_failure() {
    local failed_node=$1

    echo ""
    echo "🔙  启动回滚流程..."

    increment_rollback

    # 根据失败节点决定回退到哪里
    local rollback_to=""
    case $failed_node in
        "T1") rollback_to="T0" ;;
        "T2") rollback_to="T1" ;;
        "T3") rollback_to="T2" ;;
        "T4.5") rollback_to="T4" ;;
        "T5") rollback_to="T4" ;;
        "T5.5") rollback_to="T4" ;;
        "T6") rollback_to="T5" ;;
        "T7") rollback_to="T7" ;; # T7不回滚，就在当前节点补
        "T8") rollback_to="T6" ;;
        "T9") rollback_to="T2" ;; # T9 失败，根据问题回
        *) rollback_to="T0" ;;
    esac

    echo "📍 根据回滚矩阵，回退到节点: $rollback_to"
    echo ""

    # 检查回滚次数
    local rollback_count=$(grep -o '"rollback_count": *[0-9]*' "$STATE_FILE" 2>/dev/null | sed 's/.*: *//')
    if [ "$rollback_count" -ge 3 ]; then
        echo "🚨 警告：同一流水线已回滚 3 次！"
        echo "   建议暂停并做整体复盘..."
        echo ""
        read -p "❓ 是否继续回滚？(yes/N): " confirm
        if [ "$confirm" != "yes" ]; then
            echo "⏹️  流水线已停止，请人工介入评估"
            exit 1
        fi
    fi

    echo ""
    echo "⏸️  流水线暂停，请修复问题后从 $rollback_to 节点恢复："
    echo "   ./scripts/pipeline-orchestrator.sh $FEATURE_NAME $rollback_to"
    echo ""

    update_node_status "$failed_node" "failed"

    exit 1
}

# ==============================================================================
# 主执行循环
# ==============================================================================
main() {
    init_state

    local current_node=$(get_current_node)
    local start_time=$(date +%s)

    echo "📊 流水线状态: current_node=$current_node"
    echo ""

    # 从当前节点开始执行
    while [ "$current_node" != "DONE" ]; do
        if execute_node "$current_node"; then
            # 节点成功，推进到下一个
            current_node=$(get_next_node "$current_node")
        else
            # 节点失败，回滚（已经在 handle_node_failure 中 exit）
            exit 1
        fi

        # 节点之间的停顿（给用户时间确认）
        if [ "$current_node" != "DONE" ]; then
            echo ""
            read -t 3 -p "⏳ 3秒后自动进入下一个节点，按回车立即继续..." || true
            echo ""
        fi
    done

    # ==========================================================================
    # 流水线完成！
    # ==========================================================================
    local end_time=$(date +%s)
    local total_minutes=$(( (end_time - start_time) / 60 ))
    local total_hours=$(echo "scale=1; $total_minutes / 60" | bc 2>/dev/null || echo "~")

    echo ""
    echo "🎉🎉🎉 流水线全部完成！ 🎉🎉🎉"
    echo ""
    echo "📊 执行统计:"
    echo "   功能名称: $FEATURE_NAME"
    echo "   完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "   总耗时: $total_minutes 分钟 (~$total_hours 小时)"
    echo ""
    echo "📦 交付物:"
    echo "   - 所有文档已归档到 docs/ 目录"
    echo "   - 状态文件: $STATE_FILE"
    echo ""
    echo "🚀 可以准备上线了！"
    echo ""
    echo "✨ 恭喜完成完整的 T0-T9 流水线！"
    echo ""
}

# 显示帮助
show_help() {
    echo "用法: ./scripts/pipeline-orchestrator.sh <功能名称> [起始节点]"
    echo ""
    echo "示例:"
    echo "  ./scripts/pipeline-orchestrator.sh user-auth T0    # 从头开始"
    echo "  ./scripts/pipeline-orchestrator.sh user-auth T4    # 从 T4 开始"
    echo ""
    echo "节点顺序: T0 → T1 → T2 → T3 → T4 → T4.5 → T5 → T5.5 → T6 → T7 → T8 → T9"
    echo ""
}

if [ -z "$FEATURE_NAME" ] || [ "$FEATURE_NAME" = "--help" ] || [ "$FEATURE_NAME" = "-h" ]; then
    show_help
    exit 0
fi

main "$@"
