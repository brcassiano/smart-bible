import '../../domain/entities/book.dart' as domain;
import '../../domain/entities/translation.dart' as domain;
import '../../domain/entities/verse.dart' as domain;
import '../../domain/repositories/bible_repository.dart';
import '../datasources/bible_database.dart';

class BibleRepositoryImpl implements BibleRepository {
  const BibleRepositoryImpl(this._db);

  final BibleDatabase _db;

  @override
  Future<List<domain.Translation>> getTranslations() async {
    final rows = await _db.allTranslations();
    return rows
        .map(
          (r) => domain.Translation(
            id: r.id,
            abbreviation: r.abbreviation,
            name: r.name,
            language: r.language,
            description: r.description,
          ),
        )
        .toList();
  }

  @override
  Future<List<domain.Book>> getBooks() async {
    final rows = await _db.allBooks();
    return rows
        .map(
          (r) => domain.Book(
            id: r.id,
            name: r.name,
            namePt: r.namePt,
            testament: r.testament,
            bookOrder: r.bookOrder,
            originalLanguage: r.originalLanguage,
          ),
        )
        .toList();
  }

  @override
  Future<List<domain.Verse>> getVerses({
    required int translationId,
    required int bookId,
    required int chapter,
  }) async {
    final rows = await _db.versesForChapter(
      translationId: translationId,
      bookId: bookId,
      chapter: chapter,
    );
    return rows
        .map(
          (r) => domain.Verse(
            translationId: r.translationId,
            bookId: r.bookId,
            chapter: r.chapter,
            verse: r.verse,
            text: r.verseText,
          ),
        )
        .toList();
  }

  @override
  Future<List<domain.Verse>> searchVerses({
    required String query,
    int? translationId,
  }) async {
    final rows = await _db.searchVerses(
      query: query,
      translationId: translationId,
    );
    return rows
        .map(
          (r) => domain.Verse(
            translationId: r.translationId,
            bookId: r.bookId,
            chapter: r.chapter,
            verse: r.verse,
            text: r.verseText,
          ),
        )
        .toList();
  }
}
