import 'package:flutter/material.dart';
import 'package:loveinloop/src/core/media/gift_share_service.dart';
import 'package:loveinloop/src/data/local_gift_project_repository.dart';
import 'package:loveinloop/src/domain/gift_project.dart';
import 'package:loveinloop/src/features/editor/gift_editor_screen.dart';
import 'package:loveinloop/src/features/home/gift_home_screen.dart';
import 'package:loveinloop/src/features/player/gift_player_screen.dart';

class LoveInLoopApp extends StatefulWidget {
  const LoveInLoopApp({super.key});

  @override
  State<LoveInLoopApp> createState() => _LoveInLoopAppState();
}

class _LoveInLoopAppState extends State<LoveInLoopApp> {
  final _repository = LocalGiftProjectRepository();
  final _shareService = GiftShareService();
  late Future<List<GiftProject>> _projectsFuture;

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
    const primary = Color(0xffc9184a);
    const surface = Color(0xffffffff);
    const text = Color(0xff3f2430);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LoveinLoop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          primary: primary,
          secondary: const Color(0xffff4d6d),
          tertiary: const Color(0xfff4b942),
          surface: surface,
          error: const Color(0xffa4133c),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfffff5f7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xfffff5f7),
          foregroundColor: Color(0xff4a102a),
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xff4a102a),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xffffccd8)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xff8a1538),
            minimumSize: const Size(48, 48),
            side: const BorderSide(color: primary),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xff8a1538),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xffffb3c4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xffffb3c4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xff7a2948)),
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: text,
          displayColor: const Color(0xff4a102a),
        ),
      ),
      home: FutureBuilder<List<GiftProject>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
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
                questionText: 'Quer viver essa história comigo?',
                yesMessage:
                    'Esse sim deixou tudo ainda mais especial. Eu te amo.',
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
              await _shareService.shareProject(project);
            },
          );
        },
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Icon(Icons.favorite, color: Color(0xffc9184a), size: 96),
      ),
    );
  }
}
