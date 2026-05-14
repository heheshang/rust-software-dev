#!/bin/bash
# ==============================================================================
# T4 开发完成自检 v4.0
# ==============================================================================

echo "💻 T4 开发完成自检"
echo "═══════════════════════════════════════"
echo ""

PASS=0
WARN=0
FAIL=0

echo "🔍 后端检查:"
if [ -d "backend/src" ]; then
    # 编译检查
    echo "   运行 cargo check..."
    if cd backend && cargo check 2>/dev/null; then
        echo "   ✅ 编译通过"
        PASS=$((PASS + 1))
    else
        echo "   ❌ 编译失败"
        FAIL=$((FAIL + 1))
    fi
    cd -

    # 测试检查
    echo "   运行 cargo test..."
    if cargo test --no-run 2>/dev/null; then
        echo "   ✅ 测试编译通过"
        PASS=$((PASS + 1))
    fi
else
    echo "   ⚠️  未检测到后端代码"
    WARN=$((WARN + 1))
fi

echo ""
echo "🔍 前端检查:"
if [ -d "frontend/src" ]; then
    # 类型检查
    if [ -f "frontend/package.json" ]; then
        echo "   运行 TypeScript 检查..."
        if cd frontend && npm run type-check 2>/dev/null || npx tsc --noEmit 2>/dev/null; then
            echo "   ✅ 类型检查通过"
            PASS=$((PASS + 1))
        else
            echo "   ⚠️  类型检查有问题（或需先 npm i）"
            WARN=$((WARN + 1))
        fi
        cd ..
    fi
else
    echo "   ⚠️  未检测到前端代码"
    WARN=$((WARN + 1))
fi

echo -
cd -
echo ""
echo "═══════════════════════════════════════"
echo "📊 检查结果:"
echo "   ✅ 通过: $PASS 项"
echo "   ⚠️  警告: $WARN 项"
echo "   ❌ 失败: $FAIL 项"
echo ""

if [ $FAIL -gt 0 ]; then
    echo "🔴 结果: ❌ 不通过"
    echo "   请修复编译错误后继续"
    exit 1
elif [ $PASS -ge 2 ]; then
    echo "🟢 结果: ✅ 通过"
    exit 0
else
    echo "🟡 结果: ⚠️  基本通过，建议完整测试后进入联调"
    exit 2
fi
