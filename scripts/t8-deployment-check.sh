#!/bin/bash
# ==============================================================================
# T8 部署健康检查 v4.0
# ==============================================================================

echo "🚀 T8 部署健康检查"
echo "═══════════════════════════════════════"
echo ""

PASS=0
WARN=0
FAIL=0

# 配置文件检查
echo "🔍 配置文件检查:"
if [ -f "docker-compose.yml" ] || [ -f "Dockerfile" ]; then
    echo "   ✅ 部署配置文件存在"
    PASS=$((PASS + 1))
else
    echo "   ⚠️  未检测到 Docker 配置文件"
    WARN=$((WARN + 1))
fi

# nginx 配置检查
if [ -f "nginx.conf" ] || [ -f "docker/nginx.conf" ]; then
    echo "   ✅ Nginx 配置存在"
    PASS=$((PASS + 1))
fi

echo ""
echo "🔍 环境变量检查:"
if [ -f ".env.example" ]; then
    echo "   ✅ .env.example 示例文件存在"
    PASS=$((PASS + 1))
else
    echo "   ⚠️  缺少 .env.example 示例文件"
    WARN=$((WARN + 1))
fi

echo ""
echo "🔍 健康检查配置:"
if grep -r "healthcheck\|HEALTH_CHECK" . --include="*.yml" --include="*.yaml" -q 2>/dev/null; then
    echo "   ✅ 健康检查已配置"
    PASS=$((PASS + 1))
else
    echo "   ⚠️  建议配置健康检查"
    WARN=$((WARN + 1))
fi

echo ""
echo "═══════════════════════════════════════"
echo "📊 检查结果:"
echo "   ✅ 通过: $PASS 项"
echo "   ⚠️  建议: $WARN 项"
echo ""

if [ $PASS -ge 3 ]; then
    echo "🟢 结果: ✅ 通过，可以进入 T9 最终评审"
    echo ""
    exit 0
else
    echo "🟡 结果: ⚠️  基本通过，建议完善部署配置"
    echo ""
    exit 2
fi
