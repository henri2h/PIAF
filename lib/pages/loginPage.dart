import 'package:flutter/material.dart';
import 'package:minestrix/partials/login/loginCard.dart';
import 'package:minestrix/partials/minestrixTitle.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key? key, this.title, this.onLogin}) : super(key: key);
  final String? title;
  final Function(bool isLoggedIn)? onLogin;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 900)
        return buildDesktop();
      else
        return buildMobile();
    });
  }

  Widget buildDesktop() {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
              child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MinestrixTitle(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snap) {
                          if (!snap.hasData) return Container();
                          return Text(
                              "Version : " + (snap.data?.version ?? 'null'));
                        }),
                    TextButton(
                      onPressed: () async =>
                          await _launchURL("https://matrix.org"),
                      child: new Text('The matrix protocol'),
                    ),
                    TextButton(
                      onPressed: () async => await _launchURL(
                          "https://gitlab.com/minestrix/minestrix-flutter"),
                      child: new Text('MinesTRIX code'),
                    ),
                  ],
                ),
              ),
            ],
          )),
          Expanded(
            child: Container(
              //color: Colors.blue[700],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[Expanded(child: LoginCard())],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMobile() {
    return Scaffold(
      body: Container(
        color: Colors.grey[200],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            MinestrixTitle(),
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(40))),
                    child: LoginCard()))
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
