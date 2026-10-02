# AI 动态热点与体验调整记录

更新日期：2026-10-02。

## 调整依据

检索厂商官方发布与开发者社区信息后，本轮优先关注 Agent、AI 编程、模型效率、开源生态和企业应用。这个选择是产品编辑判断，不代表跨平台热度排名。厂商提供的性能与成本数据也不等同于独立评测结果。

| 近期信息 | 对产品的启示 | 原始来源 |
|---|---|---|
| OpenAI 9 月 10 日发布 Agents API，强调工具、上下文管理与长期任务 | 开发工具分类覆盖 Codex、MCP、Agent 与 harness | [官方发布](https://openai.com/index/introducing-the-agents-api/) |
| Anthropic 9 月 28 日发布 Sonnet 5.5，重点说明编程、速度与任务成本 | 关注实际使用效率，移除过时的固定模型话题 | [官方发布](https://www.anthropic.com/claude-sonnet-5-5) |
| Anthropic 10 月 1 日披露 Barclays 扩大 Claude 应用 | 保留企业应用与行业分类，同时排除无关商业新闻 | [官方案例](https://www.anthropic.com/news/barclays-scales-claude) |
| Hugging Face 持续发布模型与开发生态内容 | 增加官方开源生态来源 | [官方博客](https://huggingface.co/blog) |

## 已实现

### 真实资讯代替固定热点

- 侧栏移除写死的模型话题、讨论人数、排行榜与推荐用户。
- 展示近 7 日真实精选动态及来源分布。来源数量仅统计当前精选列表，最多 30 条，不代表全网或全站数量。
- 资讯流默认近 7 天，支持近 30 天及全部时间；保留精选/最新、分类筛选和原文/已有中文译文切换。
- 增加卡片上的“阅读原文”入口。隐藏普通用户无须理解的内部质量分。
- 更新网站标题、描述和页面文案，突出 AI 动态与每日摘要。

### 采集与发布质量

- 扩充 OpenAI、Hugging Face、GitHub 官方 RSS，保留 Google、MIT、TheSequence 与 VentureBeat。
- Python 采集支持 RSS 与 Atom，保存 `source_published_at`；原始日期有效时用它判断新鲜度与计算事件键，无法获取时保留采集时间回退。
- 单独判断 AI 相关性，通用的 company、policy、release、paper 等分类词不再足以证明内容与 AI 有关。
- 来源的 AI 标签须与正文/标题信号共同生效，未来日期内容进入隔离区。
- 复核历史内容，对能够在 RSS 中匹配的记录补充原始日期；2 条已发布的非 AI 内容移入隔离区，原始数据仍保留。

### 自动更新

Supabase 中已经启用以下任务，RSS 主链路独立于 GitHub 工作流：

| 任务 | 时间 | 行为 |
|---|---|---|
| `collect-ai-news-two-hourly` | UTC 偶数小时第 17 分钟，北京时间相同偶数小时第 17 分钟 | 并行抓取 7 个 RSS，每个来源最多选 20 条最近 30 天内容；按来源和 URL 查询去重，跳过已禁用来源，写入后调用处理函数 |
| `process-ai-news-quarter-hourly` | 每 15 分钟 | 处理待精选原始内容、分类、评分与合并来源 |
| `generate-ai-digest-daily` | 北京时间 08:00 | 选取过去 24 小时已发布动态，最多 10 条 |

采集只接受 HTTP(S) 原文链接与有效且不在未来的原始日期。单个源失败不会阻断其他源，响应中单独列出来源错误；全部来源失败时返回错误。采集后的处理失败由每 15 分钟任务继续处理。

此次线上执行中，OpenAI、Hugging Face、GitHub、Google、MIT、TheSequence 共 6 个来源成功；VentureBeat 返回 429。本轮新增发布 55 条、隔离 28 条。复核后的总量为 **63 条发布、31 条隔离**；2026-10-02 日报重算为 **4 条**。重复采集及处理均未增加重复记录。

## 验证

- Deno：相关性、日期、去重、RSS/Atom 与日报规则，共 15 项测试通过；两个 Edge Function 类型检查通过。
- Python：RSS、arXiv、GitHub、Hugging Face、Bluesky 与 X 的相关测试，共 55 项通过。
- Web：修改文件的 ESLint 通过，Next.js 生产构建通过。
- Supabase：函数调用与三项调度已验证；原始发布时间迁移已应用。
- Android 1.1.0 使用在线 WebView，页面调整自动同步，无须为此次内容调整重新打包。

## 尚可继续改善

1. **新资讯自动翻译**：当前只有已经保存译文的条目显示语言切换。尚未配置翻译服务，新增资讯不会凭空获得中文译文。后续接入服务时，应保存译文并保留原文与来源链接。
2. **补足未提供 RSS 的官方来源**：例如 Anthropic 新闻页需要单独的 HTML 采集适配；本轮调查参考了它的官方发布，但没有宣称已经接入自动采集。
3. **开源飙升榜与模型评测的新鲜度**：这些扩展数据仍由原有 Python 采集负责，不能把 RSS 更新视为所有榜单都已更新。
4. **仓库与发布流程**：GitHub 凭据权限不足，提交在本地；当前生产部署直接通过 Vercel 完成。后续补足仓库权限即可启用已有工作流。

生产入口：[AI 动态](https://dacong-weld.vercel.app/web/dynamics)。
