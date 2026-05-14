#!/bin/bash
# ==============================================================================
# 全栈安全扫描工具 v1.0
# 用途：T6 阶段强制执行，覆盖后端/前端/依赖/代码四个维度
# 用法：./security-scan.sh [project_root]
# ==============================================================================

set -e

PROJECT_ROOT=${1:-.}
REPORT_DIR="$PROJECT_ROOT/docs/qa"
REPORT_FILE="$REPORT_DIR/Security-Scan-Report-$(date +%Y%m%d).md"

mkdir -p "$REPORT_DIR"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    🔒 全栈安全扫描 v1.0                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📂 项目根目录: $PROJECT_ROOT"
echo "📅 扫描时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# ==============================================================================
# 全局统计变量
# ==============================================================================
TOTAL_CRITICAL=0
TOTAL_HIGH=0
TOTAL_MEDIUM=0
TOTAL_LOW=0

declare -a CRITICAL_ISSUES
declare -a HIGH_ISSUES
declare -a MEDIUM_ISSUES
declare -a LOW_ISSUES

# ==============================================================================
# 工具 1: Rust 依赖漏洞扫描 (cargo audit)
# ==============================================================================
scan_rust_dependencies() {
    echo "🔍 1/5 Rust 依赖漏洞扫描 (cargo audit)"
    echo "───────────────────────────────────────────────────────────────"

    if [ ! -d "$PROJECT_ROOT/backend" ]; then
        echo "   ⚠️  未找到 backend 目录，跳过"
        echo ""
        return
    fi

    cd "$PROJECT_ROOT/backend"

    if ! command -v cargo-audit &> /dev/null; then
        echo "   ⚠️  cargo-audit 未安装，正在安装..."
        cargo install cargo-audit 2>/dev/null || echo "   ❌ 安装失败，跳过此项"
        echo ""
        cd "$PROJECT_ROOT"
        return
    fi

    local audit_output=$(cargo audit 2>&1)
    local critical_count=$(echo "$audit_output" | grep -i "critical\|严重" | wc -l)
    local high_count=$(echo "$audit_output" | grep -i "high\|高危" | wc -l)
    local medium_count=$(echo "$audit_output" | grep -i "medium\|中危" | wc -l)

    TOTAL_CRITICAL=$((TOTAL_CRITICAL + critical_count))
    TOTAL_HIGH=$((TOTAL_HIGH + high_count))
    TOTAL_MEDIUM=$((TOTAL_MEDIUM + medium_count))

    if [ $critical_count -gt 0 ]; then
        echo "   🔴 发现 $critical_count 个严重漏洞!"
        CRITICAL_ISSUES+=("Rust 依赖: $critical_count 个严重漏洞")
    elif [ $high_count -gt 0 ]; then
        echo "   🟡 发现 $high_count 个高危漏洞"
        HIGH_ISSUES+=("Rust 依赖: $high_count 个高危漏洞")
    else
        echo "   ✅ 依赖安全，未发现漏洞"
    fi

    cd "$PROJECT_ROOT"
    echo ""
}

# ==============================================================================
# 工具 2: NPM 依赖漏洞扫描 (npm audit)
# ==============================================================================
scan_npm_dependencies() {
    echo "🔍 2/5 NPM 依赖漏洞扫描 (npm audit)"
    echo "───────────────────────────────────────────────────────────────"

    if [ ! -d "$PROJECT_ROOT/frontend" ]; then
        echo "   ⚠️  未找到 frontend 目录，跳过"
        echo ""
        return
    fi

    cd "$PROJECT_ROOT/frontend"

    local audit_output=$(npm audit --json 2>&1)
    local critical_count=$(echo "$audit_output" | grep -o '"critical":[0-9]*' | cut -d: -f2)
    local high_count=$(echo "$audit_output" | grep -o '"high":[0-9]*' | cut -d: -f2)
    local moderate_count=$(echo "$audit_output" | grep -o '"moderate":[0-9]*' | cut -d: -f2)

    [ -z "$critical_count" ] && critical_count=0
    [ -z "$high_count" ] && high_count=0
    [ -z "$moderate_count" ] && moderate_count=0

    TOTAL_CRITICAL=$((TOTAL_CRITICAL + critical_count))
    TOTAL_HIGH=$((TOTAL_HIGH + high_count))
    TOTAL_MEDIUM=$((TOTAL_MEDIUM + moderate_count))

    if [ $critical_count -gt 0 ]; then
        echo "   🔴 发现 $critical_count 个严重漏洞!"
        CRITICAL_ISSUES+=("NPM 依赖: $critical_count 个严重漏洞")
    elif [ $high_count -gt 0 ]; then
        echo "   🟡 发现 $high_count 个高危漏洞"
        HIGH_ISSUES+=("NPM 依赖: $high_count 个高危漏洞")
    else
        echo "   ✅ 依赖安全，未发现漏洞"
    fi

    cd "$PROJECT_ROOT"
    echo ""
}

# ==============================================================================
# 工具 3: 硬编码密钥/密码扫描 (grep 模式匹配)
# ==============================================================================
scan_hardcoded_secrets() {
    echo "🔍 3/5 硬编码敏感信息扫描"
    echo "───────────────────────────────────────────────────────────────"

    local found_secrets=0
    local patterns=(
        "password\s*=\s*['\"][^'\"]+['\"]"
        "secret\s*=\s*['\"][^'\"]+['\"]"
        "api[_-]?key\s*=\s*['\"][^'\"]+['\"]"
        "private[_-]?key\s*=\s*['\"][^'\"]+['\"]"
        "token\s*=\s*['\"][a-fA-F0-9]\{32,64\}['\"]"
        "AWS_SECRET_ACCESS_KEY\s*=\s*['\"][^'\"]+['\"]"
        "DATABASE_URL\s*=\s*['\"]postgres.*:.*@"
        "bearer\s\+[a-fA-F0-9]\{32,\}"
    )

    for rs_file in $(find "$PROJECT_ROOT/backend/src" -name "*.rs" -type f 2>/dev/null); do
        for pattern in "${patterns[@]}"; do
            matches=$(grep -n -i "$pattern" "$rs_file" 2>/dev/null | grep -v "example\|sample\|test")
            if [ -n "$matches" ]; then
                echo "   ⚠️  $rs_file 可能包含硬编码敏感信息"
                found_secrets=$((found_secrets + 1))
                HIGH_ISSUES+=("硬编码密钥: $rs_file")
            fi
        done
    done

    for ts_file in $(find "$PROJECT_ROOT/frontend/src" -name "*.ts" -o -name "*.vue" -type f 2>/dev/null); do
        for pattern in "${patterns[@]}"; do
            matches=$(grep -n -i "$pattern" "$ts_file" 2>/dev/null | grep -v "example\|sample\|test")
            if [ -n "$matches" ]; then
                echo "   ⚠️  $ts_file 可能包含硬编码敏感信息"
                found_secrets=$((found_secrets + 1))
                HIGH_ISSUES+=("硬编码密钥: $ts_file")
            fi
        done
    done

    if [ $found_secrets -eq 0 ]; then
        echo "   ✅ 未发现硬编码的密钥/密码"
    fi

    TOTAL_HIGH=$((TOTAL_HIGH + found_secrets))
    echo ""
}

# ==============================================================================
# 工具 4: SQL 注入风险检测 (SeaORM raw sql)
# ==============================================================================
scan_sql_injection() {
    echo "🔍 4/5 SQL 注入风险检测"
    echo "───────────────────────────────────────────────────────────────"

    if [ ! -d "$PROJECT_ROOT/backend/src" ]; then
        echo "   ⚠️  未找到 backend/src 目录，跳过"
        echo ""
        return
    fi

    local risk_count=0

    # 检测拼接字符串的 raw sql
    while IFS= read -r -d '' rs_file; do
        # 查找 format! 拼接 SQL
        matches=$(grep -n "query.*format!\|raw.*format!\|execute.*format!" "$rs_file" 2>/dev/null | head -3)
        if [ -n "$matches" ]; then
            echo "   ⚠️  $rs_file 存在 SQL 拼接风险"
            echo "$matches" | sed 's/^/     /'
            risk_count=$((risk_count + 1))
            MEDIUM_ISSUES+=("SQL 注入风险: $rs_file")
        fi

        # 查找 format! 包含 SQL 关键字
        sql_keywords=$(grep -n 'format!.*"\(SELECT\|INSERT\|UPDATE\|DELETE\)' "$rs_file" 2>/dev/null | head -3)
        if [ -n "$sql_keywords" ]; then
            echo "   ⚠️  $rs_file 使用字符串拼接 SQL"
            echo "$sql_keywords" | sed 's/^/     /'
            risk_count=$((risk_count + 1))
        fi
    done < <(find "$PROJECT_ROOT/backend/src" -name "*.rs" -type f -print0 2>/dev/null)

    if [ $risk_count -eq 0 ]; then
        echo "   ✅ 未发现明显的 SQL 注入风险"
    else
        TOTAL_MEDIUM=$((TOTAL_MEDIUM + risk_count))
    fi

    echo ""
}

# ==============================================================================
# 工具 5: CORS 配置安全检查
# ==============================================================================
scan_cors_config() {
    echo "🔍 5/5 CORS 配置安全检查"
    echo "───────────────────────────────────────────────────────────────"

    if [ ! -d "$PROJECT_ROOT/backend/src" ]; then
        echo "   ⚠️  未找到 backend/src 目录，跳过"
        echo ""
        return
    fi

    local cors_issues=0

    # 查找允许所有来源的危险配置
    while IFS= read -r -d '' rs_file; do
        allow_all=$(grep -n "AllowAnyOrigin\|Origin::All\|\.any()" "$rs_file" 2>/dev/null | head -3)
        if [ -n "$allow_all" ]; then
            echo "   ⚠️  $rs_file CORS 配置过于宽松 (允许所有来源)"
            echo "$allow_all" | sed 's/^/     /'
            cors_issues=$((cors_issues + 1))
            LOW_ISSUES+=("CORS 配置宽松: $rs_file")
        fi
    done < <(find "$PROJECT_ROOT/backend/src" -name "*.rs" -type f -print0 2>/dev/null)

    if [ $cors_issues -eq 0 ]; then
        echo "   ✅ CORS 配置看起来合理"
    else
        TOTAL_LOW=$((TOTAL_LOW + cors_issues))
    fi

    echo ""
}

# ==============================================================================
# 生成安全报告
# ==============================================================================
generate_security_report() {
    echo "📋 生成安全扫描报告..."
    echo ""

    cat > "$REPORT_FILE" << EOF
# 🔒 全栈安全扫描报告

**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')
**扫描范围**: 全项目

## 风险汇总

| 风险等级 | 数量 | 处理优先级 |
|---------|------|----------|
| 🔴 严重 (Critical) | $TOTAL_CRITICAL | 立即修复，阻塞发布 |
| 🟡 高危 (High) | $TOTAL_HIGH | 本迭代修复，发布前必须审核 |
| 🟠 中危 (Medium) | $TOTAL_MEDIUM | 下个迭代修复 |
| 🟢 低危 (Low) | $TOTAL_LOW | 技术债务，择机修复 |

---

## 详细问题列表

### 🔴 严重问题 (Critical)

EOF

    if [ ${#CRITICAL_ISSUES[@]} -gt 0 ]; then
        for issue in "${CRITICAL_ISSUES[@]}"; do
            echo "- [ ] $issue" >> "$REPORT_FILE"
        done
    else
        echo "✅ 无严重问题" >> "$REPORT_FILE"
    fi

    cat >> "$REPORT_FILE" << EOF

---

### 🟡 高危问题 (High)

EOF

    if [ ${#HIGH_ISSUES[@]} -gt 0 ]; then
        for issue in "${HIGH_ISSUES[@]}"; do
            echo "- [ ] $issue" >> "$REPORT_FILE"
        done
    else
        echo "✅ 无高危问题" >> "$REPORT_FILE"
    fi

    cat >> "$REPORT_FILE" << EOF

---

### 🟠 中危问题 (Medium)

EOF

    if [ ${#MEDIUM_ISSUES[@]} -gt 0 ]; then
        for issue in "${MEDIUM_ISSUES[@]}"; do
            echo "- [ ] $issue" >> "$REPORT_FILE"
        done
    else
        echo "✅ 无中危问题" >> "$REPORT_FILE"
    fi

    cat >> "$REPORT_FILE" << EOF

---

### 🟢 低危问题 (Low)

EOF

    if [ ${#LOW_ISSUES[@]} -gt 0 ]; then
        for issue in "${LOW_ISSUES[@]}"; do
            echo "- [ ] $issue" >> "$REPORT_FILE"
        done
    else
        echo "✅ 无低危问题" >> "$REPORT_FILE"
    fi

    cat >> "$REPORT_FILE" << EOF

---

## 安全门禁判定

| 条件 | 状态 |
|------|------|
| 严重漏洞 = 0 | $([ $TOTAL_CRITICAL -eq 0 ] && echo "✅ 通过" || echo "❌ 未通过") |
| 高危漏洞 ≤ 3 | $([ $TOTAL_HIGH -le 3 ] && echo "✅ 通过" || echo "❌ 未通过") |

## 修复建议优先级

1. **立即修复**：所有 🔴 严重问题
2. **本次迭代修复**：所有 🟡 高危问题
3. **下个迭代修复**：所有 🟠 中危问题
4. **技术债务池**：所有 🟢 低危问题

## 审核签字

- [ ] 安全负责人已审核所有问题
- [ ] 严重/高危问题已有修复方案
- [ ] 同意本次发布（如问题在可控范围）

签字: _______________ 日期: ___________

---

*本报告由全栈安全扫描工具自动生成*
EOF

    echo "   ✅ 报告已生成: $REPORT_FILE"
    echo ""
}

# ==============================================================================
# 输出最终结果
# ==============================================================================
print_final_result() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                      📊 安全扫描结果汇总                          ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    printf "║  🔴 严重漏洞:  %-3d 个 【立即修复，阻塞发布】                   ║\n" $TOTAL_CRITICAL
    printf "║  🟡 高危漏洞:  %-3d  个 【本迭代修复】                           ║\n" $TOTAL_HIGH
    printf "║  🟠 中危漏洞:  %-3d  个 【下个迭代】                            ║\n" $TOTAL_MEDIUM
    printf "║  🟢 低危漏洞:  %-3d  个 【技术债务】                            ║\n" $TOTAL_LOW
    echo "╠════════════════════════════════════════════════════════════════╣"

    if [ $TOTAL_CRITICAL -gt 0 ]; then
        echo "║  ❌ 结论: 存在严重安全漏洞，必须修复后才能发布！                  ║"
    elif [ $TOTAL_HIGH -gt 3 ]; then
        echo "║  ⚠️  结论: 高危漏洞超过 3 个，建议修复后再发布                     ║"
    else
        echo "║  ✅ 结论: 安全扫描通过！                                          ║"
    fi

    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📋 详细报告: $REPORT_FILE"
    echo ""

    if [ $TOTAL_CRITICAL -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# ==============================================================================
# 主流程
# ==============================================================================
main() {
    scan_rust_dependencies
    scan_npm_dependencies
    scan_hardcoded_secrets
    scan_sql_injection
    scan_cors_config
    generate_security_report
    print_final_result
}

main "$@"
