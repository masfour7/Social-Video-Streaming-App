import 'dart:io';

import 'package:image/image.dart' as Im;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

class StorageServices {
  Future<String> uploadProfileImage(
      File image, String basename, String userId) async {
    String url;
    try {
      StorageReference profilesImagesRef = FirebaseStorage.instance
          .ref()
          .child('images/profiles/$userId/$basename');
      StorageUploadTask uploadTask = profilesImagesRef.putFile(image);
      await uploadTask.onComplete;
      url = await profilesImagesRef.getDownloadURL();
    } catch (e) {
      print('${e.toString()} in StorageServices.profile');
    }
    return url;
  }

  Future<String> uploadPostImage(File image, String basename) async {
    String url;
    try {
      StorageReference postsImagesRef =
          FirebaseStorage.instance.ref().child('images/posts/$basename');
      StorageUploadTask uploadTask = postsImagesRef.putFile(image);
      await uploadTask.onComplete;
      url = await postsImagesRef.getDownloadURL();
    } catch (e) {
      print('${e.toString()} in StorageServices.postImage');
    }
    return url;
  }

  Future<String> uploadPostVideoAndThumbnail(
      File video, String basename) async {
    String videoUrl;

    video = await compressVideoFile(video);

    try {
      StorageReference postsVideosRef =
          FirebaseStorage.instance.ref().child('videos/posts/$basename');
      StorageUploadTask videoUploadTask = postsVideosRef.putFile(video);
      await videoUploadTask.onComplete;
      videoUrl = await postsVideosRef.getDownloadURL();
    } catch (e) {
      print('${e.toString()} in StorageServices.postVideo');
    }
    return videoUrl;
  }

  // reduce video size
  Future<File> compressVideoFile(File chosenVideo) async {
    File compressedFile;

    MediaInfo media = await VideoCompress.compressVideo(
      chosenVideo.path,
      quality: VideoQuality.LowQuality,
      deleteOrigin: true, // It's false by default
    );
    compressedFile = media.file;

    return compressedFile;
  }

  // reduce image size
  Future<File> compressImage(File chosenImage) async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(chosenImage.readAsBytesSync());
    final compressedImageFile = File('$path.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 85));
    return compressedImageFile;
  }
}
