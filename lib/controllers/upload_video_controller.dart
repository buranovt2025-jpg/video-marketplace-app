import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:gogomarket/constants.dart';
import 'package:gogomarket/models/video.dart';
import 'package:video_compress/video_compress.dart';

class UploadVideoController extends GetxController {
  // Добавляем переменную для отслеживания состояния загрузки
  var isUploading = false.obs;

  Future<File?> _compressVideo(String videoPath) async {
    try {
      final compressedVideo = await VideoCompress.compressVideo(
        videoPath,
        quality: VideoQuality.MediumQuality,
      );
      
      if (compressedVideo == null || compressedVideo.file == null) {
        Get.snackbar(
          'Error',
          'Failed to compress video. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }
      
      return compressedVideo.file;
    } catch (e) {
      Get.snackbar(
        'Compression Error',
        'Failed to compress video: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  Future<String?> _uploadVideoToStorage(String id, String videoPath) async {
    try {
      final compressedFile = await _compressVideo(videoPath);
      if (compressedFile == null) {
        return null;
      }

      Reference ref = firebaseStorage.ref().child('videos').child(id);
      UploadTask uploadTask = ref.putFile(compressedFile);
      
      TaskSnapshot snap = await uploadTask;
      String downloadUrl = await snap.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      Get.snackbar(
        'Upload Error',
        'Failed to upload video: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  Future<File?> _getThumbnail(String videoPath) async {
    try {
      final thumbnail = await VideoCompress.getFileThumbnail(videoPath);
      if (thumbnail == null) {
        Get.snackbar(
          'Error',
          'Failed to generate thumbnail. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }
      return thumbnail;
    } catch (e) {
      Get.snackbar(
        'Thumbnail Error',
        'Failed to generate thumbnail: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  Future<String?> _uploadImageToStorage(String id, String videoPath) async {
    try {
      final thumbnailFile = await _getThumbnail(videoPath);
      if (thumbnailFile == null) {
        return null;
      }

      Reference ref = firebaseStorage.ref().child('thumbnails').child(id);
      UploadTask uploadTask = ref.putFile(thumbnailFile);
      
      TaskSnapshot snap = await uploadTask;
      String downloadUrl = await snap.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      Get.snackbar(
        'Upload Error',
        'Failed to upload thumbnail: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  // upload video
  uploadVideo(String songName, String caption, String videoPath) async {
    if (isUploading.value) {
      Get.snackbar(
        'Upload in Progress',
        'Please wait for the current upload to finish.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isUploading.value = true;
      
      // Показываем индикатор загрузки
      Get.snackbar(
        'Uploading Video',
        'Please wait while your video is being uploaded...',
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
        showProgressIndicator: true,
      );

      // Проверяем авторизацию
      if (firebaseAuth.currentUser == null) {
        throw Exception('User not authenticated');
      }

      String uid = firebaseAuth.currentUser!.uid;
      
      // Получаем данные пользователя
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) {
        throw Exception('Invalid user data');
      }

      // Получаем ID для видео
      var allDocs = await firestore.collection('videos').get();
      int len = allDocs.docs.length;
      String videoId = "Video $len";

      // Загружаем видео и превью
      String? videoUrl = await _uploadVideoToStorage(videoId, videoPath);
      if (videoUrl == null) {
        throw Exception('Failed to upload video');
      }

      String? thumbnail = await _uploadImageToStorage(videoId, videoPath);
      if (thumbnail == null) {
        throw Exception('Failed to upload thumbnail');
      }

      // Создаем объект видео
      Video video = Video(
        username: userData['name'] ?? 'Unknown',
        uid: uid,
        id: videoId,
        likes: [],
        commentCount: 0,
        shareCount: 0,
        songName: songName,
        caption: caption,
        videoUrl: videoUrl,
        profilePhoto: userData['profilePhoto'] ?? '',
        thumbnail: thumbnail,
      );

      // Сохраняем в Firestore
      await firestore.collection('videos').doc(videoId).set(
            video.toJson(),
          );

      Get.snackbar(
        'Success',
        'Video uploaded successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error Uploading Video',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isUploading.value = false;
    }
  }
}
