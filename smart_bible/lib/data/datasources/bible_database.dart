import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'bible_database.g.dart';

// ---------------------------------------------------------------------------
// Table definitions (mirror the pre-built bible.db schema)
// ---------------------------------------------------------------------------

@DataClassName('DbTranslation')
class Translations extends Table {
  IntColumn get id => integer()();
  TextColumn get abbreviation => text()();
  TextColumn get name => text()();
  TextColumn get language => text()();
  TextColumn get description => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DbBook')
class Books extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get namePt => text().named('name_pt')();
  TextColumn get testament => text()();
  IntColumn get bookOrder => integer().named('book_order')();
  TextColumn get originalLanguage => text().named('original_language')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DbVerse')
class Verses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get translationId => integer().named('translation_id')();
  IntColumn get bookId => integer().named('book_id')();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();
  TextColumn get verseText => text().named('text')();
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [Translations, Books, Verses])
class BibleDatabase extends _$BibleDatabase {
  BibleDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // No migrations — database is pre-built and shipped as an asset.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {},
        onUpgrade: (m, from, to) async {},
      );

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  Future<List<DbTranslation>> allTranslations() =>
      select(translations).get();

  Future<List<DbBook>> allBooks() =>
      (select(books)..orderBy([(b) => OrderingTerm.asc(b.bookOrder)])).get();

  Future<List<DbVerse>> versesForChapter({
    required int translationId,
    required int bookId,
    required int chapter,
  }) =>
      (select(verses)
            ..where((v) =>
                v.translationId.equals(translationId) &
                v.bookId.equals(bookId) &
                v.chapter.equals(chapter))
            ..orderBy([(v) => OrderingTerm.asc(v.verse)]))
          .get();

  Future<List<DbVerse>> searchVerses({
    required String query,
    int? translationId,
  }) {
    final stmt = select(verses)
      ..where((v) {
        final textMatch = v.verseText.like('%$query%');
        if (translationId != null) {
          return textMatch & v.translationId.equals(translationId);
        }
        return textMatch;
      });
    return stmt.get();
  }
}

// ---------------------------------------------------------------------------
// Database file helper — copies asset to app documents on first launch
// ---------------------------------------------------------------------------

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'bible.db'));

    if (!file.existsSync()) {
      final blob = await rootBundle.load('assets/databases/bible.db');
      final buffer = blob.buffer;
      await file.writeAsBytes(
        buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes),
      );
    }

    return NativeDatabase.createInBackground(file);
  });
}
