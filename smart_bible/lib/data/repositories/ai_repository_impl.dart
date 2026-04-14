import '../../core/constants/ai_prompts.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/llm_engine.dart';
import '../services/bible_context_service.dart';

class AiRepositoryImpl implements AiRepository {
  AiRepositoryImpl({
    required LlmEngine engine,
    required BibleContextService contextService,
  })  : _engine = engine,
        _contextService = contextService;

  final LlmEngine _engine;
  final BibleContextService _contextService;

  @override
  bool get isModelLoaded => _engine.isModelLoaded;

  @override
  Future<void> loadModel(String modelPath) => _engine.loadModel(modelPath);

  @override
  Future<void> unloadModel() => _engine.unloadModel();

  @override
  Stream<String> generateResponse(String userQuestion) async* {
    final context = await _contextService.retrieveContext(userQuestion);

    final prompt = _buildPrompt(
      userQuestion: userQuestion,
      contextBlock: context.toPromptContext(),
    );

    yield* _engine.generateTokens(prompt);
  }

  String _buildPrompt({
    required String userQuestion,
    required String contextBlock,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('<start_of_turn>system');
    buffer.writeln(systemPrompt);
    if (contextBlock.isNotEmpty) {
      buffer.writeln(contextBlock);
    }
    buffer.writeln('<end_of_turn>');
    buffer.writeln('<start_of_turn>user');
    buffer.writeln(userQuestion);
    buffer.writeln('<end_of_turn>');
    buffer.writeln('<start_of_turn>model');
    return buffer.toString();
  }
}
