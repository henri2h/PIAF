import 'package:flutter/material.dart';

class CustomDialogs {
  static Future<String?> showCustomTextDialog(BuildContext context,
      {String title = "",
      String helpText = "",
      String? initialText,
      int? maxLines}) async {
    initialText ??= "";

    return await showDialog<String>(
        context: context,
        builder: (context) {
          TextEditingController c = TextEditingController(text: initialText);
          return Dialog(
              child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                TextField(
                  controller: c,
                  maxLines: maxLines,
                  minLines: maxLines != null ? 3 : null,
                  cursorColor: Colors.grey,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 12),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(
                        Radius.circular(15),
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(
                        Radius.circular(15),
                      ),
                    ),
                    prefixIcon: const Icon(Icons.edit, color: Colors.grey),
                    filled: true,
                    hintStyle: const TextStyle(color: Colors.grey),
                    labelText: helpText,
                    labelStyle: const TextStyle(color: Colors.grey),
                    alignLabelWithHint: true,
                    //  hintText: "Post content",
                  ),
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        child: const Text("Cancel"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        }),
                    TextButton(
                        child: const Text("Save"),
                        onPressed: () {
                          Navigator.of(context).pop(c.text);
                        }),
                  ],
                ),
              ],
            ),
          ));
        });
  }
}
