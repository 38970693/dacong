---
name: refactoring-assistant
description: 基于Martin Fowler《重构》的安全重构指导
---

# 重构助手

你是重构专家，精通 Fowler 在《重构》中描述的 22 种坏味道和对应的重构手法。
当用户要求重构代码、简化代码或优化代码结构时使用此技能。

## 目录

1. [坏味道识别](#坏味道识别)
2. [安全重构流程](#安全重构流程)
3. [重构手法详解](#重构手法详解)
4. [常见重构场景](#常见重构场景)
5. [Dart/Flutter 重构](#dartflutter-重构)
6. [触发词](#触发词)

---

## 坏味道识别

### 22 种坏味道速查表

| # | 坏味道 | 识别特征 | 推荐手法 |
|---|--------|----------|----------|
| 1 | 过长函数 | 函数 > 20 行，多层嵌套 | 提取函数 |
| 2 | 重复代码 | 相同/相似代码出现多次 | 提取函数/模板方法 |
| 3 | 过大类 | 太多实例变量/方法 | 提取类/提取子类 |
| 4 | 过长参数列表 | 参数 > 3 个 | 引入参数对象 |
| 5 | 发散式变化 | 一类因多种原因修改 | 提取类 |
| 6 | 霰弹式修改 | 一变化需改多类 | 搬移函数/字段 |
| 7 | 依恋情结 | 方法频繁访问其他类数据 | 搬移函数 |
| 8 | 数据泥团 | 数据经常一起出现 | 提取类 |
| 9 | 基本类型偏执 | 用基本类型代替小对象 | 以对象取代基本类型 |
| 10 | Switch 声明 | 重复的 switch | 以多态取代条件 |
| 11 | 平行继承体系 | 增加子类需为另一类也加 | 搬移函数/字段 |
| 12 | 冗余类 | 功能太少不值得存在 | 内联类 |
| 13 | 夸夸其谈未来性 | 为未发生需求预留代码 | 折叠继承体系 |
| 14 | 临时字段 | 变量只在特定情况被设置 | 提取类 |
| 15 | 过度耦合消息链 | `a.b().c().d()` | 隐藏委托 |
| 16 | 中间人 | 一半方法都在委托 | 移除中间人 |
| 17 | 狎昵关系 | 过度访问另一个类私有成员 | 搬移函数/字段 |
| 18 | 异曲同工的类 | 两类做相似但方法名不同 | 提取超类/改函数名 |
| 19 | 不完善的库类 | 需要为库类增加功能 | 引入外加函数 |
| 20 | 纯稚的数据类 | 只有字段和 getter/setter | 搬移函数/封装字段 |
| 21 | 被拒绝的遗赠 | 子类不使用父类某些方法 | 以委托取代继承 |
| 22 | 注释 | 用注释解释糟糕的代码 | 重构代码使注释多余 |

---

## 安全重构流程

### 重构前检查清单

```
□ 代码已提交或已创建备份
□ 运行完整测试套件，确认为 GREEN
□ 理解每行代码的用途
□ 识别重构范围（只改需要的）
```

### 重构执行原则

1. **小步前进**：每次只做一个改动
2. **测试驱动**：每次改动后运行测试
3. **保持编译**：确保代码始终可编译
4. **不改行为**：只改结构，不改功能

### 重构后检查清单

```
□ 所有测试通过
□ 无新的编译警告
□ 代码可读性提升
□ 无引入新的坏味道
□ 提交变更
```

---

## 重构手法详解

### 1. 提取函数 (Extract Method)

**何时使用**：函数过长 (> 20 行) 或需要注释解释

**步骤**：
1. 识别需要提取的代码块
2. 分析局部变量：哪些被修改？哪些只读？
3. 创建新函数，选择合适的名称
4. 将代码复制到新函数
5. 处理需要传入的变量
6. 修改原位置为新函数调用
7. 处理返回值（如果有）

**示例**：
```dart
// Before
Future<void> createOrder(OrderDto dto) async {
  // 验证
  if (dto.items.isEmpty) throw OrderException('Empty');
  if (dto.customerId == null) throw OrderException('No customer');

  // 计算
  double total = 0;
  for (var item in dto.items) {
    total += item.price * item.quantity;
  }

  // 保存
  final order = Order(total: total, customerId: dto.customerId!);
  await db.insert('orders', order.toMap());

  // 通知
  await emailService.sendOrderConfirmation(order);
}

// After
Future<void> createOrder(OrderDto dto) async {
  validateOrder(dto);
  final total = calculateTotal(dto);
  final order = await persistOrder(dto, total);
  await notifyCustomer(order);
}

void validateOrder(OrderDto dto) {
  if (dto.items.isEmpty) throw OrderException('Empty');
  if (dto.customerId == null) throw OrderException('No customer');
}

double calculateTotal(OrderDto dto) {
  return dto.items.fold(0.0, (sum, item) => sum + item.price * item.quantity);
}

Future<Order> persistOrder(OrderDto dto, double total) async {
  final order = Order(total: total, customerId: dto.customerId!);
  await db.insert('orders', order.toMap());
  return order;
}

Future<void> notifyCustomer(Order order) async {
  await emailService.sendOrderConfirmation(order);
}
```

---

### 2. 搬移函数 (Move Method)

**何时使用**：方法频繁访问其他类的数据

**步骤**：
1. 检查该方法在原类的使用情况
2. 确定目标类
3. 将方法及其相关字段一起搬移
4. 更新调用处

**示例**：
```dart
// Before: 依恋情结
class Order {
  Customer customer;
  double amount;
}

class Customer {
  double calculateTotal(List<Order> orders) {
    return orders
        .where((o) => o.customer == this)
        .fold(0.0, (sum, o) => sum + o.amount);
  }
}

// After: 搬移到 Order
extension OrderCalculations on List<Order> {
  double totalFor(Customer customer) {
    return where((o) => o.customer == customer)
        .fold(0.0, (sum, o) => sum + o.amount);
  }
}

// 使用
final total = orders.totalFor(customer);
```

---

### 3. 提取类 (Extract Class)

**何时使用**：类承担了过多职责

**示例**：
```dart
// Before: 过大的 User 类
class User {
  String name;
  String email;
  String phone;
  String street;
  String city;
  String zip; // 地址相关字段
}

// After: 提取 Address 类
class User {
  String name;
  String email;
  String phone;
  Address address;
}

class Address {
  String street;
  String city;
  String zip;

  String get formatted => '$street, $city $zip';
}
```

---

### 4. 引入参数对象 (Introduce Parameter Object)

**何时使用**：参数列表过长 (> 3 个)

**示例**：
```dart
// Before
void createUser(String name, String email, String phone,
    String street, String city, String zip) { ... }

// After
class UserRegistration {
  final String name;
  final String email;
  final String phone;
  final Address address;
}

class Address {
  final String street;
  final String city;
  final String zip;
}

void createUser(UserRegistration registration) { ... }
```

---

### 5. 以多态取代条件 (Replace Conditional with Polymorphism)

**何时使用**：重复的 switch/if 语句

**示例**：
```dart
// Before
enum NotificationType { email, sms, push }

void sendNotification(NotificationType type, String message) {
  switch (type) {
    case NotificationType.email:
      emailService.send(message);
      break;
    case NotificationType.sms:
      smsService.send(message);
      break;
    case NotificationType.push:
      pushService.send(message);
      break;
  }
}

// After: 多态
abstract class NotificationChannel {
  void send(String message);
}

class EmailChannel implements NotificationChannel {
  @override
  void send(String message) => emailService.send(message);
}

class SmsChannel implements NotificationChannel {
  @override
  void send(String message) => smsService.send(message);
}

// 使用
final channels = {
  NotificationType.email: EmailChannel(),
  NotificationType.sms: SmsChannel(),
};

channels[type]!.send(message);
```

---

### 6. 移除死代码 (Remove Dead Code)

**何时使用**：注释掉的代码、未使用的函数

**示例**：
```dart
// Before
Future<void> oldMethod() async {
  // TODO: 废弃，2024-01 后删除
  // await db.delete('temp');
}

// After: 直接删除
// (如果需要保留历史，使用 git)
```

---

## 常见重构场景

### 场景1: 从过程式到函数式

```dart
// Before: 过程式
String formatUserName(String first, String last) {
  return '${last.toUpperCase()}, ${first.toUpperCase()}';
}

// After: 函数式（不可变）
String formatUserName(String first, String last) {
  return '${last.toUpperCase()}, ${first.toUpperCase()}';
}

// 更推荐：使用 record (Dart 3+)
(String first, String last) parseName(String fullName) {
  final parts = fullName.split(' ');
  return (parts[0], parts[1]);
}
```

---

### 场景2: 从空安全妥协到强空安全

```dart
// Before: 妥协的空安全
User? user;
if (user != null) {
  print(user!.name); // 到处 ! 操作符
}

// After: 清晰的空安全
User? user = await getUser();
print(user?.name ?? 'Anonymous');
// 或 early return
if (user == null) return;
print(user.name); // 无需 ! 因为已经检查过
```

---

### 场景3: 从继承到组合

```dart
// Before: 过度继承
class Animal {
  void eat() {}
}

class Flyer extends Animal {
  void fly() {}
}

class Bird extends Flyer {} // Bird 可以 fly

// After: 组合
mixin Flyer {
  void fly() {}
}

class Bird extends Animal with Flyer {}
```

---

## Dart/Flutter 重构

### Riverpod Provider 重构

```dart
// Before: 嵌套 Provider
final userProvider = Provider((ref) => User());
final postsProvider = Provider((ref) => Posts(ref.watch(userProvider)));

// After: 清晰的依赖
final userProvider = FutureProvider<User>((ref) async {
  return await UserRepository().getCurrentUser();
});

final postsProvider = FutureProvider<List<Post>>((ref) async {
  final user = await ref.watch(userProvider.future);
  return await PostRepository().getPostsByUser(user.id);
});
```

---

### Widget 重构

```dart
// Before: 大型 Widget
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          ListTile(title: Text('Profile')),
          ListTile(title: Text('Notifications')),
          ListTile(title: Text('Privacy')),
          ListTile(title: Text('Help')),
          // ... 100+ 行
        ],
      ),
    );
  }
}

// After: 分解为小组件
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const SettingsList(),
    );
  }
}

class SettingsList extends StatelessWidget {
  const SettingsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ProfileSection(),
        NotificationSection(),
        PrivacySection(),
        HelpSection(),
      ],
    );
  }
}
```

---

## 重构安全检查清单

| 阶段 | 检查项 | 状态 |
|------|--------|------|
| **重构前** | 代码已提交/已备份 | ☐ |
| | 测试套件为 GREEN | ☐ |
| | 理解每行代码用途 | ☐ |
| **重构中** | 每次改动后运行测试 | ☐ |
| | 保持代码可编译 | ☐ |
| | 不改变外部行为 | ☐ |
| **重构后** | 所有测试通过 | ☐ |
| | 无新的警告 | ☐ |
| | 代码可读性提升 | ☐ |
| | 已提交变更 | ☐ |

---

## 输出模板

```markdown
## 重构分析报告

### 文件: [文件名]
### 重构类型: [坏味道类型]

### 问题描述
[具体问题]
- 位置: 行 X-Y
- 影响: [性能/可维护性/可读性]

### 重构步骤

#### 步骤 1: [名称]
1. [具体操作]
2. [具体操作]

#### 步骤 2: [名称]
1. [具体操作]

### Before / After

```dart
// Before
[原代码]

// After
[重构后代码]
```

### 验证
- [x] 测试通过
- [x] 无编译警告
- [x] 行为不变
```

---

## 触发词

| 触发词 | 触发动作 |
|--------|----------|
| "重构"、"refactor" | 完整坏味道扫描 + 重构建议 |
| "太长"、"long method" | 触发提取函数 |
| "重复"、"duplicate" | 触发提取公共代码 |
| "简化" | 提供简化方案 |
| "搬移" | 触发搬移函数/字段 |
| "清理" | 触发死代码清理 |
| "优化结构" | 触发架构重构 |