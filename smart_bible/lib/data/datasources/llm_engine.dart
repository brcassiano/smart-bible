/// LLM engine stub.
///
/// No mature, pub-published Flutter llama.cpp binding is available that
/// supports GGUF models reliably on both Android and iOS as of 2026-04.
/// This stub exposes the same interface that [AiRepositoryImpl] expects so
/// the entire chat pipeline (context retrieval, prompt construction, UI) works
/// end-to-end.  Swap [_runInference] for real FFI calls once a binding lands.
library;

import 'dart:async';

class LlmEngine {
  bool _loaded = false;
  // ignore: unused_field — will be used by real FFI when llama.cpp binding lands
  String? _modelPath;

  bool get isModelLoaded => _loaded;

  Future<void> loadModel(String modelPath) async {
    // TODO: replace with actual llama.cpp FFI initialisation once a
    //       stable Flutter binding is available (e.g. lcpp, woolydart).
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _modelPath = modelPath;
    _loaded = true;
  }

  Stream<String> generateTokens(String prompt) async* {
    if (!_loaded) {
      yield* Stream.error(StateError('Model not loaded. Call loadModel first.'));
      return;
    }
    // Stub: emits a helpful beta message word by word, simulating streaming.
    // Replace with real token streaming from the native library.
    const message =
        'Olá! Sou o assistente bíblico Smart Bible. Atualmente estou em fase '
        'de configuração. Em breve, poderei ajudá-lo com:\n\n'
        '- Análise de textos bíblicos em múltiplas traduções\n'
        '- Estudo de palavras no hebraico e grego originais\n'
        '- Contexto histórico e cultural das passagens\n\n'
        'Enquanto isso, experimente o Leitor Bíblico e o Estudo de Palavras!';
    for (final word in message.split(' ')) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      yield '$word ';
    }
  }

  Future<void> unloadModel() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _loaded = false;
    _modelPath = null;
  }
}
