# QA Bug Report 模板

> T6（QA）执行测试后填写此模板，作为 `handle_qa_bugs()` 的输入。

## 输出格式

```json
{
  "task_id": "t_xxxx",
  "project": "<项目名>",
  "test_round": 1,
  "bugs": [
    {
      "id": "BUG-001",
      "severity": "P0|P1|P2|P3",
      "layer": "frontend|backend|fullstack",
      "title": "<简短描述>",
      "description": "<详细描述>",
      "reproduce_steps": ["步骤1", "步骤2", "步骤3"],
      "expected": "<期望行为>",
      "actual": "<实际行为>",
      "impact": "<影响范围>",
      "assignee": "rust-frontend|rust-backend",
      "status": "open|fixed|declined"
    }
  ],
  "summary": {
    "total": 5,
    "p0": 0,
    "p1": 2,
    "p2": 2,
    "p3": 1
  },
  "test_coverage": {
    "frontend_tc": 45,
    "backend_tc": 38,
    "e2e_tc": 12,
    "coverage_percent": 72
  },
  "verdict": "pass|blocked",
  "verdict_reason": "<P0=0 且 P1≤3 时为 pass，否则 blocked>"
}
```

## Bug 分级标准

| 级别 | 定义 | 必须修复 |
|------|------|---------|
| **P0** | 致命：数据丢失、系统崩溃、核心功能完全不可用 | ✅ 立即 |
| **P1** | 严重：功能部分失效、严重性能问题、安全隐患 | ✅ 3轮内 |
| **P2** | 一般：UI 样式偏差、非核心功能异常、边界条件漏检 | ⚠️ 视情况 |
| **P3** | 轻微：文案错误、格式问题、建议改进 | ❌ 忽略 |

## QA 报告文件命名

```
docs/qa-report/
├── QA-Report-<功能名>-<YYYYMMDD>.md    # 主报告
├── Bug-List-<功能名>-<YYYYMMDD>.md     # Bug 清单
└── TC-Coverage-<功能名>-<YYYYMMDD>.md  # 覆盖率报告
```

## T6 Complete 判定

```
verdict = "pass" 当且仅当：
  summary.p0 == 0 AND summary.p1 <= 3

verdict = "blocked" 当：
  summary.p0 > 0 OR summary.p1 > 3
```
