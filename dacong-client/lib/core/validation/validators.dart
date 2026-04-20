/// Validators
/// 验证器工具类
library;

/// 邮箱验证
class Validators {
  /// 邮箱验证
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return '邮箱不能为空';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return '邮箱格式不正确';
    }

    return null;
  }

  /// 密码验证（基础）
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return '密码不能为空';
    }

    if (value.length < 8) {
      return '密码至少需要 8 个字符';
    }

    if (value.length > 128) {
      return '密码不能超过 128 个字符';
    }

    return null;
  }

  /// 密码强度验证
  static String? passwordStrength(String? value) {
    if (value == null || value.isEmpty) {
      return '密码不能为空';
    }

    if (value.length < 8) {
      return '密码至少需要 8 个字符';
    }

    if (value.length > 128) {
      return '密码不能超过 128 个字符';
    }

    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasLowercase = value.contains(RegExp(r'[a-z]'));
    final hasDigit = value.contains(RegExp(r'\d'));
    final hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasUppercase) {
      return '密码必须包含至少一个大写字母';
    }

    if (!hasLowercase) {
      return '密码必须包含至少一个小写字母';
    }

    if (!hasDigit) {
      return '密码必须包含至少一个数字';
    }

    if (!hasSpecialChar) {
      return '密码建议包含特殊字符以提高安全性';
    }

    return null;
  }

  /// 用户名验证
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return '用户名不能为空';
    }

    if (value.length < 3) {
      return '用户名至少需要 3 个字符';
    }

    if (value.length > 30) {
      return '用户名不能超过 30 个字符';
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!usernameRegex.hasMatch(value)) {
      return '用户名只能包含字母、数字、下划线和连字符';
    }

    return null;
  }

  /// 最小长度验证
  static String? minLength(String? value, int min) {
    if (value == null || value.isEmpty) {
      return '不能为空';
    }

    if (value.length < min) {
      return '至少需要 $min 个字符';
    }

    return null;
  }

  /// 最大长度验证
  static String? maxLength(String? value, int max) {
    if (value == null) {
      return null;
    }

    if (value.length > max) {
      return '不能超过 $max 个字符';
    }

    return null;
  }

  /// 长度范围验证
  static String? lengthRange(String? value, int min, int max) {
    if (value == null || value.isEmpty) {
      return '不能为空';
    }

    if (value.length < min) {
      return '至少需要 $min 个字符';
    }

    if (value.length > max) {
      return '不能超过 $max 个字符';
    }

    return null;
  }

  /// URL 验证
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL 不能为空';
    }

    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return 'URL 格式不正确';
      }
      return null;
    } catch (e) {
      return 'URL 格式不正确';
    }
  }

  /// HTTPS URL 验证
  static String? httpsUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL 不能为空';
    }

    try {
      final uri = Uri.parse(value);
      if (uri.scheme != 'https') {
        return 'URL 必须使用 HTTPS 协议';
      }
      if (!uri.hasAuthority) {
        return 'URL 格式不正确';
      }
      return null;
    } catch (e) {
      return 'URL 格式不正确';
    }
  }

  /// 整数验证
  static String? integer(String? value) {
    if (value == null || value.isEmpty) {
      return '不能为空';
    }

    if (int.tryParse(value) == null) {
      return '必须是整数';
    }

    return null;
  }

  /// 正整数验证
  static String? positiveInteger(String? value) {
    if (value == null || value.isEmpty) {
      return '不能为空';
    }

    final intValue = int.tryParse(value);
    if (intValue == null) {
      return '必须是整数';
    }

    if (intValue <= 0) {
      return '必须是正整数';
    }

    return null;
  }

  /// 数字范围验证
  static String? range(String? value, int min, int max) {
    if (value == null || value.isEmpty) {
      return '不能为空';
    }

    final intValue = int.tryParse(value);
    if (intValue == null) {
      return '必须是整数';
    }

    if (intValue < min || intValue > max) {
      return '必须在 $min 到 $max 之间';
    }

    return null;
  }

  /// 正则表达式验证
  static String? pattern(String? value, RegExp pattern, String message) {
    if (value == null || value.isEmpty) {
      return '不能为空';
    }

    if (!pattern.hasMatch(value)) {
      return message;
    }

    return null;
  }

  /// 自定义验证
  static String? custom(
    String? value,
    bool Function(String) validator,
    String message,
  ) {
    if (value == null || value.isEmpty) {
      return '不能为空';
    }

    if (!validator(value)) {
      return message;
    }

    return null;
  }

  /// 必填验证
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName不能为空' : '不能为空';
    }
    return null;
  }

  /// 手机号验证（中国）
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return '手机号不能为空';
    }

    final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
    if (!phoneRegex.hasMatch(value)) {
      return '手机号格式不正确';
    }

    return null;
  }

  /// 确认密码验证
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return '确认密码不能为空';
    }

    if (value != password) {
      return '两次输入的密码不一致';
    }

    return null;
  }

  /// 组合验证器
  static String? compose(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}
