/// Form Validators
/// 表单验证器
library;

import 'validators.dart';

/// 表单验证器集合
class FormValidators {
  /// 注册表单验证器
  static Map<String, String? Function(String?)> registrationForm() {
    return {
      'email': Validators.email,
      'password': Validators.passwordStrength,
      'username': Validators.username,
    };
  }

  /// 登录表单验证器
  static Map<String, String? Function(String?)> loginForm() {
    return {
      'email': Validators.email,
      'password': Validators.password,
    };
  }

  /// 内容创建表单验证器
  static Map<String, String? Function(String?)> contentForm() {
    return {
      'title': (value) => Validators.lengthRange(value, 1, 200),
      'description': (value) => Validators.maxLength(value, 2000),
      'content': (value) => Validators.lengthRange(value, 1, 50000),
    };
  }

  /// 评论表单验证器
  static Map<String, String? Function(String?)> commentForm() {
    return {
      'content': (value) => Validators.lengthRange(value, 1, 1000),
    };
  }

  /// 用户资料表单验证器
  static Map<String, String? Function(String?)> profileForm() {
    return {
      'username': Validators.username,
      'bio': (value) => Validators.maxLength(value, 500),
      'website': (value) {
        if (value == null || value.isEmpty) return null;
        return Validators.url(value);
      },
      'location': (value) => Validators.maxLength(value, 100),
    };
  }

  /// 修改密码表单验证器
  static Map<String, String? Function(String?)> changePasswordForm(
    String newPassword,
  ) {
    return {
      'old_password': Validators.password,
      'new_password': Validators.passwordStrength,
      'confirm_password': (value) =>
          Validators.confirmPassword(value, newPassword),
    };
  }

  /// 重置密码表单验证器
  static Map<String, String? Function(String?)> resetPasswordForm(
    String password,
  ) {
    return {
      'password': Validators.passwordStrength,
      'confirm_password': (value) => Validators.confirmPassword(value, password),
    };
  }

  /// 搜索表单验证器
  static Map<String, String? Function(String?)> searchForm() {
    return {
      'query': (value) => Validators.lengthRange(value, 1, 200),
    };
  }

  /// 反馈表单验证器
  static Map<String, String? Function(String?)> feedbackForm() {
    return {
      'comment': (value) => Validators.maxLength(value, 500),
    };
  }

  /// 举报表单验证器
  static Map<String, String? Function(String?)> reportForm() {
    return {
      'description': (value) => Validators.maxLength(value, 500),
    };
  }
}

/// 验证规则类
class ValidationRules {
  /// 标题验证规则
  static String? title(String? value) {
    return Validators.lengthRange(value, 1, 200);
  }

  /// 描述验证规则
  static String? description(String? value) {
    if (value == null || value.isEmpty) return null;
    return Validators.maxLength(value, 2000);
  }

  /// 内容验证规则
  static String? content(String? value) {
    return Validators.lengthRange(value, 1, 50000);
  }

  /// 评论验证规则
  static String? comment(String? value) {
    return Validators.lengthRange(value, 1, 1000);
  }

  /// 标签验证规则
  static String? tag(String? value) {
    if (value == null || value.isEmpty) {
      return '标签不能为空';
    }

    if (value.length > 30) {
      return '标签长度不能超过 30 个字符';
    }

    final tagRegex = RegExp(r'^[a-zA-Z0-9\-_\u4e00-\u9fa5]+$');
    if (!tagRegex.hasMatch(value)) {
      return '标签只能包含字母、数字、连字符、下划线和中文';
    }

    return null;
  }

  /// 显示名称验证规则
  static String? displayName(String? value) {
    return Validators.lengthRange(value, 1, 50);
  }

  /// 个人简介验证规则
  static String? bio(String? value) {
    if (value == null || value.isEmpty) return null;
    return Validators.maxLength(value, 500);
  }

  /// 网站验证规则
  static String? website(String? value) {
    if (value == null || value.isEmpty) return null;
    return Validators.url(value);
  }

  /// 头像 URL 验证规则
  static String? avatarUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    return Validators.httpsUrl(value);
  }

  /// 位置验证规则
  static String? location(String? value) {
    if (value == null || value.isEmpty) return null;
    return Validators.maxLength(value, 100);
  }

  /// 搜索查询验证规则
  static String? searchQuery(String? value) {
    return Validators.lengthRange(value, 1, 200);
  }

  /// 反馈评论验证规则
  static String? feedbackComment(String? value) {
    if (value == null || value.isEmpty) return null;
    return Validators.maxLength(value, 500);
  }

  /// 举报描述验证规则
  static String? reportDescription(String? value) {
    if (value == null || value.isEmpty) return null;
    return Validators.maxLength(value, 500);
  }

  /// 审核原因验证规则
  static String? reviewReason(String? value) {
    if (value == null || value.isEmpty) return null;
    return Validators.maxLength(value, 200);
  }
}
