import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/ai_prompts.dart';
import '../../../../domain/entities/strongs_entry.dart';
import '../../../../domain/entities/verse.dart';
import '../../../providers/ai_providers.dart';
import '../../../providers/strongs_providers.dart';

class VerseStudySheet extends ConsumerStatefulWidget {
  const VerseStudySheet({
    super.key,
    required this.verse,
    required this.bookName,
    required this.translationAbbr,
  });

  final Verse verse;
  final String bookName;
  final String translationAbbr;

  @override
  ConsumerState<VerseStudySheet> createState() => _VerseStudySheetState();
}

class _VerseStudySheetState extends ConsumerState<VerseStudySheet> {
  String? _selectedWord;
  List<StrongsEntry>? _strongsResults;
  bool _loadingStrongs = false;
  String _aiAnalysis = '';
  bool _loadingAi = false;

  List<String> get _words => widget.verse.text.split(' ');

  String _cleanWord(String word) {
    return word
        .replaceAll(RegExp(r'[^\w\s]', unicode: true), '')
        .toLowerCase()
        .trim();
  }

  Future<void> _onWordTap(String word) async {
    final clean = _cleanWord(word);
    if (clean.isEmpty) return;

    setState(() {
      _selectedWord = word;
      _strongsResults = null;
      _loadingStrongs = true;
      _aiAnalysis = '';
      _loadingAi = false;
    });

    final results =
        await ref.read(strongsRepositoryProvider).searchByWord(clean);

    if (!mounted) return;
    setState(() {
      _strongsResults = results;
      _loadingStrongs = false;
    });

    await _triggerAiAnalysis(word, results.isNotEmpty ? results.first : null);
  }

  Future<void> _triggerAiAnalysis(
    String word,
    StrongsEntry? strongs,
  ) async {
    setState(() {
      _loadingAi = true;
      _aiAnalysis = '';
    });

    final reference =
        '${widget.bookName} ${widget.verse.chapter}:${widget.verse.verse}';

    String strongsContext = '';
    if (strongs != null) {
      strongsContext =
          'Dados Strong\'s: ${strongs.strongsNumber} - ${strongs.originalWord} '
          '(${strongs.transliteration}) - ${strongs.shortDefinition}';
    }

    final prompt = kWordAnalysisPrompt
        .replaceAll('{word}', word)
        .replaceAll('{reference}', reference)
        .replaceAll('{verseText}', widget.verse.text)
        .replaceAll('{strongsContext}', strongsContext);

    final aiRepo = ref.read(aiRepositoryProvider);

    if (!aiRepo.isModelLoaded) {
      if (mounted) {
        setState(() {
          _aiAnalysis = 'Modelo de IA não carregado. '
              'Faça o download do modelo na tela de Chat para habilitar a análise.';
          _loadingAi = false;
        });
      }
      return;
    }

    await for (final token in aiRepo.generateResponse(prompt)) {
      if (!mounted) return;
      setState(() {
        _aiAnalysis += token;
      });
    }

    if (mounted) {
      setState(() {
        _loadingAi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reference =
        '${widget.bookName} ${widget.verse.chapter}:${widget.verse.verse}';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$reference — ${widget.translationAbbr}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Word chips
                Text(
                  'Toque em uma palavra para analisar:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _words.map((word) {
                    final isSelected = word == _selectedWord;
                    return GestureDetector(
                      onTap: () => _onWordTap(word),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Text(
                          word,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : null,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Strong's section
                if (_selectedWord != null) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),
                  if (_loadingStrongs)
                    const Center(child: CircularProgressIndicator())
                  else if (_strongsResults != null) ...[
                    if (_strongsResults!.isEmpty)
                      Text(
                        'Nenhum resultado encontrado no léxico para "${_cleanWord(_selectedWord!)}".',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      _StrongsCard(entry: _strongsResults!.first),
                  ],
                  // AI Analysis section
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Análise',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_loadingAi && _aiAnalysis.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (_aiAnalysis.isNotEmpty)
                    Text(
                      _aiAnalysis,
                      style: theme.textTheme.bodyMedium,
                    )
                  else if (!_loadingAi && !_loadingStrongs)
                    Text(
                      'Aguardando análise...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Em breve: chat integrado'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Perguntar mais'),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StrongsCard extends StatelessWidget {
  const _StrongsCard({required this.entry});

  final StrongsEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                entry.originalWord,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${entry.transliteration})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${entry.strongsNumber} — ${entry.shortDefinition}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (entry.partOfSpeech.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.partOfSpeech,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
