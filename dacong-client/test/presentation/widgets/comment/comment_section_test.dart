import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dacong_client/domain/entities/comment.dart';
import 'package:dacong_client/presentation/blocs/comment/comment_bloc.dart';
import 'package:dacong_client/presentation/blocs/comment/comment_state.dart';
import 'package:dacong_client/presentation/widgets/comment/comment_section.dart';

class MockCommentBloc extends Mock implements CommentBloc {}

void main() {
  late MockCommentBloc mockCommentBloc;

  setUp(() {
    mockCommentBloc = MockCommentBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<CommentBloc>.value(
          value: mockCommentBloc,
          child: const CommentSection(contentId: 'test-content-id'),
        ),
      ),
    );
  }

  final tComment = Comment(
    id: 'comment-1',
    contentId: 'test-content-id',
    userId: 'user-1',
    content: 'Test comment content',
    likesCount: 5,
    replyCount: 2,
    isLiked: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('CommentSection Widget', () {
    testWidgets('displays loading indicator when state is CommentLoading',
        (WidgetTester tester) async {
      when(() => mockCommentBloc.state).thenReturn(CommentLoading());
      when(() => mockCommentBloc.stream)
          .thenAnswer((_) => Stream.value(CommentLoading()));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when state is CommentError',
        (WidgetTester tester) async {
      const errorMessage = 'Failed to load comments';
      when(() => mockCommentBloc.state)
          .thenReturn(const CommentError(message: errorMessage));
      when(() => mockCommentBloc.stream).thenAnswer(
          (_) => Stream.value(const CommentError(message: errorMessage)));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('displays empty message when no comments',
        (WidgetTester tester) async {
      when(() => mockCommentBloc.state).thenReturn(const CommentLoaded(
        comments: [],
        currentPage: 1,
        hasMore: false,
        sort: 'latest',
      ));
      when(() => mockCommentBloc.stream).thenAnswer((_) =>
          Stream.value(const CommentLoaded(
            comments: [],
            currentPage: 1,
            hasMore: false,
            sort: 'latest',
          )));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(
          find.text('No comments yet. Be the first to comment!'), findsOneWidget);
    });

    testWidgets('displays comment list when state is CommentLoaded',
        (WidgetTester tester) async {
      when(() => mockCommentBloc.state).thenReturn(CommentLoaded(
        comments: [tComment],
        currentPage: 1,
        hasMore: false,
        sort: 'latest',
      ));
      when(() => mockCommentBloc.stream).thenAnswer((_) => Stream.value(
          CommentLoaded(
            comments: [tComment],
            currentPage: 1,
            hasMore: false,
            sort: 'latest',
          )));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text(tComment.content), findsOneWidget);
    });

    testWidgets('displays sort options', (WidgetTester tester) async {
      when(() => mockCommentBloc.state).thenReturn(const CommentLoaded(
        comments: [],
        currentPage: 1,
        hasMore: false,
        sort: 'latest',
      ));
      when(() => mockCommentBloc.stream).thenAnswer((_) =>
          Stream.value(const CommentLoaded(
            comments: [],
            currentPage: 1,
            hasMore: false,
            sort: 'latest',
          )));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Sort by:'), findsOneWidget);
      expect(find.text('Latest'), findsOneWidget);
      expect(find.text('Popular'), findsOneWidget);
    });
  });
}
