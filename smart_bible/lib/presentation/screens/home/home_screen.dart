import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Bible')),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Bem-vindo ao Smart Bible',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Estudo bíblico inteligente com IA local',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _FeatureCard(
                icon: Icons.auto_stories_rounded,
                title: 'Leitor Bíblico',
                description: 'Leia e navegue pela Bíblia com múltiplas traduções',
                color: theme.colorScheme.primaryContainer,
                onTap: () => context.go('/reader'),
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.translate_rounded,
                title: 'Estudo de Palavras',
                description: 'Explore palavras originais com o Léxico de Strong',
                color: theme.colorScheme.secondaryContainer,
                onTap: () => context.go('/word-study'),
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.smart_toy_rounded,
                title: 'Assistente IA',
                description: 'Converse com IA local para aprofundar seus estudos',
                color: theme.colorScheme.tertiaryContainer,
                onTap: () => context.go('/ai-chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.onSurface),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
