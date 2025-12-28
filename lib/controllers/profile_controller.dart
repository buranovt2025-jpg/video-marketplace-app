import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/demo_config.dart';

class ProfileController extends GetxController {
  final Rx<Map<String, dynamic>> _user = Rx<Map<String, dynamic>>({});
  Map<String, dynamic> get user => _user.value;

  Rx<String> _uid = "".obs;
  var isLoading = false.obs;

  updateUserId(String uid) {
    _uid.value = uid;
    getUserData();
  }

  getUserData() async {
    if (DEMO_MODE) {
      _loadDemoUserData();
      return;
    }
    
    try {
      isLoading.value = true;
      List<String> thumbnails = [];
      
      // Получаем видео пользователя
      var myVideos = await firestore
          .collection('videos')
          .where('uid', isEqualTo: _uid.value)
          .get();

      for (int i = 0; i < myVideos.docs.length; i++) {
        final videoData = myVideos.docs[i].data();
        if (videoData['thumbnail'] != null) {
          thumbnails.add(videoData['thumbnail'] as String);
        }
      }

      // Получаем данные пользователя
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(_uid.value).get();
      
      if (!userDoc.exists) {
        Get.snackbar(
          'Error',
          'User not found',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) {
        Get.snackbar(
          'Error',
          'Invalid user data',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      String name = userData['name'] ?? 'Unknown User';
      String profilePhoto = userData['profilePhoto'] ?? '';
      int likes = 0;
      int followers = 0;
      int following = 0;
      bool isFollowing = false;

      // Подсчитываем лайки
      for (var item in myVideos.docs) {
        final videoData = item.data();
        if (videoData['likes'] != null) {
          likes += (videoData['likes'] as List).length;
        }
      }

      // Получаем количество подписчиков и подписок
      var followerDoc = await firestore
          .collection('users')
          .doc(_uid.value)
          .collection('followers')
          .get();
      var followingDoc = await firestore
          .collection('users')
          .doc(_uid.value)
          .collection('following')
          .get();
      
      followers = followerDoc.docs.length;
      following = followingDoc.docs.length;

      // Проверяем, подписан ли текущий пользователь
      // ИСПРАВЛЕНИЕ: Проверяем наличие текущего пользователя перед использованием
      if (firebaseAuth.currentUser != null) {
        var followDoc = await firestore
            .collection('users')
            .doc(_uid.value)
            .collection('followers')
            .doc(firebaseAuth.currentUser!.uid)
            .get();
        
        isFollowing = followDoc.exists;
      }

      _user.value = {
        'followers': followers.toString(),
        'following': following.toString(),
        'isFollowing': isFollowing,
        'likes': likes.toString(),
        'profilePhoto': profilePhoto,
        'name': name,
        'thumbnails': thumbnails,
      };
      
      update();
    } catch (e) {
      Get.snackbar(
        'Error Loading Profile',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  void _loadDemoUserData() {
    isLoading.value = true;
    
    // Find user in demo data
    Map<String, dynamic>? userData;
    for (var user in demoUsers) {
      if (user['uid'] == _uid.value) {
        userData = user;
        break;
      }
    }
    
    // Get thumbnails from demo videos
    List<String> thumbnails = [];
    int likes = 0;
    for (var video in demoVideos) {
      if (video['uid'] == _uid.value) {
        thumbnails.add(video['thumbnail']);
        likes += (video['likes'] as List).length;
      }
    }
    
    _user.value = {
      'followers': '125',
      'following': '48',
      'isFollowing': false,
      'likes': likes.toString(),
      'profilePhoto': userData?['profilePhoto'] ?? DEMO_USER_PHOTO,
      'name': userData?['name'] ?? DEMO_USER_NAME,
      'thumbnails': thumbnails,
    };
    
    isLoading.value = false;
    update();
  }

  followUser() async {
    if (DEMO_MODE) {
      // Demo mode - toggle follow locally
      bool isFollowing = _user.value['isFollowing'] ?? false;
      int followers = int.parse(_user.value['followers'] ?? '0');
      
      _user.value['isFollowing'] = !isFollowing;
      _user.value['followers'] = (isFollowing ? followers - 1 : followers + 1).toString();
      update();
      return;
    }
    
    try {
      // Проверяем авторизацию
      if (firebaseAuth.currentUser == null) {
        Get.snackbar(
          'Error',
          'Please login to follow users',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      String currentUserId = firebaseAuth.currentUser!.uid;

      var doc = await firestore
          .collection('users')
          .doc(_uid.value)
          .collection('followers')
          .doc(currentUserId)
          .get();

      if (!doc.exists) {
        // Подписываемся
        await firestore
            .collection('users')
            .doc(_uid.value)
            .collection('followers')
            .doc(currentUserId)
            .set({});
        await firestore
            .collection('users')
            .doc(currentUserId)
            .collection('following')
            .doc(_uid.value)
            .set({});
        
        _user.value.update(
          'followers',
          (value) => (int.parse(value) + 1).toString(),
        );
      } else {
        // Отписываемся
        await firestore
            .collection('users')
            .doc(_uid.value)
            .collection('followers')
            .doc(currentUserId)
            .delete();
        await firestore
            .collection('users')
            .doc(currentUserId)
            .collection('following')
            .doc(_uid.value)
            .delete();
        
        _user.value.update(
          'followers',
          (value) => (int.parse(value) - 1).toString(),
        );
      }
      
      _user.value.update('isFollowing', (value) => !value);
      update();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update follow status: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
