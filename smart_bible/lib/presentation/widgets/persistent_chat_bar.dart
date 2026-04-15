import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/ai_prompts.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/ai_providers.dart';

/// Wraps app content with a persistent chat input bar at the bottom.
/// The bar is always visible. When the user sends a message, the sheet
/// expands upward to show the conversation.
class PersistentChatBar extends ConsumerStatefulWidget {
  const PersistentChatBar({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PersistentChatBar> createState() => _PersistentChatBarState();
}

class _PersistentChatBarState extends ConsumerState<PersistentChatBar> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _messagesScrollController = ScrollController();
  bool _isStreaming = false;

  static const double _collapsedSize = 0.08;
  static const double _expandedSize = 0.5;
  static const double _maxSize = 0.85;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(modelStatusNotifierProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _inputController.dispose();
    _messagesScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_messagesScrollController.hasClients) {
        _messagesScrollController.animateTo(
          _messagesScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isStreaming) return;

    final modelStatus = ref.read(modelStatusNotifierProvider);
    if (modelStatus.status != ModelStatus.ready) return;

    _inputController.clear();
    setState(() => _isStreaming = true);

    // Expand the sheet when a message is sent
    if (_sheetController.isAttached &&
        _sheetController.size < _expandedSize) {
      await _sheetController.animateTo(
        _expandedSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    await ref
        .read(chatMessagesNotifierProvider.notifier)
        .sendUserMessage(text);

    if (mounted) setState(() => _isStreaming = false);
  }

  @override
  Widget build(BuildContext context) {
    final modelStatus = ref.watch(modelStatusNotifierProvider);
    final messages = ref.watch(chatMessagesNotifierProvider);

    if (messages.isNotEmpty) _scrollToBottom();

    return Stack(
      children: [
        widget.child,
        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: _collapsedSize,
          minChildSize: _collapsedSize,
          maxChildSize: _maxSize,
          snap: true,
          snapSizes: const [_collapsedSize, _expandedSize, _maxSize],
          builder: (context, scrollController) {
            return Material(
              elevation: 8,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Column(
                children: [
                  // Drag handle
                  _DragHandle(scrollController: scrollController),
                  // Chat messages area (visible when expanded)
                  Expanded(
                    child: messages.isEmpty
                        ? _SuggestedQuestions(
                            onSelected: (q) {
                              _inputController.text = q;
                              _sendMessage(q);
                            },
                          )
                        : _MessageList(
                            messages: messages,
                            scrollController: _messagesScrollController,
                          ),
                  ),
                  // Status cards
                  if (modelStatus.status == ModelStatus.notDownloaded)
                    _ModelDownloadCard(
                      onDownload: () {
                        ref
                            .read(modelStatusNotifierProvider.notifier)
                            .startDownload()
                            .listen((_) {});
                      },
                    ),
                  if (modelStatus.status == ModelStatus.downloading)
                    _DownloadProgressBar(
                      state: modelStatus,
                      onCancel: () {
                        ref
                            .read(modelStatusNotifierProvider.notifier)
                            .cancelDownload();
                      },
                    ),
                  if (modelStatus.status == ModelStatus.error)
                    _DownloadErrorCard(
                      errorMessage: modelStatus.errorMessage ??
                          'Erro desconhecido ao carregar o modelo.',
                      onRetry: () {
                        ref
                            .read(modelStatusNotifierProvider.notifier)
                            .retryDownload();
                      },
                    ),
                  // Input bar always visible at bottom
                  _InputBar(
                    controller: _inputController,
                    isStreaming: _isStreaming,
                    modelReady: modelStatus.status == ModelStatus.ready,
                    onSend: _sendMessage,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Drag handle
// ---------------------------------------------------------------------------

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      controller: scrollController,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Suggested questions
// ---------------------------------------------------------------------------

class _SuggestedQuestions extends StatelessWidget {
  const _SuggestedQuestions({required this.onSelected});

  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.smart_toy_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Pergunte à IA sobre a Bíblia',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...suggestedQuestions.map(
            (q) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onSelected(q),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          q,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message list
// ---------------------------------------------------------------------------

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.scrollController,
  });

  final List<ChatMessage> messages;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return _MessageBubble(message: messages[index]);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == ChatRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: message.content.isEmpty
            ? _TypingIndicator(color: theme.colorScheme.onSurfaceVariant)
            : Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUser
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.color});

  final Color color;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final opacity = ((t * 3 - i) % 1.0).clamp(0.2, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: widget.color,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Model download card
// ---------------------------------------------------------------------------

class _ModelDownloadCard extends StatelessWidget {
  const _ModelDownloadCard({required this.onDownload});

  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.download_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Baixe o modelo de IA (~769 MB) para usar o assistente',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onDownload,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Baixar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Download progress bar
// ---------------------------------------------------------------------------

class _DownloadProgressBar extends StatelessWidget {
  const _DownloadProgressBar({
    required this.state,
    required this.onCancel,
  });

  final ModelStatusState state;
  final VoidCallback onCancel;

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = state.downloadProgress;
    final percent = (progress * 100).toStringAsFixed(1);
    final received = _formatBytes(state.bytesReceived);
    final total = state.totalBytes > 0
        ? _formatBytes(state.totalBytes)
        : _formatBytes(kModelSizeBytes);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Baixando modelo...', style: theme.textTheme.bodySmall),
              Row(
                children: [
                  Text('$received / $total ($percent%)',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Download error card
// ---------------------------------------------------------------------------

class _DownloadErrorCard extends StatelessWidget {
  const _DownloadErrorCard({
    required this.errorMessage,
    required this.onRetry,
  });

  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  color: theme.colorScheme.onErrorContainer, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  'Tentar novamente',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input bar
// ---------------------------------------------------------------------------

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isStreaming,
    required this.modelReady,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isStreaming;
  final bool modelReady;
  final void Function(String) onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: modelReady && !isStreaming,
                decoration: InputDecoration(
                  hintText: modelReady
                      ? 'Pergunte à IA...'
                      : 'Baixe o modelo para usar o assistente',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: onSend,
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: modelReady && !isStreaming
                  ? () => onSend(controller.text)
                  : null,
              icon: isStreaming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
