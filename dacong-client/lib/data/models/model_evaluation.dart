// 大模型评测成绩数据模型
// 对应 Edge Function get-model-evaluations 返回的 model_evaluations 行
class ModelEvaluation {
  final String benchmark;   // MMLU-Pro / GPQA / HumanEval / Arena-ELO ...
  final double? score;
  final String? category;   // general / coding / math / vision / chinese / agentic
  final String source;      // artificial_analysis / lmarena
  final DateTime evalDate;

  const ModelEvaluation({
    required this.benchmark,
    this.score,
    this.category,
    required this.source,
    required this.evalDate,
  });

  factory ModelEvaluation.fromJson(Map<String, dynamic> json) {
    return ModelEvaluation(
      benchmark: json['benchmark'] as String,
      score: (json['score'] as num?)?.toDouble(),
      category: json['category'] as String?,
      source: json['source'] as String? ?? '',
      evalDate: DateTime.parse(json['eval_date'] as String),
    );
  }

  /// Arena-ELO 是 1000+ 的绝对分，其余 benchmark 已统一成百分制
  bool get isElo => benchmark == 'Arena-ELO';

  String get scoreLabel {
    if (score == null) return '-';
    return isElo ? score!.toStringAsFixed(0) : '${score!.toStringAsFixed(1)}%';
  }
}
