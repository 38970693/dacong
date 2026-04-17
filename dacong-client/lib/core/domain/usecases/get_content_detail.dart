import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/content.dart';
import '../repositories/i_content_repository.dart';
import '../../error/failures.dart';

/// 获取内容详情用例
@injectable
class GetContentDetail {
  final IContentRepository _repository;

  GetContentDetail(this._repository);

  Future<Either<Failure, Content>> call(String contentId) async {
    return await _repository.getContentById(contentId);
  }
}
