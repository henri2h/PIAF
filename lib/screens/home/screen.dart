import 'package:flutter/material.dart';
import 'package:minestrix/components/postEditor.dart';
import 'package:minestrix/components/postView.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/screens/chatVue.dart';
import 'package:minestrix/screens/chatsVue.dart';
import 'package:minestrix/screens/debugVue.dart';
import 'package:minestrix/screens/friendsVue.dart';
import 'package:minestrix/screens/home/left_bar/widget.dart';
import 'package:minestrix/screens/home/navbar/widget.dart';
import 'package:minestrix/screens/home/right_bar/widget.dart';
import 'package:minestrix/screens/settings.dart';

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
                Expanded(
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
        widgetView = Flexible(child: widgetIn);
        changing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    if (widgetView == null) widgetView = FeedView(sclient: sclient);
    return Scaffold(
      body: Container(
        child: Column(
          children: [widgetView],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          changePage(PostEditor());
        },
        tooltip: "New post",
        child: Container(
          margin: EdgeInsets.all(15.0),
          child: Icon(Icons.edit),
        ),
        elevation: 4.0,
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          margin: EdgeInsets.only(left: 12.0, right: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                //update the bottom app bar view each time an item is clicked
                onPressed: () {
                  changePage(FeedView(sclient: sclient));
                },
                icon: Icon(
                  Icons.home,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.person,
                ),
              ),
              IconButton(
                onPressed: () {
                  changePage(FriendsVue());
                },
                icon: Icon(
                  Icons.people,
                ),
              ),
              SizedBox(
                width: 50.0,
              ),
              IconButton(
                onPressed: () {
                  changePage(ChatsVue());
                },
                icon: Icon(
                  Icons.message,
                ),
              ),
              IconButton(
                onPressed: () {
                  changePage(DebugView());
                },
                icon: Icon(
                  Icons.bug_report,
                ),
              ),
              IconButton(
                onPressed: () {
                  changePage(SettingsView());
                },
                icon: Icon(
                  Icons.settings,
                ),
              ),
            ],
          ),
        ),
        //to add a space between the FAB and BottomAppBar
        shape: CircularNotchedRectangle(),
      ),
    );
  }
}

class FeedView extends StatelessWidget {
  const FeedView({
    Key key,
    @required this.sclient,
  }) : super(key: key);

  final SClient sclient;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder(
        stream: sclient.onTimelineUpdate.stream,
        builder: (context, _) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sclient.stimeline.length,
            itemBuilder: (BuildContext context, int i) =>
                Post(event: sclient.stimeline[i])),
      ),
    );
  }
}
