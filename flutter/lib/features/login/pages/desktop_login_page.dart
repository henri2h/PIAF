import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class DesktopLoginPage extends StatefulWidget {
  const DesktopLoginPage(
      {super.key, this.title, this.onLogin, this.popOnLogin = false});
  final String? title;
  final Function(bool isLoggedIn)? onLogin;

  final bool popOnLogin;

  @override
  DesktopLoginPageState createState() => DesktopLoginPageState();
}

class DesktopLoginPageState extends State<DesktopLoginPage> {
  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(8);

    return Scaffold(
      body: Row(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child:
                        Image.asset("assets/piaf.jpg", width: 150, height: 150),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("PIAF",
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onPrimary)),
                      Text("A privacy focused social media based on MATRIX",
                          style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onPrimary))
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Card(
                    color: Theme.of(context).cardColor.withAlpha(120),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 15.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () async => await _launchURL(
                                Uri.parse("https://matrix.org")),
                            child: const Text('The Matrix protocol'),
                          ),
                          TextButton(
                            onPressed: () async => await _launchURL(Uri.parse(
                                "https://gitlab.com/minestrix/minestrix-flutter")),
                            child: const Text('Le PIAF code'),
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
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              Image.asset("assets/login_background.jpg", fit: BoxFit.cover),
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
                                Theme(
                                  data: ThemeData(
                                      scaffoldBackgroundColor:
                                          Colors.transparent),
                                  child: Card(
                                    color: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(radius)),
                                    margin: EdgeInsets.zero,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                            maxWidth: 700, minHeight: 450),
                                        child: const AutoRouter(),
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
                ],
              ),
            ]),
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
