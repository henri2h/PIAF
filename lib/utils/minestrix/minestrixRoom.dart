import 'package:logging/logging.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixTypes.dart';

class MinestrixRoom {
  static final log = Logger("MinestrixRoom");

  // would have liked to extends Room type, but couldn't manage to get Down Casting to work properly...
  // initialize the class, return false, if it could not generate the classes
  // i.e, it is not a valid class

  // final variable
  late User user;
  late Room room;
  SRoomType? roomType = SRoomType.UserRoom; // by default

  Timeline? timeline;
  bool _validSRoom = false;
  bool get validSRoom => _validSRoom;

  String get name {
    if (roomType == SRoomType.UserRoom)
      return user.displayName ?? user.id;
    else {
      return room.name;
    }
  }

  String get userID => user.id;

  Uri? get avatar =>
      roomType == SRoomType.UserRoom ? user.avatarUrl : room.avatar;

  bool get isUserPage => user.id == room.client.userID;

  Future<void> loadRoomCreator(MinestrixClient sclient) async {
    Event? state = room.getState("m.room.create");

    if (state != null) {
      // get creator id from cache and if not in cache, from server
      String? creatorID = state.sender.id;

      User? u;
      // we get user id from the room participants as state.sender doesn't contains avatarUrl
      if (room.membership != Membership.invite ||
          room.historyVisibility == HistoryVisibility.worldReadable) {
        // find local on local users
        List<User> users = room.getParticipants();
        u = findUser(users, creatorID);

        if (u == null) {
          // we have not found the user but maybe we just can't preview the room
          users = await room.requestParticipants();
          u = findUser(users, creatorID);
        }
      } else if (u == null) {
        // in the case we can't request participants

        Profile p = await sclient.getProfileFromUserId(creatorID);
        u = User(creatorID,
            membership: "m.join",
            avatarUrl: p.avatarUrl.toString(),
            displayName: p.displayName,
            room: room);
      }

      assert(u !=
          null); // if we could not find the creator of the room in the members of the room. It could mean that the user creator has left the room. We should not consider it as valid.
      user = u!; // save the discovered user
    }
  }

  static Future<MinestrixRoom?> loadMinesTrixRoom(
      Room r, MinestrixClient sclient) async {
    try {
      MinestrixRoom sr = MinestrixRoom();

      // initialise room
      sr.room = r;
      sr.roomType = await getSRoomType(r);
      if (sr.roomType == null) return null;

      await sr.loadRoomCreator(sclient);

      if (sr.roomType == SRoomType.UserRoom) {
        sr._validSRoom = true;
        return sr;
      } else if (sr.roomType == SRoomType.Group) {
        sr._validSRoom = true;
        return sr;
      }
    } catch (_) {}
    return null;
  }

  static User? findUser(List<User> users, String? userId) {
    try {
      return users.firstWhere((User u) => userId == u.id);
    } catch (e) {
      // return null if no element
      print("Could not find user : " + (userId ?? 'null') + " " + e.toString());
    }
    return null;
  }

  static Future<SRoomType?> getSRoomType(Room room) async {
    Event? state = room.getState("m.room.create");

    if (state != null && state.content["type"] != null) {
      // check if it is a group or account room if not, throw null
      if (state.content["type"] == MinestrixTypes.account)
        return SRoomType.UserRoom;
      else if (state.content["type"] == MinestrixTypes.group)
        return SRoomType.Group;
    }

    return null;
  }

  Future<void> sendPost(String postContent,
      {Event? inReplyTo, MatrixImageFile? image}) async {
    Map<String, dynamic> extraContent = {
      'body': postContent,
      MinestrixTypes.post: [
        {"m.text": postContent}
      ]
    };
    if (image != null) {
      await sendFileEventWithType(image,
          type: MinestrixTypes.post,
          extraContent: extraContent,
          inReplyTo: inReplyTo);
    } else {
      await room.sendEvent(extraContent,
          type: MinestrixTypes.post, inReplyTo: inReplyTo);
    }
  }

  Future<Uri> sendFileEventWithType(
    MatrixFile file, {
    required String type,
    String? txid,
    Event? inReplyTo,
    String? editEventId,
    bool waitUntilSent = false,
    MatrixImageFile? thumbnail,
    Map<String, dynamic>? extraContent,
  }) async {
    MatrixFile uploadFile = file; // ignore: omit_local_variable_types
    MatrixFile? uploadThumbnail =
        thumbnail; // ignore: omit_local_variable_types
    EncryptedFile? encryptedFile;
    EncryptedFile? encryptedThumbnail;
    if (room.encrypted && room.client.fileEncryptionEnabled) {
      encryptedFile = await file.encrypt();
      uploadFile = encryptedFile.toMatrixFile();

      if (thumbnail != null) {
        encryptedThumbnail = await thumbnail.encrypt();
        uploadThumbnail = encryptedThumbnail.toMatrixFile();
      }
    }
    final uploadResp = await room.client.uploadContent(
      uploadFile.bytes,
      filename: uploadFile.name,
      contentType: uploadFile.mimeType,
    );
    final thumbnailUploadResp = uploadThumbnail != null
        ? await room.client.uploadContent(
            uploadThumbnail.bytes,
            filename: uploadThumbnail.name,
            contentType: uploadThumbnail.mimeType,
          )
        : null;

    // Send event
    final content = <String, dynamic>{
      'msgtype': file.msgType,
      'body': file.name,
      'filename': file.name,
      if (encryptedFile == null) 'url': uploadResp.toString(),
      if (encryptedFile != null)
        'file': {
          'url': uploadResp.toString(),
          'mimetype': file.mimeType,
          'v': 'v2',
          'key': {
            'alg': 'A256CTR',
            'ext': true,
            'k': encryptedFile.k,
            'key_ops': ['encrypt', 'decrypt'],
            'kty': 'oct'
          },
          'iv': encryptedFile.iv,
          'hashes': {'sha256': encryptedFile.sha256}
        },
      'info': {
        ...file.info,
        if (thumbnail != null && encryptedThumbnail == null)
          'thumbnail_url': thumbnailUploadResp.toString(),
        if (thumbnail != null && encryptedThumbnail != null)
          'thumbnail_file': {
            'url': thumbnailUploadResp.toString(),
            'mimetype': thumbnail.mimeType,
            'v': 'v2',
            'key': {
              'alg': 'A256CTR',
              'ext': true,
              'k': encryptedThumbnail.k,
              'key_ops': ['encrypt', 'decrypt'],
              'kty': 'oct'
            },
            'iv': encryptedThumbnail.iv,
            'hashes': {'sha256': encryptedThumbnail.sha256}
          },
        if (thumbnail != null) 'thumbnail_info': thumbnail.info,
      },
      if (extraContent != null) ...extraContent,
    };
    final sendResponse = room.sendEvent(content,
        txid: txid, inReplyTo: inReplyTo, editEventId: editEventId, type: type);
    if (waitUntilSent) {
      await sendResponse;
    }
    return uploadResp;
  }
}

enum SRoomType { UserRoom, Group }
