// GitHub 飙升榜数据模型
// 对应 Edge Function get-rising-stars 返回的 rising_stars_rankings 行
class RisingStar {
  final String repoName;     // "owner/repo"
  final String repoUrl;
  final String? owner;
  final String? language;
  final String? description;
  final int totalStars;
  final int stars1d;
  final int stars7d;
  final int stars30d;
  final double velocity;     // 增速斜率（stars/day）
  final double rankScore;

  const RisingStar({
    required this.repoName,
    required this.repoUrl,
    this.owner,
    this.language,
    this.description,
    this.totalStars = 0,
    this.stars1d = 0,
    this.stars7d = 0,
    this.stars30d = 0,
    this.velocity = 0,
    this.rankScore = 0,
  });

  factory RisingStar.fromJson(Map<String, dynamic> json) {
    return RisingStar(
      repoName: json['repo_name'] as String,
      repoUrl: json['repo_url'] as String,
      owner: json['owner'] as String?,
      language: json['language'] as String?,
      description: json['description'] as String?,
      totalStars: json['total_stars'] as int? ?? 0,
      stars1d: json['stars_1d'] as int? ?? 0,
      stars7d: json['stars_7d'] as int? ?? 0,
      stars30d: json['stars_30d'] as int? ?? 0,
      velocity: (json['velocity'] as num?)?.toDouble() ?? 0,
      rankScore: (json['rank_score'] as num?)?.toDouble() ?? 0,
    );
  }

  /// 按周期取对应的新增星数
  int starsFor(String period) {
    switch (period) {
      case '1d':
        return stars1d;
      case '30d':
        return stars30d;
      default:
        return stars7d;
    }
  }
}
