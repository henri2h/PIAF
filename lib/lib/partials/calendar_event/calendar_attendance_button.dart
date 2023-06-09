import 'package:flutter/material.dart';

class CalendarAttendanceCardButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final String userResponse;
  final Map<String, int> resp;
  final String value;
  final Future<void> Function(String? value) check;

  const CalendarAttendanceCardButton(
      {Key? key,
      required this.title,
      required this.icon,
      required this.userResponse,
      required this.resp,
      required this.value,
      required this.check})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool checked = userResponse == value;
    int participantsCount = resp[value] ?? 0;

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: MaterialButton(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: checked
                  ? const BorderSide(color: Colors.green, width: 1.8)
                  : BorderSide.none),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(icon, color: checked ? Colors.green : null),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    Text(
                        "$participantsCount personne${participantsCount != 1 ? "s" : ""}",
                        style: Theme.of(context).textTheme.caption)
                  ],
                ),
              ],
            ),
          ),
          onPressed: () async {
            await check(checked == false ? value : null);
          }),
    );
  }
}
