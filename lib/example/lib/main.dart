import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/partials/login/login_card.dart';
import 'package:minestrix_chat/partials/sync/sync_status_card.dart';

import 'package:minestrix_chat/utils/manager/client_manager.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import 'chat_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final clients = await ClientManager.getClients();

  runApp(MinesTRIXChatDemoApp(clients: clients));
}

class MinesTRIXChatDemoApp extends StatelessWidget {
  final List<Client> clients;
  const MinesTRIXChatDemoApp({Key? key, required this.clients})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Matrix(
      applicationName: 'MinesTRIX chat demo',
      context: context,
      clients: clients,
      child: MaterialApp(
        title: 'MinesTRIX chat demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> _openChat() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const ChatPage()));
  }

  Future<void> _logIn() async {
    await AdaptativeDialogs.show(
        builder: (BuildContext context) => LoginMatrixCard(
            client: Matrix.of(context).client,
            popOnLogin:
                true // allow hiding the dialog when succesfuly logged in
            ),
        context: context);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    return Scaffold(
      appBar: AppBar(
        title: const Text("MinesTRIX chat demo"),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ListTile(
                  title: const Text("Matrix connected"),
                  subtitle: Text("${client.isLogged()}")),
              if (!client.isLogged())
                ListTile(
                    onTap: _logIn,
                    title: const Text("Log in"),
                    trailing: const Icon(Icons.login)),
              if (client.isLogged()) SyncStatusCard(client: client)
            ],
          ),
        ),
      ),
      floatingActionButton: client.isLogged()
          ? FloatingActionButton(
              onPressed: _openChat,
              tooltip: 'Open chat page',
              child: const Icon(Icons.chat),
            )
          : null,
    );
  }
}
