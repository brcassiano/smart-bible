import '../entities/strongs_entry.dart';
import '../repositories/strongs_repository.dart';

enum StrongsLanguage { hebrew, greek }

class GetStrongsEntry {
  const GetStrongsEntry(this._repository);

  final StrongsRepository _repository;

  Future<StrongsEntry?> call({
    required String strongsNumber,
    required StrongsLanguage language,
  }) {
    return switch (language) {
      StrongsLanguage.hebrew => _repository.getHebrewEntry(strongsNumber),
      StrongsLanguage.greek => _repository.getGreekEntry(strongsNumber),
    };
  }
}
