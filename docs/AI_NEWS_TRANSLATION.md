# 官方动态采集与自动翻译

更新日期：2026-10-03。

## 当前状态

- Anthropic 官方新闻采集已部署并接入现有每两小时调度；首轮新增发布 8 条。2026-10-03 检查时已发布 9 条 Anthropic 内容，全站已发布 77 条英文资讯。
- `translate-ai-news` 已开发和部署。缺少有效的翻译 API Key，线上自动翻译尚未启用，翻译调度也未启用。
- 2026-10-03 一次性补齐 69 条英文资讯的中文标题和摘要，保留原有 8 条译文；本次检查的 77 条英文资讯均可切换中文。补齐使用助手翻译，不调用收费模型 API，也不等于启用了后续自动翻译。
- 英文资讯始终显示“翻译成中文”按钮。有完整译文时可点击切换；没有译文或译文不完整时禁用，并显示“暂无中文译文”。原文没有摘要时，只有标题译文也可切换。按钮采用边框和至少 40px 的触控高度，适用于 Web 与 Android 在线客户端。

## 官方来源

采集 [Anthropic Newsroom](https://www.anthropic.com/news) 中的精选卡片与新闻列表，保留官方标题、日期和链接；近期内容包括 [Sonnet 5.5](https://www.anthropic.com/claude-sonnet-5-5) 与 [Barclays 案例](https://www.anthropic.com/news/barclays-scales-claude)。

每轮最多选取最近 30 天的 20 条内容，排除未来日期、无效日期、非官方域名和重复 URL。来源开关仍由 `ai_source_settings` 控制。

列表提供摘要时直接使用；新文章没有列表摘要时，尝试提取官方文章的 description 或首段，最多保存 500 字符。摘要抓取失败会在响应中记录 `summaryFailures`，保留标题与原文链接，由已有规则生成标题摘要。首轮 8 条的摘要均正常获取。

官方列表只提供日期，未提供具体时区和小时，因此按该日期 UTC 00:00 保存，不把采集时间伪装成原始发布时间。页面结构无法识别时，该来源报告错误，其他 RSS 来源继续运行。

## 翻译方式

使用 [Anthropic Messages API](https://platform.claude.com/docs/en/api/messages/create) 的结构化工具结果，将已发布英文资讯的标题和规则摘要翻译为简体中文。默认模型为 `claude-sonnet-5-5`，可通过服务端配置改变；模型名称参考 [官方模型说明](https://platform.claude.com/docs/en/models/overview)。

每次最多处理 5 条缺少译文的已发布英文资讯，一个批次调用一次模型。仅发送标题、短摘要与资讯 ID，不发送账号凭据、用户内容或完整文章。正文作为待翻译数据，系统指令要求保留产品名、技术术语、数字及限定条件，不添加事实。

返回结果必须与请求 ID 一一对应，并具备非空、包含中文且长度受限的标题和摘要。模型错误、缺少结构化结果、ID 不匹配等情况不会被当作成功译文保存。

通过验证后仅更新 `title_zh`、`summary_zh`；原始标题、摘要、事件键、发布时间与来源 URL 均保持不变。保存时再次检查资讯仍已发布、原文未改动且仍缺少译文，避免对撤回或更新后的内容写入过期翻译。已有译文字段会保留。

Web 与 Android 仍默认展示英文；完整译文保存后，“翻译成中文／查看原文”按钮即可使用。翻译不在用户每次切换时重复调用模型。

## 免费服务选择

目前不必购买大模型服务才能提供资讯翻译。可考虑专用机器翻译 API：

- [Azure Translator F0](https://azure.microsoft.com/en-us/pricing/details/translator/) 每月提供 200 万字符免费额度；需要 Azure 账号和 Translator 资源的 Key，创建时选择 F0。详见[资源配置说明](https://learn.microsoft.com/en-us/azure/ai-services/translator/how-to/create-translator-resource)。
- [Google Cloud Translation](https://cloud.google.com/products/translate/pricing?hl=en) 普通 NMT 文本翻译每月前 50 万字符免费，超额计费。

截至本次修改，代码内自动翻译提供商仍是 Anthropic；Azure 或 Google 尚未接入。选择服务并获得凭据后，需要添加对应 API 调用、验证真实翻译，再启用调度。

## 启用步骤

1. 在项目 `prszkdbdgffbdqclbgol` 的 Edge Function Secrets 配置有效的 `ANTHROPIC_API_KEY`。可选配置 `AI_NEWS_TRANSLATION_MODEL`。密钥仅放在服务端，不使用 `NEXT_PUBLIC_*`，不提交到仓库。
2. 函数已经部署。需要重新部署时，在 `dacong-api` 目录执行：

   ```powershell
   supabase functions deploy translate-ai-news --project-ref prszkdbdgffbdqclbgol --use-api
   ```

3. 使用当前有效的服务端凭据，通过 POST 调用 `/functions/v1/translate-ai-news`；成功响应包含 `data.translated`。缺少翻译凭据返回 503，无授权返回 401，服务商调用失败返回 502。
4. 真实翻译验证通过后，在 Supabase SQL Editor 执行 `dacong-api/supabase/deploy-cron-ai-news-translation.sql`。该文件复用已有 Vault 的 `project_url` 与 `service_role_key`，不包含密钥文本。

调度为每小时第 7、22、37、52 分钟调用一次，每轮最多翻译 5 条。请求超时为 60 秒，模型调用超时为 40 秒。失败不会影响资讯采集、英文阅读或已有译文；下一次调度会重新选取仍缺译文的内容。批次优先处理发布时间较新的资讯，大量历史内容需多轮完成。

## 验证结果

- 新增 6 项测试，覆盖官方页面解析、日期和链接过滤、元信息摘要、中文结果与 ID 校验、模型请求结构、服务商失败及缺失结构化返回；连同已有规则共 21 项 Deno 测试通过，类型检查与相关 Lint 通过。
- 两个新增共享模块的行覆盖率为 97.0%（不包含 Edge Function 数据库处理入口）。
- 线上采集新增 8 条 Anthropic 内容，0 条摘要抓取失败，处理错误为空。
- 重复执行采集，新增原始记录与发布数均为 0。
- 公开 API：近 7 天 26 条，近 30 天 70 条，全部时间 71 条；原文链接、已有译文、隔离限制、匿名管理限制验证通过。
- 翻译函数无凭据时返回 503，无授权时返回 401，符合预期；尚未验证真实模型生成，因为没有可用 API Key。
- 2026-10-03 补齐后通过公开 API 验证全部 77 条英文资讯都有完整中文译文；逐条比较本次 69 条记录，原始标题、摘要、语言、发布日期、来源链接、分类和评分保持不变，已有译文字段未覆盖。
- 翻译按钮 5 项回归测试通过，覆盖无译文、完整译文、中文原文、不完整或空白译文、无原文摘要；相关 ESLint 通过。这些测试验证初始渲染状态，不代替 Android 真机点击验收。

部署后新增官方内容通过原有 Web API 和 Android 在线客户端自动展示，无须重新打 APK。
