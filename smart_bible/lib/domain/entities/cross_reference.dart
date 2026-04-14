import 'package:freezed_annotation/freezed_annotation.dart';

part 'cross_reference.freezed.dart';

@freezed
class CrossReference with _$CrossReference {
  const factory CrossReference({
    required int fromBook,
    required int fromChapter,
    required int fromVerse,
    required int toBook,
    required int toChapter,
    required int toVerse,
    required int votes,
  }) = _CrossReference;
}
