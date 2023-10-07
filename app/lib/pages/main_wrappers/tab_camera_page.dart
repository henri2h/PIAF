import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

@RoutePage()
class TabCameraPage extends StatefulWidget {
  const TabCameraPage({super.key});

  @override
  State<TabCameraPage> createState() => _TabCameraPageState();
}

class _TabCameraPageState extends State<TabCameraPage>
    with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }

  void onNewCameraSelected(CameraDescription? cameraDescription) async {
    if (cameraDescription == null) return;

    final previousCameraController = controller;
    // Instantiating the camera controller
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Dispose the previous controller
    await previousCameraController?.dispose();

    // Replace with the new controller
    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    // Initialize controller
    controller?.initialize().then((_) {
      controller?.getMaxZoomLevel().then((value) => setState(() {
            _maxAvailableZoom = value;
            if (value < _currentZoomLevel) _currentZoomLevel = value;
          }));
      controller?.getMinZoomLevel().then((value) => setState(() {
            _minAvailableZoom = value;
            if (value > _currentZoomLevel) _currentZoomLevel = value;
          }));
      _currentFlashMode = controller?.value.flashMode;
      if (!mounted) {
        return;
      }
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  bool _isCameraInitialized = false;
  List<CameraDescription>? _cameras;
  CameraController? controller;

  @override
  void initState() {
    _init();
    super.initState();
  }

// Variable set in onNewCamera
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentZoomLevel = 1.0;

  FlashMode? _currentFlashMode;

  bool _isRearCameraSelected = false;

  Future<void> _init() async {
    _cameras = await availableCameras();
    controller = CameraController(_cameras![0], ResolutionPreset.max);
    onNewCameraSelected(controller!.description);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;
    if (cameraController!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }
    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      print('Error occured while taking picture: $e');
      return null;
    }
  }

  void switchCamera() {
    setState(() {
      _isCameraInitialized = false;
    });
    onNewCameraSelected(
      _cameras?[_isRearCameraSelected ? 0 : 1],
    );
    setState(() {
      _isRearCameraSelected = !_isRearCameraSelected;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) return Container();
    return Center(
      child: GestureDetector(
        onDoubleTap: switchCamera,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 1 / controller!.value.aspectRatio,
            child: CameraPreview(
              controller!,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SafeArea(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () async {
                                setState(() {
                                  _currentFlashMode = FlashMode.off;
                                });
                                await controller!.setFlashMode(
                                  FlashMode.off,
                                );
                              },
                              child: Icon(
                                Icons.flash_off,
                                color: _currentFlashMode == FlashMode.off
                                    ? Colors.amber
                                    : Colors.white,
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                setState(() {
                                  _currentFlashMode = FlashMode.auto;
                                });
                                await controller!.setFlashMode(
                                  FlashMode.auto,
                                );
                              },
                              child: Icon(
                                Icons.flash_auto,
                                color: _currentFlashMode == FlashMode.auto
                                    ? Colors.amber
                                    : Colors.white,
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                setState(() {
                                  _currentFlashMode = FlashMode.always;
                                });
                                await controller!.setFlashMode(
                                  FlashMode.always,
                                );
                              },
                              child: Icon(
                                Icons.flash_on,
                                color: _currentFlashMode == FlashMode.always
                                    ? Colors.amber
                                    : Colors.white,
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                setState(() {
                                  _currentFlashMode = FlashMode.torch;
                                });
                                await controller!.setFlashMode(
                                  FlashMode.torch,
                                );
                              },
                              child: Icon(
                                Icons.highlight,
                                color: _currentFlashMode == FlashMode.torch
                                    ? Colors.amber
                                    : Colors.white,
                              ),
                            ),
                            InkWell(
                              onTap: switchCamera,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    color: Colors.black38,
                                    size: 60,
                                  ),
                                  Icon(
                                    _isRearCameraSelected
                                        ? Icons.camera_front
                                        : Icons.camera_rear,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_isCameraInitialized)
                    Row(children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Slider(
                            value: _currentZoomLevel,
                            min: _minAvailableZoom,
                            max: _maxAvailableZoom,
                            activeColor: Colors.white,
                            inactiveColor: Colors.white30,
                            onChanged: (value) async {
                              setState(() {
                                _currentZoomLevel = value;
                              });
                              await controller?.setZoomLevel(value);
                            },
                          ),
                        ),
                      ),
                    ]),
                  InkWell(
                    onTap: () async {
                      XFile? rawImage = await takePicture();
                      File imageFile = File(rawImage!.path);

                      int currentUnix = DateTime.now().millisecondsSinceEpoch;
                      final directory =
                          await getApplicationDocumentsDirectory();
                      String fileFormat = imageFile.path.split('.').last;

                      await imageFile.copy(
                        '${directory.path}/$currentUnix.$fileFormat',
                      );
                    },
                    child: const Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.circle, color: Colors.white38, size: 80),
                        Icon(Icons.circle, color: Colors.white, size: 65),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
