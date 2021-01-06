// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:famedlysdk/famedlysdk.dart';
import 'package:moor/moor_web.dart';

Future<Database> constructDb(
    {bool logStatements = false,
    String filename = 'database.sqlite',
    String password = ''}) async {
  print('[Moor] Using moor web');
  return Database(WebDatabase.withStorage(
      MoorWebStorage.indexedDbIfSupported(filename),
      logStatements: logStatements));
}

Future<String> getLocalstorage(String key) async {
  // ignore: await_only_futures
  return await window.localStorage[key];
}
