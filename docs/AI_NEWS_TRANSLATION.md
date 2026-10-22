# 官方动态采集与自动翻译

更新日期：2026-10-22。

## 当前状态

- 2026-10-22 检查：全站已发布 163 条英文资讯，全部有完整中文标题和摘要。采集、处理、日报与翻译调度均已启用，最近翻译任务的实际 HTTP 响应为 200，当前没有待翻译积压。
- Anthropic 官方新闻采集已部署并接入现有每两小时调度；首轮新增发布 8 条。2026-10-03 检查时已发布 9 条 Anthropic 内容，全站已发布 77 条英文资讯。
- `translate-ai-news` 已部署并切换为免 Key 的 MyMemory 匿名 API；每 15 分钟的自动翻译调度已启用，不需要绑定信用卡。
- 2026-10-03 一次性补齐 69 条英文资讯的中文标题和摘要，保留原有 8 条译文；本次检查的 77 条英文资讯均可切换中文。此次补齐使用助手翻译，后续新增资讯由 MyMemory 在免费额度内自动翻译。
- 非中文原始资讯始终显示语言切换按钮。有完整译文时默认中文，可点击“查看原文”；没有译文或译文不完整时显示英文，禁用“翻译成中文”并显示“暂无中文译文”。原文没有摘要时，只有标题译文也可切换。按钮采用边框和至少 40px 的触控高度，适用于 Web 与 Android 在线客户端。

## 官方来源

采集 [Anthropic Newsroom](https://www.anthropic.com/news) 中的精选卡片与新闻列表，保留官方标题、日期和链接；近期内容包括 [Sonnet 5.5](https://www.anthropic.com/claude-sonnet-5-5) 与 [Barclays 案例](https://www.anthropic.com/news/barclays-scales-claude)。

每轮最多选取最近 30 天的 20 条内容，排除未来日期、无效日期、非官方域名和重复 URL。来源开关仍由 `ai_source_settings` 控制。

列表提供摘要时直接使用；新文章没有列表摘要时，尝试提取官方文章的 description 或首段，最多保存 500 字符。摘要抓取失败会在响应中记录 `summaryFailures`，保留标题与原文链接，由已有规则生成标题摘要。首轮 8 条的摘要均正常获取。

官方列表只提供日期，未提供具体时区和小时，因此按该日期 UTC 00:00 保存，不把采集时间伪装成原始发布时间。页面结构无法识别时，该来源报告错误，其他 RSS 来源继续运行。

## 翻译方式

线上使用 [MyMemory 官方 API](https://mymemory.translated.net/doc/spec.php)，将已发布英文资讯的标题和短摘要从 `en` 翻译为 `zh-CN`。匿名调用无需账号、API Key 或信用卡，每日免费额度为 [5,000 字符](https://mymemory.translated.net/doc/usagelimits.php)，额度以服务商响应为准。

MyMemory 每轮最多处理 2 条缺少译文的已发布英文资讯，每条完成后立即保存，再处理下一条。后续条目遇到额度或接口错误时停止本轮，已保存的译文保留，错误响应的 `data.translated` 表示已成功保存的条数，下一轮无需重译这些条目。

仅发送公开标题和短摘要，不发送账号凭据、用户内容或完整文章，不设置邮箱或用户 IP 参数。每段最多 500 UTF-8 字节，超长文本按空格优先分段，不截断 Unicode 字符；标题与摘要相同时只翻译一次。

返回结果必须与请求 ID 一一对应，并具备非空、包含中文且长度受限的标题和摘要。HTTP 错误、服务商错误状态、额度耗尽提示、空内容或纯英文返回不会被当作成功译文保存。额度耗尽时保留英文和已有译文，后续调度重新尝试，不更换出口 IP 绕过额度。

保留 [Anthropic Messages API](https://platform.claude.com/docs/en/api/messages/create) 适配器作为可选提供商。设置 `AI_NEWS_TRANSLATION_PROVIDER=anthropic` 和有效的 `ANTHROPIC_API_KEY` 后，每轮最多翻译 5 条；默认模型为 `claude-sonnet-5-5`，可通过 `AI_NEWS_TRANSLATION_MODEL` 改变。

通过验证后仅更新 `title_zh`、`summary_zh`；原始标题、摘要、事件键、发布时间与来源 URL 均保持不变。保存时再次检查资讯仍已发布、原文未改动且仍缺少译文，避免对撤回或更新后的内容写入过期翻译。已有译文字段会保留。

Web 与 Android 对已有完整译文的资讯默认展示中文，可点击“查看原文”切换英文，再点击“翻译成中文”切回；暂无完整译文时继续显示英文。列表、详情和日报条目共用该行为，侧栏精选标题也优先显示已有中文译文。翻译不在用户每次切换时重复调用模型。

## 免费服务选择

当前选择免 Key 的 MyMemory。其他专用机器翻译 API 的免费额度可供后续评估：

- [Azure Translator F0](https://azure.microsoft.com/en-us/pricing/details/translator/) 每月提供 200 万字符免费额度；需要 Azure 账号和 Translator 资源的 Key，创建时选择 F0。详见[资源配置说明](https://learn.microsoft.com/en-us/azure/ai-services/translator/how-to/create-translator-resource)。
- [Google Cloud Translation](https://cloud.google.com/products/translate/pricing?hl=en) 普通 NMT 文本翻译每月前 50 万字符免费，超额计费。

Azure、Google 与自行托管的 [LibreTranslate](https://docs.libretranslate.com/) 尚未接入；LibreTranslate 软件免费，但需要自行提供运行服务器。

## 启用步骤

1. 在项目 `prszkdbdgffbdqclbgol` 的 Edge Function Secrets 配置 `AI_NEWS_TRANSLATION_PROVIDER=mymemory`，无需翻译密钥。该配置已在线上应用。切回 Anthropic 时才需要相应 API Key；密钥仅放在服务端，不使用 `NEXT_PUBLIC_*`，不提交到仓库。
2. 函数已经部署。需要重新部署时，在 `dacong-api` 目录执行：

   ```powershell
   supabase functions deploy translate-ai-news --project-ref prszkdbdgffbdqclbgol --use-api
   ```

3. 使用当前有效的服务端凭据，通过 POST 调用 `/functions/v1/translate-ai-news`；成功响应包含 `data.translated`。无授权返回 401；Anthropic 缺少密钥或提供商配置错误返回 503；服务商调用失败或额度耗尽返回 502，同时返回本轮已保存的 `data.translated`。
4. 真实翻译验证通过后，在 Supabase SQL Editor 执行 `dacong-api/supabase/deploy-cron-ai-news-translation.sql`。该文件复用已有 Vault 的 `project_url` 与 `service_role_key`，不包含密钥文本。

调度为每小时第 7、22、37、52 分钟调用一次，已启用。MyMemory 每轮最多翻译 2 条，Anthropic 最多 5 条；没有待翻译资讯时不请求翻译提供商。调度请求超时为 60 秒，翻译调用超时为 40 秒。失败不会影响资讯采集、英文阅读或已有译文；下一次调度会重新选取仍缺译文的内容。批次优先处理发布时间较新的资讯，大量历史内容需多轮或多日完成。

## 验证结果

- 新增 6 项测试，覆盖官方页面解析、日期和链接过滤、元信息摘要、中文结果与 ID 校验、模型请求结构、服务商失败及缺失结构化返回；连同已有规则共 21 项 Deno 测试通过，类型检查与相关 Lint 通过。
- 两个新增共享模块的行覆盖率为 97.0%（不包含 Edge Function 数据库处理入口）。
- 线上采集新增 8 条 Anthropic 内容，0 条摘要抓取失败，处理错误为空。
- 重复执行采集，新增原始记录与发布数均为 0。
- 公开 API：近 7 天 26 条，近 30 天 70 条，全部时间 71 条；原文链接、已有译文、隔离限制、匿名管理限制验证通过。
- Anthropic 适配器缺少密钥时返回 503，无授权时返回 401；未验证真实 Anthropic 模型生成，因为没有该服务的可用 API Key。
- 2026-10-03 补齐后通过公开 API 验证全部 77 条英文资讯都有完整中文译文；逐条比较本次 69 条记录，原始标题、摘要、语言、发布日期、来源链接、分类和评分保持不变，已有译文字段未覆盖。
- 翻译按钮 6 项回归测试通过，覆盖无译文、完整译文默认中文、中文原文、不完整或空白译文、无原文摘要、详情中文标题和摘要；相关 ESLint 通过。这些测试验证初始渲染状态，不代替 Android 真机点击验收。
- MyMemory 新增 4 项测试，涵盖 UTF-8 分段边界、匿名调用参数、标题摘要去重、空批次及配额/错误结果拒绝；共享模块共 25 项 Deno 测试通过，Edge Function 类型检查和相关 Lint 通过。
- 已用真实 MyMemory API 翻译一条公开资讯的标题和摘要，返回中文且通过结果校验。线上翻译函数返回成功、翻译数为 0：现有 77 条资讯已有译文，本次未改写。匿名调用仍返回 401，定时任务状态为启用。
- 2026-10-22 修复批次中后续失败丢弃先前成功结果的问题，新增 7 项 handler 链路测试：逐条保存顺序、首条失败、第二条额度/HTTP 错误时保留成功条数、已有译文和原文保护、整轮共享超时、Anthropic 批量调用。共享模块及 handler 共 32 项测试通过，入口类型检查、相关 Lint 通过。逐条保存行为通过真实 Supabase client 配合 mock HTTP 验证，未在生产库人为清空译文制造失败。
- 修复已部署到线上。验证期间新增的 1 条待翻译资讯通过真实函数调用完成翻译和保存，公开资讯总数从 162 增至 163，缺少译文的数量为 0。使用调度相同 Vault 凭据经 `pg_net` 调用返回 HTTP 200，匿名调用返回 401。浏览器验收接口仍超时，未取得本次手机截图或真实切换结果。

部署后新增官方内容通过原有 Web API 和 Android 在线客户端自动展示，无须重新打 APK。
