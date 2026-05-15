# quant-trading 项目状态快照

> 最后更新：2026-05-15
> 用途：流水线启动前快速了解项目现状

---

## 已完成的模块

| 模块 | T9 状态 | 主要产出 |
|------|---------|---------|
| 行情模块 (Market) | ✅ done | ADR-005, T1-T9 全部完成 |
| K线数据管理 | ⚠️ archived | T1-T9 有产出，但 protocol_violation，质量参差 |
| 用户认证+RBAC | ✅ done | ADR, T1-T9 完成 |
| 策略管理 | ✅ done | ADR-003, T1-T9 完成 |
| Portfolio | ✅ done | ADR-009, T1-T9 完成 |
| 订单管理 | ✅ done | ADR-010, T1-T9 完成 |
| 回测系统 | ✅ done | ADR-004/007/008, T1-T9 完成 |
| 交易执行 (Trading) | ✅ done | ADR-010, T4/T5/T4.5 完成 |

---

## 交易执行模块 (Trading Execution) — 2026-05-15 完成

### 已完成阶段

| 阶段 | 产出 | 路径 |
|------|------|------|
| T1 | PRD (1629行) + Gherkin (425行) | `docs/prd/PRD-trading-execution.md` |
| T2 | ADR-010 订单管理架构设计 | `docs/architecture/ADR-010-order-management.md` |
| T3 | UI设计规格 + 原型 + 走查清单 | `docs/design/Design_TradingExecution.md` |
| T4 | TradingView.vue 645行 + 组件更新 | `frontend/src/views/trade/TradingView.vue` |
| T4.5 | UI/UE走查（180项通过） | `TradingExecution_Checklist.md` |
| T5 | ADR-010 MVP 后端核对完成 | `backend/src/handlers/order.rs` |

### T4 产出摘要
- **TradingView.vue**：230→645行，三栏布局（K线图+下单表单+委托Tab）
- **OrderList.vue**：买入/卖出颜色区分，空状态骨架屏
- **OrderSummaryCards.vue / PositionPanel.vue**：去除骨架屏CSS动画
- **TradeRecordTab.vue**：修复同名文件冲突，统一 `order/` 路径引用
- **设计token**：#08090a 深色背景 + #7170ff 主色 + Inter/JetBrains Mono
- **响应式**：≤1200px 右侧面板320px，≤900px 两栏切换

### T4 Frontend Worker 超时处理记录（2026-05-15）

- **触发**：Frontend worker 600s 超时，22次API调用未完成
- **问题**：
  1. `TradeRecordTab.vue` 在 `trade/` 和 `order/` 两路径同名，git未暂存冲突文件
  2. TradingView.vue import 指向 `trade/TradeRecordTab.vue`（已删除）
  3. Worker 只产出部分文件，未做 git commit/整理
- **修复步骤**：
  1. `git status --short` 确认变更范围
  2. 对比两路径 TradeRecordTab.vue 内容，保留 `order/` 版本
  3. 修正 TradingView.vue import 路径为 `@/components/order/TradeRecordTab.vue`
  4. git add → commit → push
- **结论**：Worker 超时后手动补全产出物可行，优先检查文件冲突而非重试

### API契约检查 — 常见bug模式（2026-05-15）

新模块启动前应做前端类型↔后端DB schema对照，发现3个契约不匹配：

| bug类型 | 前端类型（错误） | 后端实际 | 影响 |
|---------|-----------------|---------|------|
| UUID vs number | `Position.id: number` | `String` (UUID) | 运行时类型错误 |
| UUID vs number | `PaperAccount.user_id: number` | `String` (UUID) | 同上 |
| 路由路径不匹配 | `POST /positions/:id/close` | `POST /positions/:symbol/close` | 404 |

**检查流程**：前端 `types/*.ts` → 后端 `handlers/*.rs` response 结构 → DB entity定义
**修复优先级**：路由路径 > 类型不匹配（类型错误会导致整个页面崩溃）
详细Bug清单见 `references/api-contract-trading-bugs.md`

### T5 后端核对结论（ADR-010 MVP）
- ✅ `close_position` handler 已实现（`order.rs:829`，路由 `POST /positions/{symbol}/close`）
- ✅ 余额检查（限价买单，`order.rs:367`）
- ✅ 卖出持仓检查 + 冻结逻辑
- ✅ 保证金冻结（`order.rs:400`）
- ✅ 交易对 `enabled` 校验
- ⚠️ `stop/stop_limit` 类型 → MVP 不支持（预期行为，返回参数错误）
- ⚠️ `risk_manager.rs` → MVP 基础风控已嵌入 `create_order`，独立服务 P1
- ⚠️ `TradeWsHub` → 基础 echo WS，`ws.rs:88`行，P1 阶段
- ⚠️ Redis PubSub 策略信号 → P1 阶段

### 后端 handler 全貌（`handlers/order.rs`）
```
create_order, list_orders, get_order, cancel_order, cancel_all_orders,
list_trades, list_positions, close_position, get_account, init_account, list_symbols
共 11 个 handler，1273 行
```

### 待做阶段
| 阶段 | 说明 |
|------|------|
| T6 | QA 全链路测试 |
| T7 | Tech-Writer API文档 + 用户指南 |
| T8 | DevOps Docker 部署 |
| T9 | Tech-Lead 最终评审 |

### P1 待办（非MVP范围）
- `risk_manager.rs` 独立风控服务
- `TradeWsHub` 实时交易推送
- Redis PubSub 策略信号接收
- 止损单 (stop/stop_limit) OrderType

---

## docs/ 目录结构

```
docs/
├── prd/                    # PRD + Gherkin
│   ├── PRD-trading-execution.md
│   └── trading-execution.feature
├── architecture/           # ADR + TechDesign
│   └── ADR-010-order-management.md
├── design/                 # UI 设计规格（T3 产出）
│   ├── Design_TradingExecution.md     (1100行)
│   ├── TradingExecution_Checklist.md    (180项)
│   └── prototype_trading_execution.html (57KB)
├── api/                    # API 文档（T7 产出）
├── qa/                     # QA 报告（T6 产出）
└── PIPELINE-REPORT-*.md    # 流水线完成报告
```

---

## 启动新流水线节点前的检查清单

```bash
# 1. 确认项目根目录
cd /home/ssk/workspace/quant-trading

# 2. 确认 T3 设计文档存在
ls docs/design/Design_TradingExecution.md

# 3. 确认前端 TradingView.vue 已实现（非占位）
wc -l frontend/src/views/trade/TradingView.vue  # 应 > 600行

# 4. 确认后端 close_position 已实现
grep -n "^pub async fn close_position" backend/src/handlers/order.rs

# 5. 检查 git 状态（应有 T4 commit）
git log --oneline -3

# 6. T6 QA 前必做：API契约检查
grep -n "id: number\|user_id: number" frontend/src/types/order.ts
grep -n "closePosition\|/positions/:id" frontend/src/api/order.ts
```