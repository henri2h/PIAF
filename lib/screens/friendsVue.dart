import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/accountCard.dart';
import 'package:minestrix/global/matrix.dart';
import 'package:minestrix/global/smatrix.dart';

class FriendsVue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Client client = Matrix.of(context).client;
    final SMatrix sclient = Matrix.of(context).sclient;
    return Scaffold(
      appBar: AppBar(title: Text("Friends")),
      body: StreamBuilder(
        stream: client.onSync.stream,
        builder: (context, _) => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: sclient.srooms.length,
          itemBuilder: (BuildContext context, int i) => AccountCard(sroom: sclient.srooms[i]),
        ),
      ),
    );
  }
}
