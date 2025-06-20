import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final files = [
    'index.html',
    'Build/d2822e4a9f0d71c41427f922e253050a.framework.js.unityweb',
    'Build/ff1050a13c2847cee173916bd9c265cb.wasm.unityweb',
    'Build/dfb21f1f70f797a3ccc0fe3128e85a8e.data.unityweb',
    'Build/ca9603362935615175cf9899a05ad3cb.loader.js',
  ];

  final dir = await getApplicationDocumentsDirectory();
  final dstDir = Directory('${dir.path}/unityweb');

  if (dstDir.existsSync()) {
    await dstDir.delete(recursive: true);
  }
  dstDir.createSync(recursive: true);

  final localPath = '${dir.path}/unityweb';
  final handler = createStaticHandler(
    localPath,
    defaultDocument: 'index.html',
    serveFilesOutsidePath: true,
  );

  for (var file in files) {
    final data = await rootBundle.load('assets/unityweb/$file');
    final outFile = File('${dstDir.path}/$file');
    outFile.createSync(recursive: true);
    await outFile.writeAsBytes(data.buffer.asUint8List());
  }

  // Start the server on port 8080
  // final server = await shelf_io.serve(
  //   handler,
  //   InternetAddress.loopbackIPv4,
  //   8080,
  // );
  // debugPrint('Serving at http://${server.address.host}:${server.port}');

  //Load environment variables
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
  // runApp(MyAppTest());
}

class MyAppTest extends StatelessWidget {
  const MyAppTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri("http://127.0.0.1:8080/index.html"),
          ),
          initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(javaScriptEnabled: true),
          ),
        ),
      ),
    );
  }
}
