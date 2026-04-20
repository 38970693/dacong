# 开发模式快速切换脚本

## 快速切换配置

### 全部禁用（快速开发）
```bash
# Windows (PowerShell)
$env:DEV_ENABLE_CSRF="false"
$env:DEV_ENABLE_AUTH="false"
$env:DEV_ENABLE_INPUT_VALIDATION="false"
$env:DEV_ENABLE_SQL_INJECTION_PROTECTION="false"
$env:DEV_ENABLE_XSS_PROTECTION="false"
$env:DEV_ENABLE_RATE_LIMIT="false"

# Linux/Mac
export DEV_ENABLE_CSRF=false
export DEV_ENABLE_AUTH=false
export DEV_ENABLE_INPUT_VALIDATION=false
export DEV_ENABLE_SQL_INJECTION_PROTECTION=false
export DEV_ENABLE_XSS_PROTECTION=false
export DEV_ENABLE_RATE_LIMIT=false
```

### 全部启用（测试验证）
```bash
# Windows (PowerShell)
$env:DEV_ENABLE_CSRF="true"
$env:DEV_ENABLE_AUTH="true"
$env:DEV_ENABLE_INPUT_VALIDATION="true"
$env:DEV_ENABLE_SQL_INJECTION_PROTECTION="true"
$env:DEV_ENABLE_XSS_PROTECTION="true"
$env:DEV_ENABLE_RATE_LIMIT="true"

# Linux/Mac
export DEV_ENABLE_CSRF=true
export DEV_ENABLE_AUTH=true
export DEV_ENABLE_INPUT_VALIDATION=true
export DEV_ENABLE_SQL_INJECTION_PROTECTION=true
export DEV_ENABLE_XSS_PROTECTION=true
export DEV_ENABLE_RATE_LIMIT=true
```

### 只启用认证（推荐）
```bash
# Windows (PowerShell)
$env:DEV_ENABLE_AUTH="true"

# Linux/Mac
export DEV_ENABLE_AUTH=true
```
