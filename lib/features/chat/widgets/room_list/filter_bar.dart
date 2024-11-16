import 'package:flutter/material.dart';

import '../chat_page_items/provider/chat_page_state.dart';
import '../spaces/list/spaces_list.dart';

// A horizontal bar list to filter specific categories of rooms.
// This is used to filter the room list
class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.roomListSelectorHeight,
    required this.controller,
  });

  final ChatPageState controller;
  final double roomListSelectorHeight;

  @override
  Widget build(BuildContext context) {
    return SliverFixedExtentList.builder(
      itemExtent: roomListSelectorHeight,
      itemBuilder: (BuildContext context, int i) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                CustomFilter(
                  controller: controller,
                  name: "All",
                  spaceName: CustomSpacesTypes.home,
                ),
                CustomFilter(
                  controller: controller,
                  spaceName: CustomSpacesTypes.unread,
                ),
                CustomFilter(
                  controller: controller,
                  spaceName: CustomSpacesTypes.favorites,
                ),
                CustomFilter(
                  controller: controller,
                  spaceName: CustomSpacesTypes.todo,
                ),
                CustomFilter(
                  controller: controller,
                  spaceName: CustomSpacesTypes.dm,
                ),
                CustomFilter(
                  controller: controller,
                  spaceName: CustomSpacesTypes.lowPriority,
                ),
              ],
            ),
          ),
        ),
      ),
      itemCount: 1,
    );
  }
}

class CustomFilter extends StatelessWidget {
  const CustomFilter({
    super.key,
    required this.controller,
    this.name,
    required this.spaceName,
  });

  final ChatPageState controller;
  final String? name;
  final String spaceName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        label: Text(name ?? spaceName),
        selected: controller.selectedSpace == spaceName,
        onSelected: (bool value) {
          controller.selectSpace(spaceName);
        },
      ),
    );
  }
}
