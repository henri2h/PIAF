import 'dart:convert';

import 'package:matrix/matrix.dart';

import 'package:http/http.dart' as http;

extension MutualRooms on Client {
  Future<List<String>?> getMutualRoomsWithUser(String userID) async {
    final requestUri = Uri(
        path: '_matrix/client/unstable/uk.half-shot.msc2666/user/mutual_rooms',
        queryParameters: {"user_id": userID});
    final request = http.Request('GET', baseUri!.resolveUri(requestUri));
    request.headers['authorization'] = 'Bearer ${bearerToken!}';
    final response = await httpClient.send(request);
    final responseBody = await response.stream.toBytes();
    if (response.statusCode != 200) {
      unexpectedResponse(response, responseBody);
    }
    final responseString = utf8.decode(responseBody);
    Map<String, dynamic> json = jsonDecode(responseString);

    return json.tryGetList<String>("joined");
  }
}
