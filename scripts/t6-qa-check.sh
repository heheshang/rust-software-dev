#!/bin/bash
# ==============================================================================
# T6 QA 测试通过检查 v4.1（自动化版）
# ==============================================================================

PROJECT_ROOT=${1:-.}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECURITY_REPORT="$PROJECT_ROOT/docs/qa/Security-Scan-Report-$(date +%Y%m%d).md"

echo "🧪 T6 QA 测试自动化检查"
echo "═══════════════════════════════════════"
echo ""

FAIL=0
WARN=0
PASS=0

# ==============================================================================
# 1. 安全扫描（调用已自动化的 security-scan.sh）
# ==============================================================================
echo "🔒 1/4 安全扫描..."
if [ -x "$SCRIPT_DIR/security-scan.sh" ]; then
    SECURITY_RESULT=$(bash "$SCRIPT_DIR/security-scan.sh" "$PROJECT_ROOT" 2>&1)
    SECURITY_EXIT=$?

    # 从报告文件读取 Critical 数量
    if [ -f "$SECURITY_REPORT" ]; then
        CRITICAL=$(grep -oP "🔴 严重 \(Critical\) \| \K\d+" "$SECURITY_REPORT" 2>/dev/null || echo "0")
        HIGH=$(grep -oP "🟡 高危 \(High\) \| \K\d+" "$SECURITY_REPORT" 2>/dev/null || echo "0")
    else
        CRITICAL=0
        HIGH=0
    fi

    if [ "$CRITICAL" -gt 0 ]; then
        echo "   ❌ 安全扫描: 发现 $CRITICAL 个 Critical 漏洞"
        FAIL=$((FAIL + 1))
    elif [ "$HIGH" -gt 3 ]; then
        echo "   ⚠️  安全扫描: $HIGH 个高危漏洞（> 3）"
        WARN=$((WARN + 1))
    else
        echo "   ✅ 安全扫描: 无 Critical / 高危漏洞 ≤ 3"
        PASS=$((PASS + 1))
    fi
else
    echo "   ⚠️  security-scan.sh 不存在，跳过安全扫描"
    WARN=$((WARN + 1))
fi

# ==============================================================================
# 2. 后端测试（cargo test）
# ==============================================================================
echo ""
echo "🧪 2/4 后端测试..."

if [ -d "$PROJECT_ROOT/backend" ]; then
    cd "$PROJECT_ROOT/backend"
    if cargo test --quiet 2>&1 | tee /tmp/cargo_test_output.txt; then
        echo "   ✅ cargo test: 全部通过"
        PASS=$((PASS + 1))
    else
        echo "   ❌ cargo test: 有测试失败"
        FAIL=$((FAIL + 1))
    fi
    cd "$PROJECT_ROOT"
else
    echo "   ⚠️  未找到 backend 目录"
    WARN=$((WARN + 1))
fi

# ==============================================================================
# 3. 前端测试（vitest / jest）
# ==============================================================================
echo ""
echo "🧪 3/4 前端测试..."

if [ -d "$PROJECT_ROOT/frontend" ]; then
    cd "$PROJECT_ROOT/frontend"

    if [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ]; then
        if npx vitest run --reporter=basic 2>&1 | tee /tmp/vitest_output.txt; then
            echo "   ✅ Vitest: 全部通过"
            PASS=$((PASS + 1))
        else
            echo "   ❌ Vitest: 有测试失败"
            FAIL=$((FAIL + 1))
        fi
    elif [ -f "jest.config.js" ] || [ -f "jest.config.ts" ]; then
        if npx jest --passWithNoTests 2>&1 | tee /tmp/jest_output.txt; then
            echo "   ✅ Jest: 全部通过"
            PASS=$((PASS + 1))
        else
            echo "   ❌ Jest: 有测试失败"
            FAIL=$((FAIL + 1))
        fi
    else
        echo "   ⚠️  未检测到 vitest/jest 配置，跳过前端测试"
        WARN=$((WARN + 1))
    fi

    cd "$PROJECT_ROOT"
else
    echo "   ⚠️  未找到 frontend 目录"
    WARN=$((WARN + 1))
fi

# ==============================================================================
# 4. API 冒烟测试（curl 健康检查）
# ==============================================================================
echo ""
echo "🚀 4/4 API 冒烟测试..."

SMOKE_FAIL=0
SMOKE_PASS=0

# 读取后端端口配置（尝试从 backend 配置推断，默认 8080）
API_BASE=${API_BASE:-"http://localhost:8080"}

# 常见健康检查端点
for endpoint in "/health" "/api/health" "/api/v1/health"; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$API_BASE$endpoint" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "204" ]; then
        echo "   ✅ $endpoint → $HTTP_CODE"
        SMOKE_PASS=$((SMOKE_PASS + 1))
    else
        echo "   ⚠️  $endpoint → $HTTP_CODE"
    fi
done

if [ "$SMOKE_PASS" -eq 0 ]; then
    echo "   ⚠️  所有健康检查端点均无响应（服务可能未启动，跳过）"
    WARN=$((WARN + 1))
else
    echo "   ✅ API 冒烟测试: $SMOKE_PASS/$((SMOKE_PASS + SMOKE_FAIL)) 端点正常"
    PASS=$((PASS + 1))
fi

# ==============================================================================
# 最终判定
# ==============================================================================
echo ""
echo "═══════════════════════════════════════"
echo "📊 检查结果:"
echo "   ✅ 通过: $PASS 项"
echo "   ⚠️  警告: $WARN 项"
echo "   ❌ 失败: $FAIL 项"
echo ""

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
    echo "🟢 结果: ✅ 通过，可进入 T7 文档阶段"
    echo ""
    exit 0
fi
