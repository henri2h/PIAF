import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:matrix/matrix.dart';

import '../../../../../../../../../utils/matrix_widget.dart';
import '../../../../../../../../../matrix/matrix_image_avatar.dart';

class RoomPillExtension extends HtmlExtension {
  final Room room;
  final BuildContext context;

  RoomPillExtension(this.context, this.room);
  @override
  Set<String> get supportedTags => {'a'};

  @override
  bool matches(ExtensionContext context) {
    if (context.elementName != 'a') return false;
    final userId = context.element?.attributes['href']
        ?.parseIdentifierIntoParts()
        ?.primaryIdentifier;
    return userId != null;
  }

  static final _cachedUsers = <String, User?>{};

  Future<User?> _fetchUser(String matrixId) async =>
      _cachedUsers[room.id + matrixId] ??= await room.requestUser(matrixId);

  @override
  InlineSpan build(ExtensionContext context) {
    final href = context.element?.attributes['href'];
    final matrixId = href?.parseIdentifierIntoParts()?.primaryIdentifier;
    if (href == null || matrixId == null) {
      return TextSpan(text: context.innerHtml);
    }
    if (matrixId.sigil == '@') {
      return WidgetSpan(
        child: FutureBuilder<User?>(
          future: _fetchUser(matrixId),
          builder: (context, snapshot) => InkWell(
            key: Key('user_pill_$matrixId'),
            child: Text(
                "@${_cachedUsers[room.id + matrixId]?.calcDisplayname() ?? matrixId.localpart ?? matrixId}",
                style: TextStyle(color: Colors.blue[800])),
            onTap: () {},
          ),
        ),
      );
    }
    if (matrixId.sigil == '#' || matrixId.sigil == '!') {
      final room = matrixId.sigil == '!'
          ? this.room.client.getRoomById(matrixId)
          : this.room.client.getRoomByAlias(matrixId);
      if (room != null) {
        return WidgetSpan(
          child: MatrixPill(
            name: room.getLocalizedDisplayname(),
            avatar: room.avatar,
            uri: href,
            outerContext: this.context,
          ),
        );
      }
    }

    return TextSpan(text: context.innerHtml);
  }
}

class MatrixPill extends StatelessWidget {
  final String name;
  final BuildContext outerContext;
  final Uri? avatar;
  final String uri;

  const MatrixPill({
    super.key,
    required this.name,
    required this.outerContext,
    this.avatar,
    required this.uri,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (kDebugMode) {
          print("Tapped on $uri");
        }
      },
      child: Material(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: Theme.of(outerContext).colorScheme.primaryContainer,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 10,
              child: MatrixImageAvatar(
                client: Matrix.of(context).client,
                defaultText: name,
                url: avatar,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Text(
                name,
                style: TextStyle(
                  color: Theme.of(outerContext).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
