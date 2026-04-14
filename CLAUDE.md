# Smart Bible

App mobile de estudo biblico que roda 100% offline com IA local (Gemma 4 E2B via llama.cpp).

## Stack

- **App**: Flutter (Dart) com clean architecture
- **Database**: SQLite via Drift ORM
- **State**: Riverpod (com codegen)
- **Navigation**: GoRouter
- **AI**: llama.cpp (GGUF) - stub atual, integracao FFI pendente
- **Data pipeline**: Python com uv

## Estrutura

```
smart-bible/
  smart_bible/              # Projeto Flutter
    lib/
      main.dart             # Entry point
      app.dart              # MaterialApp + GoRouter + localization
      core/
        constants/          # bible_constants, app_constants, ai_prompts
        theme/              # Material 3 theme (amber/brown)
        l10n/               # ARB files (pt_BR, en)
        utils/              # Extensions
      domain/
        entities/           # Verse, Book, Translation, StrongsEntry, ChatMessage
        repositories/       # Abstract interfaces
        usecases/           # GetVerses, SearchBible, GetStrongsEntry, SendChatMessage
      data/
        datasources/        # Drift databases (bible_database, strongs_database, llm_engine)
        repositories/       # Implementations
        services/           # BibleContextService, ModelDownloadService
      presentation/
        screens/            # home, reader, word_study, ai_chat
        providers/          # Riverpod providers (bible, strongs, ai)
        widgets/            # Shared widgets
    assets/
      databases/            # bible.db (~15MB), strongs.db (~18MB)
  data/
    raw/                    # Cloned source repos (git ignored)
    processed/              # Generated .db files
    scripts/                # Python ETL scripts (uv project)
```

## Comandos

### App Flutter
```bash
cd smart_bible
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # gerar .g.dart e .freezed.dart
flutter analyze
flutter run                                                # debug
flutter build apk --release                                # APK
```

### Pipeline de Dados
```bash
cd data/scripts
uv run python build_bible_db.py      # gera data/processed/bible.db
uv run python build_strongs_db.py    # gera data/processed/strongs.db
```

Apos gerar, copiar para assets:
```bash
sqlite3 data/processed/bible.db "PRAGMA wal_checkpoint(TRUNCATE); VACUUM;"
sqlite3 data/processed/strongs.db "PRAGMA wal_checkpoint(TRUNCATE); VACUUM;"
cp data/processed/bible.db smart_bible/assets/databases/
cp data/processed/strongs.db smart_bible/assets/databases/
```

## Bancos de Dados

### bible.db
- **translations**: id (INT PK), abbreviation, name, language. IDs: 1=ACF, 2=ARA, 3=KJV
- **books**: id (INT PK 1-66), name, name_pt, testament (OT/NT), book_order, original_language (he/el)
- **verses**: translation_id (INT FK), book_id (INT FK), chapter, verse, text. ~31k versos por traducao

### strongs.db
- **hebrew_lexicon**: strongs_number (TEXT PK, ex: "H1"), original_word, transliteration, pronunciation, short/full_definition, part_of_speech. 8.674 entradas
- **greek_lexicon**: mesmo schema, prefixo "G". 5.624 entradas
- **cross_references**: from/to (book, chapter, verse), votes. 432k+ referencias

## Convencoes

- Clean architecture: domain/ nao importa data/ nem presentation/
- Entities usam freezed para imutabilidade
- Providers usam riverpod_generator (@riverpod)
- Drift databases abrem .db pre-existente de assets (nao criam tabelas)
- UI em portugues brasileiro, codigo em ingles
- Tema Material 3 com seed color amber/brown (#7B4F2E)
- Fontes: Lora (serif, texto biblico), Nunito (UI)

## Modelo de IA

- **Modelo**: Gemma 4 E2B Q4_K_M (~1.3GB GGUF)
- **Runtime**: llama.cpp via FFI (integracao pendente, stub atual)
- **Fluxo**: pergunta → RAG local (busca em SQLite) → monta prompt com contexto → modelo gera resposta
- **Download**: modelo baixado na primeira execucao, armazenado em app documents
