import '../entities/chat_message.dart';
import '../repositories/ai_repository.dart';

/// Sends a user message through the AI pipeline and returns a stream of
/// [ChatMessage] snapshots as tokens arrive.
class SendChatMessage {
  const SendChatMessage(this._repository);

  final AiRepository _repository;

  /// Emits successive [ChatMessage] snapshots as the assistant response builds.
  Stream<ChatMessage> call({
    required String userQuestion,
    required String assistantMessageId,
  }) async* {
    var content = '';

    await for (final token in _repository.generateResponse(userQuestion)) {
      content += token;
      yield ChatMessage(
        id: assistantMessageId,
        role: ChatRole.assistant,
        content: content,
        timestamp: DateTime.now(),
      );
    }
  }
}
