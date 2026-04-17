import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// 应用标题
  ///
  /// In zh, this message translates to:
  /// **'大聪明'**
  String get appTitle;

  /// 底部导航-AI热点资讯
  ///
  /// In zh, this message translates to:
  /// **'AI速递'**
  String get newsTab;

  /// 底部导航-AI工具排行
  ///
  /// In zh, this message translates to:
  /// **'工具榜'**
  String get rankingTab;

  /// 底部导航-免费使用技巧
  ///
  /// In zh, this message translates to:
  /// **'免费用'**
  String get empowerTab;

  /// 底部导航-社区
  ///
  /// In zh, this message translates to:
  /// **'社区'**
  String get communityTab;

  /// 底部导航-个人中心
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get profileTab;

  /// 综合排行榜
  ///
  /// In zh, this message translates to:
  /// **'综合榜'**
  String get rankOverall;

  /// 分类排行榜
  ///
  /// In zh, this message translates to:
  /// **'分类榜'**
  String get rankCategory;

  /// 免费工具分类
  ///
  /// In zh, this message translates to:
  /// **'免费工具'**
  String get rankFreeModels;

  /// 开源工具分类
  ///
  /// In zh, this message translates to:
  /// **'开源工具'**
  String get rankOpenSource;

  /// 新上线分类
  ///
  /// In zh, this message translates to:
  /// **'新上线'**
  String get rankNewTech;

  /// 多模态工具
  ///
  /// In zh, this message translates to:
  /// **'多模态'**
  String get rankMultimodal;

  /// 效率工具
  ///
  /// In zh, this message translates to:
  /// **'效率工具'**
  String get rankCodeModel;

  /// 提示词模板
  ///
  /// In zh, this message translates to:
  /// **'提示词'**
  String get promptSquare;

  /// 免费AI工具合集
  ///
  /// In zh, this message translates to:
  /// **'免费工具'**
  String get workflowTutorials;

  /// 免费使用大模型的方法
  ///
  /// In zh, this message translates to:
  /// **'免费AI工具'**
  String get freeModelGuide;

  /// 快讯流标题
  ///
  /// In zh, this message translates to:
  /// **'AI热点'**
  String get hotNews;

  /// 热搜词
  ///
  /// In zh, this message translates to:
  /// **'热搜词'**
  String get trendingKeywords;

  /// 每日推荐
  ///
  /// In zh, this message translates to:
  /// **'每日推荐'**
  String get dailyRecommendation;

  /// 工具详情页
  ///
  /// In zh, this message translates to:
  /// **'工具详情'**
  String get modelDetails;

  /// GitHub热榜
  ///
  /// In zh, this message translates to:
  /// **'GitHub热榜'**
  String get githubTrending;

  /// HackerNews
  ///
  /// In zh, this message translates to:
  /// **'HackerNews'**
  String get hackerNews;

  /// 帖子列表
  ///
  /// In zh, this message translates to:
  /// **'帖子'**
  String get posts;

  /// 评论
  ///
  /// In zh, this message translates to:
  /// **'评论'**
  String get comments;

  /// 点赞
  ///
  /// In zh, this message translates to:
  /// **'点赞'**
  String get likes;

  /// 收藏
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get favorites;

  /// 设置
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// 订阅管理
  ///
  /// In zh, this message translates to:
  /// **'订阅管理'**
  String get subscriptions;

  /// 登录按钮
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get signIn;

  /// 退出登录按钮
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get signOut;

  /// 注册按钮
  ///
  /// In zh, this message translates to:
  /// **'注册'**
  String get register;

  /// 搜索框占位符
  ///
  /// In zh, this message translates to:
  /// **'搜索AI工具、话题...'**
  String get searchPlaceholder;

  /// 空状态提示
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get noData;

  /// 加载中
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get loading;

  /// 错误提示
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get error;

  /// 重试按钮
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// 查看更多
  ///
  /// In zh, this message translates to:
  /// **'查看更多'**
  String get viewMore;

  /// 发布时间
  ///
  /// In zh, this message translates to:
  /// **'发布于 {time}'**
  String publishedAt(String time);

  /// 热度标签
  ///
  /// In zh, this message translates to:
  /// **'热度：{score}'**
  String scoreLabel(String score);

  /// 使用量标签
  ///
  /// In zh, this message translates to:
  /// **'{count} 次使用'**
  String downloadsLabel(String count);

  /// 语言标签
  ///
  /// In zh, this message translates to:
  /// **'语言：{lang}'**
  String languageLabel(String lang);

  /// 话题标签
  ///
  /// In zh, this message translates to:
  /// **'话题：{topic}'**
  String topicLabel(String topic);

  /// 通知设置
  ///
  /// In zh, this message translates to:
  /// **'通知设置'**
  String get notificationSettings;

  /// 隐私设置
  ///
  /// In zh, this message translates to:
  /// **'隐私设置'**
  String get privacySettings;

  /// 关于应用
  ///
  /// In zh, this message translates to:
  /// **'关于大聪明'**
  String get aboutApp;

  /// 版本号标签
  ///
  /// In zh, this message translates to:
  /// **'版本 {version}'**
  String versionLabel(String version);

  /// 粉丝数
  ///
  /// In zh, this message translates to:
  /// **'粉丝'**
  String get followers;

  /// 关注数
  ///
  /// In zh, this message translates to:
  /// **'关注'**
  String get following;

  /// 我的帖子
  ///
  /// In zh, this message translates to:
  /// **'我的帖子'**
  String get myPosts;

  /// 我的收藏
  ///
  /// In zh, this message translates to:
  /// **'我的收藏'**
  String get myFavorites;

  /// 浏览历史
  ///
  /// In zh, this message translates to:
  /// **'浏览历史'**
  String get myHistory;

  /// 免费标签
  ///
  /// In zh, this message translates to:
  /// **'🆓 免费'**
  String get tagFree;

  /// 开源标签
  ///
  /// In zh, this message translates to:
  /// **'📂 开源'**
  String get tagOpenSource;

  /// 新工具标签
  ///
  /// In zh, this message translates to:
  /// **'🆕 新工具'**
  String get tagNewModel;

  /// 热门标签
  ///
  /// In zh, this message translates to:
  /// **'🔥 热门'**
  String get tagHot;

  /// 上升趋势标签
  ///
  /// In zh, this message translates to:
  /// **'📈 上升'**
  String get tagTrending;

  /// API可用标签
  ///
  /// In zh, this message translates to:
  /// **'🔑 API'**
  String get tagAPI;

  /// 即将上线提示
  ///
  /// In zh, this message translates to:
  /// **'即将上线'**
  String get comingSoon;

  /// 首页标题
  ///
  /// In zh, this message translates to:
  /// **'DaCong - AI工具决策助手'**
  String get homeTitle;

  /// 选择场景提示
  ///
  /// In zh, this message translates to:
  /// **'选择使用场景'**
  String get selectScenario;

  /// 编程场景
  ///
  /// In zh, this message translates to:
  /// **'写代码'**
  String get scenarioCoding;

  /// 编程场景描述
  ///
  /// In zh, this message translates to:
  /// **'AI编程助手'**
  String get scenarioCodingDesc;

  /// 视频场景
  ///
  /// In zh, this message translates to:
  /// **'做视频'**
  String get scenarioVideo;

  /// 视频场景描述
  ///
  /// In zh, this message translates to:
  /// **'视频创作工具'**
  String get scenarioVideoDesc;

  /// 图片场景
  ///
  /// In zh, this message translates to:
  /// **'做图片'**
  String get scenarioImage;

  /// 图片场景描述
  ///
  /// In zh, this message translates to:
  /// **'图片生成工具'**
  String get scenarioImageDesc;

  /// 对话场景
  ///
  /// In zh, this message translates to:
  /// **'日常对话'**
  String get scenarioChat;

  /// 对话场景描述
  ///
  /// In zh, this message translates to:
  /// **'聊天助手'**
  String get scenarioChatDesc;

  /// 最佳推荐标签
  ///
  /// In zh, this message translates to:
  /// **'最佳'**
  String get recommendationBest;

  /// 平替推荐标签
  ///
  /// In zh, this message translates to:
  /// **'平替'**
  String get recommendationAlternative;

  /// 免费推荐标签
  ///
  /// In zh, this message translates to:
  /// **'免费'**
  String get recommendationFree;

  /// 优点标题
  ///
  /// In zh, this message translates to:
  /// **'优点'**
  String get pros;

  /// 缺点标题
  ///
  /// In zh, this message translates to:
  /// **'缺点'**
  String get cons;

  /// 国内可用标签
  ///
  /// In zh, this message translates to:
  /// **'国内可用'**
  String get availableInChina;

  /// 需要VPN标签
  ///
  /// In zh, this message translates to:
  /// **'需翻墙'**
  String get needVPN;

  /// 无推荐提示
  ///
  /// In zh, this message translates to:
  /// **'暂无推荐'**
  String get noRecommendations;

  /// 请选择场景提示
  ///
  /// In zh, this message translates to:
  /// **'请选择一个使用场景'**
  String get pleaseSelectScenario;

  /// 个人中心标题
  ///
  /// In zh, this message translates to:
  /// **'个人中心'**
  String get profile;

  /// 未登录提示
  ///
  /// In zh, this message translates to:
  /// **'未登录'**
  String get notLoggedIn;

  /// 登录提示
  ///
  /// In zh, this message translates to:
  /// **'登录后可使用更多功能'**
  String get loginToAccessFeatures;

  /// 我的内容标题
  ///
  /// In zh, this message translates to:
  /// **'我的内容'**
  String get myContent;

  /// 项目单位
  ///
  /// In zh, this message translates to:
  /// **'项'**
  String get items;

  /// 语言设置
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// 主题设置
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get theme;

  /// 浅色主题
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get lightTheme;

  /// 深色主题
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get darkTheme;

  /// 跟随系统主题
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get systemTheme;

  /// 通知设置
  ///
  /// In zh, this message translates to:
  /// **'通知'**
  String get notifications;

  /// 关于标题
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get about;

  /// 隐私政策
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get privacyPolicy;

  /// 服务条款
  ///
  /// In zh, this message translates to:
  /// **'服务条款'**
  String get termsOfService;

  /// 退出登录确认
  ///
  /// In zh, this message translates to:
  /// **'确定要退出登录吗？'**
  String get confirmSignOut;

  /// 取消按钮
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// 空收藏提示
  ///
  /// In zh, this message translates to:
  /// **'还没有收藏内容'**
  String get emptyFavorites;

  /// 空历史提示
  ///
  /// In zh, this message translates to:
  /// **'还没有浏览历史'**
  String get emptyHistory;

  /// 清空历史按钮
  ///
  /// In zh, this message translates to:
  /// **'清空历史'**
  String get clearHistory;

  /// 清空历史确认
  ///
  /// In zh, this message translates to:
  /// **'确定要清空浏览历史吗？'**
  String get confirmClearHistory;

  /// 确定按钮
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get confirm;

  /// 编辑资料
  ///
  /// In zh, this message translates to:
  /// **'编辑资料'**
  String get editProfile;

  /// 用户名
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get username;

  /// 个人简介
  ///
  /// In zh, this message translates to:
  /// **'个人简介'**
  String get bio;

  /// 保存按钮
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// 应用版本
  ///
  /// In zh, this message translates to:
  /// **'应用版本'**
  String get appVersion;

  /// 检查更新
  ///
  /// In zh, this message translates to:
  /// **'检查更新'**
  String get checkUpdate;

  /// 意见反馈
  ///
  /// In zh, this message translates to:
  /// **'意见反馈'**
  String get feedback;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
