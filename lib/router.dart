// @CupertinoAutoRouter
// @AdaptiveAutoRouter
// @CustomAutoRouter

import 'package:auto_route/auto_route.dart';
import 'package:minestrix_chat/partials/feed/posts/matrix_post_editor.dart';
import 'package:minestrix_chat/view/room_list_page.dart';
import 'package:minestrix_chat/view/room_page.dart';

import 'pages/account/accountsDetailsPage.dart';
import 'pages/appWrapperPage.dart';
import 'pages/calendar_events/calendarEventPage.dart';
import 'pages/loginPage.dart';
import 'pages/main_page.dart';
import 'pages/matrixLoadingPage.dart';
import 'pages/minestrix/calendarEvents/calendarEventsListPage.dart';
import 'pages/minestrix/feedPage.dart';
import 'pages/minestrix/friends/researchPage.dart';
import 'pages/minestrix/groups/createGroupPage.dart';
import 'pages/minestrix/groups/groupPage.dart';
import 'pages/minestrix/image/post_gallery_page.dart';
import 'pages/minestrix/user/friendsPage.dart';
import 'pages/minestrix/user/userFriendsPage.dart';
import 'pages/minestrix/user/userViewPage.dart';
import 'pages/settings/settingsLabsPage.dart';
import 'pages/settings/settingsPage.dart';
import 'pages/settings/settingsProfilePage.dart';
import 'pages/settings/settingsSecurityPage.dart';
import 'pages/settings/settingsThemePage.dart';

@AdaptiveAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    AutoRoute(page: MatrixLoadingPage),

// this app wrapper add the top navigation bar for desktop
// we want to have the top navigation bar on the chat page when on desktop but not the bottom one on small screen
// as it's distracting when typing messages
    AutoRoute(path: '/', page: AppWrapperPage, children: [
      // nested routes defines the bottom navigation bar for mobile

      AutoRoute(path: '', page: MainPage, initial: true, children: [
        AutoRoute(path: 'feed', page: FeedPage, initial: true),
        AutoRoute(path: 'search', page: ResearchPage),
        AutoRoute(path: 'my_account', page: UserViewPage, name: "UserRoute"),
        AutoRoute(
          path: 'chats',
          page: RoomsListPage,
        ),
      ]),
      AutoRoute(path: 'feed', page: FeedPage),
      AutoRoute(path: 'group', page: GroupPage),
      AutoRoute(path: 'group/create', page: CreateGroupPage),
      AutoRoute(path: 'createPost', page: PostEditorPage),
      AutoRoute(path: 'userfeed', page: UserViewPage),
      AutoRoute(path: 'my_friends', page: FriendsPage),
      AutoRoute(path: 'user_friends', page: UserFriendsPage),
      AutoRoute(path: 'calendar_events/item', page: CalendarEventPage),
      AutoRoute(path: 'post/image_gallery', page: PostGalleryPage),
      AutoRoute(path: 'calendar_events/list', page: CalendarEventListPage),
      AutoRoute(path: 'search', page: ResearchPage),
      AutoRoute(path: 'accounts', page: AccountsDetailsPage),
      AutoRoute(path: 'settings', page: SettingsPage),
      AutoRoute(path: 'settings/account', page: SettingsAccountPage),
      AutoRoute(path: 'settings/theme', page: SettingsThemePage),
      AutoRoute(path: 'settings/security', page: SettingsSecurityPage),
      AutoRoute(path: 'settings/labs', page: SettingsLabsPage),
      // chats
      AutoRoute(path: ':roomId', page: RoomPage),
      AutoRoute(
        path: 'chats',
        page: RoomsListPage,
      ),
      AutoRoute(path: 'login', page: LoginPage),
      RedirectRoute(path: '*', redirectTo: 'feed')
    ]),

    AutoRoute(path: 'login', page: LoginPage)
  ],
)
class $AppRouter {}
