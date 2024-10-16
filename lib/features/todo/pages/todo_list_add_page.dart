import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:piaf/config/matrix_types.dart';

import '../../../partials/style/constants.dart';
import '../../../utils/matrix_widget.dart';

@RoutePage()
class TodoListAddPage extends StatefulWidget {
  const TodoListAddPage({super.key});

  @override
  State<TodoListAddPage> createState() => _TodoListAddPageState();
}

class _TodoListAddPageState extends State<TodoListAddPage> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.addListener(onEdit);
  }

  @override
  void dispose() {
    nameController.removeListener(onEdit);
    super.dispose();
  }

  void onEdit() {
    setState(() {});
  }

  void createRoom() async {
    final client = Matrix.of(context).client;
    await client.createRoom(
        creationContent: {"type": MatrixRoomTypes.todo},
        name: nameController.text,
        topic: descriptionController.text);
    if (mounted) {
      await context.maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add todo list"),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                    controller: nameController,
                    decoration: Constants.kTextFieldInputDecoration.copyWith(
                        prefixIcon: Icon(Icons.title), hintText: "Title")),
                SizedBox(height: 8),
                TextField(
                    controller: descriptionController,
                    decoration: Constants.kTextFieldInputDecoration.copyWith(
                        prefixIcon: Icon(Icons.description),
                        hintText: "Description")),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton(
                onPressed: nameController.text.isNotEmpty ? createRoom : null,
                child: Text("Create")),
          )
        ],
      ),
    );
  }
}
