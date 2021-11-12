import 'package:flutter/material.dart';
import 'package:minestrix/components/notificationView.dart';
import 'package:minestrix/components/post/postEditor.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/screens/smatrix/groups/createGroup.dart';
import 'package:minestrix/screens/smatrix/feedView.dart';
import 'package:minestrix/screens/home/navbar/widget.dart';
import 'package:minestrix/screens/home/right_bar/widget.dart';
import 'package:minestrix/screens/smatrix/userFeedView.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';
import 'package:minestrix_chat/view/matrix_chats_page.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  Widget widgetView = null;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 900)
        return buildWideContainer(context);
      else
        return buildMobileContainer(context);
    });
  }

  Widget buildWideContainer(BuildContext context) {
    bool feedView = false;
    if (widgetView == null) widgetView = FeedView();
    return Scaffold(
        floatingActionButton: buildFloattingButton(),
        body: Container(
          child: Column(
            children: [
              NavBar(changePage: changePage),
              Expanded(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(flex: 10, child: widgetView),
                      if (feedView)
                        Flexible(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Text("Contacts",
                                        style: TextStyle(fontSize: 30)),
                                  ),
                                  Flexible(child: RightBar()),
                                ],
                              ),
                            )),
                    ]),
              ),
            ],
          ),
        ),
        endDrawer: NotificationView());
  }

  bool changing = false;
  bool isChatVue = false;

  bool isNavBarExtended = false;

  void changePage(Widget widgetIn, {bool chatVue}) {
    if (mounted && changing == false) {
      changing = true;
      if (chatVue != null)
        isChatVue = true;
      else
        isChatVue = false;
      setState(() {
        widgetView = widgetIn;
        changing = false;
        isNavBarExtended = false;
      });
    }
  }

  Widget buildMobileContainer(BuildContext context) {
    Widget widgetFeedView = FeedView();
    if (widgetView == null) widgetView = widgetFeedView;
    return Scaffold(
        body: Container(child: widgetView ?? Text("hello")),
        bottomNavigationBar: NavigationBar(changePage: changePage),
        endDrawer: NotificationView());
  }

  Widget buildFloattingButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isNavBarExtended)
          Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
            child: Material(
              color: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30))),
              elevation: 30,
              child: Column(
                children: [
                  FloatingActionButton(
                    onPressed: () async {
                      changePage(PostEditor());
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
                          context: context, builder: (_) => CreateGroup());
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

class NavigationBar extends StatefulWidget {
  NavigationBar({Key key, @required this.changePage}) : super(key: key);
  final Function changePage;
  @override
  NavigationBarState createState() => NavigationBarState();
}

class NavigationBarState extends State<NavigationBar> {
  int _selectedIndex = 0;
  String userId;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        widget.changePage(FeedView());
        break;
      case 1:
        widget.changePage(MatrixChatsPage(client: Matrix.of(context).sclient),
            chatVue: true);
        break;
      case 2:
        widget.changePage(UserFeedView(userId: userId));
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    userId = sclient.userID;

    return BottomNavigationBar(
      onTap: _onItemTapped,
      currentIndex: _selectedIndex,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Feed'),
        BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined), label: "Messages"),
        BottomNavigationBarItem(
            icon: FutureBuilder(
                future: sclient.getProfileFromUserId(sclient.userID),
                builder: (BuildContext context, AsyncSnapshot<Profile> p) {
                  if (p.data?.avatarUrl == null) return Icon(Icons.person);
                  return MatrixUserImage(
                      client: sclient,
                      url: p.data.avatarUrl,
                      fit: true,
                      thumnail: true);
                }),
            label: "My account"),
      ],
    );
  }
}
