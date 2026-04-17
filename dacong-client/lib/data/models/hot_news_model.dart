// AI热点/快讯/开源项目数据模型
// 支持：HackerNews / GitHub Trending / AI新闻
class HotNews {
  final int id;
  final String source;       // HN / GH / RSS / DEV / PH
  final String title;
  final String url;
  final String summary;
  final String author;
  final int score;            // HN upvotes / GH stars / etc
  final DateTime fetchedAt;

  // GitHub 专有字段
  final String? language;     // 编程语言
  final String? repoOwner;    // GH仓库 owner
  final String? repoName;     // GH仓库名
  final int? stars;          // GH stars
  final int? forks;           // GH forks

  // 话题/标签
  final List<String> tags;

  const HotNews({
    required this.id,
    required this.source,
    required this.title,
    required this.url,
    this.summary = '',
    this.author = '',
    this.score = 0,
    required this.fetchedAt,
    this.language,
    this.repoOwner,
    this.repoName,
    this.stars,
    this.forks,
    this.tags = const [],
  });

  factory HotNews.fromJson(Map<String, dynamic> json) {
    return HotNews(
      id: json['id'] as int,
      source: json['source'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      summary: json['summary'] as String? ?? '',
      author: json['author'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      fetchedAt: DateTime.parse(json['fetched_at'] as String),
      language: json['language'] as String?,
      repoOwner: json['repo_owner'] as String?,
      repoName: json['repo_name'] as String?,
      stars: json['stars'] as int?,
      forks: json['forks'] as int?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'title': title,
    'url': url,
    'summary': summary,
    'author': author,
    'score': score,
    'fetched_at': fetchedAt.toIso8601String(),
    'language': language,
    'repo_owner': repoOwner,
    'repo_name': repoName,
    'stars': stars,
    'forks': forks,
    'tags': tags,
  };

  /// HackerNews 评论区链接
  String get hnCommentsUrl =>
      source == 'HN' ? 'https://news.ycombinator.com/item?id=$id' : url;

  /// GitHub 仓库地址
  String? get githubUrl =>
      (repoOwner != null && repoName != null)
          ? 'https://github.com/$repoOwner/$repoName'
          : null;

  /// 展示用 stars（优先用 GH stars，否则用 score）
  int get displayStars => stars ?? score;
}
