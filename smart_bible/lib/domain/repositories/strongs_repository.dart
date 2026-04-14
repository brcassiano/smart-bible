import '../entities/cross_reference.dart';
import '../entities/strongs_entry.dart';

abstract interface class StrongsRepository {
  Future<StrongsEntry?> getHebrewEntry(String strongsNumber);

  Future<StrongsEntry?> getGreekEntry(String strongsNumber);

  Future<List<CrossReference>> getCrossReferences({
    required int bookId,
    required int chapter,
    required int verse,
  });

  Future<List<StrongsEntry>> searchByWord(String query);
}
