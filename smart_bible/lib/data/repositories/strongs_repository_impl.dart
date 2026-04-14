import '../../domain/entities/cross_reference.dart' as domain;
import '../../domain/entities/strongs_entry.dart';
import '../../domain/repositories/strongs_repository.dart';
import '../datasources/strongs_database.dart';

class StrongsRepositoryImpl implements StrongsRepository {
  const StrongsRepositoryImpl(this._db);

  final StrongsDatabase _db;

  @override
  Future<StrongsEntry?> getHebrewEntry(String strongsNumber) async {
    final row = await _db.getHebrewEntry(strongsNumber);
    if (row == null) return null;
    return StrongsEntry(
      strongsNumber: row.strongsNumber,
      originalWord: row.originalWord,
      transliteration: row.transliteration,
      pronunciation: row.pronunciation,
      shortDefinition: row.shortDefinition,
      fullDefinition: row.fullDefinition,
      partOfSpeech: row.partOfSpeech,
    );
  }

  @override
  Future<StrongsEntry?> getGreekEntry(String strongsNumber) async {
    final row = await _db.getGreekEntry(strongsNumber);
    if (row == null) return null;
    return StrongsEntry(
      strongsNumber: row.strongsNumber,
      originalWord: row.originalWord,
      transliteration: row.transliteration,
      pronunciation: row.pronunciation,
      shortDefinition: row.shortDefinition,
      fullDefinition: row.fullDefinition,
      partOfSpeech: row.partOfSpeech,
    );
  }

  @override
  Future<List<StrongsEntry>> searchByWord(String query) async {
    final rows = await _db.searchLexicon(query);
    return rows
        .map(
          (r) => StrongsEntry(
            strongsNumber: r.strongsNumber,
            originalWord: r.originalWord,
            transliteration: r.transliteration,
            pronunciation: '',
            shortDefinition: r.shortDefinition,
            fullDefinition: '',
            partOfSpeech: '',
          ),
        )
        .toList();
  }

  @override
  Future<List<domain.CrossReference>> getCrossReferences({
    required int bookId,
    required int chapter,
    required int verse,
  }) async {
    final rows = await _db.getCrossReferences(
      fromBook: bookId,
      fromChapter: chapter,
      fromVerse: verse,
    );
    return rows
        .map(
          (r) => domain.CrossReference(
            fromBook: r.fromBook,
            fromChapter: r.fromChapter,
            fromVerse: r.fromVerse,
            toBook: r.toBook,
            toChapter: r.toChapter,
            toVerse: r.toVerse,
            votes: r.votes,
          ),
        )
        .toList();
  }
}
