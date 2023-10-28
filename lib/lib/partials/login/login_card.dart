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

import 'matrix_server_chooser.dart';

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
      _passwordController = TextEditingController();

  final domainController = MatrixServerChooserController();

  Client get client => widget.client;

  String? _errorText;

  Uri? get domain => domainController.domain;
  bool get serverSelected => domain != null;

  bool _isLoading = false;
  bool _credentialsEdited = false;

  bool get ssoLogin =>
      domainController.loginFlowsSupported.contains(AuthenticationTypes.sso);
  bool get passwordLogin => domainController.loginFlowsSupported
      .contains(AuthenticationTypes.password);

  @override
  void initState() {
    domainController.setUrl(client, widget.defaultServer);

    super.initState();
  }

  void onTextChanged() {
    final value = _usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;
    if (_credentialsEdited != value && mounted) {
      setState(() {
        _credentialsEdited = value;
      });
    }
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
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          MatrixServerChooser(
            onChanged: (value) {
              setState(() {
                _passwordController.clear();
                _usernameController.clear();
              });
            },
            client: client,
            controller: domainController,
          ),
          const SizedBox(height: 25),
          if (serverSelected)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Credentials",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (passwordLogin)
                  Row(
                    children: [
                      Flexible(
                        child: LoginInput(
                            name: "username",
                            hintText: "@john.doe:example.com",
                            icon: Icons.account_circle,
                            tController: _usernameController,
                            onChanged: (_) => onTextChanged()),
                      ),
                    ],
                  ),
                if (passwordLogin)
                  LoginInput(
                      name: "password",
                      icon: Icons.lock_outline,
                      tController: _passwordController,
                      onChanged: (_) => onTextChanged(),
                      obscureText: true),
              ],
            ),
          if (serverSelected && _errorText != null)
            ListTile(
                leading: const Icon(Icons.error),
                title: const Text("Whoops something wrong happened"),
                subtitle: Text(_errorText!)),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Row(
              children: [
                if (ssoLogin)
                  Expanded(
                    child: LoginButton(
                        icon: Icons.web,
                        onPressed: _ssoLogin,
                        text: "SSO Login"),
                  ),
                if (ssoLogin && passwordLogin && _credentialsEdited)
                  const SizedBox(width: 12),
                if (passwordLogin && _credentialsEdited)
                  Expanded(
                    child: LoginButton(
                        icon: Icons.login,
                        onPressed: () async =>
                            await _loginAction(client, useSsoLogin: false),
                        text: "Sign In",
                        filled: true),
                  ),
              ],
            ),
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
      if (domain == null) return;
      String nav = await (Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  MobileSSOLogin(url: url, domain: domain!.toString()))));

      loginWithToken(nav);
    }
  }

  void loginWithToken(String nav) {
    Uri tokenUrl = Uri.parse(nav);
    _loginAction(client,
        token: tokenUrl.queryParameters["loginToken"], useSsoLogin: true);
  }
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
