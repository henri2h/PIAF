import 'package:matrix/matrix.dart';

class SearchItem {
  Room? room;
  Profile? profile;
  PublicRoomsChunk? public;

  SearchItem({this.room, this.profile, this.public})
      : assert(room != null || profile != null);

  bool get isSpace => room?.isSpace ?? false;

  String get displayname =>
      room?.getLocalizedDisplayname() ??
      profile?.displayName ??
      profile?.userId ??
      public?.name ??
      '';
  Uri? get avatar => room?.avatar ?? profile?.avatarUrl ?? public?.avatarUrl;
  String get canonicalAlias => room?.canonicalAlias ?? '';
  String get topic => room?.topic ?? public?.topic ?? '';
  String get directChatMatrixID => room?.directChatMatrixID ?? '';
  bool get isDirectChat => room?.isDirectChat ?? false;

  bool get isProfile => profile != null;

  String get secondText => room != null
      ? (room!.isDirectChat
          ? room!.directChatMatrixID ?? ''
          : room!.topic.isNotEmpty
              ? room!.topic
              : room!.canonicalAlias)
      : profile?.userId ?? public?.topic ?? public?.canonicalAlias ?? '';
}

class ResultList {
  final String searchText;
  final List<SearchItem> items;

  const ResultList(this.items, {this.searchText = ''});
}
