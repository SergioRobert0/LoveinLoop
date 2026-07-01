import 'package:flutter/material.dart';
import 'package:loveinloop/src/app/loveinloop_theme.dart';
import 'package:loveinloop/src/domain/gift_project.dart';

class GiftHomeScreen extends StatelessWidget {
  const GiftHomeScreen({
    required this.projects,
    required this.onCreate,
    required this.onEdit,
    required this.onPlay,
    required this.onShare,
    required this.onDelete,
    super.key,
  });

  final List<GiftProject> projects;
  final VoidCallback onCreate;
  final ValueChanged<GiftProject> onEdit;
  final ValueChanged<GiftProject> onPlay;
  final ValueChanged<GiftProject> onShare;
  final ValueChanged<GiftProject> onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LoveinLoop')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _HeroPanel(onCreate: onCreate),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: LoveInLoopColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Surpresas criadas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: LoveInLoopColors.primaryDark,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Nova'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (projects.isEmpty)
            const _EmptyState()
          else
            ...projects.map(
              (project) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GiftProjectTile(
                  project: project,
                  onEdit: () => onEdit(project),
                  onPlay: () => onPlay(project),
                  onShare: () => onShare(project),
                  onDelete: () => _confirmDelete(context, project),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, GiftProject project) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir surpresa?'),
          content: Text(
            'A surpresa "${project.title}" será removida deste aparelho.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: LoveInLoopColors.danger,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      onDelete(project);
    }
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LoveInLoopColors.surface,
            LoveInLoopColors.surfaceMuted,
            Color(0xffffd9c7),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoveInLoopColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/logo.png', width: 48, height: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Produto digital de presentes afetivos',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: LoveInLoopColors.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Crie uma experiência pronta para emocionar',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: LoveInLoopColors.primaryDark,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Monte uma página com fotos, música, mensagens e um fechamento especial em poucos passos.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LoveInLoopColors.textMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeaturePill(icon: Icons.check_circle, label: '5 etapas'),
                _FeaturePill(icon: Icons.photo_library, label: 'Fotos e áudio'),
                _FeaturePill(icon: Icons.ios_share, label: 'Compartilhável'),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.card_giftcard),
                label: const Text('Criar surpresa'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: LoveInLoopColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: LoveInLoopColors.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: LoveInLoopColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GiftProjectTile extends StatelessWidget {
  const _GiftProjectTile({
    required this.project,
    required this.onEdit,
    required this.onPlay,
    required this.onShare,
    required this.onDelete,
  });

  final GiftProject project;
  final VoidCallback onEdit;
  final VoidCallback onPlay;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final recipient = project.recipientName.trim().isEmpty
        ? 'Pessoa especial'
        : project.recipientName.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: LoveInLoopColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: LoveInLoopColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: LoveInLoopColors.primaryDark,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Para $recipient • ${project.photos.length} fotos',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: LoveInLoopColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onPlay,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Prévia'),
                ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
                IconButton.filledTonal(
                  onPressed: onShare,
                  icon: const Icon(Icons.ios_share),
                  tooltip: 'Compartilhar',
                ),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    foregroundColor: LoveInLoopColors.danger,
                  ),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Excluir',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.favorite_border,
              color: LoveInLoopColors.primary,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma surpresa criada ainda.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: LoveInLoopColors.primaryDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Comece criando uma experiência com fotos, música e uma mensagem especial.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LoveInLoopColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
