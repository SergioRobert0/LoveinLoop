import 'dart:convert';
import 'dart:io';

import 'package:loveinloop/src/domain/gift_project.dart';
import 'package:path_provider/path_provider.dart';

class LocalGiftProjectRepository {
  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}${Platform.pathSeparator}gift_projects.json');
  }

  Future<List<GiftProject>> loadProjects() async {
    final file = await _file();
    if (!await file.exists()) {
      final sample = GiftProject.sample();
      await saveProjects([sample]);
      return [sample];
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return [];
    }

    final decoded = jsonDecode(content) as List<Object?>;
    return decoded
        .cast<Map<String, Object?>>()
        .map(GiftProject.fromJson)
        .toList();
  }

  Future<void> saveProjects(List<GiftProject> projects) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final encoded = jsonEncode(
      projects.map((project) => project.toJson()).toList(),
    );
    await file.writeAsString(encoded);
  }
}
