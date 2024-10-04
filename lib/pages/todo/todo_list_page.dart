import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:piaf/pages/todo/todo_room_page.dart';
import 'package:piaf/partials/utils/extensions/matrix/room_extension.dart';
import 'package:piaf/router.gr.dart';

import '../../config/matrix_types.dart';
import '../../partials/utils/matrix_widget.dart';

@RoutePage()
class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  void createNewTodoRoom() async {
    await context.pushRoute(TodoListAddRoute());
  }

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    return Scaffold(
        appBar: AppBar(
          title: Text("Todo"),
          actions: [
            IconButton(onPressed: createNewTodoRoom, icon: Icon(Icons.add))
          ],
        ),
        body: StreamBuilder<Object>(
            stream: client.onSync.stream,
            builder: (context, snapshot) {
              final rooms = client.rooms
                  .where((room) => room.type == MatrixRoomTypes.todo)
                  .toList();

              return ListView.builder(
                itemBuilder: (BuildContext context, int i) {
                  final room = rooms[i];
                  return ListTile(
                    title: Text(room.getLocalizedDisplayname()),
                    subtitle: Text(room.topic),
                    trailing: Icon(Icons.navigate_next),
                    onTap: () async {
                      await context.pushRoute(TodoRoomRoute(room: room));
                    },
                  );
                },
                itemCount: rooms.length,
              );
            }));
  }
}
