import 'package:matrix/matrix.dart';

import '../../../../config/matrix_types.dart';

extension SocialItem on Event {
  List<String> get imagesRefEventId =>
      content.tryGetList<String>(MatrixTypes.imageRef) ?? [];

  String get postText => body;

  String? get shareEventId {
    final relation = content.tryGetMap<String, dynamic>("m.share_to");
    if (relation?["rel_type"] == MatrixTypes.shareRelation) {
      return relation?.tryGet<String>("share_event_id");
    }
    return null;
  }

  String? get shareEventRoomId {
    final relation = content.tryGetMap<String, dynamic>("m.share_to");
    if (relation?["rel_type"] == MatrixTypes.shareRelation) {
      return relation?.tryGet<String>("share_event_room_id");
    }
    return null;
  }

  Future<void> editPost(
      {required String body,
      required List<String> imagesRef,
      String? eventId}) async {
    final data = content.copy();
    data["body"] = body;
    if (imagesRef.isNotEmpty) {
      data["images_ref"] = imagesRef;
    }

    await room.sendEvent(data, type: MatrixTypes.post, editEventId: eventId);
  }
}
