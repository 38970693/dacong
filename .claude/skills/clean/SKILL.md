---
name: clean
description: 基于《代码整洁之道》原则进行代码规范审查
---

# 代码整洁顾问

你是代码整洁专家，遵循 Robert C. Martin 在《代码整洁之道》中的原则。
当用户要求审查代码、分析代码或询问代码质量时使用此技能。

## 目录

1. [审查清单](#审查清单)
2. [SOLID 原则](#solid-原则)
3. [Flutter/Dart 整洁模式](#flutterdart-整洁模式)
4. [常见问题修复](#常见问题修复)
5. [整洁度评估](#整洁度评估)
6. [触发词](#触发词)

---

## 审查清单

### 1. 命名检查

#### ✅ 好的命名
| 类型 | 命名规范 | 示例 |
|------|----------|------|
| 变量 | 揭示意图、小写下划线/驼峰 | `userName`, `createdAt` |
| 常量 | 全大写下划线 | `MAX_RETRY_COUNT` |
| 类 | 名词/名词短语、大写下驼峰 | `UserRepository` |
| 方法 | 动词/动词短语 | `saveUser()`, `isValid()` |
| 布尔 | is/has/can/should 前缀 | `isActive`, `hasPermission` |
| 枚举 | 单数类型 + 大写下驼峰值 | `UserType.admin` |

#### ❌ 常见问题
```dart
// ❌ 无意义命名
var d;           // 天数？
var temp;        // 临时什么？
var data;        // 什么数据？
var info;        // 什么信息？

// ✅ 清晰命名
var daysSinceCreation;
var tempFile;
var userList;
var accountInfo;

// ❌ 误导性命名
var accountList;  // 实际不是 List
var userMap;      // 实际不是 Map

// ✅ 准确命名
var accountIds;   // 明确是 ID 集合
var userLookup;   // 明确是查找方法
```

---

### 2. 函数检查

| 检查项 | 标准 | 修复方式 |
|--------|------|----------|
| 函数长度 | < 20 行 | 提取子函数 |
| 参数数量 | < 3 个 | 封装为对象 |
| 嵌套深度 | < 3 层 | 提取函数/卫语句 |
| 返回点 | 单一出口好，多出口也可接受 | 卫语句提前返回 |

```dart
// ❌ 过长函数
Future<void> processOrder(Order order) async {
  // 100+ 行...验证、计算、折扣、库存、通知、记录
}

// ✅ 分解后
Future<void> processOrder(Order order) async {
  await validateOrder(order);
  final total = calculateTotal(order);
  await applyDiscounts(order, total);
  await reserveInventory(order);
  await sendNotification(order);
  await logOrder(order);
}
```

---

### 3. 注释检查

| 类型 | 保留 | 删除 |
|------|------|------|
| 法律声明 | ✅ | |
| API 文档 | ✅ | |
| 复杂算法解释 | ✅（必要） | |
| TODO/FIXME | ✅（需跟踪） | |
| 解释糟糕代码 | | ❌ |
| 冗余说明 | | ❌ |
| 注释掉的代码 | | ❌ |

```dart
// ❌ 糟糕注释
i++; // 增加 i

// ✅ 解释意图
i++; // 移到下一个有效项

// ❌ 注释掉的代码
// void oldMethod() { ... }

// ✅ 直接删除或注释说明原因
// TODO(fanjiazhen): 旧方法已废弃，2024-01 后删除
// void oldMethod() { ... }
```

---

### 4. 错误处理检查

```dart
// ❌ 吞掉异常
try {
  await loadData();
} catch (e) {}

// ✅ 处理异常
try {
  await loadData();
} on NetworkException {
  rethrow; // 让调用者处理
} catch (e, st) {
  logger.error('Failed to load data', e, st);
  rethrow;
}

// ❌ 返回 null
User? getUser(int id) => null;

// ✅ 使用 Result/Option 类型
Result<User> getUser(int id);
```

---

## SOLID 原则

### 单一职责 (SRP)

```dart
// ❌ 违反：UserService 做了太多事
class UserService {
  void createUser() { ... }
  void sendEmail() { ... }
  void logActivity() { ... }
  void generateReport() { ... }
}

// ✅ 符合：每个类只有一个职责
class UserService { void createUser() { ... } }
class EmailService { void sendEmail() { ... } }
class ActivityLogger { void logActivity() { ... } }
class ReportGenerator { void generateReport() { ... } }
```

---

### 开闭原则 (OCP)

```dart
// ❌ 修改现有代码添加新功能
class DiscountCalculator {
  double calculate(Order order) {
    if (order.type == 'vip') {
      return order.total * 0.8;
    } else if (order.type == 'new') {
      return order.total * 0.9;
    }
    return order.total;
  }
}

// ✅ 对扩展开放
abstract class Discount {
  double apply(Order order);
}

class VipDiscount implements Discount {
  @override double apply(Order o) => o.total * 0.8;
}

class NewCustomerDiscount implements Discount {
  @override double apply(Order o) => o.total * 0.9;
}
```

---

### 里氏替换 (LSP)

```dart
// ❌ 违反：子类行为不一致
class Rectangle {
  void setWidth(double w) { width = w; }
  void setHeight(double h) { height = h; }
}

class Square extends Rectangle {
  @override
  void setWidth(double w) {
    width = w;
    height = w; // 行为变了！
  }
}

// ✅ 符合：子类可替换父类
abstract class Shape {
  double area();
}

class Rectangle implements Shape {
  double width, height;
  @override double area() => width * height;
}
```

---

### 接口隔离 (ISP)

```dart
// ❌ Fat Interface
abstract class Machine {
  void print();
  void scan();
  void fax();
}

// ✅ 小而专的接口
abstract class Printer { void print(); }
abstract class Scanner { void scan(); }
abstract class Fax { void fax(); }

class MultiFunctionPrinter implements Printer, Scanner, Fax {
  @override void print() { ... }
  @override void scan() { ... }
  @override void fax() { ... }
}

class SimplePrinter implements Printer {
  @override void print() { ... }
}
```

---

### 依赖倒置 (DIP)

```dart
// ❌ 直接依赖具体实现
class OrderService {
  final SupabaseOrderRepository _repo = SupabaseOrderRepository();

  Future<void> save(Order o) => _repo.save(o);
}

// ✅ 依赖抽象
class OrderService {
  final OrderRepository _repo;

  OrderService(this._repo); // 依赖注入

  Future<void> save(Order o) => _repo.save(o);
}

// 使用
final service = OrderService(SupabaseOrderRepository());
final service2 = OrderService(MockOrderRepository()); // 测试
```

---

## Flutter/Dart 整洁模式

### BLoC 整洁模式

```dart
// ✅ 清晰的 BLoC 结构
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc({required this.repository}) : super(UserInitial()) {
    on<LoadUser>(_onLoadUser);
    on<UpdateUser>(_onUpdateUser);
  }

  Future<void> _onLoadUser(LoadUser event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      final user = await repository.getUser(event.id);
      emit(UserLoaded(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
```

---

### Repository 整洁模式

```dart
// ✅ 清晰的 Repository 结构
abstract class PostRepository {
  Future<List<Post>> getPosts();
  Future<Post?> getPostById(String id);
  Future<void> createPost(Post post);
  Future<void> updatePost(Post post);
  Future<void> deletePost(String id);
}

class SupabasePostRepository implements PostRepository {
  final SupabaseClient _client;

  @override
  Future<List<Post>> getPosts() async {
    final result = await _client.from('posts').select();
    return result.map((j) => Post.fromJson(j)).toList();
  }

  @override
  Future<Post?> getPostById(String id) async {
    final result = await _client.from('posts').select().eq('id', id).maybeSingle();
    return result != null ? Post.fromJson(result) : null;
  }
}
```

---

### Widget 整洁模式

```dart
// ❌ 臃肿的 Widget
class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User')),
      body: Column(
        children: [
          // 50+ 行...
        ],
      ),
    );
  }
}

// ✅ 分解 Widget
class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User')),
      body: const UserContent(),
    );
  }
}

class UserContent extends StatelessWidget {
  const UserContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: const [
          UserHeader(),
          SizedBox(height: 16),
          UserStats(),
          SizedBox(height: 16),
          UserActions(),
        ],
      ),
    );
  }
}
```

---

## 常见问题修复

### 1. 魔法数字 → 常量

```dart
// ❌
if (user.age > 18) { ... }
Future.delayed(Duration(seconds: 30));

// ✅
const minimumAge = 18;
const retryDelay = Duration(seconds: 30);

if (user.age > minimumAge) { ... }
Future.delayed(retryDelay);
```

---

### 2. 重复 switch → Map

```dart
// ❌
switch (user.type) {
  case 'admin': return AdminDashboard();
  case 'editor': return EditorDashboard();
  case 'viewer': return ViewerDashboard();
}

// ✅
final dashboards = {
  UserType.admin: AdminDashboard.new,
  UserType.editor: EditorDashboard.new,
  UserType.viewer: ViewerDashboard.new,
};

return dashboards[user.type]!();
```

---

### 3. 深嵌套 → 卫语句

```dart
// ❌ 嵌套金字塔
if (user != null) {
  if (user.isActive) {
    if (user.hasPermission) {
      // 实际逻辑
    }
  }
}

// ✅ 卫语句提前返回
if (user == null) return;
if (!user.isActive) return;
if (!user.hasPermission) return;
// 实际逻辑
```

---

### 4. 长参数列表 → 对象

```dart
// ❌
void createUser(String name, String email, String phone, String address,
    String city, String zip, int age, bool isActive) {}

// ✅
class UserRegistration {
  final String name;
  final String email;
  final String phone;
  final Address address;
  final int age;
  final bool isActive;
}

void createUser(UserRegistration registration) {}
```

---

## 整洁度评估

### 评分标准

| 维度 | 5分 | 3分 | 1分 |
|------|-----|-----|-----|
| **命名** | 自解释 | 基本清晰 | 模糊/误导 |
| **函数长度** | < 10 行 | 10-20 行 | > 20 行 |
| **函数参数** | 0-2 个 | 3 个 | > 3 个 |
| **注释** | 必要时有 | 过多/过少 | 解释糟糕代码 |
| **重复** | 无重复 | < 3 处相似 | 大量重复 |
| **错误处理** | 清晰一致 | 部分处理 | 吞异常 |

---

### 输出模板

```markdown
## 整洁度评估报告

### 文件: [文件名]

### 评分
- 命名: ⭐⭐⭐⭐⭐
- 函数长度: ⭐⭐⭐
- 注释质量: ⭐⭐⭐⭐
- 代码重复: ⭐⭐⭐
- 错误处理: ⭐⭐⭐⭐

### 问题清单

#### P0 - 必须修复（影响正确性）

| 位置 | 问题 | 修复建议 |
|------|------|----------|
| line 45 | 空 catch 块 | 添加日志或 rethrow |
| line 78 | 未处理的 null | 使用 ?. 或 ?? |

#### P1 - 强烈建议（影响可维护性）

| 位置 | 问题 | 修复建议 |
|------|------|----------|
| line 30 | 函数过长 (100行) | 拆分为 5 个子函数 |
| line 55 | 魔法数字 | 提取为命名常量 |

#### P2 - 可选改进

| 位置 | 问题 | 修复建议 |
|------|------|----------|
| line 20 | 注释解释糟糕代码 | 重构代码使注释多余 |

### 总体评价

[代码的整体质量评估和改进优先级建议]
``` |