import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/login/loginInput.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LoginCard extends StatefulWidget {
  LoginCard({Key? key}) : super(key: key);
  @override
  LoginCardState createState() => LoginCardState();
}

class LoginCardState extends State<LoginCard> {
  final TextEditingController _usernameController = TextEditingController(),
      _passwordController = TextEditingController(),
      _hostNameController = TextEditingController();

  MinestrixClient? client;

  String? _errorText;
  bool _isLoading = false;
  String password = "";
  String domain = "";

  bool ssoLogin = false;
  bool passwordLogin = false;

  bool canTryLogIn = false;
  int verificationTrial = 0;
  bool checkingUserId = false;

  @override
  Widget build(BuildContext context) {
    client = Matrix.of(context).sclient;
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 600),
                    child: buildSimpleDetail()),
              ],
            ),
          ),
          advancedViewSwitch()
        ]);
  }

  void _loginAction(MinestrixClient client,
      {String? token, required useSsoLogin}) async {
    if (mounted)
      setState(() {
        _isLoading = true;
        _errorText = null;
      });
    try {
      await client.checkHomeserver(_hostNameController.text);
      await client.login(
          useSsoLogin ? LoginType.mLoginToken : LoginType.mLoginPassword,
          identifier:
              AuthenticationUserIdentifier(user: _usernameController.text),
          password: _passwordController.text,
          token: token,
          initialDeviceDisplayName: client.clientName);

      await client.roomsLoading;
      await client.updateAll(); // start synchronsiation
    } catch (error) {
      print("could not log in");
      if (mounted) setState(() => _errorText = error.toString());
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _requestSupportedTypes(MinestrixClient client) {
    for (String item in client.supportedLoginTypes) {
      print(item.toString());
    }
    setState(() {
      ssoLogin = client.supportedLoginTypes.contains(AuthenticationTypes.sso);
      passwordLogin =
          client.supportedLoginTypes.contains(AuthenticationTypes.password);
    });
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void updateDomain(String url, {canTryLogIn: true}) {
    setState(() {
      // change if hostname hasn't be set by user

      _hostNameController.text = url;
      domain = url;

      checkingUserId = false;

      this.canTryLogIn = canTryLogIn;
    });
  }

  Future<void> _verifyDomain(MinestrixClient client, String serverUrl) async {
    verificationTrial++;
    int localVerificationNumber =
        verificationTrial; // check if we use the result of the verification for the last input of the user

    setState(() {
      checkingUserId = true;
    });

    try {
      print("Input server url : " + serverUrl);
      await client.checkHomeserver(serverUrl);

      // check  if info is not null and
      // if we are the last try (prevent an old request to modify the results)
      if (localVerificationNumber == verificationTrial) {
        updateDomain(client.homeserver.toString());
        print("Returned matrix server url : " + client.homeserver.toString());

        _requestSupportedTypes(client);
        return;
      }
    } catch (e) {
      print("error : " + serverUrl);
      print(e);
    }

    // if we are here, we had an issue somewhere...
    setState(() {
      checkingUserId = false;
      passwordLogin = false;
      ssoLogin = false;
    });

    updateDomain("", canTryLogIn: false);
  }

  Timer? verifyDomainCallback;
// according to the matrix specification https://matrix.org/docs/spec/appendices#id9
  RegExp userRegex = RegExp(
      r"@((([a-z]|\.|_|-|=|\/|[0-9])+):(((.+)\.(.+))|\[((([0-9]|[a-f]|[A-F])+):){2,7}:?([0-9]|[a-f]|[A-F])+\]))(:([0-9]+))?");

  Widget buildSimpleDetail() {
    return Column(children: [
      if (advancedView)
        Padding(
          padding: const EdgeInsets.only(right: 40),
          child: LoginInput(
            name: "Server",
            icon: Icons.cloud,
            tController: _hostNameController,
          ),
        ),
      Row(
        children: [
          Flexible(
            child: LoginInput(
                name: "userid",
                icon: Icons.account_circle,
                onChanged: (String userid) async {
                  verifyDomainCallback?.cancel();
                  verifyDomainCallback =
                      new Timer(const Duration(milliseconds: 500), () async {
                    if (userid.isValidMatrixId) {
                      // check to log in using .wellknown informations
                      await _verifyDomain(client!, "https://" + userid.domain!);

                      if (canTryLogIn == false)
                        // if this hasn't worked, try to use the potential matrix.xxx subdomain
                        await _verifyDomain(
                            client!, "https://matrix." + userid.domain!);
                    }
                  });
                },
                tController: _usernameController),
          ),
          SizedBox(
              width: 40,
              height: 40,
              child: checkingUserId ? CircularProgressIndicator() : Container())
        ],
      ),
      if (canTryLogIn && passwordLogin)
        Padding(
          padding: const EdgeInsets.only(right: 40),
          child: LoginInput(
              name: "password",
              icon: Icons.lock_outline,
              tController: _passwordController,
              obscureText: true),
        ),
      if (_errorText != null) Text(_errorText!),
      if (_isLoading)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: LinearProgressIndicator(),
        ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (passwordLogin)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton.extended(
                  heroTag: "passwordFAB",
                  icon: const Icon(Icons.login),
                  label: Text('Login'),
                  onPressed: _isLoading || !canTryLogIn
                      ? null
                      : () => _loginAction(client!, useSsoLogin: false)),
            ),
          if (ssoLogin)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton.extended(
                  heroTag: "ssoFAB",
                  icon: const Icon(Icons.login),
                  label: Text('SSO Login'),
                  onPressed: _isLoading || !canTryLogIn
                      ? null
                      : () async {
                          String url = domain +
                              "/_matrix/client/r0/login/sso/redirect?redirectUrl=" +
                              domain +
                              "/#/"; // we should not reach the redirect url ...

                          TextEditingController ssoResponse =
                              TextEditingController();

                          String nav = await (Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => !kIsWeb &&
                                        (Platform.isAndroid || Platform.isIOS)
                                    ? WebView(
                                        initialUrl: url,
                                        javascriptMode: JavascriptMode
                                            .unrestricted, // well, we need to enable javascript
                                        navigationDelegate: (action) {
                                          if (action.url.startsWith(domain)) {
                                            Navigator.pop(
                                                context,
                                                action
                                                    .url); // we have the login token now ;)
                                            return NavigationDecision.prevent;
                                          }
                                          return NavigationDecision.navigate;
                                        },
                                      )
                                    : Scaffold(
                                        appBar:
                                            AppBar(title: Text("SSO Login")),
                                        body: Padding(
                                          padding: const EdgeInsets.all(30.0),
                                          child: Column(
                                            children: [
                                              Text(
                                                  "Oups... you're not on Android or IOS"),
                                              Text(
                                                  "We can't open a web page inside minestrix"),
                                              Text(
                                                  "So please copy and paste this link into your web browser"),
                                              Text(
                                                "Open it in private window",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SelectableText(url),
                                              SizedBox(height: 30),
                                              Text("And paste response"),
                                              SizedBox(height: 30),
                                              if (!kIsWeb &&
                                                  (Platform.isAndroid ||
                                                      Platform.isIOS))
                                                TextButton(
                                                    onPressed: () async {
                                                      await _launchURL(url);
                                                    },
                                                    child: Text("Copy")),
                                              TextField(
                                                  autocorrect: false,
                                                  controller: ssoResponse),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(30.0),
                                                child: MinesTrixButton(
                                                    onPressed: () {
                                                      Navigator.pop(
                                                          context,
                                                          ssoResponse
                                                              .text); // we have the login token now ;)
                                                    },
                                                    icon: Icons.send,
                                                    label: "Login"),
                                              )
                                            ],
                                          ),
                                        )),
                              )) as FutureOr<String>);

                          Uri tokenUrl = Uri.parse(nav);
                          _loginAction(client!,
                              token: tokenUrl.queryParameters["loginToken"],
                              useSsoLogin: true);
                        }),
            )
        ],
      ),
    ]);
  }

  bool advancedView = false;
  Widget advancedViewSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            color: Colors.blue,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(advancedView ? "Advanced view" : "Simple view"),
                  Switch(
                      value: advancedView,
                      onChanged: (value) {
                        setState(() {
                          advancedView = value;
                        });
                      }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
