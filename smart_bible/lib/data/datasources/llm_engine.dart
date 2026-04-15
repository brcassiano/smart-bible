/// LLM engine using llamadart for local GGUF model inference.
library;

import 'dart:async';

import 'package:llamadart/llamadart.dart';

class LlmEngine {
  LlamaEngine? _engine;
  bool _loaded = false;

  bool get isModelLoaded => _loaded;

  Future<void> loadModel(String modelPath) async {
    try {
      _engine = LlamaEngine(LlamaBackend());
      await _engine!.loadModel(modelPath);
      _loaded = true;
    } catch (e) {
      _loaded = false;
      _engine = null;
      rethrow;
    }
  }

  Stream<String> generateTokens(String prompt) async* {
    if (!_loaded || _engine == null) {
      yield* Stream.error(StateError('Model not loaded. Call loadModel first.'));
      return;
    }
    await for (final token in _engine!.generate(prompt)) {
      yield token;
    }
  }

  Future<void> unloadModel() async {
    if (_engine != null) {
      await _engine!.dispose();
      _engine = null;
    }
    _loaded = false;
  }
}
