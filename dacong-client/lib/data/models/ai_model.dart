// AI 模型数据模型（对应 Supabase models 表 + model_raw_metrics）
class AIModel {
  final String id;
  final String name;
  final String vendor;       // OpenAI / Anthropic / GitHub / HuggingFace
  final String category;     // LLM / VLM / TTS / Embedding / etc
  final String description;
  final String? websiteUrl;
  final String? apiEndpoint;
  final bool isOpenSource;
  final List<String> tags;
  final DateTime createdAt;

  // 排名数据（来自 model_ranks join）
  final int? rankOverall;
  final int? rankCategory;
  final double? score;
  final DateTime? rankUpdatedAt;

  // 💰 价格/免费相关
  final bool isFree;              // 是否完全免费
  final bool hasFreeTier;        // 是否有免费额度
  final String? pricePer1MInput; // $ / 1M input tokens
  final String? pricePer1MOutput; // $ / 1M output tokens
  final String? contextWindow;   // 上下文窗口大小，如 "128K"

  // 📊 热度数据
  final int? weeklyDownloads;   // 周下载量
  final int? monthlyDownloads;  // 月下载量

  const AIModel({
    required this.id,
    required this.name,
    required this.vendor,
    required this.category,
    this.description = '',
    this.websiteUrl,
    this.apiEndpoint,
    this.isOpenSource = false,
    this.tags = const [],
    required this.createdAt,
    this.rankOverall,
    this.rankCategory,
    this.score,
    this.rankUpdatedAt,
    this.isFree = false,
    this.hasFreeTier = false,
    this.pricePer1MInput,
    this.pricePer1MOutput,
    this.contextWindow,
    this.weeklyDownloads,
    this.monthlyDownloads,
  });

  /// 从 Supabase JSON 构建（用于 list API）
  factory AIModel.fromJson(Map<String, dynamic> json) {
    return AIModel(
      id: json['id'] as String,
      name: json['name'] as String,
      vendor: json['vendor'] as String,
      category: json['category'] as String,
      description: json['description'] as String? ?? '',
      websiteUrl: json['website_url'] as String?,
      apiEndpoint: json['api_endpoint'] as String?,
      isOpenSource: json['is_open_source'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      rankOverall: json['rank_overall'] as int?,
      rankCategory: json['rank_category'] as int?,
      score: (json['score'] as num?)?.toDouble(),
      rankUpdatedAt: json['rank_updated_at'] != null
          ? DateTime.parse(json['rank_updated_at'] as String)
          : null,
      isFree: json['is_free'] as bool? ?? false,
      hasFreeTier: json['has_free_tier'] as bool? ?? false,
      pricePer1MInput: json['price_per_1m_input'] as String?,
      pricePer1MOutput: json['price_per_1m_output'] as String?,
      // M3 起 models.context_window 为 INTEGER，这里兼容数字与字符串两种取值
      contextWindow: json['context_window']?.toString(),
      weeklyDownloads: json['weekly_downloads'] as int?,
      monthlyDownloads: json['monthly_downloads'] as int?,
    );
  }

  /// 转为 Map（用于写入）
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'vendor': vendor,
        'category': category,
        'description': description,
        'website_url': websiteUrl,
        'api_endpoint': apiEndpoint,
        'is_open_source': isOpenSource,
        'tags': tags,
        'created_at': createdAt.toIso8601String(),
        'is_free': isFree,
        'has_free_tier': hasFreeTier,
        'price_per_1m_input': pricePer1MInput,
        'price_per_1m_output': pricePer1MOutput,
        'context_window': contextWindow,
        'weekly_downloads': weeklyDownloads,
        'monthly_downloads': monthlyDownloads,
      };

  /// 拷贝修改
  AIModel copyWith({
    String? id,
    String? name,
    String? vendor,
    String? category,
    String? description,
    String? websiteUrl,
    String? apiEndpoint,
    bool? isOpenSource,
    List<String>? tags,
    DateTime? createdAt,
    int? rankOverall,
    int? rankCategory,
    double? score,
    DateTime? rankUpdatedAt,
    bool? isFree,
    bool? hasFreeTier,
    String? pricePer1MInput,
    String? pricePer1MOutput,
    String? contextWindow,
    int? weeklyDownloads,
    int? monthlyDownloads,
  }) {
    return AIModel(
      id: id ?? this.id,
      name: name ?? this.name,
      vendor: vendor ?? this.vendor,
      category: category ?? this.category,
      description: description ?? this.description,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      isOpenSource: isOpenSource ?? this.isOpenSource,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      rankOverall: rankOverall ?? this.rankOverall,
      rankCategory: rankCategory ?? this.rankCategory,
      score: score ?? this.score,
      rankUpdatedAt: rankUpdatedAt ?? this.rankUpdatedAt,
      isFree: isFree ?? this.isFree,
      hasFreeTier: hasFreeTier ?? this.hasFreeTier,
      pricePer1MInput: pricePer1MInput ?? this.pricePer1MInput,
      pricePer1MOutput: pricePer1MOutput ?? this.pricePer1MOutput,
      contextWindow: contextWindow ?? this.contextWindow,
      weeklyDownloads: weeklyDownloads ?? this.weeklyDownloads,
      monthlyDownloads: monthlyDownloads ?? this.monthlyDownloads,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AIModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
