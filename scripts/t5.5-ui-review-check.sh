#!/bin/bash
# ==============================================================================
# T5.5 UI 走查检查 v4.0
# ==============================================================================

echo "🎨 T5.5 UI 走查检查"
echo "═══════════════════════════════════════"
echo ""

echo "📋 走查清单确认:"
echo ""

PASS=0
FAIL=0
WARN=0

check_item() {
    local desc=$1
    local level=$2

    read -p "   $desc？(y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "      ✅ 通过"
        PASS=$((PASS + 1))
    else
        if [ "$level" = "P0" ]; then
            echo "      ❌ 不通过 [P0]"
            FAIL=$((FAIL + 1))
        else
            echo "      ⚠️  待优化 [P1]"
            WARN=$((WARN + 1))
        fi
    fi
    echo ""
}

check_item "核心页面还原度 ≥ 90%" "P0"
check_item "交互符合设计规范" "P1"
check_item "空状态/错误状态已实现" "P1"
check_item "响应式适配正常" "P2"
check_item "产品已确认走查通过" "P0"

echo "═══════════════════════════════════════"
echo "📊 走查结果:"
echo "   ✅ 通过: $PASS 项"
echo "   ⚠️  待优化: $WARN 项"
echo "   ❌ 不通过: $FAIL 项"
echo ""

if [ $FAIL -gt 0 ]; then
    echo "🔴 结果: ❌ 不通过"
    echo "   请修复 P0 问题后再走查"
    echo ""
    exit 1
elif [ $PASS -ge 4 ]; then
    echo "🟢 结果: ✅ 通过，可以进入 QA 测试"
    echo ""
    exit 0
else
    echo "🟡 结果: ⚠️  有风险，建议继续优化"
    echo ""
    exit 2
fi
