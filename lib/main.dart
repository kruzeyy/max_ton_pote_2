import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:max_ton_pote_2/pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(); // Charge les variables d'environnement

  await Supabase.initialize(
    url: 'https://jlbgttnxwamvfhgfqbhv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpsYmd0dG54d2FtdmZoZ2ZxYmh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwNjA4MTYsImV4cCI6MjA1NTYzNjgxNn0.esJ7BtZYU17bYJzTxCEfOTMFxA1pSjyfoJ5gMowaREk',
  );

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(), // 🔥 Affiche d'abord la page de connexion
    );
  }
}



