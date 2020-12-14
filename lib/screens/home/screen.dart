import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/postEditor.dart';
import 'package:minestrix/screens/chatsVue.dart';
import 'package:minestrix/screens/home/feed/widget.dart';
import 'package:minestrix/global/matrix.dart';
import 'package:minestrix/screens/home/left_bar/widget.dart';
import 'package:minestrix/screens/home/navbar/widget.dart';
import 'package:minestrix/screens/home/right_bar/widget.dart';
import 'package:provider/provider.dart';

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
  void _incrementCounter() async {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatsVue(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      /*appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Mines'Trix"),
      ),*/
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
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Text("Feed",
                            style: TextStyle(
                                fontSize: 50, fontWeight: FontWeight.w600)),
                      ),
                      FeedView(),
                    ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
