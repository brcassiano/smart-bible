import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'strongs_database.g.dart';

// ---------------------------------------------------------------------------
// Table definitions (mirror the pre-built strongs.db schema)
// ---------------------------------------------------------------------------

@DataClassName('DbHebrewEntry')
class HebrewLexicon extends Table {
  TextColumn get strongsNumber => text().named('strongs_number')();
  TextColumn get originalWord => text().named('original_word')();
  TextColumn get transliteration => text()();
  TextColumn get pronunciation => text()();
  TextColumn get shortDefinition => text().named('short_definition')();
  TextColumn get fullDefinition => text().named('full_definition')();
  TextColumn get partOfSpeech => text().named('part_of_speech')();

  @override
  Set<Column> get primaryKey => {strongsNumber};
}

@DataClassName('DbGreekEntry')
class GreekLexicon extends Table {
  TextColumn get strongsNumber => text().named('strongs_number')();
  TextColumn get originalWord => text().named('original_word')();
  TextColumn get transliteration => text()();
  TextColumn get pronunciation => text()();
  TextColumn get shortDefinition => text().named('short_definition')();
  TextColumn get fullDefinition => text().named('full_definition')();
  TextColumn get partOfSpeech => text().named('part_of_speech')();

  @override
  Set<Column> get primaryKey => {strongsNumber};
}

@DataClassName('DbCrossReference')
class CrossReferences extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fromBook => integer().named('from_book')();
  IntColumn get fromChapter => integer().named('from_chapter')();
  IntColumn get fromVerse => integer().named('from_verse')();
  IntColumn get toBook => integer().named('to_book')();
  IntColumn get toChapter => integer().named('to_chapter')();
  IntColumn get toVerse => integer().named('to_verse')();
  IntColumn get votes => integer().withDefault(const Constant(0))();
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [HebrewLexicon, GreekLexicon, CrossReferences])
class StrongsDatabase extends _$StrongsDatabase {
  StrongsDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {},
        onUpgrade: (m, from, to) async {},
      );

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  Future<DbHebrewEntry?> getHebrewEntry(String strongsNumber) =>
      (select(hebrewLexicon)
            ..where((h) => h.strongsNumber.equals(strongsNumber)))
          .getSingleOrNull();

  Future<DbGreekEntry?> getGreekEntry(String strongsNumber) =>
      (select(greekLexicon)
            ..where((g) => g.strongsNumber.equals(strongsNumber)))
          .getSingleOrNull();

  Future<List<({String strongsNumber, String originalWord, String transliteration, String shortDefinition, String language})>> searchLexicon(String query) async {
    final pattern = '%$query%';

    final hebrewRows = await (select(hebrewLexicon)
          ..where(
            (h) =>
                h.shortDefinition.like(pattern) |
                h.transliteration.like(pattern),
          )
          ..limit(20))
        .get();

    final greekRows = await (select(greekLexicon)
          ..where(
            (g) =>
                g.shortDefinition.like(pattern) |
                g.transliteration.like(pattern),
          )
          ..limit(20))
        .get();

    final combined = <({String strongsNumber, String originalWord, String transliteration, String shortDefinition, String language})>[];

    for (final r in hebrewRows) {
      combined.add((
        strongsNumber: r.strongsNumber,
        originalWord: r.originalWord,
        transliteration: r.transliteration,
        shortDefinition: r.shortDefinition,
        language: 'hebrew',
      ));
    }

    for (final r in greekRows) {
      combined.add((
        strongsNumber: r.strongsNumber,
        originalWord: r.originalWord,
        transliteration: r.transliteration,
        shortDefinition: r.shortDefinition,
        language: 'greek',
      ));
    }

    return combined.take(20).toList();
  }

  Future<List<DbCrossReference>> getCrossReferences({
    required int fromBook,
    required int fromChapter,
    required int fromVerse,
  }) =>
      (select(crossReferences)
            ..where((c) =>
                c.fromBook.equals(fromBook) &
                c.fromChapter.equals(fromChapter) &
                c.fromVerse.equals(fromVerse))
            ..orderBy([(c) => OrderingTerm.desc(c.votes)]))
          .get();
}

// ---------------------------------------------------------------------------
// Database file helper
// ---------------------------------------------------------------------------

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'strongs.db'));

    if (!file.existsSync()) {
      final blob = await rootBundle.load('assets/databases/strongs.db');
      final buffer = blob.buffer;
      await file.writeAsBytes(
        buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes),
      );
    }

    return NativeDatabase.createInBackground(file);
  });
}
