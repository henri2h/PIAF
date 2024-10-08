// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i64;
import 'package:flutter/material.dart' as _i65;
import 'package:matrix/matrix.dart' as _i66;
import 'package:piaf/app.dart' as _i24;
import 'package:piaf/models/search/search_mode.dart' as _i67;
import 'package:piaf/pages/app_wrapper_page.dart' as _i2;
import 'package:piaf/pages/calendar_events/calendar_event_page.dart' as _i4;
import 'package:piaf/pages/calendar_events/calendar_events_list_page.dart'
    as _i3;
import 'package:piaf/pages/chat/add_user_page.dart' as _i1;
import 'package:piaf/pages/chat/chat_lib/chat_page_items/chat_page_space_page.dart'
    as _i7;
import 'package:piaf/pages/chat/chat_lib/chat_page_items/chat_page_spaces_list.dart'
    as _i6;
import 'package:piaf/pages/chat/chat_lib/chat_page_items/provider/chat_page_provider.dart'
    as _i5;
import 'package:piaf/pages/chat/chat_lib/device_media_gallery.dart' as _i16;
import 'package:piaf/pages/chat/chat_lib/matrix_create_group.dart' as _i25;
import 'package:piaf/pages/chat/chat_lib/matrix_storie_create.dart' as _i26;
import 'package:piaf/pages/chat/chat_lib/matrix_stories_page.dart' as _i28;
import 'package:piaf/pages/chat/chat_lib/room_create/create_chat_page.dart'
    as _i11;
import 'package:piaf/pages/chat/chat_lib/room_create/create_group_page.dart'
    as _i12;
import 'package:piaf/pages/chat/chat_lib/room_settings_page.dart' as _i38;
import 'package:piaf/pages/chat/chat_lib/space_page.dart' as _i51;
import 'package:piaf/pages/chat/chat_room_page.dart' as _i8;
import 'package:piaf/pages/chat/room_list_or_placeholder.dart' as _i36;
import 'package:piaf/pages/chat/room_page.dart' as _i37;
import 'package:piaf/pages/communities/community_detail_page.dart' as _i9;
import 'package:piaf/pages/communities/community_page.dart' as _i10;
import 'package:piaf/pages/debug_page.dart' as _i13;
import 'package:piaf/pages/feed/feed_creation_page.dart' as _i17;
import 'package:piaf/pages/feed/feed_list_page.dart' as _i18;
import 'package:piaf/pages/feed/feed_page.dart' as _i19;
import 'package:piaf/pages/follow_recommendations.dart' as _i20;
import 'package:piaf/pages/groups/group_page.dart' as _i21;
import 'package:piaf/pages/home/home_page.dart' as _i22;
import 'package:piaf/pages/home_space_page.dart' as _i23;
import 'package:piaf/pages/image/post_gallery_page.dart' as _i34;
import 'package:piaf/pages/matrix_loading_page.dart' as _i27;
import 'package:piaf/pages/post_page.dart' as _i35;
import 'package:piaf/pages/search/search_page.dart' as _i39;
import 'package:piaf/pages/settings/settings_account_page.dart' as _i40;
import 'package:piaf/pages/settings/settings_account_switch_page.dart' as _i41;
import 'package:piaf/pages/settings/settings_feeds_page.dart' as _i42;
import 'package:piaf/pages/settings/settings_labs_page.dart' as _i43;
import 'package:piaf/pages/settings/settings_page.dart' as _i44;
import 'package:piaf/pages/settings/settings_security_page.dart' as _i45;
import 'package:piaf/pages/settings/settings_story_detail_page.dart' as _i46;
import 'package:piaf/pages/settings/settings_storys_page.dart' as _i47;
import 'package:piaf/pages/settings/settings_sync_page.dart' as _i48;
import 'package:piaf/pages/settings/settings_theme_page.dart' as _i49;
import 'package:piaf/pages/social_settings_page.dart' as _i50;
import 'package:piaf/pages/tabs/tab_calendar_page.dart' as _i52;
import 'package:piaf/pages/tabs/tab_camera_page.dart' as _i53;
import 'package:piaf/pages/tabs/tab_chat_page.dart' as _i54;
import 'package:piaf/pages/tabs/tab_community_page.dart' as _i55;
import 'package:piaf/pages/tabs/tab_home_page.dart' as _i56;
import 'package:piaf/pages/tabs/tab_stories_page.dart' as _i57;
import 'package:piaf/pages/tabs/tab_todo_page.dart' as _i58;
import 'package:piaf/pages/todo/todo_list_add_page.dart' as _i59;
import 'package:piaf/pages/todo/todo_list_page.dart' as _i60;
import 'package:piaf/pages/todo/todo_room_page.dart' as _i61;
import 'package:piaf/pages/user/user_followers_page.dart' as _i62;
import 'package:piaf/pages/user/user_view_page.dart' as _i63;
import 'package:piaf/pages/welcome/desktop/desktop_welcome_route.dart' as _i15;
import 'package:piaf/pages/welcome/desktop_login_page.dart' as _i14;
import 'package:piaf/pages/welcome/mobile/mobile_create_account_page.dart'
    as _i29;
import 'package:piaf/pages/welcome/mobile/mobile_explore_page.dart' as _i30;
import 'package:piaf/pages/welcome/mobile/mobile_login_page.dart' as _i31;
import 'package:piaf/pages/welcome/mobile/mobile_welcome_page.dart' as _i32;
import 'package:piaf/pages/welcome/mobile/mobile_welcome_router_page.dart'
    as _i33;

/// generated route for
/// [_i1.AddUserPage]
class AddUserRoute extends _i64.PageRouteInfo<AddUserRouteArgs> {
  AddUserRoute({
    required _i65.BuildContext context,
    _i65.Key? key,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          AddUserRoute.name,
          args: AddUserRouteArgs(
            context: context,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'AddUserRoute';

  static _i64.PageInfo page = _i64.PageInfo(
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

  final _i65.BuildContext context;

  final _i65.Key? key;

  @override
  String toString() {
    return 'AddUserRouteArgs{context: $context, key: $key}';
  }
}

/// generated route for
/// [_i2.AppWrapperPage]
class AppWrapperRoute extends _i64.PageRouteInfo<void> {
  const AppWrapperRoute({List<_i64.PageRouteInfo>? children})
      : super(
          AppWrapperRoute.name,
          initialChildren: children,
        );

  static const String name = 'AppWrapperRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i2.AppWrapperPage();
    },
  );
}

/// generated route for
/// [_i3.CalendarEventListPage]
class CalendarEventListRoute extends _i64.PageRouteInfo<void> {
  const CalendarEventListRoute({List<_i64.PageRouteInfo>? children})
      : super(
          CalendarEventListRoute.name,
          initialChildren: children,
        );

  static const String name = 'CalendarEventListRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i3.CalendarEventListPage();
    },
  );
}

/// generated route for
/// [_i4.CalendarEventPage]
class CalendarEventRoute extends _i64.PageRouteInfo<CalendarEventRouteArgs> {
  CalendarEventRoute({
    _i65.Key? key,
    required _i66.Room room,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          CalendarEventRoute.name,
          args: CalendarEventRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'CalendarEventRoute';

  static _i64.PageInfo page = _i64.PageInfo(
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

  final _i65.Key? key;

  final _i66.Room room;

  @override
  String toString() {
    return 'CalendarEventRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i5.ChatPageProvider]
class ChatRouteProvider extends _i64.PageRouteInfo<ChatRouteProviderArgs> {
  ChatRouteProvider({
    _i65.Key? key,
    required _i65.Widget child,
    required _i66.Client client,
    required void Function(String?)? onRoomSelection,
    required void Function(String?) onLongPressedSpace,
    required void Function(String)? onSpaceSelection,
    String selectedSpace = "Explore",
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
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

  final _i65.Key? key;

  final _i65.Widget child;

  final _i66.Client client;

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
class ChatRouteSpaceList extends _i64.PageRouteInfo<ChatRouteSpaceListArgs> {
  ChatRouteSpaceList({
    _i65.Key? key,
    required bool popAfterSelection,
    required _i65.ScrollController scrollController,
    _i65.VoidCallback? onSelection,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
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

  final _i65.Key? key;

  final bool popAfterSelection;

  final _i65.ScrollController scrollController;

  final _i65.VoidCallback? onSelection;

  @override
  String toString() {
    return 'ChatRouteSpaceListArgs{key: $key, popAfterSelection: $popAfterSelection, scrollController: $scrollController, onSelection: $onSelection}';
  }
}

/// generated route for
/// [_i7.ChatPageSpacePage]
class ChatRouteSpaceRoute extends _i64.PageRouteInfo<void> {
  const ChatRouteSpaceRoute({List<_i64.PageRouteInfo>? children})
      : super(
          ChatRouteSpaceRoute.name,
          initialChildren: children,
        );

  static const String name = 'ChatRouteSpaceRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i7.ChatPageSpacePage();
    },
  );
}

/// generated route for
/// [_i8.ChatRoomPage]
class ChatRoomRoute extends _i64.PageRouteInfo<ChatRoomRouteArgs> {
  ChatRoomRoute({
    _i65.Key? key,
    bool displaySettingsOnDesktop = false,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          ChatRoomRoute.name,
          args: ChatRoomRouteArgs(
            key: key,
            displaySettingsOnDesktop: displaySettingsOnDesktop,
          ),
          initialChildren: children,
        );

  static const String name = 'ChatRoomRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ChatRoomRouteArgs>(
          orElse: () => const ChatRoomRouteArgs());
      return _i8.ChatRoomPage(
        key: args.key,
        displaySettingsOnDesktop: args.displaySettingsOnDesktop,
      );
    },
  );
}

class ChatRoomRouteArgs {
  const ChatRoomRouteArgs({
    this.key,
    this.displaySettingsOnDesktop = false,
  });

  final _i65.Key? key;

  final bool displaySettingsOnDesktop;

  @override
  String toString() {
    return 'ChatRoomRouteArgs{key: $key, displaySettingsOnDesktop: $displaySettingsOnDesktop}';
  }
}

/// generated route for
/// [_i9.CommunityDetailPage]
class CommunityDetailRoute
    extends _i64.PageRouteInfo<CommunityDetailRouteArgs> {
  CommunityDetailRoute({
    _i65.Key? key,
    required _i66.Room room,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          CommunityDetailRoute.name,
          args: CommunityDetailRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'CommunityDetailRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CommunityDetailRouteArgs>();
      return _i9.CommunityDetailPage(
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

  final _i65.Key? key;

  final _i66.Room room;

  @override
  String toString() {
    return 'CommunityDetailRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i10.CommunityPage]
class CommunityRoute extends _i64.PageRouteInfo<void> {
  const CommunityRoute({List<_i64.PageRouteInfo>? children})
      : super(
          CommunityRoute.name,
          initialChildren: children,
        );

  static const String name = 'CommunityRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i10.CommunityPage();
    },
  );
}

/// generated route for
/// [_i11.CreateChatPage]
class CreateChatRoute extends _i64.PageRouteInfo<CreateChatRouteArgs> {
  CreateChatRoute({
    _i65.Key? key,
    required dynamic Function(String?) onRoomSelected,
    required _i66.Client client,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          CreateChatRoute.name,
          args: CreateChatRouteArgs(
            key: key,
            onRoomSelected: onRoomSelected,
            client: client,
          ),
          initialChildren: children,
        );

  static const String name = 'CreateChatRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CreateChatRouteArgs>();
      return _i11.CreateChatPage(
        key: args.key,
        onRoomSelected: args.onRoomSelected,
        client: args.client,
      );
    },
  );
}

class CreateChatRouteArgs {
  const CreateChatRouteArgs({
    this.key,
    required this.onRoomSelected,
    required this.client,
  });

  final _i65.Key? key;

  final dynamic Function(String?) onRoomSelected;

  final _i66.Client client;

  @override
  String toString() {
    return 'CreateChatRouteArgs{key: $key, onRoomSelected: $onRoomSelected, client: $client}';
  }
}

/// generated route for
/// [_i12.CreateGroupPage]
class CreateGroupRoute extends _i64.PageRouteInfo<CreateGroupRouteArgs> {
  CreateGroupRoute({
    _i65.Key? key,
    required dynamic Function(String?) onRoomSelected,
    required _i66.Client client,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CreateGroupRouteArgs>();
      return _i12.CreateGroupPage(
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

  final _i65.Key? key;

  final dynamic Function(String?) onRoomSelected;

  final _i66.Client client;

  @override
  String toString() {
    return 'CreateGroupRouteArgs{key: $key, onRoomSelected: $onRoomSelected, client: $client}';
  }
}

/// generated route for
/// [_i13.DebugPage]
class DebugRoute extends _i64.PageRouteInfo<void> {
  const DebugRoute({List<_i64.PageRouteInfo>? children})
      : super(
          DebugRoute.name,
          initialChildren: children,
        );

  static const String name = 'DebugRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i13.DebugPage();
    },
  );
}

/// generated route for
/// [_i14.DesktopLoginPage]
class DesktopLoginRoute extends _i64.PageRouteInfo<DesktopLoginRouteArgs> {
  DesktopLoginRoute({
    _i65.Key? key,
    String? title,
    dynamic Function(bool)? onLogin,
    bool popOnLogin = false,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DesktopLoginRouteArgs>(
          orElse: () => const DesktopLoginRouteArgs());
      return _i14.DesktopLoginPage(
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

  final _i65.Key? key;

  final String? title;

  final dynamic Function(bool)? onLogin;

  final bool popOnLogin;

  @override
  String toString() {
    return 'DesktopLoginRouteArgs{key: $key, title: $title, onLogin: $onLogin, popOnLogin: $popOnLogin}';
  }
}

/// generated route for
/// [_i15.DesktopWelcomePage]
class DesktopWelcomeRoute extends _i64.PageRouteInfo<void> {
  const DesktopWelcomeRoute({List<_i64.PageRouteInfo>? children})
      : super(
          DesktopWelcomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'DesktopWelcomeRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i15.DesktopWelcomePage();
    },
  );
}

/// generated route for
/// [_i16.DeviceMediaGallery]
class DeviceMediaGallery extends _i64.PageRouteInfo<void> {
  const DeviceMediaGallery({List<_i64.PageRouteInfo>? children})
      : super(
          DeviceMediaGallery.name,
          initialChildren: children,
        );

  static const String name = 'DeviceMediaGallery';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i16.DeviceMediaGallery();
    },
  );
}

/// generated route for
/// [_i17.FeedCreationPage]
class FeedCreationRoute extends _i64.PageRouteInfo<void> {
  const FeedCreationRoute({List<_i64.PageRouteInfo>? children})
      : super(
          FeedCreationRoute.name,
          initialChildren: children,
        );

  static const String name = 'FeedCreationRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i17.FeedCreationPage();
    },
  );
}

/// generated route for
/// [_i18.FeedListPage]
class FeedListRoute extends _i64.PageRouteInfo<FeedListRouteArgs> {
  FeedListRoute({
    _i65.Key? key,
    required _i18.Selection initialSelection,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          FeedListRoute.name,
          args: FeedListRouteArgs(
            key: key,
            initialSelection: initialSelection,
          ),
          initialChildren: children,
        );

  static const String name = 'FeedListRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<FeedListRouteArgs>();
      return _i18.FeedListPage(
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

  final _i65.Key? key;

  final _i18.Selection initialSelection;

  @override
  String toString() {
    return 'FeedListRouteArgs{key: $key, initialSelection: $initialSelection}';
  }
}

/// generated route for
/// [_i19.FeedPage]
class FeedRoute extends _i64.PageRouteInfo<void> {
  const FeedRoute({List<_i64.PageRouteInfo>? children})
      : super(
          FeedRoute.name,
          initialChildren: children,
        );

  static const String name = 'FeedRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i19.FeedPage();
    },
  );
}

/// generated route for
/// [_i20.FollowRecommendationsPage]
class FollowRecommendationsRoute extends _i64.PageRouteInfo<void> {
  const FollowRecommendationsRoute({List<_i64.PageRouteInfo>? children})
      : super(
          FollowRecommendationsRoute.name,
          initialChildren: children,
        );

  static const String name = 'FollowRecommendationsRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i20.FollowRecommendationsPage();
    },
  );
}

/// generated route for
/// [_i21.GroupPage]
class GroupRoute extends _i64.PageRouteInfo<GroupRouteArgs> {
  GroupRoute({
    _i65.Key? key,
    required String roomId,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<GroupRouteArgs>(
          orElse: () => GroupRouteArgs(roomId: pathParams.getString('roomId')));
      return _i21.GroupPage(
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

  final _i65.Key? key;

  final String roomId;

  @override
  String toString() {
    return 'GroupRouteArgs{key: $key, roomId: $roomId}';
  }
}

/// generated route for
/// [_i22.HomePage]
class HomeRoute extends _i64.PageRouteInfo<void> {
  const HomeRoute({List<_i64.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i22.HomePage();
    },
  );
}

/// generated route for
/// [_i23.HomeSpacePage]
class HomeSpaceRoute extends _i64.PageRouteInfo<void> {
  const HomeSpaceRoute({List<_i64.PageRouteInfo>? children})
      : super(
          HomeSpaceRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeSpaceRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i23.HomeSpacePage();
    },
  );
}

/// generated route for
/// [_i24.MainRouterPage]
class MainRouterRoute extends _i64.PageRouteInfo<void> {
  const MainRouterRoute({List<_i64.PageRouteInfo>? children})
      : super(
          MainRouterRoute.name,
          initialChildren: children,
        );

  static const String name = 'MainRouterRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i24.MainRouterPage();
    },
  );
}

/// generated route for
/// [_i25.MatrixCreateGroup]
class MatrixCreateGroup extends _i64.PageRouteInfo<MatrixCreateGroupArgs> {
  MatrixCreateGroup({
    _i65.Key? key,
    required _i66.Client client,
    void Function(String)? onGroupCreated,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MatrixCreateGroupArgs>();
      return _i25.MatrixCreateGroup(
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

  final _i65.Key? key;

  final _i66.Client client;

  final void Function(String)? onGroupCreated;

  @override
  String toString() {
    return 'MatrixCreateGroupArgs{key: $key, client: $client, onGroupCreated: $onGroupCreated}';
  }
}

/// generated route for
/// [_i26.MatrixCreateStoriePage]
class MatrixCreateStorieRoute
    extends _i64.PageRouteInfo<MatrixCreateStorieRouteArgs> {
  MatrixCreateStorieRoute({
    _i65.Key? key,
    required _i66.Client client,
    required _i66.Room r,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MatrixCreateStorieRouteArgs>();
      return _i26.MatrixCreateStoriePage(
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

  final _i65.Key? key;

  final _i66.Client client;

  final _i66.Room r;

  @override
  String toString() {
    return 'MatrixCreateStorieRouteArgs{key: $key, client: $client, r: $r}';
  }
}

/// generated route for
/// [_i27.MatrixLoadingPage]
class MatrixLoadingRoute extends _i64.PageRouteInfo<void> {
  const MatrixLoadingRoute({List<_i64.PageRouteInfo>? children})
      : super(
          MatrixLoadingRoute.name,
          initialChildren: children,
        );

  static const String name = 'MatrixLoadingRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i27.MatrixLoadingPage();
    },
  );
}

/// generated route for
/// [_i28.MatrixStoriesPage]
class MatrixStoriesRoute extends _i64.PageRouteInfo<MatrixStoriesRouteArgs> {
  MatrixStoriesRoute({
    required _i66.Room room,
    _i65.Key? key,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          MatrixStoriesRoute.name,
          args: MatrixStoriesRouteArgs(
            room: room,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'MatrixStoriesRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MatrixStoriesRouteArgs>();
      return _i28.MatrixStoriesPage(
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

  final _i66.Room room;

  final _i65.Key? key;

  @override
  String toString() {
    return 'MatrixStoriesRouteArgs{room: $room, key: $key}';
  }
}

/// generated route for
/// [_i29.MobileCreateAccountPage]
class MobileCreateAccountRoute extends _i64.PageRouteInfo<void> {
  const MobileCreateAccountRoute({List<_i64.PageRouteInfo>? children})
      : super(
          MobileCreateAccountRoute.name,
          initialChildren: children,
        );

  static const String name = 'MobileCreateAccountRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i29.MobileCreateAccountPage();
    },
  );
}

/// generated route for
/// [_i30.MobileExplorePage]
class MobileExploreRoute extends _i64.PageRouteInfo<void> {
  const MobileExploreRoute({List<_i64.PageRouteInfo>? children})
      : super(
          MobileExploreRoute.name,
          initialChildren: children,
        );

  static const String name = 'MobileExploreRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i30.MobileExplorePage();
    },
  );
}

/// generated route for
/// [_i31.MobileLoginPage]
class MobileLoginRoute extends _i64.PageRouteInfo<MobileLoginRouteArgs> {
  MobileLoginRoute({
    _i65.Key? key,
    bool popOnLogin = false,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          MobileLoginRoute.name,
          args: MobileLoginRouteArgs(
            key: key,
            popOnLogin: popOnLogin,
          ),
          initialChildren: children,
        );

  static const String name = 'MobileLoginRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MobileLoginRouteArgs>(
          orElse: () => const MobileLoginRouteArgs());
      return _i31.MobileLoginPage(
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

  final _i65.Key? key;

  final bool popOnLogin;

  @override
  String toString() {
    return 'MobileLoginRouteArgs{key: $key, popOnLogin: $popOnLogin}';
  }
}

/// generated route for
/// [_i32.MobileWelcomePage]
class MobileWelcomeRoute extends _i64.PageRouteInfo<void> {
  const MobileWelcomeRoute({List<_i64.PageRouteInfo>? children})
      : super(
          MobileWelcomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'MobileWelcomeRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i32.MobileWelcomePage();
    },
  );
}

/// generated route for
/// [_i33.MobileWelcomeRouterPage]
class MobileWelcomeRouter extends _i64.PageRouteInfo<void> {
  const MobileWelcomeRouter({List<_i64.PageRouteInfo>? children})
      : super(
          MobileWelcomeRouter.name,
          initialChildren: children,
        );

  static const String name = 'MobileWelcomeRouter';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i33.MobileWelcomeRouterPage();
    },
  );
}

/// generated route for
/// [_i34.PostGalleryPage]
class PostGalleryRoute extends _i64.PageRouteInfo<PostGalleryRouteArgs> {
  PostGalleryRoute({
    _i65.Key? key,
    required _i66.Event post,
    _i66.Event? image,
    String? selectedImageEventId,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PostGalleryRouteArgs>();
      return _i34.PostGalleryPage(
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

  final _i65.Key? key;

  final _i66.Event post;

  final _i66.Event? image;

  final String? selectedImageEventId;

  @override
  String toString() {
    return 'PostGalleryRouteArgs{key: $key, post: $post, image: $image, selectedImageEventId: $selectedImageEventId}';
  }
}

/// generated route for
/// [_i35.PostPage]
class PostRoute extends _i64.PageRouteInfo<PostRouteArgs> {
  PostRoute({
    _i65.Key? key,
    required _i66.Event event,
    required _i66.Timeline timeline,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PostRouteArgs>();
      return _i35.PostPage(
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

  final _i65.Key? key;

  final _i66.Event event;

  final _i66.Timeline timeline;

  @override
  String toString() {
    return 'PostRouteArgs{key: $key, event: $event, timeline: $timeline}';
  }
}

/// generated route for
/// [_i36.RoomListOrPlaceHolderPage]
class RoomListOrPlaceHolderRoute extends _i64.PageRouteInfo<void> {
  const RoomListOrPlaceHolderRoute({List<_i64.PageRouteInfo>? children})
      : super(
          RoomListOrPlaceHolderRoute.name,
          initialChildren: children,
        );

  static const String name = 'RoomListOrPlaceHolderRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i36.RoomListOrPlaceHolderPage();
    },
  );
}

/// generated route for
/// [_i37.RoomPage]
class RoomRoute extends _i64.PageRouteInfo<RoomRouteArgs> {
  RoomRoute({
    _i65.Key? key,
    required String roomId,
    required _i66.Client client,
    void Function()? onBack,
    bool allowPop = false,
    bool displaySettingsOnDesktop = false,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          RoomRoute.name,
          args: RoomRouteArgs(
            key: key,
            roomId: roomId,
            client: client,
            onBack: onBack,
            allowPop: allowPop,
            displaySettingsOnDesktop: displaySettingsOnDesktop,
          ),
          initialChildren: children,
        );

  static const String name = 'RoomRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RoomRouteArgs>();
      return _i37.RoomPage(
        key: args.key,
        roomId: args.roomId,
        client: args.client,
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
    required this.client,
    this.onBack,
    this.allowPop = false,
    this.displaySettingsOnDesktop = false,
  });

  final _i65.Key? key;

  final String roomId;

  final _i66.Client client;

  final void Function()? onBack;

  final bool allowPop;

  final bool displaySettingsOnDesktop;

  @override
  String toString() {
    return 'RoomRouteArgs{key: $key, roomId: $roomId, client: $client, onBack: $onBack, allowPop: $allowPop, displaySettingsOnDesktop: $displaySettingsOnDesktop}';
  }
}

/// generated route for
/// [_i38.RoomSettingsPage]
class RoomSettingsRoute extends _i64.PageRouteInfo<RoomSettingsRouteArgs> {
  RoomSettingsRoute({
    _i65.Key? key,
    required _i66.Room room,
    required _i65.VoidCallback onLeave,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RoomSettingsRouteArgs>();
      return _i38.RoomSettingsPage(
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

  final _i65.Key? key;

  final _i66.Room room;

  final _i65.VoidCallback onLeave;

  @override
  String toString() {
    return 'RoomSettingsRouteArgs{key: $key, room: $room, onLeave: $onLeave}';
  }
}

/// generated route for
/// [_i39.SearchPage]
class SearchRoute extends _i64.PageRouteInfo<SearchRouteArgs> {
  SearchRoute({
    _i65.Key? key,
    bool isPopup = false,
    _i67.SearchMode? initialSearchMode,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args =
          data.argsAs<SearchRouteArgs>(orElse: () => const SearchRouteArgs());
      return _i39.SearchPage(
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

  final _i65.Key? key;

  final bool isPopup;

  final _i67.SearchMode? initialSearchMode;

  @override
  String toString() {
    return 'SearchRouteArgs{key: $key, isPopup: $isPopup, initialSearchMode: $initialSearchMode}';
  }
}

/// generated route for
/// [_i40.SettingsAccountPage]
class SettingsAccountRoute extends _i64.PageRouteInfo<void> {
  const SettingsAccountRoute({List<_i64.PageRouteInfo>? children})
      : super(
          SettingsAccountRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsAccountRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i40.SettingsAccountPage();
    },
  );
}

/// generated route for
/// [_i41.SettingsAccountSwitchPage]
class SettingsAccountSwitchRoute
    extends _i64.PageRouteInfo<SettingsAccountSwitchRouteArgs> {
  SettingsAccountSwitchRoute({
    _i65.Key? key,
    bool popOnUserSelected = false,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          SettingsAccountSwitchRoute.name,
          args: SettingsAccountSwitchRouteArgs(
            key: key,
            popOnUserSelected: popOnUserSelected,
          ),
          initialChildren: children,
        );

  static const String name = 'SettingsAccountSwitchRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SettingsAccountSwitchRouteArgs>(
          orElse: () => const SettingsAccountSwitchRouteArgs());
      return _i41.SettingsAccountSwitchPage(
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

  final _i65.Key? key;

  final bool popOnUserSelected;

  @override
  String toString() {
    return 'SettingsAccountSwitchRouteArgs{key: $key, popOnUserSelected: $popOnUserSelected}';
  }
}

/// generated route for
/// [_i42.SettingsFeedsPage]
class SettingsFeedsRoute extends _i64.PageRouteInfo<void> {
  const SettingsFeedsRoute({List<_i64.PageRouteInfo>? children})
      : super(
          SettingsFeedsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsFeedsRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i42.SettingsFeedsPage();
    },
  );
}

/// generated route for
/// [_i43.SettingsLabsPage]
class SettingsLabsRoute extends _i64.PageRouteInfo<void> {
  const SettingsLabsRoute({List<_i64.PageRouteInfo>? children})
      : super(
          SettingsLabsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsLabsRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i43.SettingsLabsPage();
    },
  );
}

/// generated route for
/// [_i44.SettingsPage]
class SettingsRoute extends _i64.PageRouteInfo<void> {
  const SettingsRoute({List<_i64.PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i44.SettingsPage();
    },
  );
}

/// generated route for
/// [_i44.SettingsPanelInnerPage]
class SettingsPanelInnerRoute extends _i64.PageRouteInfo<void> {
  const SettingsPanelInnerRoute({List<_i64.PageRouteInfo>? children})
      : super(
          SettingsPanelInnerRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsPanelInnerRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i44.SettingsPanelInnerPage();
    },
  );
}

/// generated route for
/// [_i45.SettingsSecurityPage]
class SettingsSecurityRoute extends _i64.PageRouteInfo<void> {
  const SettingsSecurityRoute({List<_i64.PageRouteInfo>? children})
      : super(
          SettingsSecurityRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsSecurityRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i45.SettingsSecurityPage();
    },
  );
}

/// generated route for
/// [_i46.SettingsStorysDetailPage]
class SettingsStorysDetailRoute
    extends _i64.PageRouteInfo<SettingsStorysDetailRouteArgs> {
  SettingsStorysDetailRoute({
    _i65.Key? key,
    required _i66.Room room,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          SettingsStorysDetailRoute.name,
          args: SettingsStorysDetailRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'SettingsStorysDetailRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SettingsStorysDetailRouteArgs>();
      return _i46.SettingsStorysDetailPage(
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

  final _i65.Key? key;

  final _i66.Room room;

  @override
  String toString() {
    return 'SettingsStorysDetailRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i47.SettingsStorysPage]
class SettingsStorysRoute extends _i64.PageRouteInfo<void> {
  const SettingsStorysRoute({List<_i64.PageRouteInfo>? children})
      : super(
          SettingsStorysRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsStorysRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i47.SettingsStorysPage();
    },
  );
}

/// generated route for
/// [_i48.SettingsSyncPage]
class SettingsSyncRoute extends _i64.PageRouteInfo<void> {
  const SettingsSyncRoute({List<_i64.PageRouteInfo>? children})
      : super(
          SettingsSyncRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsSyncRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i48.SettingsSyncPage();
    },
  );
}

/// generated route for
/// [_i49.SettingsThemePage]
class SettingsThemeRoute extends _i64.PageRouteInfo<void> {
  const SettingsThemeRoute({List<_i64.PageRouteInfo>? children})
      : super(
          SettingsThemeRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsThemeRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i49.SettingsThemePage();
    },
  );
}

/// generated route for
/// [_i50.SocialSettingsPage]
class SocialSettingsRoute extends _i64.PageRouteInfo<SocialSettingsRouteArgs> {
  SocialSettingsRoute({
    _i65.Key? key,
    required _i66.Room room,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          SocialSettingsRoute.name,
          args: SocialSettingsRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'SocialSettingsRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SocialSettingsRouteArgs>();
      return _i50.SocialSettingsPage(
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

  final _i65.Key? key;

  final _i66.Room room;

  @override
  String toString() {
    return 'SocialSettingsRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i51.SpacePage]
class SpaceRoute extends _i64.PageRouteInfo<SpaceRouteArgs> {
  SpaceRoute({
    _i65.Key? key,
    required String spaceId,
    required _i66.Client client,
    void Function()? onBack,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          SpaceRoute.name,
          args: SpaceRouteArgs(
            key: key,
            spaceId: spaceId,
            client: client,
            onBack: onBack,
          ),
          initialChildren: children,
        );

  static const String name = 'SpaceRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SpaceRouteArgs>();
      return _i51.SpacePage(
        key: args.key,
        spaceId: args.spaceId,
        client: args.client,
        onBack: args.onBack,
      );
    },
  );
}

class SpaceRouteArgs {
  const SpaceRouteArgs({
    this.key,
    required this.spaceId,
    required this.client,
    this.onBack,
  });

  final _i65.Key? key;

  final String spaceId;

  final _i66.Client client;

  final void Function()? onBack;

  @override
  String toString() {
    return 'SpaceRouteArgs{key: $key, spaceId: $spaceId, client: $client, onBack: $onBack}';
  }
}

/// generated route for
/// [_i52.TabCalendarPage]
class TabCalendarRoute extends _i64.PageRouteInfo<void> {
  const TabCalendarRoute({List<_i64.PageRouteInfo>? children})
      : super(
          TabCalendarRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabCalendarRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i52.TabCalendarPage();
    },
  );
}

/// generated route for
/// [_i53.TabCameraPage]
class TabCameraRoute extends _i64.PageRouteInfo<void> {
  const TabCameraRoute({List<_i64.PageRouteInfo>? children})
      : super(
          TabCameraRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabCameraRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i53.TabCameraPage();
    },
  );
}

/// generated route for
/// [_i54.TabChatPage]
class TabChatRoute extends _i64.PageRouteInfo<void> {
  const TabChatRoute({List<_i64.PageRouteInfo>? children})
      : super(
          TabChatRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabChatRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i54.TabChatPage();
    },
  );
}

/// generated route for
/// [_i55.TabCommunityPage]
class TabCommunityRoute extends _i64.PageRouteInfo<void> {
  const TabCommunityRoute({List<_i64.PageRouteInfo>? children})
      : super(
          TabCommunityRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabCommunityRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i55.TabCommunityPage();
    },
  );
}

/// generated route for
/// [_i56.TabHomePage]
class TabHomeRoute extends _i64.PageRouteInfo<void> {
  const TabHomeRoute({List<_i64.PageRouteInfo>? children})
      : super(
          TabHomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabHomeRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i56.TabHomePage();
    },
  );
}

/// generated route for
/// [_i57.TabStoriesPage]
class TabStoriesRoute extends _i64.PageRouteInfo<void> {
  const TabStoriesRoute({List<_i64.PageRouteInfo>? children})
      : super(
          TabStoriesRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabStoriesRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i57.TabStoriesPage();
    },
  );
}

/// generated route for
/// [_i58.TabTodoPage]
class TabTodoRoute extends _i64.PageRouteInfo<void> {
  const TabTodoRoute({List<_i64.PageRouteInfo>? children})
      : super(
          TabTodoRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabTodoRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i58.TabTodoPage();
    },
  );
}

/// generated route for
/// [_i59.TodoListAddPage]
class TodoListAddRoute extends _i64.PageRouteInfo<void> {
  const TodoListAddRoute({List<_i64.PageRouteInfo>? children})
      : super(
          TodoListAddRoute.name,
          initialChildren: children,
        );

  static const String name = 'TodoListAddRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i59.TodoListAddPage();
    },
  );
}

/// generated route for
/// [_i60.TodoListPage]
class TodoListRoute extends _i64.PageRouteInfo<void> {
  const TodoListRoute({List<_i64.PageRouteInfo>? children})
      : super(
          TodoListRoute.name,
          initialChildren: children,
        );

  static const String name = 'TodoListRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      return const _i60.TodoListPage();
    },
  );
}

/// generated route for
/// [_i61.TodoRoomPage]
class TodoRoomRoute extends _i64.PageRouteInfo<TodoRoomRouteArgs> {
  TodoRoomRoute({
    _i65.Key? key,
    required _i66.Room room,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          TodoRoomRoute.name,
          args: TodoRoomRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'TodoRoomRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TodoRoomRouteArgs>();
      return _i61.TodoRoomPage(
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

  final _i65.Key? key;

  final _i66.Room room;

  @override
  String toString() {
    return 'TodoRoomRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i62.UserFollowersPage]
class UserFollowersRoute extends _i64.PageRouteInfo<UserFollowersRouteArgs> {
  UserFollowersRoute({
    _i65.Key? key,
    required _i66.Room room,
    List<_i64.PageRouteInfo>? children,
  }) : super(
          UserFollowersRoute.name,
          args: UserFollowersRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'UserFollowersRoute';

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<UserFollowersRouteArgs>();
      return _i62.UserFollowersPage(
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

  final _i65.Key? key;

  final _i66.Room room;

  @override
  String toString() {
    return 'UserFollowersRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i63.UserViewPage]
class UserViewRoute extends _i64.PageRouteInfo<UserViewRouteArgs> {
  UserViewRoute({
    _i65.Key? key,
    String? userID,
    _i66.Room? mroom,
    List<_i64.PageRouteInfo>? children,
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

  static _i64.PageInfo page = _i64.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<UserViewRouteArgs>(
          orElse: () => const UserViewRouteArgs());
      return _i63.UserViewPage(
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

  final _i65.Key? key;

  final String? userID;

  final _i66.Room? mroom;

  @override
  String toString() {
    return 'UserViewRouteArgs{key: $key, userID: $userID, mroom: $mroom}';
  }
}
