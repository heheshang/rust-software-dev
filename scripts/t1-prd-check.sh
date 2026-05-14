#!/bin/bash
# ==============================================================================
# T1 PRD 完整性检查 v4.0
# ==============================================================================

echo "📝 T1 PRD 完整性检查"
echo "═══════════════════════════════════════"
echo ""

PASS=0
WARN=0
FAIL=0

# 检查文件是否存在
if [ ! -f "docs/prd/PRD-*.md" ] 2>/dev/null; then
    echo "❌ 未找到 PRD 文档 (docs/prd/PRD-*.md)"
    echo ""
    exit 1
fi

PRD_FILE=$(ls docs/prd/PRD-*.md | head -1)
echo "📄 检查文件: $PRD_FILE"
echo ""

# 检查项
check_item() {
    local keyword=$1
    local desc=$2
    local level=$3

    if grep -q "$keyword" "$PRD_FILE"; then
        echo "   ✅ $desc"
        PASS=$((PASS + 1))
    else
        if [ "$level" = "P0" ]; then
            echo "   ❌ $desc [P0 - 必须有]"
            FAIL=$((FAIL + 1))
        else
            echo "   ⚠️  $desc [建议补充]"
            WARN=$((WARN + 1))
        fi
    fi
}

echo "🔍 检查内容:"
check_item "功能背景" "功能背景/动机" "P0"
check_item "用户角色" "用户角色定义" "P0"
check_item "功能说明\|功能描述" "功能说明描述" "P0"
check_item "边界\|不包含" "边界/不做范围定义" "P1"
check_item "数据来源\|数据模型" "数据来源/流向说明" "P1"
check_item "异常场景\|错误处理" "异常场景说明" "P1"
check_item "验收标准\|Acceptance" "验收标准定义" "P0"
check_item "Gherkin\|Given\|When\|Then" "Gherkin 场景描述" "P1"

echo ""
echo "═══════════════════════════════════════"
echo "📊 检查结果:"
echo "   ✅ 通过: $PASS 项"
echo "   ⚠️  建议: $WARN 项"
echo "   ❌ 缺失: $FAIL 项"
echo ""

if [ $FAIL -gt 0 ]; then
    echo "🔴 结果: ❌ 不通过"
    echo "   请补充 $FAIL 项 P0 级必需内容"
    echo ""
    exit 1
elif [ $WARN -gt 2 ]; then
    echo "🟡 结果: ⚠️  有风险，建议补充完整后继续"
    echo ""
    exit 2
else
    echo "🟢 结果: ✅ 通过"
    echo ""
    exit 0
fi
