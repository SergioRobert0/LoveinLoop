import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:loveinloop/src/app/loveinloop_theme.dart';
import 'package:loveinloop/src/domain/gift_project.dart';
import 'package:loveinloop/src/shared/widgets/gift_image.dart';

class GiftPlayerScreen extends StatefulWidget {
  const GiftPlayerScreen({required this.project, super.key});

  final GiftProject project;

  @override
  State<GiftPlayerScreen> createState() => _GiftPlayerScreenState();
}

class _GiftPlayerScreenState extends State<GiftPlayerScreen> {
  final _player = AudioPlayer();
  int _step = 0;

  @override
  void initState() {
    super.initState();
    if (widget.project.music.type == GiftMusicType.asset) {
      _player.play(AssetSource(widget.project.music.path));
    } else if (widget.project.music.type == GiftMusicType.local ||
        widget.project.music.type == GiftMusicType.recorded) {
      _player.play(DeviceFileSource(widget.project.music.path));
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _OpeningStep(
        project: widget.project,
        onNext: () => setState(() => _step = 1),
      ),
      _CarouselStep(
        project: widget.project,
        onNext: () => setState(() => _step = 2),
      ),
      _FinalStep(project: widget.project),
    ];

    return Scaffold(
      body: _RomanticBackground(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          child: screens[_step],
        ),
      ),
    );
  }
}

class _RomanticBackground extends StatelessWidget {
  const _RomanticBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LoveInLoopColors.background,
            LoveInLoopColors.surfaceMuted,
            Color(0xffffd9c7),
          ],
        ),
      ),
      child: child,
    );
  }
}

class _OpeningStep extends StatelessWidget {
  const _OpeningStep({required this.project, required this.onNext});

  final GiftProject project;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final creator = project.creatorName.trim();
    final recipient = project.recipientName.trim();
    final names = creator.isEmpty ? recipient : '$creator e $recipient';

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 116,
                height: 116,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x26be123c),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  color: LoveInLoopColors.primary,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                names,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: LoveInLoopColors.primaryDark,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                project.openingMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LoveInLoopColors.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onNext,
                  icon: const Icon(Icons.favorite),
                  label: const Text('Ver nossos momentos'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarouselStep extends StatefulWidget {
  const _CarouselStep({required this.project, required this.onNext});

  final GiftProject project;
  final VoidCallback onNext;

  @override
  State<_CarouselStep> createState() => _CarouselStepState();
}

class _CarouselStepState extends State<_CarouselStep> {
  var _currentPhoto = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.project.orderedPhotos;

    if (photos.isEmpty) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.photo_library_outlined,
                color: LoveInLoopColors.primary,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma foto foi adicionada',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: LoveInLoopColors.primaryDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A surpresa pode continuar com a mensagem e o fechamento.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LoveInLoopColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.onNext,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continuar'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Stack(
        children: [
          Center(
            child: CarouselSlider(
              options: CarouselOptions(
                height: 430,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 3),
                enlargeCenterPage: true,
                viewportFraction: 0.82,
                onPageChanged: (index, reason) {
                  setState(() => _currentPhoto = index);
                },
              ),
              items: photos.map((photo) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: GiftImage(
                    photo: photo,
                    width: MediaQuery.of(context).size.width * 0.82,
                    height: 430,
                    borderRadius: 8,
                  ),
                );
              }).toList(),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 98,
            child: _PhotoDots(count: photos.length, current: _currentPhoto),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: FilledButton.icon(
              onPressed: widget.onNext,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continuar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoDots extends StatelessWidget {
  const _PhotoDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final visibleCount = count > 10 ? 10 : count;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(visibleCount, (index) {
        final active = index == current.clamp(0, visibleCount - 1);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: active ? 22 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? LoveInLoopColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _FinalStep extends StatefulWidget {
  const _FinalStep({required this.project});

  final GiftProject project;

  @override
  State<_FinalStep> createState() => _FinalStepState();
}

class _FinalStepState extends State<_FinalStep> {
  var _showText = false;
  var _hearts = <Widget>[];

  void _revealMessage() {
    final size = MediaQuery.of(context).size;
    setState(() {
      _showText = true;
      _hearts = List.generate(18, (index) {
        return _HeartParticle(
          key: ValueKey(index),
          left: (index / 18) * size.width,
          screenHeight: size.height,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          if (!_showText)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.project.questionText,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: LoveInLoopColors.primaryDark,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                    ),
                    const SizedBox(height: 42),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _revealMessage,
                        icon: const Icon(Icons.mail),
                        label: const Text('Abrir mensagem'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_showText)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: _FinalMessageCard(message: widget.project.yesMessage),
              ),
            ),
          ..._hearts,
        ],
      ),
    );
  }
}

class _FinalMessageCard extends StatelessWidget {
  const _FinalMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x55ffffff), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x334c1024),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: LoveInLoopColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite,
                color: LoveInLoopColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Mensagem final',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: LoveInLoopColors.accent,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 58,
              height: 3,
              decoration: BoxDecoration(
                color: LoveInLoopColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: LoveInLoopColors.primaryDark,
                fontWeight: FontWeight.w900,
                height: 1.28,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Feito com LoveinLoop',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: LoveInLoopColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeartParticle extends StatefulWidget {
  const _HeartParticle({
    required this.left,
    required this.screenHeight,
    super.key,
  });

  final double left;
  final double screenHeight;

  @override
  State<_HeartParticle> createState() => _HeartParticleState();
}

class _HeartParticleState extends State<_HeartParticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _topAnimation;
  late final Animation<double> _opacityAnimation;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2 + _random.nextInt(2)),
      vsync: this,
    );
    _topAnimation = Tween<double>(
      begin: widget.screenHeight - 100,
      end: widget.screenHeight / 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacityAnimation = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
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
      builder: (context, child) {
        return Positioned(
          top: _topAnimation.value,
          left: widget.left,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Icon(
              Icons.favorite,
              color: LoveInLoopColors.primary,
              size: 30 + _random.nextDouble() * 20,
            ),
          ),
        );
      },
    );
  }
}
