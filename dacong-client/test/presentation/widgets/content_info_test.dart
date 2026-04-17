import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dacong_client/core/domain/entities/content.dart';
import 'package:dacong_client/presentation/widgets/content_detail/content_info.dart';

void main() {
  group('ContentInfo', () {
    late Content testContent;

    setUp(() {
      testContent = Content(
        id: 'test-id',
        name: 'Test Tool',
        vendor: 'Test Vendor',
        description: 'Test Description',
        officialWebsite: 'https://test.com',
        githubUrl: 'https://github.com/test',
        features: ['Feature 1', 'Feature 2'],
        priceInfo: const PriceInfo(
          isFree: true,
          freeDescription: 'Free forever',
          paidDescription: null,
          tiers: [],
        ),
        accessInfo: const AccessInfo(
          availableInChina: true,
          needsVpn: false,
          difficulty: InstallDifficulty.easy,
          installGuideUrl: 'https://test.com/guide',
        ),
        useCases: ['Use case 1', 'Use case 2'],
        helpfulCount: 10,
        unhelpfulCount: 2,
        publishedAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    });

    testWidgets('displays content description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentInfo(content: testContent),
          ),
        ),
      );

      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('displays price information for free content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentInfo(content: testContent),
          ),
        ),
      );

      expect(find.text('免费'), findsOneWidget);
    });

    testWidgets('displays access information for China available content',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentInfo(content: testContent),
          ),
        ),
      );

      expect(find.text('国内可用'), findsOneWidget);
    });

    testWidgets('displays install difficulty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentInfo(content: testContent),
          ),
        ),
      );

      expect(find.text('简单'), findsOneWidget);
    });

    testWidgets('displays official website button when available',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentInfo(content: testContent),
          ),
        ),
      );

      expect(find.text('官网'), findsOneWidget);
    });

    testWidgets('displays GitHub button when available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentInfo(content: testContent),
          ),
        ),
      );

      expect(find.text('GitHub'), findsOneWidget);
    });

    testWidgets('displays correct difficulty color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentInfo(content: testContent),
          ),
        ),
      );

      // Easy difficulty should be green
      final textWidget = tester.widget<Text>(
        find.text('简单'),
      );
      expect(textWidget.style?.color, equals(Colors.green));
    });
  });
}
