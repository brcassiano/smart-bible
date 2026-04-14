import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/ai_providers.dart';
import 'ai_chat_content.dart';

/// Wraps app content with a global FAB that opens an AI chat bottom sheet.
/// The FAB is hidden when the /ai-chat full-screen route is active.
class AiChatOverlay extends ConsumerStatefulWidget {
  const AiChatOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AiChatOverlay> createState() => _AiChatOverlayState();
}

class _AiChatOverlayState extends ConsumerState<AiChatOverlay> {
  bool _sheetOpen = false;

  void _openSheet() {
    if (_sheetOpen) return;
    setState(() => _sheetOpen = true);
    ref.read(chatOverlayVisibleProvider.notifier).show();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AiChatSheet(
        onClose: () => Navigator.of(ctx).pop(),
      ),
    ).whenComplete(() {
      if (mounted) {
        setState(() => _sheetOpen = false);
        ref.read(chatOverlayVisibleProvider.notifier).hide();
      }
    });
  }

  bool _isOnAiChatRoute(BuildContext context) {
    try {
      final location = GoRouterState.of(context).uri.path;
      return location == '/ai-chat';
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnAiChatRoute = _isOnAiChatRoute(context);

    return Stack(
      children: [
        widget.child,
        if (!isOnAiChatRoute && !_sheetOpen)
          Positioned(
            right: 16,
            bottom: 24,
            child: _AiChatFab(
              modelStatus: ref.watch(modelStatusNotifierProvider),
              onTap: _openSheet,
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// FAB with model status badge
// ---------------------------------------------------------------------------

class _AiChatFab extends StatelessWidget {
  const _AiChatFab({
    required this.modelStatus,
    required this.onTap,
  });

  final ModelStatusState modelStatus;
  final VoidCallback onTap;

  Color _badgeColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (modelStatus.status) {
      ModelStatus.ready => Colors.green,
      ModelStatus.downloading => scheme.primary,
      ModelStatus.error => scheme.error,
      ModelStatus.loading => Colors.orange,
      ModelStatus.notDownloaded => Colors.orange,
    };
  }

  String? _badgeLabel() {
    if (modelStatus.status == ModelStatus.downloading) {
      final pct = (modelStatus.downloadProgress * 100).toStringAsFixed(0);
      return '$pct%';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badgeLabel();
    final badgeColor = _badgeColor(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton(
          onPressed: onTap,
          tooltip: 'Assistente IA',
          child: const Icon(Icons.smart_toy_rounded),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: badge != null
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet content
// ---------------------------------------------------------------------------

class _AiChatSheet extends StatelessWidget {
  const _AiChatSheet({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
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
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.smart_toy_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Assistente IA',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Fechar',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Chat content
              const Expanded(
                child: AiChatContent(),
              ),
            ],
          ),
        );
      },
    );
  }
}
