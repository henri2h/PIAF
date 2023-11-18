import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'provider/chat_page_state.dart';
import '../space_page.dart';

class ChatPageSpacePage extends StatelessWidget {
  const ChatPageSpacePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ChatPageState>(
        builder: (context, controller, _) =>
            !controller.selectedSpace.startsWith("!")
                ? Text("No room selected ${controller.selectedSpace}")
                : SpacePage(
                    key: Key("space_${controller.selectedSpace}"),
                    spaceId: controller.selectedSpace,
                    client: controller.client,
                    onBack: () {
                      controller.selectRoom(null);
                      Navigator.of(context).pop();
                    },
                  ));
  }
}
