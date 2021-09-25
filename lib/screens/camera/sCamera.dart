import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'wCameraItem.dart';

class CameraScreen extends StatefulWidget {
  static final String routePath = '/camera';

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool inProgress = true;
  Future<List<CameraDescription>> _cameras;

  @override
  void initState() {
    super.initState();
    _cameras = availableCameras();
    setState(() {
      inProgress = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CameraDescription>>(
      future: _cameras,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          );
        return Scaffold(
          body: inProgress
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : CameraItem(snapshot.data),
        );
      },
    );
  }
}
