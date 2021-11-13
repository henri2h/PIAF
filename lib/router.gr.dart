// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i14;
import 'package:flutter/material.dart' as _i15;
import 'package:matrix/matrix.dart' as _i17;
import 'package:minestrix_chat/view/matrix_chat_page.dart' as _i9;
import 'package:minestrix_chat/view/matrix_chats_page.dart' as _i8;

import 'components/post/postEditor.dart' as _i7;
import 'pages/loginPage.dart' as _i3;
import 'pages/matrixLoadingPage.dart' as _i1;
import 'pages/minestrix/feedPage.dart' as _i4;
import 'pages/minestrix/friends/friendsVue.dart' as _i6;
import 'pages/minestrix/friends/researchPage.dart' as _i12;
import 'pages/minestrix/groups/groupPage.dart' as _i5;
import 'pages/minestrix/homeWraperPage.dart' as _i2;
import 'pages/minestrix/user/userFeedPage.dart' as _i10;
import 'pages/minestrix/user/userFriendsPage.dart' as _i11;
import 'pages/settingsPage.dart' as _i13;
import 'utils/minestrix/minestrixRoom.dart' as _i16;

class AppRouter extends _i14.RootStackRouter {
  AppRouter([_i15.GlobalKey<_i15.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i14.PageFactory> pagesMap = {
    MatrixLoadingRoute.name: (routeData) {
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i1.MatrixLoadingPage());
    },
    HomeWraperRoute.name: (routeData) {
      final args = routeData.argsAs<HomeWraperRouteArgs>(
          orElse: () => const HomeWraperRouteArgs());
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i2.HomeWraperPage(key: args.key, title: args.title));
    },
    LoginRoute.name: (routeData) {
      final args = routeData.argsAs<LoginRouteArgs>(
          orElse: () => const LoginRouteArgs());
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i3.LoginPage(
              key: args.key, title: args.title, onLogin: args.onLogin));
    },
    FeedRoute.name: (routeData) {
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i4.FeedPage());
    },
    GroupRoute.name: (routeData) {
      final args = routeData.argsAs<GroupRouteArgs>(
          orElse: () => const GroupRouteArgs());
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i5.GroupPage(key: args.key, sroom: args.sroom));
    },
    FriendsRoute.name: (routeData) {
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData, child: _i6.FriendsPage());
    },
    PostEditorRoute.name: (routeData) {
      final args = routeData.argsAs<PostEditorRouteArgs>(
          orElse: () => const PostEditorRouteArgs());
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i7.PostEditorPage(key: args.key, sroom: args.sroom));
    },
    MatrixChatsRoute.name: (routeData) {
      final args = routeData.argsAs<MatrixChatsRouteArgs>();
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i8.MatrixChatsPage(key: args.key, client: args.client));
    },
    MatrixChatRoute.name: (routeData) {
      final args = routeData.argsAs<MatrixChatRouteArgs>();
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i9.MatrixChatPage(
              key: args.key, roomId: args.roomId, client: args.client));
    },
    UserFeedRoute.name: (routeData) {
      final args = routeData.argsAs<UserFeedRouteArgs>();
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i10.UserFeedPage(key: args.key, userId: args.userId));
    },
    UserFriendsRoute.name: (routeData) {
      final args = routeData.argsAs<UserFriendsRouteArgs>();
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i11.UserFriendsPage(key: args.key, sroom: args.sroom));
    },
    ResearchRoute.name: (routeData) {
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData, child: _i12.ResearchPage());
    },
    SettingsRoute.name: (routeData) {
      return _i14.MaterialPageX<dynamic>(
          routeData: routeData, child: _i13.SettingsPage());
    }
  };

  @override
  List<_i14.RouteConfig> get routes => [
        _i14.RouteConfig(MatrixLoadingRoute.name, path: '/matrix-loading-page'),
        _i14.RouteConfig(HomeWraperRoute.name, path: '/', children: [
          _i14.RouteConfig(FeedRoute.name,
              path: '', parent: HomeWraperRoute.name),
          _i14.RouteConfig(GroupRoute.name,
              path: 'group', parent: HomeWraperRoute.name),
          _i14.RouteConfig(FriendsRoute.name,
              path: 'friends', parent: HomeWraperRoute.name),
          _i14.RouteConfig(PostEditorRoute.name,
              path: 'createPost', parent: HomeWraperRoute.name),
          _i14.RouteConfig(MatrixChatsRoute.name,
              path: 'chats', parent: HomeWraperRoute.name),
          _i14.RouteConfig(MatrixChatRoute.name,
              path: 'chat/:roomId', parent: HomeWraperRoute.name),
          _i14.RouteConfig(UserFeedRoute.name,
              path: 'user/feed/:userId', parent: HomeWraperRoute.name),
          _i14.RouteConfig(UserFriendsRoute.name,
              path: 'user/friends/', parent: HomeWraperRoute.name),
          _i14.RouteConfig(ResearchRoute.name,
              path: 'search', parent: HomeWraperRoute.name),
          _i14.RouteConfig(SettingsRoute.name,
              path: 'settings', parent: HomeWraperRoute.name),
          _i14.RouteConfig('*#redirect',
              path: '*',
              parent: HomeWraperRoute.name,
              redirectTo: '',
              fullMatch: true)
        ]),
        _i14.RouteConfig(LoginRoute.name, path: '/login')
      ];
}

/// generated route for [_i1.MatrixLoadingPage]
class MatrixLoadingRoute extends _i14.PageRouteInfo<void> {
  const MatrixLoadingRoute() : super(name, path: '/matrix-loading-page');

  static const String name = 'MatrixLoadingRoute';
}

/// generated route for [_i2.HomeWraperPage]
class HomeWraperRoute extends _i14.PageRouteInfo<HomeWraperRouteArgs> {
  HomeWraperRoute(
      {_i15.Key? key, String? title, List<_i14.PageRouteInfo>? children})
      : super(name,
            path: '/',
            args: HomeWraperRouteArgs(key: key, title: title),
            initialChildren: children);

  static const String name = 'HomeWraperRoute';
}

class HomeWraperRouteArgs {
  const HomeWraperRouteArgs({this.key, this.title});

  final _i15.Key? key;

  final String? title;

  @override
  String toString() {
    return 'HomeWraperRouteArgs{key: $key, title: $title}';
  }
}

/// generated route for [_i3.LoginPage]
class LoginRoute extends _i14.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({_i15.Key? key, String? title, dynamic Function(bool)? onLogin})
      : super(name,
            path: '/login',
            args: LoginRouteArgs(key: key, title: title, onLogin: onLogin));

  static const String name = 'LoginRoute';
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.title, this.onLogin});

  final _i15.Key? key;

  final String? title;

  final dynamic Function(bool)? onLogin;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, title: $title, onLogin: $onLogin}';
  }
}

/// generated route for [_i4.FeedPage]
class FeedRoute extends _i14.PageRouteInfo<void> {
  const FeedRoute() : super(name, path: '');

  static const String name = 'FeedRoute';
}

/// generated route for [_i5.GroupPage]
class GroupRoute extends _i14.PageRouteInfo<GroupRouteArgs> {
  GroupRoute({_i15.Key? key, _i16.MinestrixRoom? sroom})
      : super(name,
            path: 'group', args: GroupRouteArgs(key: key, sroom: sroom));

  static const String name = 'GroupRoute';
}

class GroupRouteArgs {
  const GroupRouteArgs({this.key, this.sroom});

  final _i15.Key? key;

  final _i16.MinestrixRoom? sroom;

  @override
  String toString() {
    return 'GroupRouteArgs{key: $key, sroom: $sroom}';
  }
}

/// generated route for [_i6.FriendsPage]
class FriendsRoute extends _i14.PageRouteInfo<void> {
  const FriendsRoute() : super(name, path: 'friends');

  static const String name = 'FriendsRoute';
}

/// generated route for [_i7.PostEditorPage]
class PostEditorRoute extends _i14.PageRouteInfo<PostEditorRouteArgs> {
  PostEditorRoute({_i15.Key? key, _i16.MinestrixRoom? sroom})
      : super(name,
            path: 'createPost',
            args: PostEditorRouteArgs(key: key, sroom: sroom));

  static const String name = 'PostEditorRoute';
}

class PostEditorRouteArgs {
  const PostEditorRouteArgs({this.key, this.sroom});

  final _i15.Key? key;

  final _i16.MinestrixRoom? sroom;

  @override
  String toString() {
    return 'PostEditorRouteArgs{key: $key, sroom: $sroom}';
  }
}

/// generated route for [_i8.MatrixChatsPage]
class MatrixChatsRoute extends _i14.PageRouteInfo<MatrixChatsRouteArgs> {
  MatrixChatsRoute({_i15.Key? key, required _i17.Client client})
      : super(name,
            path: 'chats',
            args: MatrixChatsRouteArgs(key: key, client: client));

  static const String name = 'MatrixChatsRoute';
}

class MatrixChatsRouteArgs {
  const MatrixChatsRouteArgs({this.key, required this.client});

  final _i15.Key? key;

  final _i17.Client client;

  @override
  String toString() {
    return 'MatrixChatsRouteArgs{key: $key, client: $client}';
  }
}

/// generated route for [_i9.MatrixChatPage]
class MatrixChatRoute extends _i14.PageRouteInfo<MatrixChatRouteArgs> {
  MatrixChatRoute(
      {_i15.Key? key, required String roomId, required _i17.Client client})
      : super(name,
            path: 'chat/:roomId',
            args:
                MatrixChatRouteArgs(key: key, roomId: roomId, client: client));

  static const String name = 'MatrixChatRoute';
}

class MatrixChatRouteArgs {
  const MatrixChatRouteArgs(
      {this.key, required this.roomId, required this.client});

  final _i15.Key? key;

  final String roomId;

  final _i17.Client client;

  @override
  String toString() {
    return 'MatrixChatRouteArgs{key: $key, roomId: $roomId, client: $client}';
  }
}

/// generated route for [_i10.UserFeedPage]
class UserFeedRoute extends _i14.PageRouteInfo<UserFeedRouteArgs> {
  UserFeedRoute({_i15.Key? key, required String? userId})
      : super(name,
            path: 'user/feed/:userId',
            args: UserFeedRouteArgs(key: key, userId: userId));

  static const String name = 'UserFeedRoute';
}

class UserFeedRouteArgs {
  const UserFeedRouteArgs({this.key, required this.userId});

  final _i15.Key? key;

  final String? userId;

  @override
  String toString() {
    return 'UserFeedRouteArgs{key: $key, userId: $userId}';
  }
}

/// generated route for [_i11.UserFriendsPage]
class UserFriendsRoute extends _i14.PageRouteInfo<UserFriendsRouteArgs> {
  UserFriendsRoute({_i15.Key? key, required _i16.MinestrixRoom sroom})
      : super(name,
            path: 'user/friends/',
            args: UserFriendsRouteArgs(key: key, sroom: sroom));

  static const String name = 'UserFriendsRoute';
}

class UserFriendsRouteArgs {
  const UserFriendsRouteArgs({this.key, required this.sroom});

  final _i15.Key? key;

  final _i16.MinestrixRoom sroom;

  @override
  String toString() {
    return 'UserFriendsRouteArgs{key: $key, sroom: $sroom}';
  }
}

/// generated route for [_i12.ResearchPage]
class ResearchRoute extends _i14.PageRouteInfo<void> {
  const ResearchRoute() : super(name, path: 'search');

  static const String name = 'ResearchRoute';
}

/// generated route for [_i13.SettingsPage]
class SettingsRoute extends _i14.PageRouteInfo<void> {
  const SettingsRoute() : super(name, path: 'settings');

  static const String name = 'SettingsRoute';
}
