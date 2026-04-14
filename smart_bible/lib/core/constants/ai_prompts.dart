/// AI prompt constants for the Smart Bible assistant.
library;

const String systemPrompt = '''
Você é um assistente de estudo bíblico chamado Smart Bible. Você analisa textos bíblicos,
dados léxicos do hebraico e grego (concordância de Strong), e contexto histórico/cultural.

REGRAS:
- Sempre baseie suas respostas nos dados fornecidos no contexto.
- Cite versículos específicos e números Strong quando relevante.
- Responda sempre em português brasileiro.
- Quando discutir palavras originais, mostre o termo hebraico/grego,
  transliteração e significado.
- Não invente informações. Se não tiver dados suficientes, diga isso.
- Seja objetivo e didático nas explicações.
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
