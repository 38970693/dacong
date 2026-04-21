# GitHub Copilot 配置指南

## 1. 购买和分配

### 购买方式
- 访问：https://github.com/features/copilot
- 选择：GitHub Copilot Business ($19/user/month)
- 为13名开发人员购买：$247/月

### 分配给团队成员
```bash
# 在GitHub Organization设置中
Settings → Copilot → Enable for organization
→ Add users (13名开发人员)
```

## 2. IDE集成

### VS Code
```bash
# 安装扩展
code --install-extension GitHub.copilot
code --install-extension GitHub.copilot-chat
```

### JetBrains IDEs
```bash
# Settings → Plugins → Marketplace
搜索 "GitHub Copilot" → Install
```

## 3. 配置最佳实践

### VS Code settings.json
```json
{
  "github.copilot.enable": {
    "*": true,
    "yaml": true,
    "plaintext": false,
    "markdown": true
  },
  "github.copilot.advanced": {
    "debug.overrideEngine": "gpt-4",
    "inlineSuggestCount": 3
  }
}
```

## 4. 使用技巧

### 编写清晰的注释
```typescript
// 创建一个函数，从Supabase获取用户列表，支持分页和搜索
// Copilot会自动生成完整的函数实现
```

### 使用描述性函数名
```typescript
async function getUsersWithPaginationAndSearch() {
  // Copilot会根据函数名生成实现
}
```

### 测试生成
```typescript
// 为上面的函数生成单元测试
// Copilot会自动生成完整的测试用例
```

## 5. 预期效果

- 代码编写速度提升：40-50%
- 测试用例生成：节省60%时间
- 文档编写：节省50%时间
- 样板代码：几乎零时间

## 6. 成本效益

- 月成本：$247
- 节省工时：约40小时/月
- 节省成本：约$4,000/月
- ROI：1,520%
