// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i61;
import 'package:flutter/material.dart' as _i62;
import 'package:matrix/matrix.dart' as _i63;
import 'package:piaf/models/search/search_mode.dart' as _i64;
import 'package:piaf/pages/app_wrapper_page.dart' as _i2;
import 'package:piaf/pages/calendar_events/calendar_event_page.dart' as _i4;
import 'package:piaf/pages/calendar_events/calendar_events_list_page.dart'
    as _i3;
import 'package:piaf/pages/chat/add_user_page.dart' as _i1;
import 'package:piaf/pages/chat/overrides/override_room_list_room_page.dart'
    as _i32;
import 'package:piaf/pages/chat/overrides/override_room_list_space_page.dart'
    as _i33;
import 'package:piaf/pages/chat/overrides/override_room_space_page.dart'
    as _i34;
import 'package:piaf/pages/chat/room_list_or_placeholder.dart' as _i37;
import 'package:piaf/pages/chat/room_page.dart' as _i38;
import 'package:piaf/pages/chat_lib/chat_page_items/chat_page_room.dart' as _i6;
import 'package:piaf/pages/chat_lib/chat_page_items/chat_page_space_page.dart'
    as _i8;
import 'package:piaf/pages/chat_lib/chat_page_items/chat_page_spaces_list.dart'
    as _i7;
import 'package:piaf/pages/chat_lib/chat_page_items/provider/chat_page_provider.dart'
    as _i5;
import 'package:piaf/pages/chat_lib/device_media_gallery.dart' as _i16;
import 'package:piaf/pages/chat_lib/matrix_create_group.dart' as _i23;
import 'package:piaf/pages/chat_lib/matrix_storie_create.dart' as _i24;
import 'package:piaf/pages/chat_lib/matrix_stories_page.dart' as _i26;
import 'package:piaf/pages/chat_lib/room_create/create_chat_page.dart' as _i11;
import 'package:piaf/pages/chat_lib/room_create/create_group_page.dart' as _i12;
import 'package:piaf/pages/chat_lib/room_settings_page.dart' as _i39;
import 'package:piaf/pages/chat_lib/space_page.dart' as _i52;
import 'package:piaf/pages/communities/community_detail_page.dart' as _i9;
import 'package:piaf/pages/communities/community_page.dart' as _i10;
import 'package:piaf/pages/debug_page.dart' as _i13;
import 'package:piaf/pages/feed/feed_creation_page.dart' as _i17;
import 'package:piaf/pages/feed/feed_list_page.dart' as _i18;
import 'package:piaf/pages/feed/feed_page.dart' as _i19;
import 'package:piaf/pages/follow_recommendations.dart' as _i20;
import 'package:piaf/pages/groups/group_page.dart' as _i21;
import 'package:piaf/pages/home/home_page.dart' as _i22;
import 'package:piaf/pages/image/post_gallery_page.dart' as _i35;
import 'package:piaf/pages/matrix_loading_page.dart' as _i25;
import 'package:piaf/pages/post_page.dart' as _i36;
import 'package:piaf/pages/search/search_page.dart' as _i40;
import 'package:piaf/pages/settings/settings_account_page.dart' as _i41;
import 'package:piaf/pages/settings/settings_account_switch_page.dart' as _i42;
import 'package:piaf/pages/settings/settings_feeds_page.dart' as _i43;
import 'package:piaf/pages/settings/settings_labs_page.dart' as _i44;
import 'package:piaf/pages/settings/settings_page.dart' as _i45;
import 'package:piaf/pages/settings/settings_security_page.dart' as _i46;
import 'package:piaf/pages/settings/settings_story_detail_page.dart' as _i47;
import 'package:piaf/pages/settings/settings_storys_page.dart' as _i48;
import 'package:piaf/pages/settings/settings_sync_page.dart' as _i49;
import 'package:piaf/pages/settings/settings_theme_page.dart' as _i50;
import 'package:piaf/pages/social_settings_page.dart' as _i51;
import 'package:piaf/pages/tabs/tab_calendar_page.dart' as _i53;
import 'package:piaf/pages/tabs/tab_camera_page.dart' as _i54;
import 'package:piaf/pages/tabs/tab_chat_page.dart' as _i55;
import 'package:piaf/pages/tabs/tab_community_page.dart' as _i56;
import 'package:piaf/pages/tabs/tab_home_page.dart' as _i57;
import 'package:piaf/pages/tabs/tab_stories_page.dart' as _i58;
import 'package:piaf/pages/user/user_followers_page.dart' as _i59;
import 'package:piaf/pages/user/user_view_page.dart' as _i60;
import 'package:piaf/pages/welcome/desktop/desktop_welcome_route.dart' as _i15;
import 'package:piaf/pages/welcome/desktop_login_page.dart' as _i14;
import 'package:piaf/pages/welcome/mobile/mobile_create_account_page.dart'
    as _i27;
import 'package:piaf/pages/welcome/mobile/mobile_explore_page.dart' as _i28;
import 'package:piaf/pages/welcome/mobile/mobile_login_page.dart' as _i29;
import 'package:piaf/pages/welcome/mobile/mobile_welcome_page.dart' as _i30;
import 'package:piaf/pages/welcome/mobile/mobile_welcome_router_page.dart'
    as _i31;

abstract class $AppRouter extends _i61.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i61.PageFactory> pagesMap = {
    AddUserRoute.name: (routeData) {
      final args = routeData.argsAs<AddUserRouteArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.AddUserPage(
          args.context,
          key: args.key,
        ),
      );
    },
    AppWrapperRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.AppWrapperPage(),
      );
    },
    CalendarEventListRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i3.CalendarEventListPage(),
      );
    },
    CalendarEventRoute.name: (routeData) {
      final args = routeData.argsAs<CalendarEventRouteArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i4.CalendarEventPage(
          key: args.key,
          room: args.room,
        ),
      );
    },
    ChatRouteProvider.name: (routeData) {
      final args = routeData.argsAs<ChatRouteProviderArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i5.ChatPageProvider(
          key: args.key,
          child: args.child,
          client: args.client,
          onRoomSelection: args.onRoomSelection,
          onLongPressedSpace: args.onLongPressedSpace,
          onSpaceSelection: args.onSpaceSelection,
          selectedSpace: args.selectedSpace,
        ),
      );
    },
    ChatRouteRoom.name: (routeData) {
      final args = routeData.argsAs<ChatRouteRoomArgs>(
          orElse: () => const ChatRouteRoomArgs());
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i6.ChatPageRoom(
          key: args.key,
          displaySettingsOnDesktop: args.displaySettingsOnDesktop,
        ),
      );
    },
    ChatRouteSpaceList.name: (routeData) {
      final args = routeData.argsAs<ChatRouteSpaceListArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i7.ChatPageSpaceList(
          key: args.key,
          popAfterSelection: args.popAfterSelection,
          scrollController: args.scrollController,
          onSelection: args.onSelection,
        ),
      );
    },
    ChatRouteSpaceRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i8.ChatPageSpacePage(),
      );
    },
    CommunityDetailRoute.name: (routeData) {
      final args = routeData.argsAs<CommunityDetailRouteArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i9.CommunityDetailPage(
          key: args.key,
          room: args.room,
        ),
      );
    },
    CommunityRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i10.CommunityPage(),
      );
    },
    CreateChatRoute.name: (routeData) {
      final args = routeData.argsAs<CreateChatRouteArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i11.CreateChatPage(
          key: args.key,
          onRoomSelected: args.onRoomSelected,
          client: args.client,
        ),
      );
    },
    CreateGroupRoute.name: (routeData) {
      final args = routeData.argsAs<CreateGroupRouteArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i12.CreateGroupPage(
          key: args.key,
          onRoomSelected: args.onRoomSelected,
          client: args.client,
        ),
      );
    },
    DebugRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i13.DebugPage(),
      );
    },
    DesktopLoginRoute.name: (routeData) {
      final args = routeData.argsAs<DesktopLoginRouteArgs>(
          orElse: () => const DesktopLoginRouteArgs());
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i14.DesktopLoginPage(
          key: args.key,
          title: args.title,
          onLogin: args.onLogin,
          popOnLogin: args.popOnLogin,
        ),
      );
    },
    DesktopWelcomeRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i15.DesktopWelcomePage(),
      );
    },
    DeviceMediaGallery.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i16.DeviceMediaGallery(),
      );
    },
    FeedCreationRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i17.FeedCreationPage(),
      );
    },
    FeedListRoute.name: (routeData) {
      final args = routeData.argsAs<FeedListRouteArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i18.FeedListPage(
          key: args.key,
          initialSelection: args.initialSelection,
        ),
      );
    },
    FeedRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i19.FeedPage(),
      );
    },
    FollowRecommendationsRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i20.FollowRecommendationsPage(),
      );
    },
    GroupRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<GroupRouteArgs>(
          orElse: () => GroupRouteArgs(roomId: pathParams.getString('roomId')));
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i21.GroupPage(
          key: args.key,
          roomId: args.roomId,
        ),
      );
    },
    HomeRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i22.HomePage(),
      );
    },
    MatrixCreateGroup.name: (routeData) {
      final args = routeData.argsAs<MatrixCreateGroupArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i23.MatrixCreateGroup(
          key: args.key,
          client: args.client,
          onGroupCreated: args.onGroupCreated,
        ),
      );
    },
    MatrixCreateStorieRoute.name: (routeData) {
      final args = routeData.argsAs<MatrixCreateStorieRouteArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i24.MatrixCreateStoriePage(
          key: args.key,
          client: args.client,
          r: args.r,
        ),
      );
    },
    MatrixLoadingRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i25.MatrixLoadingPage(),
      );
    },
    MatrixStoriesRoute.name: (routeData) {
      final args = routeData.argsAs<MatrixStoriesRouteArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i26.MatrixStoriesPage(
          args.room,
          key: args.key,
        ),
      );
    },
    MobileCreateAccountRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i27.MobileCreateAccountPage(),
      );
    },
    MobileExploreRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i28.MobileExplorePage(),
      );
    },
    MobileLoginRoute.name: (routeData) {
      final args = routeData.argsAs<MobileLoginRouteArgs>(
          orElse: () => const MobileLoginRouteArgs());
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i29.MobileLoginPage(
          key: args.key,
          popOnLogin: args.popOnLogin,
        ),
      );
    },
    MobileWelcomeRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i30.MobileWelcomePage(),
      );
    },
    MobileWelcomeRouter.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i31.MobileWelcomeRouterPage(),
      );
    },
    OverrideRoomListRoomRoute.name: (routeData) {
      final args = routeData.argsAs<OverrideRoomListRoomRouteArgs>(
          orElse: () => const OverrideRoomListRoomRouteArgs());
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i32.OverrideRoomListRoomPage(
          key: args.key,
          displaySettingsOnDesktop: args.displaySettingsOnDesktop,
        ),
      );
    },
    OverrideRoomListSpaceRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i33.OverrideRoomListSpacePage(),
      );
    },
    OverrideRoomSpaceRoute.name: (routeData) {
      final args = routeData.argsAs<OverrideRoomSpaceRouteArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i34.OverrideRoomSpacePage(
          key: args.key,
          spaceId: args.spaceId,
          client: args.client,
          onBack: args.onBack,
        ),
      );
    },
    PostGalleryRoute.name: (routeData) {
      final args = routeData.argsAs<PostGalleryRouteArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i35.PostGalleryPage(
          key: args.key,
          post: args.post,
          image: args.image,
          selectedImageEventId: args.selectedImageEventId,
        ),
      );
    },
    PostRoute.name: (routeData) {
      final args = routeData.argsAs<PostRouteArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i36.PostPage(
          key: args.key,
          event: args.event,
          timeline: args.timeline,
        ),
      );
    },
    RoomListOrPlaceHolderRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i37.RoomListOrPlaceHolderPage(),
      );
    },
    RoomRoute.name: (routeData) {
      final args = routeData.argsAs<RoomRouteArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i38.RoomPage(
          key: args.key,
          roomId: args.roomId,
          client: args.client,
          onBack: args.onBack,
          allowPop: args.allowPop,
          displaySettingsOnDesktop: args.displaySettingsOnDesktop,
        ),
      );
    },
    RoomSettingsRoute.name: (routeData) {
      final args = routeData.argsAs<RoomSettingsRouteArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i39.RoomSettingsPage(
          key: args.key,
          room: args.room,
          onLeave: args.onLeave,
        ),
      );
    },
    SearchRoute.name: (routeData) {
      final args = routeData.argsAs<SearchRouteArgs>(
          orElse: () => const SearchRouteArgs());
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i40.SearchPage(
          key: args.key,
          isPopup: args.isPopup,
          initialSearchMode: args.initialSearchMode,
        ),
      );
    },
    SettingsAccountRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i41.SettingsAccountPage(),
      );
    },
    SettingsAccountSwitchRoute.name: (routeData) {
      final args = routeData.argsAs<SettingsAccountSwitchRouteArgs>(
          orElse: () => const SettingsAccountSwitchRouteArgs());
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i42.SettingsAccountSwitchPage(
          key: args.key,
          popOnUserSelected: args.popOnUserSelected,
        ),
      );
    },
    SettingsFeedsRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i43.SettingsFeedsPage(),
      );
    },
    SettingsLabsRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i44.SettingsLabsPage(),
      );
    },
    SettingsRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i45.SettingsPage(),
      );
    },
    SettingsPanelInnerRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i45.SettingsPanelInnerPage(),
      );
    },
    SettingsSecurityRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i46.SettingsSecurityPage(),
      );
    },
    SettingsStorysDetailRoute.name: (routeData) {
      final args = routeData.argsAs<SettingsStorysDetailRouteArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i47.SettingsStorysDetailPage(
          key: args.key,
          room: args.room,
        ),
      );
    },
    SettingsStorysRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i48.SettingsStorysPage(),
      );
    },
    SettingsSyncRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i49.SettingsSyncPage(),
      );
    },
    SettingsThemeRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i50.SettingsThemePage(),
      );
    },
    SocialSettingsRoute.name: (routeData) {
      final args = routeData.argsAs<SocialSettingsRouteArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i51.SocialSettingsPage(
          key: args.key,
          room: args.room,
        ),
      );
    },
    SpaceRoute.name: (routeData) {
      final args = routeData.argsAs<SpaceRouteArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i52.SpacePage(
          key: args.key,
          spaceId: args.spaceId,
          client: args.client,
          onBack: args.onBack,
        ),
      );
    },
    TabCalendarRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i53.TabCalendarPage(),
      );
    },
    TabCameraRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i54.TabCameraPage(),
      );
    },
    TabChatRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i55.TabChatPage(),
      );
    },
    TabCommunityRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i56.TabCommunityPage(),
      );
    },
    TabHomeRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i57.TabHomePage(),
      );
    },
    TabStoriesRoute.name: (routeData) {
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i58.TabStoriesPage(),
      );
    },
    UserFollowersRoute.name: (routeData) {
      final args = routeData.argsAs<UserFollowersRouteArgs>();
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i59.UserFollowersPage(
          key: args.key,
          room: args.room,
        ),
      );
    },
    UserViewRoute.name: (routeData) {
      final args = routeData.argsAs<UserViewRouteArgs>(
          orElse: () => const UserViewRouteArgs());
      return _i61.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i60.UserViewPage(
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
class AddUserRoute extends _i61.PageRouteInfo<AddUserRouteArgs> {
  AddUserRoute({
    required _i62.BuildContext context,
    _i62.Key? key,
    List<_i61.PageRouteInfo>? children,
  }) : super(
          AddUserRoute.name,
          args: AddUserRouteArgs(
            context: context,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'AddUserRoute';

  static const _i61.PageInfo<AddUserRouteArgs> page =
      _i61.PageInfo<AddUserRouteArgs>(name);
}

class AddUserRouteArgs {
  const AddUserRouteArgs({
    required this.context,
    this.key,
  });

  final _i62.BuildContext context;

  final _i62.Key? key;

  @override
  String toString() {
    return 'AddUserRouteArgs{context: $context, key: $key}';
  }
}

/// generated route for
/// [_i2.AppWrapperPage]
class AppWrapperRoute extends _i61.PageRouteInfo<void> {
  const AppWrapperRoute({List<_i61.PageRouteInfo>? children})
      : super(
          AppWrapperRoute.name,
          initialChildren: children,
        );

  static const String name = 'AppWrapperRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i3.CalendarEventListPage]
class CalendarEventListRoute extends _i61.PageRouteInfo<void> {
  const CalendarEventListRoute({List<_i61.PageRouteInfo>? children})
      : super(
          CalendarEventListRoute.name,
          initialChildren: children,
        );

  static const String name = 'CalendarEventListRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i4.CalendarEventPage]
class CalendarEventRoute extends _i61.PageRouteInfo<CalendarEventRouteArgs> {
  CalendarEventRoute({
    _i62.Key? key,
    required _i63.Room room,
    List<_i61.PageRouteInfo>? children,
  }) : super(
          CalendarEventRoute.name,
          args: CalendarEventRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'CalendarEventRoute';

  static const _i61.PageInfo<CalendarEventRouteArgs> page =
      _i61.PageInfo<CalendarEventRouteArgs>(name);
}

class CalendarEventRouteArgs {
  const CalendarEventRouteArgs({
    this.key,
    required this.room,
  });

  final _i62.Key? key;

  final _i63.Room room;

  @override
  String toString() {
    return 'CalendarEventRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i5.ChatPageProvider]
class ChatRouteProvider extends _i61.PageRouteInfo<ChatRouteProviderArgs> {
  ChatRouteProvider({
    _i62.Key? key,
    required _i62.Widget child,
    required _i63.Client client,
    required void Function(String?)? onRoomSelection,
    required void Function(String?) onLongPressedSpace,
    required void Function(String)? onSpaceSelection,
    String selectedSpace = "Explore",
    List<_i61.PageRouteInfo>? children,
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

  static const _i61.PageInfo<ChatRouteProviderArgs> page =
      _i61.PageInfo<ChatRouteProviderArgs>(name);
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

  final _i62.Key? key;

  final _i62.Widget child;

  final _i63.Client client;

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
/// [_i6.ChatPageRoom]
class ChatRouteRoom extends _i61.PageRouteInfo<ChatRouteRoomArgs> {
  ChatRouteRoom({
    _i62.Key? key,
    bool displaySettingsOnDesktop = false,
    List<_i61.PageRouteInfo>? children,
  }) : super(
          ChatRouteRoom.name,
          args: ChatRouteRoomArgs(
            key: key,
            displaySettingsOnDesktop: displaySettingsOnDesktop,
          ),
          initialChildren: children,
        );

  static const String name = 'ChatRouteRoom';

  static const _i61.PageInfo<ChatRouteRoomArgs> page =
      _i61.PageInfo<ChatRouteRoomArgs>(name);
}

class ChatRouteRoomArgs {
  const ChatRouteRoomArgs({
    this.key,
    this.displaySettingsOnDesktop = false,
  });

  final _i62.Key? key;

  final bool displaySettingsOnDesktop;

  @override
  String toString() {
    return 'ChatRouteRoomArgs{key: $key, displaySettingsOnDesktop: $displaySettingsOnDesktop}';
  }
}

/// generated route for
/// [_i7.ChatPageSpaceList]
class ChatRouteSpaceList extends _i61.PageRouteInfo<ChatRouteSpaceListArgs> {
  ChatRouteSpaceList({
    _i62.Key? key,
    required bool popAfterSelection,
    required _i62.ScrollController scrollController,
    void Function()? onSelection,
    List<_i61.PageRouteInfo>? children,
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

  static const _i61.PageInfo<ChatRouteSpaceListArgs> page =
      _i61.PageInfo<ChatRouteSpaceListArgs>(name);
}

class ChatRouteSpaceListArgs {
  const ChatRouteSpaceListArgs({
    this.key,
    required this.popAfterSelection,
    required this.scrollController,
    this.onSelection,
  });

  final _i62.Key? key;

  final bool popAfterSelection;

  final _i62.ScrollController scrollController;

  final void Function()? onSelection;

  @override
  String toString() {
    return 'ChatRouteSpaceListArgs{key: $key, popAfterSelection: $popAfterSelection, scrollController: $scrollController, onSelection: $onSelection}';
  }
}

/// generated route for
/// [_i8.ChatPageSpacePage]
class ChatRouteSpaceRoute extends _i61.PageRouteInfo<void> {
  const ChatRouteSpaceRoute({List<_i61.PageRouteInfo>? children})
      : super(
          ChatRouteSpaceRoute.name,
          initialChildren: children,
        );

  static const String name = 'ChatRouteSpaceRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i9.CommunityDetailPage]
class CommunityDetailRoute
    extends _i61.PageRouteInfo<CommunityDetailRouteArgs> {
  CommunityDetailRoute({
    _i62.Key? key,
    required _i63.Room room,
    List<_i61.PageRouteInfo>? children,
  }) : super(
          CommunityDetailRoute.name,
          args: CommunityDetailRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'CommunityDetailRoute';

  static const _i61.PageInfo<CommunityDetailRouteArgs> page =
      _i61.PageInfo<CommunityDetailRouteArgs>(name);
}

class CommunityDetailRouteArgs {
  const CommunityDetailRouteArgs({
    this.key,
    required this.room,
  });

  final _i62.Key? key;

  final _i63.Room room;

  @override
  String toString() {
    return 'CommunityDetailRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i10.CommunityPage]
class CommunityRoute extends _i61.PageRouteInfo<void> {
  const CommunityRoute({List<_i61.PageRouteInfo>? children})
      : super(
          CommunityRoute.name,
          initialChildren: children,
        );

  static const String name = 'CommunityRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i11.CreateChatPage]
class CreateChatRoute extends _i61.PageRouteInfo<CreateChatRouteArgs> {
  CreateChatRoute({
    _i62.Key? key,
    required dynamic Function(String?) onRoomSelected,
    required _i63.Client client,
    List<_i61.PageRouteInfo>? children,
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

  static const _i61.PageInfo<CreateChatRouteArgs> page =
      _i61.PageInfo<CreateChatRouteArgs>(name);
}

class CreateChatRouteArgs {
  const CreateChatRouteArgs({
    this.key,
    required this.onRoomSelected,
    required this.client,
  });

  final _i62.Key? key;

  final dynamic Function(String?) onRoomSelected;

  final _i63.Client client;

  @override
  String toString() {
    return 'CreateChatRouteArgs{key: $key, onRoomSelected: $onRoomSelected, client: $client}';
  }
}

/// generated route for
/// [_i12.CreateGroupPage]
class CreateGroupRoute extends _i61.PageRouteInfo<CreateGroupRouteArgs> {
  CreateGroupRoute({
    _i62.Key? key,
    required dynamic Function(String?) onRoomSelected,
    required _i63.Client client,
    List<_i61.PageRouteInfo>? children,
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

  static const _i61.PageInfo<CreateGroupRouteArgs> page =
      _i61.PageInfo<CreateGroupRouteArgs>(name);
}

class CreateGroupRouteArgs {
  const CreateGroupRouteArgs({
    this.key,
    required this.onRoomSelected,
    required this.client,
  });

  final _i62.Key? key;

  final dynamic Function(String?) onRoomSelected;

  final _i63.Client client;

  @override
  String toString() {
    return 'CreateGroupRouteArgs{key: $key, onRoomSelected: $onRoomSelected, client: $client}';
  }
}

/// generated route for
/// [_i13.DebugPage]
class DebugRoute extends _i61.PageRouteInfo<void> {
  const DebugRoute({List<_i61.PageRouteInfo>? children})
      : super(
          DebugRoute.name,
          initialChildren: children,
        );

  static const String name = 'DebugRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i14.DesktopLoginPage]
class DesktopLoginRoute extends _i61.PageRouteInfo<DesktopLoginRouteArgs> {
  DesktopLoginRoute({
    _i62.Key? key,
    String? title,
    dynamic Function(bool)? onLogin,
    bool popOnLogin = false,
    List<_i61.PageRouteInfo>? children,
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

  static const _i61.PageInfo<DesktopLoginRouteArgs> page =
      _i61.PageInfo<DesktopLoginRouteArgs>(name);
}

class DesktopLoginRouteArgs {
  const DesktopLoginRouteArgs({
    this.key,
    this.title,
    this.onLogin,
    this.popOnLogin = false,
  });

  final _i62.Key? key;

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
class DesktopWelcomeRoute extends _i61.PageRouteInfo<void> {
  const DesktopWelcomeRoute({List<_i61.PageRouteInfo>? children})
      : super(
          DesktopWelcomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'DesktopWelcomeRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i16.DeviceMediaGallery]
class DeviceMediaGallery extends _i61.PageRouteInfo<void> {
  const DeviceMediaGallery({List<_i61.PageRouteInfo>? children})
      : super(
          DeviceMediaGallery.name,
          initialChildren: children,
        );

  static const String name = 'DeviceMediaGallery';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i17.FeedCreationPage]
class FeedCreationRoute extends _i61.PageRouteInfo<void> {
  const FeedCreationRoute({List<_i61.PageRouteInfo>? children})
      : super(
          FeedCreationRoute.name,
          initialChildren: children,
        );

  static const String name = 'FeedCreationRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i18.FeedListPage]
class FeedListRoute extends _i61.PageRouteInfo<FeedListRouteArgs> {
  FeedListRoute({
    _i62.Key? key,
    required _i18.Selection initialSelection,
    List<_i61.PageRouteInfo>? children,
  }) : super(
          FeedListRoute.name,
          args: FeedListRouteArgs(
            key: key,
            initialSelection: initialSelection,
          ),
          initialChildren: children,
        );

  static const String name = 'FeedListRoute';

  static const _i61.PageInfo<FeedListRouteArgs> page =
      _i61.PageInfo<FeedListRouteArgs>(name);
}

class FeedListRouteArgs {
  const FeedListRouteArgs({
    this.key,
    required this.initialSelection,
  });

  final _i62.Key? key;

  final _i18.Selection initialSelection;

  @override
  String toString() {
    return 'FeedListRouteArgs{key: $key, initialSelection: $initialSelection}';
  }
}

/// generated route for
/// [_i19.FeedPage]
class FeedRoute extends _i61.PageRouteInfo<void> {
  const FeedRoute({List<_i61.PageRouteInfo>? children})
      : super(
          FeedRoute.name,
          initialChildren: children,
        );

  static const String name = 'FeedRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i20.FollowRecommendationsPage]
class FollowRecommendationsRoute extends _i61.PageRouteInfo<void> {
  const FollowRecommendationsRoute({List<_i61.PageRouteInfo>? children})
      : super(
          FollowRecommendationsRoute.name,
          initialChildren: children,
        );

  static const String name = 'FollowRecommendationsRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i21.GroupPage]
class GroupRoute extends _i61.PageRouteInfo<GroupRouteArgs> {
  GroupRoute({
    _i62.Key? key,
    required String roomId,
    List<_i61.PageRouteInfo>? children,
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

  static const _i61.PageInfo<GroupRouteArgs> page =
      _i61.PageInfo<GroupRouteArgs>(name);
}

class GroupRouteArgs {
  const GroupRouteArgs({
    this.key,
    required this.roomId,
  });

  final _i62.Key? key;

  final String roomId;

  @override
  String toString() {
    return 'GroupRouteArgs{key: $key, roomId: $roomId}';
  }
}

/// generated route for
/// [_i22.HomePage]
class HomeRoute extends _i61.PageRouteInfo<void> {
  const HomeRoute({List<_i61.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i23.MatrixCreateGroup]
class MatrixCreateGroup extends _i61.PageRouteInfo<MatrixCreateGroupArgs> {
  MatrixCreateGroup({
    _i62.Key? key,
    required _i63.Client client,
    void Function(String)? onGroupCreated,
    List<_i61.PageRouteInfo>? children,
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

  static const _i61.PageInfo<MatrixCreateGroupArgs> page =
      _i61.PageInfo<MatrixCreateGroupArgs>(name);
}

class MatrixCreateGroupArgs {
  const MatrixCreateGroupArgs({
    this.key,
    required this.client,
    this.onGroupCreated,
  });

  final _i62.Key? key;

  final _i63.Client client;

  final void Function(String)? onGroupCreated;

  @override
  String toString() {
    return 'MatrixCreateGroupArgs{key: $key, client: $client, onGroupCreated: $onGroupCreated}';
  }
}

/// generated route for
/// [_i24.MatrixCreateStoriePage]
class MatrixCreateStorieRoute
    extends _i61.PageRouteInfo<MatrixCreateStorieRouteArgs> {
  MatrixCreateStorieRoute({
    _i62.Key? key,
    required _i63.Client client,
    required _i63.Room r,
    List<_i61.PageRouteInfo>? children,
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

  static const _i61.PageInfo<MatrixCreateStorieRouteArgs> page =
      _i61.PageInfo<MatrixCreateStorieRouteArgs>(name);
}

class MatrixCreateStorieRouteArgs {
  const MatrixCreateStorieRouteArgs({
    this.key,
    required this.client,
    required this.r,
  });

  final _i62.Key? key;

  final _i63.Client client;

  final _i63.Room r;

  @override
  String toString() {
    return 'MatrixCreateStorieRouteArgs{key: $key, client: $client, r: $r}';
  }
}

/// generated route for
/// [_i25.MatrixLoadingPage]
class MatrixLoadingRoute extends _i61.PageRouteInfo<void> {
  const MatrixLoadingRoute({List<_i61.PageRouteInfo>? children})
      : super(
          MatrixLoadingRoute.name,
          initialChildren: children,
        );

  static const String name = 'MatrixLoadingRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i26.MatrixStoriesPage]
class MatrixStoriesRoute extends _i61.PageRouteInfo<MatrixStoriesRouteArgs> {
  MatrixStoriesRoute({
    required _i63.Room room,
    _i62.Key? key,
    List<_i61.PageRouteInfo>? children,
  }) : super(
          MatrixStoriesRoute.name,
          args: MatrixStoriesRouteArgs(
            room: room,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'MatrixStoriesRoute';

  static const _i61.PageInfo<MatrixStoriesRouteArgs> page =
      _i61.PageInfo<MatrixStoriesRouteArgs>(name);
}

class MatrixStoriesRouteArgs {
  const MatrixStoriesRouteArgs({
    required this.room,
    this.key,
  });

  final _i63.Room room;

  final _i62.Key? key;

  @override
  String toString() {
    return 'MatrixStoriesRouteArgs{room: $room, key: $key}';
  }
}

/// generated route for
/// [_i27.MobileCreateAccountPage]
class MobileCreateAccountRoute extends _i61.PageRouteInfo<void> {
  const MobileCreateAccountRoute({List<_i61.PageRouteInfo>? children})
      : super(
          MobileCreateAccountRoute.name,
          initialChildren: children,
        );

  static const String name = 'MobileCreateAccountRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i28.MobileExplorePage]
class MobileExploreRoute extends _i61.PageRouteInfo<void> {
  const MobileExploreRoute({List<_i61.PageRouteInfo>? children})
      : super(
          MobileExploreRoute.name,
          initialChildren: children,
        );

  static const String name = 'MobileExploreRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i29.MobileLoginPage]
class MobileLoginRoute extends _i61.PageRouteInfo<MobileLoginRouteArgs> {
  MobileLoginRoute({
    _i62.Key? key,
    bool popOnLogin = false,
    List<_i61.PageRouteInfo>? children,
  }) : super(
          MobileLoginRoute.name,
          args: MobileLoginRouteArgs(
            key: key,
            popOnLogin: popOnLogin,
          ),
          initialChildren: children,
        );

  static const String name = 'MobileLoginRoute';

  static const _i61.PageInfo<MobileLoginRouteArgs> page =
      _i61.PageInfo<MobileLoginRouteArgs>(name);
}

class MobileLoginRouteArgs {
  const MobileLoginRouteArgs({
    this.key,
    this.popOnLogin = false,
  });

  final _i62.Key? key;

  final bool popOnLogin;

  @override
  String toString() {
    return 'MobileLoginRouteArgs{key: $key, popOnLogin: $popOnLogin}';
  }
}

/// generated route for
/// [_i30.MobileWelcomePage]
class MobileWelcomeRoute extends _i61.PageRouteInfo<void> {
  const MobileWelcomeRoute({List<_i61.PageRouteInfo>? children})
      : super(
          MobileWelcomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'MobileWelcomeRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i31.MobileWelcomeRouterPage]
class MobileWelcomeRouter extends _i61.PageRouteInfo<void> {
  const MobileWelcomeRouter({List<_i61.PageRouteInfo>? children})
      : super(
          MobileWelcomeRouter.name,
          initialChildren: children,
        );

  static const String name = 'MobileWelcomeRouter';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i32.OverrideRoomListRoomPage]
class OverrideRoomListRoomRoute
    extends _i61.PageRouteInfo<OverrideRoomListRoomRouteArgs> {
  OverrideRoomListRoomRoute({
    _i62.Key? key,
    bool displaySettingsOnDesktop = false,
    List<_i61.PageRouteInfo>? children,
  }) : super(
          OverrideRoomListRoomRoute.name,
          args: OverrideRoomListRoomRouteArgs(
            key: key,
            displaySettingsOnDesktop: displaySettingsOnDesktop,
          ),
          initialChildren: children,
        );

  static const String name = 'OverrideRoomListRoomRoute';

  static const _i61.PageInfo<OverrideRoomListRoomRouteArgs> page =
      _i61.PageInfo<OverrideRoomListRoomRouteArgs>(name);
}

class OverrideRoomListRoomRouteArgs {
  const OverrideRoomListRoomRouteArgs({
    this.key,
    this.displaySettingsOnDesktop = false,
  });

  final _i62.Key? key;

  final bool displaySettingsOnDesktop;

  @override
  String toString() {
    return 'OverrideRoomListRoomRouteArgs{key: $key, displaySettingsOnDesktop: $displaySettingsOnDesktop}';
  }
}

/// generated route for
/// [_i33.OverrideRoomListSpacePage]
class OverrideRoomListSpaceRoute extends _i61.PageRouteInfo<void> {
  const OverrideRoomListSpaceRoute({List<_i61.PageRouteInfo>? children})
      : super(
          OverrideRoomListSpaceRoute.name,
          initialChildren: children,
        );

  static const String name = 'OverrideRoomListSpaceRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i34.OverrideRoomSpacePage]
class OverrideRoomSpaceRoute
    extends _i61.PageRouteInfo<OverrideRoomSpaceRouteArgs> {
  OverrideRoomSpaceRoute({
    _i62.Key? key,
    required String spaceId,
    required _i63.Client client,
    void Function()? onBack,
    List<_i61.PageRouteInfo>? children,
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

  static const _i61.PageInfo<OverrideRoomSpaceRouteArgs> page =
      _i61.PageInfo<OverrideRoomSpaceRouteArgs>(name);
}

class OverrideRoomSpaceRouteArgs {
  const OverrideRoomSpaceRouteArgs({
    this.key,
    required this.spaceId,
    required this.client,
    this.onBack,
  });

  final _i62.Key? key;

  final String spaceId;

  final _i63.Client client;

  final void Function()? onBack;

  @override
  String toString() {
    return 'OverrideRoomSpaceRouteArgs{key: $key, spaceId: $spaceId, client: $client, onBack: $onBack}';
  }
}

/// generated route for
/// [_i35.PostGalleryPage]
class PostGalleryRoute extends _i61.PageRouteInfo<PostGalleryRouteArgs> {
  PostGalleryRoute({
    _i62.Key? key,
    required _i63.Event post,
    _i63.Event? image,
    String? selectedImageEventId,
    List<_i61.PageRouteInfo>? children,
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

  static const _i61.PageInfo<PostGalleryRouteArgs> page =
      _i61.PageInfo<PostGalleryRouteArgs>(name);
}

class PostGalleryRouteArgs {
  const PostGalleryRouteArgs({
    this.key,
    required this.post,
    this.image,
    this.selectedImageEventId,
  });

  final _i62.Key? key;

  final _i63.Event post;

  final _i63.Event? image;

  final String? selectedImageEventId;

  @override
  String toString() {
    return 'PostGalleryRouteArgs{key: $key, post: $post, image: $image, selectedImageEventId: $selectedImageEventId}';
  }
}

/// generated route for
/// [_i36.PostPage]
class PostRoute extends _i61.PageRouteInfo<PostRouteArgs> {
  PostRoute({
    _i62.Key? key,
    required _i63.Event event,
    required _i63.Timeline timeline,
    List<_i61.PageRouteInfo>? children,
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

  static const _i61.PageInfo<PostRouteArgs> page =
      _i61.PageInfo<PostRouteArgs>(name);
}

class PostRouteArgs {
  const PostRouteArgs({
    this.key,
    required this.event,
    required this.timeline,
  });

  final _i62.Key? key;

  final _i63.Event event;

  final _i63.Timeline timeline;

  @override
  String toString() {
    return 'PostRouteArgs{key: $key, event: $event, timeline: $timeline}';
  }
}

/// generated route for
/// [_i37.RoomListOrPlaceHolderPage]
class RoomListOrPlaceHolderRoute extends _i61.PageRouteInfo<void> {
  const RoomListOrPlaceHolderRoute({List<_i61.PageRouteInfo>? children})
      : super(
          RoomListOrPlaceHolderRoute.name,
          initialChildren: children,
        );

  static const String name = 'RoomListOrPlaceHolderRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i38.RoomPage]
class RoomRoute extends _i61.PageRouteInfo<RoomRouteArgs> {
  RoomRoute({
    _i62.Key? key,
    required String roomId,
    required _i63.Client client,
    void Function()? onBack,
    bool allowPop = false,
    bool displaySettingsOnDesktop = false,
    List<_i61.PageRouteInfo>? children,
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

  static const _i61.PageInfo<RoomRouteArgs> page =
      _i61.PageInfo<RoomRouteArgs>(name);
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

  final _i62.Key? key;

  final String roomId;

  final _i63.Client client;

  final void Function()? onBack;

  final bool allowPop;

  final bool displaySettingsOnDesktop;

  @override
  String toString() {
    return 'RoomRouteArgs{key: $key, roomId: $roomId, client: $client, onBack: $onBack, allowPop: $allowPop, displaySettingsOnDesktop: $displaySettingsOnDesktop}';
  }
}

/// generated route for
/// [_i39.RoomSettingsPage]
class RoomSettingsRoute extends _i61.PageRouteInfo<RoomSettingsRouteArgs> {
  RoomSettingsRoute({
    _i62.Key? key,
    required _i63.Room room,
    required void Function() onLeave,
    List<_i61.PageRouteInfo>? children,
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

  static const _i61.PageInfo<RoomSettingsRouteArgs> page =
      _i61.PageInfo<RoomSettingsRouteArgs>(name);
}

class RoomSettingsRouteArgs {
  const RoomSettingsRouteArgs({
    this.key,
    required this.room,
    required this.onLeave,
  });

  final _i62.Key? key;

  final _i63.Room room;

  final void Function() onLeave;

  @override
  String toString() {
    return 'RoomSettingsRouteArgs{key: $key, room: $room, onLeave: $onLeave}';
  }
}

/// generated route for
/// [_i40.SearchPage]
class SearchRoute extends _i61.PageRouteInfo<SearchRouteArgs> {
  SearchRoute({
    _i62.Key? key,
    bool isPopup = false,
    _i64.SearchMode? initialSearchMode,
    List<_i61.PageRouteInfo>? children,
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

  static const _i61.PageInfo<SearchRouteArgs> page =
      _i61.PageInfo<SearchRouteArgs>(name);
}

class SearchRouteArgs {
  const SearchRouteArgs({
    this.key,
    this.isPopup = false,
    this.initialSearchMode,
  });

  final _i62.Key? key;

  final bool isPopup;

  final _i64.SearchMode? initialSearchMode;

  @override
  String toString() {
    return 'SearchRouteArgs{key: $key, isPopup: $isPopup, initialSearchMode: $initialSearchMode}';
  }
}

/// generated route for
/// [_i41.SettingsAccountPage]
class SettingsAccountRoute extends _i61.PageRouteInfo<void> {
  const SettingsAccountRoute({List<_i61.PageRouteInfo>? children})
      : super(
          SettingsAccountRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsAccountRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i42.SettingsAccountSwitchPage]
class SettingsAccountSwitchRoute
    extends _i61.PageRouteInfo<SettingsAccountSwitchRouteArgs> {
  SettingsAccountSwitchRoute({
    _i62.Key? key,
    bool popOnUserSelected = false,
    List<_i61.PageRouteInfo>? children,
  }) : super(
          SettingsAccountSwitchRoute.name,
          args: SettingsAccountSwitchRouteArgs(
            key: key,
            popOnUserSelected: popOnUserSelected,
          ),
          initialChildren: children,
        );

  static const String name = 'SettingsAccountSwitchRoute';

  static const _i61.PageInfo<SettingsAccountSwitchRouteArgs> page =
      _i61.PageInfo<SettingsAccountSwitchRouteArgs>(name);
}

class SettingsAccountSwitchRouteArgs {
  const SettingsAccountSwitchRouteArgs({
    this.key,
    this.popOnUserSelected = false,
  });

  final _i62.Key? key;

  final bool popOnUserSelected;

  @override
  String toString() {
    return 'SettingsAccountSwitchRouteArgs{key: $key, popOnUserSelected: $popOnUserSelected}';
  }
}

/// generated route for
/// [_i43.SettingsFeedsPage]
class SettingsFeedsRoute extends _i61.PageRouteInfo<void> {
  const SettingsFeedsRoute({List<_i61.PageRouteInfo>? children})
      : super(
          SettingsFeedsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsFeedsRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i44.SettingsLabsPage]
class SettingsLabsRoute extends _i61.PageRouteInfo<void> {
  const SettingsLabsRoute({List<_i61.PageRouteInfo>? children})
      : super(
          SettingsLabsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsLabsRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i45.SettingsPage]
class SettingsRoute extends _i61.PageRouteInfo<void> {
  const SettingsRoute({List<_i61.PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i45.SettingsPanelInnerPage]
class SettingsPanelInnerRoute extends _i61.PageRouteInfo<void> {
  const SettingsPanelInnerRoute({List<_i61.PageRouteInfo>? children})
      : super(
          SettingsPanelInnerRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsPanelInnerRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i46.SettingsSecurityPage]
class SettingsSecurityRoute extends _i61.PageRouteInfo<void> {
  const SettingsSecurityRoute({List<_i61.PageRouteInfo>? children})
      : super(
          SettingsSecurityRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsSecurityRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i47.SettingsStorysDetailPage]
class SettingsStorysDetailRoute
    extends _i61.PageRouteInfo<SettingsStorysDetailRouteArgs> {
  SettingsStorysDetailRoute({
    _i62.Key? key,
    required _i63.Room room,
    List<_i61.PageRouteInfo>? children,
  }) : super(
          SettingsStorysDetailRoute.name,
          args: SettingsStorysDetailRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'SettingsStorysDetailRoute';

  static const _i61.PageInfo<SettingsStorysDetailRouteArgs> page =
      _i61.PageInfo<SettingsStorysDetailRouteArgs>(name);
}

class SettingsStorysDetailRouteArgs {
  const SettingsStorysDetailRouteArgs({
    this.key,
    required this.room,
  });

  final _i62.Key? key;

  final _i63.Room room;

  @override
  String toString() {
    return 'SettingsStorysDetailRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i48.SettingsStorysPage]
class SettingsStorysRoute extends _i61.PageRouteInfo<void> {
  const SettingsStorysRoute({List<_i61.PageRouteInfo>? children})
      : super(
          SettingsStorysRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsStorysRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i49.SettingsSyncPage]
class SettingsSyncRoute extends _i61.PageRouteInfo<void> {
  const SettingsSyncRoute({List<_i61.PageRouteInfo>? children})
      : super(
          SettingsSyncRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsSyncRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i50.SettingsThemePage]
class SettingsThemeRoute extends _i61.PageRouteInfo<void> {
  const SettingsThemeRoute({List<_i61.PageRouteInfo>? children})
      : super(
          SettingsThemeRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsThemeRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i51.SocialSettingsPage]
class SocialSettingsRoute extends _i61.PageRouteInfo<SocialSettingsRouteArgs> {
  SocialSettingsRoute({
    _i62.Key? key,
    required _i63.Room room,
    List<_i61.PageRouteInfo>? children,
  }) : super(
          SocialSettingsRoute.name,
          args: SocialSettingsRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'SocialSettingsRoute';

  static const _i61.PageInfo<SocialSettingsRouteArgs> page =
      _i61.PageInfo<SocialSettingsRouteArgs>(name);
}

class SocialSettingsRouteArgs {
  const SocialSettingsRouteArgs({
    this.key,
    required this.room,
  });

  final _i62.Key? key;

  final _i63.Room room;

  @override
  String toString() {
    return 'SocialSettingsRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i52.SpacePage]
class SpaceRoute extends _i61.PageRouteInfo<SpaceRouteArgs> {
  SpaceRoute({
    _i62.Key? key,
    required String spaceId,
    required _i63.Client client,
    void Function()? onBack,
    List<_i61.PageRouteInfo>? children,
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

  static const _i61.PageInfo<SpaceRouteArgs> page =
      _i61.PageInfo<SpaceRouteArgs>(name);
}

class SpaceRouteArgs {
  const SpaceRouteArgs({
    this.key,
    required this.spaceId,
    required this.client,
    this.onBack,
  });

  final _i62.Key? key;

  final String spaceId;

  final _i63.Client client;

  final void Function()? onBack;

  @override
  String toString() {
    return 'SpaceRouteArgs{key: $key, spaceId: $spaceId, client: $client, onBack: $onBack}';
  }
}

/// generated route for
/// [_i53.TabCalendarPage]
class TabCalendarRoute extends _i61.PageRouteInfo<void> {
  const TabCalendarRoute({List<_i61.PageRouteInfo>? children})
      : super(
          TabCalendarRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabCalendarRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i54.TabCameraPage]
class TabCameraRoute extends _i61.PageRouteInfo<void> {
  const TabCameraRoute({List<_i61.PageRouteInfo>? children})
      : super(
          TabCameraRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabCameraRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i55.TabChatPage]
class TabChatRoute extends _i61.PageRouteInfo<void> {
  const TabChatRoute({List<_i61.PageRouteInfo>? children})
      : super(
          TabChatRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabChatRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i56.TabCommunityPage]
class TabCommunityRoute extends _i61.PageRouteInfo<void> {
  const TabCommunityRoute({List<_i61.PageRouteInfo>? children})
      : super(
          TabCommunityRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabCommunityRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i57.TabHomePage]
class TabHomeRoute extends _i61.PageRouteInfo<void> {
  const TabHomeRoute({List<_i61.PageRouteInfo>? children})
      : super(
          TabHomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabHomeRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i58.TabStoriesPage]
class TabStoriesRoute extends _i61.PageRouteInfo<void> {
  const TabStoriesRoute({List<_i61.PageRouteInfo>? children})
      : super(
          TabStoriesRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabStoriesRoute';

  static const _i61.PageInfo<void> page = _i61.PageInfo<void>(name);
}

/// generated route for
/// [_i59.UserFollowersPage]
class UserFollowersRoute extends _i61.PageRouteInfo<UserFollowersRouteArgs> {
  UserFollowersRoute({
    _i62.Key? key,
    required _i63.Room room,
    List<_i61.PageRouteInfo>? children,
  }) : super(
          UserFollowersRoute.name,
          args: UserFollowersRouteArgs(
            key: key,
            room: room,
          ),
          initialChildren: children,
        );

  static const String name = 'UserFollowersRoute';

  static const _i61.PageInfo<UserFollowersRouteArgs> page =
      _i61.PageInfo<UserFollowersRouteArgs>(name);
}

class UserFollowersRouteArgs {
  const UserFollowersRouteArgs({
    this.key,
    required this.room,
  });

  final _i62.Key? key;

  final _i63.Room room;

  @override
  String toString() {
    return 'UserFollowersRouteArgs{key: $key, room: $room}';
  }
}

/// generated route for
/// [_i60.UserViewPage]
class UserViewRoute extends _i61.PageRouteInfo<UserViewRouteArgs> {
  UserViewRoute({
    _i62.Key? key,
    String? userID,
    _i63.Room? mroom,
    List<_i61.PageRouteInfo>? children,
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

  static const _i61.PageInfo<UserViewRouteArgs> page =
      _i61.PageInfo<UserViewRouteArgs>(name);
}

class UserViewRouteArgs {
  const UserViewRouteArgs({
    this.key,
    this.userID,
    this.mroom,
  });

  final _i62.Key? key;

  final String? userID;

  final _i63.Room? mroom;

  @override
  String toString() {
    return 'UserViewRouteArgs{key: $key, userID: $userID, mroom: $mroom}';
  }
}
