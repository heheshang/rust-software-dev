# Trading 模块 — API契约检查与常见Bug模式

> 基于 2026-05-15 T6 QA 阶段发现的三类契约不匹配
> 用途：前端-后端联调前必做检查，新模块启动时参考

---

## 一、契约检查流程

每次 T4 前端完成（T6 QA 开始前），执行以下对照：

```
frontend/src/types/order.ts  →  后端 handlers/*.rs response  →  DB entity定义
```

**顺序**：先查后端 handler 返回的 JSON 结构，再对前端 TypeScript 类型

---

## 二、已发现的 Bug 模式

### Bug 1: UUID vs Number（最常见）

**触发条件**：后端用 `uuid` 或 `i32` 做 ID，前端默认为 `number`

| 字段 | 前端类型（错误） | 后端实际 | 修 |
|---------|-----------------|---------|-----|
| `Position.id` | `number` | `String` (UUID) | `string` |
| `PaperAccount.user_id` | `number` | `String` (UUID) | `string` |
| `Order.id` | `number` | `String` (UUID) | `string` |

**检查命令**：
```bash
grep -n "uuid\|i32\|i64\|user_id.*eq\|id.*eq" backend/src/handlers/*.rs | head -20
grep -n "id: number\|user_id: number" frontend/src/types/*.ts
```

**修复**：将前端类型改为 `string`，勿用 `number` 存储 ID

---

### Bug 2: 路由路径不匹配

**触发条件**：前端用 `/:id` 但后端用 `/:symbol`

| 前端 API | 前端路径 | 后端路由 | 影响 |
|---------|---------|---------|------|
| `closePosition(id)` | `POST /positions/:id/close` | `POST /positions/:symbol/close` | 404 |
| `cancelOrder(order_id)` | `POST /orders/:id/cancel` | 需确认后端路由 | 待核对 |

**检查命令**：
```bash
# 前端 API 路径
grep -n "post\|get" frontend/src/api/order.ts | head -20

# 后端路由
grep -n "route\|positions.*close\|orders.*cancel" backend/src/main.rs
```

**修复**：统一路径，symbol 用 `encodeURIComponent` 编码

---

### Bug 3: Props 接口不匹配

**触发条件**：组件接收的 props 与调用方传入的不一致

常见场景：
- TradingView.vue 传入 `activeOrderCount` 但组件用 `orderCount`
- `is-history` vs `isHistory`（Vue 自动转换，但需确认组件定义）
- emit 事件参数类型变化（如 `close-success` 从 `positionId: number` → `symbol: string`）

**检查命令**：
```bash
# 查 TradingView.vue 中的组件 Props
grep -n "@close-success\|:active-order\|is-history" frontend/src/views/trade/TradingView.vue

# 查组件 defineEmits
grep -n "defineEmits\|emit(" frontend/src/components/order/PositionPanel.vue
```

**修复**：确认 emit 载荷类型，更新调用方

---

## 三、完整检查清单（T6 开始前必做）

```bash
cd /home/ssk/workspace/quant-trading

# 1. 类型检查
grep -n "id: number\|user_id: number" frontend/src/types/order.ts

# 2. API 路由检查
grep -rn "closePosition\|cancelOrder" frontend/src/api/ --include="*.ts" | grep "post\|path"

# 3. 后端路由确认
grep -n "route.*close\|route.*cancel" backend/src/main.rs

# 4. emit/Props 匹配
grep -n "emit\|defineEmits" frontend/src/components/order/PositionPanel.vue

# 5. 运行测试
cd frontend && npm test -- --run 2>&1 | tail -5
```

---

## 四、已确认无Bug的模块（参考）

| 模块 | 前端类型 | 后端类型 | 状态 |
|------|---------|---------|------|
| Order side | `buy \| sell` | `OrderSide` enum | ✅ |
| Order status | `pending \| filled \| cancelled` | `OrderStatus` enum | ✅ |
| Trade | `Trade[]` | `Vec<Trade>` | ✅ |
| SymbolConfig | 完整 | 完整 | ✅ |