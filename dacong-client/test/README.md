# 搜索功能测试

## 运行测试

### 1. 生成 Mock 文件

```bash
cd dacong-client
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. 运行所有测试

```bash
flutter test
```

### 3. 运行特定测试

```bash
# 测试 LocalDataSource
flutter test test/data/datasources/local_data_source_test.dart

# 测试 SearchBloc
flutter test test/presentation/blocs/search/search_bloc_test.dart
```

### 4. 查看测试覆盖率

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 测试文件说明

### LocalDataSource 测试
- `test/data/datasources/local_data_source_test.dart`
- 测试搜索历史的保存、删除、清空
- 测试收藏功能
- 测试热门搜索

### SearchBloc 测试
- `test/presentation/blocs/search/search_bloc_test.dart`
- 测试搜索查询变化（带防抖）
- 测试筛选功能
- 测试排序功能
- 测试搜索历史管理

## 测试覆盖率目标

- 单元测试覆盖率：80%+
- BLoC 测试覆盖率：90%+
- 关键业务逻辑覆盖率：100%
