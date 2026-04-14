import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ai_providers.dart';
import '../../widgets/ai_chat_content.dart';
import '../../widgets/app_drawer.dart';

class AiChatScreen extends ConsumerWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelStatus = ref.watch(modelStatusNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistente IA'),
        actions: [
          _ModelStatusChip(state: modelStatus),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: const AiChatContent(),
    );
  }
}

// ---------------------------------------------------------------------------
// Model status chip in app bar
// ---------------------------------------------------------------------------

class _ModelStatusChip extends StatelessWidget {
  const _ModelStatusChip({required this.state});

  final ModelStatusState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (label, color) = switch (state.status) {
      ModelStatus.ready => ('Pronto', theme.colorScheme.primary),
      ModelStatus.loading => ('Carregando...', theme.colorScheme.tertiary),
      ModelStatus.downloading => (
          'Baixando ${(state.downloadProgress * 100).toStringAsFixed(0)}%',
          theme.colorScheme.secondary,
        ),
      ModelStatus.error => ('Erro', theme.colorScheme.error),
      ModelStatus.notDownloaded => ('Sem modelo', theme.colorScheme.outline),
    };

    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 11)),
      side: BorderSide(color: color),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
