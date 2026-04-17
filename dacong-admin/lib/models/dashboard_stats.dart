class DashboardStats {
  final int todayDau;
  final int todayPv;
  final int todayUv;
  final int newUsers;
  final int publishedContent;
  final int totalUsers;
  final int totalContent;
  final int pendingReview;
  final int totalComments;
  final int pendingComments;
  final double dauChange;
  final double pvChange;
  final double uvChange;
  final double newUsersChange;

  DashboardStats({
    required this.todayDau,
    required this.todayPv,
    required this.todayUv,
    required this.newUsers,
    required this.publishedContent,
    required this.totalUsers,
    required this.totalContent,
    required this.pendingReview,
    required this.totalComments,
    required this.pendingComments,
    required this.dauChange,
    required this.pvChange,
    required this.uvChange,
    required this.newUsersChange,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      todayDau: json['today_dau'] ?? 0,
      todayPv: json['today_pv'] ?? 0,
      todayUv: json['today_uv'] ?? 0,
      newUsers: json['new_users'] ?? 0,
      publishedContent: json['published_content'] ?? 0,
      totalUsers: json['total_users'] ?? 0,
      totalContent: json['total_content'] ?? 0,
      pendingReview: json['pending_review'] ?? 0,
      totalComments: json['total_comments'] ?? 0,
      pendingComments: json['pending_comments'] ?? 0,
      dauChange: (json['dau_change'] ?? 0).toDouble(),
      pvChange: (json['pv_change'] ?? 0).toDouble(),
      uvChange: (json['uv_change'] ?? 0).toDouble(),
      newUsersChange: (json['new_users_change'] ?? 0).toDouble(),
    );
  }
}

class TrendData {
  final List<String> labels;
  final List<double> dauData;
  final List<double> pvData;
  final List<double> uvData;

  TrendData({
    required this.labels,
    required this.dauData,
    required this.pvData,
    required this.uvData,
  });

  factory TrendData.fromJson(Map<String, dynamic> json) {
    return TrendData(
      labels: List<String>.from(json['labels'] ?? []),
      dauData: List<double>.from(json['dau_data'] ?? []),
      pvData: List<double>.from(json['pv_data'] ?? []),
      uvData: List<double>.from(json['uv_data'] ?? []),
    );
  }
}

class TopContent {
  final String id;
  final String title;
  final int views;
  final int likes;
  final double helpfulRate;

  TopContent({
    required this.id,
    required this.title,
    required this.views,
    required this.likes,
    required this.helpfulRate,
  });

  factory TopContent.fromJson(Map<String, dynamic> json) {
    return TopContent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      helpfulRate: (json['helpful_rate'] ?? 0).toDouble(),
    );
  }
}

class SearchKeyword {
  final String keyword;
  final int count;

  SearchKeyword({
    required this.keyword,
    required this.count,
  });

  factory SearchKeyword.fromJson(Map<String, dynamic> json) {
    return SearchKeyword(
      keyword: json['keyword'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class PendingTasks {
  final int pendingContents;
  final int pendingComments;
  final int pendingReports;
  final int pendingAppeals;

  PendingTasks({
    required this.pendingContents,
    required this.pendingComments,
    required this.pendingReports,
    required this.pendingAppeals,
  });

  int get total => pendingContents + pendingComments + pendingReports + pendingAppeals;

  factory PendingTasks.fromJson(Map<String, dynamic> json) {
    return PendingTasks(
      pendingContents: json['pending_contents'] ?? 0,
      pendingComments: json['pending_comments'] ?? 0,
      pendingReports: json['pending_reports'] ?? 0,
      pendingAppeals: json['pending_appeals'] ?? 0,
    );
  }
}
