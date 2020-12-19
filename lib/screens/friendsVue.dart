import 'package:flutter/material.dart';
import 'package:minestrix/components/accountCard.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/global/smatrix.dart';

class FriendsVue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final SClient sclient = Matrix.of(context).sclient;
    return Scaffold(
      appBar: AppBar(title: Text("Friends")),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            
            child: StreamBuilder(
                stream: sclient.onSync.stream,
                builder: (context, _) => ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: sclient.srooms.length,
                  itemBuilder: (BuildContext context, int i) =>
                      AccountCard(sroom: sclient.srooms[i]),
                ),
              ),
          ),
          Text("Friends: ", style: TextStyle(fontSize: 20)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text("Friends: ", style: TextStyle(fontSize: 20)),
          )
        ],
      ),
    );
  }
}
