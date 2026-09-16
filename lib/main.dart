import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/app.dart';
import 'package:vitta_mobile/core/config/app_preferences.dart';
import 'package:vitta_mobile/firebase_options.dart';
import 'package:vitta_mobile/features/auth/data/repositories/firebase_auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuthRepository.configurePersistence();
  await AppPreferences.instance.load();
  runApp(const VittaApp());
}
