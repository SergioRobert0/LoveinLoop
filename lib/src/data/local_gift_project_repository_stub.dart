import 'package:loveinloop/src/domain/gift_project.dart';

class LocalGiftProjectRepository {
  List<GiftProject>? _projects;

  Future<List<GiftProject>> loadProjects() async {
    _projects ??= [GiftProject.sample()];
    return List<GiftProject>.from(_projects!);
  }

  Future<void> saveProjects(List<GiftProject> projects) async {
    _projects = List<GiftProject>.from(projects);
  }
}
