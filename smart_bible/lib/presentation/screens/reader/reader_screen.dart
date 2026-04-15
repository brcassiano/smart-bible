import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/bible_constants.dart';
import '../../../domain/entities/verse.dart';
import '../../providers/bible_providers.dart';
import '../../widgets/app_drawer.dart';
import 'widgets/chapter_selector.dart';
import 'widgets/verse_study_sheet.dart';
import 'widgets/verse_tile.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(readerStateProvider, (prev, next) {
      if (prev?.chapter != next.chapter || prev?.bookId != next.bookId) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      }
    });

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
        title: GestureDetector(
          onTap: () => _showBookPicker(context, ref),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${book.namePt} ${readerState.chapter}'),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
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
                  controller: _scrollController,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => _BookPickerContent(
          currentBookId: ref.read(readerStateProvider).bookId,
          onBookSelected: (bookId) {
            ref.read(readerStateProvider.notifier).navigateTo(bookId: bookId, chapter: 1);
            Navigator.pop(context);
          },
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

class _BookPickerContent extends StatefulWidget {
  const _BookPickerContent({
    required this.currentBookId,
    required this.onBookSelected,
  });

  final int currentBookId;
  final ValueChanged<int> onBookSelected;

  @override
  State<_BookPickerContent> createState() => _BookPickerContentState();
}

class _BookPickerContentState extends State<_BookPickerContent> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otBooks = kBibleBooks.where((b) => b.testament == Testament.ot).toList();
    final ntBooks = kBibleBooks.where((b) => b.testament == Testament.nt).toList();

    final filteredOt = _searchQuery.isEmpty
        ? otBooks
        : otBooks
            .where((b) => b.namePt.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
    final filteredNt = _searchQuery.isEmpty
        ? ntBooks
        : ntBooks
            .where((b) => b.namePt.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar livro...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildColumn('Antigo Testamento', filteredOt)),
              const VerticalDivider(width: 1),
              Expanded(child: _buildColumn('Novo Testamento', filteredNt)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(String title, List<BibleBook> books) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              final isSelected = book.id == widget.currentBookId;
              return ListTile(
                dense: true,
                title: Text(
                  book.namePt,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () => widget.onBookSelected(book.id),
              );
            },
          ),
        ),
      ],
    );
  }
}
