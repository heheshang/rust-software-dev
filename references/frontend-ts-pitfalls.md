# Frontend TypeScript 常见陷阱速查

> 本文件记录 SDD 流水线中反复出现的 Vue3/TypeScript 编译错误和修复模式。
> Docker 构建会运行 `vue-tsc`，这些错误会直接导致镜像构建失败。

## 1. Temporal Dead Zone (TDZ)

**症状**: `Block-scoped variable 'X' used before its declaration`

**根因**: `const` 声明在 `try` 块内，但在声明前就被同块内代码引用。

```ts
// ❌ 错误
const payload = { risk_config: riskConfigPayload }  // 引用在声明前
const riskConfigPayload = { ... }                    // 声明在后面

// ✅ 修复：将声明移到使用前
const riskConfigPayload = { ... }
const payload = { risk_config: riskConfigPayload }
```

**规律**: 凡是在 `try` 块内构建多个 `const` 对象且有依赖关系，必须按依赖顺序声明。

## 2. Null-unsafe API 解构

**症状**: 运行时 `TypeError: can't access property "length", t is undefined`

**根因**: API 返回值结构不可靠，`result.data` 可能为 `undefined`（如 401 被拦截、网络错误、后端返回格式不匹配）。

```ts
// ❌ 错误 — 如果 result 是 undefined 或 result.data 不存在，crash
strategies.value = result.data
totalCount.value = result.meta.total

// ✅ 修复 — null-safe 解构
strategies.value = result?.data ?? []
totalCount.value = result?.meta?.total ?? 0
```

**规律**: 所有 API 调用返回值的 `.data` / `.meta` 解构必须用 `?.` + `??` 防御。

## 3. 元组类型初始化

**症状**: `TS2352: Conversion of type '[]' to type '[number, number]' may be a mistake`

**根因**: 空数组 `[]` 无法赋值给元组类型 `[number, number] | null`。

```ts
// ❌ 错误
dateRange: [] as [number, number] | null

// ✅ 修复
dateRange: null as [number, number] | null
```

## 4. Element Plus 图标导入

**症状**: `TS2305: Module '"@element-plus/icons-vue"' has no exported member 'X'`

**常见误用对照表：**

| 错误图标 | 正确替代 |
|---------|---------|
| `Api` | `Connection` |
| `Shopping` | `ShoppingCart` |
| `Setting` | `Setting` (这个没问题) |
| `Data` | `DataLine` 或 `DataBoard` |

**验证方法**: `node -e "const icons = require('@element-plus/icons-vue'); console.log(Object.keys(icons).filter(k => k.includes('Shop')))"`

## 5. UpdatePayload 类型不完整

**症状**: `TS2353: Object literal may only specify known properties, and 'X' does not exist in type 'UpdateStrategyPayload'`

**根因**: 前端 `UpdateStrategyPayload` 类型定义落后于实际使用（如 T4.5 新增了 `risk_config` 字段但类型未更新）。

**修复**: 在 `types/index.ts` 中补充缺失字段：
```ts
export interface UpdateStrategyPayload {
  name?: string
  parameters?: Record<string, any>
  risk_config?: {       // 补充
    max_position: number
    stop_loss: number
    stop_profit: number
  }
  strategy_code?: string
}
```

**规律**: 每次 T4.5 UI 走查发现新增字段时，必须同步检查 `types/index.ts` 中对应的 Payload 类型。

## 6. 模板中联合类型赋值

**症状**: `TS2322: Type 'string' is not assignable to type '"csv" | "api" | "exchange" | null'`

**根因**: `v-for` 循环中的 `method.value` 类型推断为 `string`，但目标 ref 是联合类型。

```html
<!-- ❌ 错误 -->
@click="selectedMethod = method.value"

<!-- ✅ 修复 -->
@click="selectedMethod = method.value as 'csv' | 'api' | 'exchange'"
```

## 7. WebSocket 订阅数组符号拼写错误

**症状**: 前端订阅了不存在的交易对，backend 返回 404 或忽略。

**根因**: 符号名称拼写错误（如 `BNBUSUSDT` 而非 `BNBUSDT`），这种错误 TypeScript 不会报错（只是字符串字面量），但 backend WS 会因为不识别而静默失败。

```ts
// ❌ 错误 — 重复的 US（BNB + US + USDT）
subscribe(['ticker:BTCUSDT', 'ticker:ETHUSDT', 'ticker:BNBUSUSDT'])

// ✅ 修复
subscribe(['ticker:BTCUSDT', 'ticker:ETHUSDT', 'ticker:BNBUSDT'])
```

**防御方法**: 使用常量集中管理符号，避免字面量拼写：
```ts
// constants/symbols.ts
export const SUPPORTED_SYMBOLS = ['BTCUSDT', 'ETHUSDT', 'BNBUSDT', 'SOLUSDT', 'XRPUSDT', 'DOGEUSDT', 'ADAUSDT', 'AVAXUSDT', 'DOTUSDT', 'LINKUSDT'] as const
subscribe(SUPPORTED_SYMBOLS.map(s => `ticker:${s}`))
```

## 8. WsMessageType 联合类型遗漏新消息类型

**症状**: `TS2345: Argument of type '{ type: "kline"; ... }' is not assignable to parameter of type 'WsMessage'`

**根因**: 后端新增了 WS 消息类型（如 `kline`），但前端 `WsMessageType` 联合类型未同步更新。

```ts
// ❌ 错误 — 缺少 'kline'
export type WsMessageType = 'ticker' | 'depth' | 'depth_update' | 'heartbeat' | 'subscribed' | 'unsubscribed' | 'kick' | 'error'

// ✅ 修复 — 新增 'kline'
export type WsMessageType = 'ticker' | 'depth' | 'depth_update' | 'kline' | 'heartbeat' | 'subscribed' | 'unsubscribed' | 'kick' | 'error'
```

**防御方法**: 使用常量集中管理符号，避免字面量拼写：
```ts
// constants/symbols.ts
export const SUPPORTED_SYMBOLS = ['BTCUSDT', 'ETHUSDT', 'BNBUSDT', 'SOLUSDT', 'XRPUSDT', 'DOGEUSDT', 'ADAUSDT', 'AVAXUSDT', 'DOTUSDT', 'LINKUSDT'] as const
subscribe(SUPPORTED_SYMBOLS.map(s => `ticker:${s}`))
```

**规律**: 当前后端 WS 新增消息类型时，必须同步检查 `frontend/src/types/market.ts` 中的 `WsMessageType`。

---

## 9. Vue 组件数据管理模式冲突（内部自管理 vs 外部传入）

**症状**: 组件有两种不同的 composition 风格导致接口不兼容：
- **外部传入模式**: 父组件通过 `props` 传入数据（`trades`, `total`, `loading`），组件仅负责展示和分页事件上报
- **内部自管理模式**: 组件内部 `ref` 管理数据，自己调用 API `fetchTrades()`，props 只用于配置（如 `defaultSymbol`）

**冲突场景**: T4 frontend worker 超时后产出了 `trade/TradeRecordTab.vue`（内部自管理，385行），但 `TradingView.vue` 和 `OrderManagementView.vue` 使用的是**外部传入模式**调用方式（传入 `:trades="trades" :total="tradesTotal"` 等 props）。

**判断方法**:
```ts
// 外部传入模式 — defineProps 包含 trades/total/loading 等数据型 props
const props = withDefaults(defineProps<{
  trades?: Trade[]
  total?: number
  page?: number
  size?: number
  loading?: boolean
}>(), { ... })

// 内部自管理模式 — props 只有配置项，数据通过 ref+API内部获取
const props = withDefaults(defineProps<{
  defaultSymbol?: string   // ← 配置型 prop
}>(), { ... })
const trades = ref<Trade[]>([])  // ← 内部自己管理
```

**修复流程**:
1. `git checkout` 恢复旧版（外部传入模式）
2. 删除 worker 产出的内部自管理版本
3. 修正 import 路径指向恢复后的文件
4. 验证父组件的 props 传递与子组件 `defineProps` 匹配

**预防**: 前端 worker 任务应明确指定组件的数据管理模式（外部传入优先，与后端 API 对齐）。

---

## 10. 前端 Subagent 超时后的清理检查清单

Frontend worker 超时（默认 600s）后，需要手动执行以下检查：

```
□ git status --short frontend/src/          # 查看所有变更文件
□ wc -l <file>                              # 确认行数是否符合预期
□ grep -n "defineProps\|props\|ref\|onMounted\|onUnmounted" <file>  # 验证完整性
□ grep "import.*from" <file>                # 检查是否有悬空的 import
□ git diff --stat                           # 变更量是否合理（如 TradingView.vue 230→645行）
□ 修复 import 路径冲突（同名组件在不同目录）
□ 合并重复文件（保留符合调用方接口的版本）
□ git add + git commit                      # 手动提交
```

**常见超时产出特征**:
- 核心文件行数大幅增长但未 commit
- 存在 `??` 标记的新文件（untracked）
- 同一组件有多个版本存在于不同目录
- 组件内可能有悬空 import（worker 被中断在 import 语句中间）
