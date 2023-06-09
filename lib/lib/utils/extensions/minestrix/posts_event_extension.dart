import 'package:matrix/matrix.dart';

import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/utils/extensions/matrix/event_extension.dart';

extension PostsEventExtension on Event {
  /// Fetches the event to be rendered, taking into account all the edits and the like.
  /// It needs a [timeline] for that.
  Event getDisplayPostEvent(Timeline timeline) =>
      getDisplayEventWithType(timeline, MatrixTypes.post);

  Set<Event>? getReactions(Timeline t) =>
      aggregatedEvents(t, RelationshipTypes.reaction)
          .where((e) => !e.redacted)
          .toSet();

  Set<Event>? getReplies(Timeline t) {
    Set<Event>? events = aggregatedEvents(t, MatrixTypes.threadRelation);
    events.addAll(aggregatedEvents(t, RelationshipTypes.reply).where(
        (element) =>
            element.content
                .tryGet<Map<String, dynamic>>('m.relates_to')
                ?.tryGet<String>('rel_type') ==
            MatrixTypes.threadRelation));
    return events.where((e) => !e.redacted).toSet();
  }

  Map<Event, dynamic>? constructNestedReplies(
      Set<Event> data, String? eventId, int depth) {
    final nestedReplies = <Event, dynamic>{};

    if (depth > 50) {
      return null;
      // Arbitrary limit to prevent too much recursion
    }

    int pos = 0;

    while (pos < data.length) {
      final event = data.elementAt(pos);

      String? val = event.content
          .tryGetMap<String, dynamic>("m.relates_to")
          ?.tryGetMap<String, dynamic>("m.in_reply_to")
          ?.tryGet<String>("event_id");

      if (val == eventId) {
        data.remove(event);
        nestedReplies[event] =
            constructNestedReplies(data, event.eventId, depth++);
      } else {
        pos++;
      }
    }

    return nestedReplies.isNotEmpty ? nestedReplies : null;
  }

  /// Get all the related event with this event
  Map<Event, dynamic>? getNestedReplies(Set<Event> replies) {
    return {
      ...(constructNestedReplies(replies.toSet(), eventId, 0) ?? {}),
      ...(constructNestedReplies(replies.toSet(), null, 0) ?? {})
    };
  }
}

extension PostEventInRoomExtension on Room {
  Iterable<Event> getPosts(Timeline t,
      {List<String> eventTypesFilter = const [
        MatrixTypes.post,
        EventTypes.Encrypted
      ]}) {
    List<Event> filteredEvents = t.events
        .where((e) =>
            !{
              RelationshipTypes.edit,
              RelationshipTypes.reaction,
              RelationshipTypes.reply,
              MatrixTypes.threadRelation
            }.contains(e.relationshipType) &&
            eventTypesFilter.contains(e.type) &&
            !e.redacted)
        .toList();
    for (var i = 0; i < filteredEvents.length; i++) {
      filteredEvents[i] = filteredEvents[i].getDisplayEvent(t);
    }
    return filteredEvents;
  }

  Future<String?> sendSocialPost(
      {required String content,
      List<String>? imagesRef,
      Event? shareEvent}) async {
    Map<String, dynamic> data = {
      "body": content,
      if (imagesRef?.isNotEmpty ?? false) MatrixTypes.imageRef: imagesRef
    };
    if (shareEvent != null) {
      data.addAll({
        "m.share_to": {
          "rel_type": MatrixTypes.shareRelation,
          "share_event_id": shareEvent.eventId,
          "share_event_room_id": shareEvent.roomId,
        }
      });
    }
    return await sendEvent(data, type: MatrixTypes.post);
  }

  /// Allow sending a comment for the post [post] and optionally setting the
  /// comment we would like to reply to for this specific post using [replyTo]
  Future<String?> commentPost(
      {required String content, required Event post, Event? replyTo}) async {
    final result = {
      "body": content,
      "m.relates_to": {
        "rel_type": MatrixTypes.threadRelation,
        "event_id": post.eventId,
        "m.in_reply_to": {if (replyTo != null) "event_id": replyTo.eventId}
      }
    };

    return await sendEvent(result, type: MatrixTypes.comment);
  }
}
