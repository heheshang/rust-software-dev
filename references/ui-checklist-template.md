# UI/UE 走查清单模板

> T4.5（Designer UI/UE 走查）使用此清单，对比设计稿与实际实现。

## 输出格式

```json
{
  "task_id": "t_xxxx",
  "project": "<项目名>",
  "round": 1,
  "checklist": [
    {
      "id": "UI-001",
      "category": "layout|typography|color|spacing|interaction|content|responsive|accessibility",
      "severity": "P0|P1|P2",
      "page": "<页面名>",
      "element": "<元素描述>",
      "design_spec": "<设计稿要求>",
      "actual_implementation": "<实际实现>",
      "diff_percent": 15,
      "status": "pass|fail|deprecated"
    }
  ],
  "summary": {
    "total": 20,
    "p0": 0,
    "p1": 2,
    "p2": 3,
    "pass": 15
  },
  "verdict": "pass|blocked",
  "verdict_reason": "P0=0 时为 pass；P0>0 时为 blocked"
}
```

## 走查维度

| 维度 | 检查项 |
|------|--------|
| **layout** | 页面结构、栅格、容器宽度、响应式断点 |
| **typography** | 字体 family/size/weight、行高、层级 |
| **color** | 主色/辅助色/状态色是否与 Design_Spec 一致 |
| **spacing** | 内外边距、元素间距（检查 ±4px 容忍度） |
| **interaction** | hover/active/disabled/focus 状态、动画时长 |
| **content** | 文案、标签、提示语是否与 PRD 一致 |
| **responsive** | 1440px / 1280px / 1024px / 768px / 375px |
| **accessibility** | ARIA label、键盘导航、颜色对比度 4.5:1 |

## 差异容忍度

| 级别 | 触发条件 | 处理 |
|------|---------|------|
| **P0** | 功能缺失、交互逻辑错误、严重布局错位 | 立即修复 |
| **P1** | 样式偏差 > 20%、文案不准确、交互不一致 | 3轮内修复 |
| **P2** | 字体大小差 2px、间距差 4px、微调建议 | 忽略，不阻塞 |

## 文件命名

```
docs/qa/
├── UI-Checklist-<功能名>-Round-<N>-<YYYYMMDD>.md
└── UI-Screenshot-<页面名>-<YYYYMMDD>.png  # 截图证据
```

## T4.5 Complete 判定

```
verdict = "pass" 当且仅当：
  summary.p0 == 0

verdict = "blocked" 当：
  summary.p0 > 0
```

## T4.Fix 迭代约定

- 每次 Fix 完成后，Designer 必须重新走查一轮（`T4.5.Recheck-N`）
- 迭代上限 3 轮；3 轮后仍有 P0 → 通知用户决策
- 3 轮后仍有 P1 → 降级为 P2 记录，继续流水线
