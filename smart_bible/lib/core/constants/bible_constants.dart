/// Constants for all 66 Bible books with Portuguese names, English names,
/// abbreviations, testament classification, and chapter counts.
library;

enum Testament { ot, nt }

enum OriginalLanguage { hebrew, greek, aramaic }

class BibleBook {
  const BibleBook({
    required this.id,
    required this.nameEn,
    required this.namePt,
    required this.abbreviationEn,
    required this.abbreviationPt,
    required this.testament,
    required this.bookOrder,
    required this.originalLanguage,
    required this.chapterCount,
  });

  final int id;
  final String nameEn;
  final String namePt;
  final String abbreviationEn;
  final String abbreviationPt;
  final Testament testament;
  final int bookOrder;
  final OriginalLanguage originalLanguage;
  final int chapterCount;
}

const List<BibleBook> kBibleBooks = [
  // Old Testament
  BibleBook(id: 1, nameEn: 'Genesis', namePt: 'Gênesis', abbreviationEn: 'Gen', abbreviationPt: 'Gn', testament: Testament.ot, bookOrder: 1, originalLanguage: OriginalLanguage.hebrew, chapterCount: 50),
  BibleBook(id: 2, nameEn: 'Exodus', namePt: 'Êxodo', abbreviationEn: 'Exo', abbreviationPt: 'Ex', testament: Testament.ot, bookOrder: 2, originalLanguage: OriginalLanguage.hebrew, chapterCount: 40),
  BibleBook(id: 3, nameEn: 'Leviticus', namePt: 'Levítico', abbreviationEn: 'Lev', abbreviationPt: 'Lv', testament: Testament.ot, bookOrder: 3, originalLanguage: OriginalLanguage.hebrew, chapterCount: 27),
  BibleBook(id: 4, nameEn: 'Numbers', namePt: 'Números', abbreviationEn: 'Num', abbreviationPt: 'Nm', testament: Testament.ot, bookOrder: 4, originalLanguage: OriginalLanguage.hebrew, chapterCount: 36),
  BibleBook(id: 5, nameEn: 'Deuteronomy', namePt: 'Deuteronômio', abbreviationEn: 'Deu', abbreviationPt: 'Dt', testament: Testament.ot, bookOrder: 5, originalLanguage: OriginalLanguage.hebrew, chapterCount: 34),
  BibleBook(id: 6, nameEn: 'Joshua', namePt: 'Josué', abbreviationEn: 'Jos', abbreviationPt: 'Js', testament: Testament.ot, bookOrder: 6, originalLanguage: OriginalLanguage.hebrew, chapterCount: 24),
  BibleBook(id: 7, nameEn: 'Judges', namePt: 'Juízes', abbreviationEn: 'Jdg', abbreviationPt: 'Jz', testament: Testament.ot, bookOrder: 7, originalLanguage: OriginalLanguage.hebrew, chapterCount: 21),
  BibleBook(id: 8, nameEn: 'Ruth', namePt: 'Rute', abbreviationEn: 'Rut', abbreviationPt: 'Rt', testament: Testament.ot, bookOrder: 8, originalLanguage: OriginalLanguage.hebrew, chapterCount: 4),
  BibleBook(id: 9, nameEn: '1 Samuel', namePt: '1 Samuel', abbreviationEn: '1Sa', abbreviationPt: '1Sm', testament: Testament.ot, bookOrder: 9, originalLanguage: OriginalLanguage.hebrew, chapterCount: 31),
  BibleBook(id: 10, nameEn: '2 Samuel', namePt: '2 Samuel', abbreviationEn: '2Sa', abbreviationPt: '2Sm', testament: Testament.ot, bookOrder: 10, originalLanguage: OriginalLanguage.hebrew, chapterCount: 24),
  BibleBook(id: 11, nameEn: '1 Kings', namePt: '1 Reis', abbreviationEn: '1Ki', abbreviationPt: '1Rs', testament: Testament.ot, bookOrder: 11, originalLanguage: OriginalLanguage.hebrew, chapterCount: 22),
  BibleBook(id: 12, nameEn: '2 Kings', namePt: '2 Reis', abbreviationEn: '2Ki', abbreviationPt: '2Rs', testament: Testament.ot, bookOrder: 12, originalLanguage: OriginalLanguage.hebrew, chapterCount: 25),
  BibleBook(id: 13, nameEn: '1 Chronicles', namePt: '1 Crônicas', abbreviationEn: '1Ch', abbreviationPt: '1Cr', testament: Testament.ot, bookOrder: 13, originalLanguage: OriginalLanguage.hebrew, chapterCount: 29),
  BibleBook(id: 14, nameEn: '2 Chronicles', namePt: '2 Crônicas', abbreviationEn: '2Ch', abbreviationPt: '2Cr', testament: Testament.ot, bookOrder: 14, originalLanguage: OriginalLanguage.hebrew, chapterCount: 36),
  BibleBook(id: 15, nameEn: 'Ezra', namePt: 'Esdras', abbreviationEn: 'Ezr', abbreviationPt: 'Ed', testament: Testament.ot, bookOrder: 15, originalLanguage: OriginalLanguage.hebrew, chapterCount: 10),
  BibleBook(id: 16, nameEn: 'Nehemiah', namePt: 'Neemias', abbreviationEn: 'Neh', abbreviationPt: 'Ne', testament: Testament.ot, bookOrder: 16, originalLanguage: OriginalLanguage.hebrew, chapterCount: 13),
  BibleBook(id: 17, nameEn: 'Esther', namePt: 'Ester', abbreviationEn: 'Est', abbreviationPt: 'Et', testament: Testament.ot, bookOrder: 17, originalLanguage: OriginalLanguage.hebrew, chapterCount: 10),
  BibleBook(id: 18, nameEn: 'Job', namePt: 'Jó', abbreviationEn: 'Job', abbreviationPt: 'Jó', testament: Testament.ot, bookOrder: 18, originalLanguage: OriginalLanguage.hebrew, chapterCount: 42),
  BibleBook(id: 19, nameEn: 'Psalms', namePt: 'Salmos', abbreviationEn: 'Psa', abbreviationPt: 'Sl', testament: Testament.ot, bookOrder: 19, originalLanguage: OriginalLanguage.hebrew, chapterCount: 150),
  BibleBook(id: 20, nameEn: 'Proverbs', namePt: 'Provérbios', abbreviationEn: 'Pro', abbreviationPt: 'Pv', testament: Testament.ot, bookOrder: 20, originalLanguage: OriginalLanguage.hebrew, chapterCount: 31),
  BibleBook(id: 21, nameEn: 'Ecclesiastes', namePt: 'Eclesiastes', abbreviationEn: 'Ecc', abbreviationPt: 'Ec', testament: Testament.ot, bookOrder: 21, originalLanguage: OriginalLanguage.hebrew, chapterCount: 12),
  BibleBook(id: 22, nameEn: 'Song of Solomon', namePt: 'Cantares', abbreviationEn: 'Sng', abbreviationPt: 'Ct', testament: Testament.ot, bookOrder: 22, originalLanguage: OriginalLanguage.hebrew, chapterCount: 8),
  BibleBook(id: 23, nameEn: 'Isaiah', namePt: 'Isaías', abbreviationEn: 'Isa', abbreviationPt: 'Is', testament: Testament.ot, bookOrder: 23, originalLanguage: OriginalLanguage.hebrew, chapterCount: 66),
  BibleBook(id: 24, nameEn: 'Jeremiah', namePt: 'Jeremias', abbreviationEn: 'Jer', abbreviationPt: 'Jr', testament: Testament.ot, bookOrder: 24, originalLanguage: OriginalLanguage.hebrew, chapterCount: 52),
  BibleBook(id: 25, nameEn: 'Lamentations', namePt: 'Lamentações', abbreviationEn: 'Lam', abbreviationPt: 'Lm', testament: Testament.ot, bookOrder: 25, originalLanguage: OriginalLanguage.hebrew, chapterCount: 5),
  BibleBook(id: 26, nameEn: 'Ezekiel', namePt: 'Ezequiel', abbreviationEn: 'Ezk', abbreviationPt: 'Ez', testament: Testament.ot, bookOrder: 26, originalLanguage: OriginalLanguage.hebrew, chapterCount: 48),
  BibleBook(id: 27, nameEn: 'Daniel', namePt: 'Daniel', abbreviationEn: 'Dan', abbreviationPt: 'Dn', testament: Testament.ot, bookOrder: 27, originalLanguage: OriginalLanguage.aramaic, chapterCount: 12),
  BibleBook(id: 28, nameEn: 'Hosea', namePt: 'Oséias', abbreviationEn: 'Hos', abbreviationPt: 'Os', testament: Testament.ot, bookOrder: 28, originalLanguage: OriginalLanguage.hebrew, chapterCount: 14),
  BibleBook(id: 29, nameEn: 'Joel', namePt: 'Joel', abbreviationEn: 'Jol', abbreviationPt: 'Jl', testament: Testament.ot, bookOrder: 29, originalLanguage: OriginalLanguage.hebrew, chapterCount: 3),
  BibleBook(id: 30, nameEn: 'Amos', namePt: 'Amós', abbreviationEn: 'Amo', abbreviationPt: 'Am', testament: Testament.ot, bookOrder: 30, originalLanguage: OriginalLanguage.hebrew, chapterCount: 9),
  BibleBook(id: 31, nameEn: 'Obadiah', namePt: 'Obadias', abbreviationEn: 'Oba', abbreviationPt: 'Ob', testament: Testament.ot, bookOrder: 31, originalLanguage: OriginalLanguage.hebrew, chapterCount: 1),
  BibleBook(id: 32, nameEn: 'Jonah', namePt: 'Jonas', abbreviationEn: 'Jon', abbreviationPt: 'Jn', testament: Testament.ot, bookOrder: 32, originalLanguage: OriginalLanguage.hebrew, chapterCount: 4),
  BibleBook(id: 33, nameEn: 'Micah', namePt: 'Miquéias', abbreviationEn: 'Mic', abbreviationPt: 'Mq', testament: Testament.ot, bookOrder: 33, originalLanguage: OriginalLanguage.hebrew, chapterCount: 7),
  BibleBook(id: 34, nameEn: 'Nahum', namePt: 'Naum', abbreviationEn: 'Nam', abbreviationPt: 'Na', testament: Testament.ot, bookOrder: 34, originalLanguage: OriginalLanguage.hebrew, chapterCount: 3),
  BibleBook(id: 35, nameEn: 'Habakkuk', namePt: 'Habacuque', abbreviationEn: 'Hab', abbreviationPt: 'Hc', testament: Testament.ot, bookOrder: 35, originalLanguage: OriginalLanguage.hebrew, chapterCount: 3),
  BibleBook(id: 36, nameEn: 'Zephaniah', namePt: 'Sofonias', abbreviationEn: 'Zep', abbreviationPt: 'Sf', testament: Testament.ot, bookOrder: 36, originalLanguage: OriginalLanguage.hebrew, chapterCount: 3),
  BibleBook(id: 37, nameEn: 'Haggai', namePt: 'Ageu', abbreviationEn: 'Hag', abbreviationPt: 'Ag', testament: Testament.ot, bookOrder: 37, originalLanguage: OriginalLanguage.hebrew, chapterCount: 2),
  BibleBook(id: 38, nameEn: 'Zechariah', namePt: 'Zacarias', abbreviationEn: 'Zec', abbreviationPt: 'Zc', testament: Testament.ot, bookOrder: 38, originalLanguage: OriginalLanguage.hebrew, chapterCount: 14),
  BibleBook(id: 39, nameEn: 'Malachi', namePt: 'Malaquias', abbreviationEn: 'Mal', abbreviationPt: 'Ml', testament: Testament.ot, bookOrder: 39, originalLanguage: OriginalLanguage.hebrew, chapterCount: 4),
  // New Testament
  BibleBook(id: 40, nameEn: 'Matthew', namePt: 'Mateus', abbreviationEn: 'Mat', abbreviationPt: 'Mt', testament: Testament.nt, bookOrder: 40, originalLanguage: OriginalLanguage.greek, chapterCount: 28),
  BibleBook(id: 41, nameEn: 'Mark', namePt: 'Marcos', abbreviationEn: 'Mrk', abbreviationPt: 'Mc', testament: Testament.nt, bookOrder: 41, originalLanguage: OriginalLanguage.greek, chapterCount: 16),
  BibleBook(id: 42, nameEn: 'Luke', namePt: 'Lucas', abbreviationEn: 'Luk', abbreviationPt: 'Lc', testament: Testament.nt, bookOrder: 42, originalLanguage: OriginalLanguage.greek, chapterCount: 24),
  BibleBook(id: 43, nameEn: 'John', namePt: 'João', abbreviationEn: 'Jhn', abbreviationPt: 'Jo', testament: Testament.nt, bookOrder: 43, originalLanguage: OriginalLanguage.greek, chapterCount: 21),
  BibleBook(id: 44, nameEn: 'Acts', namePt: 'Atos', abbreviationEn: 'Act', abbreviationPt: 'At', testament: Testament.nt, bookOrder: 44, originalLanguage: OriginalLanguage.greek, chapterCount: 28),
  BibleBook(id: 45, nameEn: 'Romans', namePt: 'Romanos', abbreviationEn: 'Rom', abbreviationPt: 'Rm', testament: Testament.nt, bookOrder: 45, originalLanguage: OriginalLanguage.greek, chapterCount: 16),
  BibleBook(id: 46, nameEn: '1 Corinthians', namePt: '1 Coríntios', abbreviationEn: '1Co', abbreviationPt: '1Co', testament: Testament.nt, bookOrder: 46, originalLanguage: OriginalLanguage.greek, chapterCount: 16),
  BibleBook(id: 47, nameEn: '2 Corinthians', namePt: '2 Coríntios', abbreviationEn: '2Co', abbreviationPt: '2Co', testament: Testament.nt, bookOrder: 47, originalLanguage: OriginalLanguage.greek, chapterCount: 13),
  BibleBook(id: 48, nameEn: 'Galatians', namePt: 'Gálatas', abbreviationEn: 'Gal', abbreviationPt: 'Gl', testament: Testament.nt, bookOrder: 48, originalLanguage: OriginalLanguage.greek, chapterCount: 6),
  BibleBook(id: 49, nameEn: 'Ephesians', namePt: 'Efésios', abbreviationEn: 'Eph', abbreviationPt: 'Ef', testament: Testament.nt, bookOrder: 49, originalLanguage: OriginalLanguage.greek, chapterCount: 6),
  BibleBook(id: 50, nameEn: 'Philippians', namePt: 'Filipenses', abbreviationEn: 'Php', abbreviationPt: 'Fp', testament: Testament.nt, bookOrder: 50, originalLanguage: OriginalLanguage.greek, chapterCount: 4),
  BibleBook(id: 51, nameEn: 'Colossians', namePt: 'Colossenses', abbreviationEn: 'Col', abbreviationPt: 'Cl', testament: Testament.nt, bookOrder: 51, originalLanguage: OriginalLanguage.greek, chapterCount: 4),
  BibleBook(id: 52, nameEn: '1 Thessalonians', namePt: '1 Tessalonicenses', abbreviationEn: '1Th', abbreviationPt: '1Ts', testament: Testament.nt, bookOrder: 52, originalLanguage: OriginalLanguage.greek, chapterCount: 5),
  BibleBook(id: 53, nameEn: '2 Thessalonians', namePt: '2 Tessalonicenses', abbreviationEn: '2Th', abbreviationPt: '2Ts', testament: Testament.nt, bookOrder: 53, originalLanguage: OriginalLanguage.greek, chapterCount: 3),
  BibleBook(id: 54, nameEn: '1 Timothy', namePt: '1 Timóteo', abbreviationEn: '1Ti', abbreviationPt: '1Tm', testament: Testament.nt, bookOrder: 54, originalLanguage: OriginalLanguage.greek, chapterCount: 6),
  BibleBook(id: 55, nameEn: '2 Timothy', namePt: '2 Timóteo', abbreviationEn: '2Ti', abbreviationPt: '2Tm', testament: Testament.nt, bookOrder: 55, originalLanguage: OriginalLanguage.greek, chapterCount: 4),
  BibleBook(id: 56, nameEn: 'Titus', namePt: 'Tito', abbreviationEn: 'Tit', abbreviationPt: 'Tt', testament: Testament.nt, bookOrder: 56, originalLanguage: OriginalLanguage.greek, chapterCount: 3),
  BibleBook(id: 57, nameEn: 'Philemon', namePt: 'Filemom', abbreviationEn: 'Phm', abbreviationPt: 'Fm', testament: Testament.nt, bookOrder: 57, originalLanguage: OriginalLanguage.greek, chapterCount: 1),
  BibleBook(id: 58, nameEn: 'Hebrews', namePt: 'Hebreus', abbreviationEn: 'Heb', abbreviationPt: 'Hb', testament: Testament.nt, bookOrder: 58, originalLanguage: OriginalLanguage.greek, chapterCount: 13),
  BibleBook(id: 59, nameEn: 'James', namePt: 'Tiago', abbreviationEn: 'Jas', abbreviationPt: 'Tg', testament: Testament.nt, bookOrder: 59, originalLanguage: OriginalLanguage.greek, chapterCount: 5),
  BibleBook(id: 60, nameEn: '1 Peter', namePt: '1 Pedro', abbreviationEn: '1Pe', abbreviationPt: '1Pe', testament: Testament.nt, bookOrder: 60, originalLanguage: OriginalLanguage.greek, chapterCount: 5),
  BibleBook(id: 61, nameEn: '2 Peter', namePt: '2 Pedro', abbreviationEn: '2Pe', abbreviationPt: '2Pe', testament: Testament.nt, bookOrder: 61, originalLanguage: OriginalLanguage.greek, chapterCount: 3),
  BibleBook(id: 62, nameEn: '1 John', namePt: '1 João', abbreviationEn: '1Jn', abbreviationPt: '1Jo', testament: Testament.nt, bookOrder: 62, originalLanguage: OriginalLanguage.greek, chapterCount: 5),
  BibleBook(id: 63, nameEn: '2 John', namePt: '2 João', abbreviationEn: '2Jn', abbreviationPt: '2Jo', testament: Testament.nt, bookOrder: 63, originalLanguage: OriginalLanguage.greek, chapterCount: 1),
  BibleBook(id: 64, nameEn: '3 John', namePt: '3 João', abbreviationEn: '3Jn', abbreviationPt: '3Jo', testament: Testament.nt, bookOrder: 64, originalLanguage: OriginalLanguage.greek, chapterCount: 1),
  BibleBook(id: 65, nameEn: 'Jude', namePt: 'Judas', abbreviationEn: 'Jud', abbreviationPt: 'Jd', testament: Testament.nt, bookOrder: 65, originalLanguage: OriginalLanguage.greek, chapterCount: 1),
  BibleBook(id: 66, nameEn: 'Revelation', namePt: 'Apocalipse', abbreviationEn: 'Rev', abbreviationPt: 'Ap', testament: Testament.nt, bookOrder: 66, originalLanguage: OriginalLanguage.greek, chapterCount: 22),
];

const int kOldTestamentBookCount = 39;
const int kNewTestamentBookCount = 27;
const int kTotalBookCount = 66;
