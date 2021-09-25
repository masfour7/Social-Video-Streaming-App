import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:newapp_video_player/screens/camera/sCamera.dart';
import 'package:newapp_video_player/screens/videos/videosList.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'video player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
      routes: {
        CameraScreen.routePath: (context) => CameraScreen(),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('videos'),
      ),
      body: VideosListScreen(UniqueKey()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, CameraScreen.routePath);
        },
        tooltip: 'openCamera',
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}
