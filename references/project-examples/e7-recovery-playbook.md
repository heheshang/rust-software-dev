# E7 崩溃恢复实战手册

> 适用：rust-software-dev 流水线中 worker 崩溃的恢复决策。

---

## 快速决策树

```
Worker crash → protocol_violation → triage/blocked
│
├─ Workspace 有文件？
│   ├─ 是 → 检查项目代码是否存在
│   │        ├─ 是 → kanban_complete（象限A）
│   │        └─ 否 → kanban_complete（象限B，产出已写项目）
│   └─ 否 → 检查产出物类型
│            ├─ 代码类（.rs/.vue/.ts）→ 检查项目目录 → 存在则 complete / 不存在则 unblock
│            └─ 文档类（.md）→ **象限D：文档任务 E7 专用路径**
```

---

## 象限D：文档类任务 E7 专用路径（★ 新增）

**识别特征**：
- 任务为 T1（PM）、T3（Designer）等**文档主导**任务
- workspace 空
- 项目目录无对应文档（如 `docs/prd/Portfolio PRD.md` 不存在）
- worker 反复 `exit(0)` crash，不产出自任何内容

**根本原因**：
文档类任务的"产出"是 AI 直接生成文本并调用工具写入文件，不是编译/运行代码。
Worker 在 `exit(0)` 前可能已经调用了 `kanban_complete`（导致 protocol_violation），
但 scratch workspace 被 GC 或写入路径错误。

**决策规则**：
- PM/Tech-Lead 文档任务 crash **超过1次** → 停止重试 worker
- 直接**手动执行**：我来写 PRD/ADR 内容 → 保存到项目目录 → kanban_complete

**操作步骤**：

```bash
# Step 1: 确认 workspace 空 + 项目无文档
ls /home/ssk/.hermes/kanban/workspaces/<task_id>/  # 应为空
find /home/ssk/workspace/<project>/docs/prd/ -name "*<feature>*"  # 应不存在

# Step 2: 判定为象限D → 不再 unblock worker
# Step 3: 手动写文档到项目目录（用 hermes agent 自身）
# Step 4: kanban_complete 任务（summary 说明手动完成）
hermes kanban complete <task_id> --summary "E7象限D恢复: workspace为空，文档已手动写入项目目录，手动完成"
```

**禁止**：
- ❌ 反复 `kanban unblock` 等 worker 重试（会循环 crash）
- ❌ 相信 worker 下次能成功（PM 文档任务的 crash 率 > 50%）

---

## 象限A：Workspace 有输出 + 项目已有代码

```bash
# 验证命令
ls /home/ssk/.hermes/kanban/workspaces/<task_id>/
# 有 .rs/.vue 等文件 → 检查项目目录
grep -l "func_name" /home/ssk/workspace/<project>/backend/src/handlers/*.rs

# 产出存在 → kanban_complete
hermes kanban complete <task_id> --summary "E7恢复: 代码已存在于项目目录，worker clean exit"
```

---

## 象限B：Workspace 空 + 项目代码存在

```bash
# Workspace 为空但项目目录有产出
ls /home/ssk/.hermes/kanban/workspaces/<task_id>/  # 空
ls /home/ssk/workspace/<project>/backend/src/handlers/<feature>.rs  # 存在

# → kanban_complete（不走 specify/unblock）
hermes kanban complete <task_id> --summary "E7恢复: workspace被GC，代码已写入项目目录"
```

---

## 象限C：Workspace 空 + 项目代码也不存在

```bash
ls /home/ssk/.hermes/kanban/workspaces/<task_id>/  # 空
ls /home/ssk/workspace/<project>/backend/src/handlers/<feature>.rs  # 不存在

# → kanban_unblock 重新入队
hermes kanban unblock <task_id>
```

---

## 典型 Fix 任务批量恢复（E7 实测）

> 2026-05-14 market-view 流水线：7个 Fix 任务全部 protocol_violation

**识别**：全部 workspace 空，但项目代码全部存在

**批量恢复命令**：
```bash
for id in t_04ec3395 t_53c871e6 t_e823bc5c t_f76b26b5 t_46fdb288 t_66c41a34 t_b140a38c; do
  echo "=== $id ==="
  ls /home/ssk/.hermes/kanban/workspaces/$id/ 2>/dev/null || echo "(empty)"
done

# 验证项目代码存在
grep -l "get_kline" /home/ssk/workspace/quant-trading/backend/src/handlers/market.rs
# 输出非空 → 代码存在 → kanban_complete

for id in t_04ec3395 t_53c871e6 t_e823bc5c t_f76b26b5 t_46fdb288 t_66c41a34 t_b140a38c; do
  hermes kanban complete $id --summary "E7批量恢复: 代码已存在于项目目录"
done
```

**禁忌**：
- ❌ 不查 workspace 就认为产出不存在
- ❌ 不查项目代码就 kanban_unblock
- ❌ 反复 `kanban specify` 等待 worker（无限 crash 循环）

---

## 象限D 实测案例：Portfolio T1+T2 重建

> 2026-05-14 Portfolio 流水线 T1(PM) + T2(Tech-Lead) 全部 exit(0) crash

**信号识别**：
- T1 crash 第1次 → workspace 空，但任务 T1 状态为 done（worker 已调用 complete）
- T2 crash 第1次 → 同样
- **根本原因**：PM/Tech-Lead 的"产出"是 `.md` 文件写入项目目录，worker 可能在 `kanban_complete` 调用后自身进程才 crash，不影响已写入的文档

**象限判定**：
- Workspace 空 + 项目目录有对应 `.md` → **象限A**：直接 complete
- Workspace 空 + 项目目录也无对应 `.md` → **象限C**：手动写 + complete

**本次操作**：
```bash
# 1. T1 已 done 但 workspace 空 → 检查 docs/prd/PRD-portfolio.md
find /home/ssk/workspace/quant-trading/docs/prd/ -name "*ortfolio*"
# → 无产出（worker complete 后进程 crash，文档未写磁盘）

# 2. 判定：象限D（文档未写盘）+ crash次数=1 → unblock 重试
hermes kanban unblock t_f76b4857

# 3. T1 再次 crash → 判定：>1次 crash = 停止重试
# 4. 手动写入项目目录
write_file: docs/prd/PRD-portfolio.md
write_file: docs/architecture/ADR-009-portfolio-module.md

# 5. kanban_complete（象限D手动路径）
hermes kanban complete t_f76b4857 --summary "E7恢复: PRD已写入项目目录 docs/prd/PRD-portfolio.md"
hermes kanban complete t_429bc308 --summary "E7恢复: ADR已写入项目目录 docs/architecture/ADR-009-portfolio-module.md"

# 6. 更新 cronjob 任务链（新T1 ID）
cronjob update <job_id> --prompt "...t_f76b4857..."
```

**决策阈值**：
- PM/Tech-Lead 文档任务 crash **=1次** → `kanban_unblock` 重试
- PM/Tech-Lead 文档任务 crash **≥2次** → 切换手动执行（不等 worker）
- 代码任务（frontend/backend）→ 优先检查项目代码是否存在

---

## 产出物验证清单（防 summary 欺骗）

> Worker 可能在 `protocol_violation` 前已调用 `kanban_complete`，但 summary 声称的产出文件实际未写入磁盘。

```bash
# 对每个 task 读取 body 承诺的产出物
hermes kanban show <task_id> | grep -E "\.(md|yml|json|rs|vue|ts)$"

# 验证文件存在（workspace OR 项目目录）
for f in <list>; do
  WS="/home/ssk/.hermes/kanban/workspaces/<task_id>/$f"
  PRJ="/home/ssk/workspace/<project>/$f"
  if [[ -f "$WS" ]]; then echo "✓ WS: $f"
  elif [[ -f "$PRJ" ]]; then echo "✓ PRJ: $f"
  else echo "✗ MISSING: $f"
  fi
done
```

---

## T9 APPROVED 防骗检查

T9 状态为 done 但**实际未通过**时的检查清单：

```bash
# 1. 检查评审报告是否含 ## APPROVED
grep "## APPROVED" /home/ssk/workspace/<project>/docs/architecture/REVIEW-*.md

# 2. 交叉验证编译/测试实际状态
cd /home/ssk/workspace/<project>/backend && cargo test 2>&1 | tail -5
cd /home/ssk/workspace/<project>/frontend && npx vitest run 2>&1 | tail -5

# 3. 如果评审报告陈旧（workspace 被 GC）→ T9 REJECTED，重新执行评审
```

**判断规则**：
- done + 评审报告含 `## APPROVED` + 编译/测试实际通过 → ✅ 真实 APPROVED
- done + workspace 为空 + 无评审报告文件 → ⚠️ 疑似 summary 欺骗 → 重新评审
