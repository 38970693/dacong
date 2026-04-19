#!/usr/bin/env python3
"""
修复 freezed 生成的格式问题
将单行的属性声明和构造函数拆分为多行
"""

import re
import glob

def fix_mixin_properties(content):
    """修复 mixin 中的属性声明"""
    # 匹配 mixin _$ClassName { ... }
    pattern = r'(mixin _\$\w+ \{)(.*?)(\n/// Create a copy)'

    def replace_properties(match):
        prefix = match.group(1)
        props = match.group(2)
        suffix = match.group(3)

        # 分割属性
        props = props.strip()
        # 替换 "; Type get" 为 ";\n  Type get"
        props = re.sub(r';\s*(\w+(?:<[^>]+>)?)\s+get\s+', r';\n  \1 get ', props)
        # 清理开头多余的分号
        props = re.sub(r'^\s*;\s*', '\n  ', props)

        return prefix + props + suffix

    return re.sub(pattern, replace_properties, content, flags=re.DOTALL)

def fix_call_parameters(content):
    """修复 call 方法中的参数"""
    # 匹配 $Res call({ ... })
    pattern = r'(\$Res call\(\{)(.*?)(\}\);)'

    def replace_params(match):
        prefix = match.group(1)
        params = match.group(2)
        suffix = match.group(3)

        # 分割参数
        params = params.strip()
        # 替换 ", Type param" 为 ",\n  Type param"
        params = re.sub(r',\s*(\w+(?:<[^>]+>)?)\s+', r',\n  \1 ', params)
        # 清理开头
        params = re.sub(r'^\s*,?\s*', '\n  ', params)
        params = params.rstrip(',\n ')

        return prefix + params + '\n' + suffix

    return re.sub(pattern, replace_params, content, flags=re.DOTALL)

def fix_constructor(content):
    """修复构造函数"""
    # 匹配构造函数: const _ClassName({...}): ...;
    pattern = r'(const _\w+\(\{)(required[^}]+)(\}\)[^;]*;)'

    def replace_constructor(match):
        prefix = match.group(1)
        params = match.group(2)
        suffix = match.group(3)

        # 分割参数
        params = re.sub(r',\s*required\s+', r',\n    required ', params)
        params = '\n    required ' + params.lstrip('required ')

        return prefix + params + '\n  ' + suffix

    return re.sub(pattern, replace_constructor, content, flags=re.DOTALL)

def fix_copyWith_call(content):
    """修复 copyWith 中的 call 方法"""
    # 匹配 @pragma('vm:prefer-inline') @override $Res call({...}) {
    pattern = r'(@pragma\(\'vm:prefer-inline\'\) @override \$Res call\(\{)(Object\?[^}]+)(\}\) \{)'

    def replace_call(match):
        prefix = match.group(1)
        params = match.group(2)
        suffix = match.group(3)

        # 分割参数
        params = re.sub(r',\s*Object\?\s+', r',\n    Object? ', params)
        params = '\n    Object? ' + params.lstrip('Object? ')
        params = params.rstrip(',\n ')

        return prefix + params + ',\n  ' + suffix

    return re.sub(pattern, replace_call, content, flags=re.DOTALL)

def fix_copyWith_body(content):
    """修复 copyWith 方法体"""
    # 匹配 return _then(_self.copyWith( ... ));
    pattern = r'(return _then\(_self\.copyWith\()([\w\s:?=\(\)\[\]<>,./\-]+)(\s*\)\);)'

    def replace_body(match):
        prefix = match.group(1)
        body = match.group(2)
        suffix = match.group(3)

        # 分割参数
        body = re.sub(r',(\w+:)', r',\n      \1', body)
        body = '\n      ' + body.lstrip()
        body = body.rstrip(',\n ')

        return prefix + body + ',\n    ' + suffix

    return re.sub(pattern, replace_body, content, flags=re.DOTALL)

def process_file(filepath):
    """处理单个文件"""
    print(f"Processing {filepath}...")

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 应用所有修复
    content = fix_mixin_properties(content)
    content = fix_call_parameters(content)
    content = fix_constructor(content)
    content = fix_copyWith_call(content)
    content = fix_copyWith_body(content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

def main():
    """主函数"""
    files = glob.glob('lib/core/domain/entities/*.freezed.dart')
    files.extend(glob.glob('lib/data/models/*.freezed.dart'))

    for filepath in files:
        process_file(filepath)

    print("Done!")

if __name__ == '__main__':
    main()
