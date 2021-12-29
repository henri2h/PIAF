import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';

class UserAvatar extends StatelessWidget {
  final Profile p;

  const UserAvatar({Key? key, required this.p}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 15,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40.0),
        ),
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MatrixUserImage(
              client: Matrix.of(context).sclient,
              url: p.avatarUrl,
              width: 250,
              height: 250,
              thumnail: true,
              rounded: false,
              defaultIcon: Icon(Icons.person, size: 120),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(p.displayName ?? p.userId,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            ),
            if (p.displayName != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(p.userId,
                    style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).textTheme.caption!.color)),
              ),
          ],
        ),
      ),
    );
  }
}
