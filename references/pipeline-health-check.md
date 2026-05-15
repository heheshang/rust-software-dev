# 流水线健康检查参考

## Kanban DB Schema 速查（2026-05 实测）

> `hermes kanban` CLI 不可用时，直接查 `~/.hermes/kanban.db`。

**tasks 表关键列**：id, title, status, assignee, worker_pid, last_heartbeat_at, started_at, consecutive_failures, last_failure_error, workspace_path, body

**注意**：
- **无 `completed_at` 列** — 任务完成状态存在 `status` 列（'done'|'archived'|'running'|'todo'|'blocked'）
- **T9 的 `body` 字段含评审结论**（如 `## APPROVED`）— kanban status=done 不等于流水线通过
- 判断真实状态：结合 `status` + `body` 内容 + git status 交叉验证

**快速查询模板**：
```python
import os, sqlite3, time
db = os.path.expanduser('~/.hermes/kanban.db')
conn = sqlite3.connect(db)
conn.row_factory = sqlite3.Row
cur = conn.cursor()

# 所有流水线任务（按 workspace 筛选）
cur.execute('''SELECT id, title, status, assignee, last_heartbeat_at
               FROM tasks WHERE workspace_path LIKE '%quant-trading%'
               ORDER BY status, id''')

# 单任务详情（含 body 摘要）
cur.execute("SELECT id, title, status, body FROM tasks WHERE id = ?", (task_id,))
```

---

## 卡住检测逻辑

```
对每个 in_progress 任务：
  last_update = 读取任务的 updated_at
  elapsed = now - last_update

  if elapsed > 30min AND 无新 heartbeat:
    → 标记为 "卡住"

卡住计数：
  > 3 个卡住任务 → 告警: "流水线阻塞，请检查"
  ≤ 3 个 → 列出每个卡住任务 + 持续时间
```

---

## blocked 原因速查

| block reason | 自动处理 | 手动处理 |
|---|---|---|
| `triage` | kanban_reclaim（5分钟后重试1次） | 无需 |
| `waiting_dep` | 检查父任务 done → kanban_unblock | 如父任务确实 done 但未解锁，手动 kanban_unblock |
| `review-required` | workspace 有输出 → kanban_complete | 无输出则通知用户 |
| `fix_required` | 已创建 fix 任务 → 跳过 | 确认 fix 任务已 assign |
| `protocol_violation` | workspace 有输出 → complete | 无输出则 unblock |
| `protocol_violation`（零长度 result） | **检查项目实际代码目录**：workspace 为 scratch 时 worker 可能直接写了项目文件，文件存在则 kanban_unblock + kanban_complete | workspace 和项目代码均无输出则 kanban_unblock 重新入队 |
| `Iteration budget exhausted` | **检查项目实际目录**（非 workspace）：DevOps 等任务产出到项目目录，不是 scratch workspace → 如产出物存在则 kanban_complete | workspace 和项目目录均空则 kanban_unblock |
| 401 认证失败 | 批量迁移 profile 到新模型 | — |

**triage protocol_violation 连锁崩溃恢复（E7）：**

```
Fix 任务 crash → triage → kanban specify → worker 再次 crash → blocked
                                                        ↓
                                               检查项目代码是否存在
                                                        ↓
                              ┌─────────────────────────┴─────────────────────────┐
                              ↓                                                   ↓
                    代码已实现 → kanban unblock + kanban complete         代码未实现 → kanban unblock
                    （不走 worker）                                           （重新入队）
```

**判断口诀**：workspace 空 → 查项目代码 → 有则 complete，无则 unblock。

**禁忌**：
- ❌ 不查 workspace 就认为产出不存在
- ❌ 不查项目代码就 kanban_unblock（会重新触发 worker，造成重复劳动）
- ❌ 反复 `kanban specify` 等待 worker（无限 crash 循环）

**E7 验证产出物清单（防 summary 欺骗）：**

> Worker 可能在 `protocol_violation` 前已调用 `kanban_complete`，但 summary 声称的产出文件实际上没有写入磁盘（常见于 scratch workspace 被 GC、或 worker 误判成功）。
> 因此 E7 恢复时，即使 workspace 有内容，也必须核对 task body 中承诺的产出物是否真实存在。

```bash
# E7 恢复后立即执行产出物核查
# 1. 读取 task body 中的产出物清单
hermes kanban show <task_id> | grep -E "\.(md|yml|json|rs|vue|ts|feature)$"

# 2. 对每个产出物验证文件存在
for f in <list>; do
  ls $HERMES_KANBAN_WORKSPACE/<task_id>/$f 2>/dev/null && echo "✓ WS: $f"
  ls /home/ssk/workspace/<project>/$f 2>/dev/null && echo "✓ PRJ: $f"
  if [[ ! -f "$HERMES_KANBAN_WORKSPACE/<task_id>/$f" && ! -f "/home/ssk/workspace/<project>/$f" ]]; then
    echo "✗ MISSING: $f"
  fi
done
```

**真实案例（2026-05-13 K线数据管理流水线）：**
- T7 (tech-writer) summary 声称已产出 `KlineManagement_API.md`，workspace 为空
- `/home/ssk/workspace/quant-trading/docs/api/` 下无此文件，`docs/guides/` 目录甚至不存在
- T6 (QA) 同样声称产出 QA 报告，实际文件不存在
- 结果：T7/T8/T9 全部以 `protocol_violation` 崩溃告终
- **教训**：summary 声称产出 ≠ 产出实际存在，E7 恢复必须交叉验证

---

## 质量门快速检查

```
T4 Frontend:
  npm run type-check (vue-tsc)  →  0 errors
  npm run build                 →  success
  vitest --coverage             →  Statements ≥ 100%, Lines ≥ 100%

T5 Backend:
  cargo clippy -- -D warnings   →  0 warnings
  cargo test                    →  all pass
  cargo tarpaulin               →  Statements ≥ 100%, Lines ≥ 100%
  cargo bench (可选)             →  QPS ≥ 门槛

T5.5 Designer:
  UI 走查 P0 = 0

T6 QA:
  QA 报告存在
  P0 = 0
  P1 ≤ 3
  cargo tarpaulin ≥ 100%
  vitest --coverage ≥ 100%

T8 DevOps:
  docker compose up -d          →  success
  docker ps                     →  healthcheck 全 green
```

---

## 批量迁移 Worker Profile 模型

当所有 worker 返回 401 时，执行批量迁移：

```bash
# 1. 确认哪些 profile 失败
hermes profile list

# 2. 批量更新模型配置
# ⚠ Profile 名称无 rust- 前缀！实际为: pm tech-lead designer frontend backend qa tech-writer devops
for profile in pm tech-lead designer frontend backend qa tech-writer devops; do
  hermes -p $profile config set model.default glm-5.1
  hermes -p $profile config set model.provider custom
  hermes -p $profile config set model.base_url https://ark.cn-beijing.volces.com/api/coding/v1
  hermes -p $profile config set model.api_type openai
done

# 3. 验证
hermes profile list
```

> **当前模型**: glm-5.1 (provider: custom, base_url: https://ark.cn-beijing.volces.com/api/coding/v1, api_type: openai)
> 历史: DeepSeek-v4-flash (2026-05-13 失效, 401) → glm-5.1/ark (过渡) → MiniMax-M2.7 → glm-5.1/custom (当前)
> ⚠ Profile 名称是 `pm` 不是 `rust-pm`，`tech-lead` 不是 `rust-tech-lead`，以此类推

---

## E9: T9 done/archived 状态 ≠ APPROVED（流水线实质阻塞）

> 适用场景：T9 任务状态为 `done` 或 `archived`，但未包含 `## APPROVED` 标记。
> 常见于 T9 Worker 遇到 `protocol_violation`（clean exit 但未调用 kanban_complete）后被 dispatcher 归档，或输出了 `## REJECTED` 结论但仍 `kanban_complete`。

**判断标准：**
```
T9 task 显示 done/archived
  → 检查任务 body 或项目 docs/architecture/ 中的评审文件
  → 是 → 流水线实质完成
  → 否 → 流水线实质阻塞
```

**T9 done + REJECTED 的识别特征（2026-05-14 实测）：**
- `hermes kanban show <t9_id>` 中 `Latest summary` 包含 "E7恢复"
- `completed` 事件几乎紧跟 `gave_up`/`protocol_violation` 事件（时间差 < 1min）
- workspace 可能为 scratch，但项目 `docs/architecture/REVIEW-*.md` 存在且含 `## REJECTED`
- 评审报告中 P0 阻塞项可能已部分修复（如 cargo 编译从 FAIL 变为 pass）

**检查序列：**
```bash
# Step 1: 检查 T9 workspace 中的 APPROVED/REJECTED 标记（workspace 为 scratch 时为空）
cat $HERMES_KANBAN_WORKSPACE/<t9_id>/*.md 2>/dev/null | grep -E "APPROVED|REJECTED"
hermes kanban show <t9_id> | grep -E "APPROVED|REJECTED"

# Step 2: workspace 为空 → 检查项目 docs/architecture/ 中的评审文件
ls /home/ssk/workspace/<project>/docs/architecture/REVIEW-*.md 2>/dev/null
grep -E "## APPROVED|## REJECTED" /home/ssk/workspace/<project>/docs/architecture/REVIEW-*.md 2>/dev/null

# Step 3: 交叉验证当前实际状态（避免被旧评审报告误导）
cd /home/ssk/workspace/<project>/backend && cargo check 2>&1 | tail -5   # 编译状态
cd /home/ssk/workspace/<project>/frontend && npx vue-tsc -b --noEmit 2>&1 | tail -5  # TS 状态
```

**T9 done + REJECTED 处理流程：**
```
T9 done + REJECTED 检测到
    │
    ├── Step 1: 交叉验证 REJECTED 原因是否已修复（cargo check / vitest 等）
    │           有些原因可能在 E7 恢复后已自动修复（如编译错误被后来的 worker 修复）
    │
    ├── Step 2: 原因未修复 → 不可跳过
    │            创建 Fix 任务链（T4.Fix / T6.Fix）→ 重新走查（T5.5）→ 重新 T9
    │
    └── Step 3: 原因已修复（如交付压力短期止血）
                创建新 T9 评审任务（不等同于覆盖原 REJECTED）
                原 T9 保持 done + REJECTED 记录不覆盖
```

**禁忌**：
- ❌ T9 done/archived 就认为流水线 APPROVED（task 内容可能是 REJECTED）
- ❌ 不检查 T5 编译状态就标记 T9 done
- ❌ 用 `kanban complete` 覆盖已有 REJECTED 结论（掩盖问题，不可逆）
- ❌ 用评审报告中的旧状态（如旧编译错误）判断当前状态，需重新验证

---

## Cronjob 巡检输出格式

```
Pipeline: <name> | 总任务: 10 | 完成: 3 | 进行中: 4 | 阻塞: 2

[T1] PM          ● running  | 8min ago  | PRD 编写中
[T2] Tech-Lead   ◻ todo     | waiting T1
[T3] Designer    ◻ todo     | waiting T2
[T4] Frontend    ● running  | 22min ago | 组件实现
[T5] Backend     ⚠ blocked  | triage    | 重试中
[T6] QA          ⚠ blocked  | waiting_dep | 等待 T5.5
[T9] Tech-Lead   ◻ todo     | waiting T6+T7+T8

⚠ 卡住任务: T4 (22min), T5 (35min) → 流水线轻微阻塞
```

---

## Docker 前端重新部署

> `docker compose up -d` 可能被 terminal 工具误判为长驻进程而拒绝执行。变通方案：

```bash
# 方案 A：直接用 docker run（需手动指定 network）
docker rm -f quant-frontend
docker run -d --name quant-frontend --network quant-trading-network -p 8081:80 quant-trading-frontend:latest

# 方案 B：先 build 再手动 up（build 通常不被拦截）
docker compose build frontend
# 然后用 docker run 或单独 stop+rm+run

# 注意：网络名称用 `docker network ls | grep quant` 确认
# 当前项目网络名：quant-trading-network（非 quant-trading_default）
```

**完整流程（前端代码修改后重新部署）：**
```bash
# 1. 本地 TS 检查（避免 Docker 内构建失败）
cd frontend && npx vue-tsc -b --noEmit

# 2. 构建 Docker 镜像（内含 npm run build）
cd .. && docker compose build frontend

# 3. 重新部署
docker rm -f quant-frontend
docker run -d --name quant-frontend --network quant-trading-network -p 8081:80 quant-trading-frontend:latest

# 4. 验证
sleep 5 && curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/
```

---

## delegate_task 启动节点模板

启动 worker 前先确认任务 ID，避免重复创建：

**delegate_task JSON 模板**：
```json
{
  "context": "workspace=/home/ssk/workspace/quant-trading\nskill=rust-software-dev\n节点=T3\n功能=交易执行模块",
  "goal": "完整描述 + 参考文档路径 + 产出目录 + 完成后 kanban_complete",
  "role": "leaf",
  "toolsets": ["terminal", "file", "web"]
}
```

**常用任务 ID（quant-trading）**：
| 节点 | 任务 ID | 状态 |
|------|---------|------|
| T3 UI设计 | t_abc8efb8 | ✅ done（已产出 Design_TradingExecution.md） |
| T4 前端实现 | 新建 | — |
| T5 后端实现 | 新建 | — |

---

## Python execute_code 陷阱

`execute_code` 工具中 body 参数含花括号（如 `{symbol}`）会触发 Python f-string 解析错误 `NameError: name 'symbol' is not defined`。

```python
# ❌ 错误 — body 中的 {symbol} 被 Python 解析为 f-string 变量
body = """...
- 缓存：Redis 热点K线（key格式：kline:{symbol}:{timeframe}:{ts}）
..."""
out = run(f"hermes kanban create ... --body '{body}'")

# ✅ 正确 — 使用 raw string 包裹 body
body = r"""...
- 缓存：Redis 热点K线（key格式：kline:{symbol}:{timeframe}:{ts}）
..."""
out = run(f"hermes kanban create ... --body '{body}'")
```

**规律**：凡是在 f-string `f"..."` 内部传 shell 命令，且 body 内容含 `{}`，一律用 `r"""..."""` 包裹 body。
