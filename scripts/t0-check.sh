#!/bin/bash
# ==============================================================================
# T0 需求门禁检查 v4.0
# 用途：过滤说不清、道不明、做不了的需求
# ==============================================================================

echo "🔍 T0 需求门禁检查"
echo "═══════════════════════════════════════"
echo ""

SCORE=0
P0_FAIL=0
WARNINGS=0

echo "📋 请回答以下问题（y/n）："
echo ""

# P0 检查项（一票否决）
read -p "1. 功能范围能用一句话说清楚？(y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    SCORE=$((SCORE + 25))
    echo "   ✅ 通过 (+25分)"
else
    P0_FAIL=1
    echo "   ❌ 不通过 - 请先明确核心功能范围"
fi

read -p "2. 目标用户角色明确（谁在用）？(y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    SCORE=$((SCORE + 20))
    echo "   ✅ 通过 (+20分)"
else
    P0_FAIL=1
    echo "   ❌ 不通过 - 请明确谁是目标用户"
fi

# P1 检查项
read -p "3. 边界清晰（明确什么不做）？(y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    SCORE=$((SCORE + 15))
    echo "   ✅ 通过 (+15分)"
else
    WARNINGS=$((WARNINGS + 1))
    echo "   ⚠️  建议补充 - 边界不清会导致范围蔓延"
fi

read -p "4. 数据来源和流向明确？(y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    SCORE=$((SCORE + 15))
    echo "   ✅ 通过 (+15分)"
else
    WARNINGS=$((WARNINGS + 1))
    echo "   ⚠️  建议补充 - 数据问题到 T2 才发现会很麻烦"
fi

# P2 检查项
read -p "5. 有非功能需求（性能/安全/可用性）？(y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    SCORE=$((SCORE + 10))
    echo "   ✅ 通过 (+10分)"
else
    echo "   ℹ️  建议补充 - 非功能需求上线后补成本很高"
fi

read -p "6. 依赖关系明确？(y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    SCORE=$((SCORE + 10))
    echo "   ✅ 通过 (+10分)"
else
    echo "   ℹ️  建议确认 - 避免开发到一半才发现依赖其他功能"
fi

read -p "7. 验收标准可量化？(y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    SCORE=$((SCORE + 5))
    echo "   ✅ 通过 (+5分)"
else
    echo "   ℹ️  建议补充 - 可量化的验收标准避免上线时扯皮"
fi

echo ""
echo "═══════════════════════════════════════"
echo "📊 最终得分: $SCORE / 100"
echo ""

# 判断结果
if [ $P0_FAIL -eq 1 ]; then
    echo "🔴 结果: ❌ 不通过"
    echo "   P0 项未达标，请先明确需求范围和用户角色"
    echo ""
    exit 1
elif [ $SCORE -ge 70 ]; then
    echo "🟢 结果: ✅ 通过，可以进入 T1-T9 流水线"
    echo "   💡 得分: $SCORE，建议继续完善低分项"
    echo ""
    exit 0
elif [ $SCORE -ge 50 ]; then
    echo "🟡 结果: ⚠️  有风险 ($SCORE < 70)，需要用户确认是否继续"
    echo "   请确认后重新运行，或补充需求信息后重试"
    echo ""
    exit 2  # 有风险，需要人工确认
else
    echo "🔴 结果: ❌ 不通过，需求信息太模糊"
    echo "   请补充完整需求后重新评估"
    echo ""
    exit 1
fi
