import 'package:flutter/material.dart';

class TreeView extends InheritedWidget {
  final List<Widget> children;
  final bool startExpanded;

  TreeView({
    super.key,
    required this.children,
    this.startExpanded = false,
  }) : super(
          child: _TreeViewData(
            children: children,
          ),
        );

  static TreeView? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TreeView>();
  }

  @override
  bool updateShouldNotify(TreeView oldWidget) {
    if (oldWidget.children == children &&
        oldWidget.startExpanded == startExpanded) {
      return false;
    }
    return true;
  }
}

class _TreeViewData extends StatelessWidget {
  final List<Widget>? children;

  const _TreeViewData({
    this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: children!.length,
      itemBuilder: (context, index) {
        return children!.elementAt(index);
      },
    );
  }
}

class TreeViewChild extends StatefulWidget {
  final bool startExpanded;
  final Widget parent;
  final List<Widget> children;

  const TreeViewChild({
    required this.parent,
    required this.children,
    this.startExpanded = false,
    super.key,
  });

  @override
  TreeViewChildState createState() => TreeViewChildState();
}

class TreeViewChildState extends State<TreeViewChild>
    with SingleTickerProviderStateMixin {
  bool? isExpanded;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.startExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: [
            Expanded(child: widget.parent),
            SizedBox(
              width: 36,
              height: 36,
              child: widget.children.isNotEmpty
                  ? IconButton(
                      icon: Icon(isExpanded ?? false
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_left),
                      onPressed: () {
                        toggleExpanded();
                      })
                  : null,
            ),
          ],
        ),
        AnimatedSize(
          curve: Curves.easeIn,
          duration: const Duration(milliseconds: 400),
          child: isExpanded!
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.children,
                )
              : const Offstage(),
        ),
        if (isExpanded ?? false) const SizedBox(height: 12),
      ],
    );
  }

  void toggleExpanded() {
    setState(() {
      isExpanded = !isExpanded!;
    });
  }
}
