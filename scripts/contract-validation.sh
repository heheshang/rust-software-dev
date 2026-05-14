#!/bin/bash
# ==============================================================================
# API 契约一致性检查 v1.0
# 用途：T4.5 前后端联调阶段执行，验证契约一致性
# 用法：./contract-validation.sh [project_root]
# ==============================================================================

set -e

PROJECT_ROOT=${1:-.}

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║               📜 API 契约一致性检查 v1.0                          ║"
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

SPEC_FILE="docs/api/OpenAPI-3.0-spec.yaml"
FRONTEND_TYPES="frontend/src/types/api.generated.ts"

declare -a ISSUES

# ==============================================================================
# 1. OpenAPI Spec 存在性检查
# ==============================================================================
check_spec_exists() {
    echo "🔍 1/4 OpenAPI Spec 存在性检查..."
    echo "───────────────────────────────────────────────────────────────"

    if [ ! -f "$SPEC_FILE" ]; then
        echo "   🔴 P0: 未找到 OpenAPI Spec 文件"
        echo "      期望路径: $SPEC_FILE"
        echo "      💡 请先创建 API 契约规范"
        TOTAL_P0=$((TOTAL_P0 + 1))
        ISSUES+=("缺少OpenAPI Spec文件")
    else
        echo "   ✅ OpenAPI Spec 存在"

        # 验证基本结构
        has_openapi=$(grep -c "^openapi:" "$SPEC_FILE" 2>/dev/null || echo 0)
        has_paths=$(grep -c "^paths:" "$SPEC_FILE" 2>/dev/null || echo 0)
        has_components=$(grep -c "^components:" "$SPEC_FILE" 2>/dev/null || echo 0)

        if [ $has_openapi -eq 0 ] || [ $has_paths -eq 0 ]; then
            echo "   🟡 P1: Spec 文件结构不完整"
            TOTAL_P1=$((TOTAL_P1 + 1))
            ISSUES+=("Spec结构不完整")
        else
            echo "   ✅ Spec 结构验证通过"
        fi
    fi

    echo ""
}

# ==============================================================================
# 2. 前端类型生成检查
# ==============================================================================
check_frontend_types() {
    echo "🔍 2/4 前端类型文件检查..."
    echo "───────────────────────────────────────────────────────────────"

    if [ ! -f "$FRONTEND_TYPES" ]; then
        echo "   🟡 P1: 未找到前端类型生成文件"
        echo "      期望路径: $FRONTEND_TYPES"
        echo "      💡 请从 OpenAPI Spec 生成 TypeScript 类型"
        TOTAL_P1=$((TOTAL_P1 + 1))
        ISSUES+=("缺少前端类型文件")
    else
        echo "   ✅ 前端类型文件存在"

        # 检查是否有导出内容
        has_export=$(grep -c "export interface\|export type" "$FRONTEND_TYPES" 2>/dev/null || echo 0)
        if [ $has_export -eq 0 ]; then
            echo "   🟡 P1: 类型文件中没有导出的类型定义"
            TOTAL_P1=$((TOTAL_P1 + 1))
            ISSUES+=("类型文件无导出内容")
        else
            echo "   ✅ 找到 $has_export 个类型定义"
        fi
    fi

    echo ""
}

# ==============================================================================
# 3. 后端路由与 Spec 一致性检查
# ==============================================================================
check_backend_routes() {
    echo "🔍 3/4 后端路由与 Spec 一致性检查..."
    echo "───────────────────────────────────────────────────────────────"

    if [ ! -f "$SPEC_FILE" ]; then
        echo "   ⚠️  跳过：缺少 Spec 文件"
        echo ""
        return
    fi

    # 从 Spec 提取所有路径
    SPEC_PATHS=$(grep -E "^  [/a-zA-Z0-9_{}]+" "$SPEC_FILE" | sed 's/^  //' | sed 's/:$//' | sort | uniq)
    SPEC_PATH_COUNT=$(echo "$SPEC_PATHS" | wc -l | tr -d ' ')

    # 从后端代码提取实际路由
    BACKEND_ROUTES=""
    if [ -d "backend/src" ]; then
        # Axum 风格路由
        BACKEND_ROUTES=$(grep -rn "Router::new\|\.route\|router\." backend/src --include="*.rs" 2>/dev/null | \
                        grep -oE '"/[a-zA-Z0-9_/{}]+"' | sed 's/"//g' | sort | uniq)
    fi

    BACKEND_ROUTE_COUNT=$(echo "$BACKEND_ROUTES" | grep -v '^$' | wc -l | tr -d ' ')

    echo "   📋 Spec 定义端点 ($SPEC_PATH_COUNT 个):"
    if [ $SPEC_PATH_COUNT -gt 0 ]; then
        echo "$SPEC_PATHS" | sed 's/^/      - /'
    fi

    echo ""
    echo "   🛠️  实际实现端点 ($BACKEND_ROUTE_COUNT 个):"
    if [ $BACKEND_ROUTE_COUNT -gt 0 ]; then
        echo "$BACKEND_ROUTES" | sed 's/^/      - /'
    fi

    echo ""

    # 覆盖率估算
    if [ $SPEC_PATH_COUNT -gt 0 ]; then
        coverage=$((BACKEND_ROUTE_COUNT * 100 / SPEC_PATH_COUNT))
        if [ $coverage -gt 80 ]; then
            echo "   ✅ 路由覆盖率约 ${coverage}%"
        elif [ $coverage -gt 50 ]; then
            echo "   🟡 P1: 路由覆盖率约 ${coverage}%，建议补充"
            TOTAL_P1=$((TOTAL_P1 + 1))
            ISSUES+=("路由覆盖率不足:${coverage}%")
        else
            echo "   🔴 P0: 路由覆盖率仅 ${coverage}%，严重不足"
            TOTAL_P0=$((TOTAL_P0 + 1))
            ISSUES+=("路由覆盖率严重不足:${coverage}%")
        fi
    fi

    echo ""
}

# ==============================================================================
# 4. 错误码一致性检查
# ==============================================================================
check_error_codes() {
    echo "🔍 4/4 错误码一致性检查..."
    echo "───────────────────────────────────────────────────────────────"

    if [ ! -f "$SPEC_FILE" ]; then
        echo "   ⚠️  跳过：缺少 Spec 文件"
        echo ""
        return
    fi

    # 从 Spec 提取错误响应码
    SPEC_ERRORS=$(grep -n "4[0-9][0-9]\|5[0-9][0-9]" "$SPEC_FILE" 2>/dev/null | head -20)
    SPEC_ERROR_COUNT=$(echo "$SPEC_ERRORS" | grep -v '^$' | wc -l | tr -d ' ')

    # 从后端提取实际使用的错误码
    BACKEND_ERRORS=""
    if [ -d "backend/src" ]; then
        BACKEND_ERRORS=$(grep -rn "StatusCode\|HttpResponse\|ErrorResponse" backend/src --include="*.rs" 2>/dev/null | \
                        head -20)
    fi

    BACKEND_ERROR_COUNT=$(echo "$BACKEND_ERRORS" | grep -v '^$' | wc -l | tr -d ' ')

    if [ $SPEC_ERROR_COUNT -gt 0 ]; then
        echo "   ✅ Spec 中定义了错误响应码"
    else
        echo "   🟢 P2: Spec 建议定义错误响应码"
        TOTAL_P2=$((TOTAL_P2 + 1))
    fi

    if [ $BACKEND_ERROR_COUNT -gt 0 ]; then
        echo "   ✅ 后端代码使用了错误响应"
    else
        echo "   🟢 P2: 建议统一错误响应格式"
        TOTAL_P2=$((TOTAL_P2 + 1))
    fi

    echo ""
}

# ==============================================================================
# 输出最终结果
# ==============================================================================
print_final_result() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                   📊 契约检查结果汇总                             ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    printf "║  🔴 P0 级严重问题:  %-3d 个 【阻塞联调】                       ║\n" $TOTAL_P0
    printf "║  🟡 P1 级警告问题:  %-3d  个 【建议修复】                       ║\n" $TOTAL_P1
    printf "║  🟢 P2 级建议优化:  %-3d  个 【技术债务】                       ║\n" $TOTAL_P2
    echo "╠════════════════════════════════════════════════════════════════╣"

    if [ ${#ISSUES[@]} -gt 0 ]; then
        echo "║  📋 问题详情:                                                    ║"
        for issue in "${ISSUES[@]}"; do
            printf "║     - %s\n" "$issue"
        done
    fi

    echo "╠════════════════════════════════════════════════════════════════╣"

    if [ $TOTAL_P0 -gt 0 ]; then
        echo "║  ❌ 结论：存在 P0 级问题，必须修复后才能开始联调！                ║"
    elif [ $TOTAL_P1 -gt 0 ]; then
        echo "║  ⚠️  结论：存在 P1 级问题，建议修复后再联调                       ║"
    else
        echo "║  ✅ 结论：API 契约一致性检查通过！                                ║"
    fi

    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "💡 生成前端类型命令:"
    echo "   npx openapi-typescript $SPEC_FILE -o $FRONTEND_TYPES"
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
check_spec_exists
check_frontend_types
check_backend_routes
check_error_codes
print_final_result
