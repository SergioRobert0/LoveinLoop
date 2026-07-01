import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:loveinloop/src/core/media/gift_share_result.dart';
import 'package:loveinloop/src/domain/gift_project.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class GiftShareService {
  static const _shareChannel = MethodChannel('loveinloop/share');

  Future<File> exportProject(GiftProject project) async {
    final exports = await _exportsDirectory();
    final safeTitle = project.title
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp('^-|-\$'), '');
    final fileName = '${safeTitle.isEmpty ? 'presente' : safeTitle}.loveinloop';
    final file = File(p.join(exports.path, fileName));
    final archive = Archive();
    const encoder = JsonEncoder.withIndent('  ');

    archive.addFile(
      ArchiveFile.string('project.json', encoder.convert(project.toJson())),
    );

    for (final photo in project.photos.where((photo) => !photo.isAsset)) {
      final mediaFile = File(photo.path);
      if (await mediaFile.exists()) {
        archive.addFile(
          ArchiveFile(
            'media/photos/${p.basename(photo.path)}',
            await mediaFile.length(),
            await mediaFile.readAsBytes(),
          ),
        );
      }
    }

    if (project.music.type != GiftMusicType.asset &&
        project.music.type != GiftMusicType.none) {
      final musicFile = File(project.music.path);
      if (await musicFile.exists()) {
        archive.addFile(
          ArchiveFile(
            'media/music/${p.basename(project.music.path)}',
            await musicFile.length(),
            await musicFile.readAsBytes(),
          ),
        );
      }
    }

    await file.writeAsBytes(ZipEncoder().encode(archive));
    return file;
  }

  Future<GiftShareResult> shareProject(GiftProject project) async {
    if (!Platform.isAndroid) {
      final file = await exportProject(project);
      return GiftShareResult(
        path: file.path,
        openedShareSheet: false,
        isVideo: false,
      );
    }

    final videoPath = await _tryCreateVideo(project);
    final file = videoPath == null
        ? await exportProject(project)
        : File(videoPath);
    final isVideo = videoPath != null;
    final openedShareSheet = await _tryOpenShareSheet(file, isVideo: isVideo);

    return GiftShareResult(
      path: file.path,
      openedShareSheet: openedShareSheet,
      isVideo: isVideo,
    );
  }

  Future<String?> _tryCreateVideo(GiftProject project) async {
    try {
      return await _shareChannel.invokeMethod<String>(
        'createShareVideo',
        project.toJson(),
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<bool> _tryOpenShareSheet(File file, {required bool isVideo}) async {
    try {
      await _shareChannel.invokeMethod<void>('shareFile', {
        'path': file.path,
        'mimeType': isVideo ? 'video/mp4' : 'application/octet-stream',
        'subject': 'Surpresa LoveinLoop',
        'text':
            'Preparei uma surpresa em vídeo no LoveinLoop. Assista até o final e me responda.',
      });
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<Directory> _exportsDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      p.join(documents.path, 'loveinloop', 'exports'),
    );
    await directory.create(recursive: true);
    return directory;
  }
}
