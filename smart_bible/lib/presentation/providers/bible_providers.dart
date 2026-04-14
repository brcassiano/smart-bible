import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/bible_database.dart';
import '../../data/repositories/bible_repository_impl.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/translation.dart';
import '../../domain/entities/verse.dart';
import '../../domain/repositories/bible_repository.dart';
import '../../domain/usecases/get_verses.dart';
import '../../domain/usecases/search_bible.dart';

part 'bible_providers.g.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
BibleDatabase bibleDatabase(Ref ref) => BibleDatabase();

@Riverpod(keepAlive: true)
BibleRepository bibleRepository(Ref ref) =>
    BibleRepositoryImpl(ref.watch(bibleDatabaseProvider));

// ---------------------------------------------------------------------------
// Use case providers
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
GetVerses getVerses(Ref ref) =>
    GetVerses(ref.watch(bibleRepositoryProvider));

@Riverpod(keepAlive: true)
SearchBible searchBible(Ref ref) =>
    SearchBible(ref.watch(bibleRepositoryProvider));

// ---------------------------------------------------------------------------
// Data providers
// ---------------------------------------------------------------------------

@riverpod
Future<List<Translation>> translations(Ref ref) =>
    ref.watch(bibleRepositoryProvider).getTranslations();

@riverpod
Future<List<Book>> books(Ref ref) =>
    ref.watch(bibleRepositoryProvider).getBooks();

@riverpod
Future<List<Verse>> chapterVerses(
  Ref ref, {
  required int translationId,
  required int bookId,
  required int chapter,
}) =>
    ref.watch(getVersesProvider).call(
          translationId: translationId,
          bookId: bookId,
          chapter: chapter,
        );

@riverpod
Future<List<Verse>> searchResults(
  Ref ref, {
  required String query,
  int? translationId,
}) =>
    ref.watch(searchBibleProvider).call(
          query: query,
          translationId: translationId,
        );

// ---------------------------------------------------------------------------
// Reader state
// ---------------------------------------------------------------------------

@riverpod
class ReaderState extends _$ReaderState {
  @override
  ({int translationId, int bookId, int chapter}) build() => (
        translationId: 2, // 2 = ARA
        bookId: 43,
        chapter: 3,
      );

  void navigateTo({
    int? translationId,
    int? bookId,
    int? chapter,
  }) {
    state = (
      translationId: translationId ?? state.translationId,
      bookId: bookId ?? state.bookId,
      chapter: chapter ?? state.chapter,
    );
  }
}
