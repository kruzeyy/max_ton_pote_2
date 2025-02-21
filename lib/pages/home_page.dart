import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:max_ton_pote_2/pages/profile_page.dart';
import 'package:max_ton_pote_2/pages/user_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'favorites_page.dart';
import 'map_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
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
