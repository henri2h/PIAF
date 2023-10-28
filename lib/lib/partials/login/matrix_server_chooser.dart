import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'login_input.dart';

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

      final homeserver = await client.checkHomeserver(address);

      // check  if info is not null and
      // if we are the last try (prevent an old request to modify the results)
      if (localVerificationNumber == verificationTrial) {
        updateDomain(homeserver, address);
        return;
      }
    } catch (e, s) {
      Logs().e("[Login] : an error happend", e, s);
      if (localVerificationNumber == verificationTrial) {
        errorText = e.toString();
        updateDomain(null, null);
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

  void updateDomain(HomeserverSummary? server, Uri? url) {
    if (server != null) {
      // Use the information returned by the server or fallback to the value given by the user
      domain = server.discoveryInformation?.mHomeserver.baseUrl ?? url;

      // update UI according to server capabilities
      loginFlowsSupported = server.loginFlows.map((e) => e.type).toList();
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
      widget.controller.setUrl(widget.client, widget.client.baseUri.toString());
    }

    widget.controller.addListener(() {
      if (!widget.controller.isLoading) {
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
