import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:matrix/encryption/utils/key_verification.dart';
import 'package:matrix/matrix.dart';

import '../custom_image_resizer.dart';
import '../database/flutter_matrix_sdk_database_builder.dart';
import '../famedlysdk_store.dart';
import '../platform_infos.dart';

abstract class ClientManager {
  static String clientNamespace =
      'fr.minestrix.store.clients${kDebugMode ? '.debug' : ''}';

  static Future<List<Client>> getClients({bool initialize = true}) async {
    final clientNames = <String>{};
    try {
      final rawClientNames = await Store().getItem(clientNamespace);

      if (rawClientNames != null) {
        final clientNamesList =
            (jsonDecode(rawClientNames) as List).cast<String>();
        clientNames.addAll(clientNamesList);
      }
    } catch (e, s) {
      Logs().w('Client names in store are corrupted', e, s);
      await Store().deleteItem(clientNamespace);
    }
    if (clientNames.isEmpty) {
      clientNames.add(PlatformInfos.firstClientName);
      await Store().setItem(clientNamespace, jsonEncode(clientNames.toList()));
    }
    final clients = clientNames.map(createClient).toList();
    if (initialize) {
      await Future.wait(clients.map((client) => client
          .init(
            waitForFirstSync: false,
            waitUntilLoadCompletedLoaded: false,
          )
          .catchError(
              (e, s) => Logs().e('Unable to initialize client', e, s))));
    }
    if (clients.length > 1 && clients.any((c) => !c.isLogged())) {
      final loggedOutClients = clients.where((c) => !c.isLogged()).toList();
      for (final client in loggedOutClients) {
        Logs().w(
            'Multi account is enabled but client ${client.userID} is not logged in. Removing...');
        clientNames.remove(client.clientName);
        clients.remove(client);
      }
      await Store().setItem(clientNamespace, jsonEncode(clientNames.toList()));
    }
    return clients;
  }

  static Future<void> addClientNameToStore(String clientName) async {
    final clientNamesList = <String>[];
    final rawClientNames = await Store().getItem(clientNamespace);
    if (rawClientNames != null) {
      final stored = (jsonDecode(rawClientNames) as List).cast<String>();
      clientNamesList.addAll(stored);
    }
    clientNamesList.add(clientName);
    await Store().setItem(clientNamespace, jsonEncode(clientNamesList));
  }

  static Future<void> removeClientNameFromStore(String clientName) async {
    final clientNamesList = <String>[];
    final rawClientNames = await Store().getItem(clientNamespace);
    if (rawClientNames != null) {
      final stored = (jsonDecode(rawClientNames) as List).cast<String>();
      clientNamesList.addAll(stored);
    }
    clientNamesList.remove(clientName);
    await Store().setItem(clientNamespace, jsonEncode(clientNamesList));
  }

  /// When creating a new client, we will use thoose to add to the importantStateEvents of Client()
  static Set<String> importantStateEventsOverrides = {};

  static Client createClient(String clientName) => Client(
        clientName,
        verificationMethods: {
          KeyVerificationMethod.numbers,
          if (kIsWeb || PlatformInfos.isMobile || PlatformInfos.isLinux)
            KeyVerificationMethod.emoji,
        },
        importantStateEvents: <String>{
          // To make room emotes work
          'im.ponies.room_emotes',
          // To check which story room we can post in
          EventTypes.RoomPowerLevels,
        }..addAll(importantStateEventsOverrides),
        databaseBuilder: flutterMatrixSdkDatabaseBuilder,
        supportedLoginTypes: {
          AuthenticationTypes.password,
          if (PlatformInfos.isMobile ||
              PlatformInfos.isWeb ||
              PlatformInfos.isMacOS ||
              PlatformInfos.isLinux)
            AuthenticationTypes.sso
        },
        compute: compute,
        customImageResizer: PlatformInfos.isMobile ? customImageResizer : null,
      );
}
