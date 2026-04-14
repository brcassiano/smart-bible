import '../entities/verse.dart';
import '../repositories/bible_repository.dart';

class SearchBible {
  const SearchBible(this._repository);

  final BibleRepository _repository;

  Future<List<Verse>> call({
    required String query,
    int? translationId,
  }) {
    return _repository.searchVerses(
      query: query,
      translationId: translationId,
    );
  }
}
