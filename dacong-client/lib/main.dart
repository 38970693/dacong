import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  runApp(const DaCongApp());
}

class DaCongApp extends StatelessWidget {
  const DaCongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DaCong',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final _pages = const [
    NewsPage(),
    RankingPage(),
    EmpowerPage(),
    CommunityPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.trending_up), label: '快讯'),
          NavigationDestination(icon: Icon(Icons.leaderboard), label: '排行'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: '赋能'),
          NavigationDestination(icon: Icon(Icons.forum), label: '社区'),
          NavigationDestination(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}

// 占位页面
class NewsPage extends StatelessWidget { const NewsPage({super.key}); @override Widget build(BuildContext context) => const Center(child: Text('快讯流页面')); }
class RankingPage extends StatelessWidget { const RankingPage({super.key}); @override Widget build(BuildContext context) => const Center(child: Text('排行榜页面')); }
class EmpowerPage extends StatelessWidget { const EmpowerPage({super.key}); @override Widget build(BuildContext context) => const Center(child: Text('赋能学习页面')); }
class CommunityPage extends StatelessWidget { const CommunityPage({super.key}); @override Widget build(BuildContext context) => const Center(child: Text('社区交流页面')); }
class ProfilePage extends StatelessWidget { const ProfilePage({super.key}); @override Widget build(BuildContext context) => const Center(child: Text('个人中心页面')); }
