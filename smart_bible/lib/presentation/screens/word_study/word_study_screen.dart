import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/strongs_providers.dart';
import '../../widgets/app_drawer.dart';
import '../../../domain/entities/strongs_entry.dart';

// ---------------------------------------------------------------------------
// Popular words to show when search is empty
// ---------------------------------------------------------------------------

class _PopularWord {
  const _PopularWord({
    required this.strongsNumber,
    required this.transliteration,
    required this.portugueseMeaning,
  });

  final String strongsNumber;
  final String transliteration;
  final String portugueseMeaning;
}

const _popularWords = [
  _PopularWord(strongsNumber: 'H430', transliteration: 'Elohim', portugueseMeaning: 'Deus'),
  _PopularWord(strongsNumber: 'H3068', transliteration: 'YHWH', portugueseMeaning: 'Senhor'),
  _PopularWord(strongsNumber: 'H157', transliteration: 'Ahab', portugueseMeaning: 'Amor'),
  _PopularWord(strongsNumber: 'H7965', transliteration: 'Shalom', portugueseMeaning: 'Paz'),
  _PopularWord(strongsNumber: 'H2617', transliteration: 'Chesed', portugueseMeaning: 'Misericórdia'),
  _PopularWord(strongsNumber: 'G26', transliteration: 'Agape', portugueseMeaning: 'Amor'),
  _PopularWord(strongsNumber: 'G5485', transliteration: 'Charis', portugueseMeaning: 'Graça'),
  _PopularWord(strongsNumber: 'G4102', transliteration: 'Pistis', portugueseMeaning: 'Fé'),
  _PopularWord(strongsNumber: 'G3056', transliteration: 'Logos', portugueseMeaning: 'Palavra'),
  _PopularWord(strongsNumber: 'G1680', transliteration: 'Elpis', portugueseMeaning: 'Esperança'),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class WordStudyScreen extends ConsumerStatefulWidget {
  const WordStudyScreen({super.key});

  @override
  ConsumerState<WordStudyScreen> createState() => _WordStudyScreenState();
}

class _WordStudyScreenState extends ConsumerState<WordStudyScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  // The Strong's number to show full detail for (null = none selected)
  String? _selectedNumber;
  bool _selectedIsHebrew = true;

  // The live search text (after debounce)
  String _searchQuery = '';

  // Whether the current query looks like a Strong's number (H/G + digits)
  bool get _isStrongsNumberQuery =>
      RegExp(r'^[HhGg]\d+$').hasMatch(_searchQuery);

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = value.trim();
        // Clear detail when user starts a new search
        _selectedNumber = null;
      });
    });
  }

  void _selectEntry(String strongsNumber) {
    final isHebrew = strongsNumber.toUpperCase().startsWith('H');
    setState(() {
      _selectedNumber = strongsNumber.toUpperCase();
      _selectedIsHebrew = isHebrew;
    });
  }

  void _onChipTapped(_PopularWord word) {
    _controller.text = word.strongsNumber;
    _selectEntry(word.strongsNumber);
    setState(() => _searchQuery = word.strongsNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estudo de Palavras')),
      drawer: const AppDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildExplanatoryCard(context),
          _buildSearchField(context),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildExplanatoryCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'A Concordância de Strong associa cada palavra da Bíblia ao seu termo '
          'original em hebraico (Antigo Testamento) ou grego (Novo Testamento). '
          'Explore as sugestões abaixo ou busque por número ou palavra.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Buscar por número (H430) ou palavra (amor, graça...)',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _searchQuery = '';
                      _selectedNumber = null;
                    });
                  },
                )
              : null,
        ),
        textInputAction: TextInputAction.search,
        onChanged: _onSearchChanged,
        onSubmitted: (v) {
          final q = v.trim();
          if (q.isNotEmpty) {
            setState(() => _searchQuery = q);
            if (RegExp(r'^[HhGg]\d+$').hasMatch(q)) {
              _selectEntry(q);
            }
          }
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    // If a detail is selected, show detail view
    if (_selectedNumber != null) {
      return _buildDetailView(context, _selectedNumber!, _selectedIsHebrew);
    }

    // If search query looks like a Strong's number, auto-select it
    if (_isStrongsNumberQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _selectEntry(_searchQuery);
      });
      return const Center(child: CircularProgressIndicator());
    }

    // If search query is non-empty text, show word search results
    if (_searchQuery.isNotEmpty) {
      return _buildWordSearchResults(context, _searchQuery);
    }

    // Default: show popular words
    return _buildPopularWords(context);
  }

  Widget _buildPopularWords(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Palavras Populares', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularWords.map((w) {
              return ActionChip(
                label: Text('${w.transliteration} (${w.portugueseMeaning})'),
                avatar: Text(
                  w.strongsNumber,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => _onChipTapped(w),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWordSearchResults(BuildContext context, String query) {
    final theme = Theme.of(context);
    final resultsAsync = ref.watch(wordSearchProvider(query));

    return resultsAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Text(
              'Nenhum resultado para "$query"',
              style: theme.textTheme.bodyLarge,
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final entry = entries[i];
            return _SearchResultTile(
              entry: entry,
              onTap: () => _selectEntry(entry.strongsNumber),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
    );
  }

  Widget _buildDetailView(
      BuildContext context, String strongsNumber, bool isHebrew) {
    final theme = Theme.of(context);
    final entryAsync = isHebrew
        ? ref.watch(hebrewEntryProvider(strongsNumber))
        : ref.watch(greekEntryProvider(strongsNumber));

    return entryAsync.when(
      data: (entry) {
        if (entry == null) {
          return Center(
            child: Text(
              'Nenhum resultado para "$strongsNumber"',
              style: theme.textTheme.bodyLarge,
            ),
          );
        }
        return _StrongsDetailCard(entry: entry);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
    );
  }
}

// ---------------------------------------------------------------------------
// Search result tile
// ---------------------------------------------------------------------------

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.entry, required this.onTap});

  final StrongsEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          entry.strongsNumber,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        '${entry.originalWord}  ${entry.transliteration}',
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        entry.shortDefinition,
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// Full detail card
// ---------------------------------------------------------------------------

class _StrongsDetailCard extends StatelessWidget {
  const _StrongsDetailCard({required this.entry});

  final StrongsEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    entry.originalWord,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    entry.strongsNumber,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${entry.transliteration} (${entry.pronunciation})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (entry.partOfSpeech.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  entry.partOfSpeech,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const Divider(height: 24),
              Text('Definição breve', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(entry.shortDefinition, style: theme.textTheme.bodyMedium),
              if (entry.fullDefinition.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Definição completa', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(entry.fullDefinition, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
