/// Admin Validators
/// 管理后台验证器
library;

/// 管理后台验证器
class AdminValidators {
  /// 批量 ID 验证
  static String? batchIds(List<String>? ids) {
    if (ids == null || ids.isEmpty) {
      return '至少选择一项';
    }

    if (ids.length > 100) {
      return '一次最多处理 100 项';
    }

    return null;
  }

  /// 批量操作验证
  static String? batchAction(String? action) {
    if (action == null || action.isEmpty) {
      return '请选择操作';
    }

    final validActions = ['approve', 'reject', 'delete'];
    if (!validActions.contains(action)) {
      return '无效的操作';
    }

    return null;
  }

  /// 封禁原因验证
  static String? banReason(String? reason) {
    if (reason == null || reason.isEmpty) {
      return '封禁原因不能为空';
    }

    if (reason.length < 1 || reason.length > 500) {
      return '封禁原因长度必须在 1-500 个字符之间';
    }

    return null;
  }

  /// 封禁时长验证
  static String? banDuration(String? duration) {
    if (duration == null || duration.isEmpty) {
      return null; // 可选，null 表示永久封禁
    }

    final intValue = int.tryParse(duration);
    if (intValue == null) {
      return '时长必须是整数';
    }

    if (intValue <= 0) {
      return '时长必须大于 0';
    }

    if (intValue > 8760) {
      // 最多 365 天
      return '时长不能超过 365 天（8760 小时）';
    }

    return null;
  }

  /// 审核原因验证
  static String? reviewReason(String? reason) {
    if (reason == null || reason.isEmpty) {
      return null; // 可选
    }

    if (reason.length > 200) {
      return '审核原因不能超过 200 个字符';
    }

    return null;
  }

  /// 配置键验证
  static String? configKey(String? key) {
    if (key == null || key.isEmpty) {
      return '配置键不能为空';
    }

    final keyRegex = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
    if (!keyRegex.hasMatch(key)) {
      return '配置键只能包含字母、数字和下划线，且必须以字母或下划线开头';
    }

    if (key.length > 100) {
      return '配置键不能超过 100 个字符';
    }

    return null;
  }

  /// 配置值验证
  static String? configValue(String? value) {
    if (value == null || value.isEmpty) {
      return '配置值不能为空';
    }

    if (value.length > 1000) {
      return '配置值不能超过 1000 个字符';
    }

    return null;
  }

  /// 用户角色验证
  static String? userRole(String? role) {
    if (role == null || role.isEmpty) {
      return '请选择用户角色';
    }

    final validRoles = ['user', 'moderator', 'admin'];
    if (!validRoles.contains(role)) {
      return '无效的用户角色';
    }

    return null;
  }

  /// 内容状态验证
  static String? contentStatus(String? status) {
    if (status == null || status.isEmpty) {
      return '请选择内容状态';
    }

    final validStatuses = ['pending', 'approved', 'rejected', 'flagged'];
    if (!validStatuses.contains(status)) {
      return '无效的内容状态';
    }

    return null;
  }

  /// 审核操作验证
  static String? moderationAction(String? action) {
    if (action == null || action.isEmpty) {
      return '请选择审核操作';
    }

    final validActions = ['approve', 'reject', 'delete', 'flag'];
    if (!validActions.contains(action)) {
      return '无效的审核操作';
    }

    return null;
  }

  /// 日期范围验证
  static String? dateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return null; // 可选
    }

    if (startDate.isAfter(endDate)) {
      return '开始日期必须早于或等于结束日期';
    }

    return null;
  }

  /// 分页参数验证
  static String? page(String? value) {
    if (value == null || value.isEmpty) {
      return null; // 使用默认值
    }

    final intValue = int.tryParse(value);
    if (intValue == null) {
      return '页码必须是整数';
    }

    if (intValue < 1) {
      return '页码必须大于 0';
    }

    return null;
  }

  /// 每页数量验证
  static String? limit(String? value) {
    if (value == null || value.isEmpty) {
      return null; // 使用默认值
    }

    final intValue = int.tryParse(value);
    if (intValue == null) {
      return '每页数量必须是整数';
    }

    if (intValue < 1 || intValue > 100) {
      return '每页数量必须在 1-100 之间';
    }

    return null;
  }

  /// 排序字段验证
  static String? sortBy(String? value) {
    if (value == null || value.isEmpty) {
      return null; // 使用默认值
    }

    final validFields = [
      'created_at',
      'updated_at',
      'title',
      'username',
      'email',
      'status',
    ];

    if (!validFields.contains(value)) {
      return '无效的排序字段';
    }

    return null;
  }

  /// 排序顺序验证
  static String? sortOrder(String? value) {
    if (value == null || value.isEmpty) {
      return null; // 使用默认值
    }

    final validOrders = ['asc', 'desc'];
    if (!validOrders.contains(value)) {
      return '排序顺序必须是 asc 或 desc';
    }

    return null;
  }
}
