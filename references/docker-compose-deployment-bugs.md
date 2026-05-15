# Docker Compose 部署常见 Bug

> 基于 2026-05-15 quant-trading 项目本地部署调试
> 用途：T8 部署阶段 / 本地 dev 环境搭建时必检

---

## 一、Redis 启动崩溃（空密码）

**症状**：Redis 容器 restart loop，日志：
```
FATAL CONFIG FILE ERROR: >>> 'requirepass' wrong number of arguments
```

**根因**：`--requirepass ""` 空字符串不合法

**修复**：
```yaml
redis:
  command: >
    redis-server
    --requirepass "${REDIS_PASSWORD:-}"
```

---

## 二、Redis healthcheck 空密码挂起

**症状**：healthcheck 一直 `starting`，容器实际已就绪但 health check 无响应

**根因**：`redis-cli -a $REDIS_PASSWORD` 空密码时阻塞不返回

**修复**：
```yaml
healthcheck:
  test: ["CMD-SHELL", "redis-cli -a ${REDIS_PASSWORD:-} --no-auth-warning ping | grep PONG"]
```

---

## 三、environment 硬编码覆盖 env_file

**症状**：`.env` 文件正确，但容器内 `DATABASE_URL` 仍是占位符值（如 `***`）

**根因**：
```yaml
env_file:
  - .env
environment:
  - DATABASE_URL=postgres://quant:***@postgres:5432/quant_trading  # ← 硬编码覆盖 .env
```

**修复**：
```yaml
environment:
  - DATABASE_URL=${DATABASE_URL}
  - REDIS_URL=redis://:${REDIS_PASSWORD:-}@redis:6379
```

**原则**：`environment:` 只引用 `${VAR}` 变量，不写死值

---

## 四、Postgres 数据卷密码初始化陷阱

**症状**：更新 `.env` 后 `POSTGRES_PASSWORD`，但重启后仍报 `password authentication failed`

**根因**：首次 `docker compose up -d` 时 `.env` 没有 `POSTGRES_PASSWORD`，导致 Postgres 用户密码为空字符串。数据卷已初始化，不会重新执行 init script。

**修复**：
```bash
docker compose stop postgres
docker compose rm -f postgres
docker volume rm quant-postgres-data   # 删除旧数据卷
docker compose up -d postgres          # 重新初始化
```

---

## 五、Backend expose: vs ports:

**症状**：容器内 `curl http://localhost:8080` 正常，但 host `curl localhost:8080` 连接被拒绝

**根因**：`expose:` 仅容器间可见，不映射 host 端口：
```yaml
expose:
  - "8080"       # ← 仅容器间可见，host 不可访问
```

**修复**：
```yaml
expose:
  - "8080"
ports:
  - "8082:8080"  # ← host 8082 → 容器 8080
```

---

## 六、Host 端口被其他容器占用

**症状**：`curl localhost:8080` 返回其他项目的内容（非预期 API 响应）

**根因**：其他项目的容器占用 host 端口（如 `auth-rbac-demo-frontend` 占 8080）

**修复**：
```bash
# 查看占用
docker ps -a --format "{{.ID}} {{.Image}} {{.Status}} {{.Ports}}"

# 停掉冲突容器
docker stop <container-id>
```

---

## 七、部署后验证检查清单

```bash
# 1. 所有容器 healthy
docker compose ps

# 2. Backend API（从容器内验证）
docker compose exec backend curl -sf http://localhost:8080/api/v1/health

# 3. 无数据库密码认证失败
docker compose logs backend | grep "password authentication failed"

# 4. Redis 就绪
docker compose logs redis | grep "Ready to accept connections"

# 5. 端口冲突检查（host）
ss -tlnp | grep -E "8080|8081"
```

---

## 八、docker compose up -d 前必检

1. `.env` 包含所有必要变量：`DATABASE_URL`（含密码）、`POSTGRES_PASSWORD`、`REDIS_PASSWORD=`
2. `docker-compose.yml` 里 `environment:` 无硬编码占位符
3. 无其他容器占用目标端口