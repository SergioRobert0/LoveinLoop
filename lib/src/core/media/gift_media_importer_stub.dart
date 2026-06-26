import 'package:loveinloop/src/domain/gift_project.dart';

class GiftMediaImporter {
  Future<List<GiftPhoto>> pickPhotos({
    required String projectId,
    required int startOrder,
  }) async {
    return [];
  }

  Future<GiftMusic?> pickMusic({required String projectId}) async {
    return null;
  }

  Future<bool> startVoiceRecording({required String projectId}) async {
    return false;
  }

  Future<GiftMusic?> stopVoiceRecording() async {
    return null;
  }

  Future<void> dispose() async {}
}
