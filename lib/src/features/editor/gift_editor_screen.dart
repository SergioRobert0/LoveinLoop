import 'package:flutter/material.dart';
import 'package:loveinloop/src/core/media/gift_media_importer.dart';
import 'package:loveinloop/src/domain/gift_project.dart';
import 'package:loveinloop/src/shared/widgets/gift_image.dart';

class GiftEditorScreen extends StatefulWidget {
  const GiftEditorScreen({required this.project, super.key});

  final GiftProject project;

  @override
  State<GiftEditorScreen> createState() => _GiftEditorScreenState();
}

class _GiftEditorScreenState extends State<GiftEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mediaImporter = GiftMediaImporter();
  late final TextEditingController _title;
  late final TextEditingController _creatorName;
  late final TextEditingController _recipientName;
  late final TextEditingController _openingMessage;
  late final TextEditingController _questionText;
  late final TextEditingController _yesMessage;
  late List<GiftPhoto> _photos;
  late GiftMusic _music;
  var _currentStep = 0;
  var _isImportingMedia = false;
  var _isRecordingVoice = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.project.title);
    _creatorName = TextEditingController(text: widget.project.creatorName);
    _recipientName = TextEditingController(text: widget.project.recipientName);
    _openingMessage = TextEditingController(
      text: widget.project.openingMessage,
    );
    _questionText = TextEditingController(text: widget.project.questionText);
    _yesMessage = TextEditingController(text: widget.project.yesMessage);
    _photos = List<GiftPhoto>.from(widget.project.orderedPhotos);
    _music = widget.project.music;
  }

  @override
  void dispose() {
    _title.dispose();
    _creatorName.dispose();
    _recipientName.dispose();
    _openingMessage.dispose();
    _questionText.dispose();
    _yesMessage.dispose();
    _mediaImporter.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    setState(() => _isImportingMedia = true);
    try {
      final photos = await _mediaImporter.pickPhotos(
        projectId: widget.project.id,
        startOrder: _photos.length,
      );
      if (!mounted || photos.isEmpty) {
        return;
      }
      setState(() {
        _photos = [..._photos, ...photos];
      });
    } finally {
      if (mounted) {
        setState(() => _isImportingMedia = false);
      }
    }
  }

  Future<void> _pickMusic() async {
    setState(() => _isImportingMedia = true);
    try {
      final music = await _mediaImporter.pickMusic(
        projectId: widget.project.id,
      );
      if (!mounted || music == null) {
        return;
      }
      setState(() {
        _music = music;
      });
    } finally {
      if (mounted) {
        setState(() => _isImportingMedia = false);
      }
    }
  }

  Future<void> _toggleVoiceRecording() async {
    if (_isRecordingVoice) {
      final music = await _mediaImporter.stopVoiceRecording();
      if (!mounted) {
        return;
      }
      setState(() {
        _isRecordingVoice = false;
        if (music != null) {
          _music = music;
        }
      });
      return;
    }

    final started = await _mediaImporter.startVoiceRecording(
      projectId: widget.project.id,
    );
    if (!mounted) {
      return;
    }
    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível acessar o microfone.')),
      );
      return;
    }

    setState(() => _isRecordingVoice = true);
  }

  void _removePhoto(GiftPhoto photo) {
    setState(() {
      _photos = _photos.where((item) => item.id != photo.id).toList();
    });
  }

  void _nextStep() {
    if (_currentStep == 0 && !_formKey.currentState!.validate()) {
      return;
    }

    if (_currentStep < 4) {
      setState(() => _currentStep += 1);
      return;
    }

    _save();
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _currentStep = 0);
      return;
    }

    final saved = widget.project.copyWith(
      title: _title.text.trim(),
      creatorName: _creatorName.text.trim(),
      recipientName: _recipientName.text.trim(),
      openingMessage: _openingMessage.text.trim(),
      questionText: _questionText.text.trim(),
      yesMessage: _yesMessage.text.trim(),
      photos: _photos
          .asMap()
          .entries
          .map((entry) => entry.value.copyWith(order: entry.key))
          .toList(),
      music: _music,
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final stepNumber = _currentStep + 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preparar surpresa'),
        actions: [TextButton(onPressed: _save, child: const Text('Salvar'))],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _ProgressHeader(stepNumber: stepNumber),
            Expanded(
              child: Stepper(
                currentStep: _currentStep,
                margin: EdgeInsets.zero,
                onStepTapped: (step) => setState(() => _currentStep = step),
                onStepContinue: _nextStep,
                onStepCancel: _previousStep,
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: details.onStepContinue,
                            child: Text(
                              _currentStep == 4
                                  ? 'Salvar surpresa ❤️'
                                  : 'Próximo ❤️',
                            ),
                          ),
                        ),
                        if (_currentStep > 0) ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: details.onStepCancel,
                            child: const Text('Voltar'),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                steps: [
                  Step(
                    title: const Text('Nomes de vocês'),
                    subtitle: const Text('Quem cria e quem recebe'),
                    isActive: _currentStep >= 0,
                    content: Column(
                      children: [
                        _TextField(
                          controller: _title,
                          label: 'Nome da surpresa',
                          icon: Icons.card_giftcard,
                          required: true,
                        ),
                        _TextField(
                          controller: _creatorName,
                          label: 'Seu nome',
                          icon: Icons.person,
                        ),
                        _TextField(
                          controller: _recipientName,
                          label: 'Nome de quem vai receber',
                          icon: Icons.favorite,
                          required: true,
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Fotos'),
                    subtitle: Text('${_photos.length} selecionadas'),
                    isActive: _currentStep >= 1,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Escolha as memórias que vão aparecer no carrossel.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isImportingMedia ? null : _addPhotos,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Adicionar fotos'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PhotoPreview(photos: _photos, onRemove: _removePhoto),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Música'),
                    subtitle: Text(_music.title),
                    isActive: _currentStep >= 2,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Use a trilha padrão, escolha um áudio ou grave uma voz.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        _MusicTile(music: _music),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: _isImportingMedia ? null : _pickMusic,
                              icon: const Icon(Icons.library_music),
                              label: const Text('Escolher música'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _music = const GiftMusic(
                                    type: GiftMusicType.asset,
                                    path: 'music.mp3',
                                    title: 'Trilha LoveinLoop',
                                  );
                                });
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Usar padrão'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _toggleVoiceRecording,
                              icon: Icon(
                                _isRecordingVoice ? Icons.stop : Icons.mic,
                              ),
                              label: Text(
                                _isRecordingVoice
                                    ? 'Parar gravação'
                                    : 'Gravar voz',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Mensagens'),
                    subtitle: const Text('Abertura e pergunta final'),
                    isActive: _currentStep >= 3,
                    content: Column(
                      children: [
                        _TextField(
                          controller: _openingMessage,
                          label: 'Mensagem de abertura',
                          icon: Icons.mail,
                          maxLines: 3,
                          required: true,
                        ),
                        _TextField(
                          controller: _questionText,
                          label: 'Pergunta final',
                          icon: Icons.favorite,
                          maxLines: 2,
                          required: true,
                        ),
                        _TextField(
                          controller: _yesMessage,
                          label: 'Mensagem depois do SIM',
                          icon: Icons.celebration,
                          maxLines: 4,
                          required: true,
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Tudo pronto?'),
                    subtitle: const Text('Confira antes de salvar'),
                    isActive: _currentStep >= 4,
                    content: _ReviewStep(
                      title: _title.text,
                      recipientName: _recipientName.text,
                      photos: _photos,
                      musicTitle: _music.title,
                      questionText: _questionText.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.stepNumber});

  final int stepNumber;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Etapa $stepNumber de 5',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xff8a1538),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: stepNumber / 5,
              minHeight: 8,
              backgroundColor: const Color(0xffffccd8),
              color: const Color(0xffc9184a),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.required = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xffc9184a)),
          labelText: label,
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Preencha este campo para continuar.';
                }
                return null;
              }
            : null,
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photos, required this.onRemove});

  final List<GiftPhoto> photos;
  final ValueChanged<GiftPhoto> onRemove;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.photo_library, color: Color(0xffc9184a)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nenhuma foto selecionada ainda.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final photo = photos[index];
          return Stack(
            children: [
              GiftImage(photo: photo, width: 82, height: 112),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton.filled(
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  onPressed: () => onRemove(photo),
                  icon: const Icon(Icons.close),
                  tooltip: 'Remover foto',
                ),
              ),
            ],
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: photos.length,
      ),
    );
  }
}

class _MusicTile extends StatelessWidget {
  const _MusicTile({required this.music});

  final GiftMusic music;

  @override
  Widget build(BuildContext context) {
    final subtitle = music.type == GiftMusicType.asset
        ? 'Trilha incluída no app'
        : music.type == GiftMusicType.recorded
        ? 'Mensagem gravada no app'
        : 'Arquivo local importado';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.music_note, color: Color(0xffc9184a)),
        title: Text(music.title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.title,
    required this.recipientName,
    required this.photos,
    required this.musicTitle,
    required this.questionText,
  });

  final String title;
  final String recipientName;
  final List<GiftPhoto> photos;
  final String musicTitle;
  final String questionText;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo da surpresa ❤️',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xff4a102a),
              ),
            ),
            const SizedBox(height: 12),
            if (photos.isNotEmpty) ...[
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return GiftImage(
                      photo: photos[index],
                      width: 56,
                      height: 72,
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemCount: photos.length > 6 ? 6 : photos.length,
                ),
              ),
              const SizedBox(height: 12),
            ],
            _ReviewRow(label: 'Presente', value: title),
            _ReviewRow(label: 'Para', value: recipientName),
            _ReviewRow(label: 'Fotos', value: '${photos.length}'),
            _ReviewRow(label: 'Música', value: musicTitle),
            _ReviewRow(label: 'Pergunta', value: questionText),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = value.trim().isEmpty ? 'Não informado' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xff3f2430),
            height: 1.35,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}
