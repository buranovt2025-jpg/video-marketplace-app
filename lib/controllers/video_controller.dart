import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:gogomarket/constants.dart';
import 'package:gogomarket/demo_config.dart';
import 'package:gogomarket/models/video.dart';

class VideoController extends GetxController {
  final Rx<List<Video>> _videoList = Rx<List<Video>>([]);

  List<Video> get videoList => _videoList.value;

  @override
  void onInit() {
    super.onInit();
    
    if (DEMO_MODE) {
      // Load demo videos
      _loadDemoVideos();
    } else {
      // Production mode - load from Firestore
      _videoList.bindStream(
          firestore.collection('videos').snapshots().map((QuerySnapshot query) {
        List<Video> retVal = [];
        for (var element in query.docs) {
          retVal.add(
            Video.fromSnap(element),
          );
        }
        return retVal;
      }));
    }
  }
  
  void _loadDemoVideos() {
    List<Video> videos = demoVideos.map((data) => Video(
      id: data['id'],
      uid: data['uid'],
      username: data['username'],
      profilePhoto: data['profilePhoto'],
      videoUrl: data['videoUrl'],
      thumbnail: data['thumbnail'],
      caption: data['caption'],
      songName: data['songName'],
      likes: List<String>.from(data['likes']),
      commentCount: data['commentCount'],
      shareCount: data['shareCount'],
    )).toList();
    
    _videoList.value = videos;
  }

  likeVideo(String id) async {
    if (DEMO_MODE) {
      // Demo mode - toggle like locally
      int index = _videoList.value.indexWhere((v) => v.id == id);
      if (index != -1) {
        Video video = _videoList.value[index];
        List<String> likes = List<String>.from(video.likes);
        if (likes.contains(DEMO_USER_ID)) {
          likes.remove(DEMO_USER_ID);
        } else {
          likes.add(DEMO_USER_ID);
        }
        // Create updated video
        _videoList.value[index] = Video(
          id: video.id,
          uid: video.uid,
          username: video.username,
          profilePhoto: video.profilePhoto,
          videoUrl: video.videoUrl,
          thumbnail: video.thumbnail,
          caption: video.caption,
          songName: video.songName,
          likes: likes,
          commentCount: video.commentCount,
          shareCount: video.shareCount,
        );
        _videoList.refresh();
      }
      return;
    }
    
    try {
      if (authController.user == null) {
        Get.snackbar(
          'Error',
          'Please login to like videos',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      DocumentSnapshot doc = await firestore.collection('videos').doc(id).get();
      
      if (!doc.exists) {
        Get.snackbar(
          'Error',
          'Video not found',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      var uid = authController.user!.uid;
      final videoData = doc.data() as Map<String, dynamic>?;
      
      if (videoData == null || videoData['likes'] == null) {
        Get.snackbar(
          'Error',
          'Invalid video data',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if ((videoData['likes'] as List).contains(uid)) {
        await firestore.collection('videos').doc(id).update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        await firestore.collection('videos').doc(id).update({
          'likes': FieldValue.arrayUnion([uid]),
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to like video: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
