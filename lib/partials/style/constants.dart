import 'package:flutter/material.dart';

class Constants {
  static InputDecoration kTextFieldInputDecoration = kBasicSearch.copyWith(
    prefixIcon: const Icon(Icons.search, color: Colors.grey),
    hintText: "Search",
  );

  static const InputDecoration kBasicSearch = InputDecoration(
    isDense: false,
    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    border: InputBorder.none,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.all(
        Radius.circular(8),
      ),
    ),
    disabledBorder: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.all(
        Radius.circular(8),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.all(
        Radius.circular(8),
      ),
    ),
    filled: true,
  );

  static const TextStyle kTextTitleStyle =
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
}
