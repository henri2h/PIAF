import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix_homeserver_recommendations/matrix_homeserver_recommendations.dart';
import 'package:url_launcher/url_launcher.dart';

class MatrixServerChooserController extends ChangeNotifier {
  void setUrl(Client client, String value) {
    textController.text = value;
    _verifyDomain(client);
  }

  final textController = TextEditingController();

  Timer? verifyDomainCallback;

  List<String?> loginFlowsSupported = [];
  int verificationTrial = 0;
  Uri? domain;

  // Status

  bool isLoading = false;
  String? errorText;

  void reset() {
    loginFlowsSupported = [];
    isLoading = true;
    errorText = null;
    notifyListeners();
  }

  Future<void> _verifyDomain(Client client) async {
    final serverUrl = textController.text;

    verificationTrial++;
    int localVerificationNumber =
        verificationTrial; // check if we use the result of the verification for the last input of the user
    reset();

    Uri? address;

    try {
      address = serverUrl.startsWith("http")
          ? Uri.parse(serverUrl)
          : Uri.https(serverUrl, "");

      var (homeserver, _, loginFlow) = await client.checkHomeserver(address);

      // check  if info is not null and
      // if we are the last try (prevent an old request to modify the results)
      if (localVerificationNumber == verificationTrial) {
        updateDomain(homeserver, loginFlow, address);
        return;
      }
    } catch (e, s) {
      Logs().e("[Login] : an error happend", e, s);
      if (localVerificationNumber == verificationTrial) {
        errorText = e.toString();
        updateDomain(null, null, null);
      }
    }
  }

  void verifyDomain(Client client) {
    verifyDomainCallback?.cancel();
    verifyDomainCallback = Timer(const Duration(milliseconds: 500), () async {
      // check to log in using .wellknown informations
      await _verifyDomain(client);
    });
  }

  void updateDomain(
      DiscoveryInformation? server, List<LoginFlow>? loginFlow, Uri? url) {
    if (server != null) {
      // Use the information returned by the server or fallback to the value given by the user
      domain = server.mHomeserver.baseUrl;

      // update UI according to server capabilities
      loginFlowsSupported = loginFlow?.map((e) => e.type).toList() ?? [];
    }

    // change if hostname hasn't be set by user
    isLoading = false;
    notifyListeners();
  }
}

class MatrixServerChooser extends StatefulWidget {
  const MatrixServerChooser(
      {super.key,
      required this.client,
      required this.onChanged,
      required this.controller});
  final void Function(Uri?) onChanged;
  final Client client;
  final MatrixServerChooserController controller;

  @override
  State<MatrixServerChooser> createState() => MatrixServerChooserState();
}

class MatrixServerChooserState extends State<MatrixServerChooser> {
  MatrixServerChooserController get controller => widget.controller;

  bool get _isLoading => controller.isLoading;
  String? get _errorText => controller.errorText;

  @override
  void initState() {
    super.initState();

    if (widget.client.baseUri != null) {
      controller.setUrl(widget.client, widget.client.baseUri.toString());
    }

    controller.addListener(() {
      if (!controller.isLoading) {
        widget.onChanged(controller.domain);
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  void onServerChanged() {
    controller.verifyDomain(widget.client);
  }

  var joinMatrixParser = const JoinmatrixOrgParser();

  Future<void> enterCustomServerURL() async {
    List<String>? results = await showTextInputDialog(
      context: context,
      textFields: [
        DialogTextField(
            hintText: "Homeserver url",
            initialText: widget.controller.textController.text)
      ],
      title: "Set homeserver url",
    );
    if (results?.isNotEmpty == true) {
      widget.controller.textController.text = results![0];
      onServerChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.cloud),
          trailing: const Icon(Icons.edit),
          title: const Text("Homeserver"),
          subtitle: Text(widget.controller.textController.text),
          onTap: () async {
            final servers = await joinMatrixParser.fetchHomeservers();
            if (context.mounted) {
              await showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return ListView(children: [
                      ListTile(
                        leading: const Icon(Icons.cloud),
                        title: const Text("Custom homeserver"),
                        subtitle: const Text("Enter a custom URL"),
                        trailing: const Icon(Icons.edit),
                        onTap: () async {
                          await enterCustomServerURL();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                      for (final server in servers)
                        ListTile(
                          title: Text(server.baseUrl.toString()),
                          subtitle: server.description != null
                              ? Text(server.description!)
                              : null,
                          trailing: server.aboutUrl != null
                              ? IconButton(
                                  icon: const Icon(Icons.info),
                                  onPressed: () async {
                                    final url = server.aboutUrl!;

                                    if (await canLaunchUrl(url)) {
                                      launchUrl(url);
                                    }
                                  })
                              : null,
                          onTap: () {
                            controller.textController.text =
                                server.baseUrl.toString();
                            onServerChanged();
                            Navigator.of(context).pop();
                          },
                        )
                    ]);
                  });
            }
            return;
          },
        ),
        if (_isLoading) const CircularProgressIndicator(),
        if (_errorText != null && !_isLoading)
          const ListTile(
              leading: Icon(Icons.error),
              title: Text("Invalid server"),
              subtitle: Text(
                  "Please enter a valid Matrix server or check your internet connection")),
      ],
    );
  }
}
