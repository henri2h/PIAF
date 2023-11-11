
import 'dart:convert';

import 'package:http/http.dart';
import 'package:matrix/matrix.dart';

extension SyncApi on MatrixApi {
  Future<InitialSyncUpdate> initialSync(String roomId,
      {String? filter,
      String? since,
      bool? fullState,
      PresenceType? setPresence,
      int? timeout}) async {
    final requestUri = Uri(
        path: '_matrix/client/v3/rooms/$roomId/initialSync',
        queryParameters: {
          if (filter != null) 'filter': filter,
          if (since != null) 'since': since,
          if (fullState != null) 'full_state': fullState.toString(),
          if (setPresence != null) 'set_presence': setPresence.name,
          if (timeout != null) 'timeout': timeout.toString(),
        });
    final request = Request('GET', baseUri!.resolveUri(requestUri));
    request.headers['authorization'] = 'Bearer ${bearerToken!}';
    final response = await httpClient.send(request);
    final responseBody = await response.stream.toBytes();
    if (response.statusCode != 200) unexpectedResponse(response, responseBody);
    final responseString = utf8.decode(responseBody);
    final json = jsonDecode(responseString);
    return InitialSyncUpdate.fromJson(json as Map<String, Object?>);
  }
}

class InitialSyncUpdate extends SyncRoomUpdate {
  List<BasicEvent>? accountData;
  String? membership;
  PaginationChunk? messages;
  String? roomId;
  List<MatrixEvent>? state;
  String? visibility;

  InitialSyncUpdate(
      {this.accountData,
      this.membership,
      this.roomId,
      this.state,
      this.visibility});

  InitialSyncUpdate.fromJson(Map<String, Object?> json)
      : accountData = json
            .tryGetList<Map<String, Object>>('account_data')
            ?.map((i) => BasicEvent.fromJson(i))
            .toList(),
        membership = json.tryGet<String>('membership'),
        messages = json.tryGetFromJson('messages', PaginationChunk.fromJson),
        roomId = json.tryGet<String>('roomId'),
        state = json
            .tryGetList<Object?>('state')
            ?.map((i) => MatrixEvent.fromJson(i as Map<String, Object?>))
            .toList(),
        visibility = json.tryGet<String>('visibility');
}

class PaginationChunk extends SyncRoomUpdate {
  List<MatrixEvent>? chunk;
  String? end;
  String? start;

  PaginationChunk({this.chunk, this.end, this.start});

  PaginationChunk.fromJson(Map<String, Object?> json)
      : chunk = json
            .tryGetList<Map<String, Object?>>('chunk')
            ?.map((i) => MatrixEvent.fromJson(i))
            .toList(),
        end = json.tryGet<String>('end'),
        start = json.tryGet<String>('start');
}
