// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i49;
import 'package:flutter/material.dart' as _i50;
import 'package:matrix/matrix.dart' as _i51;
import 'package:minestrix/models/search/search_mode.dart' as _i52;
import 'package:minestrix/pages/app_wrapper_page.dart' as _i2;
import 'package:minestrix/pages/calendar_events/calendar_event_page.dart'
    as _i4;
import 'package:minestrix/pages/calendar_events/calendar_events_list_page.dart'
    as _i3;
import 'package:minestrix/pages/chat/add_user_page.dart' as _i1;
import 'package:minestrix/pages/chat/overrides/override_room_list_page.dart'
    as _i21;
import 'package:minestrix/pages/chat/overrides/override_room_list_room_page.dart'
    as _i22;
import 'package:minestrix/pages/chat/overrides/override_room_list_space_page.dart'
    as _i23;
import 'package:minestrix/pages/chat/overrides/override_room_page.dart' as _i24;
import 'package:minestrix/pages/chat/overrides/override_room_space_page.dart'
    as _i25;
import 'package:minestrix/pages/chat/room_list_page.dart' as _i28;
import 'package:minestrix/pages/communities/community_detail_page.dart' as _i5;
import 'package:minestrix/pages/communities/community_page.dart' as _i6;
import 'package:minestrix/pages/debug_page.dart' as _i8;
import 'package:minestrix/pages/feed/feed_list_page.dart' as _i11;
import 'package:minestrix/pages/feed/feed_page.dart' as _i12;
import 'package:minestrix/pages/follow_recommendations.dart' as _i13;
import 'package:minestrix/pages/groups/create_group_page.dart' as _i7;
import 'package:minestrix/pages/groups/group_page.dart' as _i14;
import 'package:minestrix/pages/image/post_gallery_page.dart' as _i26;
import 'package:minestrix/pages/matrix_loading_page.dart' as _i15;
import 'package:minestrix/pages/post_page.dart' as _i27;
import 'package:minestrix/pages/search/search_page.dart' as _i29;
import 'package:minestrix/pages/settings/settings_account_page.dart' as _i30;
import 'package:minestrix/pages/settings/settings_account_switch_page.dart'
    as _i31;
import 'package:minestrix/pages/settings/settings_feeds_page.dart' as _i32;
import 'package:minestrix/pages/settings/settings_labs_page.dart' as _i33;
import 'package:minestrix/pages/settings/settings_page.dart' as _i34;
import 'package:minestrix/pages/settings/settings_security_page.dart' as _i35;
import 'package:minestrix/pages/settings/settings_story_detail_page.dart'
    as _i36;
import 'package:minestrix/pages/settings/settings_storys_page.dart' as _i37;
import 'package:minestrix/pages/settings/settings_sync_page.dart' as _i38;
import 'package:minestrix/pages/settings/settings_theme_page.dart' as _i39;
import 'package:minestrix/pages/social_settings_page.dart' as _i40;
import 'package:minestrix/pages/tabs/tab_calendar_page.dart' as _i41;
import 'package:minestrix/pages/tabs/tab_camera_page.dart' as _i42;
import 'package:minestrix/pages/tabs/tab_chat_page.dart' as _i43;
import 'package:minestrix/pages/tabs/tab_community_page.dart' as _i44;
import 'package:minestrix/pages/tabs/tab_home_page.dart' as _i45;
import 'package:minestrix/pages/tabs/tab_stories_page.dart' as _i46;
import 'package:minestrix/pages/user/user_followers_page.dart' as _i47;
import 'package:minestrix/pages/user/user_view_page.dart' as _i48;
import 'package:minestrix/pages/welcome/desktop/desktop_welcome_route.dart'
    as _i10;
import 'package:minestrix/pages/welcome/desktop_login_page.dart' as _i9;
import 'package:minestrix/pages/welcome/mobile/mobile_create_account_page.dart'
    as _i16;
import 'package:minestrix/pages/welcome/mobile/mobile_explore_page.dart'
    as _i17;
import 'package:minestrix/pages/welcome/mobile/mobile_login_page.dart' as _i18;
import 'package:minestrix/pages/welcome/mobile/mobile_welcome_page.dart'
    as _i19;
import 'package:minestrix/pages/welcome/mobile/mobile_welcome_router_page.dart'
    as _i20;

abstract class $AppRouter extends _i49.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i49.PageFactory> pagesMap = {
    AddUserRoute.name: (routeData) {
      final args = routeData.argsAs<AddUserRouteArgs>();
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.AddUserPage(
          args.context,
          key: args.key,
        ),
      );
    },
    AppWrapperRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.AppWrapperPage(),
      );
    },
    CalendarEventListRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i3.CalendarEventListPage(),
      );
    },
    CalendarEventRoute.name: (routeData) {
      final args = routeData.argsAs<CalendarEventRouteArgs>();
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i4.CalendarEventPage(
          key: args.key,
          room: args.room,
        ),
      );
    },
    CommunityDetailRoute.name: (routeData) {
      final args = routeData.argsAs<CommunityDetailRouteArgs>();
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i5.CommunityDetailPage(
          key: args.key,
          room: args.room,
        ),
      );
    },
    CommunityRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i6.CommunityPage(),
      );
    },
    CreateGroupRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i7.CreateGroupPage(),
      );
    },
    DebugRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i8.DebugPage(),
      );
    },
    DesktopLoginRoute.name: (routeData) {
      final args = routeData.argsAs<DesktopLoginRouteArgs>(
          orElse: () => const DesktopLoginRouteArgs());
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i9.DesktopLoginPage(
          key: args.key,
          title: args.title,
          onLogin: args.onLogin,
          popOnLogin: args.popOnLogin,
        ),
      );
    },
    DesktopWelcomeRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i10.DesktopWelcomePage(),
      );
    },
    FeedListRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i11.FeedListPage(),
      );
    },
    FeedRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i12.FeedPage(),
      );
    },
    FollowRecommendationsRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i13.FollowRecommendationsPage(),
      );
    },
    GroupRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<GroupRouteArgs>(
          orElse: () => GroupRouteArgs(roomId: pathParams.getString('roomId')));
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i14.GroupPage(
          key: args.key,
          roomId: args.roomId,
        ),
      );
    },
    MatrixLoadingRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i15.MatrixLoadingPage(),
      );
    },
    MobileCreateAccountRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i16.MobileCreateAccountPage(),
      );
    },
    MobileExploreRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i17.MobileExplorePage(),
      );
    },
    MobileLoginRoute.name: (routeData) {
      final args = routeData.argsAs<MobileLoginRouteArgs>(
          orElse: () => const MobileLoginRouteArgs());
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i18.MobileLoginPage(
          key: args.key,
          popOnLogin: args.popOnLogin,
        ),
      );
    },
    MobileWelcomeRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i19.MobileWelcomePage(),
      );
    },
    MobileWelcomeRouter.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i20.MobileWelcomeRouterPage(),
      );
    },
    OverrideRoomListRoute.name: (routeData) {
      final args = routeData.argsAs<OverrideRoomListRouteArgs>(
          orElse: () => const OverrideRoomListRouteArgs());
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i21.OverrideRoomListPage(
          key: args.key,
          isMobile: args.isMobile,
        ),
      );
    },
    OverrideRoomListRoomRoute.name: (routeData) {
      final args = routeData.argsAs<OverrideRoomListRoomRouteArgs>(
          orElse: () => const OverrideRoomListRoomRouteArgs());
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i22.OverrideRoomListRoomPage(
          key: args.key,
          displaySettingsOnDesktop: args.displaySettingsOnDesktop,
        ),
      );
    },
    OverrideRoomListSpaceRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i23.OverrideRoomListSpacePage(),
      );
    },
    OverrideRoomRoute.name: (routeData) {
      final args = routeData.argsAs<OverrideRoomRouteArgs>();
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i24.OverrideRoomPage(
          key: args.key,
          roomId: args.roomId,
          client: args.client,
          onBack: args.onBack,
          allowPop: args.allowPop,
          displaySettingsOnDesktop: args.displaySettingsOnDesktop,
        ),
      );
    },
    OverrideRoomSpaceRoute.name: (routeData) {
      final args = routeData.argsAs<OverrideRoomSpaceRouteArgs>();
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i25.OverrideRoomSpacePage(
          key: args.key,
          spaceId: args.spaceId,
          client: args.client,
          onBack: args.onBack,
        ),
      );
    },
    PostGalleryRoute.name: (routeData) {
      final args = routeData.argsAs<PostGalleryRouteArgs>();
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i26.PostGalleryPage(
          key: args.key,
          post: args.post,
          image: args.image,
          selectedImageEventId: args.selectedImageEventId,
        ),
      );
    },
    PostRoute.name: (routeData) {
      final args = routeData.argsAs<PostRouteArgs>();
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i27.PostPage(
          key: args.key,
          event: args.event,
          timeline: args.timeline,
        ),
      );
    },
    RoomListRoute.name: (routeData) {
      final args = routeData.argsAs<RoomListRouteArgs>(
          orElse: () => const RoomListRouteArgs());
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i28.RoomListPage(
          key: args.key,
          isMobile: args.isMobile,
        ),
      );
    },
    SearchRoute.name: (routeData) {
      final args = routeData.argsAs<SearchRouteArgs>(
          orElse: () => const SearchRouteArgs());
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i29.SearchPage(
          key: args.key,
          isPopup: args.isPopup,
          initialSearchMode: args.initialSearchMode,
        ),
      );
    },
    SettingsAccountRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i30.SettingsAccountPage(),
      );
    },
    SettingsAccountSwitchRoute.name: (routeData) {
      final args = routeData.argsAs<SettingsAccountSwitchRouteArgs>(
          orElse: () => const SettingsAccountSwitchRouteArgs());
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i31.SettingsAccountSwitchPage(
          key: args.key,
          popOnUserSelected: args.popOnUserSelected,
        ),
      );
    },
    SettingsFeedsRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i32.SettingsFeedsPage(),
      );
    },
    SettingsLabsRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i33.SettingsLabsPage(),
      );
    },
    SettingsRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i34.SettingsPage(),
      );
    },
    SettingsPanelInnerRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i34.SettingsPanelInnerPage(),
      );
    },
    SettingsSecurityRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i35.SettingsSecurityPage(),
      );
    },
    SettingsStorysDetailRoute.name: (routeData) {
      final args = routeData.argsAs<SettingsStorysDetailRouteArgs>();
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i36.SettingsStorysDetailPage(
          key: args.key,
          room: args.room,
        ),
      );
    },
    SettingsStorysRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i37.SettingsStorysPage(),
      );
    },
    SettingsSyncRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i38.SettingsSyncPage(),
      );
    },
    SettingsThemeRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i39.SettingsThemePage(),
      );
    },
    SocialSettingsRoute.name: (routeData) {
      final args = routeData.argsAs<SocialSettingsRouteArgs>();
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i40.SocialSettingsPage(
          key: args.key,
          room: args.room,
        ),
      );
    },
    TabCalendarRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i41.TabCalendarPage(),
      );
    },
    TabCameraRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i42.TabCameraPage(),
      );
    },
    TabChatRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i43.TabChatPage(),
      );
    },
    TabCommunityRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i44.TabCommunityPage(),
      );
    },
    TabHomeRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i45.TabHomePage(),
      );
    },
    TabStoriesRoute.name: (routeData) {
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i46.TabStoriesPage(),
      );
    },
    UserFollowersRoute.name: (routeData) {
      final args = routeData.argsAs<UserFollowersRouteArgs>();
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i47.UserFollowersPage(
          key: args.key,
          room: args.room,
        ),
      );
    },
    UserViewRoute.name: (routeData) {
      final args = routeData.argsAs<UserViewRouteArgs>(
          orElse: () => const UserViewRouteArgs());
      return _i49.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i48.UserViewPage(
          key: args.key,
          userID: args.userID,
          mroom: args.mroom,
        ),
      );
    },
  };
}

/// generated route for
/// [_i1.AddUserPage]
class AddUserRoute extends _i49.PageRouteInfo<AddUserRouteArgs> {
  AddUserRoute({
    required _i50.BuildContext context,
    _i50.Key? key,
    List<_i49.PageRouteInfo>? children,
  }) : super(
          AddUserRoute.name,
          args: AddUserRouteArgs(
            context: context,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'AddUserRoute';

  static const _i49.PageInfo<AddUserRouteArgs> page =
      _i49.PageInfo<AddUserRouteArgs>(name);
}

class AddUserRouteArgs {
  const AddUserRouteArgs({
    required this.context,
    this.key,
  });

  final _i50.BuildContext context;

  final _i50.Key? key;

  @override
  String toString() {
    return 'AddUserRouteArgs{context: $context, key: $key}';
  }
}

/// generated route for
/// [_i2.AppWrapperPage]
class AppWrapperRoute extends _i49.PageRouteInfo<void> {
  const AppWrapperRoute({List<_i49.PageRouteInfo>? children})
      : super(
          AppWrapperRoute.name,
          initialChildren: children,
        );

  static const String name = 'AppWrapperRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i3.CalendarEventListPage]
class CalendarEventListRoute extends _i49.PageRouteInfo<void> {
  const CalendarEventListRoute({List<_i49.PageRouteInfo>? children})
      : super(
          CalendarEventListRoute.name,
          initialChildren: children,
        );

  static const String name = 'CalendarEventListRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i4.CalendarEventPage]
class CalendarEventRoute extends _i49.PageRouteInfo<CalendarEventRouteArgs> {
  CalendarEventRoute({
    _i50.Key? key,
    required _i51.Room room,
    List<_i49.PageRouteInfo>? children,
  }) : super(
          CalendarEventRoute.name,
          args: CalendarEventRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'CalendarEventRoute';

  static const _i49.PageInfo<CalendarEventRouteArgs> page =
      _i49.PageInfo<CalendarEventRouteArgs>(name);
}

class CalendarEventRouteArgs {
  const CalendarEventRouteArgs({
    this.key,
    required this.room,
  });

  final _i50.Key? key;

  final _i51.Room room;

  @override
  String toString() {
    return 'CalendarEventRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i5.CommunityDetailPage]
class CommunityDetailRoute
    extends _i49.PageRouteInfo<CommunityDetailRouteArgs> {
  CommunityDetailRoute({
    _i50.Key? key,
    required _i51.Room room,
    List<_i49.PageRouteInfo>? children,
  }) : super(
          CommunityDetailRoute.name,
          args: CommunityDetailRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'CommunityDetailRoute';

  static const _i49.PageInfo<CommunityDetailRouteArgs> page =
      _i49.PageInfo<CommunityDetailRouteArgs>(name);
}

class CommunityDetailRouteArgs {
  const CommunityDetailRouteArgs({
    this.key,
    required this.room,
  });

  final _i50.Key? key;

  final _i51.Room room;

  @override
  String toString() {
    return 'CommunityDetailRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i6.CommunityPage]
class CommunityRoute extends _i49.PageRouteInfo<void> {
  const CommunityRoute({List<_i49.PageRouteInfo>? children})
      : super(
          CommunityRoute.name,
          initialChildren: children,
        );

  static const String name = 'CommunityRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i7.CreateGroupPage]
class CreateGroupRoute extends _i49.PageRouteInfo<void> {
  const CreateGroupRoute({List<_i49.PageRouteInfo>? children})
      : super(
          CreateGroupRoute.name,
          initialChildren: children,
        );

  static const String name = 'CreateGroupRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i8.DebugPage]
class DebugRoute extends _i49.PageRouteInfo<void> {
  const DebugRoute({List<_i49.PageRouteInfo>? children})
      : super(
          DebugRoute.name,
          initialChildren: children,
        );

  static const String name = 'DebugRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i9.DesktopLoginPage]
class DesktopLoginRoute extends _i49.PageRouteInfo<DesktopLoginRouteArgs> {
  DesktopLoginRoute({
    _i50.Key? key,
    String? title,
    dynamic Function(bool)? onLogin,
    bool popOnLogin = false,
    List<_i49.PageRouteInfo>? children,
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

  static const _i49.PageInfo<DesktopLoginRouteArgs> page =
      _i49.PageInfo<DesktopLoginRouteArgs>(name);
}

class DesktopLoginRouteArgs {
  const DesktopLoginRouteArgs({
    this.key,
    this.title,
    this.onLogin,
    this.popOnLogin = false,
  });

  final _i50.Key? key;

  final String? title;

  final dynamic Function(bool)? onLogin;

  final bool popOnLogin;

  @override
  String toString() {
    return 'DesktopLoginRouteArgs{key: $key, title: $title, onLogin: $onLogin, popOnLogin: $popOnLogin}';
  }
}

/// generated route for
/// [_i10.DesktopWelcomePage]
class DesktopWelcomeRoute extends _i49.PageRouteInfo<void> {
  const DesktopWelcomeRoute({List<_i49.PageRouteInfo>? children})
      : super(
          DesktopWelcomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'DesktopWelcomeRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i11.FeedListPage]
class FeedListRoute extends _i49.PageRouteInfo<void> {
  const FeedListRoute({List<_i49.PageRouteInfo>? children})
      : super(
          FeedListRoute.name,
          initialChildren: children,
        );

  static const String name = 'FeedListRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i12.FeedPage]
class FeedRoute extends _i49.PageRouteInfo<void> {
  const FeedRoute({List<_i49.PageRouteInfo>? children})
      : super(
          FeedRoute.name,
          initialChildren: children,
        );

  static const String name = 'FeedRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i13.FollowRecommendationsPage]
class FollowRecommendationsRoute extends _i49.PageRouteInfo<void> {
  const FollowRecommendationsRoute({List<_i49.PageRouteInfo>? children})
      : super(
          FollowRecommendationsRoute.name,
          initialChildren: children,
        );

  static const String name = 'FollowRecommendationsRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i14.GroupPage]
class GroupRoute extends _i49.PageRouteInfo<GroupRouteArgs> {
  GroupRoute({
    _i50.Key? key,
    required String roomId,
    List<_i49.PageRouteInfo>? children,
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

  static const _i49.PageInfo<GroupRouteArgs> page =
      _i49.PageInfo<GroupRouteArgs>(name);
}

class GroupRouteArgs {
  const GroupRouteArgs({
    this.key,
    required this.roomId,
  });

  final _i50.Key? key;

  final String roomId;

  @override
  String toString() {
    return 'GroupRouteArgs{key: $key, roomId: $roomId}';
  }
}

/// generated route for
/// [_i15.MatrixLoadingPage]
class MatrixLoadingRoute extends _i49.PageRouteInfo<void> {
  const MatrixLoadingRoute({List<_i49.PageRouteInfo>? children})
      : super(
          MatrixLoadingRoute.name,
          initialChildren: children,
        );

  static const String name = 'MatrixLoadingRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i16.MobileCreateAccountPage]
class MobileCreateAccountRoute extends _i49.PageRouteInfo<void> {
  const MobileCreateAccountRoute({List<_i49.PageRouteInfo>? children})
      : super(
          MobileCreateAccountRoute.name,
          initialChildren: children,
        );

  static const String name = 'MobileCreateAccountRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i17.MobileExplorePage]
class MobileExploreRoute extends _i49.PageRouteInfo<void> {
  const MobileExploreRoute({List<_i49.PageRouteInfo>? children})
      : super(
          MobileExploreRoute.name,
          initialChildren: children,
        );

  static const String name = 'MobileExploreRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i18.MobileLoginPage]
class MobileLoginRoute extends _i49.PageRouteInfo<MobileLoginRouteArgs> {
  MobileLoginRoute({
    _i50.Key? key,
    bool popOnLogin = false,
    List<_i49.PageRouteInfo>? children,
  }) : super(
          MobileLoginRoute.name,
          args: MobileLoginRouteArgs(
            key: key,
            popOnLogin: popOnLogin,
          ),
          initialChildren: children,
        );

  static const String name = 'MobileLoginRoute';

  static const _i49.PageInfo<MobileLoginRouteArgs> page =
      _i49.PageInfo<MobileLoginRouteArgs>(name);
}

class MobileLoginRouteArgs {
  const MobileLoginRouteArgs({
    this.key,
    this.popOnLogin = false,
  });

  final _i50.Key? key;

  final bool popOnLogin;

  @override
  String toString() {
    return 'MobileLoginRouteArgs{key: $key, popOnLogin: $popOnLogin}';
  }
}

/// generated route for
/// [_i19.MobileWelcomePage]
class MobileWelcomeRoute extends _i49.PageRouteInfo<void> {
  const MobileWelcomeRoute({List<_i49.PageRouteInfo>? children})
      : super(
          MobileWelcomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'MobileWelcomeRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i20.MobileWelcomeRouterPage]
class MobileWelcomeRouter extends _i49.PageRouteInfo<void> {
  const MobileWelcomeRouter({List<_i49.PageRouteInfo>? children})
      : super(
          MobileWelcomeRouter.name,
          initialChildren: children,
        );

  static const String name = 'MobileWelcomeRouter';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i21.OverrideRoomListPage]
class OverrideRoomListRoute
    extends _i49.PageRouteInfo<OverrideRoomListRouteArgs> {
  OverrideRoomListRoute({
    _i50.Key? key,
    bool isMobile = false,
    List<_i49.PageRouteInfo>? children,
  }) : super(
          OverrideRoomListRoute.name,
          args: OverrideRoomListRouteArgs(
            key: key,
            isMobile: isMobile,
          ),
          initialChildren: children,
        );

  static const String name = 'OverrideRoomListRoute';

  static const _i49.PageInfo<OverrideRoomListRouteArgs> page =
      _i49.PageInfo<OverrideRoomListRouteArgs>(name);
}

class OverrideRoomListRouteArgs {
  const OverrideRoomListRouteArgs({
    this.key,
    this.isMobile = false,
  });

  final _i50.Key? key;

  final bool isMobile;

  @override
  String toString() {
    return 'OverrideRoomListRouteArgs{key: $key, isMobile: $isMobile}';
  }
}

/// generated route for
/// [_i22.OverrideRoomListRoomPage]
class OverrideRoomListRoomRoute
    extends _i49.PageRouteInfo<OverrideRoomListRoomRouteArgs> {
  OverrideRoomListRoomRoute({
    _i50.Key? key,
    bool displaySettingsOnDesktop = false,
    List<_i49.PageRouteInfo>? children,
  }) : super(
          OverrideRoomListRoomRoute.name,
          args: OverrideRoomListRoomRouteArgs(
            key: key,
            displaySettingsOnDesktop: displaySettingsOnDesktop,
          ),
          initialChildren: children,
        );

  static const String name = 'OverrideRoomListRoomRoute';

  static const _i49.PageInfo<OverrideRoomListRoomRouteArgs> page =
      _i49.PageInfo<OverrideRoomListRoomRouteArgs>(name);
}

class OverrideRoomListRoomRouteArgs {
  const OverrideRoomListRoomRouteArgs({
    this.key,
    this.displaySettingsOnDesktop = false,
  });

  final _i50.Key? key;

  final bool displaySettingsOnDesktop;

  @override
  String toString() {
    return 'OverrideRoomListRoomRouteArgs{key: $key, displaySettingsOnDesktop: $displaySettingsOnDesktop}';
  }
}

/// generated route for
/// [_i23.OverrideRoomListSpacePage]
class OverrideRoomListSpaceRoute extends _i49.PageRouteInfo<void> {
  const OverrideRoomListSpaceRoute({List<_i49.PageRouteInfo>? children})
      : super(
          OverrideRoomListSpaceRoute.name,
          initialChildren: children,
        );

  static const String name = 'OverrideRoomListSpaceRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i24.OverrideRoomPage]
class OverrideRoomRoute extends _i49.PageRouteInfo<OverrideRoomRouteArgs> {
  OverrideRoomRoute({
    _i50.Key? key,
    required String roomId,
    required _i51.Client client,
    void Function()? onBack,
    bool allowPop = false,
    bool displaySettingsOnDesktop = false,
    List<_i49.PageRouteInfo>? children,
  }) : super(
          OverrideRoomRoute.name,
          args: OverrideRoomRouteArgs(
            key: key,
            roomId: roomId,
            client: client,
            onBack: onBack,
            allowPop: allowPop,
            displaySettingsOnDesktop: displaySettingsOnDesktop,
          ),
          initialChildren: children,
        );

  static const String name = 'OverrideRoomRoute';

  static const _i49.PageInfo<OverrideRoomRouteArgs> page =
      _i49.PageInfo<OverrideRoomRouteArgs>(name);
}

class OverrideRoomRouteArgs {
  const OverrideRoomRouteArgs({
    this.key,
    required this.roomId,
    required this.client,
    this.onBack,
    this.allowPop = false,
    this.displaySettingsOnDesktop = false,
  });

  final _i50.Key? key;

  final String roomId;

  final _i51.Client client;

  final void Function()? onBack;

  final bool allowPop;

  final bool displaySettingsOnDesktop;

  @override
  String toString() {
    return 'OverrideRoomRouteArgs{key: $key, roomId: $roomId, client: $client, onBack: $onBack, allowPop: $allowPop, displaySettingsOnDesktop: $displaySettingsOnDesktop}';
  }
}

/// generated route for
/// [_i25.OverrideRoomSpacePage]
class OverrideRoomSpaceRoute
    extends _i49.PageRouteInfo<OverrideRoomSpaceRouteArgs> {
  OverrideRoomSpaceRoute({
    _i50.Key? key,
    required String spaceId,
    required _i51.Client client,
    void Function()? onBack,
    List<_i49.PageRouteInfo>? children,
  }) : super(
          OverrideRoomSpaceRoute.name,
          args: OverrideRoomSpaceRouteArgs(
            key: key,
            spaceId: spaceId,
            client: client,
            onBack: onBack,
          ),
          initialChildren: children,
        );

  static const String name = 'OverrideRoomSpaceRoute';

  static const _i49.PageInfo<OverrideRoomSpaceRouteArgs> page =
      _i49.PageInfo<OverrideRoomSpaceRouteArgs>(name);
}

class OverrideRoomSpaceRouteArgs {
  const OverrideRoomSpaceRouteArgs({
    this.key,
    required this.spaceId,
    required this.client,
    this.onBack,
  });

  final _i50.Key? key;

  final String spaceId;

  final _i51.Client client;

  final void Function()? onBack;

  @override
  String toString() {
    return 'OverrideRoomSpaceRouteArgs{key: $key, spaceId: $spaceId, client: $client, onBack: $onBack}';
  }
}

/// generated route for
/// [_i26.PostGalleryPage]
class PostGalleryRoute extends _i49.PageRouteInfo<PostGalleryRouteArgs> {
  PostGalleryRoute({
    _i50.Key? key,
    required _i51.Event post,
    _i51.Event? image,
    String? selectedImageEventId,
    List<_i49.PageRouteInfo>? children,
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

  static const _i49.PageInfo<PostGalleryRouteArgs> page =
      _i49.PageInfo<PostGalleryRouteArgs>(name);
}

class PostGalleryRouteArgs {
  const PostGalleryRouteArgs({
    this.key,
    required this.post,
    this.image,
    this.selectedImageEventId,
  });

  final _i50.Key? key;

  final _i51.Event post;

  final _i51.Event? image;

  final String? selectedImageEventId;

  @override
  String toString() {
    return 'PostGalleryRouteArgs{key: $key, post: $post, image: $image, selectedImageEventId: $selectedImageEventId}';
  }
}

/// generated route for
/// [_i27.PostPage]
class PostRoute extends _i49.PageRouteInfo<PostRouteArgs> {
  PostRoute({
    _i50.Key? key,
    required _i51.Event event,
    required _i51.Timeline timeline,
    List<_i49.PageRouteInfo>? children,
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

  static const _i49.PageInfo<PostRouteArgs> page =
      _i49.PageInfo<PostRouteArgs>(name);
}

class PostRouteArgs {
  const PostRouteArgs({
    this.key,
    required this.event,
    required this.timeline,
  });

  final _i50.Key? key;

  final _i51.Event event;

  final _i51.Timeline timeline;

  @override
  String toString() {
    return 'PostRouteArgs{key: $key, event: $event, timeline: $timeline}';
  }
}

/// generated route for
/// [_i28.RoomListPage]
class RoomListRoute extends _i49.PageRouteInfo<RoomListRouteArgs> {
  RoomListRoute({
    _i50.Key? key,
    bool isMobile = false,
    List<_i49.PageRouteInfo>? children,
  }) : super(
          RoomListRoute.name,
          args: RoomListRouteArgs(
            key: key,
            isMobile: isMobile,
          ),
          initialChildren: children,
        );

  static const String name = 'RoomListRoute';

  static const _i49.PageInfo<RoomListRouteArgs> page =
      _i49.PageInfo<RoomListRouteArgs>(name);
}

class RoomListRouteArgs {
  const RoomListRouteArgs({
    this.key,
    this.isMobile = false,
  });

  final _i50.Key? key;

  final bool isMobile;

  @override
  String toString() {
    return 'RoomListRouteArgs{key: $key, isMobile: $isMobile}';
  }
}

/// generated route for
/// [_i29.SearchPage]
class SearchRoute extends _i49.PageRouteInfo<SearchRouteArgs> {
  SearchRoute({
    _i50.Key? key,
    bool isPopup = false,
    _i52.SearchMode? initialSearchMode,
    List<_i49.PageRouteInfo>? children,
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

  static const _i49.PageInfo<SearchRouteArgs> page =
      _i49.PageInfo<SearchRouteArgs>(name);
}

class SearchRouteArgs {
  const SearchRouteArgs({
    this.key,
    this.isPopup = false,
    this.initialSearchMode,
  });

  final _i50.Key? key;

  final bool isPopup;

  final _i52.SearchMode? initialSearchMode;

  @override
  String toString() {
    return 'SearchRouteArgs{key: $key, isPopup: $isPopup, initialSearchMode: $initialSearchMode}';
  }
}

/// generated route for
/// [_i30.SettingsAccountPage]
class SettingsAccountRoute extends _i49.PageRouteInfo<void> {
  const SettingsAccountRoute({List<_i49.PageRouteInfo>? children})
      : super(
          SettingsAccountRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsAccountRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i31.SettingsAccountSwitchPage]
class SettingsAccountSwitchRoute
    extends _i49.PageRouteInfo<SettingsAccountSwitchRouteArgs> {
  SettingsAccountSwitchRoute({
    _i50.Key? key,
    bool popOnUserSelected = false,
    List<_i49.PageRouteInfo>? children,
  }) : super(
          SettingsAccountSwitchRoute.name,
          args: SettingsAccountSwitchRouteArgs(
            key: key,
            popOnUserSelected: popOnUserSelected,
          ),
          initialChildren: children,
        );

  static const String name = 'SettingsAccountSwitchRoute';

  static const _i49.PageInfo<SettingsAccountSwitchRouteArgs> page =
      _i49.PageInfo<SettingsAccountSwitchRouteArgs>(name);
}

class SettingsAccountSwitchRouteArgs {
  const SettingsAccountSwitchRouteArgs({
    this.key,
    this.popOnUserSelected = false,
  });

  final _i50.Key? key;

  final bool popOnUserSelected;

  @override
  String toString() {
    return 'SettingsAccountSwitchRouteArgs{key: $key, popOnUserSelected: $popOnUserSelected}';
  }
}

/// generated route for
/// [_i32.SettingsFeedsPage]
class SettingsFeedsRoute extends _i49.PageRouteInfo<void> {
  const SettingsFeedsRoute({List<_i49.PageRouteInfo>? children})
      : super(
          SettingsFeedsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsFeedsRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i33.SettingsLabsPage]
class SettingsLabsRoute extends _i49.PageRouteInfo<void> {
  const SettingsLabsRoute({List<_i49.PageRouteInfo>? children})
      : super(
          SettingsLabsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsLabsRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i34.SettingsPage]
class SettingsRoute extends _i49.PageRouteInfo<void> {
  const SettingsRoute({List<_i49.PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i34.SettingsPanelInnerPage]
class SettingsPanelInnerRoute extends _i49.PageRouteInfo<void> {
  const SettingsPanelInnerRoute({List<_i49.PageRouteInfo>? children})
      : super(
          SettingsPanelInnerRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsPanelInnerRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i35.SettingsSecurityPage]
class SettingsSecurityRoute extends _i49.PageRouteInfo<void> {
  const SettingsSecurityRoute({List<_i49.PageRouteInfo>? children})
      : super(
          SettingsSecurityRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsSecurityRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i36.SettingsStorysDetailPage]
class SettingsStorysDetailRoute
    extends _i49.PageRouteInfo<SettingsStorysDetailRouteArgs> {
  SettingsStorysDetailRoute({
    _i50.Key? key,
    required _i51.Room room,
    List<_i49.PageRouteInfo>? children,
  }) : super(
          SettingsStorysDetailRoute.name,
          args: SettingsStorysDetailRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'SettingsStorysDetailRoute';

  static const _i49.PageInfo<SettingsStorysDetailRouteArgs> page =
      _i49.PageInfo<SettingsStorysDetailRouteArgs>(name);
}

class SettingsStorysDetailRouteArgs {
  const SettingsStorysDetailRouteArgs({
    this.key,
    required this.room,
  });

  final _i50.Key? key;

  final _i51.Room room;

  @override
  String toString() {
    return 'SettingsStorysDetailRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i37.SettingsStorysPage]
class SettingsStorysRoute extends _i49.PageRouteInfo<void> {
  const SettingsStorysRoute({List<_i49.PageRouteInfo>? children})
      : super(
          SettingsStorysRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsStorysRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i38.SettingsSyncPage]
class SettingsSyncRoute extends _i49.PageRouteInfo<void> {
  const SettingsSyncRoute({List<_i49.PageRouteInfo>? children})
      : super(
          SettingsSyncRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsSyncRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i39.SettingsThemePage]
class SettingsThemeRoute extends _i49.PageRouteInfo<void> {
  const SettingsThemeRoute({List<_i49.PageRouteInfo>? children})
      : super(
          SettingsThemeRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsThemeRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i40.SocialSettingsPage]
class SocialSettingsRoute extends _i49.PageRouteInfo<SocialSettingsRouteArgs> {
  SocialSettingsRoute({
    _i50.Key? key,
    required _i51.Room room,
    List<_i49.PageRouteInfo>? children,
  }) : super(
          SocialSettingsRoute.name,
          args: SocialSettingsRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'SocialSettingsRoute';

  static const _i49.PageInfo<SocialSettingsRouteArgs> page =
      _i49.PageInfo<SocialSettingsRouteArgs>(name);
}

class SocialSettingsRouteArgs {
  const SocialSettingsRouteArgs({
    this.key,
    required this.room,
  });

  final _i50.Key? key;

  final _i51.Room room;

  @override
  String toString() {
    return 'SocialSettingsRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i41.TabCalendarPage]
class TabCalendarRoute extends _i49.PageRouteInfo<void> {
  const TabCalendarRoute({List<_i49.PageRouteInfo>? children})
      : super(
          TabCalendarRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabCalendarRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i42.TabCameraPage]
class TabCameraRoute extends _i49.PageRouteInfo<void> {
  const TabCameraRoute({List<_i49.PageRouteInfo>? children})
      : super(
          TabCameraRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabCameraRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i43.TabChatPage]
class TabChatRoute extends _i49.PageRouteInfo<void> {
  const TabChatRoute({List<_i49.PageRouteInfo>? children})
      : super(
          TabChatRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabChatRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i44.TabCommunityPage]
class TabCommunityRoute extends _i49.PageRouteInfo<void> {
  const TabCommunityRoute({List<_i49.PageRouteInfo>? children})
      : super(
          TabCommunityRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabCommunityRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i45.TabHomePage]
class TabHomeRoute extends _i49.PageRouteInfo<void> {
  const TabHomeRoute({List<_i49.PageRouteInfo>? children})
      : super(
          TabHomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabHomeRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i46.TabStoriesPage]
class TabStoriesRoute extends _i49.PageRouteInfo<void> {
  const TabStoriesRoute({List<_i49.PageRouteInfo>? children})
      : super(
          TabStoriesRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabStoriesRoute';

  static const _i49.PageInfo<void> page = _i49.PageInfo<void>(name);
}

/// generated route for
/// [_i47.UserFollowersPage]
class UserFollowersRoute extends _i49.PageRouteInfo<UserFollowersRouteArgs> {
  UserFollowersRoute({
    _i50.Key? key,
    required _i51.Room room,
    List<_i49.PageRouteInfo>? children,
  }) : super(
          UserFollowersRoute.name,
          args: UserFollowersRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'UserFollowersRoute';

  static const _i49.PageInfo<UserFollowersRouteArgs> page =
      _i49.PageInfo<UserFollowersRouteArgs>(name);
}

class UserFollowersRouteArgs {
  const UserFollowersRouteArgs({
    this.key,
    required this.room,
  });

  final _i50.Key? key;

  final _i51.Room room;

  @override
  String toString() {
    return 'UserFollowersRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i48.UserViewPage]
class UserViewRoute extends _i49.PageRouteInfo<UserViewRouteArgs> {
  UserViewRoute({
    _i50.Key? key,
    String? userID,
    _i51.Room? mroom,
    List<_i49.PageRouteInfo>? children,
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

  static const _i49.PageInfo<UserViewRouteArgs> page =
      _i49.PageInfo<UserViewRouteArgs>(name);
}

class UserViewRouteArgs {
  const UserViewRouteArgs({
    this.key,
    this.userID,
    this.mroom,
  });

  final _i50.Key? key;

  final String? userID;

  final _i51.Room? mroom;

  @override
  String toString() {
    return 'UserViewRouteArgs{key: $key, userID: $userID, mroom: $mroom}';
  }
}
