import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/models/video.dart';

class VideoController extends GetxController {
  final Rx<List<Video>> _videoList = Rx<List<Video>>([]);

  List<Video> get videoList => _videoList.value;

  @override
  void onInit() {
    super.onInit();
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

  likeVideo(String id) async {
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
