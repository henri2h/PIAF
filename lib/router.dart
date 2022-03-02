// @CupertinoAutoRouter
// @AdaptiveAutoRouter
// @CustomAutoRouter
import 'package:auto_route/auto_route.dart';
import 'package:minestrix/pages/calendar_events/calendarEventPage.dart';
import 'package:minestrix/pages/minestrix/calendarEvents/calendarEventsListPage.dart';
import 'package:minestrix/pages/minestrix/groups/createGroupPage.dart';
import 'package:minestrix/pages/minestrix/postEditor.dart';
import 'package:minestrix/pages/account/accountsDetailsPage.dart';
import 'package:minestrix/pages/appWrapperPage.dart';
import 'package:minestrix/pages/loginPage.dart';
import 'package:minestrix/pages/matrixLoadingPage.dart';
import 'package:minestrix/pages/minestrix/feedPage.dart';
import 'package:minestrix/pages/minestrix/friends/researchPage.dart';
import 'package:minestrix/pages/minestrix/groups/groupPage.dart';
import 'package:minestrix/pages/minestrix/homeWrapperPage.dart';
import 'package:minestrix/pages/minestrix/user/friendsPage.dart';
import 'package:minestrix/pages/minestrix/user/userFriendsPage.dart';
import 'package:minestrix/pages/minestrix/user/userViewPage.dart';
import 'package:minestrix/pages/settings/settingsPage.dart';
import 'package:minestrix/pages/settings/settingsProfilePage.dart';
import 'package:minestrix/pages/settings/settingsSecurityPage.dart';
import 'package:minestrix/pages/settings/settingsThemePage.dart';
import 'package:minestrix_chat/view/matrix_chat_page.dart';
import 'package:minestrix_chat/view/matrix_chats_page.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    AutoRoute(page: MatrixLoadingPage),

// this app wrapper add the top navigation bar for desktop
// we want to have the top navigation bar on the chat page when on desktop but not the bottom one on small screen
// as it's distracting when typing messages
    AutoRoute(path: '/', page: AppWrapperPage, children: [
      // nested routes defines the bottom navigation bar for mobile
      AutoRoute(
          path: '',
          name: 'MinestrixRouter',
          page: HomeWrapperPage,
          children: [
            AutoRoute(path: 'feed', page: FeedPage, initial: true),
            AutoRoute(path: 'group', page: GroupPage),
            AutoRoute(path: 'group/create', page: CreateGroupPage),
            AutoRoute(path: 'createPost', page: PostEditorPage),
            AutoRoute(path: 'userfeed', page: UserViewPage),
            AutoRoute(path: 'my_friends', page: FriendsPage),
            AutoRoute(path: 'user_friends', page: UserFriendsPage),
            AutoRoute(path: 'calendar_events/item', page: CalendarEventPage),
            AutoRoute(
                path: 'calendar_events/list', page: CalendarEventListPage),
            AutoRoute(path: 'search', page: ResearchPage),
            AutoRoute(path: 'accounts', page: AccountsDetailsPage),
            AutoRoute(path: 'settings', page: SettingsPage),
            AutoRoute(path: 'settings/account', page: SettingsAccountPage),
            AutoRoute(path: 'settings/theme', page: SettingsThemePage),
            AutoRoute(path: 'settings/security', page: SettingsSecurityPage),
            RedirectRoute(path: '*', redirectTo: 'feed')
          ]),
      AutoRoute(
        path: 'chats',
        page: MatrixChatsPage,
      ),
      AutoRoute(
          path: 'chatsW',
          name: 'ChatsRouter',
          page: EmptyRouterPage,
          children: [
            AutoRoute(path: ':roomId', page: MatrixChatPage),
            RedirectRoute(path: '*', redirectTo: ''),
          ]),
      RedirectRoute(path: '*', redirectTo: ''),
    ]),
    AutoRoute(path: '/login', page: LoginPage)
  ],
)
class $AppRouter {}
