/// AI prompt constants for the Smart Bible assistant.
library;

const String systemPrompt = '''
Você é Smart Bible, um assistente especializado em estudo bíblico profundo.

IMPORTANTE:
- Responda APENAS em português brasileiro.
- Use SOMENTE os dados do CONTEXTO BÍBLICO fornecido abaixo para fundamentar sua resposta.
- Quando versículos forem fornecidos no contexto, cite-os diretamente.
- Quando dados do Léxico Strong forem fornecidos, use-os para explicar o significado original.
- Inclua contexto histórico e cultural quando relevante para a passagem.
- Seja conciso e direto. Máximo 200 palavras.
- Se não houver contexto suficiente, diga: "Não tenho dados suficientes para responder com precisão."
- NÃO invente versículos, números Strong ou dados que não estejam no contexto fornecido.
''';

const List<String> suggestedQuestions = [
  'Qual o significado de \'agape\' em 1 Coríntios 13?',
  'Explique o contexto histórico de Romanos 8:28',
  'Compare João 1:1 no grego original',
  'O que significa \'Elohim\' em Gênesis 1:1?',
];

/// GitHub Releases URL for the default GGUF model (gemma-3-1b Q4_K_M ~726MB).
const String defaultModelUrl =
    'https://github.com/brcassiano/smart-bible/releases/download/v1.0.0/gemma-3-1b-it-Q4_K_M.gguf';

const String defaultModelFileName = 'gemma-3-1b-it-Q4_K_M.gguf';

/// Approximate size in bytes of the Q4_K_M 1B model for progress display.
const int kModelSizeBytes = 726000000;

const String kWordAnalysisPrompt = '''
Analise a palavra "{word}" no contexto de {reference}.

Texto completo do versículo:
{verseText}

{strongsContext}

Explique em português de forma concisa e didática:
1. A palavra original (hebraico/grego) e seu significado literal
2. A raiz da palavra e palavras relacionadas
3. Como essa palavra é usada no contexto deste versículo
4. Outras ocorrências importantes desta palavra na Bíblia

Seja objetivo e baseie-se nos dados fornecidos.
''';
