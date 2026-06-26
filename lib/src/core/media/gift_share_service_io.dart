import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
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

    if (project.music.type != GiftMusicType.asset) {
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

  Future<void> shareProject(GiftProject project) async {
    final file = await exportProject(project);
    if (!Platform.isAndroid) {
      return;
    }

    await _shareChannel.invokeMethod('shareFile', {
      'path': file.path,
      'subject': 'Presente LoveinLoop',
      'text':
          'Preparei uma surpresa interativa no LoveinLoop. Guarde este pacote para abrir no app.',
    });
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
