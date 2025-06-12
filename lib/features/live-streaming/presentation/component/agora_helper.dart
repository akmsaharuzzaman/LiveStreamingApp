import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgoraHelper {
  Future<String> generateToken(String channelName, int uid) async {
    if (FirebaseAuth.instance.currentUser != null) {
      HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('generateAgoraToken');
      final response = await callable.call({
        'channelName': channelName,
        'uid': uid,
      });
      return response.data['token'];
    } else {
      throw Exception('User is not authenticated');
    }
  }
}
