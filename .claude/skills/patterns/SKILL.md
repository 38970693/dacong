
---
name: patterns
description: 基于GoF《设计模式》的设计模式推荐与实现指导
---

# 设计模式顾问

你是设计模式专家，精通 GoF 的 23 种设计模式及其变体。
当用户询问设计模式或需要代码架构建议时使用此技能。

## 目录

1. [创建型模式](#创建型模式-5种)
2. [结构型模式](#结构型模式-7种)
3. [行为型模式](#行为型模式-11种)
4. [模式推荐流程](#模式推荐流程)
5. [代码模板库](#代码模板库)
6. [快速查询](#快速查询)

---

## 创建型模式 (5种)

### 单例模式 (Singleton)

**意图**：确保一个类只有一个实例，并提供全局访问点。

**适用场景**：
- 全局配置管理器
- 日志记录器
- 数据库连接池

**Dart 实现**：
```dart
class ConfigManager {
  // 私有静态实例
  static ConfigManager? _instance;

  // 私有构造函数
  ConfigManager._internal();

  // 全局访问点
  static ConfigManager get instance {
    _instance ??= ConfigManager._internal();
    return _instance!;
  }
}
```

**Flutter GetIt 实现**（推荐）：
```dart
// 更推荐的依赖注入方式
final getIt = GetIt.instance;
getIt.registerSingleton<ConfigManager>(ConfigManager());
```

---

### 工厂方法 (Factory Method)

**意图**：定义创建对象的接口，让子类决定实例化哪个类。

**适用场景**：
- 对象创建逻辑可能变化
- 需要延迟实例化

**Dart 实现**：
```dart
abstract class Dialog {
  void show();
}

class AlertDialog extends Dialog {
  @override
  void show() => print('Alert dialog shown');
}

class ConfirmDialog extends Dialog {
  @override
  void show() => print('Confirm dialog shown');
}

// 工厂
class DialogFactory {
  static Dialog create(String type) {
    return switch (type) {
      'alert' => AlertDialog(),
      'confirm' => ConfirmDialog(),
      _ => throw ArgumentError('Unknown dialog type'),
    };
  }
}
```

---

### 抽象工厂 (Abstract Factory)

**意图**：创建一系列相关对象，无需指定具体类。

**适用场景**：
- 产品族（跨平台 UI：iOS/Android 组件）
- 主题系统（深色/浅色模式）

**Dart 实现**：
```dart
// 抽象工厂
abstract class DeviceFactory {
  Widget createButton();
  Widget createTextField();
}

// iOS 风格工厂
class IosFactory implements DeviceFactory {
  @override
  Widget createButton() => CupertinoButton(child: Text('iOS Button'));
  @override
  Widget createTextField() => CupertinoTextField();
}

// Android 风格工厂
class AndroidFactory implements DeviceFactory {
  @override
  Widget createButton() => ElevatedButton(child: Text('Android Button'));
  @override
  Widget createTextField() => TextField();
}

// 使用
DeviceFactory factory = Platform.isIOS ? IosFactory() : AndroidFactory();
```

---

### 建造者模式 (Builder)

**意图**：分步构建复杂对象，构造与表示分离。

**适用场景**：
- 对象有多个可选参数
- 构建过程需要链式调用
- 不可变对象

**Dart 实现**：
```dart
class User {
  final String name;
  final String email;
  final int age;
  final List<String> roles;

  User._({
    required this.name,
    required this.email,
    required this.age,
    required this.roles,
  });
}

class UserBuilder {
  String? _name;
  String? _email;
  int? _age;
  List<String> _roles = [];

  UserBuilder name(String name) { _name = name; return this; }
  UserBuilder email(String email) { _email = email; return this; }
  UserBuilder age(int age) { _age = age; return this; }
  UserBuilder addRole(String role) { _roles.add(role); return this; }

  User build() {
    if (_name == null || _email == null) {
      throw StateError('name and email are required');
    }
    return User._(
      name: _name!,
      email: _email!,
      age: _age ?? 0,
      roles: List.unmodifiable(_roles),
    );
  }
}

// 使用
final user = UserBuilder()
    .name('Alice')
    .email('alice@example.com')
    .age(30)
    .addRole('admin')
    .build();
```

---

### 原型模式 (Prototype)

**意图**：通过复制现有对象创建新对象。

**适用场景**：
- 对象创建成本高（数据库查询、网络请求）
- 对象状态相似只需修改少量属性

**Dart 实现**：
```dart
abstract class Prototype<T> {
  T clone();
}

class UserProfile implements Prototype<UserProfile> {
  String name;
  String avatar;
  Map<String, dynamic> settings;

  UserProfile({required this.name, required this.avatar, required this.settings});

  @override
  UserProfile clone() => UserProfile(
    name: name,
    avatar: avatar,
    settings: Map.from(settings),
  );
}

// 使用
final original = UserProfile(name: 'Alice', avatar: '...', settings: {'theme': 'dark'});
final copy = original.clone();
copy.name = 'Bob'; // 不影响 original
```

---

## 结构型模式 (7种)

### 适配器模式 (Adapter)

**意图**：将不兼容的接口转换为可兼容的接口。

**适用场景**：
- 集成第三方库
- 统一不同数据源的接口
- 遗留代码兼容

**Dart 实现**：
```dart
// 第三方库的旧接口
class LegacyPayment {
  void processPayment(double amount, String currency) {
    print('Legacy: Paid $amount $currency');
  }
}

// 新系统接口
abstract class PaymentProcessor {
  Future<void> pay(double amount);
}

// 适配器
class PaymentAdapter implements PaymentProcessor {
  final LegacyPayment _legacy;

  PaymentAdapter(this._legacy);

  @override
  Future<void> pay(double amount) async {
    // 转换接口
    _legacy.processPayment(amount, 'CNY');
  }
}
```

---

### 装饰器模式 (Decorator)

**意图**：动态增加职责，比继承更灵活。

**适用场景**：
- 需要透明地扩展功能
- 功能可以动态组合
- 不适合用子类继承

**Dart 实现**：
```dart
abstract class Coffee {
  double get cost;
  String get description;
}

class SimpleCoffee implements Coffee {
  @override double get cost => 10.0;
  @override String get description => 'Coffee';
}

// 装饰器基类
mixin CoffeeDecorator implements Coffee {
  @override double get cost => 10.0 + (this as Coffee).cost;
}

// 具体装饰器
class MilkDecorator extends CoffeeDecorator {
  final Coffee _coffee;
  MilkDecorator(this._coffee);

  @override
  double get cost => _coffee.cost + 3.0;

  @override
  String get description => '${_coffee.description} + Milk';
}

class SugarDecorator extends CoffeeDecorator {
  final Coffee _coffee;
  SugarDecorator(this._coffee);

  @override
  double get cost => _coffee.cost + 2.0;

  @override
  String get description => '${_coffee.description} + Sugar';
}

// 使用
var coffee = SugarDecorator(MilkDecorator(SimpleCoffee()));
print('${coffee.description}: \$${coffee.cost}'); // Coffee + Milk + Sugar: $15
```

---

### 代理模式 (Proxy)

**意图**：控制对原对象的访问。

**适用场景**：
- 延迟加载（大图片、远程数据）
- 访问控制
- 日志记录
- 缓存

**Dart 实现**：
```dart
abstract class Image {
  void display();
}

class RealImage implements Image {
  final String fileName;

  RealImage(this.fileName) {
    _loadFromDisk();
  }

  void _loadFromDisk() {
    print('Loading $fileName from disk...');
  }

  @override
  void display() {
    print('Displaying $fileName');
  }
}

// 虚拟代理（延迟加载）
class ImageProxy implements Image {
  final String fileName;
  RealImage? _realImage;

  ImageProxy(this.fileName);

  @override
  void display() {
    _realImage ??= RealImage(fileName);
    _realImage!.display();
  }
}

// 使用 - 图片只在调用 display() 时才加载
final image = ImageProxy('photo.jpg');
// ... 做其他事情
image.display(); // 此时才加载
```

---

### 外观模式 (Facade)

**意图**：简化复杂子系统，提供统一接口。

**适用场景**：
- 封装复杂的多步骤流程
- 提供简单的统一入口
- 解耦客户端与子系统

**Dart 实现**：
```dart
// 子系统类
class VideoFile { final String name; VideoFile(this.name); }
class CodecFactory { static String extract(String f) => 'MPEG4'; }
class BitrateReader { static String read(String c, String f) => 'bitrate data'; }
class AudioMixer { static String fix(String b) => 'fixed audio'; }

// 外观类
class VideoConverter {
  String convert(String fileName, String format) {
    final file = VideoFile(fileName);
    final codec = CodecFactory.extract(fileName);
    final bitrate = BitrateReader.read(codec, fileName);
    final audio = AudioMixer.fix(bitrate);
    return 'converted to $format';
  }
}

// 使用 - 客户端只需调用一个方法
final converter = VideoConverter();
converter.convert('video.ogg', 'mp4');
```

---

### 组合模式 (Composite)

**意图**：将对象组合成树形结构，统一对待单个对象和组合对象。

**适用场景**：
- 文件系统
- 组织架构
- UI 组件树

**Dart 实现**：
```dart
abstract class FileSystemComponent {
  String get name;
  int get size;
  void print([String prefix = '']);
}

class File implements FileSystemComponent {
  @override final String name;
  @override final int size;

  File(this.name, this.size);

  @override
  void print([String prefix = '']) {
    print('$prefix- $name ($size KB)');
  }
}

class Directory implements FileSystemComponent {
  @override final String name;
  final List<FileSystemComponent> children = [];

  Directory(this.name);

  @override
  int get size => children.fold(0, (sum, c) => sum + c.size);

  @override
  void print([String prefix = '']) {
    print('$prefix+ $name/ (${size} KB)');
    for (final child in children) {
      child.print('$prefix  ');
    }
  }
}

// 使用
final root = Directory('root');
final docs = Directory('docs');
docs.children.addAll([File('resume.pdf', 100), File('notes.txt', 20)]);
root.children.addAll([docs, File('readme.md', 5)]);
root.print();
```

---

### 桥接模式 (Bridge)

**意图**：分离抽象与实现，使两者可以独立变化。

**适用场景**：
- 跨平台应用
- 多维度变化（形状 + 颜色）
- 避免类爆炸

**Dart 实现**：
```dart
// 实现部分
abstract class Device {
  bool isEnabled();
  void enable();
  void disable();
  int get volume;
  void setVolume(int percent);
}

// 抽象部分
class RemoteControl {
  final Device device;
  RemoteControl(this.device);

  void togglePower() {
    if (device.isEnabled()) {
      device.disable();
    } else {
      device.enable();
    }
  }

  void volumeUp() => device.setVolume(device.volume + 10);
}

// 具体实现
class TV implements Device {
  bool _on = false;
  int _vol = 30;

  @override bool isEnabled() => _on;
  @override void enable() => _on = true;
  @override void disable() => _on = false;
  @override int get volume => _vol;
  @override void setVolume(int v) => _vol = v;
}

// 使用
final tv = TV();
final remote = RemoteControl(tv);
remote.togglePower();
remote.volumeUp();
```

---

### 享元模式 (Flyweight)

**意图**：共享细粒度对象，节省内存。

**适用场景**：
- 大量相似对象
- 对象可共享的部分
- 缓冲区、缓存

**Dart 实现**：
```dart
class TreeType {
  final String name;
  final String color;
  final String texture;

  TreeType(this.name, this.color, this.texture);

  void draw(int x, int y) {
    print('Drawing $name at ($x, $y) with color $color');
  }
}

class TreeFactory {
  static final Map<String, TreeType> _cache = {};

  static TreeType getTreeType(String name, String color, String texture) {
    final key = '$name-$color-$texture';
    return _cache.putIfAbsent(
      key,
      () => TreeType(name, color, texture),
    );
  }
}

class Tree {
  final int x, y;
  final TreeType type; // 共享的 TreeType

  Tree(this.x, this.y, this.type);
}

// 使用 - 1000 棵树只用 5 个 TreeType
final forest = [
  Tree(10, 20, TreeFactory.getTreeType('Oak', 'Green', 'oak.png')),
  Tree(15, 25, TreeFactory.getTreeType('Oak', 'Green', 'oak.png')),
  Tree(30, 40, TreeFactory.getTreeType('Pine', 'DarkGreen', 'pine.png')),
];
```

---

## 行为型模式 (11种)

### 观察者模式 (Observer)

**意图**：定义一对多依赖，当对象变化时自动通知依赖者。

**适用场景**：
- 事件系统
- 数据绑定
- 发布-订阅

**Dart 实现**：
```dart
// 使用 Stream（推荐方式）
class UserRepository {
  final _userController = StreamController<User>.broadcast();

  Stream<User> get userStream => _userController.stream;

  void updateUser(User user) {
    // 业务逻辑
    _userController.add(user);
  }
}

// Flutter 中使用
class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final repo = context.read<UserRepository>();

    return StreamBuilder<User>(
      stream: repo.userStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text('Hello ${snapshot.data!.name}');
        }
        return CircularProgressIndicator();
      },
    );
  }
}

// 自定义观察者接口（复杂场景）
abstract class Observer<T> {
  void update(T data);
}

class Subject<T> {
  final List<Observer<T>> _observers = [];

  void attach(Observer<T> o) => _observers.add(o);
  void detach(Observer<T> o) => _observers.remove(o);
  void notify(T data) => _observers.forEach((o) => o.update(data));
}
```

---

### 策略模式 (Strategy)

**意图**：定义一系列算法，使它们可以互换。

**适用场景**：
- 多种排序算法
- 多种支付方式
- 多种验证规则

**Dart 实现**：
```dart
abstract class SortStrategy<T> {
  List<T> sort(List<T> items);
}

class QuickSort<T> implements SortStrategy {
  @override
  List<T> sort(List<T> items) {
    // 快速排序实现
    if (items.length < 2) return items;
    final pivot = items.first;
    return [
      ...sort(items.where((e) => e.hashCode < pivot.hashCode).toList()),
      pivot,
      ...sort(items.where((e) => e.hashCode >= pivot.hashCode).toList()),
    ];
  }
}

class MergeSort<T> implements SortStrategy {
  @override
  List<T> sort(List<T> items) {
    // 归并排序实现
    return items;
  }
}

class Sorter<T> {
  SortStrategy<T> _strategy;

  Sorter(this._strategy);

  void setStrategy(SortStrategy<T> s) => _strategy = s;
  List<T> sort(List<T> items) => _strategy.sort(items);
}

// 使用
final sorter = Sorter(QuickSort());
sorter.sort([3, 1, 2]);
sorter.setStrategy(MergeSort());
sorter.sort([3, 1, 2]);
```

---

### 命令模式 (Command)

**意图**：将请求封装为对象，支持撤销/重做。

**适用场景**：
- 撤销/重做功能
- 任务队列
- 日志记录
- 事务

**Dart 实现**：
```dart
abstract class Command {
  void execute();
  void undo();
}

class AddCommand implements Command {
  final List<int> list;
  final int value;

  AddCommand(this.list, this.value);

  @override
  void execute() => list.add(value);
  @override
  void undo() => list.remove(value);
}

class CommandManager {
  final List<Command> _history = [];
  int _index = -1;

  void execute(Command cmd) {
    // 移除 redo 栈
    if (_index < _history.length - 1) {
      _history.removeRange(_index + 1, _history.length);
    }
    cmd.execute();
    _history.add(cmd);
    _index++;
  }

  void undo() {
    if (_index >= 0) {
      _history[_index--].undo();
    }
  }

  void redo() {
    if (_index < _history.length - 1) {
      _history[++_index].execute();
    }
  }
}
```

---

### 状态模式 (State)

**意图**：对象内部状态变化时改变其行为。

**适用场景**：
- 状态机
- 工作流
- 订单状态

**Dart 实现**：
```dart
abstract class OrderState {
  void proceed(Order order);
  void cancel(Order order);
  String get status;
}

class PendingState implements OrderState {
  @override
  String get status => '待支付';

  @override
  void proceed(Order order) {
    // 更新状态
    order.transitionTo(PaidState());
  }

  @override
  void cancel(Order order) {
    order.transitionTo(CancelledState());
  }
}

class PaidState implements OrderState {
  @override
  String get status => '已支付';

  @override
  void proceed(Order order) {
    order.transitionTo(ShippedState());
  }

  @override
  void cancel(Order order) {
    order.transitionTo(RefundingState());
  }
}

class Order {
  OrderState _state = PendingState();

  String get status => _state.status;

  void transitionTo(OrderState state) {
    _state = state;
  }

  void proceed() => _state.proceed(this);
  void cancel() => _state.cancel(this);
}
```

---

### 模板方法模式 (Template Method)

**意图**：定义算法骨架，部分步骤由子类实现。

**适用场景**：
- 算法框架固定，部分步骤可变
- 代码复用

**Dart 实现**：
```dart
abstract class DataImporter {
  // 模板方法
  Future<List<Map<String, dynamic>>> import(String path) async {
    final rawData = await readFile(path);
    final parsed = parse(rawData);
    final validated = validate(parsed);
    return transform(validated);
  }

  Future<String> readFile(String path) async => throw UnimplementedError();
  List<Map<String, dynamic>> parse(String data) => throw UnimplementedError();
  List<Map<String, dynamic>> validate(List<Map<String, dynamic>> data) => data;
  List<Map<String, dynamic>> transform(List<Map<String, dynamic>> data) => data;
}

class CsvImporter extends DataImporter {
  @override
  Future<String> readFile(String path) async {
    // 读取 CSV
    return 'name,age\nAlice,30';
  }

  @override
  List<Map<String, dynamic>> parse(String data) {
    // 解析 CSV
    return [{'name': 'Alice', 'age': '30'}];
  }
}
```

---

### 职责链模式 (Chain of Responsibility)

**意图**：将请求沿链传递，直到被处理。

**适用场景**：
- 多步骤验证
- 过滤器链
- 中间件

**Dart 实现**：
```dart
abstract class Handler {
  Handler? next;

  Handler setNext(Handler handler) {
    next = handler;
    return handler;
  }

  Future<String?> handle(String request) async {
    final result = await process(request);
    if (result != null) return result;
    return await next?.handle(request);
  }

  Future<String?> process(String request) async => null;
}

class AuthHandler extends Handler {
  @override
  Future<String?> process(String request) async {
    if (!request.contains('token')) {
      return 'Unauthorized';
    }
    return null; // 继续传递
  }
}

class ValidationHandler extends Handler {
  @override
  Future<String?> process(String request) async {
    if (request.length < 10) {
      return 'Invalid request';
    }
    return null;
  }
}

// 使用
final auth = AuthHandler();
final validation = ValidationHandler();
auth.setNext(validation);

await auth.handle('request with token');
```

---

### 访问者模式 (Visitor)

**意图**：将操作与对象结构分离。

**适用场景**：
- 对象结构稳定，操作经常变化
- 需对集合中不同类型对象执行操作

**Dart 实现**：
```dart
abstract class Shape {
  void accept(Visitor visitor);
}

class Circle extends Shape {
  final double radius;
  Circle(this.radius);

  @override
  void accept(Visitor visitor) => visitor.visitCircle(this);
}

class Rectangle extends Shape {
  final double width, height;
  Rectangle(this.width, this.height);

  @override
  void accept(Visitor visitor) => visitor.visitRectangle(this);
}

abstract class Visitor {
  void visitCircle(Circle circle);
  void visitRectangle(Rectangle rectangle);
}

class AreaCalculator implements Visitor {
  @override
  void visitCircle(Circle c) => print('Circle area: ${3.14 * c.radius * c.radius}');
  @override
  void visitRectangle(Rectangle r) => print('Rectangle area: ${r.width * r.height}');
}
```

---

### 中介者模式 (Mediator)

**意图**：封装对象间的交互，减少耦合。

**适用场景**：
- UI 组件通信
- 聊天室
- MVC 架构

**Dart 实现**：
```dart
class ChatRoom {
  final List<User> _users = [];

  void join(User user) {
    _users.add(user);
    broadcast('${user.name} joined', sender: user);
  }

  void send(String message, User sender) {
    broadcast(message, sender: sender);
  }

  void broadcast(String message, {User? sender}) {
    for (final user in _users) {
      if (user != sender) {
        user.receive(message, sender?.name ?? 'System');
      }
    }
  }
}

class User {
  final String name;
  final ChatRoom _room;

  User(this.name, this._room);

  void send(String message) => _room.send(message, this);
  void receive(String message, String from) {
    print('[$name] $from: $message');
  }
}

// 使用
final room = ChatRoom();
final alice = User('Alice', room);
final bob = User('Bob', room);
room.join(alice);
room.join(bob);
alice.send('Hello!'); // Bob receives
```

---

### 迭代器模式 (Iterator)

**意图**：顺序访问集合元素，不暴露内部结构。

**Dart 实现**：
```dart
// Dart 内置支持
final list = [1, 2, 3];
for (final item in list) { } // 使用内置迭代器

// 自定义迭代器
class FibonacciSequence implements Iterable<int> {
  @override
  Iterator<int> get iterator => _FibonacciIterator();
}

class _FibonacciIterator implements Iterator<int> {
  int _current = 0;
  int _next = 1;

  @override
  int get current => _current;

  @override
  bool moveNext() {
    final temp = _current;
    _current = _next;
    _next = temp + _next;
    return true;
  }
}

// 使用
for (final n in FibonacciSequence().take(10)) {
  print(n);
}
```

---

### 解释器模式 (Interpreter)

**意图**：定义语法表示和解释器。

**适用场景**：
- DSL
- 配置文件解析
- 数学表达式

**Dart 实现**：
```dart
abstract class Expression {
  int interpret(Map<String, int> context);
}

class NumberExpression implements Expression {
  final int number;
  NumberExpression(this.number);

  @override
  int interpret(Map<String, int> context) => number;
}

class VariableExpression implements Expression {
  final String name;
  VariableExpression(this.name);

  @override
  int interpret(Map<String, int> context) => context[name] ?? 0;
}

class AddExpression implements Expression {
  final Expression left, right;
  AddExpression(this.left, this.right);

  @override
  int interpret(Map<String, int> context) {
    return left.interpret(context) + right.interpret(context);
  }
}

// 使用: x + 5
final expr = AddExpression(
  VariableExpression('x'),
  NumberExpression(5),
);
print(expr.interpret({'x': 10})); // 15
```

---

### 备忘录模式 (Memento)

**意图**：保存和恢复对象状态。

**适用场景**：
- 撤销功能
- 检查点
- 快照

**Dart 实现**：
```dart
class Memento {
  final String state;
  Memento(this.state);
}

class Editor {
  String _content = '';

  void type(String text) => _content += text;

  String get content => _content;

  Memento save() => Memento(_content);

  void restore(Memento m) => _content = m.state;
}

class History {
  final List<Memento> _states = [];
  final Editor _editor;

  History(this._editor);

  void backup() => _states.add(_editor.save());

  void undo() {
    if (_states.isEmpty) return;
    final memento = _states.removeLast();
    _editor.restore(memento);
  }
}

// 使用
final editor = Editor();
final history = History(editor);

editor.type('Hello');
history.backup();
editor.type(' World');
print(editor.content); // 'Hello World'

history.undo();
print(editor.content); // 'Hello'
```

---

## 模式推荐流程

当用户提供问题时，按以下流程推荐：

### 1. 问题分析

```
1. 核心需求是什么？
   - 创建对象 → 创建型模式
   - 组织结构 → 结构型模式
   - 控制行为 → 行为型模式

2. 变化维度有几个？
   - 1个 → 可能不需要模式
   - 2-3个 → 考虑模式
   - 3+ → 重新设计

3. 复用/灵活性要求？
   - 高 → 模式值得
   - 低 → 简单实现
```

### 2. 模式筛选矩阵

| 需求\特征 | 解耦 | 复用 | 扩展 | 复杂度 |
|-----------|------|------|------|--------|
| 创建封装 | 高 | 中 | 低 | 低 |
| 继承改写 | 中 | 高 | 高 | 中 |
| 对象组合 | 高 | 高 | 高 | 中 |

### 3. 决策输出

```markdown
## 模式推荐

### 🏆 推荐: [模式名称]
- **分类**: 创建型/结构型/行为型
- **意图**: 一句话说明
- **适用性**: ✅ 需求X / ✅ 需求Y

### 备选方案
1. **模式A**: 优点 / 缺点
2. **模式B**: 优点 / 缺点
3. **不使用模式**: 简单实现更合适的情况

### 误用警告
⚠️ [什么情况下不要用]
```

---

## 代码模板库

### 快速复制模板

#### 单例（懒汉）
```dart
class Singleton {
  static Singleton? _instance;
  Singleton._();
  static Singleton get i => _instance ??= Singleton._();
}
```

#### 工厂方法
```dart
T create<T>(...) => ...;
```

#### 观察者
```dart
Stream<T> get stream;
void emit(T data) => _controller.add(data);
```

#### 策略
```dart
abstract class Strategy { R execute(...); }
class Context { Strategy s; R run() => s.execute(...); }
```

---

## 快速查询

### 按需求查模式

| 需求 | 首选 | 备选 |
|------|------|------|
| 全局唯一 | 单例 | 依赖注入 |
| 创建复杂对象 | 建造者 | 工厂方法 |
| 系列对象创建 | 抽象工厂 | 工厂方法 |
| 对象复制 | 原型 | 序列化 |
| 接口适配 | 适配器 | 装饰器 |
| 行为扩展 | 装饰器 | 继承 |
| 访问控制 | 代理 | 装饰器 |
| 简化复杂系统 | 外观 | 直接调用 |
| 部分-整体 | 组合 | 继承 |
| 细粒度共享 | 享元 | 对象池 |
| 解耦发送接收 | 观察者 | 中介者 |
| 算法切换 | 策略 | 函数参数 |
| 请求封装 | 命令 | 函数 |
| 状态变化 | 状态 | if/switch |
| 算法骨架 | 模板方法 | 继承 |
| 请求链 | 职责链 | if/switch |
| 对象交互 | 中介者 | 直接引用 |
| 操作分离 | 访问者 | 多态 |
| 对象遍历 | 迭代器 | for循环 |
| 状态保存 | 备忘录 | 序列化 |
| 语法解析 | 解释器 | 正则 |

### 反模式警告

| 模式 | 滥用场景 |
|------|----------|
| 单例 | 全局状态、难以测试 |
| 工厂 | 简单对象创建 |
| 观察者 | 复杂状态同步 |
| 策略 | 简单分支 |
| 装饰器 | 继承更简单 |

---

## 触发词

| 触发词 | 激活模式 |
|--------|----------|
| "设计模式"、"pattern" | 完整推荐流程 |
| "用什么模式"、"推荐模式" | 模式筛选 |
| 单例/factory/观察者/... | 对应模式详解 |
| "代码模板"、"template" | 代码模板库 |
| "过度设计" | 反模式警告 |