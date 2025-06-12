// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:logger/logger.dart';

// /// A scope that provides [StreamAuth] for the subtree.
// class StreamAuthScope extends InheritedNotifier<StreamAuthNotifier> {
//   /// Creates a [StreamAuthScope] sign in scope.
//   StreamAuthScope({
//     super.key,
//     required super.child,
//   }) : super(
//           notifier: StreamAuthNotifier(),
//         );

//   /// Gets the [StreamAuth].
//   static StreamAuth of(BuildContext context) {
//     return context
//         .dependOnInheritedWidgetOfExactType<StreamAuthScope>()!
//         .notifier!
//         .streamAuth;
//   }
// }

// /// A class that converts [StreamAuth] into a [ChangeNotifier].
// class StreamAuthNotifier extends ChangeNotifier {
//   /// Creates a [StreamAuthNotifier].
//   StreamAuthNotifier() : streamAuth = StreamAuth() {
//     streamAuth.onTokenChanged.listen((String? string) {
//       notifyListeners();
//     });
//   }

//   /// The stream auth client.
//   final StreamAuth streamAuth;
// }

// /// An asynchronous log in services mock with stream similar to google_sign_in.
// ///
// /// This class adds an artificial delay of 3 second when logging in an user, and
// /// will automatically clear the login session after [refreshInterval].
// class StreamAuth {
//   /// Creates an [StreamAuth] that clear the current user session in
//   /// [refeshInterval] second.
//   StreamAuth({this.refreshInterval = 2000})
//       : _tokenStreamController = StreamController<String?>.broadcast() {
//     _tokenStreamController.stream.listen((String? token) {
//       _currentToken = token;
//     });
//   }

//   /// The current user.
//   String? get currentToken => _currentToken;
//   String? _currentToken;

//   /// Checks whether current user is signed in with an artificial delay to mimic
//   /// async operation.
//   Future<bool> isSignedIn() async {
//     return _currentToken != null;
//   }

//   /// A stream that notifies when current user has changed.
//   Stream<String?> get onTokenChanged => _tokenStreamController.stream;
//   final StreamController<String?> _tokenStreamController;

//   /// The interval that automatically signs out the user.
//   final int refreshInterval;

//   Timer? _timer;
//   Timer _createRefreshTimer() {
//     return Timer(Duration(seconds: refreshInterval), () {
//       _tokenStreamController.add(null);
//       _timer = null;
//     });
//   }

//   /// Signs in a user with an artificial delay to mimic async operation.
//   Future<void> signIn(String token) async {
//     const storage = FlutterSecureStorage();

//     await storage.write(key: "token", value: token);

//     _tokenStreamController.add(token);
//     _timer?.cancel();
//     _timer = _createRefreshTimer();
//   }

//   Future<void> autoSignIn() async {
//     const storage = FlutterSecureStorage();

//     String? token = await storage.read(key: "token");

//     // Logger().i(token);

//     // _tokenStreamController.sink;

//     // _tokenStreamController.add(token);

//     //TODO: Need to change
//     _tokenStreamController.add(token);
//     _timer?.cancel();
//     _timer = _createRefreshTimer();
//   }

//   /// Signs out the current user.
//   Future<void> signOut() async {
//     const storage = FlutterSecureStorage();

//     await storage.delete(key: "token");
//     Logger().i("token Deleted");
//     _timer?.cancel();
//     _timer = null;
//     _tokenStreamController.add(null);
//   }
// }
