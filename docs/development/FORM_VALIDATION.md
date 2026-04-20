# 表单验证指南

## 概述

本文档介绍如何在 DaCong Flutter 应用中实现表单验证，包括实时验证、异步验证和自定义验证规则。

## 目录

- [基础验证](#基础验证)
- [表单验证器](#表单验证器)
- [验证文本框组件](#验证文本框组件)
- [异步验证](#异步验证)
- [自定义验证](#自定义验证)
- [最佳实践](#最佳实践)

---

## 基础验证

### 导入验证器

```dart
import 'package:dacong_client/core/validation/validators.dart';
```

### 使用内置验证器

```dart
// 邮箱验证
final emailError = Validators.email(emailController.text);
if (emailError != null) {
  // 显示错误消息
  print(emailError); // "邮箱格式不正确"
}

// 密码验证
final passwordError = Validators.password(passwordController.text);

// 密码强度验证
final strengthError = Validators.passwordStrength(passwordController.text);

// 用户名验证
final usernameError = Validators.username(usernameController.text);

// 长度验证
final lengthError = Validators.lengthRange(value, 3, 30);

// URL 验证
final urlError = Validators.url(urlController.text);

// HTTPS URL 验证
final httpsError = Validators.httpsUrl(urlController.text);
```

### 组合验证器

```dart
final error = Validators.compose(value, [
  Validators.required,
  (v) => Validators.minLength(v, 3),
  (v) => Validators.maxLength(v, 30),
  Validators.username,
]);
```

---

## 表单验证器

### 导入表单验证器

```dart
import 'package:dacong_client/core/validation/form_validators.dart';
```

### 注册表单

```dart
class RegistrationForm extends StatefulWidget {
  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final validators = FormValidators.registrationForm();

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: '邮箱'),
            validator: validators['email'],
          ),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: '密码'),
            obscureText: true,
            validator: validators['password'],
          ),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(labelText: '用户名'),
            validator: validators['username'],
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // 表单验证通过，提交数据
                _submitForm();
              }
            },
            child: Text('注册'),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    // 提交表单逻辑
  }
}
```

### 登录表单

```dart
final validators = FormValidators.loginForm();

TextFormField(
  controller: _emailController,
  validator: validators['email'],
)

TextFormField(
  controller: _passwordController,
  validator: validators['password'],
  obscureText: true,
)
```

### 内容创建表单

```dart
final validators = FormValidators.contentForm();

TextFormField(
  controller: _titleController,
  validator: validators['title'],
  decoration: InputDecoration(labelText: '标题'),
)

TextFormField(
  controller: _descriptionController,
  validator: validators['description'],
  decoration: InputDecoration(labelText: '描述'),
  maxLines: 3,
)

TextFormField(
  controller: _contentController,
  validator: validators['content'],
  decoration: InputDecoration(labelText: '内容'),
  maxLines: 10,
)
```

### 评论表单

```dart
final validators = FormValidators.commentForm();

TextFormField(
  controller: _commentController,
  validator: validators['content'],
  decoration: InputDecoration(labelText: '评论'),
  maxLines: 3,
)
```

### 用户资料表单

```dart
final validators = FormValidators.profileForm();

TextFormField(
  controller: _usernameController,
  validator: validators['username'],
)

TextFormField(
  controller: _bioController,
  validator: validators['bio'],
  maxLines: 3,
)

TextFormField(
  controller: _websiteController,
  validator: validators['website'],
)

TextFormField(
  controller: _locationController,
  validator: validators['location'],
)
```

### 修改密码表单

```dart
final _newPasswordController = TextEditingController();
final validators = FormValidators.changePasswordForm(
  _newPasswordController.text,
);

TextFormField(
  controller: _oldPasswordController,
  validator: validators['old_password'],
  obscureText: true,
)

TextFormField(
  controller: _newPasswordController,
  validator: validators['new_password'],
  obscureText: true,
)

TextFormField(
  controller: _confirmPasswordController,
  validator: validators['confirm_password'],
  obscureText: true,
)
```

---

## 验证文本框组件

### 导入组件

```dart
import 'package:dacong_client/presentation/widgets/validated_text_field.dart';
import 'package:dacong_client/core/validation/validators.dart';
```

### 基础用法

```dart
ValidatedTextField(
  label: '邮箱',
  hint: '请输入邮箱地址',
  validator: Validators.email,
  keyboardType: TextInputType.emailAddress,
  prefixIcon: Icons.email,
)
```

### 密码输入框

```dart
ValidatedTextField(
  label: '密码',
  hint: '请输入密码',
  validator: Validators.passwordStrength,
  obscureText: true,
  prefixIcon: Icons.lock,
)
```

### 带控制器

```dart
final _emailController = TextEditingController();

ValidatedTextField(
  controller: _emailController,
  label: '邮箱',
  validator: Validators.email,
)
```

### 带输入变化回调

```dart
ValidatedTextField(
  label: '搜索',
  hint: '输入关键词搜索',
  prefixIcon: Icons.search,
  onChanged: (value) {
    // 处理输入变化
    print('搜索: $value');
  },
)
```

### 带提交回调

```dart
ValidatedTextField(
  label: '邮箱',
  validator: Validators.email,
  onSubmitted: (value) {
    // 处理提交
    _submitForm();
  },
)
```

### 自定义防抖延迟

```dart
ValidatedTextField(
  label: '用户名',
  validator: Validators.username,
  debounceDelay: 300, // 300ms 防抖
)
```

---

## 异步验证

### 检查用户名唯一性

```dart
ValidatedTextField(
  label: '用户名',
  hint: '请输入用户名',
  validator: Validators.username,
  asyncValidator: (value) async {
    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      final response = await ApiService.checkUsername(value);
      return response.exists ? '用户名已被使用' : null;
    } catch (e) {
      return '验证失败，请重试';
    }
  },
  debounceDelay: 500,
)
```

### 检查邮箱唯一性

```dart
ValidatedTextField(
  label: '邮箱',
  validator: Validators.email,
  asyncValidator: (value) async {
    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      final response = await ApiService.checkEmail(value);
      return response.exists ? '邮箱已被注册' : null;
    } catch (e) {
      return '验证失败，请重试';
    }
  },
)
```

### 验证邀请码

```dart
ValidatedTextField(
  label: '邀请码',
  validator: (value) => Validators.lengthRange(value, 6, 6),
  asyncValidator: (value) async {
    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      final response = await ApiService.validateInviteCode(value);
      return response.valid ? null : '邀请码无效';
    } catch (e) {
      return '验证失败，请重试';
    }
  },
)
```

---

## 自定义验证

### 自定义验证规则

```dart
String? validateAge(String? value) {
  if (value == null || value.isEmpty) {
    return '年龄不能为空';
  }

  final age = int.tryParse(value);
  if (age == null) {
    return '年龄必须是数字';
  }

  if (age < 18) {
    return '必须年满 18 岁';
  }

  if (age > 120) {
    return '年龄不合理';
  }

  return null;
}

// 使用
ValidatedTextField(
  label: '年龄',
  validator: validateAge,
  keyboardType: TextInputType.number,
)
```

### 使用正则表达式

```dart
String? validatePhoneNumber(String? value) {
  return Validators.pattern(
    value,
    RegExp(r'^1[3-9]\d{9}$'),
    '手机号格式不正确',
  );
}

ValidatedTextField(
  label: '手机号',
  validator: validatePhoneNumber,
  keyboardType: TextInputType.phone,
)
```

### 条件验证

```dart
String? validateOptionalUrl(String? value) {
  // 如果为空，不验证
  if (value == null || value.isEmpty) {
    return null;
  }

  // 如果不为空，验证 URL 格式
  return Validators.url(value);
}

ValidatedTextField(
  label: '个人网站（可选）',
  validator: validateOptionalUrl,
)
```

### 跨字段验证

```dart
class PasswordForm extends StatefulWidget {
  @override
  _PasswordFormState createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _validateConfirmPassword(String? value) {
    return Validators.confirmPassword(
      value,
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValidatedTextField(
          controller: _passwordController,
          label: '密码',
          validator: Validators.passwordStrength,
          obscureText: true,
        ),
        ValidatedTextField(
          controller: _confirmPasswordController,
          label: '确认密码',
          validator: _validateConfirmPassword,
          obscureText: true,
        ),
      ],
    );
  }
}
```

---

## 最佳实践

### 1. 实时验证 vs 提交时验证

**实时验证**（推荐用于简单字段）：

```dart
ValidatedTextField(
  label: '邮箱',
  validator: Validators.email,
  autovalidateMode: AutovalidateMode.onUserInteraction,
)
```

**提交时验证**（推荐用于复杂表单）：

```dart
Form(
  key: _formKey,
  autovalidateMode: AutovalidateMode.disabled,
  child: Column(
    children: [
      TextFormField(
        validator: Validators.email,
      ),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // 提交
          }
        },
        child: Text('提交'),
      ),
    ],
  ),
)
```

### 2. 防抖优化

对于异步验证，使用适当的防抖延迟：

```dart
ValidatedTextField(
  asyncValidator: checkUsername,
  debounceDelay: 500, // 500ms 防抖
)
```

### 3. 错误消息国际化

```dart
String? validateEmail(String? value, BuildContext context) {
  if (value == null || value.isEmpty) {
    return AppLocalizations.of(context).emailRequired;
  }

  if (!Validators.isValidEmail(value)) {
    return AppLocalizations.of(context).emailInvalid;
  }

  return null;
}
```

### 4. 加载状态

```dart
class MyForm extends StatefulWidget {
  @override
  _MyFormState createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.submitForm(data);
      // 成功处理
    } catch (e) {
      // 错误处理
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 表单字段...
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitForm,
          child: _isSubmitting
              ? CircularProgressIndicator()
              : Text('提交'),
        ),
      ],
    );
  }
}
```

### 5. 错误提示样式

```dart
ValidatedTextField(
  label: '邮箱',
  validator: Validators.email,
  decoration: InputDecoration(
    labelText: '邮箱',
    hintText: '请输入邮箱地址',
    prefixIcon: Icon(Icons.email),
    border: OutlineInputBorder(),
    errorStyle: TextStyle(
      color: Colors.red,
      fontSize: 12,
    ),
    errorMaxLines: 2,
  ),
)
```

### 6. 表单重置

```dart
class MyForm extends StatefulWidget {
  @override
  _MyFormState createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _resetForm() {
    _formKey.currentState?.reset();
    _emailController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // 表单字段...
          Row(
            children: [
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('提交'),
              ),
              TextButton(
                onPressed: _resetForm,
                child: Text('重置'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### 7. 焦点管理

```dart
class MyForm extends StatefulWidget {
  @override
  _MyFormState createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValidatedTextField(
          label: '邮箱',
          validator: Validators.email,
          focusNode: _emailFocusNode,
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(_passwordFocusNode);
          },
        ),
        ValidatedTextField(
          label: '密码',
          validator: Validators.password,
          focusNode: _passwordFocusNode,
          obscureText: true,
          onSubmitted: (_) {
            _submitForm();
          },
        ),
      ],
    );
  }
}
```

---

## 测试

### 单元测试验证器

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dacong_client/core/validation/validators.dart';

void main() {
  group('Validators', () {
    test('email validator accepts valid emails', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('test.user@example.co.uk'), isNull);
    });

    test('email validator rejects invalid emails', () {
      expect(Validators.email('invalid'), isNotNull);
      expect(Validators.email('user@'), isNotNull);
      expect(Validators.email('@example.com'), isNotNull);
    });

    test('password validator checks length', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('longenough'), isNull);
    });

    test('username validator checks format', () {
      expect(Validators.username('valid_user'), isNull);
      expect(Validators.username('ab'), isNotNull); // 太短
      expect(Validators.username('invalid user'), isNotNull); // 包含空格
    });
  });
}
```

---

## 相关文档

- [输入验证指南](../security/INPUT_VALIDATION.md)
- [API 验证规则](../api/VALIDATION_RULES.md)
- [Flutter 开发指南](./FLUTTER_GUIDE.md)

---

## 更新日志

- **2026-04-19**: 初始版本，包含完整的表单验证指南
