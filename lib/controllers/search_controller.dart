import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:gogomarket/constants.dart';
import 'package:gogomarket/demo_config.dart';
import 'package:gogomarket/models/user.dart';

class UserSearchController extends GetxController {
  final Rx<List<User>> _searchedUsers = Rx<List<User>>([]);

  List<User> get searchedUsers => _searchedUsers.value;

  searchUser(String typedUser) async {
    if (DEMO_MODE) {
      // Demo mode - search in demo users
      List<User> results = [];
      for (var userData in demoUsers) {
        String name = userData['name'].toString().toLowerCase();
        if (name.contains(typedUser.toLowerCase())) {
          results.add(User(
            uid: userData['uid'],
            name: userData['name'],
            email: userData['email'] ?? '',
            profilePhoto: userData['profilePhoto'],
          ));
        }
      }
      _searchedUsers.value = results;
      return;
    }
    
    _searchedUsers.bindStream(firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: typedUser)
        .snapshots()
        .map((QuerySnapshot query) {
      List<User> retVal = [];
      for (var elem in query.docs) {
        retVal.add(User.fromSnap(elem));
      }
      return retVal;
    }));
  }
}
