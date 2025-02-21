import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math';
import 'package:random_name_generator/random_name_generator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'map_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required String username, required int age, required String description, required void Function(String username, int age, String description) onProfileChanged});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  User? _user;

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  /// ✅ Vérifie si un utilisateur est connecté
  Future<void> _checkUser() async {
    print("🔹 Vérification de l'état de l'utilisateur...");

    try {
      setState(() {
        _user = supabase.auth.currentUser;
      });

      if (_user != null) {
        print("✅ Utilisateur connecté: ${_user!.email}");
      } else {
        print("❌ Aucun utilisateur connecté.");
      }
    } catch (e) {
      print("❌ Erreur lors de la vérification de l'utilisateur: $e");
    }
  }

  /// ✅ Connexion avec Google
  Future<void> _signInWithGoogle() async {
    try {
      print("🔹 Début de la connexion Google...");

      final String iosClientId = dotenv.get('GOOGLE_IOS_CLIENT_ID');
      final String webClientId = dotenv.get('GOOGLE_WEB_CLIENT_ID');

      print("✅ GOOGLE_IOS_CLIENT_ID: $iosClientId");
      print("✅ GOOGLE_WEB_CLIENT_ID: $webClientId");

      print("🔹 Envoi de la requête d'authentification à Supabase...");

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser!.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw 'No Access Token found.';
      }
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );


      _checkUser();

    } catch (e) {
      print("❌ Erreur lors de la connexion avec Google : $e");
    }
  }

  /// ✅ Déconnexion
  Future<void> _signOut() async {
    try {
      print("🔹 Déconnexion en cours...");

      await supabase.auth.signOut();

      setState(() {
        _user = null;
      });

      print("✅ Déconnexion réussie !");
    } catch (e) {
      print("❌ Erreur lors de la déconnexion: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_user == null) ...[
                const Text(
                  "Vous n'êtes pas connecté.",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text("Se connecter avec Google"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ] else ...[
                const Text(
                  "Connecté avec Google",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Email : ${_user!.email}",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text("Se déconnecter"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
Future<List<Map<String, dynamic>>> generateUsers() async {
  final random = Random();
  final randomNames = RandomNames(Zone.us);
  final List<String> cities = cityCoordinates.keys.toList();
  geo.Position? userPosition = await getUserLocation();

  return List.generate(20, (index) {
    String city = cities[random.nextInt(cities.length)];
    double distance = 0;

    if (userPosition != null && cityCoordinates.containsKey(city)) {
      distance = calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        cityCoordinates[city]!["lat"]!,
        cityCoordinates[city]!["lng"]!,
      );
    }

    return {
      'name': randomNames.fullName(),
      'age': random.nextInt(30) + 18, // Âge entre 18 et 47 ans
      'distance': distance, // 🔥 Distance réelle
      'city': city,
      'description': "Utilisateur sympathique qui aime discuter.",
      'imageURL': "https://picsum.photos/200?random=$index",
    };
  });
}