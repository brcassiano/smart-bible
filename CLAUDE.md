# Smart Bible

App mobile de estudo biblico que roda 100% offline com IA local (Gemma 3 1B via llama.cpp).

**Repo**: https://github.com/brcassiano/smart-bible

## Stack

- **App**: Flutter (Dart) com clean architecture
- **Database**: SQLite via Drift ORM
- **State**: Riverpod (com codegen)
- **Navigation**: GoRouter
- **LLM**: llamadart (llama.cpp nativo) - roda modelos GGUF localmente
- **Data pipeline**: Python com uv

## Estrutura

```
smart-bible/
  smart_bible/              # Projeto Flutter
    lib/
      main.dart             # Entry point
      app.dart              # MaterialApp + GoRouter + PersistentChatBar + setup redirect
      core/
        constants/          # bible_constants, app_constants, ai_prompts
        theme/              # Material 3 theme (amber/brown)
        l10n/               # ARB files (pt_BR, en)
        utils/              # Extensions
      domain/
        entities/           # Verse, Book, Translation, StrongsEntry, ChatMessage, CrossReference
        repositories/       # Abstract interfaces (BibleRepository, StrongsRepository, AiRepository)
        usecases/           # GetVerses, SearchBible, GetStrongsEntry, SendChatMessage
      data/
        datasources/
          bible_database.dart    # Drift ORM para bible.db
          strongs_database.dart  # Drift ORM para strongs.db
          llm_engine.dart        # llamadart wrapper (carrega e roda modelo GGUF)
        repositories/       # Implementations
        services/
          bible_context_service.dart   # RAG: parseia referencia biblica, busca versos/Strong's/cross-refs
          model_download_service.dart  # Download do modelo GGUF com retry, resume, redirect handling
      presentation/
        screens/
          home/              # Tela inicial com cards de features
          reader/            # Leitor biblico (versos, capitulos, livros)
            widgets/
              chapter_selector.dart    # Chips horizontais de capitulos
              verse_tile.dart          # Renderiza um versiculo (tappable)
              verse_study_sheet.dart   # Bottom sheet: palavras tappable → Strong's + analise IA
          word_study/        # Busca por Strong's number ou palavra
          ai_chat/           # Tela cheia do chat (usa AiChatContent)
          setup/             # Tela de setup (download obrigatorio do modelo no primeiro uso)
        providers/
          bible_providers.dart   # ReaderState, translations, books, chapterVerses
          strongs_providers.dart # Hebrew/Greek entry, word search
          ai_providers.dart      # ModelStatus, ChatMessages, download/load lifecycle
        widgets/
          persistent_chat_bar.dart  # Input de chat fixo na base de TODAS as telas (estilo ChatGPT)
          ai_chat_content.dart      # Widget reutilizavel do chat (mensagens, sugestoes)
          app_drawer.dart           # Drawer de navegacao
    assets/
      databases/            # bible.db (~15MB), strongs.db (~18MB)
    android/
      app/src/main/AndroidManifest.xml  # INTERNET permission (obrigatorio para release)
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
flutter build apk --release                                # APK (~154MB com llama.cpp nativo)
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

## Modelo de IA

- **Modelo**: Gemma 3 1B Instruct Q4_K_M (~769MB GGUF)
- **Runtime**: llamadart (llama.cpp nativo via dart:ffi, sem CMake manual)
- **Hospedagem**: GitHub Releases v1.0.0 (https://github.com/brcassiano/smart-bible/releases)
- **Fluxo**: pergunta → RAG local (busca versos + Strong's + cross-refs em SQLite) → monta prompt com contexto → Gemma gera resposta em streaming
- **Download**: automatico na tela de setup (primeiro uso), ~769MB, com retry e resume
- **Prompt**: formato Gemma `<start_of_turn>system/user/model<end_of_turn>`

## UX Patterns

- **Translation picker**: texto clicavel "ARA ▼" no app bar, bottom sheet com lista
- **Book picker**: nome do livro clicavel, bottom sheet com 2 colunas (AT/NT) + campo de busca
- **Chapter selector**: chips horizontais com scroll, auto-scroll ao topo ao trocar capitulo
- **Verse study**: tocar versiculo → bottom sheet com palavras tappable → Strong's + analise IA
- **Chat persistente**: barra de input fixa na base de TODAS as telas (estilo ChatGPT/Claude)
- **Setup obrigatorio**: primeiro uso → download automatico do modelo, sem opcao de pular

## Convencoes

- Clean architecture: domain/ nao importa data/ nem presentation/
- Entities usam freezed para imutabilidade
- Providers usam riverpod_generator (@riverpod)
- Drift databases abrem .db pre-existente de assets (nao criam tabelas)
- UI em portugues brasileiro, codigo em ingles
- Tema Material 3 com seed color amber/brown (#7B4F2E)
- Fontes: Lora (serif, texto biblico), Nunito (UI)
- AndroidManifest.xml de release DEVE ter `android.permission.INTERNET`

## Problemas Conhecidos / Proximos Passos

- Qualidade das respostas da IA: Gemma 3 1B e pequeno, pode gerar respostas genericas. Considerar upgrade para Gemma 3 4B (~2.5GB) ou Gemma 4 E4B para melhor raciocinio
- Estudo de palavras no leitor depende do searchByWord (busca por short_definition). Nao temos mapeamento palavra-por-palavra dos versos (verse_words do STEPBible-Data nao foi importado ainda)
- Dados historicos/culturais (context.db) ainda nao implementados
- Testes unitarios pendentes
