import 'package:freezed_annotation/freezed_annotation.dart';

part 'translation.freezed.dart';

@freezed
class Translation with _$Translation {
  const factory Translation({
    required int id,
    required String abbreviation,
    required String name,
    required String language,
    required String description,
  }) = _Translation;
}
