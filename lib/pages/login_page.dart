import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix_chat/partials/login/login_card.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key, this.title, this.onLogin, this.popOnLogin = false})
      : super(key: key);
  final String? title;
  final Function(bool isLoggedIn)? onLogin;

  final bool popOnLogin;

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 900) {
        return buildDesktop();
      } else {
        return buildMobile();
      }
    });
  }

  Widget buildDesktop() {
    Client client = Matrix.of(context).getLoginClient();

    const radius = Radius.circular(8);

    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        Image.asset("assets/bg_paris.jpg", fit: BoxFit.cover),
        Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: IntrinsicHeight(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 180,
                            child: Card(
                              shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                      topLeft: radius, bottomLeft: radius)),
                              margin: EdgeInsets.zero,
                              color: Theme.of(context).colorScheme.primary,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 40.0),
                                    child: Image.asset("assets/icon_512.png",
                                        width: 80, height: 80),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("MinesTRIX",
                                            style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary)),
                                        Text(
                                            "A privacy focused social media based on MATRIX",
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary))
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                    topRight: radius, bottomRight: radius)),
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15.0),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                      maxWidth: 450, minHeight: 200),
                                  child: LoginMatrixCard(
                                      client: client,
                                      popOnLogin: widget.popOnLogin),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Card(
              color: Theme.of(context).cardColor.withAlpha(120),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 15.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () async =>
                          await _launchURL(Uri.parse("https://matrix.org")),
                      child: const Text('The Matrix protocol'),
                    ),
                    TextButton(
                      onPressed: () async => await _launchURL(Uri.parse(
                          "https://gitlab.com/minestrix/minestrix-flutter")),
                      child: const Text('MinesTRIX code'),
                    ),
                    const SizedBox(width: 20),
                    FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snap) {
                          if (!snap.hasData) return Container();
                          return Text(
                              "Version ${snap.data?.version ?? 'null'}");
                        }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ]),
    );
  }

  bool advancedView = false;

  Widget buildMobile() {
    Client client = Matrix.of(context).getLoginClient();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/bg_paris.jpg", fit: BoxFit.cover),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(50),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(
                    children: [
                      Image.asset("assets/icon_512.png",
                          width: 72, height: 72, cacheWidth: 140),
                      const SizedBox(width: 28),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("MinesTRIX",
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                            Text(
                                "A privacy focused social media based on MATRIX",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white))
                          ],
                        ),
                      ),
                    ],
                  ),
                ]),
              ),
              Flexible(
                child: Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(30))),
                    child: ListView(shrinkWrap: true, children: <Widget>[
                      LoginMatrixCard(client: client),
                    ])),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
