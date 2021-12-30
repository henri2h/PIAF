// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i6;
import 'package:flutter/material.dart' as _i17;
import 'package:matrix/matrix.dart' as _i18;
import 'package:minestrix_chat/view/matrix_chat_page.dart' as _i16;
import 'package:minestrix_chat/view/matrix_chats_page.dart' as _i5;

import 'components/post/postEditor.dart' as _i9;
import 'pages/account/accountsDetailsPage.dart' as _i14;
import 'pages/appWrapperPage.dart' as _i2;
import 'pages/loginPage.dart' as _i3;
import 'pages/matrixLoadingPage.dart' as _i1;
import 'pages/minestrix/feedPage.dart' as _i7;
import 'pages/minestrix/friends/researchPage.dart' as _i13;
import 'pages/minestrix/groups/groupPage.dart' as _i8;
import 'pages/minestrix/homeWraperPage.dart' as _i4;
import 'pages/minestrix/user/friendsPage.dart' as _i11;
import 'pages/minestrix/user/userFriendsPage.dart' as _i12;
import 'pages/minestrix/user/userViewPage.dart' as _i10;
import 'pages/settingsPage.dart' as _i15;
import 'utils/minestrix/minestrixRoom.dart' as _i19;

class AppRouter extends _i6.RootStackRouter {
  AppRouter([_i17.GlobalKey<_i17.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i6.PageFactory> pagesMap = {
    MatrixLoadingRoute.name: (routeData) {
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i1.MatrixLoadingPage());
    },
    AppWrapperRoute.name: (routeData) {
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i2.AppWrapperPage());
    },
    LoginRoute.name: (routeData) {
      final args = routeData.argsAs<LoginRouteArgs>(
          orElse: () => const LoginRouteArgs());
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i3.LoginPage(
              key: args.key, title: args.title, onLogin: args.onLogin));
    },
    MinestrixRouter.name: (routeData) {
      final args = routeData.argsAs<MinestrixRouterArgs>(
          orElse: () => const MinestrixRouterArgs());
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i4.HomeWraperPage(key: args.key, title: args.title));
    },
    MatrixChatsRoute.name: (routeData) {
      final args = routeData.argsAs<MatrixChatsRouteArgs>();
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i5.MatrixChatsPage(
              key: args.key,
              client: args.client,
              enableStories: args.enableStories));
    },
    ChatsRouter.name: (routeData) {
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i6.EmptyRouterPage());
    },
    FeedRoute.name: (routeData) {
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i7.FeedPage());
    },
    GroupRoute.name: (routeData) {
      final args = routeData.argsAs<GroupRouteArgs>(
          orElse: () => const GroupRouteArgs());
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i8.GroupPage(key: args.key, sroom: args.sroom));
    },
    PostEditorRoute.name: (routeData) {
      final args = routeData.argsAs<PostEditorRouteArgs>(
          orElse: () => const PostEditorRouteArgs());
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i9.PostEditorPage(key: args.key, sroom: args.sroom));
    },
    UserViewRoute.name: (routeData) {
      final args = routeData.argsAs<UserViewRouteArgs>(
          orElse: () => const UserViewRouteArgs());
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i10.UserViewPage(
              key: args.key, userID: args.userID, mroom: args.mroom));
    },
    FriendsRoute.name: (routeData) {
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i11.FriendsPage());
    },
    UserFriendsRoute.name: (routeData) {
      final args = routeData.argsAs<UserFriendsRouteArgs>();
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i12.UserFriendsPage(key: args.key, sroom: args.sroom));
    },
    ResearchRoute.name: (routeData) {
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData, child: _i13.ResearchPage());
    },
    AccountsDetailsRoute.name: (routeData) {
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i14.AccountsDetailsPage());
    },
    SettingsRoute.name: (routeData) {
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i15.SettingsPage());
    },
    MatrixChatRoute.name: (routeData) {
      final args = routeData.argsAs<MatrixChatRouteArgs>();
      return _i6.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i16.MatrixChatPage(
              key: args.key,
              roomId: args.roomId,
              client: args.client,
              onBack: args.onBack));
    }
  };

  @override
  List<_i6.RouteConfig> get routes => [
        _i6.RouteConfig(MatrixLoadingRoute.name, path: '/matrix-loading-page'),
        _i6.RouteConfig(AppWrapperRoute.name, path: '/', children: [
          _i6.RouteConfig(MinestrixRouter.name,
              path: '',
              parent: AppWrapperRoute.name,
              children: [
                _i6.RouteConfig('#redirect',
                    path: '',
                    parent: MinestrixRouter.name,
                    redirectTo: 'feed',
                    fullMatch: true),
                _i6.RouteConfig(FeedRoute.name,
                    path: 'feed', parent: MinestrixRouter.name),
                _i6.RouteConfig(GroupRoute.name,
                    path: 'group', parent: MinestrixRouter.name),
                _i6.RouteConfig(PostEditorRoute.name,
                    path: 'createPost', parent: MinestrixRouter.name),
                _i6.RouteConfig(UserViewRoute.name,
                    path: 'userfeed', parent: MinestrixRouter.name),
                _i6.RouteConfig(FriendsRoute.name,
                    path: 'my_friends', parent: MinestrixRouter.name),
                _i6.RouteConfig(UserFriendsRoute.name,
                    path: 'user_friends', parent: MinestrixRouter.name),
                _i6.RouteConfig(ResearchRoute.name,
                    path: 'search', parent: MinestrixRouter.name),
                _i6.RouteConfig(AccountsDetailsRoute.name,
                    path: 'accounts', parent: MinestrixRouter.name),
                _i6.RouteConfig(SettingsRoute.name,
                    path: 'settings', parent: MinestrixRouter.name),
                _i6.RouteConfig('*#redirect',
                    path: '*',
                    parent: MinestrixRouter.name,
                    redirectTo: 'feed',
                    fullMatch: true)
              ]),
          _i6.RouteConfig(MatrixChatsRoute.name,
              path: 'chats', parent: AppWrapperRoute.name),
          _i6.RouteConfig(ChatsRouter.name,
              path: 'chatsW',
              parent: AppWrapperRoute.name,
              children: [
                _i6.RouteConfig(MatrixChatRoute.name,
                    path: ':roomId', parent: ChatsRouter.name),
                _i6.RouteConfig('*#redirect',
                    path: '*',
                    parent: ChatsRouter.name,
                    redirectTo: '',
                    fullMatch: true)
              ]),
          _i6.RouteConfig('*#redirect',
              path: '*',
              parent: AppWrapperRoute.name,
              redirectTo: '',
              fullMatch: true)
        ]),
        _i6.RouteConfig(LoginRoute.name, path: '/login')
      ];
}

/// generated route for
/// [_i1.MatrixLoadingPage]
class MatrixLoadingRoute extends _i6.PageRouteInfo<void> {
  const MatrixLoadingRoute()
      : super(MatrixLoadingRoute.name, path: '/matrix-loading-page');

  static const String name = 'MatrixLoadingRoute';
}

/// generated route for
/// [_i2.AppWrapperPage]
class AppWrapperRoute extends _i6.PageRouteInfo<void> {
  const AppWrapperRoute({List<_i6.PageRouteInfo>? children})
      : super(AppWrapperRoute.name, path: '/', initialChildren: children);

  static const String name = 'AppWrapperRoute';
}

/// generated route for
/// [_i3.LoginPage]
class LoginRoute extends _i6.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({_i17.Key? key, String? title, dynamic Function(bool)? onLogin})
      : super(LoginRoute.name,
            path: '/login',
            args: LoginRouteArgs(key: key, title: title, onLogin: onLogin));

  static const String name = 'LoginRoute';
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.title, this.onLogin});

  final _i17.Key? key;

  final String? title;

  final dynamic Function(bool)? onLogin;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, title: $title, onLogin: $onLogin}';
  }
}

/// generated route for
/// [_i4.HomeWraperPage]
class MinestrixRouter extends _i6.PageRouteInfo<MinestrixRouterArgs> {
  MinestrixRouter(
      {_i17.Key? key, String? title, List<_i6.PageRouteInfo>? children})
      : super(MinestrixRouter.name,
            path: '',
            args: MinestrixRouterArgs(key: key, title: title),
            initialChildren: children);

  static const String name = 'MinestrixRouter';
}

class MinestrixRouterArgs {
  const MinestrixRouterArgs({this.key, this.title});

  final _i17.Key? key;

  final String? title;

  @override
  String toString() {
    return 'MinestrixRouterArgs{key: $key, title: $title}';
  }
}

/// generated route for
/// [_i5.MatrixChatsPage]
class MatrixChatsRoute extends _i6.PageRouteInfo<MatrixChatsRouteArgs> {
  MatrixChatsRoute(
      {_i17.Key? key, required _i18.Client client, bool enableStories = false})
      : super(MatrixChatsRoute.name,
            path: 'chats',
            args: MatrixChatsRouteArgs(
                key: key, client: client, enableStories: enableStories));

  static const String name = 'MatrixChatsRoute';
}

class MatrixChatsRouteArgs {
  const MatrixChatsRouteArgs(
      {this.key, required this.client, this.enableStories = false});

  final _i17.Key? key;

  final _i18.Client client;

  final bool enableStories;

  @override
  String toString() {
    return 'MatrixChatsRouteArgs{key: $key, client: $client, enableStories: $enableStories}';
  }
}

/// generated route for
/// [_i6.EmptyRouterPage]
class ChatsRouter extends _i6.PageRouteInfo<void> {
  const ChatsRouter({List<_i6.PageRouteInfo>? children})
      : super(ChatsRouter.name, path: 'chatsW', initialChildren: children);

  static const String name = 'ChatsRouter';
}

/// generated route for
/// [_i7.FeedPage]
class FeedRoute extends _i6.PageRouteInfo<void> {
  const FeedRoute() : super(FeedRoute.name, path: 'feed');

  static const String name = 'FeedRoute';
}

/// generated route for
/// [_i8.GroupPage]
class GroupRoute extends _i6.PageRouteInfo<GroupRouteArgs> {
  GroupRoute({_i17.Key? key, _i19.MinestrixRoom? sroom})
      : super(GroupRoute.name,
            path: 'group', args: GroupRouteArgs(key: key, sroom: sroom));

  static const String name = 'GroupRoute';
}

class GroupRouteArgs {
  const GroupRouteArgs({this.key, this.sroom});

  final _i17.Key? key;

  final _i19.MinestrixRoom? sroom;

  @override
  String toString() {
    return 'GroupRouteArgs{key: $key, sroom: $sroom}';
  }
}

/// generated route for
/// [_i9.PostEditorPage]
class PostEditorRoute extends _i6.PageRouteInfo<PostEditorRouteArgs> {
  PostEditorRoute({_i17.Key? key, _i19.MinestrixRoom? sroom})
      : super(PostEditorRoute.name,
            path: 'createPost',
            args: PostEditorRouteArgs(key: key, sroom: sroom));

  static const String name = 'PostEditorRoute';
}

class PostEditorRouteArgs {
  const PostEditorRouteArgs({this.key, this.sroom});

  final _i17.Key? key;

  final _i19.MinestrixRoom? sroom;

  @override
  String toString() {
    return 'PostEditorRouteArgs{key: $key, sroom: $sroom}';
  }
}

/// generated route for
/// [_i10.UserViewPage]
class UserViewRoute extends _i6.PageRouteInfo<UserViewRouteArgs> {
  UserViewRoute({_i17.Key? key, String? userID, _i19.MinestrixRoom? mroom})
      : super(UserViewRoute.name,
            path: 'userfeed',
            args: UserViewRouteArgs(key: key, userID: userID, mroom: mroom));

  static const String name = 'UserViewRoute';
}

class UserViewRouteArgs {
  const UserViewRouteArgs({this.key, this.userID, this.mroom});

  final _i17.Key? key;

  final String? userID;

  final _i19.MinestrixRoom? mroom;

  @override
  String toString() {
    return 'UserViewRouteArgs{key: $key, userID: $userID, mroom: $mroom}';
  }
}

/// generated route for
/// [_i11.FriendsPage]
class FriendsRoute extends _i6.PageRouteInfo<void> {
  const FriendsRoute() : super(FriendsRoute.name, path: 'my_friends');

  static const String name = 'FriendsRoute';
}

/// generated route for
/// [_i12.UserFriendsPage]
class UserFriendsRoute extends _i6.PageRouteInfo<UserFriendsRouteArgs> {
  UserFriendsRoute({_i17.Key? key, required _i19.MinestrixRoom sroom})
      : super(UserFriendsRoute.name,
            path: 'user_friends',
            args: UserFriendsRouteArgs(key: key, sroom: sroom));

  static const String name = 'UserFriendsRoute';
}

class UserFriendsRouteArgs {
  const UserFriendsRouteArgs({this.key, required this.sroom});

  final _i17.Key? key;

  final _i19.MinestrixRoom sroom;

  @override
  String toString() {
    return 'UserFriendsRouteArgs{key: $key, sroom: $sroom}';
  }
}

/// generated route for
/// [_i13.ResearchPage]
class ResearchRoute extends _i6.PageRouteInfo<void> {
  const ResearchRoute() : super(ResearchRoute.name, path: 'search');

  static const String name = 'ResearchRoute';
}

/// generated route for
/// [_i14.AccountsDetailsPage]
class AccountsDetailsRoute extends _i6.PageRouteInfo<void> {
  const AccountsDetailsRoute()
      : super(AccountsDetailsRoute.name, path: 'accounts');

  static const String name = 'AccountsDetailsRoute';
}

/// generated route for
/// [_i15.SettingsPage]
class SettingsRoute extends _i6.PageRouteInfo<void> {
  const SettingsRoute() : super(SettingsRoute.name, path: 'settings');

  static const String name = 'SettingsRoute';
}

/// generated route for
/// [_i16.MatrixChatPage]
class MatrixChatRoute extends _i6.PageRouteInfo<MatrixChatRouteArgs> {
  MatrixChatRoute(
      {_i17.Key? key,
      required String roomId,
      required _i18.Client client,
      void Function()? onBack})
      : super(MatrixChatRoute.name,
            path: ':roomId',
            args: MatrixChatRouteArgs(
                key: key, roomId: roomId, client: client, onBack: onBack));

  static const String name = 'MatrixChatRoute';
}

class MatrixChatRouteArgs {
  const MatrixChatRouteArgs(
      {this.key, required this.roomId, required this.client, this.onBack});

  final _i17.Key? key;

  final String roomId;

  final _i18.Client client;

  final void Function()? onBack;

  @override
  String toString() {
    return 'MatrixChatRouteArgs{key: $key, roomId: $roomId, client: $client, onBack: $onBack}';
  }
}
