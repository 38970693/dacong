/// Validated Text Field Widget
/// 带验证的文本输入框组件
library;

import 'package:flutter/material.dart';
import 'dart:async';

/// 带验证的文本输入框
class ValidatedTextField extends StatefulWidget {
  /// 控制器
  final TextEditingController? controller;

  /// 标签
  final String? label;

  /// 提示文本
  final String? hint;

  /// 验证器
  final String? Function(String?)? validator;

  /// 异步验证器（如检查用户名唯一性）
  final Future<String?> Function(String?)? asyncValidator;

  /// 是否必填
  final bool required;

  /// 是否密码输入
  final bool obscureText;

  /// 键盘类型
  final TextInputType? keyboardType;

  /// 最大行数
  final int? maxLines;

  /// 最大长度
  final int? maxLength;

  /// 前缀图标
  final IconData? prefixIcon;

  /// 后缀图标
  final IconData? suffixIcon;

  /// 是否启用
  final bool enabled;

  /// 自动验证模式
  final AutovalidateMode? autovalidateMode;

  /// 输入变化回调
  final void Function(String)? onChanged;

  /// 提交回调
  final void Function(String)? onSubmitted;

  /// 防抖延迟（毫秒）
  final int debounceDelay;

  const ValidatedTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.validator,
    this.asyncValidator,
    this.required = false,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.autovalidateMode,
    this.onChanged,
    this.onSubmitted,
    this.debounceDelay = 500,
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  late TextEditingController _controller;
  String? _errorText;
  bool _isValidating = false;
  Timer? _debounceTimer;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _obscureText = widget.obscureText;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// 验证输入
  Future<void> _validate(String value) async {
    // 同步验证
    if (widget.validator != null) {
      final error = widget.validator!(value);
      if (error != null) {
        setState(() {
          _errorText = error;
          _isValidating = false;
        });
        return;
      }
    }

    // 异步验证
    if (widget.asyncValidator != null && value.isNotEmpty) {
      setState(() {
        _isValidating = true;
        _errorText = null;
      });

      try {
        final error = await widget.asyncValidator!(value);
        if (mounted) {
          setState(() {
            _errorText = error;
            _isValidating = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorText = '验证失败，请重试';
            _isValidating = false;
          });
        }
      }
    } else {
      setState(() {
        _errorText = null;
        _isValidating = false;
      });
    }
  }

  /// 处理输入变化（带防抖）
  void _handleChanged(String value) {
    widget.onChanged?.call(value);

    // 取消之前的定时器
    _debounceTimer?.cancel();

    // 设置新的定时器
    _debounceTimer = Timer(
      Duration(milliseconds: widget.debounceDelay),
      () => _validate(value),
    );
  }

  /// 切换密码可见性
  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      autovalidateMode: widget.autovalidateMode,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: _errorText,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon)
            : null,
        suffixIcon: _buildSuffixIcon(),
        border: const OutlineInputBorder(),
        counterText: widget.maxLength != null ? null : '',
      ),
      validator: widget.validator,
      onChanged: _handleChanged,
      onFieldSubmitted: widget.onSubmitted,
    );
  }

  /// 构建后缀图标
  Widget? _buildSuffixIcon() {
    if (_isValidating) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
        ),
        onPressed: _toggleObscureText,
      );
    }

    if (widget.suffixIcon != null) {
      return Icon(widget.suffixIcon);
    }

    return null;
  }
}
