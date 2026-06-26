import 'dart:io';

import 'package:flutter/services.dart';
import 'package:loveinloop/src/domain/gift_project.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class GiftMediaImporter {
  static const _pickerChannel = MethodChannel('loveinloop/media_picker');

  final _recorder = AudioRecorder();
  String? _recordingPath;

  Future<List<GiftPhoto>> pickPhotos({
    required String projectId,
    required int startOrder,
  }) async {
    if (!Platform.isAndroid) {
      return [];
    }

    final paths = await _pickerChannel.invokeListMethod<String>('pickPhotos', {
      'projectId': projectId,
    });
    if (paths == null || paths.isEmpty) {
      return [];
    }

    final imported = <GiftPhoto>[];
    for (final path in paths) {
      imported.add(
        GiftPhoto(
          id: 'photo-${DateTime.now().microsecondsSinceEpoch}-${imported.length}',
          path: path,
          isAsset: false,
          order: startOrder + imported.length,
        ),
      );
    }

    return imported;
  }

  Future<GiftMusic?> pickMusic({required String projectId}) async {
    if (!Platform.isAndroid) {
      return null;
    }

    final result = await _pickerChannel.invokeMapMethod<String, String>(
      'pickMusic',
      {'projectId': projectId},
    );
    if (result == null || result['path'] == null) {
      return null;
    }

    return GiftMusic(
      type: GiftMusicType.local,
      path: result['path']!,
      title: result['name'] ?? 'Música importada',
    );
  }

  Future<bool> startVoiceRecording({required String projectId}) async {
    if (!await _recorder.hasPermission()) {
      return false;
    }

    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory(
      p.join(documents.path, 'loveinloop', projectId, 'recordings'),
    );
    await folder.create(recursive: true);

    _recordingPath = p.join(
      folder.path,
      'voice-${DateTime.now().microsecondsSinceEpoch}.m4a',
    );

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _recordingPath!,
    );
    return true;
  }

  Future<GiftMusic?> stopVoiceRecording() async {
    final path = await _recorder.stop();
    final recordedPath = path ?? _recordingPath;
    _recordingPath = null;

    if (recordedPath == null) {
      return null;
    }

    return GiftMusic(
      type: GiftMusicType.recorded,
      path: recordedPath,
      title: 'Mensagem de voz',
    );
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
