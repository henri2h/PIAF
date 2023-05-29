import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

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
        child: SizedBox(
          width: 180,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MatrixImageAvatar(
                client: Matrix.of(context).client,
                url: p.avatarUrl,
                width: MinestrixAvatarSizeConstants.big,
                height: MinestrixAvatarSizeConstants.big,
                shape: MatrixImageAvatarShape.none,
                defaultIcon: Icon(Icons.person,
                    size: 100, color: Theme.of(context).colorScheme.onPrimary),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(p.displayName ?? p.userId,
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.bold)),
              ),
              if (p.displayName != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(p.userId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.caption!.color)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
