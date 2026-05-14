#!/bin/bash
# ==============================================================================
# API 契约变更影响分析 v1.0
# 用途：T2 架构设计阶段分析 Spec 变更影响范围
# 用法：./contract-change-impact.sh [project_root]
# ==============================================================================

set -e

PROJECT_ROOT=${1:-.}

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║             📊 API 契约变更影响分析 v1.0                         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📂 项目根目录: $PROJECT_ROOT"
echo "📅 分析时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

cd "$PROJECT_ROOT"

SPEC_FILE="docs/api/OpenAPI-3.0-spec.yaml"
SPEC_BACKUP="docs/api/OpenAPI-3.0-spec.yaml.bak"

if [ ! -f "$SPEC_FILE" ]; then
    echo "⚠️  未找到 OpenAPI Spec 文件: $SPEC_FILE"
    echo "   请先创建 API 契约规范"
    exit 0
fi

# ==============================================================================
# 检查是否有备份文件
# ==============================================================================
if [ ! -f "$SPEC_BACKUP" ]; then
    echo "ℹ️  未找到上一版本 Spec 备份"
    echo ""
    echo "   正在为当前版本创建备份..."
    cp "$SPEC_FILE" "$SPEC_BACKUP"
    echo "   ✅ 备份已创建: $SPEC_BACKUP"
    echo ""
    echo "📝 使用说明:"
    echo "   修改 $SPEC_FILE 文件后，再次运行此脚本查看变更影响"
    exit 0
fi

# ==============================================================================
# 对比新旧版本
# ==============================================================================
echo "🔍 检测 API 契约变更..."
echo "───────────────────────────────────────────────────────────────"

# 提取新旧版本的路径
OLD_PATHS=$(grep -E "^  [/a-zA-Z0-9_{}]+" "$SPEC_BACKUP" | sed 's/^  //' | sed 's/:$//' | sort)
NEW_PATHS=$(grep -E "^  [/a-zA-Z0-9_{}]+" "$SPEC_FILE" | sed 's/^  //' | sed 's/:$//' | sort)

# 找出新增和删除的路径
ADDED_PATHS=$(comm -13 <(echo "$OLD_PATHS") <(echo "$NEW_PATHS"))
REMOVED_PATHS=$(comm -23 <(echo "$OLD_PATHS") <(echo "$NEW_PATHS"))

ADDED_COUNT=$(echo "$ADDED_PATHS" | grep -v '^$' | wc -l | tr -d ' ')
REMOVED_COUNT=$(echo "$REMOVED_PATHS" | grep -v '^$' | wc -l | tr -d ' ')

if [ $ADDED_COUNT -eq 0 ] && [ $REMOVED_COUNT -eq 0 ]; then
    echo "   ✅ 未检测到 API 路径变更"
else
    if [ $ADDED_COUNT -gt 0 ]; then
        echo "   ➕ 新增端点 ($ADDED_COUNT 个):"
        echo "$ADDED_PATHS" | grep -v '^$' | sed 's/^/      - /'
    fi

    if [ $REMOVED_COUNT -gt 0 ]; then
        echo "   ➖ 删除端点 ($REMOVED_COUNT 个):"
        echo "$REMOVED_PATHS" | grep -v '^$' | sed 's/^/      - /'
    fi
fi

echo ""

# ==============================================================================
# 前端影响分析
# ==============================================================================
echo "📱 前端影响范围分析..."
echo "───────────────────────────────────────────────────────────────"

IMPACTED_FRONTEND_FILES=0

if [ -d "frontend/src" ]; then
    for path in $ADDED_PATHS $REMOVED_PATHS; do
        # 简化路径用于搜索
        path_simple=$(echo "$path" | sed 's/[{].*[}]//g' | sed 's/\/$//')

        if [ -n "$path_simple" ] && [ "$path_simple" != "/" ]; then
            matches=$(grep -rl "$path_simple" frontend/src --include="*.ts" --include="*.tsx" --include="*.vue" 2>/dev/null | wc -l | tr -d ' ')
            if [ $matches -gt 0 ]; then
                echo "   📍 端点 $path_simple 影响 $matches 个前端文件"
                IMPACTED_FRONTEND_FILES=$((IMPACTED_FRONTEND_FILES + matches))
            fi
        fi
    done
fi

if [ $IMPACTED_FRONTEND_FILES -eq 0 ]; then
    echo "   ✅ 未检测到直接受影响的前端文件（可能需要重新生成类型）"
else
    echo ""
    echo "   📊 总计影响约 $IMPACTED_FRONTEND_FILES 个前端文件"
fi

echo ""

# ==============================================================================
# 后端影响分析
# ==============================================================================
echo "🔧 后端影响范围分析..."
echo "───────────────────────────────────────────────────────────────"

IMPACTED_BACKEND_FILES=0

if [ -d "backend/src" ]; then
    for path in $ADDED_PATHS $REMOVED_PATHS; do
        path_simple=$(echo "$path" | sed 's/[{].*[}]//g' | sed 's/\/$//')

        if [ -n "$path_simple" ] && [ "$path_simple" != "/" ]; then
            matches=$(grep -rl "$path_simple" backend/src --include="*.rs" 2>/dev/null | wc -l | tr -d ' ')
            if [ $matches -gt 0 ]; then
                echo "   📍 端点 $path_simple 影响 $matches 个后端文件"
                IMPACTED_BACKEND_FILES=$((IMPACTED_BACKEND_FILES + matches))
            fi
        fi
    done
fi

if [ $IMPACTED_BACKEND_FILES -eq 0 ]; then
    echo "   ✅ 未检测到直接受影响的后端文件"
else
    echo ""
    echo "   📊 总计影响约 $IMPACTED_BACKEND_FILES 个后端文件"
fi

echo ""

# ==============================================================================
# 影响评估
# ==============================================================================
echo "📋 变更影响评估"
echo "───────────────────────────────────────────────────────────────"

TOTAL_IMPACT=$((ADDED_COUNT + REMOVED_COUNT))
IMPACT_LEVEL="🟢 低"

if [ $TOTAL_IMPACT -gt 10 ]; then
    IMPACT_LEVEL="🔴 高"
elif [ $TOTAL_IMPACT -gt 5 ]; then
    IMPACT_LEVEL="🟡 中"
fi

echo "   变更影响级别: $IMPACT_LEVEL"
echo "   变更端点数量: $TOTAL_IMPACT 个"
echo "   影响前端文件: 约 $IMPACTED_FRONTEND_FILES 个"
echo "   影响后端文件: 约 $IMPACTED_BACKEND_FILES 个"

echo ""

# ==============================================================================
# 建议
# ==============================================================================
echo "💡 操作建议"
echo "───────────────────────────────────────────────────────────────"

if [ $ADDED_COUNT -gt 0 ]; then
    echo "   ✅ 新增端点需要:"
    echo "      - [ ] 后端实现新的路由和处理逻辑"
    echo "      - [ ] 重新生成前端 TypeScript 类型"
    echo "      - [ ] 前端创建新的 API 调用函数"
    echo "      - [ ] 添加相应的单元测试和集成测试"
fi

if [ $REMOVED_COUNT -gt 0 ]; then
    echo "   ❌ 删除端点需要:"
    echo "      - [ ] 后端删除相应路由和处理函数"
    echo "      - [ ] 前端清理废弃的 API 调用代码"
    echo "      - [ ] 检查并更新相关的测试用例"
    echo "      - [ ] 确保向后兼容性（如需要）"
fi

echo ""
echo "   🔄 通用建议:"
echo "      - [ ] 更新 Pact 契约测试"
echo "      - [ ] 运行 ./scripts/contract-validation.sh 验证一致性"
echo "      - [ ] 更新 API 文档"
echo "      - [ ] 通知前后端团队变更内容"

echo ""

# ==============================================================================
# 更新备份
# ==============================================================================
read -p "❓ 是否更新备份文件以便下次对比? (Y/n): " update_backup
if [ "$update_backup" != "n" ] && [ "$update_backup" != "N" ]; then
    cp "$SPEC_FILE" "$SPEC_BACKUP"
    echo "   ✅ 备份已更新"
fi

echo ""
