import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dacong_client/core/domain/entities/content.dart';
import 'package:dacong_client/presentation/widgets/content_detail/content_header.dart';

void main() {
  group('ContentHeader', () {
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

    testWidgets('displays content name and vendor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentHeader(content: testContent),
          ),
        ),
      );

      expect(find.text('Test Tool'), findsOneWidget);
      expect(find.text('Test Vendor'), findsOneWidget);
    });

    testWidgets('displays helpful rate', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentHeader(content: testContent),
          ),
        ),
      );

      // 10 / (10 + 2) = 83%
      expect(find.text('83%'), findsOneWidget);
    });

    testWidgets('displays feedback count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentHeader(content: testContent),
          ),
        ),
      );

      expect(find.text('12 人反馈'), findsOneWidget);
    });

    testWidgets('displays thumb up icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentHeader(content: testContent),
          ),
        ),
      );

      expect(find.byIcon(Icons.thumb_up), findsOneWidget);
    });
  });
}
