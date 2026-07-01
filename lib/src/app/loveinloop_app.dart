import 'package:flutter/material.dart';
import 'package:loveinloop/src/app/loveinloop_theme.dart';
import 'package:loveinloop/src/core/media/gift_share_service.dart';
import 'package:loveinloop/src/data/local_gift_project_repository.dart';
import 'package:loveinloop/src/domain/gift_project.dart';
import 'package:loveinloop/src/features/editor/gift_editor_screen.dart';
import 'package:loveinloop/src/features/home/gift_home_screen.dart';
import 'package:loveinloop/src/features/player/gift_player_screen.dart';
import 'package:loveinloop/src/features/splash/loveinloop_splash_screen.dart';

class LoveInLoopApp extends StatefulWidget {
  const LoveInLoopApp({super.key});

  @override
  State<LoveInLoopApp> createState() => _LoveInLoopAppState();
}

class _LoveInLoopAppState extends State<LoveInLoopApp> {
  final _repository = LocalGiftProjectRepository();
  final _shareService = GiftShareService();
  late Future<List<GiftProject>> _projectsFuture;
  var _showSplash = true;

  @override
  void initState() {
    super.initState();
    _projectsFuture = _repository.loadProjects();
  }

  Future<void> _saveProjects(List<GiftProject> projects) async {
    await _repository.saveProjects(projects);
    setState(() {
      _projectsFuture = Future.value(projects);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LoveinLoop',
      theme: buildLoveInLoopTheme(),
      home: FutureBuilder<List<GiftProject>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (_showSplash) {
            return LoveInLoopSplashScreen(
              isReady: snapshot.hasData,
              onFinished: () => setState(() => _showSplash = false),
            );
          }

          if (!snapshot.hasData) {
            return const _LoadingScreen();
          }

          final projects = snapshot.data!;
          return GiftHomeScreen(
            projects: projects,
            onCreate: () async {
              final sample = GiftProject.sample();
              final newProject = sample.copyWith(
                id: 'gift-${DateTime.now().microsecondsSinceEpoch}',
                title: 'Nova surpresa',
                creatorName: '',
                recipientName: '',
                openingMessage:
                    'Preparei uma surpresa com alguns dos nossos momentos.',
                questionText:
                    'Posso te mostrar o quanto você é especial para mim?',
                yesMessage:
                    'Obrigado por fazer parte da minha vida de um jeito tão bonito.',
                photos: sample.photos.take(5).toList(),
              );

              final saved = await Navigator.of(context).push<GiftProject>(
                MaterialPageRoute(
                  builder: (_) => GiftEditorScreen(project: newProject),
                ),
              );

              if (saved != null) {
                await _saveProjects([saved, ...projects]);
              }
            },
            onEdit: (project) async {
              final saved = await Navigator.of(context).push<GiftProject>(
                MaterialPageRoute(
                  builder: (_) => GiftEditorScreen(project: project),
                ),
              );

              if (saved != null) {
                final updated = projects
                    .map((item) => item.id == saved.id ? saved : item)
                    .toList();
                await _saveProjects(updated);
              }
            },
            onPlay: (project) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GiftPlayerScreen(project: project),
                ),
              );
            },
            onShare: (project) async {
              await _shareProject(context, project);
            },
            onDelete: (project) async {
              final updated = projects
                  .where((item) => item.id != project.id)
                  .toList();
              await _saveProjects(updated);
            },
          );
        },
      ),
    );
  }

  Future<void> _shareProject(BuildContext context, GiftProject project) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(width: 16),
              Expanded(child: Text('Gerando vídeo rápido...')),
            ],
          ),
        );
      },
    );

    try {
      final result = await _shareService.shareProject(project);
      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compartilhamento indisponível nesta plataforma.'),
          ),
        );
        return;
      }

      final message = result.openedShareSheet
          ? result.isVideo
                ? 'Vídeo pronto. Escolha onde compartilhar.'
                : 'Pacote exportado. Escolha onde compartilhar.'
          : 'Arquivo gerado, mas o compartilhamento nativo não abriu. Reinstale o app e tente novamente.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível compartilhar: $error')),
      );
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Icon(Icons.favorite, color: LoveInLoopColors.primary, size: 96),
      ),
    );
  }
}
