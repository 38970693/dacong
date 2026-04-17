import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dacong_client/data/datasources/local_data_source.dart';

void main() {
  late LocalDataSource localDataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    localDataSource = LocalDataSource(prefs);
  });

  group('LocalDataSource - Search History', () {
    test('should return empty list when no search history', () async {
      // act
      final result = await localDataSource.getSearchHistory();

      // assert
      expect(result, isEmpty);
    });

    test('should save search history', () async {
      // act
      await localDataSource.saveSearchHistory('Claude');
      await localDataSource.saveSearchHistory('Cursor');
      final result = await localDataSource.getSearchHistory();

      // assert
      expect(result, ['Cursor', 'Claude']);
    });

    test('should remove duplicate search history', () async {
      // arrange
      await localDataSource.saveSearchHistory('Claude');
      await localDataSource.saveSearchHistory('Cursor');

      // act
      await localDataSource.saveSearchHistory('Claude');
      final result = await localDataSource.getSearchHistory();

      // assert
      expect(result, ['Claude', 'Cursor']);
    });

    test('should limit search history to 10 items', () async {
      // act
      for (int i = 0; i < 15; i++) {
        await localDataSource.saveSearchHistory('Query $i');
      }
      final result = await localDataSource.getSearchHistory();

      // assert
      expect(result.length, 10);
      expect(result.first, 'Query 14'); // 最新的在前面
    });

    test('should delete search history item', () async {
      // arrange
      await localDataSource.saveSearchHistory('Claude');
      await localDataSource.saveSearchHistory('Cursor');

      // act
      await localDataSource.deleteSearchHistoryItem('Claude');
      final result = await localDataSource.getSearchHistory();

      // assert
      expect(result, ['Cursor']);
    });

    test('should clear all search history', () async {
      // arrange
      await localDataSource.saveSearchHistory('Claude');
      await localDataSource.saveSearchHistory('Cursor');

      // act
      await localDataSource.clearSearchHistory();
      final result = await localDataSource.getSearchHistory();

      // assert
      expect(result, isEmpty);
    });
  });

  group('LocalDataSource - Favorites', () {
    test('should return empty list when no favorites', () async {
      // act
      final result = await localDataSource.getFavoriteContentIds();

      // assert
      expect(result, isEmpty);
    });

    test('should add favorite', () async {
      // act
      await localDataSource.addFavorite('content-1');
      await localDataSource.addFavorite('content-2');
      final result = await localDataSource.getFavoriteContentIds();

      // assert
      expect(result, ['content-1', 'content-2']);
    });

    test('should not add duplicate favorite', () async {
      // act
      await localDataSource.addFavorite('content-1');
      await localDataSource.addFavorite('content-1');
      final result = await localDataSource.getFavoriteContentIds();

      // assert
      expect(result, ['content-1']);
    });

    test('should remove favorite', () async {
      // arrange
      await localDataSource.addFavorite('content-1');
      await localDataSource.addFavorite('content-2');

      // act
      await localDataSource.removeFavorite('content-1');
      final result = await localDataSource.getFavoriteContentIds();

      // assert
      expect(result, ['content-2']);
    });

    test('should check if content is favorite', () async {
      // arrange
      await localDataSource.addFavorite('content-1');

      // act
      final isFavorite1 = await localDataSource.isFavorite('content-1');
      final isFavorite2 = await localDataSource.isFavorite('content-2');

      // assert
      expect(isFavorite1, true);
      expect(isFavorite2, false);
    });

    test('should clear all favorites', () async {
      // arrange
      await localDataSource.addFavorite('content-1');
      await localDataSource.addFavorite('content-2');

      // act
      await localDataSource.clearFavorites();
      final result = await localDataSource.getFavoriteContentIds();

      // assert
      expect(result, isEmpty);
    });
  });

  group('LocalDataSource - Popular Searches', () {
    test('should return popular searches', () {
      // act
      final result = localDataSource.getPopularSearches();

      // assert
      expect(result, isNotEmpty);
      expect(result, contains('Claude'));
      expect(result, contains('ChatGPT'));
    });
  });
}
