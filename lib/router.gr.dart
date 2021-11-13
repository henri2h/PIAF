// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i12;
import 'package:flutter/material.dart' as _i13;
import 'package:matrix/matrix.dart' as _i15;
import 'package:minestrix_chat/view/matrix_chat_page.dart' as _i8;
import 'package:minestrix_chat/view/matrix_chats_page.dart' as _i7;

import 'components/post/postEditor.dart' as _i6;
import 'pages/loginPage.dart' as _i3;
import 'pages/matrixLoadingPage.dart' as _i1;
import 'pages/minestrix/feedPage.dart' as _i4;
import 'pages/minestrix/friends/researchPage.dart' as _i10;
import 'pages/minestrix/groups/groupPage.dart' as _i5;
import 'pages/minestrix/homeWraperPage.dart' as _i2;
import 'pages/minestrix/userFeedPage.dart' as _i9;
import 'pages/settingsPage.dart' as _i11;
import 'utils/minestrix/minestrixRoom.dart' as _i14;

class AppRouter extends _i12.RootStackRouter {
  AppRouter([_i13.GlobalKey<_i13.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i12.PageFactory> pagesMap = {
    MatrixLoadingRoute.name: (routeData) {
      return _i12.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i1.MatrixLoadingPage());
    },
    HomeWraperRoute.name: (routeData) {
      final args = routeData.argsAs<HomeWraperRouteArgs>(
          orElse: () => const HomeWraperRouteArgs());
      return _i12.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i2.HomeWraperPage(key: args.key, title: args.title));
    },
    LoginRoute.name: (routeData) {
      final args = routeData.argsAs<LoginRouteArgs>(
          orElse: () => const LoginRouteArgs());
      return _i12.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i3.LoginPage(
              key: args.key, title: args.title, onLogin: args.onLogin));
    },
    FeedRoute.name: (routeData) {
      return _i12.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i4.FeedPage());
    },
    GroupRoute.name: (routeData) {
      final args = routeData.argsAs<GroupRouteArgs>(
          orElse: () => const GroupRouteArgs());
      return _i12.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i5.GroupPage(key: args.key, sroom: args.sroom));
    },
    PostEditorRoute.name: (routeData) {
      final args = routeData.argsAs<PostEditorRouteArgs>(
          orElse: () => const PostEditorRouteArgs());
      return _i12.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i6.PostEditorPage(key: args.key, sroom: args.sroom));
    },
    MatrixChatsRoute.name: (routeData) {
      final args = routeData.argsAs<MatrixChatsRouteArgs>();
      return _i12.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i7.MatrixChatsPage(key: args.key, client: args.client));
    },
    MatrixChatRoute.name: (routeData) {
      final args = routeData.argsAs<MatrixChatRouteArgs>();
      return _i12.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i8.MatrixChatPage(
              key: args.key, roomId: args.roomId, client: args.client));
    },
    UserFeedRoute.name: (routeData) {
      final args = routeData.argsAs<UserFeedRouteArgs>();
      return _i12.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i9.UserFeedPage(key: args.key, userId: args.userId));
    },
    ResearchRoute.name: (routeData) {
      return _i12.MaterialPageX<dynamic>(
          routeData: routeData, child: _i10.ResearchPage());
    },
    SettingsRoute.name: (routeData) {
      return _i12.MaterialPageX<dynamic>(
          routeData: routeData, child: _i11.SettingsPage());
    }
  };

  @override
  List<_i12.RouteConfig> get routes => [
        _i12.RouteConfig(MatrixLoadingRoute.name, path: '/matrix-loading-page'),
        _i12.RouteConfig(HomeWraperRoute.name, path: '/', children: [
          _i12.RouteConfig(FeedRoute.name,
              path: '', parent: HomeWraperRoute.name),
          _i12.RouteConfig(GroupRoute.name,
              path: 'group', parent: HomeWraperRoute.name),
          _i12.RouteConfig(PostEditorRoute.name,
              path: 'createPost', parent: HomeWraperRoute.name),
          _i12.RouteConfig(MatrixChatsRoute.name,
              path: 'chats', parent: HomeWraperRoute.name),
          _i12.RouteConfig(MatrixChatRoute.name,
              path: 'chat/:roomId', parent: HomeWraperRoute.name),
          _i12.RouteConfig(UserFeedRoute.name,
              path: 'user/feed/:userId', parent: HomeWraperRoute.name),
          _i12.RouteConfig(ResearchRoute.name,
              path: 'search', parent: HomeWraperRoute.name),
          _i12.RouteConfig(SettingsRoute.name,
              path: 'settings', parent: HomeWraperRoute.name),
          _i12.RouteConfig('*#redirect',
              path: '*',
              parent: HomeWraperRoute.name,
              redirectTo: '',
              fullMatch: true)
        ]),
        _i12.RouteConfig(LoginRoute.name, path: '/login')
      ];
}

/// generated route for [_i1.MatrixLoadingPage]
class MatrixLoadingRoute extends _i12.PageRouteInfo<void> {
  const MatrixLoadingRoute() : super(name, path: '/matrix-loading-page');

  static const String name = 'MatrixLoadingRoute';
}

/// generated route for [_i2.HomeWraperPage]
class HomeWraperRoute extends _i12.PageRouteInfo<HomeWraperRouteArgs> {
  HomeWraperRoute(
      {_i13.Key? key, String? title, List<_i12.PageRouteInfo>? children})
      : super(name,
            path: '/',
            args: HomeWraperRouteArgs(key: key, title: title),
            initialChildren: children);

  static const String name = 'HomeWraperRoute';
}

class HomeWraperRouteArgs {
  const HomeWraperRouteArgs({this.key, this.title});

  final _i13.Key? key;

  final String? title;

  @override
  String toString() {
    return 'HomeWraperRouteArgs{key: $key, title: $title}';
  }
}

/// generated route for [_i3.LoginPage]
class LoginRoute extends _i12.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({_i13.Key? key, String? title, dynamic Function(bool)? onLogin})
      : super(name,
            path: '/login',
            args: LoginRouteArgs(key: key, title: title, onLogin: onLogin));

  static const String name = 'LoginRoute';
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.title, this.onLogin});

  final _i13.Key? key;

  final String? title;

  final dynamic Function(bool)? onLogin;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, title: $title, onLogin: $onLogin}';
  }
}

/// generated route for [_i4.FeedPage]
class FeedRoute extends _i12.PageRouteInfo<void> {
  const FeedRoute() : super(name, path: '');

  static const String name = 'FeedRoute';
}

/// generated route for [_i5.GroupPage]
class GroupRoute extends _i12.PageRouteInfo<GroupRouteArgs> {
  GroupRoute({_i13.Key? key, _i14.MinestrixRoom? sroom})
      : super(name,
            path: 'group', args: GroupRouteArgs(key: key, sroom: sroom));

  static const String name = 'GroupRoute';
}

class GroupRouteArgs {
  const GroupRouteArgs({this.key, this.sroom});

  final _i13.Key? key;

  final _i14.MinestrixRoom? sroom;

  @override
  String toString() {
    return 'GroupRouteArgs{key: $key, sroom: $sroom}';
  }
}

/// generated route for [_i6.PostEditorPage]
class PostEditorRoute extends _i12.PageRouteInfo<PostEditorRouteArgs> {
  PostEditorRoute({_i13.Key? key, _i14.MinestrixRoom? sroom})
      : super(name,
            path: 'createPost',
            args: PostEditorRouteArgs(key: key, sroom: sroom));

  static const String name = 'PostEditorRoute';
}

class PostEditorRouteArgs {
  const PostEditorRouteArgs({this.key, this.sroom});

  final _i13.Key? key;

  final _i14.MinestrixRoom? sroom;

  @override
  String toString() {
    return 'PostEditorRouteArgs{key: $key, sroom: $sroom}';
  }
}

/// generated route for [_i7.MatrixChatsPage]
class MatrixChatsRoute extends _i12.PageRouteInfo<MatrixChatsRouteArgs> {
  MatrixChatsRoute({_i13.Key? key, required _i15.Client client})
      : super(name,
            path: 'chats',
            args: MatrixChatsRouteArgs(key: key, client: client));

  static const String name = 'MatrixChatsRoute';
}

class MatrixChatsRouteArgs {
  const MatrixChatsRouteArgs({this.key, required this.client});

  final _i13.Key? key;

  final _i15.Client client;

  @override
  String toString() {
    return 'MatrixChatsRouteArgs{key: $key, client: $client}';
  }
}

/// generated route for [_i8.MatrixChatPage]
class MatrixChatRoute extends _i12.PageRouteInfo<MatrixChatRouteArgs> {
  MatrixChatRoute(
      {_i13.Key? key, required String roomId, required _i15.Client client})
      : super(name,
            path: 'chat/:roomId',
            args:
                MatrixChatRouteArgs(key: key, roomId: roomId, client: client));

  static const String name = 'MatrixChatRoute';
}

class MatrixChatRouteArgs {
  const MatrixChatRouteArgs(
      {this.key, required this.roomId, required this.client});

  final _i13.Key? key;

  final String roomId;

  final _i15.Client client;

  @override
  String toString() {
    return 'MatrixChatRouteArgs{key: $key, roomId: $roomId, client: $client}';
  }
}

/// generated route for [_i9.UserFeedPage]
class UserFeedRoute extends _i12.PageRouteInfo<UserFeedRouteArgs> {
  UserFeedRoute({_i13.Key? key, required String? userId})
      : super(name,
            path: 'user/feed/:userId',
            args: UserFeedRouteArgs(key: key, userId: userId));

  static const String name = 'UserFeedRoute';
}

class UserFeedRouteArgs {
  const UserFeedRouteArgs({this.key, required this.userId});

  final _i13.Key? key;

  final String? userId;

  @override
  String toString() {
    return 'UserFeedRouteArgs{key: $key, userId: $userId}';
  }
}

/// generated route for [_i10.ResearchPage]
class ResearchRoute extends _i12.PageRouteInfo<void> {
  const ResearchRoute() : super(name, path: 'search');

  static const String name = 'ResearchRoute';
}

/// generated route for [_i11.SettingsPage]
class SettingsRoute extends _i12.PageRouteInfo<void> {
  const SettingsRoute() : super(name, path: 'settings');

  static const String name = 'SettingsRoute';
}
