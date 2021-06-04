import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/global/helpers/NavigationHelper.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrix/SMatrixRoom.dart';
import 'package:minestrix/global/smatrixWidget.dart';

class PostWriterModal extends StatelessWidget {
  PostWriterModal({Key key, @required this.sroom}) : super(key: key);
  final SMatrixRoom sroom;
  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    return Card(
        child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15),
      child: Row(
        children: [
          MinesTrixUserImage(
              url: sclient.userRoom.user.avatarUrl, height: 50, width: 50),
          SizedBox(width: 30),
          Expanded(
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(40)))),
                  onPressed: () {
                    NavigationHelper.navigateToWritePost(context, sroom);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(9.0),
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 10),
                        Text("Write a post as " + sroom.name),
                      ],
                    ),
                  )))
        ],
      ),
    ));
  }
}
