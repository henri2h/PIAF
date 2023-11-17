import 'package:flutter/material.dart';

import '../providers/item_manager.dart';

class SearchSystem<T> extends StatefulWidget {
  const SearchSystem({super.key, required this.manager});
  final ItemManager<T> manager;
  @override
  State<SearchSystem> createState() => _SearchSystemState();
}

class _SearchSystemState extends State<SearchSystem> {
  final controller = ScrollController();
  Future<bool>? getItems;

  @override
  void initState() {
    super.initState();
    getItems = widget.manager.requestMore();
    controller.addListener(onScroll);
  }

  Future<bool> requestMore() async {
    await widget.manager.requestMore();
    getItems = null;
    return true;
  }

  void onScroll() {
    if (controller.position.hasContentDimensions) {
      if (controller.position.extentAfter < 400) {
        if (getItems == null) {
          getItems ??= requestMore();
          setState(() {});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: getItems,
        builder: (context, snapshot) {
          if (snapshot.hasData && widget.manager.items.isEmpty) {
            return ListTile(
              leading: const Icon(Icons.not_listed_location, size: 40),
              title: Text("No profile found",
                  style: Theme.of(context).textTheme.titleLarge),
              subtitle: Text(
                "All published profiles will be displayed here",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          if (!snapshot.hasData) return const CircularProgressIndicator();

          return ListView.builder(
            itemCount: widget.manager.items.length,
            itemBuilder: (BuildContext context, int i) =>
                widget.manager.itemBuilder(context, widget.manager.items[i]),
          );
        });
  }
}
