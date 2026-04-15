import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/ai_prompts.dart';
import '../../providers/ai_providers.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  bool _downloadStarted = false;

  @override
  void initState() {
    super.initState();
    // Start download automatically on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) => _startDownload());
  }

  Future<void> _markSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_completed', true);
  }

  Future<void> _startDownload() async {
    if (_downloadStarted) return;
    setState(() => _downloadStarted = true);
    ref
        .read(modelStatusNotifierProvider.notifier)
        .startDownload()
        .listen((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modelStatus = ref.watch(modelStatusNotifierProvider);

    // Navigate away when download completes
    if (modelStatus.status == ModelStatus.ready && _downloadStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _markSetupDone();
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        context.go('/');
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Smart Bible',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Preparando o Smart Bible',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Estamos baixando o modelo de IA (~769 MB) para que o assistente funcione 100% offline.\n\n'
                  'Isso só acontece uma vez. Por favor, mantenha o app aberto.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (modelStatus.status == ModelStatus.downloading ||
                    modelStatus.status == ModelStatus.notDownloaded) ...[
                  _DownloadProgressSection(state: modelStatus),
                ],
                if (modelStatus.status == ModelStatus.loading) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Carregando modelo...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (modelStatus.status == ModelStatus.error) ...[
                  _ErrorSection(
                    errorMessage: modelStatus.errorMessage ??
                        'Erro desconhecido ao baixar o modelo.',
                    onRetry: () {
                      setState(() => _downloadStarted = false);
                      ref
                          .read(modelStatusNotifierProvider.notifier)
                          .retryDownload();
                      setState(() => _downloadStarted = true);
                    },
                  ),
                ],
                const SizedBox(height: 32),
                Icon(
                  Icons.wifi_rounded,
                  size: 24,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Recomendamos usar Wi-Fi para o download',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Download progress section
// ---------------------------------------------------------------------------

class _DownloadProgressSection extends StatelessWidget {
  const _DownloadProgressSection({required this.state});

  final ModelStatusState state;

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = state.downloadProgress;
    final percent = (progress * 100).toStringAsFixed(0);
    final received = _formatBytes(state.bytesReceived);
    final total = state.totalBytes > 0
        ? _formatBytes(state.totalBytes)
        : _formatBytes(kModelSizeBytes);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress > 0 ? progress : null,
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$received / $total',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '$percent%',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Baixando modelo de IA...',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Error section
// ---------------------------------------------------------------------------

class _ErrorSection extends StatelessWidget {
  const _ErrorSection({
    required this.errorMessage,
    required this.onRetry,
  });

  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  color: theme.colorScheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tentar novamente'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
        ),
      ],
    );
  }
}
