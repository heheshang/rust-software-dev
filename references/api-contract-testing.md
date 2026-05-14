# API 契约测试框架 v1.0

> 目标：前后端通过 API 契约协同工作，减少 80% 的联调时间

---

## 🎯 契约测试理念

```
传统方式：
  后端开发接口    →    前端开发页面    →    联调（发现一堆不匹配问题）
                          等待时间           大量返工

契约方式：
           同时开发
  ┌──────────┴──────────┐
  ↓                      ↓
后端开发接口        前端开发页面
  │                      │
  └─────── 基于契约 ─────┘
          ↑
    自动生成类型定义
    自动校验
```

---

## 📋 契约生命周期

### 1️⃣ 设计阶段（T2 TechLead）

**输出：** `docs/api/OpenAPI-3.0-spec.yaml`

```yaml
openapi: 3.0.0
info:
  title: 策略管理 API
  version: 1.0.0

paths:
  /api/v1/strategies:
    get:
      summary: 获取策略列表
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            minimum: 1
      responses:
        '200':
          description: 成功
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/StrategyListResponse'

components:
  schemas:
    Strategy:
      type: object
      required: [id, name, status]
      properties:
        id:
          type: string
          format: uuid
        name:
          type: string
        status:
          type: string
          enum: [draft, active, paused, archived]
        created_at:
          type: string
          format: date-time

    StrategyListResponse:
      type: object
      properties:
        data:
          type: array
          items:
            $ref: '#/components/schemas/Strategy'
        page:
          type: integer
        per_page:
          type: integer
        total:
          type: integer
```

---

### 2️⃣ 开发阶段（T4/T5 并行）

#### 后端：从 OpenAPI 生成 Axum 服务框架

```bash
# 使用 openapi-generator 生成 Rust 服务框架
npm install -g @openapitools/openapi-generator-cli

openapi-generator-cli generate \
  -i docs/api/OpenAPI-3.0-spec.yaml \
  -g rust-axum \
  -o backend/src/generated/
```

#### 前端：从 OpenAPI 生成 TypeScript 类型

```bash
# 使用 openapi-typescript 生成类型定义
npx openapi-typescript docs/api/OpenAPI-3.0-spec.yaml \
  -o frontend/src/types/api.generated.ts
```

**生成的类型示例：**

```typescript
// frontend/src/types/api.generated.ts
export interface Strategy {
  id: string; // uuid
  name: string;
  status: 'draft' | 'active' | 'paused' | 'archived';
  created_at: string; // date-time
}

export interface StrategyListResponse {
  data: Strategy[];
  page: number;
  per_page: number;
  total: number;
}
```

---

### 3️⃣ 联调阶段（T4.5）：Pact 契约测试

#### Pact 工作原理

```
消费者（前端）          提供者（后端）
     │                      │
     ├── 定义期望 ─────────→ │
     │                      │
     │  ←──────── 验证期望 ──┤
     │                      │
  契约文件            匹配结果
```

#### 第一步：前端定义消费者契约

```typescript
// frontend/tests/pact/strategy.pact.ts
import { PactV3, MatchersV3 } from '@pact-foundation/pact';

const { like, eachLike, uuid, iso8601DateTime } = MatchersV3;

const provider = new PactV3({
  consumer: 'frontend-web',
  provider: 'backend-api',
  port: 1234,
});

describe('Strategy API Contract', () => {
  it('GET /api/v1/strategies returns strategy list', async () => {
    // 定义期望
    provider
      .given('strategies exist')
      .uponReceiving('a request for strategy list')
      .withRequest({
        method: 'GET',
        path: '/api/v1/strategies',
        query: { page: '1' },
      })
      .willRespondWith({
        status: 200,
        headers: { 'Content-Type': 'application/json' },
        body: {
          data: eachLike({
            id: uuid('123e4567-e89b-12d3-a456-426614174000'),
            name: like('测试策略'),
            status: like('active'),
            created_at: iso8601DateTime(),
          }),
          page: like(1),
          per_page: like(20),
          total: like(100),
        },
      });

    // 生成契约文件
    await provider.executeTest(async (mockServer) => {
      // 这里调用真实的 API client 验证
      // const result = await api.getStrategies(1);
      // expect(result.data).toBeDefined();
    });
  });
});
```

#### 第二步：后端验证提供者契约

```rust
// backend/tests/pact/provider_verification.rs
use pact_verifier::*;

#[tokio::test]
async fn verify_strategy_contract() {
    let mut verifier = Verifier::new();

    verifier
        .setup(|_, _| async {
            // 启动测试服务
            start_test_server().await;
        })
        .provider_info(ProviderInfo {
            name: "backend-api".into(),
            host: "localhost".into(),
            port: 8080,
            ..Default::default()
        })
        .pact_files(PactSource::File(
            "../frontend/pacts/frontend-web-backend-api.json".into()
        ));

    let result = verifier.verify().await;

    assert!(result.all_passed(), "契约测试失败");
}
```

---

## 🔧 契约一致性检查脚本

```bash
#!/bin/bash
# scripts/contract-validation.sh
# T4.5 阶段执行，验证前后端契约一致性

echo "📜 API 契约一致性检查"
echo "═══════════════════════════════════════"
echo ""

FAILED=0

# 检查 1: OpenAPI spec 是否存在
if [ ! -f "docs/api/OpenAPI-3.0-spec.yaml" ]; then
    echo "❌ OpenAPI spec 不存在，请先生成契约文件"
    exit 1
fi

echo "✅ OpenAPI spec 存在"
echo ""

# 检查 2: 前端类型是否已生成
echo "🔍 检查前端类型文件..."
if [ -f "frontend/src/types/api.generated.ts" ]; then
    # 检查关键字段定义
    has_strategy=$(grep -c "interface Strategy" frontend/src/types/api.generated.ts)
    if [ $has_strategy -gt 0 ]; then
        echo "   ✅ Strategy 类型已生成"
    else
        echo "   ❌ Strategy 类型缺失"
        FAILED=$((FAILED + 1))
    fi
else
    echo "   ⚠️  前端类型文件不存在，建议生成"
fi

echo ""

# 检查 3: 后端路由与 spec 一致性
echo "🔍 检查后端路由与 spec 一致性..."

# 从 spec 提取路径
SPEC_PATHS=$(grep "^  /" docs/api/OpenAPI-3.0-spec.yaml | sed 's/://' | sort)

# 从后端代码提取实际路径
ACTUAL_PATHS=$(grep -rn "router\..*(.*\"/" backend/src/handlers/ 2>/dev/null | \
               grep -o '"/[^"]*"' | sed 's/"//g' | sort | uniq)

echo "   Spec 定义的端点:"
echo "$SPEC_PATHS" | sed 's/^/     - /'

echo ""
echo "   实际实现的端点:"
echo "$ACTUAL_PATHS" | sed 's/^/     - /'

echo ""

# 简单对比（实际项目用专门的工具）
echo "📊 一致性检查摘要"
SPEC_COUNT=$(echo "$SPEC_PATHS" | wc -l)
ACTUAL_COUNT=$(echo "$ACTUAL_PATHS" | wc -l)
echo "   Spec 定义端点: $SPEC_COUNT"
echo "   实际实现端点: $ACTUAL_COUNT"

echo ""

# 检查 4: 错误码一致性
echo "🔍 检查错误码一致性..."

# 从 spec 提取错误码
SPEC_ERRORS=$(grep -E "^    '[45][0-9]{2}':" docs/api/OpenAPI-3.0-spec.yaml | sort)

# 从后端代码提取实际错误码
ACTUAL_ERRORS=$(grep -rn "StatusCode::" backend/src/ 2>/dev/null | \
                grep -o "NOT_FOUND\|BAD_REQUEST\|INTERNAL_SERVER_ERROR" | sort | uniq)

echo "   Spec 定义的错误响应: $SPEC_ERRORS"
echo "   实际使用的错误码: $ACTUAL_ERRORS"

echo ""

# 最终结果
echo "═══════════════════════════════════════"
if [ $FAILED -gt 0 ]; then
    echo "❌ 契约检查发现 $FAILED 个问题，请修复后再联调"
    exit 1
else
    echo "✅ 契约一致性检查通过，可以开始联调"
    exit 0
fi
```

---

## 🎯 契约质量门禁（T4.5 阶段）

| 检查项 | 标准 | 未通过处理 |
|--------|------|----------|
| OpenAPI spec 存在 | ✅ 必须有 | 阻塞 |
| 前端类型已生成 | ✅ 从 spec 生成 | 阻塞 |
| 后端路由覆盖率 | ≥ 90% 与 spec 一致 | 警告 + 记录 |
| Pact 契约测试 | 100% 通过 | 阻塞 |
| 错误码一致性 | 前后端统一 | 必须修复 |

---

## 🔄 契约变更管理流程

```
1. 变更请求
   ↓
   TechLead 审核变更影响范围
   ↓
2. 更新 OpenAPI spec
   ↓
   自动通知前端/后端团队
   ↓
3. 重新生成类型定义
   ↓
   CI 自动运行契约测试
   ↓
4. 验证通过
   ↓
   合并代码
```

### 变更影响分析脚本

```bash
#!/bin/bash
# scripts/contract-change-impact.sh

echo "📋 契约变更影响分析"
echo "═══════════════════════════════════"

# 对比新旧版本 spec 的差异
OLD_SPEC="docs/api/OpenAPI-3.0-spec.yaml.bak"
NEW_SPEC="docs/api/OpenAPI-3.0-spec.yaml"

if [ -f "$OLD_SPEC" ]; then
    echo "🔍 检测到契约变更，分析影响范围..."
    echo ""

    # 找出新增/删除/修改的端点
    echo "端点变更:"
    diff -u \
        <(grep "^  /" $OLD_SPEC | sort) \
        <(grep "^  /" $NEW_SPEC | sort)

    echo ""

    # 估计受影响的前端文件
    echo "可能受影响的前端文件:"
    for endpoint in $(grep "^+  /" <(diff -u $OLD_SPEC $NEW_SPEC) | sed 's/+ //'); do
        grep -rl "$endpoint" frontend/src/api/ 2>/dev/null | head -5
    done

    echo ""

    # 估计受影响的后端文件
    echo "可能受影响的后端文件:"
    for endpoint in $(grep "^+  /" <(diff -u $OLD_SPEC $NEW_SPEC) | sed 's/+ //'); do
        grep -rl "$endpoint" backend/src/handlers/ 2>/dev/null | head -5
    done
fi
```

---

## 📊 契约测试报告模板

```markdown
# API 契约测试报告

**测试时间**: 2024-05-14
**测试版本**: v1.0.0

## 测试概览

| 指标 | 数值 |
|------|------|
| 契约总数 | 5 |
| 通过的契约 | 5 |
| 失败的契约 | 0 |
| 端点覆盖率 | 95% |
| 字段覆盖率 | 88% |

## 详细结果

### ✅ Strategy API - 通过
- GET /api/v1/strategies
- POST /api/v1/strategies
- GET /api/v1/strategies/{id}
- PUT /api/v1/strategies/{id}
- DELETE /api/v1/strategies/{id}

## 发现的不匹配项

1. 无

## 结论

✅ 所有契约测试通过，可以进入 T5.5 UI 走查阶段
```

---

## 💡 最佳实践

1. **契约优先**：先写 OpenAPI spec，再写代码
2. **类型驱动**：所有前后端类型都从 spec 生成，禁止手写
3. **测试先行**：Pact 测试写在实现之前
4. **变更通知**：spec 变更自动通知相关人员
5. **版本化管理**：每个版本的 spec 都归档保留

---

> **契约测试的本质**：把「联调时才发现的问题」提前到「开发阶段」，把「人的沟通成本」转化为「机器的自动验证」。
