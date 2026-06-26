import 'package:flutter/material.dart';
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _HeroPanel(onCreate: onCreate),
          const SizedBox(height: 28),
          Row(
            children: [
              const Icon(Icons.favorite, color: Color(0xffc9184a), size: 20),
              const SizedBox(width: 8),
              Text(
                'Meus presentes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xff4a102a),
                ),
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
                backgroundColor: const Color(0xffa4133c),
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
          colors: [Color(0xffffe3ec), Color(0xffffb3c4)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.favorite, color: Color(0xffc9184a), size: 44),
            const SizedBox(height: 16),
            Text(
              'Prepare uma surpresa romântica',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xff4a102a),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fotos, música, mensagem e uma pergunta final em uma experiência feita para emocionar.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xff5f2438),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
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
                    color: const Color(0xffffe3ec),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.favorite, color: Color(0xffc9184a)),
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
                              color: const Color(0xff4a102a),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Para $recipient • ${project.photos.length} fotos',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xff7a2948),
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
                    foregroundColor: const Color(0xffa4133c),
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
              color: Color(0xffc9184a),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma surpresa criada ainda.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xff4a102a),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Comece criando uma experiência com fotos, música e uma mensagem especial.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xff7a2948)),
            ),
          ],
        ),
      ),
    );
  }
}
