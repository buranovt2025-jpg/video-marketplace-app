import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:gogomarket/constants.dart';
import 'package:gogomarket/models/comment.dart';

class CommentController extends GetxController {
  final Rx<List<Comment>> _comments = Rx<List<Comment>>([]);
  List<Comment> get comments => _comments.value;

  String _postId = "";

  updatePostId(String id) {
    _postId = id;
    getComment();
  }

  getComment() async {
    _comments.bindStream(
      firestore
          .collection('videos')
          .doc(_postId)
          .collection('comments')
          .snapshots()
          .map(
        (QuerySnapshot query) {
          List<Comment> retValue = [];
          for (var element in query.docs) {
            retValue.add(Comment.fromSnap(element));
          }
          return retValue;
        },
      ),
    );
  }

  postComment(String commentText) async {
    try {
      if (authController.user == null) {
        Get.snackbar(
          'Error',
          'Please login to comment',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (commentText.isEmpty) {
        Get.snackbar(
          'Error',
          'Comment cannot be empty',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      String uid = authController.user!.uid;
      
      DocumentSnapshot userDoc = await firestore
          .collection('users')
          .doc(uid)
          .get();
      
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

      var allDocs = await firestore
          .collection('videos')
          .doc(_postId)
          .collection('comments')
          .get();
      int len = allDocs.docs.length;

      Comment comment = Comment(
        username: userData['name'] ?? 'Unknown',
        comment: commentText.trim(),
        datePublished: DateTime.now(),
        likes: [],
        profilePhoto: userData['profilePhoto'] ?? '',
        uid: uid,
        id: 'Comment $len',
      );
      
      await firestore
          .collection('videos')
          .doc(_postId)
          .collection('comments')
          .doc('Comment $len')
          .set(
            comment.toJson(),
          );
      
      DocumentSnapshot doc =
          await firestore.collection('videos').doc(_postId).get();
      
      if (doc.exists) {
        final videoData = doc.data() as Map<String, dynamic>?;
        int currentCount = videoData?['commentCount'] ?? 0;
        
        await firestore.collection('videos').doc(_postId).update({
          'commentCount': currentCount + 1,
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error While Commenting',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  likeComment(String id) async {
    try {
      if (authController.user == null) {
        Get.snackbar(
          'Error',
          'Please login to like comments',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      String uid = authController.user!.uid;
      
      DocumentSnapshot doc = await firestore
          .collection('videos')
          .doc(_postId)
          .collection('comments')
          .doc(id)
          .get();

      if (!doc.exists) {
        Get.snackbar(
          'Error',
          'Comment not found',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final commentData = doc.data() as Map<String, dynamic>?;
      if (commentData == null || commentData['likes'] == null) {
        Get.snackbar(
          'Error',
          'Invalid comment data',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if ((commentData['likes'] as List).contains(uid)) {
        await firestore
            .collection('videos')
            .doc(_postId)
            .collection('comments')
            .doc(id)
            .update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        await firestore
            .collection('videos')
            .doc(_postId)
            .collection('comments')
            .doc(id)
            .update({
          'likes': FieldValue.arrayUnion([uid]),
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to like comment: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
