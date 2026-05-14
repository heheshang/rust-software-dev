#!/bin/bash
# ==============================================================================
# T3 技术设计完整性检查 v4.0
# ==============================================================================

echo "🏗️  T3 技术设计完整性检查"
echo "═══════════════════════════════════════"
echo ""

PASS=0
WARN=0
FAIL=0

# 后端设计
echo "🔍 后端技术设计:"
if [ -f "docs/architecture/TechDesign-Backend.md" ]; then
    echo "   ✅ 后端 TechDesign 存在"
    PASS=$((PASS + 1))

    check_item() {
        if grep -q "$1" "docs/architecture/TechDesign-Backend.md"; then
            echo "   ✅ $2"
            PASS=$((PASS + 1))
        else
            echo "   ⚠️  建议补充: $2"
            WARN=$((WARN + 1))
        fi
    }

    check_item "API 设计\|接口设计" "API 设计"
    check_item "数据模型\|数据库\|Entity" "数据模型设计"
    check_item "状态机\|状态流转" "状态机定义"
else
    echo "   ⚠️  未找到后端 TechDesign 文档"
    WARN=$((WARN + 3))
fi

echo ""

# 前端设计
echo "🔍 前端技术设计:"
if [ -f "docs/architecture/TechDesign-Frontend.md" ]; then
    echo "   ✅ 前端 TechDesign 存在"
    PASS=$((PASS + 1))

    check_item() {
        if grep -q "$1" "docs/architecture/TechDesign-Frontend.md"; then
            echo "   ✅ $2"
            PASS=$((PASS + 1))
        else
            echo "   ⚠️  建议补充: $2"
            WARN=$((WARN + 1))
        fi
    }

    check_item "组件设计\|页面结构" "组件设计"
    check_item "状态管理\|Store" "状态管理设计"
    check_item "类型定义\|TypeScript" "类型定义"
else
    echo "   ⚠️  未找到前端 TechDesign 文档"
    WARN=$((WARN + 3))
fi

echo ""
echo "═══════════════════════════════════════"
echo "📊 检查结果:"
echo "   ✅ 通过: $PASS 项"
echo "   ⚠️  建议: $WARN 项"
echo ""

if [ $FAIL -gt 0 ]; then
    echo "🔴 结果: ❌ 不通过"
    exit 1
elif [ $PASS -ge 5 ]; then
    echo "🟢 结果: ✅ 通过"
    exit 0
else
    echo "🟡 结果: ⚠️  基本通过，建议补充完整后开始开发"
    exit 2
fi
