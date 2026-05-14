# P0 Code Findings — quant-trading (REVISED 2026-05-14)

> ⚠️ **勘误**：本文件初版存在两处误判，以下为修正后结论。

---

## ✅ 真实 P0：Portfolio 组合空白

**文件**: `frontend/src/views/portfolio/PortfolioView.vue`（28行占位）+ 后端无 `portfolio` handler

| 端侧 | 状态 | 说明 |
|------|------|------|
| 前端 | ⚠️ 占位页 | 仅 `<el-empty>`，需完整实现 |
| 后端 | ❌ 缺失 | `handlers/`、`services/`、`db/` 均无 portfolio 模块 |

**修复**：完整 T1-T9 流水线（已创建，2026-05-14 执行中）

---

## ✅ 已排除：market.rs 和 backtest_engine.rs

> 经逐行核实，以下原本标记为 P0 的问题均为**测试代码内**的 `.unwrap()`，不影响生产服务。

### market.rs — ✅ 排除

```bash
grep -n "\.unwrap()" backend/src/handlers/market.rs \
  | grep -v "test\|cfg\|assert"
# 返回: 空（所有 unwrap 均在 #[cfg(test)] 内）
```
所有 `.unwrap()` 散布在 `#[cfg(test)]` 模块（108-265行），非生产 handler 代码。

### backtest_engine.rs — ✅ 排除

619/738/790/836/908/987/1112 行全部在 `#[cfg(test)]` 或 `#[test]` 内。

---

## 已知 P1（不阻断但需关注）

| 模块 | 问题 | 文件/行 |
|------|------|---------|
| market_data.rs | Redis 缓存未实现，全 mock 数据 | `services/market_data.rs:63,84,114` |
| batch cancel | 标注 P1，实现完整性待确认 | `handlers/order.rs:494` |
| ticker history | 历史快照未实现（TODO P1） | `handlers/market.rs:167-192` |

---

## P0 代码扫描命令模板

```bash
cd /home/ssk/workspace/quant-trading

# 1. 查找 handler（非测试）中的 unwrap() panic 风险
grep -rn "\.unwrap()" backend/src/handlers/ \
  | grep -v "//\|test\|cfg\|assert\|\.unwrap(),"

# 2. 检查 Portfolio 前端实现行数（<50 = 占位页）
wc -l frontend/src/views/portfolio/PortfolioView.vue

# 3. 检查后端 portfolio handler 是否存在
ls backend/src/handlers/portfolio.rs 2>/dev/null && echo "EXISTS" || echo "MISSING"

# 4. 查找 TODO/FIXME（已分级的）
grep -rn "TODO: P0\|TODO: P1\|FIXME\|HACK" backend/src/ --include="*.rs"
```

---

## SeaORM Enum Serialize 大小写陷阱

> 本次发现的新 P0 级陷阱，记录于此。

当 SeaORM `DeriveActiveEnum` 与 `#[derive(Serialize)]` 联用时，Serde 默认输出 **PascalCase**，但 `string_value` 是 **snake_case**：

```rust
// ⚠️ 测试失败：serde_json::to_value(&OrderSide::Buy) → String("Buy")
//              但 assert_eq!(buy, "buy") 期望小写
#[derive(DeriveActiveEnum, Serialize, Deserialize)]
#[sea_orm(string_value = "buy")]
Buy,

// ✅ 正确：手动 impl Serialize，显式返回 string_value
impl Serialize for OrderSide {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where S: serde::Serializer {
        serializer.serialize_str(match self { OrderSide::Buy => "buy", OrderSide::Sell => "sell" })
    }
}
```

需要手动 impl Serialize 的枚举（quant-trading 项目）：
- `OrderSide` → "buy" / "sell"
- `OrderType` → "limit" / "market"
- `OrderStatus` → "pending" / "partial_filled" / "filled" / "cancelled" / "expired" / "rejected"
- `TradeMode` → "paper" / "live"
- `PositionSide` → "long" / "short"
- `TimeInForce` → "GTC" / "IOC" / "FOK"（这个本来就是 PascalCase，无需修改）
