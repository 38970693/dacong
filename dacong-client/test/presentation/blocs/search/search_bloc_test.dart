import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:dacong_client/presentation/blocs/search/search_bloc.dart';
import 'package:dacong_client/core/domain/usecases/search_content.dart';
import 'package:dacong_client/core/domain/entities/content.dart';
import 'package:dacong_client/core/error/failures.dart';
import 'package:dacong_client/data/datasources/local_data_source.dart';

@GenerateMocks([SearchContent, LocalDataSource])
import 'search_bloc_test.mocks.dart';

void main() {
  late SearchBloc searchBloc;
  late MockSearchContent mockSearchContent;
  late MockLocalDataSource mockLocalDataSource;

  setUp(() {
    mockSearchContent = MockSearchContent();
    mockLocalDataSource = MockLocalDataSource();
    searchBloc = SearchBloc(mockSearchContent, mockLocalDataSource);
  });

  tearDown(() {
    searchBloc.close();
  });

  group('SearchBloc', () {
    final tQuery = 'Claude';
    final tContent = Content(
      id: '1',
      name: 'Claude Code',
      vendor: 'Anthropic',
      description: 'AI coding assistant',
      officialWebsite: 'https://claude.ai',
      githubUrl: null,
      features: ['Code generation', 'Code review'],
      priceInfo: const PriceInfo(
        isFree: false,
        freeDescription: null,
        paidDescription: '\$20/month',
        tiers: [],
      ),
      accessInfo: const AccessInfo(
        availableInChina: false,
        needsVpn: true,
        difficulty: InstallDifficulty.easy,
        installGuideUrl: null,
      ),
      useCases: ['Coding'],
      helpfulCount: 100,
      unhelpfulCount: 10,
      publishedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('initial state is SearchInitial', () {
      expect(searchBloc.state, isA<SearchInitial>());
    });

    group('SearchQueryChanged', () {
      blocTest<SearchBloc, SearchState>(
        'emits [SearchLoading, SearchLoaded] when search succeeds',
        build: () {
          when(mockLocalDataSource.saveSearchHistory(any))
              .thenAnswer((_) async => Future.value());
          when(mockSearchContent(any, limit: anyNamed('limit'), offset: anyNamed('offset')))
              .thenAnswer((_) async => Right([tContent]));
          return searchBloc;
        },
        act: (bloc) => bloc.add(SearchQueryChanged(tQuery)),
        wait: const Duration(milliseconds: 600), // 等待防抖
        expect: () => [
          isA<SearchLoading>(),
          isA<SearchLoaded>()
              .having((s) => s.results.length, 'results length', 1)
              .having((s) => s.query, 'query', tQuery),
        ],
        verify: (_) {
          verify(mockLocalDataSource.saveSearchHistory(tQuery)).called(1);
          verify(mockSearchContent(tQuery, limit: 20, offset: 0)).called(1);
        },
      );

      blocTest<SearchBloc, SearchState>(
        'emits [SearchLoading, SearchError] when search fails',
        build: () {
          when(mockLocalDataSource.saveSearchHistory(any))
              .thenAnswer((_) async => Future.value());
          when(mockSearchContent(any, limit: anyNamed('limit'), offset: anyNamed('offset')))
              .thenAnswer((_) async => const Left(ServerFailure('搜索失败')));
          return searchBloc;
        },
        act: (bloc) => bloc.add(SearchQueryChanged(tQuery)),
        wait: const Duration(milliseconds: 600),
        expect: () => [
          isA<SearchLoading>(),
          isA<SearchError>().having((s) => s.message, 'message', '搜索失败'),
        ],
      );

      blocTest<SearchBloc, SearchState>(
        'emits [SearchLoading, SearchEmpty] when no results found',
        build: () {
          when(mockLocalDataSource.saveSearchHistory(any))
              .thenAnswer((_) async => Future.value());
          when(mockSearchContent(any, limit: anyNamed('limit'), offset: anyNamed('offset')))
              .thenAnswer((_) async => const Right([]));
          return searchBloc;
        },
        act: (bloc) => bloc.add(SearchQueryChanged(tQuery)),
        wait: const Duration(milliseconds: 600),
        expect: () => [
          isA<SearchLoading>(),
          isA<SearchEmpty>().having((s) => s.query, 'query', tQuery),
        ],
      );

      blocTest<SearchBloc, SearchState>(
        'debounces search queries',
        build: () {
          when(mockLocalDataSource.saveSearchHistory(any))
              .thenAnswer((_) async => Future.value());
          when(mockSearchContent(any, limit: anyNamed('limit'), offset: anyNamed('offset')))
              .thenAnswer((_) async => Right([tContent]));
          return searchBloc;
        },
        act: (bloc) async {
          bloc.add(const SearchQueryChanged('C'));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const SearchQueryChanged('Cl'));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const SearchQueryChanged('Cla'));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(SearchQueryChanged(tQuery));
        },
        wait: const Duration(milliseconds: 600),
        expect: () => [
          isA<SearchLoading>(),
          isA<SearchLoaded>(),
        ],
        verify: (_) {
          // 只应该调用一次（最后一次查询）
          verify(mockSearchContent(tQuery, limit: 20, offset: 0)).called(1);
        },
      );
    });

    group('SearchFilterChanged', () {
      blocTest<SearchBloc, SearchState>(
        'applies filters and searches',
        build: () {
          when(mockLocalDataSource.saveSearchHistory(any))
              .thenAnswer((_) async => Future.value());
          when(mockSearchContent(any, limit: anyNamed('limit'), offset: anyNamed('offset')))
              .thenAnswer((_) async => Right([tContent]));
          return searchBloc;
        },
        seed: () => SearchLoaded(
          results: [tContent],
          query: tQuery,
        ),
        act: (bloc) => bloc.add(const SearchFilterChanged(isFree: true)),
        expect: () => [
          isA<SearchLoading>(),
          isA<SearchLoaded>()
              .having((s) => s.isFree, 'isFree', true),
        ],
      );
    });

    group('SearchSortChanged', () {
      blocTest<SearchBloc, SearchState>(
        'sorts results by rating',
        build: () => searchBloc,
        seed: () => SearchLoaded(
          results: [tContent],
          query: tQuery,
        ),
        act: (bloc) => bloc.add(const SearchSortChanged(SearchSortType.rating)),
        expect: () => [
          isA<SearchLoaded>()
              .having((s) => s.sortType, 'sortType', SearchSortType.rating),
        ],
      );
    });

    group('SearchCleared', () {
      blocTest<SearchBloc, SearchState>(
        'clears search and returns to initial state',
        build: () => searchBloc,
        seed: () => SearchLoaded(
          results: [tContent],
          query: tQuery,
        ),
        act: (bloc) => bloc.add(const SearchCleared()),
        expect: () => [
          isA<SearchInitial>(),
        ],
      );
    });

    group('LoadSearchHistory', () {
      blocTest<SearchBloc, SearchState>(
        'loads search history and popular searches',
        build: () {
          when(mockLocalDataSource.getSearchHistory())
              .thenAnswer((_) async => ['Claude', 'Cursor']);
          when(mockLocalDataSource.getPopularSearches())
              .thenReturn(['ChatGPT', 'Midjourney']);
          return searchBloc;
        },
        act: (bloc) => bloc.add(const LoadSearchHistory()),
        expect: () => [
          isA<SearchInitial>()
              .having((s) => s.searchHistory, 'searchHistory', ['Claude', 'Cursor'])
              .having((s) => s.popularSearches, 'popularSearches', ['ChatGPT', 'Midjourney']),
        ],
      );
    });

    group('DeleteSearchHistoryItem', () {
      blocTest<SearchBloc, SearchState>(
        'deletes search history item',
        build: () {
          when(mockLocalDataSource.deleteSearchHistoryItem(any))
              .thenAnswer((_) async => Future.value());
          when(mockLocalDataSource.getSearchHistory())
              .thenAnswer((_) async => ['Cursor']);
          when(mockLocalDataSource.getPopularSearches())
              .thenReturn(['ChatGPT']);
          return searchBloc;
        },
        act: (bloc) => bloc.add(const DeleteSearchHistoryItem('Claude')),
        expect: () => [
          isA<SearchInitial>()
              .having((s) => s.searchHistory, 'searchHistory', ['Cursor']),
        ],
        verify: (_) {
          verify(mockLocalDataSource.deleteSearchHistoryItem('Claude')).called(1);
        },
      );
    });

    group('ClearSearchHistory', () {
      blocTest<SearchBloc, SearchState>(
        'clears all search history',
        build: () {
          when(mockLocalDataSource.clearSearchHistory())
              .thenAnswer((_) async => Future.value());
          when(mockLocalDataSource.getSearchHistory())
              .thenAnswer((_) async => []);
          when(mockLocalDataSource.getPopularSearches())
              .thenReturn(['ChatGPT']);
          return searchBloc;
        },
        act: (bloc) => bloc.add(const ClearSearchHistory()),
        expect: () => [
          isA<SearchInitial>()
              .having((s) => s.searchHistory, 'searchHistory', []),
        ],
        verify: (_) {
          verify(mockLocalDataSource.clearSearchHistory()).called(1);
        },
      );
    });
  });
}
