import 'package:flutter/widgets.dart';

abstract class ItemManager<T> {
  // bool searching = false;
  List<T> items = [];
  Future<bool> requestMore();
  Widget itemBuilder(BuildContext context, T item);
  Future<void> setNewTerm(String text);

  void init(BuildContext context);
}
