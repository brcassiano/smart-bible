import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/llm_engine.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../data/services/bible_context_service.dart';
import '../../data/services/model_download_service.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/usecases/send_chat_message.dart';
import 'bible_providers.dart';
import 'strongs_providers.dart';

part 'ai_providers.g.dart';

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
LlmEngine llmEngine(Ref ref) => LlmEngine();

@Riverpod(keepAlive: true)
BibleContextService bibleContextService(Ref ref) => BibleContextService(
      bibleDatabase: ref.watch(bibleDatabaseProvider),
      strongsDatabase: ref.watch(strongsDatabaseProvider),
    );

@Riverpod(keepAlive: true)
AiRepository aiRepository(Ref ref) => AiRepositoryImpl(
      engine: ref.watch(llmEngineProvider),
      contextService: ref.watch(bibleContextServiceProvider),
    );

@Riverpod(keepAlive: true)
ModelDownloadService modelDownloadService(Ref ref) => ModelDownloadService();

@Riverpod(keepAlive: true)
SendChatMessage sendChatMessage(Ref ref) =>
    SendChatMessage(ref.watch(aiRepositoryProvider));

// ---------------------------------------------------------------------------
// Model status
// ---------------------------------------------------------------------------

enum ModelStatus { notDownloaded, downloading, loading, ready, error }

class ModelStatusState {
  const ModelStatusState({
    required this.status,
    this.downloadProgress = 0.0,
    this.bytesReceived = 0,
    this.totalBytes = 0,
    this.errorMessage,
    this.modelPath,
  });

  final ModelStatus status;
  final double downloadProgress;
  final int bytesReceived;
  final int totalBytes;
  final String? errorMessage;
  final String? modelPath;
}

@Riverpod(keepAlive: true)
class ModelStatusNotifier extends _$ModelStatusNotifier {
  @override
  ModelStatusState build() => const ModelStatusState(
        status: ModelStatus.notDownloaded,
      );

  Future<void> initialize() async {
    final service = ref.read(modelDownloadServiceProvider);
    final path = await service.getSavedModelPath();
    if (path != null) {
      await _loadModel(path);
    }
  }

  Future<void> _loadModel(String path) async {
    state = ModelStatusState(status: ModelStatus.loading, modelPath: path);
    try {
      await ref.read(aiRepositoryProvider).loadModel(path);
      state = ModelStatusState(status: ModelStatus.ready, modelPath: path);
    } on Exception catch (e) {
      state = ModelStatusState(
        status: ModelStatus.error,
        errorMessage: _cleanErrorMessage(e.toString()),
      );
    }
  }

  Stream<ModelDownloadProgress> startDownload() async* {
    final service = ref.read(modelDownloadServiceProvider);
    await for (final progress in service.downloadModel()) {
      switch (progress.status) {
        case ModelDownloadStatus.downloading:
          state = ModelStatusState(
            status: ModelStatus.downloading,
            downloadProgress: progress.progress,
            bytesReceived: progress.bytesReceived,
            totalBytes: progress.totalBytes,
          );
        case ModelDownloadStatus.complete:
          if (progress.modelPath != null) {
            await _loadModel(progress.modelPath!);
          }
        case ModelDownloadStatus.error:
          state = ModelStatusState(
            status: ModelStatus.error,
            errorMessage: progress.errorMessage,
          );
        case ModelDownloadStatus.idle:
          break;
      }
      yield progress;
    }
  }

  Future<void> retryDownload() async {
    state = const ModelStatusState(status: ModelStatus.notDownloaded);
    startDownload().listen((_) {});
  }

  void cancelDownload() {
    final service = ref.read(modelDownloadServiceProvider);
    service.cancelDownload();
    state = const ModelStatusState(status: ModelStatus.notDownloaded);
  }

  String _cleanErrorMessage(String raw) {
    if (raw.startsWith('Exception: ')) return raw.substring(11);
    return raw;
  }
}

// ---------------------------------------------------------------------------
// Chat messages
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
class ChatMessagesNotifier extends _$ChatMessagesNotifier {
  @override
  List<ChatMessage> build() => [];

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void updateMessage(ChatMessage updated) {
    state = [
      for (final m in state)
        if (m.id == updated.id) updated else m,
    ];
  }

  void clear() => state = [];

  Future<void> sendUserMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: ChatRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
    );
    addMessage(userMsg);

    final assistantId =
        '${DateTime.now().microsecondsSinceEpoch + 1}';
    final assistantMsg = ChatMessage(
      id: assistantId,
      role: ChatRole.assistant,
      content: '',
      timestamp: DateTime.now(),
    );
    addMessage(assistantMsg);

    final useCase = ref.read(sendChatMessageProvider);
    await for (final snapshot in useCase.call(
      userQuestion: text.trim(),
      assistantMessageId: assistantId,
    )) {
      updateMessage(snapshot);
    }
  }
}
