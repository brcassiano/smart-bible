import '../entities/verse.dart';
import '../repositories/bible_repository.dart';

class GetVerses {
  const GetVerses(this._repository);

  final BibleRepository _repository;

  Future<List<Verse>> call({
    required int translationId,
    required int bookId,
    required int chapter,
  }) {
    return _repository.getVerses(
      translationId: translationId,
      bookId: bookId,
      chapter: chapter,
    );
  }
}
