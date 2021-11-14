// @CupertinoAutoRouter
// @AdaptiveAutoRouter
// @CustomAutoRouter
import 'package:auto_route/annotations.dart';
import 'package:minestrix/components/post/postEditor.dart';
import 'package:minestrix/pages/account/accountsDetailsPage.dart';
import 'package:minestrix/pages/minestrix/feedPage.dart';
import 'package:minestrix/pages/minestrix/friends/friendsVue.dart';
import 'package:minestrix/pages/minestrix/friends/researchPage.dart';
import 'package:minestrix/pages/minestrix/groups/groupPage.dart';
import 'package:minestrix/pages/minestrix/homeWraperPage.dart';
import 'package:minestrix/pages/loginPage.dart';
import 'package:minestrix/pages/matrixLoadingPage.dart';
import 'package:minestrix/pages/minestrix/user/userFeedPage.dart';
import 'package:minestrix/pages/minestrix/user/userFriendsPage.dart';
import 'package:minestrix/pages/settingsPage.dart';
import 'package:minestrix_chat/view/matrix_chat_page.dart';
import 'package:minestrix_chat/view/matrix_chats_page.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    AutoRoute(page: MatrixLoadingPage),
    AutoRoute(path: '/', page: HomeWraperPage, children: [
      AutoRoute(path: '', page: FeedPage),
      AutoRoute(path: 'group', page: GroupPage),
      AutoRoute(path: 'friends', page: FriendsPage),
      AutoRoute(path: 'createPost', page: PostEditorPage),
      AutoRoute(path: 'chats', page: MatrixChatsPage),
      AutoRoute(path: 'chat/:roomId', page: MatrixChatPage),
      AutoRoute(path: 'user/feed/:userId', page: UserFeedPage),
      AutoRoute(path: 'user/friends/', page: UserFriendsPage),
      AutoRoute(path: 'search', page: ResearchPage),
      AutoRoute(path: 'accounts', page: AccountsDetailsPage),
      AutoRoute(path: 'settings', page: SettingsPage),
      RedirectRoute(path: '*', redirectTo: '')
    ]),
    AutoRoute(path: '/login', page: LoginPage),
  ],
)
class $AppRouter {}
