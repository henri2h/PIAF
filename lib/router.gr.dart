// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i62;
import 'package:flutter/material.dart' as _i63;
import 'package:matrix/matrix.dart' as _i64;
import 'package:piaf/app.dart' as _i23;
import 'package:piaf/features/calendar_events/pages/calendar_event_page.dart'
    as _i4;
import 'package:piaf/features/calendar_events/pages/calendar_events_list_page.dart'
    as _i3;
import 'package:piaf/features/chat/pages/add_user_page.dart' as _i1;
import 'package:piaf/features/chat/pages/device_media_gallery_page.dart'
    as _i15;
import 'package:piaf/features/chat/pages/matrix_create_group.dart' as _i24;
import 'package:piaf/features/chat/pages/matrix_storie_create.dart' as _i25;
import 'package:piaf/features/chat/pages/matrix_stories_page.dart' as _i27;
import 'package:piaf/features/chat/pages/room_list_or_placeholder.dart' as _i35;
import 'package:piaf/features/chat/pages/room_page.dart' as _i36;
import 'package:piaf/features/chat/pages/room_settings_page.dart' as _i37;
import 'package:piaf/features/chat/pages/space_page.dart' as _i50;
import 'package:piaf/features/chat/widgets/chat_page_items/chat_page_space_page.dart'
    as _i7;
import 'package:piaf/features/chat/widgets/chat_page_items/chat_page_spaces_list.dart'
    as _i6;
import 'package:piaf/features/chat/widgets/chat_page_items/provider/chat_page_provider.dart'
    as _i5;
import 'package:piaf/features/chat/widgets/room_create/create_chat_page.dart'
    as _i10;
import 'package:piaf/features/chat/widgets/room_create/create_group_page.dart'
    as _i11;
import 'package:piaf/features/communities/pages/community_detail_page.dart'
    as _i8;
import 'package:piaf/features/communities/pages/community_page.dart' as _i9;
import 'package:piaf/features/feed/pages/feed_creation_page.dart' as _i16;
import 'package:piaf/features/feed/pages/feed_list_page.dart' as _i17;
import 'package:piaf/features/feed/pages/feed_page.dart' as _i18;
import 'package:piaf/features/groups/pages/group_page.dart' as _i20;
import 'package:piaf/features/home/pages/home_page.dart' as _i21;
import 'package:piaf/features/image/pages/post_gallery_page.dart' as _i33;
import 'package:piaf/features/login/pages/desktop/desktop_welcome_route.dart'
    as _i14;
import 'package:piaf/features/login/pages/desktop_login_page.dart' as _i13;
import 'package:piaf/features/login/pages/mobile/mobile_create_account_page.dart'
    as _i28;
import 'package:piaf/features/login/pages/mobile/mobile_explore_page.dart'
    as _i29;
import 'package:piaf/features/login/pages/mobile/mobile_login_page.dart'
    as _i30;
import 'package:piaf/features/login/pages/mobile/mobile_welcome_page.dart'
    as _i31;
import 'package:piaf/features/login/pages/mobile/mobile_welcome_router_page.dart'
    as _i32;
import 'package:piaf/features/search/pages/search_page.dart' as _i38;
import 'package:piaf/features/settings/pages/settings_account_page.dart'
    as _i39;
import 'package:piaf/features/settings/pages/settings_account_switch_page.dart'
    as _i40;
import 'package:piaf/features/settings/pages/settings_feeds_page.dart' as _i41;
import 'package:piaf/features/settings/pages/settings_labs_page.dart' as _i42;
import 'package:piaf/features/settings/pages/settings_page.dart' as _i43;
import 'package:piaf/features/settings/pages/settings_security_page.dart'
    as _i44;
import 'package:piaf/features/settings/pages/settings_story_detail_page.dart'
    as _i45;
import 'package:piaf/features/settings/pages/settings_storys_page.dart' as _i46;
import 'package:piaf/features/settings/pages/settings_sync_page.dart' as _i47;
import 'package:piaf/features/settings/pages/settings_theme_page.dart' as _i48;
import 'package:piaf/features/todo/pages/todo_list_add_page.dart' as _i57;
import 'package:piaf/features/todo/pages/todo_list_page.dart' as _i58;
import 'package:piaf/features/todo/pages/todo_room_page.dart' as _i59;
import 'package:piaf/models/search/search_mode.dart' as _i65;
import 'package:piaf/pages/app_wrapper_page.dart' as _i2;
import 'package:piaf/pages/debug_page.dart' as _i12;
import 'package:piaf/pages/follow_recommendations.dart' as _i19;
import 'package:piaf/pages/home_space_page.dart' as _i22;
import 'package:piaf/pages/matrix_loading_page.dart' as _i26;
import 'package:piaf/pages/post_page.dart' as _i34;
import 'package:piaf/pages/social_settings_page.dart' as _i49;
import 'package:piaf/pages/tabs/tab_calendar_page.dart' as _i51;
import 'package:piaf/pages/tabs/tab_camera_page.dart' as _i52;
import 'package:piaf/pages/tabs/tab_chat_page.dart' as _i53;
import 'package:piaf/pages/tabs/tab_community_page.dart' as _i54;
import 'package:piaf/pages/tabs/tab_home_page.dart' as _i55;
import 'package:piaf/pages/tabs/tab_stories_page.dart' as _i56;
import 'package:piaf/pages/user/user_followers_page.dart' as _i60;
import 'package:piaf/pages/user/user_view_page.dart' as _i61;

/// generated route for
/// [_i1.AddUserPage]
class AddUserRoute extends _i62.PageRouteInfo<AddUserRouteArgs> {
  AddUserRoute({
    required _i63.BuildContext context,
    _i63.Key? key,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          AddUserRoute.name,
          args: AddUserRouteArgs(
            context: context,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'AddUserRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AddUserRouteArgs>();
      return _i1.AddUserPage(
        args.context,
        key: args.key,
      );
    },
  );
}

class AddUserRouteArgs {
  const AddUserRouteArgs({
    required this.context,
    this.key,
  });

  final _i63.BuildContext context;

  final _i63.Key? key;

  @override
  String toString() {
    return 'AddUserRouteArgs{context: $context, key: $key}';
  }
}

/// generated route for
/// [_i2.AppWrapperPage]
class AppWrapperRoute extends _i62.PageRouteInfo<void> {
  const AppWrapperRoute({List<_i62.PageRouteInfo>? children})
      : super(
          AppWrapperRoute.name,
          initialChildren: children,
        );

  static const String name = 'AppWrapperRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i2.AppWrapperPage();
    },
  );
}

/// generated route for
/// [_i3.CalendarEventListPage]
class CalendarEventListRoute extends _i62.PageRouteInfo<void> {
  const CalendarEventListRoute({List<_i62.PageRouteInfo>? children})
      : super(
          CalendarEventListRoute.name,
          initialChildren: children,
        );

  static const String name = 'CalendarEventListRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i3.CalendarEventListPage();
    },
  );
}

/// generated route for
/// [_i4.CalendarEventPage]
class CalendarEventRoute extends _i62.PageRouteInfo<CalendarEventRouteArgs> {
  CalendarEventRoute({
    _i63.Key? key,
    required _i64.Room room,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          CalendarEventRoute.name,
          args: CalendarEventRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'CalendarEventRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CalendarEventRouteArgs>();
      return _i4.CalendarEventPage(
        key: args.key,
        room: args.room,
      );
    },
  );
}

class CalendarEventRouteArgs {
  const CalendarEventRouteArgs({
    this.key,
    required this.room,
  });

  final _i63.Key? key;

  final _i64.Room room;

  @override
  String toString() {
    return 'CalendarEventRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i5.ChatPageProvider]
class ChatRouteProvider extends _i62.PageRouteInfo<ChatRouteProviderArgs> {
  ChatRouteProvider({
    _i63.Key? key,
    required _i63.Widget child,
    required _i64.Client client,
    required void Function(String?)? onRoomSelection,
    required void Function(String?) onLongPressedSpace,
    required void Function(String)? onSpaceSelection,
    String selectedSpace = "Explore",
    List<_i62.PageRouteInfo>? children,
  }) : super(
          ChatRouteProvider.name,
          args: ChatRouteProviderArgs(
            key: key,
            child: child,
            client: client,
            onRoomSelection: onRoomSelection,
            onLongPressedSpace: onLongPressedSpace,
            onSpaceSelection: onSpaceSelection,
            selectedSpace: selectedSpace,
          ),
          initialChildren: children,
        );

  static const String name = 'ChatRouteProvider';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ChatRouteProviderArgs>();
      return _i5.ChatPageProvider(
        key: args.key,
        child: args.child,
        client: args.client,
        onRoomSelection: args.onRoomSelection,
        onLongPressedSpace: args.onLongPressedSpace,
        onSpaceSelection: args.onSpaceSelection,
        selectedSpace: args.selectedSpace,
      );
    },
  );
}

class ChatRouteProviderArgs {
  const ChatRouteProviderArgs({
    this.key,
    required this.child,
    required this.client,
    required this.onRoomSelection,
    required this.onLongPressedSpace,
    required this.onSpaceSelection,
    this.selectedSpace = "Explore",
  });

  final _i63.Key? key;

  final _i63.Widget child;

  final _i64.Client client;

  final void Function(String?)? onRoomSelection;

  final void Function(String?) onLongPressedSpace;

  final void Function(String)? onSpaceSelection;

  final String selectedSpace;

  @override
  String toString() {
    return 'ChatRouteProviderArgs{key: $key, child: $child, client: $client, onRoomSelection: $onRoomSelection, onLongPressedSpace: $onLongPressedSpace, onSpaceSelection: $onSpaceSelection, selectedSpace: $selectedSpace}';
  }
}

/// generated route for
/// [_i6.ChatPageSpaceList]
class ChatRouteSpaceList extends _i62.PageRouteInfo<ChatRouteSpaceListArgs> {
  ChatRouteSpaceList({
    _i63.Key? key,
    required bool popAfterSelection,
    required _i63.ScrollController scrollController,
    _i63.VoidCallback? onSelection,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          ChatRouteSpaceList.name,
          args: ChatRouteSpaceListArgs(
            key: key,
            popAfterSelection: popAfterSelection,
            scrollController: scrollController,
            onSelection: onSelection,
          ),
          initialChildren: children,
        );

  static const String name = 'ChatRouteSpaceList';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ChatRouteSpaceListArgs>();
      return _i6.ChatPageSpaceList(
        key: args.key,
        popAfterSelection: args.popAfterSelection,
        scrollController: args.scrollController,
        onSelection: args.onSelection,
      );
    },
  );
}

class ChatRouteSpaceListArgs {
  const ChatRouteSpaceListArgs({
    this.key,
    required this.popAfterSelection,
    required this.scrollController,
    this.onSelection,
  });

  final _i63.Key? key;

  final bool popAfterSelection;

  final _i63.ScrollController scrollController;

  final _i63.VoidCallback? onSelection;

  @override
  String toString() {
    return 'ChatRouteSpaceListArgs{key: $key, popAfterSelection: $popAfterSelection, scrollController: $scrollController, onSelection: $onSelection}';
  }
}

/// generated route for
/// [_i7.ChatPageSpacePage]
class ChatRouteSpaceRoute extends _i62.PageRouteInfo<void> {
  const ChatRouteSpaceRoute({List<_i62.PageRouteInfo>? children})
      : super(
          ChatRouteSpaceRoute.name,
          initialChildren: children,
        );

  static const String name = 'ChatRouteSpaceRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i7.ChatPageSpacePage();
    },
  );
}

/// generated route for
/// [_i8.CommunityDetailPage]
class CommunityDetailRoute
    extends _i62.PageRouteInfo<CommunityDetailRouteArgs> {
  CommunityDetailRoute({
    _i63.Key? key,
    required _i64.Room room,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          CommunityDetailRoute.name,
          args: CommunityDetailRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'CommunityDetailRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CommunityDetailRouteArgs>();
      return _i8.CommunityDetailPage(
        key: args.key,
        room: args.room,
      );
    },
  );
}

class CommunityDetailRouteArgs {
  const CommunityDetailRouteArgs({
    this.key,
    required this.room,
  });

  final _i63.Key? key;

  final _i64.Room room;

  @override
  String toString() {
    return 'CommunityDetailRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i9.CommunityPage]
class CommunityRoute extends _i62.PageRouteInfo<void> {
  const CommunityRoute({List<_i62.PageRouteInfo>? children})
      : super(
          CommunityRoute.name,
          initialChildren: children,
        );

  static const String name = 'CommunityRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i9.CommunityPage();
    },
  );
}

/// generated route for
/// [_i10.CreateChatPage]
class CreateChatRoute extends _i62.PageRouteInfo<CreateChatRouteArgs> {
  CreateChatRoute({
    _i63.Key? key,
    required dynamic Function(String?) onRoomSelected,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          CreateChatRoute.name,
          args: CreateChatRouteArgs(
            key: key,
            onRoomSelected: onRoomSelected,
          ),
          initialChildren: children,
        );

  static const String name = 'CreateChatRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CreateChatRouteArgs>();
      return _i10.CreateChatPage(
        key: args.key,
        onRoomSelected: args.onRoomSelected,
      );
    },
  );
}

class CreateChatRouteArgs {
  const CreateChatRouteArgs({
    this.key,
    required this.onRoomSelected,
  });

  final _i63.Key? key;

  final dynamic Function(String?) onRoomSelected;

  @override
  String toString() {
    return 'CreateChatRouteArgs{key: $key, onRoomSelected: $onRoomSelected}';
  }
}

/// generated route for
/// [_i11.CreateGroupPage]
class CreateGroupRoute extends _i62.PageRouteInfo<CreateGroupRouteArgs> {
  CreateGroupRoute({
    _i63.Key? key,
    required dynamic Function(String?) onRoomSelected,
    required _i64.Client client,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          CreateGroupRoute.name,
          args: CreateGroupRouteArgs(
            key: key,
            onRoomSelected: onRoomSelected,
            client: client,
          ),
          initialChildren: children,
        );

  static const String name = 'CreateGroupRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CreateGroupRouteArgs>();
      return _i11.CreateGroupPage(
        key: args.key,
        onRoomSelected: args.onRoomSelected,
        client: args.client,
      );
    },
  );
}

class CreateGroupRouteArgs {
  const CreateGroupRouteArgs({
    this.key,
    required this.onRoomSelected,
    required this.client,
  });

  final _i63.Key? key;

  final dynamic Function(String?) onRoomSelected;

  final _i64.Client client;

  @override
  String toString() {
    return 'CreateGroupRouteArgs{key: $key, onRoomSelected: $onRoomSelected, client: $client}';
  }
}

/// generated route for
/// [_i12.DebugPage]
class DebugRoute extends _i62.PageRouteInfo<void> {
  const DebugRoute({List<_i62.PageRouteInfo>? children})
      : super(
          DebugRoute.name,
          initialChildren: children,
        );

  static const String name = 'DebugRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i12.DebugPage();
    },
  );
}

/// generated route for
/// [_i13.DesktopLoginPage]
class DesktopLoginRoute extends _i62.PageRouteInfo<DesktopLoginRouteArgs> {
  DesktopLoginRoute({
    _i63.Key? key,
    String? title,
    dynamic Function(bool)? onLogin,
    bool popOnLogin = false,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          DesktopLoginRoute.name,
          args: DesktopLoginRouteArgs(
            key: key,
            title: title,
            onLogin: onLogin,
            popOnLogin: popOnLogin,
          ),
          initialChildren: children,
        );

  static const String name = 'DesktopLoginRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DesktopLoginRouteArgs>(
          orElse: () => const DesktopLoginRouteArgs());
      return _i13.DesktopLoginPage(
        key: args.key,
        title: args.title,
        onLogin: args.onLogin,
        popOnLogin: args.popOnLogin,
      );
    },
  );
}

class DesktopLoginRouteArgs {
  const DesktopLoginRouteArgs({
    this.key,
    this.title,
    this.onLogin,
    this.popOnLogin = false,
  });

  final _i63.Key? key;

  final String? title;

  final dynamic Function(bool)? onLogin;

  final bool popOnLogin;

  @override
  String toString() {
    return 'DesktopLoginRouteArgs{key: $key, title: $title, onLogin: $onLogin, popOnLogin: $popOnLogin}';
  }
}

/// generated route for
/// [_i14.DesktopWelcomePage]
class DesktopWelcomeRoute extends _i62.PageRouteInfo<void> {
  const DesktopWelcomeRoute({List<_i62.PageRouteInfo>? children})
      : super(
          DesktopWelcomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'DesktopWelcomeRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i14.DesktopWelcomePage();
    },
  );
}

/// generated route for
/// [_i15.DeviceMediaGalleryPage]
class DeviceMediaGalleryRoute extends _i62.PageRouteInfo<void> {
  const DeviceMediaGalleryRoute({List<_i62.PageRouteInfo>? children})
      : super(
          DeviceMediaGalleryRoute.name,
          initialChildren: children,
        );

  static const String name = 'DeviceMediaGalleryRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i15.DeviceMediaGalleryPage();
    },
  );
}

/// generated route for
/// [_i16.FeedCreationPage]
class FeedCreationRoute extends _i62.PageRouteInfo<void> {
  const FeedCreationRoute({List<_i62.PageRouteInfo>? children})
      : super(
          FeedCreationRoute.name,
          initialChildren: children,
        );

  static const String name = 'FeedCreationRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i16.FeedCreationPage();
    },
  );
}

/// generated route for
/// [_i17.FeedListPage]
class FeedListRoute extends _i62.PageRouteInfo<FeedListRouteArgs> {
  FeedListRoute({
    _i63.Key? key,
    required _i17.Selection initialSelection,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          FeedListRoute.name,
          args: FeedListRouteArgs(
            key: key,
            initialSelection: initialSelection,
          ),
          initialChildren: children,
        );

  static const String name = 'FeedListRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<FeedListRouteArgs>();
      return _i17.FeedListPage(
        key: args.key,
        initialSelection: args.initialSelection,
      );
    },
  );
}

class FeedListRouteArgs {
  const FeedListRouteArgs({
    this.key,
    required this.initialSelection,
  });

  final _i63.Key? key;

  final _i17.Selection initialSelection;

  @override
  String toString() {
    return 'FeedListRouteArgs{key: $key, initialSelection: $initialSelection}';
  }
}

/// generated route for
/// [_i18.FeedPage]
class FeedRoute extends _i62.PageRouteInfo<void> {
  const FeedRoute({List<_i62.PageRouteInfo>? children})
      : super(
          FeedRoute.name,
          initialChildren: children,
        );

  static const String name = 'FeedRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i18.FeedPage();
    },
  );
}

/// generated route for
/// [_i19.FollowRecommendationsPage]
class FollowRecommendationsRoute extends _i62.PageRouteInfo<void> {
  const FollowRecommendationsRoute({List<_i62.PageRouteInfo>? children})
      : super(
          FollowRecommendationsRoute.name,
          initialChildren: children,
        );

  static const String name = 'FollowRecommendationsRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i19.FollowRecommendationsPage();
    },
  );
}

/// generated route for
/// [_i20.GroupPage]
class GroupRoute extends _i62.PageRouteInfo<GroupRouteArgs> {
  GroupRoute({
    _i63.Key? key,
    required String roomId,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          GroupRoute.name,
          args: GroupRouteArgs(
            key: key,
            roomId: roomId,
          ),
          rawPathParams: {'roomId': roomId},
          initialChildren: children,
        );

  static const String name = 'GroupRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<GroupRouteArgs>(
          orElse: () => GroupRouteArgs(roomId: pathParams.getString('roomId')));
      return _i20.GroupPage(
        key: args.key,
        roomId: args.roomId,
      );
    },
  );
}

class GroupRouteArgs {
  const GroupRouteArgs({
    this.key,
    required this.roomId,
  });

  final _i63.Key? key;

  final String roomId;

  @override
  String toString() {
    return 'GroupRouteArgs{key: $key, roomId: $roomId}';
  }
}

/// generated route for
/// [_i21.HomePage]
class HomeRoute extends _i62.PageRouteInfo<void> {
  const HomeRoute({List<_i62.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i21.HomePage();
    },
  );
}

/// generated route for
/// [_i22.HomeSpacePage]
class HomeSpaceRoute extends _i62.PageRouteInfo<void> {
  const HomeSpaceRoute({List<_i62.PageRouteInfo>? children})
      : super(
          HomeSpaceRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeSpaceRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i22.HomeSpacePage();
    },
  );
}

/// generated route for
/// [_i23.MainRouterPage]
class MainRouterRoute extends _i62.PageRouteInfo<void> {
  const MainRouterRoute({List<_i62.PageRouteInfo>? children})
      : super(
          MainRouterRoute.name,
          initialChildren: children,
        );

  static const String name = 'MainRouterRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i23.MainRouterPage();
    },
  );
}

/// generated route for
/// [_i24.MatrixCreateGroup]
class MatrixCreateGroup extends _i62.PageRouteInfo<MatrixCreateGroupArgs> {
  MatrixCreateGroup({
    _i63.Key? key,
    required _i64.Client client,
    void Function(String)? onGroupCreated,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          MatrixCreateGroup.name,
          args: MatrixCreateGroupArgs(
            key: key,
            client: client,
            onGroupCreated: onGroupCreated,
          ),
          initialChildren: children,
        );

  static const String name = 'MatrixCreateGroup';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MatrixCreateGroupArgs>();
      return _i24.MatrixCreateGroup(
        key: args.key,
        client: args.client,
        onGroupCreated: args.onGroupCreated,
      );
    },
  );
}

class MatrixCreateGroupArgs {
  const MatrixCreateGroupArgs({
    this.key,
    required this.client,
    this.onGroupCreated,
  });

  final _i63.Key? key;

  final _i64.Client client;

  final void Function(String)? onGroupCreated;

  @override
  String toString() {
    return 'MatrixCreateGroupArgs{key: $key, client: $client, onGroupCreated: $onGroupCreated}';
  }
}

/// generated route for
/// [_i25.MatrixCreateStoriePage]
class MatrixCreateStorieRoute
    extends _i62.PageRouteInfo<MatrixCreateStorieRouteArgs> {
  MatrixCreateStorieRoute({
    _i63.Key? key,
    required _i64.Client client,
    required _i64.Room r,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          MatrixCreateStorieRoute.name,
          args: MatrixCreateStorieRouteArgs(
            key: key,
            client: client,
            r: r,
          ),
          initialChildren: children,
        );

  static const String name = 'MatrixCreateStorieRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MatrixCreateStorieRouteArgs>();
      return _i25.MatrixCreateStoriePage(
        key: args.key,
        client: args.client,
        r: args.r,
      );
    },
  );
}

class MatrixCreateStorieRouteArgs {
  const MatrixCreateStorieRouteArgs({
    this.key,
    required this.client,
    required this.r,
  });

  final _i63.Key? key;

  final _i64.Client client;

  final _i64.Room r;

  @override
  String toString() {
    return 'MatrixCreateStorieRouteArgs{key: $key, client: $client, r: $r}';
  }
}

/// generated route for
/// [_i26.MatrixLoadingPage]
class MatrixLoadingRoute extends _i62.PageRouteInfo<void> {
  const MatrixLoadingRoute({List<_i62.PageRouteInfo>? children})
      : super(
          MatrixLoadingRoute.name,
          initialChildren: children,
        );

  static const String name = 'MatrixLoadingRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i26.MatrixLoadingPage();
    },
  );
}

/// generated route for
/// [_i27.MatrixStoriesPage]
class MatrixStoriesRoute extends _i62.PageRouteInfo<MatrixStoriesRouteArgs> {
  MatrixStoriesRoute({
    required _i64.Room room,
    _i63.Key? key,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          MatrixStoriesRoute.name,
          args: MatrixStoriesRouteArgs(
            room: room,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'MatrixStoriesRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MatrixStoriesRouteArgs>();
      return _i27.MatrixStoriesPage(
        args.room,
        key: args.key,
      );
    },
  );
}

class MatrixStoriesRouteArgs {
  const MatrixStoriesRouteArgs({
    required this.room,
    this.key,
  });

  final _i64.Room room;

  final _i63.Key? key;

  @override
  String toString() {
    return 'MatrixStoriesRouteArgs{room: $room, key: $key}';
  }
}

/// generated route for
/// [_i28.MobileCreateAccountPage]
class MobileCreateAccountRoute extends _i62.PageRouteInfo<void> {
  const MobileCreateAccountRoute({List<_i62.PageRouteInfo>? children})
      : super(
          MobileCreateAccountRoute.name,
          initialChildren: children,
        );

  static const String name = 'MobileCreateAccountRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i28.MobileCreateAccountPage();
    },
  );
}

/// generated route for
/// [_i29.MobileExplorePage]
class MobileExploreRoute extends _i62.PageRouteInfo<void> {
  const MobileExploreRoute({List<_i62.PageRouteInfo>? children})
      : super(
          MobileExploreRoute.name,
          initialChildren: children,
        );

  static const String name = 'MobileExploreRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i29.MobileExplorePage();
    },
  );
}

/// generated route for
/// [_i30.MobileLoginPage]
class MobileLoginRoute extends _i62.PageRouteInfo<MobileLoginRouteArgs> {
  MobileLoginRoute({
    _i63.Key? key,
    bool popOnLogin = false,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          MobileLoginRoute.name,
          args: MobileLoginRouteArgs(
            key: key,
            popOnLogin: popOnLogin,
          ),
          initialChildren: children,
        );

  static const String name = 'MobileLoginRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MobileLoginRouteArgs>(
          orElse: () => const MobileLoginRouteArgs());
      return _i30.MobileLoginPage(
        key: args.key,
        popOnLogin: args.popOnLogin,
      );
    },
  );
}

class MobileLoginRouteArgs {
  const MobileLoginRouteArgs({
    this.key,
    this.popOnLogin = false,
  });

  final _i63.Key? key;

  final bool popOnLogin;

  @override
  String toString() {
    return 'MobileLoginRouteArgs{key: $key, popOnLogin: $popOnLogin}';
  }
}

/// generated route for
/// [_i31.MobileWelcomePage]
class MobileWelcomeRoute extends _i62.PageRouteInfo<void> {
  const MobileWelcomeRoute({List<_i62.PageRouteInfo>? children})
      : super(
          MobileWelcomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'MobileWelcomeRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i31.MobileWelcomePage();
    },
  );
}

/// generated route for
/// [_i32.MobileWelcomeRouterPage]
class MobileWelcomeRouter extends _i62.PageRouteInfo<void> {
  const MobileWelcomeRouter({List<_i62.PageRouteInfo>? children})
      : super(
          MobileWelcomeRouter.name,
          initialChildren: children,
        );

  static const String name = 'MobileWelcomeRouter';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i32.MobileWelcomeRouterPage();
    },
  );
}

/// generated route for
/// [_i33.PostGalleryPage]
class PostGalleryRoute extends _i62.PageRouteInfo<PostGalleryRouteArgs> {
  PostGalleryRoute({
    _i63.Key? key,
    required _i64.Event post,
    _i64.Event? image,
    String? selectedImageEventId,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          PostGalleryRoute.name,
          args: PostGalleryRouteArgs(
            key: key,
            post: post,
            image: image,
            selectedImageEventId: selectedImageEventId,
          ),
          initialChildren: children,
        );

  static const String name = 'PostGalleryRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PostGalleryRouteArgs>();
      return _i33.PostGalleryPage(
        key: args.key,
        post: args.post,
        image: args.image,
        selectedImageEventId: args.selectedImageEventId,
      );
    },
  );
}

class PostGalleryRouteArgs {
  const PostGalleryRouteArgs({
    this.key,
    required this.post,
    this.image,
    this.selectedImageEventId,
  });

  final _i63.Key? key;

  final _i64.Event post;

  final _i64.Event? image;

  final String? selectedImageEventId;

  @override
  String toString() {
    return 'PostGalleryRouteArgs{key: $key, post: $post, image: $image, selectedImageEventId: $selectedImageEventId}';
  }
}

/// generated route for
/// [_i34.PostPage]
class PostRoute extends _i62.PageRouteInfo<PostRouteArgs> {
  PostRoute({
    _i63.Key? key,
    required _i64.Event event,
    required _i64.Timeline timeline,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          PostRoute.name,
          args: PostRouteArgs(
            key: key,
            event: event,
            timeline: timeline,
          ),
          initialChildren: children,
        );

  static const String name = 'PostRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PostRouteArgs>();
      return _i34.PostPage(
        key: args.key,
        event: args.event,
        timeline: args.timeline,
      );
    },
  );
}

class PostRouteArgs {
  const PostRouteArgs({
    this.key,
    required this.event,
    required this.timeline,
  });

  final _i63.Key? key;

  final _i64.Event event;

  final _i64.Timeline timeline;

  @override
  String toString() {
    return 'PostRouteArgs{key: $key, event: $event, timeline: $timeline}';
  }
}

/// generated route for
/// [_i35.RoomListOrPlaceHolderPage]
class RoomListOrPlaceHolderRoute extends _i62.PageRouteInfo<void> {
  const RoomListOrPlaceHolderRoute({List<_i62.PageRouteInfo>? children})
      : super(
          RoomListOrPlaceHolderRoute.name,
          initialChildren: children,
        );

  static const String name = 'RoomListOrPlaceHolderRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i35.RoomListOrPlaceHolderPage();
    },
  );
}

/// generated route for
/// [_i36.RoomPage]
class RoomRoute extends _i62.PageRouteInfo<RoomRouteArgs> {
  RoomRoute({
    _i63.Key? key,
    required String roomId,
    void Function()? onBack,
    bool allowPop = true,
    bool displaySettingsOnDesktop = false,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          RoomRoute.name,
          args: RoomRouteArgs(
            key: key,
            roomId: roomId,
            onBack: onBack,
            allowPop: allowPop,
            displaySettingsOnDesktop: displaySettingsOnDesktop,
          ),
          rawPathParams: {'id': roomId},
          initialChildren: children,
        );

  static const String name = 'RoomRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<RoomRouteArgs>(
          orElse: () => RoomRouteArgs(roomId: pathParams.getString('id')));
      return _i36.RoomPage(
        key: args.key,
        roomId: args.roomId,
        onBack: args.onBack,
        allowPop: args.allowPop,
        displaySettingsOnDesktop: args.displaySettingsOnDesktop,
      );
    },
  );
}

class RoomRouteArgs {
  const RoomRouteArgs({
    this.key,
    required this.roomId,
    this.onBack,
    this.allowPop = true,
    this.displaySettingsOnDesktop = false,
  });

  final _i63.Key? key;

  final String roomId;

  final void Function()? onBack;

  final bool allowPop;

  final bool displaySettingsOnDesktop;

  @override
  String toString() {
    return 'RoomRouteArgs{key: $key, roomId: $roomId, onBack: $onBack, allowPop: $allowPop, displaySettingsOnDesktop: $displaySettingsOnDesktop}';
  }
}

/// generated route for
/// [_i37.RoomSettingsPage]
class RoomSettingsRoute extends _i62.PageRouteInfo<RoomSettingsRouteArgs> {
  RoomSettingsRoute({
    _i63.Key? key,
    required _i64.Room room,
    required _i63.VoidCallback onLeave,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          RoomSettingsRoute.name,
          args: RoomSettingsRouteArgs(
            key: key,
            room: room,
            onLeave: onLeave,
          ),
          initialChildren: children,
        );

  static const String name = 'RoomSettingsRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RoomSettingsRouteArgs>();
      return _i37.RoomSettingsPage(
        key: args.key,
        room: args.room,
        onLeave: args.onLeave,
      );
    },
  );
}

class RoomSettingsRouteArgs {
  const RoomSettingsRouteArgs({
    this.key,
    required this.room,
    required this.onLeave,
  });

  final _i63.Key? key;

  final _i64.Room room;

  final _i63.VoidCallback onLeave;

  @override
  String toString() {
    return 'RoomSettingsRouteArgs{key: $key, room: $room, onLeave: $onLeave}';
  }
}

/// generated route for
/// [_i38.SearchPage]
class SearchRoute extends _i62.PageRouteInfo<SearchRouteArgs> {
  SearchRoute({
    _i63.Key? key,
    bool isPopup = false,
    _i65.SearchMode? initialSearchMode,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          SearchRoute.name,
          args: SearchRouteArgs(
            key: key,
            isPopup: isPopup,
            initialSearchMode: initialSearchMode,
          ),
          initialChildren: children,
        );

  static const String name = 'SearchRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args =
          data.argsAs<SearchRouteArgs>(orElse: () => const SearchRouteArgs());
      return _i38.SearchPage(
        key: args.key,
        isPopup: args.isPopup,
        initialSearchMode: args.initialSearchMode,
      );
    },
  );
}

class SearchRouteArgs {
  const SearchRouteArgs({
    this.key,
    this.isPopup = false,
    this.initialSearchMode,
  });

  final _i63.Key? key;

  final bool isPopup;

  final _i65.SearchMode? initialSearchMode;

  @override
  String toString() {
    return 'SearchRouteArgs{key: $key, isPopup: $isPopup, initialSearchMode: $initialSearchMode}';
  }
}

/// generated route for
/// [_i39.SettingsAccountPage]
class SettingsAccountRoute extends _i62.PageRouteInfo<void> {
  const SettingsAccountRoute({List<_i62.PageRouteInfo>? children})
      : super(
          SettingsAccountRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsAccountRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i39.SettingsAccountPage();
    },
  );
}

/// generated route for
/// [_i40.SettingsAccountSwitchPage]
class SettingsAccountSwitchRoute
    extends _i62.PageRouteInfo<SettingsAccountSwitchRouteArgs> {
  SettingsAccountSwitchRoute({
    _i63.Key? key,
    bool popOnUserSelected = false,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          SettingsAccountSwitchRoute.name,
          args: SettingsAccountSwitchRouteArgs(
            key: key,
            popOnUserSelected: popOnUserSelected,
          ),
          initialChildren: children,
        );

  static const String name = 'SettingsAccountSwitchRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SettingsAccountSwitchRouteArgs>(
          orElse: () => const SettingsAccountSwitchRouteArgs());
      return _i40.SettingsAccountSwitchPage(
        key: args.key,
        popOnUserSelected: args.popOnUserSelected,
      );
    },
  );
}

class SettingsAccountSwitchRouteArgs {
  const SettingsAccountSwitchRouteArgs({
    this.key,
    this.popOnUserSelected = false,
  });

  final _i63.Key? key;

  final bool popOnUserSelected;

  @override
  String toString() {
    return 'SettingsAccountSwitchRouteArgs{key: $key, popOnUserSelected: $popOnUserSelected}';
  }
}

/// generated route for
/// [_i41.SettingsFeedsPage]
class SettingsFeedsRoute extends _i62.PageRouteInfo<void> {
  const SettingsFeedsRoute({List<_i62.PageRouteInfo>? children})
      : super(
          SettingsFeedsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsFeedsRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i41.SettingsFeedsPage();
    },
  );
}

/// generated route for
/// [_i42.SettingsLabsPage]
class SettingsLabsRoute extends _i62.PageRouteInfo<void> {
  const SettingsLabsRoute({List<_i62.PageRouteInfo>? children})
      : super(
          SettingsLabsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsLabsRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i42.SettingsLabsPage();
    },
  );
}

/// generated route for
/// [_i43.SettingsPage]
class SettingsRoute extends _i62.PageRouteInfo<void> {
  const SettingsRoute({List<_i62.PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i43.SettingsPage();
    },
  );
}

/// generated route for
/// [_i43.SettingsPanelInnerPage]
class SettingsPanelInnerRoute extends _i62.PageRouteInfo<void> {
  const SettingsPanelInnerRoute({List<_i62.PageRouteInfo>? children})
      : super(
          SettingsPanelInnerRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsPanelInnerRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i43.SettingsPanelInnerPage();
    },
  );
}

/// generated route for
/// [_i44.SettingsSecurityPage]
class SettingsSecurityRoute extends _i62.PageRouteInfo<void> {
  const SettingsSecurityRoute({List<_i62.PageRouteInfo>? children})
      : super(
          SettingsSecurityRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsSecurityRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i44.SettingsSecurityPage();
    },
  );
}

/// generated route for
/// [_i45.SettingsStorysDetailPage]
class SettingsStorysDetailRoute
    extends _i62.PageRouteInfo<SettingsStorysDetailRouteArgs> {
  SettingsStorysDetailRoute({
    _i63.Key? key,
    required _i64.Room room,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          SettingsStorysDetailRoute.name,
          args: SettingsStorysDetailRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'SettingsStorysDetailRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SettingsStorysDetailRouteArgs>();
      return _i45.SettingsStorysDetailPage(
        key: args.key,
        room: args.room,
      );
    },
  );
}

class SettingsStorysDetailRouteArgs {
  const SettingsStorysDetailRouteArgs({
    this.key,
    required this.room,
  });

  final _i63.Key? key;

  final _i64.Room room;

  @override
  String toString() {
    return 'SettingsStorysDetailRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i46.SettingsStorysPage]
class SettingsStorysRoute extends _i62.PageRouteInfo<void> {
  const SettingsStorysRoute({List<_i62.PageRouteInfo>? children})
      : super(
          SettingsStorysRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsStorysRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i46.SettingsStorysPage();
    },
  );
}

/// generated route for
/// [_i47.SettingsSyncPage]
class SettingsSyncRoute extends _i62.PageRouteInfo<void> {
  const SettingsSyncRoute({List<_i62.PageRouteInfo>? children})
      : super(
          SettingsSyncRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsSyncRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i47.SettingsSyncPage();
    },
  );
}

/// generated route for
/// [_i48.SettingsThemePage]
class SettingsThemeRoute extends _i62.PageRouteInfo<void> {
  const SettingsThemeRoute({List<_i62.PageRouteInfo>? children})
      : super(
          SettingsThemeRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsThemeRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i48.SettingsThemePage();
    },
  );
}

/// generated route for
/// [_i49.SocialSettingsPage]
class SocialSettingsRoute extends _i62.PageRouteInfo<SocialSettingsRouteArgs> {
  SocialSettingsRoute({
    _i63.Key? key,
    required _i64.Room room,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          SocialSettingsRoute.name,
          args: SocialSettingsRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'SocialSettingsRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SocialSettingsRouteArgs>();
      return _i49.SocialSettingsPage(
        key: args.key,
        room: args.room,
      );
    },
  );
}

class SocialSettingsRouteArgs {
  const SocialSettingsRouteArgs({
    this.key,
    required this.room,
  });

  final _i63.Key? key;

  final _i64.Room room;

  @override
  String toString() {
    return 'SocialSettingsRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i50.SpacePage]
class SpaceRoute extends _i62.PageRouteInfo<SpaceRouteArgs> {
  SpaceRoute({
    _i63.Key? key,
    required String spaceId,
    void Function()? onBack,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          SpaceRoute.name,
          args: SpaceRouteArgs(
            key: key,
            spaceId: spaceId,
            onBack: onBack,
          ),
          initialChildren: children,
        );

  static const String name = 'SpaceRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SpaceRouteArgs>();
      return _i50.SpacePage(
        key: args.key,
        spaceId: args.spaceId,
        onBack: args.onBack,
      );
    },
  );
}

class SpaceRouteArgs {
  const SpaceRouteArgs({
    this.key,
    required this.spaceId,
    this.onBack,
  });

  final _i63.Key? key;

  final String spaceId;

  final void Function()? onBack;

  @override
  String toString() {
    return 'SpaceRouteArgs{key: $key, spaceId: $spaceId, onBack: $onBack}';
  }
}

/// generated route for
/// [_i51.TabCalendarPage]
class TabCalendarRoute extends _i62.PageRouteInfo<void> {
  const TabCalendarRoute({List<_i62.PageRouteInfo>? children})
      : super(
          TabCalendarRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabCalendarRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i51.TabCalendarPage();
    },
  );
}

/// generated route for
/// [_i52.TabCameraPage]
class TabCameraRoute extends _i62.PageRouteInfo<void> {
  const TabCameraRoute({List<_i62.PageRouteInfo>? children})
      : super(
          TabCameraRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabCameraRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i52.TabCameraPage();
    },
  );
}

/// generated route for
/// [_i53.TabChatPage]
class TabChatRoute extends _i62.PageRouteInfo<void> {
  const TabChatRoute({List<_i62.PageRouteInfo>? children})
      : super(
          TabChatRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabChatRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i53.TabChatPage();
    },
  );
}

/// generated route for
/// [_i54.TabCommunityPage]
class TabCommunityRoute extends _i62.PageRouteInfo<void> {
  const TabCommunityRoute({List<_i62.PageRouteInfo>? children})
      : super(
          TabCommunityRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabCommunityRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i54.TabCommunityPage();
    },
  );
}

/// generated route for
/// [_i55.TabHomePage]
class TabHomeRoute extends _i62.PageRouteInfo<void> {
  const TabHomeRoute({List<_i62.PageRouteInfo>? children})
      : super(
          TabHomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabHomeRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i55.TabHomePage();
    },
  );
}

/// generated route for
/// [_i56.TabStoriesPage]
class TabStoriesRoute extends _i62.PageRouteInfo<void> {
  const TabStoriesRoute({List<_i62.PageRouteInfo>? children})
      : super(
          TabStoriesRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabStoriesRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i56.TabStoriesPage();
    },
  );
}

/// generated route for
/// [_i57.TodoListAddPage]
class TodoListAddRoute extends _i62.PageRouteInfo<void> {
  const TodoListAddRoute({List<_i62.PageRouteInfo>? children})
      : super(
          TodoListAddRoute.name,
          initialChildren: children,
        );

  static const String name = 'TodoListAddRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i57.TodoListAddPage();
    },
  );
}

/// generated route for
/// [_i58.TodoListPage]
class TodoListRoute extends _i62.PageRouteInfo<void> {
  const TodoListRoute({List<_i62.PageRouteInfo>? children})
      : super(
          TodoListRoute.name,
          initialChildren: children,
        );

  static const String name = 'TodoListRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      return const _i58.TodoListPage();
    },
  );
}

/// generated route for
/// [_i59.TodoRoomPage]
class TodoRoomRoute extends _i62.PageRouteInfo<TodoRoomRouteArgs> {
  TodoRoomRoute({
    _i63.Key? key,
    required _i64.Room room,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          TodoRoomRoute.name,
          args: TodoRoomRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'TodoRoomRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TodoRoomRouteArgs>();
      return _i59.TodoRoomPage(
        key: args.key,
        room: args.room,
      );
    },
  );
}

class TodoRoomRouteArgs {
  const TodoRoomRouteArgs({
    this.key,
    required this.room,
  });

  final _i63.Key? key;

  final _i64.Room room;

  @override
  String toString() {
    return 'TodoRoomRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i60.UserFollowersPage]
class UserFollowersRoute extends _i62.PageRouteInfo<UserFollowersRouteArgs> {
  UserFollowersRoute({
    _i63.Key? key,
    required _i64.Room room,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          UserFollowersRoute.name,
          args: UserFollowersRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'UserFollowersRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<UserFollowersRouteArgs>();
      return _i60.UserFollowersPage(
        key: args.key,
        room: args.room,
      );
    },
  );
}

class UserFollowersRouteArgs {
  const UserFollowersRouteArgs({
    this.key,
    required this.room,
  });

  final _i63.Key? key;

  final _i64.Room room;

  @override
  String toString() {
    return 'UserFollowersRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i61.UserViewPage]
class UserViewRoute extends _i62.PageRouteInfo<UserViewRouteArgs> {
  UserViewRoute({
    _i63.Key? key,
    String? userID,
    _i64.Room? mroom,
    List<_i62.PageRouteInfo>? children,
  }) : super(
          UserViewRoute.name,
          args: UserViewRouteArgs(
            key: key,
            userID: userID,
            mroom: mroom,
          ),
          initialChildren: children,
        );

  static const String name = 'UserViewRoute';

  static _i62.PageInfo page = _i62.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<UserViewRouteArgs>(
          orElse: () => const UserViewRouteArgs());
      return _i61.UserViewPage(
        key: args.key,
        userID: args.userID,
        mroom: args.mroom,
      );
    },
  );
}

class UserViewRouteArgs {
  const UserViewRouteArgs({
    this.key,
    this.userID,
    this.mroom,
  });

  final _i63.Key? key;

  final String? userID;

  final _i64.Room? mroom;

  @override
  String toString() {
    return 'UserViewRouteArgs{key: $key, userID: $userID, mroom: $mroom}';
  }
}
