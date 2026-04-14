import 'package:freezed_annotation/freezed_annotation.dart';

part 'strongs_entry.freezed.dart';

@freezed
class StrongsEntry with _$StrongsEntry {
  const factory StrongsEntry({
    required String strongsNumber,
    required String originalWord,
    required String transliteration,
    required String pronunciation,
    required String shortDefinition,
    required String fullDefinition,
    required String partOfSpeech,
  }) = _StrongsEntry;
}
