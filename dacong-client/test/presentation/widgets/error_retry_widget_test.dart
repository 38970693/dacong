import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dacong_client/presentation/widgets/error_retry_widget.dart';

void main() {
  group('ErrorRetryWidget Tests', () {
    testWidgets('displays default error message and retry button',
        (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget(
              onRetry: () => retryCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      await tester.tap(find.text('重试'));
      await tester.pump();

      expect(retryCalled, isTrue);
    });

    testWidgets('displays custom message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget(
              onRetry: () {},
              message: 'Custom error message',
            ),
          ),
        ),
      );

      expect(find.text('Custom error message'), findsOneWidget);
      expect(find.text('加载失败'), findsNothing);
    });

    testWidgets('displays custom icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget(
              onRetry: () {},
              icon: Icons.warning,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('displays custom button text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget(
              onRetry: () {},
              buttonText: 'Try Again',
            ),
          ),
        ),
      );

      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('重试'), findsNothing);
    });
  });

  group('NetworkErrorWidget Tests', () {
    testWidgets('displays network error message', (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkErrorWidget(
              onRetry: () => retryCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('网络连接失败\n请检查网络设置后重试'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('重新加载'), findsOneWidget);

      await tester.tap(find.text('重新加载'));
      await tester.pump();

      expect(retryCalled, isTrue);
    });
  });

  group('ServerErrorWidget Tests', () {
    testWidgets('displays server error message', (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServerErrorWidget(
              onRetry: () => retryCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('服务器错误\n请稍后再试'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);

      await tester.tap(find.text('重试'));
      await tester.pump();

      expect(retryCalled, isTrue);
    });
  });

  group('TimeoutErrorWidget Tests', () {
    testWidgets('displays timeout error message', (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeoutErrorWidget(
              onRetry: () => retryCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('请求超时\n请检查网络连接'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);

      await tester.tap(find.text('重试'));
      await tester.pump();

      expect(retryCalled, isTrue);
    });
  });

  group('InlineErrorWidget Tests', () {
    testWidgets('displays inline error with retry button', (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineErrorWidget(
              onRetry: () => retryCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      await tester.tap(find.text('重试'));
      await tester.pump();

      expect(retryCalled, isTrue);
    });

    testWidgets('displays custom message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineErrorWidget(
              onRetry: () {},
              message: 'Failed to load item',
            ),
          ),
        ),
      );

      expect(find.text('Failed to load item'), findsOneWidget);
    });
  });

  group('ErrorStateManager Tests', () {
    testWidgets('returns NetworkErrorWidget for network errors',
        (tester) async {
      final widget = ErrorStateManager.buildErrorWidget(
        error: 'Network connection failed',
        onRetry: () {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: widget),
        ),
      );

      expect(find.byType(NetworkErrorWidget), findsOneWidget);
    });

    testWidgets('returns TimeoutErrorWidget for timeout errors',
        (tester) async {
      final widget = ErrorStateManager.buildErrorWidget(
        error: 'Request timeout',
        onRetry: () {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: widget),
        ),
      );

      expect(find.byType(TimeoutErrorWidget), findsOneWidget);
    });

    testWidgets('returns ServerErrorWidget for server errors', (tester) async {
      final widget = ErrorStateManager.buildErrorWidget(
        error: 'Server error 500',
        onRetry: () {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: widget),
        ),
      );

      expect(find.byType(ServerErrorWidget), findsOneWidget);
    });

    testWidgets('returns generic ErrorRetryWidget for unknown errors',
        (tester) async {
      final widget = ErrorStateManager.buildErrorWidget(
        error: 'Unknown error',
        onRetry: () {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: widget),
        ),
      );

      expect(find.byType(ErrorRetryWidget), findsOneWidget);
      expect(find.text('出错了\nUnknown error'), findsOneWidget);
    });
  });
}
