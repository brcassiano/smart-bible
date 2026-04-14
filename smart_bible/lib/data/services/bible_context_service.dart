import '../../domain/entities/verse.dart';
import '../datasources/bible_database.dart';
import '../datasources/strongs_database.dart';

/// Result of a context retrieval for a user question.
class BibleContext {
  const BibleContext({
    this.verses = const [],
    this.strongsInfo = const [],
    this.crossReferenceVerses = const [],
  });

  final List<Verse> verses;
  final List<String> strongsInfo;
  final List<Verse> crossReferenceVerses;

  bool get isEmpty =>
      verses.isEmpty && strongsInfo.isEmpty && crossReferenceVerses.isEmpty;

  /// Human-readable labels for the context chips shown in the UI.
  List<String> get chips {
    final chips = <String>[];
    if (verses.isNotEmpty) {
      chips.add('${verses.length} versículo(s)');
    }
    if (strongsInfo.isNotEmpty) {
      chips.add('${strongsInfo.length} Strong(s)');
    }
    if (crossReferenceVerses.isNotEmpty) {
      chips.add('${crossReferenceVerses.length} referência(s)');
    }
    return chips;
  }

  /// Assembles all retrieved data into a single context block for the prompt.
  String toPromptContext() {
    if (isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('=== CONTEXTO BÍBLICO ===');

    if (verses.isNotEmpty) {
      buffer.writeln('\n--- Versículos ---');
      for (final v in verses) {
        buffer.writeln(
          '[${v.translationId}] Livro ${v.bookId} ${v.chapter}:${v.verse} — ${v.text}',
        );
      }
    }

    if (strongsInfo.isNotEmpty) {
      buffer.writeln('\n--- Léxico Strong ---');
      for (final s in strongsInfo) {
        buffer.writeln(s);
      }
    }

    if (crossReferenceVerses.isNotEmpty) {
      buffer.writeln('\n--- Referências Cruzadas ---');
      for (final v in crossReferenceVerses) {
        buffer.writeln(
          '[${v.translationId}] Livro ${v.bookId} ${v.chapter}:${v.verse} — ${v.text}',
        );
      }
    }

    buffer.writeln('\n=== FIM DO CONTEXTO ===');
    return buffer.toString();
  }
}

/// Retrieves Bible, Strong's, and cross-reference data relevant to a question.
class BibleContextService {
  const BibleContextService({
    required BibleDatabase bibleDatabase,
    required StrongsDatabase strongsDatabase,
  })  : _bibleDb = bibleDatabase,
        _strongsDb = strongsDatabase;

  final BibleDatabase _bibleDb;
  final StrongsDatabase _strongsDb;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<BibleContext> retrieveContext(String userQuestion) async {
    final question = userQuestion.toLowerCase();

    final ref = _parseVerseReference(question);
    final strongsNumbers = _extractStrongsNumbers(question);

    final futures = await Future.wait([
      ref != null ? _fetchVerses(ref) : Future.value(<Verse>[]),
      _fetchStrongsInfo(strongsNumbers),
      ref != null
          ? _fetchCrossRefVerses(ref)
          : Future.value(<Verse>[]),
    ]);

    return BibleContext(
      verses: futures[0] as List<Verse>,
      strongsInfo: futures[1] as List<String>,
      crossReferenceVerses: futures[2] as List<Verse>,
    );
  }

  // ---------------------------------------------------------------------------
  // Verse reference parsing
  // ---------------------------------------------------------------------------

  _VerseRef? _parseVerseReference(String text) {
    // Matches patterns like "João 3:16", "gênesis 1", "rm 8:28", "1co 13:4"
    final pattern = RegExp(
      r'(\d?\s?[a-záéíóúàãõâêîôûçüñ]+)\s+(\d+)(?::(\d+))?',
      caseSensitive: false,
      unicode: true,
    );

    final match = pattern.firstMatch(text);
    if (match == null) return null;

    final bookName = match.group(1)!.trim();
    final chapter = int.tryParse(match.group(2) ?? '');
    final verse = int.tryParse(match.group(3) ?? '');

    if (chapter == null) return null;

    final bookId = _resolveBookId(bookName);
    if (bookId == null) return null;

    return _VerseRef(bookId: bookId, chapter: chapter, verse: verse);
  }

  int? _resolveBookId(String name) {
    final n = name.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    return _bookAliases[n];
  }

  Future<List<Verse>> _fetchVerses(_VerseRef ref) async {
    // 1=ACF, 2=ARA, 3=KJV
    const translations = [1, 2, 3];
    final results = <Verse>[];

    for (final tr in translations) {
      if (ref.verse != null) {
        // Single verse — fetch the whole chapter and filter
        final chapter = await _bibleDb.versesForChapter(
          translationId: tr,
          bookId: ref.bookId,
          chapter: ref.chapter,
        );
        final match =
            chapter.where((v) => v.verse == ref.verse).take(1).toList();
        results.addAll(
          match.map(
            (v) => Verse(
              translationId: v.translationId,
              bookId: v.bookId,
              chapter: v.chapter,
              verse: v.verse,
              text: v.verseText,
            ),
          ),
        );
      } else {
        // Whole chapter — limit to first 5 verses to keep context short
        final chapter = await _bibleDb.versesForChapter(
          translationId: tr,
          bookId: ref.bookId,
          chapter: ref.chapter,
        );
        results.addAll(
          chapter.take(5).map(
                (v) => Verse(
                  translationId: v.translationId,
                  bookId: v.bookId,
                  chapter: v.chapter,
                  verse: v.verse,
                  text: v.verseText,
                ),
              ),
        );
      }
    }
    return results;
  }

  // ---------------------------------------------------------------------------
  // Strong's lookup
  // ---------------------------------------------------------------------------

  List<String> _extractStrongsNumbers(String text) {
    final numbers = <String>[];
    final hebrewWords = _hebrewWordAliases.entries
        .where((e) => text.contains(e.key))
        .map((e) => e.value);
    final greekWords = _greekWordAliases.entries
        .where((e) => text.contains(e.key))
        .map((e) => e.value);
    numbers.addAll(hebrewWords);
    numbers.addAll(greekWords);

    // Also match explicit Strong's numbers like H1234 or G5547
    final strongsPattern = RegExp(r'\b[hg]\d{1,4}\b', caseSensitive: false);
    for (final match in strongsPattern.allMatches(text)) {
      numbers.add(match.group(0)!.toUpperCase());
    }
    return numbers.toSet().toList();
  }

  Future<List<String>> _fetchStrongsInfo(List<String> numbers) async {
    final lines = <String>[];
    for (final number in numbers) {
      if (number.startsWith('H')) {
        final entry = await _strongsDb.getHebrewEntry(number);
        if (entry != null) {
          lines.add(
            '${entry.strongsNumber} (Hebraico): ${entry.originalWord} '
            '[${entry.transliteration}] — ${entry.shortDefinition}',
          );
        }
      } else if (number.startsWith('G')) {
        final entry = await _strongsDb.getGreekEntry(number);
        if (entry != null) {
          lines.add(
            '${entry.strongsNumber} (Grego): ${entry.originalWord} '
            '[${entry.transliteration}] — ${entry.shortDefinition}',
          );
        }
      }
    }
    return lines;
  }

  // ---------------------------------------------------------------------------
  // Cross references
  // ---------------------------------------------------------------------------

  Future<List<Verse>> _fetchCrossRefVerses(_VerseRef ref) async {
    if (ref.verse == null) return [];

    final refs = await _strongsDb.getCrossReferences(
      fromBook: ref.bookId,
      fromChapter: ref.chapter,
      fromVerse: ref.verse!,
    );

    const translation = 2; // 2=ARA
    final verses = <Verse>[];

    for (final cr in refs.take(3)) {
      final chapter = await _bibleDb.versesForChapter(
        translationId: translation,
        bookId: cr.toBook,
        chapter: cr.toChapter,
      );
      final match =
          chapter.where((v) => v.verse == cr.toVerse).take(1).toList();
      verses.addAll(
        match.map(
          (v) => Verse(
            translationId: v.translationId,
            bookId: v.bookId,
            chapter: v.chapter,
            verse: v.verse,
            text: v.verseText,
          ),
        ),
      );
    }
    return verses;
  }

  // ---------------------------------------------------------------------------
  // Book alias table (PT names + abbreviations → book ID)
  // ---------------------------------------------------------------------------

  static const Map<String, int> _bookAliases = {
    // Old Testament
    'gênesis': 1, 'genesis': 1, 'gn': 1, 'gen': 1,
    'êxodo': 2, 'exodo': 2, 'ex': 2,
    'levítico': 3, 'levitico': 3, 'lv': 3,
    'números': 4, 'numeros': 4, 'nm': 4,
    'deuteronômio': 5, 'deuteronomio': 5, 'dt': 5,
    'josué': 6, 'josue': 6, 'js': 6,
    'juízes': 7, 'juizes': 7, 'jz': 7,
    'rute': 8, 'rt': 8,
    '1samuel': 9, '1sm': 9,
    '2samuel': 10, '2sm': 10,
    '1reis': 11, '1rs': 11,
    '2reis': 12, '2rs': 12,
    '1crônicas': 13, '1cronicas': 13, '1cr': 13,
    '2crônicas': 14, '2cronicas': 14, '2cr': 14,
    'esdras': 15, 'ed': 15,
    'neemias': 16, 'ne': 16,
    'ester': 17, 'et': 17,
    'jó': 18, 'jo': 18,
    'salmos': 19, 'sl': 19, 'ps': 19,
    'provérbios': 20, 'proverbios': 20, 'pv': 20,
    'eclesiastes': 21, 'ec': 21,
    'cânticos': 22, 'canticos': 22, 'ct': 22,
    'isaías': 23, 'isaias': 23, 'is': 23,
    'jeremias': 24, 'jr': 24,
    'lamentações': 25, 'lamentacoes': 25, 'lm': 25,
    'ezequiel': 26, 'ez': 26,
    'daniel': 27, 'dn': 27,
    'oséias': 28, 'oseias': 28, 'os': 28,
    'joel': 29, 'jl': 29,
    'amós': 30, 'amos': 30, 'am': 30,
    'obadias': 31, 'ob': 31,
    'jonas': 32, 'jn': 32,
    'miquéias': 33, 'miqueias': 33, 'mq': 33,
    'naum': 34, 'na': 34,
    'habacuque': 35, 'hc': 35,
    'sofonias': 36, 'sf': 36,
    'ageu': 37, 'ag': 37,
    'zacarias': 38, 'zc': 38,
    'malaquias': 39, 'ml': 39,
    // New Testament
    'mateus': 40, 'mt': 40,
    'marcos': 41, 'mc': 41,
    'lucas': 42, 'lc': 42,
    'joão': 43, 'joao': 43,
    'atos': 44, 'at': 44,
    'romanos': 45, 'rm': 45, 'ro': 45,
    '1coríntios': 46, '1corintios': 46, '1co': 46,
    '2coríntios': 47, '2corintios': 47, '2co': 47,
    'gálatas': 48, 'galatas': 48, 'gl': 48,
    'efésios': 49, 'efesios': 49, 'ef': 49,
    'filipenses': 50, 'fp': 50,
    'colossenses': 51, 'cl': 51,
    '1tessalonicenses': 52, '1ts': 52,
    '2tessalonicenses': 53, '2ts': 53,
    '1timóteo': 54, '1timoteo': 54, '1tm': 54,
    '2timóteo': 55, '2timoteo': 55, '2tm': 55,
    'tito': 56, 'tt': 56,
    'filemom': 57, 'fm': 57,
    'hebreus': 58, 'hb': 58,
    'tiago': 59, 'tg': 59,
    '1pedro': 60, '1pe': 60,
    '2pedro': 61, '2pe': 61,
    '1joão': 62, '1joao': 62, '1jo': 62,
    '2joão': 63, '2joao': 63, '2jo': 63,
    '3joão': 64, '3joao': 64, '3jo': 64,
    'judas': 65, 'jd': 65,
    'apocalipse': 66, 'ap': 66,
  };

  // Common Hebrew words mapped to Strong's H numbers
  static const Map<String, String> _hebrewWordAliases = {
    'elohim': 'H430',
    'yahweh': 'H3068',
    'yhwh': 'H3068',
    'jeová': 'H3068',
    'shalom': 'H7965',
    'hesed': 'H2617',
    'emet': 'H571',
    'ruah': 'H7307',
    'nephesh': 'H5315',
    'basar': 'H1320',
    'torah': 'H8451',
    'berith': 'H1285',
    'adonai': 'H136',
    'kabod': 'H3519',
  };

  // Common Greek words mapped to Strong's G numbers
  static const Map<String, String> _greekWordAliases = {
    'agape': 'G26',
    'ágape': 'G26',
    'logos': 'G3056',
    'pneuma': 'G4151',
    'sarx': 'G4561',
    'pistis': 'G4102',
    'charis': 'G5485',
    'eirene': 'G1515',
    'zoe': 'G2222',
    'zoé': 'G2222',
    'aletheia': 'G225',
    'christos': 'G5547',
    'kyrios': 'G2962',
    'soter': 'G4990',
    'ekklesia': 'G1577',
    'dikaiosyne': 'G1343',
    'soteria': 'G4991',
    'kairos': 'G2540',
    'parousia': 'G3952',
    'euangelion': 'G2098',
  };
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _VerseRef {
  const _VerseRef({
    required this.bookId,
    required this.chapter,
    this.verse,
  });

  final int bookId;
  final int chapter;
  final int? verse;
}
