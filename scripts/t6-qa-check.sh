#!/bin/bash
# ==============================================================================
# T6 QA 测试通过检查 v4.0
# ==============================================================================

echo "🧪 T6 QA 测试检查"
echo "═══════════════════════════════════════"
echo ""

P0_BUGS=0
P1_BUGS=0
P2_BUGS=0

echo "📋 Bug 统计:"
read -p "   P0 阻断级 Bug 数量: " P0_BUGS
read -p "   P1 严重级 Bug 数量: " P1_BUGS
read -p "   P2 一般级 Bug 数量: " P2_BUGS

echo ""
echo "🧪 测试覆盖:"
read -p "   核心流程测试通过率（%）: " CORE_PASS_RATE
read -p "   端到端测试是否通过？(y/n): " E2E_PASS

echo ""
echo "🔒 安全扫描:"
read -p "   安全扫描是否通过（无 Critical）？(y/n): " SECURITY_PASS

echo ""
echo "═══════════════════════════════════════"
echo "📊 检查结果:"
echo "   P0 阻断: $P0_BUGS"
echo "   P1 严重: $P1_BUGS"
echo "   P2 一般: $P2_BUGS"
echo "   核心流程通过率: $CORE_PASS_RATE%"
echo "   E2E 测试: $E2E_PASS"
echo "   安全扫描: $SECURITY_PASS"
echo ""

# 判断逻辑
FAIL=0
WARN=0

if [ "$P0_BUGS" -gt 0 ]; then
    echo "🔴 存在 P0 阻断级 Bug，必须修复！"
    FAIL=$((FAIL + 1))
fi

if [ "$P1_BUGS" -gt 3 ]; then
    echo "🟡 P1 Bug 超过 3 个，建议优先修复"
    WARN=$((WARN + 1))
fi

if [ "$CORE_PASS_RATE" -lt 95 ]; then
    echo "🔴 核心流程测试通过率 < 95%，不达标！"
    FAIL=$((FAIL + 1))
fi

if [[ ! "$E2E_PASS" =~ ^[Yy]$ ]]; then
    echo "🟡 E2E 测试未通过，建议修复"
    WARN=$((WARN + 1))
fi

if [[ ! "$SECURITY_PASS" =~ ^[Yy]$ ]]; then
    echo "🔴 安全扫描不通过，必须修复！"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "═══════════════════════════════════════"

if [ $FAIL -gt 0 ]; then
    echo "🔴 结果: ❌ 不通过"
    echo "   请修复 $FAIL 项阻断性问题后重试"
    echo ""
    exit 1
elif [ $WARN -gt 0 ]; then
    echo "🟡 结果: ⚠️  有风险，建议修复后继续"
    echo ""
    exit 2
else
    echo "🟢 结果: ✅ 通过，可以进入 T7 文档阶段"
    echo ""
    exit 0
fi
