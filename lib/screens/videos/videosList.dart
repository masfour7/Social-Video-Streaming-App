import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'videoPlayer.dart';

class VideosListScreen extends StatefulWidget {
  VideosListScreen(Key key) : super(key: key);

  @override
  _VideosListScreenState createState() => _VideosListScreenState();
}

class _VideosListScreenState extends State<VideosListScreen> {
  final CollectionReference videosRef =
      FirebaseFirestore.instance.collection('videos');

  Stream<QuerySnapshot> videosQuery;
  List<String> videosUrls;

  @override
  void initState() {
    super.initState();
    videosQuery =
        videosRef.orderBy('creationDate', descending: true).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
          stream: videosQuery,
          builder: (context, snapshot) {
            // waiting for the data to come from firestore
            if (snapshot.connectionState == ConnectionState.waiting)
              return Center(
                child: CircularProgressIndicator(),
              );

            // when the data is ready.
            // if the list is empty
            if (snapshot.data.docs.isEmpty)
              return Center(
                child: Text('No videos, yet!'),
              );

            // if we have data
            videosUrls = snapshot.data.docs
                .map((e) => e.data()['url'].toString())
                .toList();
            return PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: videosUrls.length,
              itemBuilder: (context, position) {
                return VideoItem(
                  UniqueKey(),
                  videoUrl: videosUrls[position],
                );
              },
            );
          }),
    );
  }
}

class VideoItem extends StatelessWidget {
  const VideoItem(
    Key key, {
    @required this.videoUrl,
  }) : super(key: key);

  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        color: Colors.black,
        child: AppVideoPlayer(videoUrl),
      ),
    );
  }
}
