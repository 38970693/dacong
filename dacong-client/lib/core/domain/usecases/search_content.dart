import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/content.dart';
import '../repositories/i_content_repository.dart';
import '../../error/failures.dart';

/// 搜索内容用例
@injectable
class SearchContent {
  final IContentRepository _repository;

  SearchContent(this._repository);

  Future<Either<Failure, List<Content>>> call(
    String query, {
    int limit = 20,
    int offset = 0,
    String? scenario,
    bool? isFree,
    bool? availableInChina,
    String sortBy = 'relevance',
  }) async {
    // 验证输入
    if (query.trim().isEmpty) {
      return const Left(ValidationFailure('搜索关键词不能为空'));
    }

    // 验证排序参数
    if (!['relevance', 'rating', 'viewCount'].contains(sortBy)) {
      return const Left(ValidationFailure('无效的排序参数'));
    }

    return await _repository.searchContent(
      query,
      limit: limit,
      offset: offset,
      scenario: scenario,
      isFree: isFree,
      availableInChina: availableInChina,
      sortBy: sortBy,
    );
  }
}
