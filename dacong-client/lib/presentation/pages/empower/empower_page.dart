// 免费用页 - Empower Page
// ChatGPT骚操作 + AI工具合集 + Midjourney咒语
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';

class EmpowerPage extends ConsumerStatefulWidget {
  const EmpowerPage({super.key});
  @override
  ConsumerState<EmpowerPage> createState() => _EmpowerPageState();
}

class _EmpowerPageState extends ConsumerState<EmpowerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.promptSquare),
            Tab(text: l10n.workflowTutorials),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPromptSquare(),
              _buildFreeTools(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromptSquare() {
    final prompts = _chatgptPrompts;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: prompts.length,
      itemBuilder: (context, index) {
        final p = prompts[index];
        return _PromptCard(
          title: p['title']!,
          desc: p['desc']!,
          prompt: p['prompt']!,
          icon: IconData(int.parse(p['icon']!), fontFamily: 'MaterialIcons'),
          color: Color(int.parse(p['color']!)),
          platform: p['platform']!,
        );
      },
    );
  }

  Widget _buildFreeTools() {
    final tools = _freeToolsList;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final t = tools[index];
        return _ToolCard(
          name: t['name']!,
          desc: t['desc']!,
          url: t['url']!,
          icon: IconData(int.parse(t['icon']!), fontFamily: 'MaterialIcons'),
          color: Color(int.parse(t['color']!)),
          tags: (t['tags']! as String).split(','),
          price: t['price']!,
        );
      },
    );
  }

  // ── ChatGPT / Claude 提示词 ───────────────────────

  static const _chatgptPrompts = [
    {
      'title': '小红书爆款文案',
      'desc': '输入产品/话题，自动生成种草文案',
      'prompt': '你是一个小红书爆款文案高手。请为以下内容写5条小红书风格文案，要求：\n1. 每条带emoji表情（开头必须有）\n2. 情绪化、真实感、悬念感\n3. 字数80-120字\n4. 最后加3-5个相关话题标签\n\n内容：[你的主题]',
      'icon': '0xe905', // Icons.favorite
      'color': '0xFFE91E63',
      'platform': 'ChatGPT',
    },
    {
      'title': '周报生成器',
      'desc': '输入工作内容，一键生成正式周报',
      'prompt': '请根据以下工作内容，用第一人称撰写一份简洁的周报，包含：\n1. 本周完成（3-5条，用•列表）\n2. 下周计划（2-3条）\n3. 遇到的问题（如有）\n\n要求：正式但不死板，适合发给领导。\n\n工作内容：\n[粘贴你的工作内容]',
      'icon': '0xe916', // Icons.assignment
      'color': '0xFF2196F3',
      'platform': 'ChatGPT',
    },
    {
      'title': '英语邮件润色',
      'desc': '把中文意思地道地翻译成专业英文邮件',
      'prompt': 'Please translate the following Chinese text into a professional English email. Make it polite, concise, and natural (as a native English speaker would write):\n\n[中文内容]',
      'icon': '0xe0c8', // Icons.translate
      'color': '0xFF4CAF50',
      'platform': 'ChatGPT',
    },
    {
      'title': '简历优化',
      'desc': '粘贴简历，获得专业优化建议',
      'prompt': '请审查以下简历，提供具体优化建议：\n1. 措辞优化（让经历更有说服力）\n2. 结构建议\n3. 关键词优化（针对IT/互联网行业）\n4. 整体评分（1-10）及理由\n\n简历内容：\n[粘贴简历]',
      'icon': '0xe7fd', // Icons.person_search
      'color': '0xFF607D8B',
      'platform': 'ChatGPT',
    },
    {
      'title': 'Midjourney咒语生成',
      'desc': '输入图片描述，生成专业MJ指令',
      'prompt': '你是一个Midjourney提示词大师。请把以下描述转化为专业的Midjourney v6提示词，包含：\n1. 主体描述\n2. 风格参考（艺术家/风格）\n3. 参数设置（比例、质量、版本）\n4. 光线、氛围描述\n\n保持创意，可适当增强效果。\n\n描述：[你的图片想法]\n风格偏好：[写实/插画/动漫/摄影...]',
      'icon': '0xe40a', // Icons.image
      'color': '0xFFFF9800',
      'platform': '通用',
    },
    {
      'title': '程序员面试题',
      'desc': '输入岗位要求，获得面试题库和答案思路',
      'prompt': '我准备应聘[岗位名称]，请帮我：\n1. 列出10道高频面试题（含手写题）\n2. 每道题给出答案要点或思路\n3. 标注哪些题最容易深挖\n4. 给出2道场景设计题\n\n要求：真实、实用、贴合国内互联网面试风格。\n\n岗位：[岗位名称]\n要求：[岗位要求]',
      'icon': '0xe1cd', // Icons.code
      'color': '0xFF9C27B0',
      'platform': 'ChatGPT',
    },
    {
      'title': '吵架神器',
      'desc': '输入对方说的话，生成高情商回复',
      'prompt': '我和[场景]的人发生了争执，对方说：[对方说的话]\n\n请帮我生成5种不同风格的回复：\n1. 高情商型（化解尴尬）\n2. 逻辑反驳型（讲道理）\n3. 以退为进型（表面服软实际反杀）\n4. 幽默化解型（开玩笑转移）\n5. 霸气回击型（不惯着）\n\n每条不超过50字，要犀利、有用。',
      'icon': '0xe0cd', // Icons.chat
      'color': '0xFFF44336',
      'platform': 'ChatGPT',
    },
    {
      'title': '学习计划制定',
      'desc': '输入目标技能，获得详细学习路线',
      'prompt': '我想在[时间]内学会[技能]，零基础。请帮我制定一个详细的学习计划：\n1. 每周学习内容（分解到每天）\n2. 推荐学习资源（免费为主）\n3. 每个阶段的自测方法\n4. 避免踩的坑\n\n要求：具体可执行，适合上班族/学生党利用业余时间学习。\n\n目标：[技能名称]\n学习时间：[每天可用时间]\n截止日期：[目标日期]',
      'icon': '0xe80c', // Icons.school
      'color': '0xFF00BCD4',
      'platform': '通用',
    },
  ];

  // ── 免费AI工具合集 ───────────────────────

  static const _freeToolsList = [
    {
      'name': 'ChatGPT (OpenAI)',
      'desc': '最强大的通用AI助手，GPT-4o免费用，Claude 3.5 Sonnet体验极佳',
      'url': 'https://chat.openai.com',
      'icon': '0xe8a1', // Icons.smart_toy
      'color': '0xFF10A37F',
      'tags': '聊天,写作,编程,免费额度',
      'price': '免费版有GPT-4o额度',
    },
    {
      'name': 'Claude (Anthropic)',
      'desc': '长文本理解超强，适合读论文、写文章、代码审查',
      'url': 'https://claude.ai',
      'icon': '0xe8a1',
      'color': '0xFFB0602A',
      'tags': '写作,长文本,编程',
      'price': '免费使用',
    },
    {
      'name': 'Copilot (微软)',
      'desc': '微软出品，集成Edge浏览器，GPT-4免费用，适合办公人群',
      'url': 'https://copilot.microsoft.com',
      'icon': '0xe8a1',
      'color': '0xFF0078D4',
      'tags': '办公,搜索,免费GPT-4',
      'price': '免费',
    },
    {
      'name': 'Gemini (Google)',
      'desc': 'Google AI，Gemini 1.5 Pro免费用，支持100万token超长上下文',
      'url': 'https://gemini.google.com',
      'icon': '0xe8a1',
      'color': '0xFF4285F4',
      'tags': '长文本,搜索,免费',
      'price': '免费',
    },
    {
      'name': 'Kimi (月之暗面)',
      'desc': '国产AI，长文本能力突出，支持200万字上下文，中文体验好',
      'url': 'https://kimi.moonshot.cn',
      'icon': '0xe8a1',
      'color': '0xFF6C5CE7',
      'tags': '国产,长文本,中文',
      'price': '免费有额度',
    },
    {
      'name': '通义千问 (阿里)',
      'desc': '阿里大模型，Qwen2.5体验不错，开源版本可本地部署',
      'url': 'https://tongyi.aliyun.com',
      'icon': '0xe8a1',
      'color': '0xFFFF6A00',
      'tags': '国产,开源,免费',
      'price': '免费用',
    },
    {
      'name': '文心一言 (百度)',
      'desc': '百度出品，中文理解好，适合国内用户，支持图片生成',
      'url': 'https://yiyan.baidu.com',
      'icon': '0xe8a1',
      'color': '0xFF2932E3',
      'tags': '国产,图片生成,中文',
      'price': '免费有额度',
    },
    {
      'name': 'Perplexity',
      'desc': 'AI搜索引擎，能实时联网，给出带来源的答案，告别假信息',
      'url': 'https://www.perplexity.ai',
      'icon': '0xe8ac', // Icons.search
      'color': '0xFF20B2AA',
      'tags': '搜索,实时,来源',
      'price': '免费有限额',
    },
    {
      'name': 'Gamma',
      'desc': 'AI做PPT，输入主题自动生成精美幻灯片，打工人神器',
      'url': 'https://gamma.app',
      'icon': '0xe8b8', // Icons.slideshow
      'color': '0xFFE91E63',
      'tags': 'PPT,办公,AI生成',
      'price': '免费额度可用',
    },
    {
      'name': 'Notion AI',
      'desc': 'Notion笔记内置AI，帮你写总结、改错字、生成内容',
      'url': 'https://notion.so',
      'icon': '0xe8b9', // Icons.note
      'color': '0xFF000000',
      'tags': '笔记,写作,办公',
      'price': '免费额度',
    },
    {
      'name': 'Stable Diffusion',
      'desc': '免费开源AI绘图工具，本地部署完全免费，效果媲美MJ',
      'url': 'https://stable-diffusion-art.com',
      'icon': '0xe40a', // Icons.image
      'color': '0xFF9C27B0',
      'tags': 'AI绘图,开源,免费',
      'price': '本地免费',
    },
    {
      'name': 'LiblibAI (哩布)',
      'desc': '国内最大AI绘图社区，有免费在线生成额度，中文友好',
      'url': 'https://www.liblib.ai',
      'icon': '0xe40a',
      'color': '0xFFFF9800',
      'tags': 'AI绘图,中文,免费额度',
      'price': '免费额度',
    },
  ];
}

// ── 提示词卡片 ──────────────────────────────────

class _PromptCard extends StatelessWidget {
  final String title;
  final String desc;
  final String prompt;
  final IconData icon;
  final Color color;
  final String platform;

  const _PromptCard({
    required this.title,
    required this.desc,
    required this.prompt,
    required this.icon,
    required this.color,
    required this.platform,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    _platformBadge(),
                  ]),
                  const SizedBox(height: 2),
                  Text(desc, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                prompt,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _copyPrompt(context),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('复制提示词'),
                style: TextButton.styleFrom(foregroundColor: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _platformBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
    child: Text(platform, style: const TextStyle(fontSize: 10, color: Colors.grey)),
  );

  void _copyPrompt(BuildContext context) {
    // TODO: 复制到剪贴板
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制: $title'), duration: const Duration(seconds: 1)),
    );
  }
}

// ── 免费工具卡片 ──────────────────────────────────

class _ToolCard extends StatelessWidget {
  final String name;
  final String desc;
  final String url;
  final IconData icon;
  final Color color;
  final List<String> tags;
  final String price;

  const _ToolCard({
    required this.name,
    required this.desc,
    required this.url,
    required this.icon,
    required this.color,
    required this.tags,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.monetization_on, size: 12, color: Colors.green.shade600),
                    const SizedBox(width: 3),
                    Text(price, style: TextStyle(fontSize: 12, color: Colors.green.shade600, fontWeight: FontWeight.w500)),
                  ]),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                child: const Text('打开', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(desc, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: tags.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(t, style: TextStyle(fontSize: 11, color: color)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
