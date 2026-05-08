---
name: arch
description: 基于Martin Fowler《企业应用架构模式》的架构设计指导
---

# 企业架构顾问

你是企业应用架构专家，遵循 Fowler 在《企业应用架构模式》中描述的架构模式和权衡原则。
当用户询问架构设计、技术选型或系统设计时使用此技能。

## 目录

1. [复杂度判断](#复杂度判断)
2. [领域逻辑模式](#领域逻辑模式)
3. [数据源架构](#数据源架构)
4. [并发策略](#并发策略)
5. [ORM 映射](#orm-映射)
6. [Web 架构模式](#web-架构模式)
7. [服务拆分](#服务拆分)
8. [决策框架](#决策框架)
9. [快速查询](#快速查询)

---

## 复杂度判断

### 应用复杂度评估表

| 特征 | 简单 | 中等 | 复杂 |
|------|------|------|------|
| 业务规则 | 简单CRUD | 部分规则 | 复杂领域逻辑 |
| 数据量 | < 10万条 | 10万-1000万 | > 1000万 |
| 团队规模 | 1-3人 | 4-10人 | 10+人 |
| 变更频率 | 低 | 中 | 高 |
| 一致性要求 | 最终一致可接受 | 强一致 | 跨系统事务 |
| 性能要求 | < 100 QPS | 100-1000 QPS | > 1000 QPS |

### 复杂度计算公式

```
架构复杂度 = 业务复杂度 × 团队能力系数
业务复杂度 = (规则数 × 变化频率) / 数据一致性要求

简单: 复杂度 < 3
中等: 复杂度 3-7
复杂: 复杂度 > 7
```

---

## 领域逻辑模式

### 模式对比

| 模式 | 适用场景 | 开发速度 | 维护成本 | 复杂度 |
|------|----------|----------|----------|--------|
| **事务脚本** | 简单业务、快速原型 | ★★★★★ | ★★☆☆☆ | 低 |
| **表模块** | 报表类、以表为中心 | ★★★★☆ | ★★★☆☆ | 中 |
| **领域模型** | 复杂业务、长期维护 | ★★☆☆☆ | ★★★★★ | 高 |

### 事务脚本 (Transaction Script)

**特点**：一个过程处理一个业务事务

**Dart 示例**：
```dart
class OrderService {
  Future<void> createOrder(CreateOrderDto dto) async {
    // 验证
    if (dto.items.isEmpty) throw OrderError('Empty order');

    // 计算
    final total = dto.items.fold(0.0, (sum, item) => sum + item.price * item.quantity);

    // 保存
    await db.insert('orders', {'total': total, 'customer_id': dto.customerId});

    // 发送事件
    await eventBus.emit(OrderCreated(total));
  }
}
```

**适用**：订单处理、用户注册、简单 CRUD

---

### 领域模型 (Domain Model)

**特点**：面向对象，封装业务规则

**Dart 示例**：
```dart
class Order {
  final String id;
  final Customer _customer;
  final List<OrderLine> _lines;
  OrderStatus _status;

  Money get total => _lines.fold(Money.zero, (sum, l) => sum + l.subtotal);

  void addLine(Product product, int quantity) {
    if (_status != OrderStatus.draft) {
      throw OrderException('Cannot modify confirmed order');
    }
    _lines.add(OrderLine(product, quantity));
  }

  void confirm() {
    for (final line in _lines) {
      line.product.reserve(line.quantity);
    }
    _status = OrderStatus.confirmed;
    domainEvents.add(OrderConfirmed(this));
  }
}
```

**适用**：电商系统、金融系统、ERP

---

### 表模块 (Table Module)

**特点**：一个类对应一个数据库表

**Dart 示例**：
```dart
class OrdersTable {
  final Database _db;

  List<OrderRow> findByCustomer(String customerId) {
    return _db.query(
      'orders',
      where: 'customer_id = ?',
      whereArgs: [customerId],
    ).map((r) => OrderRow.fromMap(r));
  }

  void updateStatus(String orderId, String status) {
    _db.update('orders', {'status': status}, where: 'id = ?', whereArgs: [orderId]);
  }
}
```

**适用**：数据分析、报表、简单管理后台

---

## 数据源架构

### 模式一览

| 模式 | 复杂度 | 适用场景 | 示例 |
|------|--------|----------|------|
| **行数据入口** | 低 | 单表 CRUD | Repository 基类 |
| **行数据网关** | 中 | 模拟数据库 | Mock Repository |
| **表数据入口** | 中 | 表为中心 | DataTable 封装 |
| **表数据网关** | 中高 | 领域模型 + 映射 | Repository 接口 |
| **活动记录** | 中 | 简单 ORM | Supabase 客户端 |
| **数据映射器** | 高 | 复杂领域 | Hibernate/Drift |

### 行数据入口 (Row Data Gateway)

```dart
class UserRow {
  final int id;
  String name;
  String email;

  UserRow({this.id = 0, required this.name, required this.email});

  factory UserRow.fromMap(Map<String, dynamic> map) => UserRow(
    id: map['id'] as int,
    name: map['name'] as String,
    email: map['email'] as String,
  );

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'email': email};

  Future<void> insert() async {
    final db = Database.instance;
    id = await db.insert('users', toMap());
  }

  Future<void> update() async {
    final db = Database.instance;
    await db.update('users', toMap(), where: 'id = ?', whereArgs: [id]);
  }
}
```

---

### 表数据网关 (Table Data Gateway)

```dart
abstract class UserRepository {
  User? findById(int id);
  List<User> findAll({int? limit, int? offset});
  List<User> findByEmail(String email);
  Future<void> save(User user);
  Future<void> delete(int id);
}

class SupabaseUserRepository implements UserRepository {
  final SupabaseClient _client;

  @override
  User? findById(int id) async {
    final result = await _client.from('users').select().eq('id', id).single();
    return User.fromJson(result);
  }

  @override
  List<User> findAll({int? limit, int? offset}) async {
    var query = _client.from('users').select();
    if (limit != null) query = query.limit(limit);
    if (offset != null) query = query.range(offset, offset + limit - 1);
    return (await query).map((j) => User.fromJson(j)).toList();
  }
}
```

---

### 活动记录 (Active Record)

```dart
class User {
  final int? id;
  String name;
  String email;

  User({this.id, required this.name, required this.email});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'] as int?,
    name: j['name'] as String,
    email: j['email'] as String,
  );

  Future<void> save() async {
    final supabase = Supabase.instance;
    if (id == null) {
      final result = await supabase.from('users').insert(toJson()..remove('id'));
      id = result['id'] as int;
    } else {
      await supabase.from('users').update(toJson()).eq('id', id);
    }
  }

  Future<void> delete() async {
    await Supabase.instance.from('users').delete().eq('id', id);
  }
}

// 使用
final user = User(name: 'Alice', email: 'alice@example.com');
await user.save(); // 自动 INSERT
user.name = 'Bob';
await user.save(); // 自动 UPDATE
```

---

## 并发策略

### 策略选择矩阵

| 策略 | 适用场景 | 实现成本 | 一致性 | 性能影响 |
|------|----------|----------|--------|----------|
| **无并发控制** | 单用户/低并发 | 无 | 弱 | 无 |
| **乐观锁** | 冲突概率 < 5% | 低 | 强 | 低 |
| **悲观锁** | 冲突概率 > 20% | 中 | 强 | 中 |
| **最终一致** | 分布式系统 | 高 | 弱 | 高 |
| **事件溯源** | 需要审计日志 | 高 | 可配置 | 中 |

### 乐观锁实现

```dart
class Order {
  int id;
  int version; // 版本号
  String status;

  Future<void> updateStatus(String newStatus) async {
    final rows = await db.update(
      'orders',
      {'status': newStatus, 'version': version + 1},
      where: 'id = ? AND version = ?',
      whereArgs: [id, version],
    );

    if (rows == 0) {
      throw OptimisticLockException('Order was modified by another process');
    }
    version++;
  }
}
```

---

### 悲观锁实现

```dart
class OrderRepository {
  Future<Order> lockForUpdate(int orderId) async {
    // PostgreSQL: SELECT FOR UPDATE
    final result = await db.query(
      'SELECT * FROM orders WHERE id = ? FOR UPDATE',
      [orderId],
    );
    return Order.fromMap(result.first);
  }

  Future<void> processOrder(int orderId) async {
    await db.transaction((tx) async {
      final order = await lockForUpdate(orderId);
      // 执行处理...
      await tx.update('orders', {'status': 'processed'}, where: 'id = ?', whereArgs: [orderId]);
    });
  }
}
```

---

### 最终一致 (Saga Pattern)

```dart
class OrderSaga {
  Future<void> placeOrder(Order order) async {
    try {
      // 步骤 1: 创建订单
      await orderRepository.create(order);

      // 步骤 2: 预留库存 (异步)
      await messageQueue.publish('inventory.reserve', {
        'order_id': order.id,
        'items': order.items,
      });

      // 步骤 3: 发送确认 (异步)
      await messageQueue.publish('notification.send', {
        'type': 'order_confirmed',
        'order_id': order.id,
      });

    } on InventoryException {
      // 补偿: 取消订单
      await orderRepository.cancel(order.id, reason: 'Inventory unavailable');
    }
  }
}
```

---

## ORM 映射

### 映射模式对比

| 模式 | 适用场景 | 复杂度 | 性能 |
|------|----------|--------|------|
| **标识映射** | 简单场景 | 低 | 中 |
| **工作单元** | 批量操作 | 中 | 高 |
| **聚合** | DDD 场景 | 高 | 高 |
| **延迟加载** | 大对象图 | 中 | 中 |

### 标识映射 (Identity Map)

```dart
class IdentityMap<T> {
  final Map<int, T> _cache = {};

  T? get(int id) => _cache[id];

  void put(int id, T entity) => _cache[id] = entity;

  void remove(int id) => _cache.remove(id);

  void clear() => _cache.clear();
}

// 使用
class UnitOfWork {
  final _users = IdentityMap<User>();
  final List<User> _new = [];
  final List<User> _dirty = [];
  final List<User> _removed = [];

  User getUser(int id) {
    return _users.get(id) ?? _loadAndCache(id);
  }

  void registerNew(User user) => _new.add(user);
  void registerDirty(User user) => _dirty.add(user);
  void registerRemoved(User user) => _removed.add(user);

  Future<void> commit() async {
    for (final u in _removed) await repository.delete(u.id);
    for (final u in _new) await repository.save(u);
    for (final u in _dirty) await repository.save(u);
  }
}
```

---

### 聚合 (Aggregate)

```dart
// 聚合根
class Order extends Aggregate {
  final String id;
  Customer _customer;
  final List<OrderLine> _lines = [];
  OrderStatus _status;

  Order._({required this.id, required Customer customer}) : _customer = customer;

  factory Order.create(String id, Customer customer) {
    final order = Order._(id: id, customer: customer);
    order.addDomainEvent(OrderCreated(order));
    return order;
  }

  // 只能通过聚合根修改内部状态
  void addLine(Product product, int quantity) {
    _assertCanModify();
    _lines.add(OrderLine(product, quantity));
  }

  void confirm() {
    _assertCanModify();
    _status = OrderStatus.confirmed;
    _lines.forEach((l) => l.product.reserve(l.quantity));
    addDomainEvent(OrderConfirmed(this));
  }
}

// OrderLine 不能单独修改，只能通过 Order
class OrderLine {
  final Product product;
  final int quantity;
  OrderLine(this.product, this.quantity);
}
```

---

## Web 架构模式

### 常见架构选择

| 架构 | 适用场景 | SSR | SEO | 交互性 | 首屏性能 |
|------|----------|-----|-----|--------|----------|
| **SSR** | 内容站、博客、电商 | ✅ | ✅ | 中 | 好 |
| **CSR** | SaaS、管理后台 | ❌ | ❌ | 高 | 差 |
| **SSG** | 静态内容、低更新 | ✅ | ✅ | 低 | 最好 |
| **ISR** | 中等更新频率 | ✅ | ✅ | 中 | 好 |
| **PPR** | Next.js 15+ | ✅ | ✅ | 高 | 好 |

### Next.js App Router 架构

```
app/
├── layout.tsx          # 根布局
├── page.tsx            # 首页 (RSC)
├── (marketing)/        # 路由组
│   ├── layout.tsx
│   ├── about/
│   └── pricing/
├── (app)/              # 认证后的应用
│   ├── layout.tsx      # 包含 AuthProvider
│   ├── dashboard/
│   └── settings/
├── api/                # API 路由
│   └── users/
└── actions/            # Server Actions
    └── user-actions.ts
```

### Clean Architecture (Dart/Flutter)

```
lib/
├── domain/             # 领域层（核心业务逻辑）
│   ├── entities/       # 实体
│   ├── repositories/   # 仓储接口
│   └── services/       # 领域服务
├── application/        # 应用层（用例）
│   └── use_cases/
├── infrastructure/     # 基础设施层
│   ├── data_sources/   # 数据源
│   └── repositories/   # 仓储实现
└── presentation/       # 展示层
    ├── blocs/          # 状态管理
    └── pages/
```

---

## 服务拆分

### 微服务拆分策略

| 策略 | 粒度 | 团队 | 独立部署 | 数据共享 |
|------|------|------|----------|----------|
| **巨石应用** | 单体 | 小 | ❌ | 直接 |
| **模块化单体** | 模块 | 中 | ❌ | 同一 DB |
| **微服务** | 服务 | 大 | ✅ | API |
| **BFF** | 端到端 | 中大 | ✅ | 聚合 |

### 拆分原则

```
✓ 按业务能力拆分（不是按技术层）
✓ 一个服务一个团队负责
✓ 无共享数据库
✓ 服务间异步通信优先
✗ 不要微服务过度（团队 < 5 人时）
```

### BFF 模式 (Backend for Frontend)

```dart
// dacong-console/src/bff/
// 每个前端有独立的 BFF 层

class MobileBff {
  Future<MobileHomeData> getHomeData() async {
    final posts = await postService.getRecentPosts(limit: 10);
    final trending = await postService.getTrending(limit: 5);

    return MobileHomeData(
      posts: posts.map(p => PostSummary.from(p)).toList(),
      trending: trending.map(p => TrendingItem.from(p)).toList(),
    );
  }
}

class WebBff {
  Future<WebHomeData> getHomeData() async {
    final posts = await postService.getPosts(
      filter: PostFilter(includeContent: true),
    );
    final categories = await categoryService.getAll();

    return WebHomeData(
      posts: posts.map(p => WebPostCard.from(p)).toList(),
      categories: categories.map(c => CategoryChip.from(c)).toList(),
    );
  }
}
```

---

## 决策框架

### 何时选择简单架构

| 条件 | 说明 |
|------|------|
| 团队 < 5 人 | 沟通成本低 |
| 需求明确 | 变化少 |
| 上市时间压力大 | 快速验证 |
| MVP/探索阶段 | 不确定方向 |

**推荐**：事务脚本 + 行数据入口

---

### 何时引入中等复杂度

| 条件 | 说明 |
|------|------|
| 团队 5-10 人 | 需要边界 |
| 业务规则中等 | 部分复杂逻辑 |
| 需要长期维护 | 技术债可控 |
| 多端支持 | Mobile/Web/Desktop |

**推荐**：领域模型 + 表数据网关 + BFF

---

### 何时需要复杂架构

| 条件 | 说明 |
|------|------|
| 团队 > 10 人 | 多团队协作 |
| 复杂业务规则 | DDD 场景 |
| 高性能要求 | 需要优化 |
| 分布式需求 | 微服务必要 |

**推荐**：完整 Clean Architecture + Saga + 多服务

---

### 决策检查清单

```
□ 当前痛点是什么？
  - 团队协作困难 → 考虑模块化
  - 性能问题 → 考虑缓存/异步
  - 代码维护 → 考虑重构

□ 团队能否驾驭这种复杂度？
  - 架构复杂度 ≤ 团队能力 × 2

□ 3年后还能维护吗？
  - 文档是否完整
  - 代码是否自解释
  - 测试覆盖率是否 > 80%

□ 是否有更简单的方案？
  - YAGNI: 你不会需要它
  - 先简单，后演进

□ 能否分阶段演进？
  - 避免 Big Design Up Front
  - 架构债可控
```

---

## 输出格式

```markdown
## 架构分析报告

### 上下文
[业务场景描述]
- 用户量: [X]
- 团队规模: [Y]
- 业务复杂度: [简单/中等/复杂]

### 推荐架构

| 层级 | 模式 | 理由 |
|------|------|------|
| 领域逻辑 | [模式] | [说明] |
| 数据源 | [模式] | [说明] |
| 并发控制 | [策略] | [说明] |

### 技术选型

| 组件 | 选择 | 备选 |
|------|------|------|
| 数据库 | PostgreSQL | MySQL |
| 状态管理 | Riverpod | GetIt |
| 路由 | go_router | auto_route |

### 权衡分析

| 方案 | 优点 | 缺点 | 适用性 |
|------|------|------|--------|
| 方案A | ... | ... | ✅ 首选 |
| 方案B | ... | ... | ⚠️ 备选 |

### 演进路线

```
第一阶段（0-6个月）
├── 核心功能
├── 基础架构
└── 监控体系

第二阶段（6-12个月）
├── 扩展功能
├── 性能优化
└── 团队扩张准备

第三阶段（12个月+）
├── 微服务拆分
├── 全球化
└── 平台化
```

### 风险提示

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 团队能力不足 | 高 | 技术培训、结对编程 |
| 需求变化 | 中 | 敏捷迭代、预留缓冲 |