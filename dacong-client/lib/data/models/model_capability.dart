// 模型能力数据模型
// 对应 Edge Function get-model-comparison 返回的每一行（models 能力字段 + 补充）
import 'model_evaluation.dart';

class ModelCapability {
  final String id;
  final String name;
  final String vendor;
  final String category;
  final bool isOpenSource;

  // 能力字段（models 表 M3 扩展列）
  final int? contextWindow;      // 上下文窗口 tokens
  final int? maxOutputTokens;    // 最大输出 tokens
  final int? latencyMs;          // 首 token 延迟中位数（ms）
  final int? throughputTps;      // 输出速度中位数（tokens/s）
  final List<String> multimodalInputs; // text / image / speech / video
  final bool toolUse;
  final bool fineTunable;

  // 价格补充（artificial_analysis_rankings）
  final double? price1mInput;
  final double? price1mOutput;

  // 评测成绩补充（model_evaluations，每个 benchmark 取最新一条）
  final List<ModelEvaluation> evaluations;

  const ModelCapability({
    required this.id,
    required this.name,
    required this.vendor,
    required this.category,
    this.isOpenSource = false,
    this.contextWindow,
    this.maxOutputTokens,
    this.latencyMs,
    this.throughputTps,
    this.multimodalInputs = const [],
    this.toolUse = false,
    this.fineTunable = false,
    this.price1mInput,
    this.price1mOutput,
    this.evaluations = const [],
  });

  factory ModelCapability.fromJson(Map<String, dynamic> json) {
    return ModelCapability(
      id: json['id'] as String,
      name: json['name'] as String,
      vendor: json['vendor'] as String? ?? '',
      category: json['category'] as String? ?? '',
      isOpenSource: json['is_open_source'] as bool? ?? false,
      contextWindow: (json['context_window'] as num?)?.toInt(),
      maxOutputTokens: (json['max_output_tokens'] as num?)?.toInt(),
      latencyMs: (json['latency_ms'] as num?)?.toInt(),
      throughputTps: (json['throughput_tps'] as num?)?.toInt(),
      multimodalInputs: (json['multimodal_inputs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      toolUse: json['tool_use'] as bool? ?? false,
      fineTunable: json['fine_tunable'] as bool? ?? false,
      price1mInput: (json['price_1m_input_tokens'] as num?)?.toDouble(),
      price1mOutput: (json['price_1m_output_tokens'] as num?)?.toDouble(),
      evaluations: (json['evaluations'] as List<dynamic>?)
              ?.map((e) => ModelEvaluation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// benchmark → 该模型最新分数，供横评表按行取值
  Map<String, ModelEvaluation> get evaluationsByBenchmark => {
        for (final e in evaluations) e.benchmark: e,
      };

  /// 12800 → "12.8K"，1048576 → "1.0M"
  static String formatTokens(int? tokens) {
    if (tokens == null) return '-';
    if (tokens >= 1000000) {
      return '${(tokens / 1000000).toStringAsFixed(1)}M';
    }
    if (tokens >= 1000) {
      return '${(tokens / 1000).toStringAsFixed(0)}K';
    }
    return tokens.toString();
  }

  String get contextWindowLabel => formatTokens(contextWindow);
  String get maxOutputLabel => formatTokens(maxOutputTokens);
  String get latencyLabel => latencyMs == null ? '-' : '$latencyMs ms';
  String get throughputLabel =>
      throughputTps == null ? '-' : '$throughputTps t/s';
  String get multimodalLabel =>
      multimodalInputs.isEmpty ? '-' : multimodalInputs.join(' / ');

  String get priceLabel {
    if (price1mInput == null && price1mOutput == null) return '-';
    final input = price1mInput?.toStringAsFixed(2) ?? '-';
    final output = price1mOutput?.toStringAsFixed(2) ?? '-';
    return '\$$input / \$$output';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ModelCapability && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
