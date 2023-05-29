import 'dart:async';
import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/helpers/storage_manager.dart';
import 'package:minestrix_chat/partials/login/login_button.dart';
import 'package:minestrix_chat/partials/login/login_input.dart';
import 'package:minestrix_chat/utils/login/web_login_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LoginMatrixCard extends StatefulWidget {
  final Client client;
  final bool popOnLogin;
  final String defaultServer;
  const LoginMatrixCard(
      {Key? key,
      required this.client,
      this.popOnLogin = false,
      this.defaultServer = "matrix.org"})
      : super(key: key);

  @override
  LoginMatrixCardState createState() => LoginMatrixCardState();
}

class LoginMatrixCardState extends State<LoginMatrixCard> {
  final TextEditingController _usernameController = TextEditingController(),
      _passwordController = TextEditingController(),
      _hostNameController = TextEditingController();

  late Client client;

  String? _errorText;
  bool _isLoading = false;
  String domain = "";

  bool ssoLogin = false;
  bool passwordLogin = false;
  bool _serverIsValid = false;

  int verificationTrial = 0;

  @override
  void initState() {
    client = widget.client;
    _hostNameController.text = widget.defaultServer;
    _verifyDomain(client);
    super.initState();
  }

  void onServerChanged() {
    if (_errorText == null) {
      setState(() {
        _errorText = null;
      });
    }

    verifyDomainCallback?.cancel();
    verifyDomainCallback = Timer(const Duration(milliseconds: 500), () async {
      // check to log in using .wellknown informations
      await _verifyDomain(client);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Homeserver",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          LoginInput(
              name: "Homeserver",
              icon: Icons.cloud,
              tController: _hostNameController,
              onChanged: (_) => onServerChanged()),
          const SizedBox(height: 25),
          if (_serverIsValid)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Login",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
                if (passwordLogin)
                  Row(
                    children: [
                      Flexible(
                        child: LoginInput(
                            name: "username",
                            icon: Icons.account_circle,
                            tController: _usernameController),
                      ),
                    ],
                  ),
                if (passwordLogin)
                  LoginInput(
                      name: "password",
                      icon: Icons.lock_outline,
                      tController: _passwordController,
                      obscureText: true),
              ],
            ),
          if (!_serverIsValid && !_isLoading)
            const ListTile(
                leading: Icon(Icons.error),
                title: Text("Invalid server"),
                subtitle: Text(
                    "Please enter a valid Matrix server or check your internet connection")),
          if (_serverIsValid && _errorText != null)
            ListTile(
                leading: const Icon(Icons.error),
                title: const Text("Whoops something wrong happened"),
                subtitle: Text(_errorText!)),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          if (_serverIsValid) const SizedBox(height: 25),
          if (_serverIsValid)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (passwordLogin)
                  LoginButton(
                      icon: Icons.login,
                      onPressed: () async =>
                          await _loginAction(client, useSsoLogin: false),
                      text: "Login"),
                if (ssoLogin)
                  LoginButton(
                      icon: Icons.web, onPressed: _ssoLogin, text: "SSO Login")
              ],
            ),
        ]);
  }

  Future<void> _loginAction(Client client,
      {String? token, required useSsoLogin}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      await client.login(
          useSsoLogin ? LoginType.mLoginToken : LoginType.mLoginPassword,
          identifier:
              AuthenticationUserIdentifier(user: _usernameController.text),
          password: _passwordController.text,
          token: token,
          initialDeviceDisplayName: client.clientName);

      if (widget.popOnLogin) {
        if (mounted) Navigator.of(context).pop();
      }
    } catch (error, s) {
      Logs().e("[Login] : could not log in", error, s);
      if (mounted) setState(() => _errorText = error.toString());
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _ssoLogin() async {
    // redirect to the same previous domain when platform is web
    String url =
        "$domain/_matrix/client/r0/login/sso/redirect?redirectUrl=${WebLoginInterface.getUrl() ?? "$domain/#/"}"; // we should not reach the redirect url ...

    // web login
    if (kIsWeb) {
      print("Domain: $domain");
      StorageManager.saveData("homeserver", domain);
      WebLoginInterface.launchSame(url);
      return;
    }

    if (!(Platform.isAndroid || Platform.isIOS)) {
      final webview = await WebviewWindow.create();
      webview.launch(url);

      webview.addOnUrlRequestCallback((url) {
        Uri uri = Uri.parse(url);
        if (uri.queryParameters.containsKey("loginToken")) {
          webview.close();
          loginWithToken(url);
        }
      });

      webview.setOnHistoryChangedCallback((canGoBack, canGoForward) {});
    } else {
      String nav = await (Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MobileSSOLogin(url: url, domain: domain))));

      loginWithToken(nav);
    }
  }

  void loginWithToken(String nav) {
    Uri tokenUrl = Uri.parse(nav);
    _loginAction(client,
        token: tokenUrl.queryParameters["loginToken"], useSsoLogin: true);
  }

  void updateDomain(HomeserverSummary? server, String? url) {
    final serverIsValid = url != null;
    _serverIsValid = serverIsValid;
    domain = url ?? '';

    passwordLogin = false;
    ssoLogin = false;

    if (serverIsValid && server != null) {
      // update UI according to server capabilities
      for (final loginFlow in server.loginFlows) {
        switch (loginFlow.type) {
          case AuthenticationTypes.sso:
            ssoLogin = true;
            break;
          case AuthenticationTypes.password:
            passwordLogin = true;
            break;
          default:
        }
      }
    } else {
      _usernameController.clear();
      _passwordController.clear();
    }

    setState(() {
      // change if hostname hasn't be set by user
      _isLoading = false;
    });
  }

  Future<void> _verifyDomain(Client client) async {
    final serverUrl = _hostNameController.text;

    verificationTrial++;
    int localVerificationNumber =
        verificationTrial; // check if we use the result of the verification for the last input of the user

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final homeserver = await client.checkHomeserver(
          serverUrl.startsWith("http")
              ? Uri.parse(serverUrl)
              : Uri.https(serverUrl, ""));

      // check  if info is not null and
      // if we are the last try (prevent an old request to modify the results)
      if (localVerificationNumber == verificationTrial) {
        updateDomain(homeserver, client.homeserver?.toString());
        return;
      }
    } catch (e, s) {
      Logs().e("[Login] : an error happend", e, s);
      _errorText = e.toString();

      updateDomain(null, null);
    }
  }

  Timer? verifyDomainCallback;
}

class MobileSSOLogin extends StatelessWidget {
  const MobileSSOLogin({
    Key? key,
    required this.url,
    required this.domain,
  }) : super(key: key);

  final String url;
  final String domain;

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
          NavigationDelegate(onNavigationRequest: (NavigationRequest request) {
        if (request.url.startsWith(domain)) {
          Navigator.pop(context, request.url); // we have the login token now ;)
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      }))
      ..loadRequest(Uri.parse(url));

    return WebViewWidget(controller: controller);
  }
}
