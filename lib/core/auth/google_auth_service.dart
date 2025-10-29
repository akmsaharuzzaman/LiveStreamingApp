import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import '../models/google_response_model.dart';

/// Google authentication service interface
abstract class GoogleAuthService {
  Future<GoogleResponseModel?> signInWithGoogle();
  Future<void> signOut();
  User? get currentUser;
  bool get isSignedIn;
  Future<void> initialize();
}

/// Implementation of Google authentication service using Google Sign-In v7 API
@LazySingleton(as: GoogleAuthService)
class GoogleAuthServiceImpl implements GoogleAuthService {
  final GoogleSignIn _googleSignIn;
  final FirebaseAuth _firebaseAuth;

  bool _isGoogleSignInInitialized = false;
  GoogleSignInAccount? _currentGoogleUser;

  GoogleAuthServiceImpl(this._googleSignIn, this._firebaseAuth);

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  bool get isSignedIn => currentUser != null && _currentGoogleUser != null;

  /// Initialize Google Sign-In (required for v7)
  @override
  Future<void> initialize() async {
    if (_isGoogleSignInInitialized) return;

    try {
      await _googleSignIn.initialize();
      _isGoogleSignInInitialized = true;

      // Try to restore previous session
      // await _attemptSilentSignIn();
    } catch (e) {
      throw Exception('Failed to initialize Google Sign-In: ${e.toString()}');
    }
  }

  /// Ensure Google Sign-In is initialized before use
  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      await initialize();
    }
  }

  @override
  Future<GoogleResponseModel?> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    try {
      // Use authenticate() instead of signIn() in v7
      final GoogleSignInAccount account = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      _currentGoogleUser = account;

      // For now, let's create a UserModel directly from Google account data
      // We'll handle Firebase integration after confirming Google Sign-In works
      return GoogleResponseModel.fromGoogleSignIn(
        id: account.id, // Use Google ID as temporary ID
        email: account.email,
        displayName: account.displayName ?? '',
        photoUrl: account.photoUrl,
        googleId: account.id,
      );
    } on GoogleSignInException catch (e) {
      _currentGoogleUser = null;
      throw Exception(
        'Google Sign In error: code: ${e.code.name} description: ${e.description} details: ${e.details}',
      );
    } catch (e) {
      _currentGoogleUser = null;
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Sign out from both Google and Firebase
      await Future.wait([_googleSignIn.signOut(), _firebaseAuth.signOut()]);
      _currentGoogleUser = null;
    } catch (e) {
      // Clear local state even if sign out fails
      _currentGoogleUser = null;
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Get access token for specific scopes (v7 enhanced scope management)
  Future<String?> getAccessTokenForScopes(List<String> scopes) async {
    await _ensureGoogleSignInInitialized();

    try {
      final authClient = _googleSignIn.authorizationClient;

      // Try to get existing authorization
      var authorization = await authClient.authorizationForScopes(scopes);

      // Request new authorization from user
      authorization ??= await authClient.authorizeScopes(scopes);

      return authorization.accessToken;
    } catch (error) {
      throw Exception('Failed to get access token for scopes: $error');
    }
  }
}
