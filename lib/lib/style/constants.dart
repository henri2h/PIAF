import 'package:flutter/material.dart';

class Constants {
  static InputDecoration kTextFieldInputDecoration = kBasicSearch.copyWith(
    prefixIcon: const Icon(Icons.search, color: Colors.grey),
    hintText: "Search",
  );

  static const InputDecoration kBasicSearch = InputDecoration(
    isDense: true,
    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
    border: InputBorder.none,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.all(
        Radius.circular(14),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.all(
        Radius.circular(8),
      ),
    ),
    filled: true,
    focusColor: Colors.grey,
    hintStyle: TextStyle(color: Colors.grey),
  );

  static const TextStyle kTextTitleStyle =
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
}
