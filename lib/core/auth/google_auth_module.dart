import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

/// Module for Google authentication dependencies
@module
abstract class GoogleAuthModule {
  /// Provides GoogleSignIn instance using v7 API
  @lazySingleton
  GoogleSignIn get googleSignIn {
    return GoogleSignIn.instance;
  }

  /// Provides FirebaseAuth instance
  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;
}
