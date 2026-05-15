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

    # 测试检查（真正运行，不只是编译）
    echo "   运行 cargo test..."
    if cargo test 2>/dev/null; then
        echo "   ✅ 单元测试通过"
        PASS=$((PASS + 1))
    else
        echo "   ❌ 单元测试失败"
        FAIL=$((FAIL + 1))
    fi

    # 覆盖率检查（仅后端有要求 ≥70%）
    if command -v cargo-llvm-cov &>/dev/null; then
        echo "   检查覆盖率..."
        COV=$(cargo llvm-cov --quiet --json 2>/dev/null | grep '"pct":' | tail -1 | grep -o '"pct":[0-9.]*' | cut -d: -f2)
        if [ -n "$COV" ] && [ "$(echo "$COV >= 70" | bc 2>/dev/null)" = "1" ]; then
            echo "   ✅ 覆盖率 ${COV}% ≥ 70%"
            PASS=$((PASS + 1))
        elif [ -n "$COV" ]; then
            echo "   ⚠️  覆盖率 ${COV}% < 70%（P1 要求）"
            WARN=$((WARN + 1))
        fi
    else
        echo "   ⚠️  cargo-llvm-cov 未安装，无法验证覆盖率"
        WARN=$((WARN + 1))
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

        # 单元测试检查
        echo "   运行前端单元测试..."
        if [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ]; then
            if npx vitest run --reporter=basic 2>/dev/null; then
                echo "   ✅ Vitest 测试通过"
                PASS=$((PASS + 1))
            else
                echo "   ❌ Vitest 测试失败"
                FAIL=$((FAIL + 1))
            fi
        elif [ -f "jest.config.js" ] || [ -f "jest.config.ts" ]; then
            if npx jest --passWithNoTests 2>/dev/null; then
                echo "   ✅ Jest 测试通过"
                PASS=$((PASS + 1))
            else
                echo "   ❌ Jest 测试失败"
                FAIL=$((FAIL + 1))
            fi
        else
            echo "   ⚠️  未检测到 vitest/jest 配置，跳过前端测试"
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
