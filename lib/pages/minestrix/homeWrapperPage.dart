import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/pages/minestrix/groups/createGroupPage.dart';
import 'package:minestrix/partials/home/notificationView.dart';
import 'package:minestrix/router.gr.dart';

class HomeWrapperPage extends StatefulWidget {
  HomeWrapperPage({Key? key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String? title;

  @override
  _HomeWrapperPageState createState() => _HomeWrapperPageState();
}

class _HomeWrapperPageState extends State<HomeWrapperPage> {
  Widget? widgetView = null;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isWideScreen = constraints.maxWidth > 900;

      return Scaffold(
        //floatingActionButton: buildFloattingButton(),
        body: AutoRouter(),
        // bottomNavigationBar: isWideScreen ? null : NavBarMobile(),
        endDrawer: NotificationView(),
      );
    });
  }

  bool isNavBarExtended = false;

  Widget buildFloattingButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isNavBarExtended)
          Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
            child: Material(
              color: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30))),
              elevation: 30,
              child: Column(
                children: [
                  FloatingActionButton(
                    onPressed: () async {
                      context.navigateTo(PostEditorRoute());
                    },
                    tooltip: "Create post",
                    child: Container(
                      margin: EdgeInsets.all(15.0),
                      child: Icon(Icons.post_add),
                    ),
                    elevation: 0,
                  ),
                  SizedBox(height: 10),
                  FloatingActionButton(
                    onPressed: () async {
                      showDialog(
                          context: context, builder: (_) => CreateGroupPage());
                    },
                    tooltip: "New group",
                    child: Container(
                      margin: EdgeInsets.all(15.0),
                      child: Icon(Icons.group_add),
                    ),
                    elevation: 0,
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                isNavBarExtended = !isNavBarExtended;
              });
            },
            tooltip: "New post",
            child: Container(
              margin: EdgeInsets.all(15.0),
              child: Icon(Icons.add),
            ),
            elevation: 30,
          ),
        ),
      ],
    );
  }
}
