import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/bible_constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../domain/entities/verse.dart';
import '../../providers/bible_providers.dart';
import '../../widgets/app_drawer.dart';
import 'widgets/chapter_selector.dart';
import 'widgets/verse_study_sheet.dart';
import 'widgets/verse_tile.dart';

class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readerState = ref.watch(readerStateProvider);
    final book = kBibleBooks.firstWhere((b) => b.id == readerState.bookId);
    final translationsAsync = ref.watch(translationsProvider);
    final versesAsync = ref.watch(
      chapterVersesProvider(
        translationId: readerState.translationId,
        bookId: readerState.bookId,
        chapter: readerState.chapter,
      ),
    );

    final currentTranslationAbbr = translationsAsync.when(
      data: (translations) {
        final match = translations.where(
          (t) => t.id == readerState.translationId,
        );
        return match.isNotEmpty ? match.first.abbreviation : '—';
      },
      loading: () => '...',
      error: (_, __) => '?',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${book.namePt} ${readerState.chapter}'),
        actions: [
          InkWell(
            onTap: () => _showTranslationPicker(context, ref),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentTranslationAbbr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.book_rounded),
            tooltip: 'Selecionar livro',
            onPressed: () => _showBookPicker(context, ref),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          ChapterSelector(
            chapterCount: book.chapterCount,
            currentChapter: readerState.chapter,
            onChapterSelected: (chapter) =>
                ref.read(readerStateProvider.notifier).navigateTo(chapter: chapter),
          ),
          const Divider(height: 1),
          Expanded(
            child: versesAsync.when(
              data: (verses) {
                if (verses.isEmpty) {
                  return const Center(
                    child: Text('Nenhum versículo encontrado para esta tradução.'),
                  );
                }
                return ListView.builder(
                  itemCount: verses.length,
                  itemBuilder: (context, index) {
                    final verse = verses[index];
                    return VerseTile(
                      verse: verse,
                      onTap: () => _showVerseStudySheet(
                        context,
                        ref,
                        verse: verse,
                        bookName: book.namePt,
                        translationAbbr: currentTranslationAbbr,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Erro ao carregar versículos: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTranslationPicker(BuildContext context, WidgetRef ref) {
    final currentId = ref.read(readerStateProvider).translationId;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final translationsAsync = ref.watch(translationsProvider);
          return translationsAsync.when(
            data: (translations) => ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Selecionar Tradução',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ...translations.map(
                  (t) => ListTile(
                    title: Text(t.name),
                    subtitle: Text(t.abbreviation),
                    trailing: t.id == currentId
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () {
                      ref
                          .read(readerStateProvider.notifier)
                          .navigateTo(translationId: t.id);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SizedBox(
              height: 80,
              child: Center(child: Text('Erro: $e')),
            ),
          );
        },
      ),
    );
  }

  void _showBookPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Selecionar Livro',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: kBibleBooks.length,
                itemBuilder: (ctx2, index) {
                  final book = kBibleBooks[index];
                  return ListTile(
                    leading: Text(
                      '${book.bookOrder}',
                      style: Theme.of(ctx2).textTheme.bodySmall,
                    ),
                    title: Text(book.namePt),
                    subtitle: Text(book.testament.labelPt),
                    onTap: () {
                      ref
                          .read(readerStateProvider.notifier)
                          .navigateTo(bookId: book.id, chapter: 1);
                      Navigator.of(ctx2).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVerseStudySheet(
    BuildContext context,
    WidgetRef ref, {
    required Verse verse,
    required String bookName,
    required String translationAbbr,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => VerseStudySheet(
        verse: verse,
        bookName: bookName,
        translationAbbr: translationAbbr,
      ),
    );
  }
}
