# K线数据管理流水线产出物清单

> K线数据管理 Pipeline T1→T9 各阶段预期产出物。
> 监控巡检时对比此清单，缺失则标记告警。

## 项目路径

`/home/ssk/workspace/quant-trading`

---

## T1 PRD（需求分析）

| 产出物 | 路径 | 状态检查 |
|--------|------|---------|
| PRD 文档 | `docs/prd/PRD-kline-management.md` | `ls docs/prd/PRD-kline-management.md` |
| Gherkin 验收条件 | `docs/prd/kline-management.feature` | `ls docs/prd/kline-management.feature` |

---

## T2 架构设计

| 产出物 | 路径 | 状态检查 |
|--------|------|---------|
| ADR-005 市场数据管道 | `docs/architecture/ADR-005-market-data-pipeline.md` | 存在检查 |
| B1-B4 契约审查 | `docs/architecture/Contract-Review.md` | 含 Kline 相关条目 |

---

## T3 UI设计规格

| 产出物 | 路径 | 状态检查 |
|--------|------|---------|
| Design Spec | `docs/design/Design_Kline*.md` | `ls docs/design/Design_Kline*.md` |
| HTML 原型 | `docs/prototype/Kline*_Prototype.html` | `ls docs/prototype/Kline*_Prototype.html` |
| T4.5 走查清单 | `docs/qa/Kline*_UI-Checklist.md` | T4.5 完成后才有 |

---

## T4 前端实现

| 产出物 | 路径 | 质量门 |
|--------|------|--------|
| K线列表页 | `frontend/src/views/kline/KlineListView.vue` | `npm run typecheck` ✅ |
| K线导入页 | `frontend/src/views/kline/KlineImportView.vue` | `npm run typecheck` ✅ |
| K线质量报告页 | `frontend/src/views/kline/KlineQualityView.vue` | `npm run typecheck` ✅ |
| K线导出页 | `frontend/src/views/kline/KlineExportView.vue` | `npm run typecheck` ✅ |
| API 调用层 | `frontend/src/api/kline.ts` | `npm run typecheck` ✅ |
| 类型定义 | `frontend/src/types/kline.ts` | `npm run typecheck` ✅ |
| 单元测试 | `frontend/src/__tests__/views/Kline*View.test.ts` | `vitest run` ≥ 60% coverage |

**质量门命令：**
```bash
cd /home/ssk/workspace/quant-trading/frontend && npm run typecheck
cd /home/ssk/workspace/quant-trading/frontend && vitest run --coverage
```

---

## T5 后端实现

| 产出物 | 路径 | 质量门 |
|--------|------|--------|
| K线 Handler | `backend/src/handlers/kline.rs` | `cargo check` ✅ |
| K线 Service | `backend/src/services/kline.rs` | `cargo clippy -- -D warnings` ✅ |
| K线 Entity | `backend/src/db/kline.rs` | `cargo test` ✅ |
| 集成测试 | `backend/tests/api/kline_test.rs` | `cargo test` ≥ 70% coverage |

**质量门命令：**
```bash
cd /home/ssk/workspace/quant-trading/backend && cargo check
cd /home/ssk/workspace/quant-trading/backend && cargo clippy -- -D warnings
cd /home/ssk/workspace/quant-trading/backend && cargo test
```

**⚠️ 常见 SeaORM K-line 编译陷阱：**

```
// ❌ 错误：try_get 只传 1 个参数
let symbol: String = row.try_get("symbol").ok()?;

// ✅ 正确：try_get 需要 2 个参数 (pre: &str, col: &str)
let symbol: String = row.try_get("symbol", "symbol").ok()?;

// ❌ 错误：query_all 传引用
.query_all(&stmt)

// ✅ 正确：query_all 传所有权
.query_all(stmt)
```

**SeaORM 版本差异（v1.1.20）：**
- `try_get` 签名：`pub fn try_get<T>(&self, pre: &str, col: &str)`
- `query_all` 签名：`async fn query_all(&self, stmt: Statement)` — Statement 传值不走引用

---

## T4.5 UI/UE 走查

| 产出物 | 路径 | 检查 |
|--------|------|------|
| UI 走查清单 | `docs/qa/KlineManagement_UI-Checklist.md` | P0=0, P1 已修复或记录 |

---

## T6 QA 测试

| 产出物 | 路径 | 质量门 |
|--------|------|--------|
| QA 测试报告 | `docs/qa-report/QA-Report-Kline*.md` | P0=0, P1≤3 |
| TC-A 结果 | `docs/qa-report/tc_a_results.json` | 覆盖 K-line API |
| TC-C 安全结果 | `docs/qa-report/tc_c_results.json` | 14/14 通过 |

---

## T7 技术文档

| 产出物 | 路径 | 检查 |
|--------|------|------|
| K-line API 文档 | `docs/api/KlineManagement_API.md` | OpenAPI 格式 |
| 用户指南 | `docs/guides/Kline-User-Guide.md` | 操作步骤完整 |
| CHANGELOG | `docs/CHANGELOG.md` | 追加 K-line 条目 |

---

## T8 DevOps 部署

| 产出物 | 路径 | 质量门 |
|--------|------|--------|
| docker-compose.yml | `docker-compose.yml` | `docker compose up -d` 成功 |
| Backend Dockerfile | `Dockerfile.backend` | 编译成功 |
| Frontend Dockerfile | `Dockerfile.frontend` | 编译成功 |
| nginx.conf | `nginx.conf` | 存在 |
| CI/CD | `.github/workflows/ci.yml` | GitHub Actions 配置 |

---

## T9 最终评审

| 检查项 | 标准 |
|--------|------|
| 安全 | IDOR 权限校验、输入验证通过 |
| 质量 | cargo clippy/test 全绿、vitest 全绿 |
| 测试 | P0=0, P1≤3 |
| 性能 | 导入性能、查询优化达标 |
| 部署 | healthcheck 全绿 |

**⚠️ protocol_violation + archived 状态 ≠ 评审通过**

T9 `archived` 状态仅表示任务被归档，不等于 APPROVED。巡检时必须：
1. 检查 T9 task body/comment 是否含 `APPROVED`
2. 如果是 `archived` + 无 APPROVED 标记 → **流水线实质未完成**
3. 此时需检查后端编译状态（T5 cargo check 是否通过）

---

## 当前流水线状态（2026-05-13）

```
状态: ⚠️ T9 archived 但实质阻塞
- T5 Backend: ❌ cargo check 失败（kline.rs 6个SeaORM错误）
- T6 QA: ⚠️ QA报告缺失
- T7 Tech-Writer: ⚠️ API文档缺失
- T9: ⚠️ protocol_violation，未执行实际评审
```

## 修复前置条件

T9 恢复前必须：
1. T5: `cargo check` 通过（修复 kline.rs SeaORM API 调用）
2. T6: 补充 QA 测试报告
3. T7: 补充 K-line API 文档
4. 重新执行 T9 评审（或手动 `kanban_complete` + 标注 APPROVED）
