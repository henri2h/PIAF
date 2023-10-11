import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:ui' as ui;

class DeviceMediaGallery extends StatefulWidget {
  const DeviceMediaGallery({super.key});

  @override
  State<DeviceMediaGallery> createState() => _DeviceMediaGalleryState();
}

class _DeviceMediaGalleryState extends State<DeviceMediaGallery> {
  final scrollController = ScrollController();
  Future<List<AssetPathEntity>?> queryPermissions() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      // Granted.
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList();

      await loadMoreImages();

      return paths;
    } else {
      // Limited(iOS) or Rejected, use `==` for more precise judgements.
      // You can call `PhotoManager.openSetting()` to open settings for further steps.
      print("Could not get images");
      await PhotoManager.openSetting();
    }
    return null;
  }

  Future<List<AssetPathEntity>?>? futureMedia;
  int initPos = 0;
  List<AssetEntity> _entities = [];
  bool multiSelection = false;

  Future<void> loadMoreImages() async {
    final itemCount = await PhotoManager.getAssetCount();
    if (_entities.length != itemCount) {
      final List<AssetEntity> entities =
          await PhotoManager.getAssetListPaged(page: initPos, pageCount: 80);
      if (initPos == 0) {
        _entities = entities;
      } else {
        _entities.addAll(entities);
      }

      initPos++;
    }
  }

  Future<void> load() async {
    try {
      await loadMoreImages();
      setState(() {});
    } catch (_) {}
    _load = null;
  }

  Future<void>? _load;

  void scrollListener() {
    if (scrollController.hasClients) {
      final distance = scrollController.position.extentAfter;
      if (distance < 500) {
        _load ??= load();
      }
    }
  }

  @override
  void initState() {
    futureMedia = queryPermissions();
    scrollController.addListener(scrollListener);
    super.initState();
  }

  List<AssetEntity> selectedFiles = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: selectedFiles.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () {},
              icon: const Icon(Icons.check),
              label: const Text("Validate"),
            ),
      appBar: AppBar(
        title: Text(selectedFiles.isEmpty
            ? "Select images"
            : "${selectedFiles.length} files selected"),
        actions: [
          if (multiSelection || selectedFiles.isNotEmpty)
            IconButton(
                onPressed: () async {
                  setState(() {
                    multiSelection = false;
                    selectedFiles.clear();
                  });

                  await HapticFeedback.heavyImpact();
                },
                icon: const Icon(Icons.close))
        ],
      ),
      body: FutureBuilder<List<AssetPathEntity>?>(
          future: futureMedia,
          builder: (context, snapshot) {
            if (snapshot.hasData == false) {
              return const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(
                      width: 16,
                    ),
                    Text("Getting permissions...")
                  ],
                ),
              );
            }

            return GridView.builder(
              controller: scrollController,
              itemCount: _entities.length,
              cacheExtent: 2000,
              itemBuilder: (context, pos) {
                final item = _entities[pos];
                return Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: GestureDetector(
                    onTap: () async {
                      if (multiSelection) {
                        setState(() {
                          if (selectedFiles.contains(item)) {
                            selectedFiles.remove(item);
                          } else {
                            selectedFiles.add(item);
                          }
                        });
                        await HapticFeedback.heavyImpact();
                      }
                    },
                    onLongPress: () async {
                      setState(() {
                        // add item
                        if (!selectedFiles.contains(item)) {
                          selectedFiles.add(item);
                        }
                        multiSelection = true;
                      });

                      await HapticFeedback.heavyImpact();
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AssetEntityImage(
                          item,
                          fit: BoxFit.cover,
                          isOriginal: false, // Defaults to `true`.
                          thumbnailSize: const ThumbnailSize.square(
                              200), // Preferred value.
                          thumbnailFormat:
                              ThumbnailFormat.jpeg, // Defaults to `jpeg`.
                        ),
                        if (selectedFiles.contains(item))
                          ClipRect(
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(
                                sigmaX: 2.0,
                                sigmaY: 2.0,
                              ),
                              child: Container(
                                color: Colors.transparent,
                                child: const Icon(
                                  Icons.check,
                                  size: 50,
                                ),
                              ),
                            ),
                          )
                      ],
                    ),
                  ),
                );
              },
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200),
            );
          }),
    );
  }
}
