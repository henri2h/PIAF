import 'dart:io';

import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixButton.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/screens/home/screen.dart';
import 'package:minestrix/global/smatrix.dart';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: ListView(
        children: <Widget>[
          LoginTitle(),
          LoginCard(),
        ],
      )),
    );
  }
}

class LoginTitle extends StatelessWidget {
  const LoginTitle({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(50),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Mines'Trix",
            style: TextStyle(fontSize: 50, fontWeight: FontWeight.w800)),
        Text("An alternative social media based on MATRIX",
            style: TextStyle(fontSize: 30))
      ]),
    );
  }
}

class LoginCard extends StatefulWidget {
  LoginCard({Key key}) : super(key: key);
  @override
  LoginCardState createState() => LoginCardState();
}

class LoginCardState extends State<LoginCard> {
  final TextEditingController _usernameController = TextEditingController(),
      _passwordController = TextEditingController();

  String _errorText;
  bool _isLoading = false;
  String password = "";
  String domain = "";
  bool ssoLogin = false;
  bool canTryLogIn = false;
  int verificationTrial = 0;
  bool checkingUserId = false;

  void _loginAction(SClient client, {String token}) async {
    if (mounted)
      setState(() {
        _isLoading = true;
        _errorText = null;
      });
    try {
      await client.checkHomeserver(domain, supportedLoginTypes: {
        AuthenticationTypes.password,
        AuthenticationTypes.token
      });
      await client.login(
          type: ssoLogin
              ? AuthenticationTypes.token
              : AuthenticationTypes.password,
          user: _usernameController.text,
          password: _passwordController.text,
          token: token,
          initialDeviceDisplayName: client.clientName);
    } catch (error) {
      if (mounted) setState(() => _errorText = error.toString());
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _requestSupportedTypes(SClient client) async {
    LoginTypes lg = await client.requestLoginTypes();
    print(lg.toJson());
    for (Flows item in lg.flows) {
      print(item.type.toString());
    }
    setState(() {
      ssoLogin = lg.flows.firstWhere((Flows elem) => elem.type == "m.login.sso",
              orElse: () => null) !=
          null;
    });
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void updateDomain(String url) {
    setState(() {
      domain = url;
      canTryLogIn = true;
      checkingUserId = false;
    });
  }

  void _verifyDomain(SClient client, String userid) async {
    verificationTrial++;
    int localVerificationNumber = verificationTrial;
    if (userid.isValidMatrixId) {
      setState(() {
        checkingUserId = true;
      });

      try {
        WellKnownInformations infos =
            await client.getWellKnownInformationsByUserId(userid);
        if (infos?.mHomeserver?.baseUrl != null) {
          updateDomain(infos.mHomeserver.baseUrl);

          client.homeserver = Uri.parse(infos.mHomeserver.baseUrl);
          await _requestSupportedTypes(client);
          return;
        }
      } catch (e) {
        // try a catch back for home server not suporting well known ... sigh
        try {
          client.homeserver = Uri.https(userid.domain, "");
          await _requestSupportedTypes(client);

          if (verificationTrial == localVerificationNumber)
            updateDomain("https://" + userid.domain);
          return;
        } catch (e) {
          try {
            client.homeserver = Uri.https("matrix." + userid.domain, "");
            await _requestSupportedTypes(client);

            if (verificationTrial == localVerificationNumber)
              updateDomain("https://matrix." + userid.domain);

            return;
          } catch (e) {
            print("error : " + userid);
            print(e);
          }
        }
      }
    }

    if (localVerificationNumber == verificationTrial)
      // if we are here, we had an issue somewhere...
      setState(() {
        domain = "";
        canTryLogIn = false;
        checkingUserId = false;
      });
  }

// according to the matrix specification https://matrix.org/docs/spec/appendices#id9
  RegExp userRegex = RegExp(
      r"@((([a-z]|\.|_|-|=|\/|[0-9])+):(((.+)\.(.+))|\[((([0-9]|[a-f]|[A-F])+):){2,7}:?([0-9]|[a-f]|[A-F])+\]))(:([0-9]+))?");
  @override
  Widget build(BuildContext context) {
    SClient client = Matrix.of(context).sclient;
    return SizedBox(
        child: Container(
            child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(children: <Widget>[
                  Row(
                    children: [
                      Flexible(
                        child: LoginInput(
                            name: "userid",
                            icon: Icons.account_circle,
                            onChanged: (String userid) async {
                              await _verifyDomain(client, userid);
                            },
                            tController: _usernameController),
                      ),
                      SizedBox(
                          width: 40,
                          height: 40,
                          child: checkingUserId
                              ? CircularProgressIndicator()
                              : Container())
                    ],
                  ),
                  if (canTryLogIn && ssoLogin == false)
                    Padding(
                      padding: const EdgeInsets.only(right: 40),
                      child: LoginInput(
                          name: "password",
                          icon: Icons.lock_outline,
                          tController: _passwordController,
                          obscureText: true),
                    ),
                  if (canTryLogIn) Text("Domain : " + domain),
                  if (_errorText != null) Text(_errorText),
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: LinearProgressIndicator(),
                    ),
                  ssoLogin == false
                      ? FloatingActionButton.extended(
                          icon: const Icon(Icons.login),
                          label: Text('Login'),
                          onPressed: _isLoading || !canTryLogIn
                              ? null
                              : () => _loginAction(client))
                      : FloatingActionButton.extended(
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

                                  String nav = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Platform
                                                    .isAndroid ||
                                                Platform.isIOS
                                            ? WebView(
                                                initialUrl: url,
                                                javascriptMode: JavascriptMode
                                                    .unrestricted, // well, we need to enable javascript
                                                navigationDelegate: (action) {
                                                  if (action.url
                                                      .startsWith(domain)) {
                                                    Navigator.pop(
                                                        context,
                                                        action
                                                            .url); // we have the login token now ;)
                                                    return NavigationDecision
                                                        .prevent;
                                                  }
                                                  return NavigationDecision
                                                      .navigate;
                                                },
                                              )
                                            : Scaffold(
                                                appBar: AppBar(
                                                    title: Text("SSO Login")),
                                                body: Padding(
                                                  padding: const EdgeInsets.all(
                                                      30.0),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                          "Oups... you're not on Android or IOS"),
                                                      Text(
                                                          "Please copy and paste this link into your web browser"),
                                                      TextField(
                                                        controller:
                                                            TextEditingController(
                                                                text: url),
                                                        toolbarOptions:
                                                            ToolbarOptions(
                                                          paste: true,
                                                          cut: true,
                                                          copy: true,
                                                          selectAll: true,
                                                        ),
                                                        autocorrect: false,
                                                      ),
                                                      SelectableText(url),
                                                      SizedBox(height: 30),
                                                      Text(
                                                          "And paste response"),
                                                      SizedBox(height: 30),
                                                      if (Platform.isAndroid ||
                                                          Platform.isIOS)
                                                        TextButton(
                                                            onPressed:
                                                                () async {
                                                              await _launchURL(
                                                                  url);
                                                            },
                                                            child:
                                                                Text("Copy")),
                                                      TextField(
                                                        autocorrect: false,
                                                        controller: ssoResponse
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(30.0),
                                                        child: MinesTrixButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context,
                                                                  ssoResponse.text); // we have the login token now ;)
                                                            },
                                                            icon: Icons.send,
                                                            label: "Login"),
                                                      )
                                                    ],
                                                  ),
                                                )),
                                      ));

                                  Uri tokenUrl = Uri.parse(nav);
                                  _loginAction(client,
                                      token: tokenUrl
                                          .queryParameters["loginToken"]);
                                }),
                ]))));
  }

  void changePage(BuildContext context) {
    print(_usernameController.text);
    print(_passwordController.text);
    if (2 == 3)
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ));
  }
}

class LoginInput extends StatelessWidget {
  const LoginInput(
      {Key key,
      this.name,
      this.icon,
      this.tController,
      this.errorText,
      this.obscureText = false,
      this.onChanged})
      : super(key: key);
  final String name;
  final IconData icon;
  final TextEditingController tController;
  final String errorText;
  final bool obscureText;
  final Function onChanged;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        keyboardType: TextInputType.emailAddress,
        controller: tController,
        obscureText: obscureText,
        onChanged: onChanged,
        autocorrect: false,
        decoration: InputDecoration(
          errorText: errorText,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          filled: true,
          icon: Icon(icon),
          labelText: name,
        ),
      ),
    );
  }
}
