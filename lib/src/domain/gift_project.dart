enum GiftPlan { free, premium, vip }

enum GiftMusicType { asset, local, recorded }

class GiftPhoto {
  const GiftPhoto({
    required this.id,
    required this.path,
    required this.isAsset,
    required this.order,
    this.caption = '',
  });

  final String id;
  final String path;
  final bool isAsset;
  final int order;
  final String caption;

  GiftPhoto copyWith({
    String? id,
    String? path,
    bool? isAsset,
    int? order,
    String? caption,
  }) {
    return GiftPhoto(
      id: id ?? this.id,
      path: path ?? this.path,
      isAsset: isAsset ?? this.isAsset,
      order: order ?? this.order,
      caption: caption ?? this.caption,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'path': path,
      'isAsset': isAsset,
      'order': order,
      'caption': caption,
    };
  }

  factory GiftPhoto.fromJson(Map<String, Object?> json) {
    return GiftPhoto(
      id: json['id'] as String,
      path: json['path'] as String,
      isAsset: json['isAsset'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
      caption: json['caption'] as String? ?? '',
    );
  }
}

class GiftMusic {
  const GiftMusic({
    required this.type,
    required this.path,
    required this.title,
  });

  final GiftMusicType type;
  final String path;
  final String title;

  Map<String, Object?> toJson() {
    return {'type': type.name, 'path': path, 'title': title};
  }

  factory GiftMusic.fromJson(Map<String, Object?> json) {
    return GiftMusic(
      type: GiftMusicType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => GiftMusicType.asset,
      ),
      path: json['path'] as String? ?? 'music.mp3',
      title: json['title'] as String? ?? 'Trilha LoveinLoop',
    );
  }
}

class GiftProject {
  const GiftProject({
    required this.id,
    required this.title,
    required this.creatorName,
    required this.recipientName,
    required this.openingMessage,
    required this.questionText,
    required this.yesMessage,
    required this.photos,
    required this.music,
    required this.themeId,
    required this.plan,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String creatorName;
  final String recipientName;
  final String openingMessage;
  final String questionText;
  final String yesMessage;
  final List<GiftPhoto> photos;
  final GiftMusic music;
  final String themeId;
  final GiftPlan plan;
  final DateTime createdAt;
  final DateTime updatedAt;

  List<GiftPhoto> get orderedPhotos {
    final sorted = List<GiftPhoto>.from(photos);
    sorted.sort((left, right) => left.order.compareTo(right.order));
    return sorted;
  }

  bool get isFreePlan => plan == GiftPlan.free;

  GiftProject copyWith({
    String? id,
    String? title,
    String? creatorName,
    String? recipientName,
    String? openingMessage,
    String? questionText,
    String? yesMessage,
    List<GiftPhoto>? photos,
    GiftMusic? music,
    String? themeId,
    GiftPlan? plan,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GiftProject(
      id: id ?? this.id,
      title: title ?? this.title,
      creatorName: creatorName ?? this.creatorName,
      recipientName: recipientName ?? this.recipientName,
      openingMessage: openingMessage ?? this.openingMessage,
      questionText: questionText ?? this.questionText,
      yesMessage: yesMessage ?? this.yesMessage,
      photos: photos ?? this.photos,
      music: music ?? this.music,
      themeId: themeId ?? this.themeId,
      plan: plan ?? this.plan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'creatorName': creatorName,
      'recipientName': recipientName,
      'openingMessage': openingMessage,
      'questionText': questionText,
      'yesMessage': yesMessage,
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'music': music.toJson(),
      'themeId': themeId,
      'plan': plan.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GiftProject.fromJson(Map<String, Object?> json) {
    return GiftProject(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Meu presente',
      creatorName: json['creatorName'] as String? ?? '',
      recipientName: json['recipientName'] as String? ?? '',
      openingMessage: json['openingMessage'] as String? ?? '',
      questionText: json['questionText'] as String? ?? '',
      yesMessage: json['yesMessage'] as String? ?? '',
      photos: ((json['photos'] as List<Object?>?) ?? const [])
          .cast<Map<String, Object?>>()
          .map(GiftPhoto.fromJson)
          .toList(),
      music: GiftMusic.fromJson(
        (json['music'] as Map<String, Object?>?) ?? const {},
      ),
      themeId: json['themeId'] as String? ?? 'classic_rose',
      plan: GiftPlan.values.firstWhere(
        (plan) => plan.name == json['plan'],
        orElse: () => GiftPlan.free,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory GiftProject.sample() {
    final now = DateTime.now();
    final photos = _defaultAssetPhotos
        .asMap()
        .entries
        .map(
          (entry) => GiftPhoto(
            id: 'sample_photo_${entry.key + 1}',
            path: entry.value,
            isAsset: true,
            order: entry.key,
          ),
        )
        .toList();

    return GiftProject(
      id: 'sample-${now.microsecondsSinceEpoch}',
      title: 'Surpresa romântica',
      creatorName: 'Sérgio',
      recipientName: 'Letícia',
      openingMessage: 'Preparei uma surpresa com alguns dos nossos momentos.',
      questionText: 'Quer namorar comigo mais uma vez?',
      yesMessage: 'Eu te amo e quero continuar descobrindo a vida ao seu lado.',
      photos: photos,
      music: const GiftMusic(
        type: GiftMusicType.asset,
        path: 'music.mp3',
        title: 'Trilha LoveinLoop',
      ),
      themeId: 'classic_rose',
      plan: GiftPlan.free,
      createdAt: now,
      updatedAt: now,
    );
  }
}

const _defaultAssetPhotos = [
  'assets/image1.jpeg',
  'assets/image2.jpeg',
  'assets/image3.jpeg',
  'assets/image4.jpg',
  'assets/image5.jpg',
  'assets/image6.jpg',
  'assets/image7.jpg',
  'assets/image8.jpg',
  'assets/image9.jpg',
  'assets/image10.jpg',
  'assets/image11.jpg',
  'assets/image12.jpg',
];
