import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:newapp_video_player/services/storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CameraItem extends StatefulWidget {
  final List<CameraDescription> _cameras;

  CameraItem(this._cameras);

  @override
  _CameraItemState createState() => _CameraItemState();
}

class _CameraItemState extends State<CameraItem> {
  final CollectionReference videosRef =
      FirebaseFirestore.instance.collection('videos');
  final StorageServices _storageServices = StorageServices();

  CameraController _cameraController;
  VideoPlayerController _videoController;
  VoidCallback videoPlayerListener;
  File chosenFile;
  double progressSize = 85;
  int progressCount = 0;
  int seconderyProgressCount = 0;
  int recordingTime = 0;
  Timer timer;
  bool _inProgress = true;

  @override
  void initState() {
    super.initState();
    onCameraSelect(widget._cameras[0]);
    _cameraController.addListener(() {
      if (_cameraController.value.isRecordingVideo ||
          _cameraController.value.isRecordingPaused && mounted) {
        setState(() {
          progressSize = 95;
        });
        timer = Timer.periodic(
          Duration(milliseconds: 100),
          (timer) {
            if (progressCount >= 9900 && mounted) {
              setState(() {
                progressCount = 0;
                seconderyProgressCount += 100;
                recordingTime = seconderyProgressCount ~/ 1000;
              });
            } else if (mounted) {
              setState(() {
                progressCount += 100;
                seconderyProgressCount += 100;
                recordingTime = seconderyProgressCount ~/ 1000;
              });
            }
          },
        );
      } else if (_cameraController.value.isInitialized &&
          (!_cameraController.value.isRecordingPaused ||
              !_cameraController.value.isRecordingVideo)) {
        setState(() {
          if (timer != null && timer.isActive) timer.cancel();
          progressCount = 0;
          seconderyProgressCount = 0;
          recordingTime = 0;
          progressSize = 85;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (_cameraController != null) _cameraController?.dispose();
    if (_videoController != null) _videoController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _inProgress
        ? Container(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.white,
              ),
            ),
          )
        : Scaffold(
            resizeToAvoidBottomInset: false,
            extendBody: true,
            appBar: buildAppBar(context),
            body: buildBody(context),
            bottomNavigationBar: _captureControlRowWidget(),
          );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      title: Text(
        'Camera',
        style: TextStyle(color: Colors.white),
      ),
      leading: IconButton(
        icon: Icon(Icons.close),
        color: Colors.white,
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      actions: [
        if (_cameraController.value.isRecordingVideo ||
            _cameraController.value.isRecordingPaused)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$recordingTime sec',
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(
                  width: 8,
                ),
                Material(
                  type: MaterialType.circle,
                  color: Colors.red,
                  child: SizedBox(
                    width: 8,
                    height: 8,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget buildBody(BuildContext contect) {
    final Size size = MediaQuery.of(context).size;
    return Container(
      color: Colors.black,
      child: Align(
        alignment: Alignment.center,
        child: chosenFile == null ||
                _cameraController.value.isRecordingVideo ||
                _cameraController.value.isRecordingPaused
            ? AspectRatio(
                aspectRatio: _cameraController.value.aspectRatio,
                child: CameraPreview(_cameraController),
              )
            : _thumbnailWidget(size),
      ),
    );
  }

  /// Display the thumbnail of the captured image or video.
  Widget _thumbnailWidget(Size size) {
    return (!chosenFile.path.endsWith('.mp4'))
        ? Image.file(
            chosenFile,
            width: size.width,
            height: size.height - kToolbarHeight,
            filterQuality: FilterQuality.high,
          )
        : FutureBuilder<Object>(
            future: _startVideoPlayer(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done)
                return AspectRatio(
                  aspectRatio: _videoController.value.size != null
                      ? _videoController.value.aspectRatio
                      : 1.0,
                  child: VideoPlayer(_videoController),
                );
              return Center(
                child: CircularProgressIndicator(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              );
            },
          );
  }

  Future<void> _startVideoPlayer() async {
    if (_videoController != null) await _videoController.dispose();
    _videoController = VideoPlayerController.file(chosenFile);

    // await _videoController.setLooping(true);
    await _videoController.initialize();

    await _videoController.play();
  }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    return chosenFile == null ||
            _cameraController.value.isRecordingVideo ||
            _cameraController.value.isRecordingPaused
        ? SizedBox(
            height: kToolbarHeight * 2,
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.swap_horizontal_circle,
                      color: Colors.white,
                      size: 35,
                    ),
                    onPressed: _cameraController != null &&
                            _cameraController.value.isInitialized &&
                            !_cameraController.value.isRecordingVideo
                        ? () {}
                        : null,
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: progressSize,
                        height: progressSize,
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.white,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                          strokeWidth: 6,
                          value: _cameraController.value.isRecordingVideo ||
                                  _cameraController.value.isRecordingPaused
                              ? progressCount / 10000
                              : 0,
                        ),
                      ),
                      GestureDetector(
                        onTap: onTakePictureButtonPressed,
                        onLongPressStart: (details) =>
                            onVideoRecordButtonPressed(),
                        onLongPressEnd: (details) => stopVideoRecording(),
                        child: Material(
                          type: MaterialType.circle,
                          elevation: 2.0,
                          color: Colors.white,
                          child: SizedBox(
                            width: 70,
                            height: 70,
                            child: Icon(
                              Icons.camera_alt,
                              size: 35.0,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.file_upload,
                      color: Colors.white,
                      size: 35,
                    ),
                    onPressed: _cameraController != null &&
                            _cameraController.value.isInitialized &&
                            !_cameraController.value.isRecordingVideo
                        ? chooseImageFromPhone
                        : null,
                  ),
                ],
              ),
            ),
          )
        : SizedBox(
            height: kToolbarHeight,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FlatButton.icon(
                    onPressed: _clear,
                    icon: Icon(
                      Icons.clear,
                      color: Colors.white,
                    ),
                    label: Text('Cancle'),
                    textColor: Colors.white,
                  ),
                  FlatButton.icon(
                      onPressed: () async {
                        if (chosenFile.path.endsWith('.mp4')) {
                          setState(() {
                            _inProgress = true;
                          });
                          try {
                            String unigueId = Uuid().v1();
                            String videoUrl = await _storageServices
                                .uploadPostVideoAndThumbnail(
                                    chosenFile, unigueId);
                            print(videoUrl);
                            if (videoUrl != null)
                              await videosRef.doc(unigueId).set({
                                'url': videoUrl,
                                'creationDate': DateTime.now(),
                              });
                          } catch (e) {
                            print(e.toString());
                          }
                          Navigator.pop(context);
                        }
                      },
                      icon: Icon(
                        Icons.navigate_next,
                        color: Colors.white,
                      ),
                      label: Text('Next'),
                      textColor: Colors.white),
                ],
              ),
            ),
          );
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (_cameraController != null) {
      await _cameraController.dispose();
    }
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      // enableAudio: enableAudio,
    );

    // // If the controller is updated then update the UI.
    // _cameraController.addListener(() {
    //   if (mounted) setState(() {});
    //   if (_cameraController.value.hasError) {
    //     showInSnackBar('Camera error ${_cameraController.value.errorDescription}');
    //   }
    // });

    try {
      await _cameraController.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> onCameraSelect(CameraDescription camera) async {
    if (_cameraController != null) {
      _cameraController.dispose();
    }

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
    );

    _cameraController.addListener(() {
      if (mounted) setState(() {});
      if (_cameraController.value.hasError) {
        showInSnackBar(
            'Camera error ${_cameraController.value.errorDescription}');
      }
    });
    try {
      await _cameraController.initialize();
    } on CameraException catch (e) {
      print('Error: ${e.code} \nError Message: ${e.description}');
    }
    setState(() {
      _inProgress = false;
    });
  }

  ////////////////////////// recording video functionality //////////////////////////

  void onVideoRecordButtonPressed() {
    if (_cameraController.value.isRecordingVideo) {
      stopVideoRecording();
    } else {
      startVideoRecording().then((String filePath) {
        if (mounted)
          setState(() {
            chosenFile = File(filePath);
          });
      });
    }
  }

  Future<String> startVideoRecording() async {
    if (!_cameraController.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Movies/newapp';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.mp4';

    if (_cameraController.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return null;
    }

    try {
      await _cameraController.startVideoRecording(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  Future<void> stopVideoRecording() async {
    if (!_cameraController.value.isRecordingVideo) {
      return null;
    }

    try {
      await _cameraController.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  ////////////////////////// taking picktures functionality //////////////////////////

  void onTakePictureButtonPressed() {
    takePicture().then((String filePath) {
      if (filePath == null) return;
      chosenFile = File(filePath);
      _videoController?.dispose();
      _videoController = null;
    });
  }

  Future<String> takePicture() async {
    if (!_cameraController.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/newapp';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (_cameraController.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      await _cameraController.takePicture(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  ////////////////////////// choosing media from phone /////////////////////////

  void chooseImageFromPhone() async {
    File currentFile;

    try {
      currentFile = await FilePicker.getFile(
        type: FileType.media,
        allowCompression: true,
      );
    } catch (e) {
      print('ERROR:::: ${e.toString()} in chooseImageFromPhone, camera');
    }
    if (currentFile != null) {
      setState(() {
        chosenFile = currentFile;
      });
    }
  }

  ////////////////////////// general methods //////////////////////////

  void _showCameraException(CameraException e) {
    print('${e.code}, ${e.description}');
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  void showInSnackBar(String message) {
    if (context != null)
      Scaffold.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  /// Remove image
  void _clear() async {
    if (_cameraController.value.isRecordingVideo)
      await _cameraController.stopVideoRecording();
    setState(() {
      chosenFile = null;
    });
  }
}
