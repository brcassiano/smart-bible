import 'package:flutter/material.dart';

import '../../../../domain/entities/verse.dart';

class VerseTile extends StatelessWidget {
  const VerseTile({
    super.key,
    required this.verse,
    this.isHighlighted = false,
    this.onTap,
    this.onLongPress,
  });

  final Verse verse;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: isHighlighted
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${verse.verse} ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [],
                ),
              ),
              TextSpan(
                text: verse.text,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
