import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AppVideoPlayer extends StatefulWidget {
  final String videoUrl;

  AppVideoPlayer(
    this.videoUrl,
  );

  @override
  _AppVideoPlayerState createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  VideoPlayerController _controller;
  VoidCallback listener;
  String videoUrl;

  @override
  void initState() {
    super.initState();
    videoUrl = widget.videoUrl;
    listener = () {
      if (mounted) setState(() {});
    };
    if (_controller == null)
      _controller = VideoPlayerController.network(videoUrl)
        ..addListener(listener)
        ..initialize()
        ..play();
    else {
      _controller.initialize();
      _controller.play();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _controller.value.initialized
          ? GestureDetector(
              onTap: () {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              },
              child: Stack(children: [
                Align(
                  alignment: Alignment(0, 0),
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
                _controller.value.isPlaying
                    ? Text('')
                    : Align(
                        alignment: Alignment(0, 0),
                        child: Icon(
                          Icons.play_arrow,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                Align(
                  alignment: Alignment(0, 0.98),
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: false,
                    padding: EdgeInsets.only(top: 5),
                  ),
                ),
              ]),
            )
          : Container(
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  LinearProgressIndicator(),
                ],
              ),
            ),
    );
  }
}
