#!/bin/bash

# 修复 freezed 生成的格式问题
# 将单行的属性声明拆分为多行

for file in lib/core/domain/entities/*.freezed.dart; do
  echo "Processing $file..."

  # 使用 sed 将 "; String get" 替换为 ";\n  String get"
  # 使用 "; List<" 替换为 ";\n  List<"
  # 使用 "; int get" 替换为 ";\n  int get"
  # 使用 "; bool get" 替换为 ";\n  bool get"
  # 使用 "; double get" 替换为 ";\n  double get"
  # 使用 "; DateTime get" 替换为 ";\n  DateTime get"

  sed -i 's/; String get/;\n  String get/g' "$file"
  sed -i 's/; List</;\n  List</g' "$file"
  sed -i 's/; int get/;\n  int get/g' "$file"
  sed -i 's/; bool get/;\n  bool get/g' "$file"
  sed -i 's/; double/;\n  double/g' "$file"
  sed -i 's/; DateTime get/;\n  DateTime get/g' "$file"
  sed -i 's/; PriceInfo get/;\n  PriceInfo get/g' "$file"
  sed -i 's/; AccessInfo get/;\n  AccessInfo get/g' "$file"
  sed -i 's/; WeeklySection/;\n  WeeklySection/g' "$file"

  # 修复 call 方法中的参数
  sed -i 's/, String id,/,\n  String id,/g' "$file"
  sed -i 's/, String name,/,\n  String name,/g' "$file"
  sed -i 's/, String vendor,/,\n  String vendor,/g' "$file"
  sed -i 's/, String description,/,\n  String description,/g' "$file"
  sed -i 's/, String title,/,\n  String title,/g' "$file"
  sed -i 's/, String summary,/,\n  String summary,/g' "$file"
  sed -i 's/, String icon,/,\n  String icon,/g' "$file"
  sed -i 's/, List</,\n  List</g' "$file"
  sed -i 's/, int /,\n  int /g' "$file"
  sed -i 's/, bool /,\n  bool /g' "$file"
  sed -i 's/, double/,\n  double/g' "$file"
  sed -i 's/, DateTime /,\n  DateTime /g' "$file"
  sed -i 's/, PriceInfo /,\n  PriceInfo /g' "$file"
  sed -i 's/, AccessInfo /,\n  AccessInfo /g' "$file"

done

echo "Done!"
