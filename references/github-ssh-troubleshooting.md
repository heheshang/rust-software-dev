# GitHub SSH 推送故障排查

## 常见错误与解决方案

### 错误1: `Permission denied (publickey)` — 认证失败

```
git push origin main
# → Permission denied (publickey)
```

**诊断：**
```bash
ssh -T git@github.com -o StrictHostKeyChecking=no
# → Permission denied (publickey) → SSH Key 未上传 GitHub
```

**解决：** GitHub → Settings → SSH and GPG keys → New SSH key → 添加公钥

---

### 错误2: `Permission to heheshang/quant-trading.git denied` — 403 Forbidden

```
git push origin main
# → remote: Permission to heheshang/quant-trading.git denied to heheshang.
# → fatal: unable to access 'https://github.com/heheshang/quant-trading.git/': The 403
```

**诊断：** HTTPS URL + 无 token 认证，或 SSH URL + key 权限不足

**解决：**
1. 检查当前 remote：`git remote -v`
2. 如果是 HTTPS → 改用 SSH：
   ```bash
   git remote set-url origin git@github.com:heheshang/quant-trading.git
   ```
3. 如果是 SSH → 检查 key 类型（见下）

---

### 错误3: `The key you are authenticating with has been marked as read only` — SSH Key 只读

```
ssh -T git@github.com
# → Hi heheshang! You've successfully authenticated, but GitHub does not provide shell access.
git push
# → ERROR: The key you are authenticating with has been marked as read only.
```

**根因：** GitHub 上传的是 **Read-only key**（只能 `git fetch`，不能 `git push`）

**解决：**
1. GitHub → Settings → SSH and GPG keys
2. 删除旧的只读 key
3. 添加新的 **Read/write key**（类型选择 `Authentication key`，不是 `Signing key`）
4. 验证：`ssh -T git@github.com` 应显示认证成功

**判断方法：**
- 只读 key 添加时：key type 显示 "Read only"
- 读写 key 添加时：key type 显示 "Authentication key"（无 Read only 标记）

---

### 完整推送流程

```bash
# 1. 确认 SSH key 存在
ls ~/.ssh/id_ed25519.pub   # 或 id_rsa.pub

# 2. 测试认证（SSH）
ssh -T git@github.com -o StrictHostKeyChecking=no
# 期望输出：Hi <username>! You've successfully authenticated...

# 3. 设置 SSH remote（不是 HTTPS）
git remote -v
# 如果显示 https://github.com/<user>/<repo>.git
# 则改为：git remote set-url origin git@github.com:<user>/<repo>.git

# 4. 推送
git push origin main
```

---

### 验证：SSH vs HTTPS Remote

```bash
# SSH (推荐)
git@github.com:heheshang/quant-trading.git

# HTTPS (需要 token)
https://github.com/heheshang/quant-trading.git
```

---

*2026-05-13 实测：ssk-server 添加 Read-only SSH key 后 push 失败，改用 Authentication key 后成功。*
