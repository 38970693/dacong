import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dacong_client/data/services/search_service.dart';

import 'search_service_test.mocks.dart';

@GenerateMocks([SupabaseClient, SupabaseQueryBuilder, PostgrestFilterBuilder])
void main() {
  late SearchService searchService;
  late MockSupabaseClient mockClient;

  setUp(() {
    mockClient = MockSupabaseClient();
    searchService = SearchService(mockClient);
  });

  group('SearchService', () {
    group('getSearchSuggestions', () {
      test('should return all suggestions when no prefix provided', () async {
        final result = await searchService.getSearchSuggestions(limit: 5);

        expect(result.length, 5);
        expect(result, contains('Claude'));
        expect(result, contains('Cursor'));
      });

      test('should filter suggestions by prefix', () async {
        final result = await searchService.getSearchSuggestions(
          prefix: 'C',
          limit: 10,
        );

        expect(result.every((s) => s.toLowerCase().contains('c')), isTrue);
        expect(result, contains('Claude'));
        expect(result, contains('Cursor'));
        expect(result, contains('ChatGPT'));
      });

      test('should return empty list when prefix matches nothing', () async {
        final result = await searchService.getSearchSuggestions(
          prefix: 'XYZ123',
          limit: 10,
        );

        expect(result, isEmpty);
      });

      test('should respect limit parameter', () async {
        final result = await searchService.getSearchSuggestions(limit: 3);

        expect(result.length, 3);
      });

      test('should be case insensitive', () async {
        final result1 = await searchService.getSearchSuggestions(prefix: 'claude');
        final result2 = await searchService.getSearchSuggestions(prefix: 'CLAUDE');

        expect(result1, equals(result2));
      });
    });
  });
}
