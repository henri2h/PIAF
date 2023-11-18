import 'package:flutter/material.dart';

enum SearchMode {
  user(text: "User pages", icon: Icons.account_circle),
  publicRoom(text: "Public pages", icon: Icons.public);

  const SearchMode({required this.text, required this.icon});

  final IconData icon;
  final String text;
}
