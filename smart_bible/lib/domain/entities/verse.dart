import 'package:freezed_annotation/freezed_annotation.dart';

part 'verse.freezed.dart';

@freezed
class Verse with _$Verse {
  const factory Verse({
    required int translationId,
    required int bookId,
    required int chapter,
    required int verse,
    required String text,
  }) = _Verse;
}
