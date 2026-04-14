import '../entities/book.dart';
import '../entities/translation.dart';
import '../entities/verse.dart';

abstract interface class BibleRepository {
  Future<List<Translation>> getTranslations();

  Future<List<Book>> getBooks();

  Future<List<Verse>> getVerses({
    required int translationId,
    required int bookId,
    required int chapter,
  });

  Future<List<Verse>> searchVerses({
    required String query,
    int? translationId,
  });
}
