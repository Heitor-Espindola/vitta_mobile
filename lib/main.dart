import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/app.dart';
import 'package:vitta_mobile/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const VittaApp());
}
