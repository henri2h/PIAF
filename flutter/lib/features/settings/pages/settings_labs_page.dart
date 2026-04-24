import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:piaf/partials/layouts/custom_header.dart';

import '../../../utils/settings.dart';

@RoutePage()
class SettingsLabsPage extends StatefulWidget {
  const SettingsLabsPage({super.key});

  @override
  State<SettingsLabsPage> createState() => _SettingsLabsPageState();
}

class _SettingsLabsPageState extends State<SettingsLabsPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: [
          const CustomHeader(title: "Labs"),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Experimental features, use with caution!"),
          ),
          SwitchListTile(
              value: Settings().multipleFeedSupport,
              onChanged: (value) {
                Settings().multipleFeedSupport = value;
                setState(() {});
              },
              secondary: const Icon(Icons.people),
              title: const Text("Allow creating multiple feeds"),
              subtitle: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "Want to share post with a subset of you friends ? Then multiple feed support is the solution."),
                  InfoBadge(text: "WIP"),
                  InfoBadge(color: Colors.blue, text: "UI")
                ],
              )),
          const SizedBox(height: 8),
          SwitchListTile(
              value: Settings().optimizedFeed,
              onChanged: (value) {
                Settings().optimizedFeed = value;
                setState(() {});
              },
              secondary: const Icon(Icons.list),
              title: const Text("Optimized feed"),
              subtitle: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Restart to reload the feed correctly"),
                  InfoBadge(text: "WIP"),
                  InfoBadge(text: "Need restart", color: Colors.orange),
                ],
              ))
        ],
      ),
    );
  }
}

class InfoBadge extends StatelessWidget {
  const InfoBadge({super.key, required this.text, this.color = Colors.red});

  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
