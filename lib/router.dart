import 'package:auto_route/auto_route.dart';
import 'package:piaf/router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends $AppRouter {
  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  static List<AutoRoute> welcomeRoutes = [
    AutoRoute(path: 'mobile_login', page: MobileLoginRoute.page),
    AutoRoute(
        path: 'mobile_create_account', page: MobileCreateAccountRoute.page),
    AutoRoute(path: 'mobile_explore', page: MobileExploreRoute.page),
  ];

  static List<AutoRoute> communityRoutes = [
    AutoRoute(path: 'communities', page: CommunityRoute.page),
    AutoRoute(path: 'community', page: CommunityDetailRoute.page),
    AutoRoute(path: 'social_page_settings', page: SocialSettingsRoute.page),
  ];

  static List<AutoRoute> calendarRoutes = [
    AutoRoute(path: 'events', page: CalendarEventListRoute.page),
    AutoRoute(path: 'events/calendar', page: CalendarEventRoute.page),
    AutoRoute(path: 'social_page_settings', page: SocialSettingsRoute.page),
  ];

  @override
  final List<AutoRoute> routes = [
    AutoRoute(path: '/loading', page: MatrixLoadingRoute.page),

// this app wrapper add the top navigation bar for desktop
// we want to have the top navigation bar on the chat page when on desktop but not the bottom one on small screen
// as it's distracting when typing messages
    AutoRoute(path: '/', page: AppWrapperRoute.page, children: [
      AutoRoute(path: 'home', page: TabHomeRoute.page, children: [
        AutoRoute(path: '', page: HomeRoute.page),
        AutoRoute(path: 'feed', page: FeedRoute.page),
        AutoRoute(path: 'feeds', page: FeedListRoute.page),
        AutoRoute(path: 'feeds/create', page: FeedCreationRoute.page),
        AutoRoute(path: 'post', page: PostRoute.page),
        AutoRoute(path: 'feeds/search', page: SearchRoute.page),
        AutoRoute(path: 'group/:roomId', page: GroupRoute.page),
        AutoRoute(path: 'group/create', page: CreateGroupRoute.page),
        AutoRoute(path: 'user_feed', page: UserViewRoute.page),
        AutoRoute(path: 'followers', page: UserFollowersRoute.page),
        AutoRoute(path: 'post/image_gallery', page: PostGalleryRoute.page),
        AutoRoute(path: 'accounts', page: SettingsFeedsRoute.page),
        AutoRoute(
            path: 'recommandations', page: FollowRecommendationsRoute.page),
        AutoRoute(path: 'social_page_settings', page: SocialSettingsRoute.page),
        AutoRoute(path: 'settings', page: SettingsRoute.page, children: [
          AutoRoute(
            path: '',
            page: SettingsPanelInnerRoute.page,
          ),
          AutoRoute(path: 'account', page: SettingsAccountRoute.page),
          AutoRoute(
              path: 'account_switch', page: SettingsAccountSwitchRoute.page),
          AutoRoute(path: 'theme', page: SettingsThemeRoute.page),
          AutoRoute(path: 'security', page: SettingsSecurityRoute.page),
          AutoRoute(path: 'labs', page: SettingsLabsRoute.page),
          AutoRoute(path: 'sync', page: SettingsSyncRoute.page),
          AutoRoute(path: 'storys', page: SettingsStorysRoute.page),
          AutoRoute(path: 'story', page: SettingsStorysDetailRoute.page),
          AutoRoute(path: 'accounts', page: SettingsFeedsRoute.page),
          AutoRoute(path: 'debug', page: DebugRoute.page),
          AutoRoute(path: 'chat/:roomId', page: RoomRoute.page),
        ]),
        ...communityRoutes,
        ...calendarRoutes,
        AutoRoute(path: 'feeds/search', page: SearchRoute.page),
      ]),

      AutoRoute(path: 'search', page: SearchRoute.page),
      AutoRoute(path: 'stories', page: TabStoriesRoute.page),

      AutoRoute(
          path: 'events',
          page: TabCalendarRoute.page,
          children: calendarRoutes),

      AutoRoute(
          path: 'community',
          page: TabCommunityRoute.page,
          children: communityRoutes),

      AutoRoute(path: 'camera', page: TabCameraRoute.page),

      // chats, initial page
      AutoRoute(path: '', page: TabChatRoute.page, children: [
        AutoRoute(path: '', page: RoomListOrPlaceHolderRoute.page),
        AutoRoute(path: 'space', page: OverrideRoomListSpaceRoute.page),
        AutoRoute(path: 'space/:spaceId', page: OverrideRoomSpaceRoute.page),
        AutoRoute(path: ':roomId', page: OverrideRoomListRoomRoute.page),
      ]),

      AutoRoute(path: 'desktop_login', page: DesktopLoginRoute.page),
      AutoRoute(path: 'mobile_login', page: MobileLoginRoute.page),

      RedirectRoute(path: '*', redirectTo: 'feed')
    ]),

    AutoRoute(
        path: '/desktop_login',
        page: DesktopLoginRoute.page,
        children: welcomeRoutes
          ..add(
            AutoRoute(path: '', page: DesktopWelcomeRoute.page),
          )),
    AutoRoute(
        page: MobileWelcomeRouter.page,
        children: welcomeRoutes
          ..add(
            AutoRoute(path: '', page: MobileWelcomeRoute.page),
          )),
  ];
}
