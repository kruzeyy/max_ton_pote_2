import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'dart:math';
import 'package:random_name_generator/random_name_generator.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final Map<String, Map<String, double>> cityCoordinates = {
  "Lyon": {"lat": 45.764, "lng": 4.8357},
  "Paris": {"lat": 48.8566, "lng": 2.3522},
  "Marseille": {"lat": 43.2965, "lng": 5.3698},
  "Toulouse": {"lat": 43.6047, "lng": 1.4442},
  "Bordeaux": {"lat": 44.8378, "lng": -0.5792},
  "Nice": {"lat": 43.7102, "lng": 7.262},
  "Nantes": {"lat": 47.2184, "lng": -1.5536},
  "Strasbourg": {"lat": 48.5734, "lng": 7.7521},
};

Future<geo.Position?> getUserLocation() async {
  bool serviceEnabled;
  geo.LocationPermission permission;

  serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print("Service de localisation désactivé");
    return null;
  }

  permission = await geo.Geolocator.checkPermission();
  if (permission == geo.LocationPermission.denied) {
    permission = await geo.Geolocator.requestPermission();
    if (permission == geo.LocationPermission.denied) {
      print("Permission refusée");
      return null;
    }
  }

  if (permission == geo.LocationPermission.deniedForever) {
    print("Permission refusée définitivement");
    return null;
  }

  return await geo.Geolocator.getCurrentPosition(
      desiredAccuracy: geo.LocationAccuracy.high);
}

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double R = 6371; // Rayon de la Terre en km
  double dLat = (lat2 - lat1) * pi / 180;
  double dLon = (lon2 - lon1) * pi / 180;

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
          sin(dLon / 2) * sin(dLon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return R * c; // Distance en km
}


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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _locationPermissionDenied = false;

  Future<void> _requestLocationPermission() async {
    geo.LocationPermission permission = await geo.Geolocator.checkPermission();

    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }

    if (permission == geo.LocationPermission.deniedForever) {
      setState(() => _locationPermissionDenied = true);
    } else if (permission != geo.LocationPermission.denied) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()), // 🔥 Passe à HomeScreen si accepté
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                "assets/MaxTonPote-1.png",
                height: 500,
              ),
              const SizedBox(height: 20),
              const Text(
                "Bienvenue sur Max ton pote !",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Nous avons besoin de votre localisation pour vous montrer des utilisateurs proches.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _requestLocationPermission,
                label: const Text("Bienvenue"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              if (_locationPermissionDenied) ...[
                const SizedBox(height: 20),
                const Text(
                  "Permission refusée. Vous pouvez l'activer dans les paramètres.",
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

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

      print("✅ Réponse de Supabase: $response");

      print("🔹 Vérification de l'utilisateur après connexion...");
      _checkUser();

      print("✅ Connexion réussie !");
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

class _HomeScreenState extends State<HomeScreen> {
  late List<Map<String, dynamic>> users;
  List<Map<String, dynamic>> _favorites = []; // 🏆 Liste des favoris
  int _selectedIndex = 0;
  String _username = "";
  int _age = 18;
  String _description = "";

  /// ✅ Charger les informations du profil depuis SharedPreferences
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? "Utilisateur inconnu";
      _age = prefs.getInt('age') ?? 18;
      _description = prefs.getString('description') ?? "Aucune description disponible.";
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadFavorites();

    generateUsers().then((generatedUsers) {
      setState(() {
        users = generatedUsers;
      });
    });
  }

  /// ✅ Charger les favoris depuis `SharedPreferences`
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? favs = prefs.getStringList('favorites');

    if (favs != null) {
      setState(() {
        _favorites = favs
            .map((e) => users.firstWhere(
              (user) => user['name'] == e,
          orElse: () => <String, dynamic>{}, // ✅ Retourne un Map vide au lieu de {}
        ))
            .where((user) => user.isNotEmpty) // ✅ Filtrer les valeurs vides
            .toList();
      });
    }
  }

  /// ✅ Sauvegarder les favoris
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'favorites',
      _favorites.map((e) => e['name'] as String).toList(),
    );
  }

  /// ✅ Met à jour et sauvegarde le profil
  void _updateProfile(String username, int age, String description) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setInt('age', age);
    await prefs.setString('description', description);

    setState(() {
      _username = username;
      _age = age;
      _description = description;
    });
  }

  /// ✅ Ajouter ou retirer des favoris
  void _toggleFavorite(Map<String, dynamic> user) {
    setState(() {
      if (_favorites.contains(user)) {
        _favorites.remove(user);
      } else {
        _favorites.add(user);
      }
      _saveFavorites();
    });
  }

  /// ✅ Liste des pages à afficher
  final List<Widget> _pages = [];

  @override
  Widget build(BuildContext context) {
    // Ajout de la page MapScreen dans la liste des pages
    _pages.clear();
    _pages.addAll([
      UserList(users: users, toggleFavorite: _toggleFavorite, favorites: _favorites),
      ProfileScreen(username: _username, age: _age, description: _description, onProfileChanged: _updateProfile),
      FavoritesScreen(favorites: _favorites, toggleFavorite: _toggleFavorite),
      MapScreen(),
    ]);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          UserList(users: users, toggleFavorite: _toggleFavorite, favorites: _favorites),
          ProfileScreen(username: _username, age: _age, description: _description, onProfileChanged: _updateProfile),
          FavoritesScreen(favorites: _favorites, toggleFavorite: _toggleFavorite),
          MapScreen(),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.white,
        color: Colors.red,
        buttonBackgroundColor: Colors.redAccent,
        height: 60,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
        index: _selectedIndex,
        items: const [
          Icon(Icons.people, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
          Icon(Icons.favorite, size: 30, color: Colors.white),
          Icon(Icons.map, size: 30, color: Colors.white),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  geo.Position? _currentPosition;
  late mapbox.MapWidget _mapWidget;
  late mapbox.PointAnnotationManager _annotationManager;
  late mapbox.MapboxMap _mapboxMap; // ✅ Stocker la référence de la carte

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// ✅ Récupère la position actuelle de l'utilisateur
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    geo.LocationPermission permission;

    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Service de localisation désactivé");
      return;
    }

    permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        print("Permission refusée");
        return;
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      print("Permission refusée définitivement");
      return;
    }

    geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high);

    setState(() {
      _currentPosition = position;
    });

    _addUserLocationMarker(position); // 🔥 Ajoute un marqueur à la position actuelle
  }

  /// ✅ Ajoute un marqueur sur la position actuelle de l'utilisateur
  Future<void> _addUserLocationMarker(geo.Position position) async {
    if (_annotationManager == null) return;

    await _annotationManager.create(
      mapbox.PointAnnotationOptions(
        geometry: mapbox.Point(
          coordinates: mapbox.Position(
            position.longitude,
            position.latitude,
          ),
        ),
      ),
    );
  }

  /// ✅ Centre la carte sur la position actuelle
  void _centerToUserLocation() {
    if (_currentPosition != null && _mapboxMap != null) {
      _mapboxMap.setCamera(mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(
            _currentPosition!.longitude,
            _currentPosition!.latitude,
          ),
        ),
        zoom: 15.0,
        bearing: 0,
        pitch: 0,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carte"),
        backgroundColor: Colors.red,
        centerTitle: true,
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : mapbox.MapWidget(
        key: const ValueKey("mapWidget"),
        cameraOptions: mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(
              _currentPosition!.longitude,
              _currentPosition!.latitude,
            ),
          ),
          zoom: 15.0,
          bearing: 0,
          pitch: 0,
        ),
        onMapCreated: (mapbox.MapboxMap mapboxMap) async {
          _mapboxMap = mapboxMap; // ✅ Stocker la référence de la carte
          _annotationManager =
          await mapboxMap.annotations.createPointAnnotationManager();
          _addUserLocationMarker(_currentPosition!);

          // ✅ Active le suivi de localisation avec un effet de pulsation en bleu
          mapboxMap.location.updateSettings(mapbox.LocationComponentSettings(
            enabled: true,
            pulsingEnabled: true,
            pulsingColor: Colors.blue.value,
          ));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentPosition != null && _mapboxMap != null) {
            // 🔥 Animation fluide vers la position actuelle
            _mapboxMap.easeTo(
              mapbox.CameraOptions(
                center: mapbox.Point(
                  coordinates: mapbox.Position(
                    _currentPosition!.longitude,
                    _currentPosition!.latitude,
                  ),
                ),
                zoom: 17.0, // ✅ Zoom légèrement plus proche pour un meilleur effet
                bearing: Random().nextDouble() * 360, // ✅ Ajoute une légère rotation aléatoire
                pitch: 30, // ✅ Incline la vue pour un effet plus immersif
              ),
              mapbox.MapAnimationOptions(
                duration: 1500, // ✅ Durée de l'animation en millisecondes
              ),
            );
          }
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> favorites;
  final Function(Map<String, dynamic>) toggleFavorite;

  const FavoritesScreen({super.key, required this.favorites, required this.toggleFavorite});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favoris"), centerTitle: true, backgroundColor: Colors.red),
      body: favorites.isEmpty
          ? const Center(child: Text("Aucun favori ajouté.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))
          : ListView.builder(
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final user = favorites[index];
          return ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(user['imageURL'])),
            title: Text(user['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            subtitle: Text("${user['age']} ans • ${user['distance'].toStringAsFixed(1)} km • ${user['city']}"),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () => toggleFavorite(user), // ❌ Retirer des favoris
            ),
          );
        },
      ),
    );
  }
}

class UserList extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final Function(Map<String, dynamic>) toggleFavorite;
  final List<Map<String, dynamic>> favorites;

  const UserList({super.key, required this.users, required this.toggleFavorite, required this.favorites});

  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = widget.users;
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = widget.users
          .where((user) => user['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 50, backgroundImage: NetworkImage(user['imageURL'])),
              const SizedBox(height: 10),
              Text(user['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text("${user['age']} ans", style: const TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 15),
              Text(user['description'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Text("Distance : ${user['distance'].toStringAsFixed(1)} km", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text("Ville : ${user['city']}", style: const TextStyle(fontSize: 18, color: Colors.grey)), // 🔥 Ajout de la ville
              ElevatedButton.icon(
                icon: Icon(widget.favorites.contains(user) ? Icons.favorite : Icons.favorite_border, color: Colors.white),
                label: Text(widget.favorites.contains(user) ? "Retirer des favoris" : "Ajouter aux favoris"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  widget.toggleFavorite(user);
                  Navigator.pop(context); // Fermer le modal après l'action
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Max ton pote"), centerTitle: true, backgroundColor: Colors.red),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Rechercher un utilisateur",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return ListTile(
                  leading: CircleAvatar(backgroundImage: NetworkImage(user['imageURL'])),
                  title: Text(user['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: Icon(widget.favorites.contains(user) ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                    onPressed: () => widget.toggleFavorite(user),
                  ),
                  onTap: () => _showUserDetails(context, user),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}