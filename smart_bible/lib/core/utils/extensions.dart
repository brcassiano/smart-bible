import '../constants/bible_constants.dart';

extension TestamentExtension on Testament {
  String get labelPt => switch (this) {
        Testament.ot => 'Antigo Testamento',
        Testament.nt => 'Novo Testamento',
      };

  String get labelEn => switch (this) {
        Testament.ot => 'Old Testament',
        Testament.nt => 'New Testament',
      };
}

extension OriginalLanguageExtension on OriginalLanguage {
  String get labelPt => switch (this) {
        OriginalLanguage.hebrew => 'Hebraico',
        OriginalLanguage.greek => 'Grego',
        OriginalLanguage.aramaic => 'Aramaico',
      };
}

extension StringExtension on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String normalizeForSearch() {
    return toLowerCase()
        .replaceAll(RegExp(r'[áàãâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòõôö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .trim();
  }
}
