import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/strongs_database.dart';
import '../../data/repositories/strongs_repository_impl.dart';
import '../../domain/entities/cross_reference.dart';
import '../../domain/entities/strongs_entry.dart';
import '../../domain/repositories/strongs_repository.dart';
import '../../domain/usecases/get_strongs_entry.dart';

part 'strongs_providers.g.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
StrongsDatabase strongsDatabase(Ref ref) => StrongsDatabase();

@Riverpod(keepAlive: true)
StrongsRepository strongsRepository(Ref ref) =>
    StrongsRepositoryImpl(ref.watch(strongsDatabaseProvider));

// ---------------------------------------------------------------------------
// Use case providers
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
GetStrongsEntry getStrongsEntry(Ref ref) =>
    GetStrongsEntry(ref.watch(strongsRepositoryProvider));

// ---------------------------------------------------------------------------
// Data providers
// ---------------------------------------------------------------------------

@riverpod
Future<StrongsEntry?> hebrewEntry(Ref ref, String strongsNumber) =>
    ref.watch(strongsRepositoryProvider).getHebrewEntry(strongsNumber);

@riverpod
Future<StrongsEntry?> greekEntry(Ref ref, String strongsNumber) =>
    ref.watch(strongsRepositoryProvider).getGreekEntry(strongsNumber);

@riverpod
Future<List<StrongsEntry>> wordSearch(Ref ref, String query) =>
    ref.watch(strongsRepositoryProvider).searchByWord(query);

@riverpod
Future<List<CrossReference>> crossReferences(
  Ref ref, {
  required int bookId,
  required int chapter,
  required int verse,
}) =>
    ref.watch(strongsRepositoryProvider).getCrossReferences(
          bookId: bookId,
          chapter: chapter,
          verse: verse,
        );
