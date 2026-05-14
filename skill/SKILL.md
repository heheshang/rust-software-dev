---
name: rust-software-dev
description: "Rust + Vue 3 全栈开发流水线 - T0 到 T9 自动化编排"
version: 4.0.0
category: pipeline
modular: true

# 执行引擎配置
execution:
  mode: orchestrated
  entry_point: T0
  state_file: .pipeline-state.json
  max_rollbacks: 3
  auto_advance: true

# 模块引用
imports:
  # 元数据层
  - "./meta/definitions.yaml"
  - "./meta/notification.yaml"
  # 节点层
  - "./nodes/T0.md"
  - "./nodes/T1.md"
  - "./nodes/T2.md"
  - "./nodes/T3.md"
  - "./nodes/T4.md"
  - "./nodes/T4.5.md"
  - "./nodes/T5.md"
  - "./nodes/T5.5.md"
  - "./nodes/T6.md"
  - "./nodes/T7.md"
  - "./nodes/T8.md"
  - "./nodes/T9.md"
  # 检查层
  - "./checks/architecture.yaml"
  - "./checks/security.yaml"
  - "./checks/contract.yaml"
  - "./checks/document.yaml"
  # 回滚层
  - "./rollback/matrix.yaml"
  - "./rollback/handler.yaml"
  # 归档层
  - "./archive/standard.yaml"
  - "./archive/auto.yaml"

# 节点依赖图 (DAG)
dependency_graph:
  T0:   [T1]
  T1:   [T2]
  T2:   [T3]
  T3:   [T4]
  T4:   [T4.5]
  T4.5: [T5]
  T5:   [T5.5]
  T5.5: [T6]
  T6:   [T7]
  T7:   [T8]
  T8:   [T9]
  T9:   []

# 触发条件
triggers:
  - command: "启动流水线"
  - command: "rust pipeline"
  - pr_comment: "/start-pipeline"

# 指标采集
metrics:
  - node_duration
  - rollback_count
  - arch_health_score
  - quality_score
---
