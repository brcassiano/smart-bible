abstract interface class AiRepository {
  bool get isModelLoaded;

  Future<void> loadModel(String modelPath);

  Stream<String> generateResponse(String prompt);

  Future<void> unloadModel();
}
