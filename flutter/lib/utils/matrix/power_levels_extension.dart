import 'package:matrix/matrix.dart';

extension PowerLevelsExtension on Room {
  Future<void> setPowerLevels(Map<String, dynamic> permissions) async {
// override default powerLevelState
    Map<String, dynamic> powerLevelState =
        await client.getRoomStateWithKey(id, EventTypes.RoomPowerLevels, "");
    powerLevelState.addAll(permissions);

    client.setRoomStateWithKey(id, "m.room.power_levels", "", powerLevelState);
  }
}
