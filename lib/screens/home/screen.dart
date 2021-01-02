import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/components/postEditor.dart';
import 'package:minestrix/components/postView.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/screens/chatsVue.dart';
import 'package:minestrix/screens/debugVue.dart';
import 'package:minestrix/screens/feedView.dart';
import 'package:minestrix/screens/friendsVue.dart';
import 'package:minestrix/screens/home/left_bar/widget.dart';
import 'package:minestrix/screens/home/navbar/widget.dart';
import 'package:minestrix/screens/home/right_bar/widget.dart';
import 'package:minestrix/screens/settings.dart';
import 'package:minestrix/screens/userFeedView.dart';
import 'package:famedlysdk/famedlysdk.dart';

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
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final sclient = Matrix.of(context).sclient;

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return
        /*appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Mines'Trix"),
      ),*/
        LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 1200)
        return WideContainer(sclient: sclient);
      else if (constraints.maxWidth > 900)
        return TabletContainer(sclient: sclient);
      else
        return MobileContainer();
    });
  }
}

class WideContainer extends StatelessWidget {
  const WideContainer({
    Key key,
    @required this.sclient,
  }) : super(key: key);

  final SClient sclient;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          onPressed: () {}, tooltip: 'Write post', child: Icon(Icons.edit)),
      body: Container(
        child: Column(
          children: [
            NavBar(),
            //PostEditor(),
            Expanded(
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text("Help bar"),
                      LeftBar(),
                    ],
                  ),
                ),
                Flexible(
                  flex: 7,
                  child: StreamBuilder(
                    stream: sclient.onTimelineUpdate.stream,
                    builder: (context, _) => ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sclient.stimeline.length,
                        itemBuilder: (BuildContext context, int i) =>
                            Post(event: sclient.stimeline[i])),
                  ),
                ),
                Flexible(
                    flex: 3,
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
    );
  }
}

class TabletContainer extends StatelessWidget {
  const TabletContainer({
    Key key,
    @required this.sclient,
  }) : super(key: key);

  final SClient sclient;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          onPressed: () {}, tooltip: 'Write post', child: Icon(Icons.edit)),
      body: Container(
        child: Column(
          children: [
            NavBar(),
            //PostEditor(),
            Expanded(
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  flex: 9,
                  child: StreamBuilder(
                    stream: sclient.onTimelineUpdate.stream,
                    builder: (context, _) => ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sclient.stimeline.length,
                        itemBuilder: (BuildContext context, int i) =>
                            Post(event: sclient.stimeline[i])),
                  ),
                ),
                Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text("Contacts",
                                style: TextStyle(fontSize: 30)),
                          ),
                          Expanded(child: RightBar()),
                        ],
                      ),
                    )),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class MobileContainer extends StatefulWidget {
  @override
  _MobileContainerState createState() => _MobileContainerState();
}

class _MobileContainerState extends State<MobileContainer> {
  final int selectedIndex = 1;
  Widget widgetView;
  bool changing = false;

  void changePage(Widget widgetIn) {
    if (mounted && changing == false) {
      changing = true;
      setState(() {
        widgetView = widgetIn;
        changing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    Widget widgetFeedView = FeedView(sclient: sclient);
    if (widgetView == null) widgetView = widgetFeedView;
    return Scaffold(
      extendBody: true,
      body: Container(color: Colors.white, child: widgetView ?? Text("hello")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
              context: context, builder: (_) => Dialog(child: PostEditor()));
          /* NavigatorState nav = Navigator.of(context);
          if (nav.canPop()) {
            nav.pop<PostEditor>();
            
          } else
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(body: PostEditor()),
              ),
            );*/
        },
        tooltip: "New post",
        child: Container(
          margin: EdgeInsets.all(15.0),
          child: Icon(Icons.edit),
        ),
        elevation: 4.0,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 30),
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(30.0)),
              color: Colors.white),
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal:14),
              child: NavigationBar(changePage: changePage)),
        ),
      ),
    );
  }
}

class NavigationBar extends StatefulWidget {
  static int _selectedIndex = 0;
  NavigationBar({Key key, @required this.changePage}) : super(key: key);
  final Function changePage;
  @override
  NavigationBarState createState() => NavigationBarState();
}

class NavigationBarState extends State<NavigationBar> {
  int _selectedIndex = -1;
  void _onItemTapped(int index, SClient sclient) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        widget.changePage(FeedView(sclient: sclient));
        break;
      case 1:
        widget.changePage(FriendsVue());
        break;
      case 2:
        widget.changePage(ChatsVue());
        break;
      case 3:
        widget.changePage(UserFeedView(userId: sclient.userID));
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    List<Widget> items = [
      Icon(
        Icons.home_outlined,
      ),
      Icon(
        Icons.people_outlined,
      ),
      Icon(
        Icons.message_outlined,
      ),
      FutureBuilder(
          future: sclient.getProfileFromUserId(sclient.userID),
          builder: (BuildContext context, AsyncSnapshot<Profile> p) {
            if (p.data?.avatarUrl == null) return Icon(Icons.person);
            return MatrixUserImage(url: p.data.avatarUrl);
          }),
    ];
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        for (int i = 0; i < items.length; i++)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  onPressed: () {
                    _onItemTapped(i, sclient);
                  },
                  icon: items[i]),
              if (i == _selectedIndex)
                Container(
                  width: 8,
                  height: 8,
                  decoration: new BoxDecoration(
                    color: Color(0xFFd24800),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
