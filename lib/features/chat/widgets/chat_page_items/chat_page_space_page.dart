import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'provider/chat_page_state.dart';
import '../../pages/space_page.dart';

@RoutePage()
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
                    onBack: () {
                      controller.selectRoom(null);
                      Navigator.of(context).pop();
                    },
                  ));
  }
}
