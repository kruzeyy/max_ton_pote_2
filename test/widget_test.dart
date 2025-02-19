import 'package:flutter/material.dart';
import 'dart:math';
import 'package:random_name_generator/random_name_generator.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Map<String, dynamic>> users;
  List<Map<String, dynamic>> favorites = [];
  int _selectedIndex = 0;
  String _username = "";
  int _age = 18;
  String _description = "";

  @override
  void initState() {
    super.initState();
    users = generateUsers();
    _loadProfile();
    _loadFavorites();
  }

  List<Map<String, dynamic>> generateUsers() {
    const int imageLimit = 10;
    final randomNames = RandomNames();
    final random = Random();

    return List.generate(50, (index) {
      String name = randomNames.fullName();
      int age = random.nextInt(43) + 18;
      double distance = random.nextDouble() * 99 + 1;

      return {
        'name': name,
        'age': age,
        'imageURL': 'https://picsum.photos/200/300?random=${(index % imageLimit) + 1}',
        'description': "$name, $age ans, aime voyager.",
        'distance': distance,
      };
    })..sort((a, b) => a['distance'].compareTo(b['distance']));
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? "";
      _age = prefs.getInt('age') ?? 18;
      _description = prefs.getString('description') ?? "";
    });
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favoriteNames = List<String>.from(prefs.getStringList('favorites') ?? []);
    setState(() {
      favorites = users.where((user) => favoriteNames.contains(user['name'])).toList();
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', List<String>.from(favorites.map((e) => e['name'])));
  }

  void _toggleFavorite(Map<String, dynamic> user) {
    setState(() {
      if (favorites.contains(user)) {
        favorites.remove(user);
      } else {
        favorites.add(user);
      }
      _saveFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 0
          ? UserList(users: users, onFavoriteToggle: _toggleFavorite, favorites: favorites)
          : _selectedIndex == 1
          ? FavoriteList(favorites: favorites, onFavoriteToggle: _toggleFavorite)
          : ProfileScreen(username: _username, age: _age, description: _description),
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
          Icon(Icons.favorite, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
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

class UserList extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final Function(Map<String, dynamic>) onFavoriteToggle;
  final List<Map<String, dynamic>> favorites;

  const UserList({super.key, required this.users, required this.onFavoriteToggle, required this.favorites});

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          AppBar(
            title: const Text("Max ton pote"),
            centerTitle: true,
            backgroundColor: Colors.red,
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
                decoration: InputDecoration(
                  labelText: "Rechercher un utilisateur",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (query) {
                  // Ajouter ici la logique de filtrage
                }
            ),
          ),
          Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    leading: CircleAvatar(backgroundImage: NetworkImage(user['imageURL'])),
                    title: Text(user['name']),
                    subtitle: Text("${user['age']} ans - ${user['distance'].toStringAsFixed(1)} km"),
                    trailing: IconButton(
                      icon: Icon(favorites.contains(user) ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                      onPressed: () => onFavoriteToggle(user),
                    ),
                  );
                },
              ))]);
  }
}

class FavoriteList extends StatelessWidget {
  final List<Map<String, dynamic>> favorites;
  final Function(Map<String, dynamic>) onFavoriteToggle;

  const FavoriteList({super.key, required this.favorites, required this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final user = favorites[index];
        return ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(user['imageURL'])),
          title: Text(user['name']),
          subtitle: Text("${user['age']} ans - ${user['distance'].toStringAsFixed(1)} km"),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.red),
            onPressed: () => onFavoriteToggle(user),
          ),
        );
      },
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final String username;
  final int age;
  final String description;

  const ProfileScreen({super.key, required this.username, required this.age, required this.description});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Pseudo : $username", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text("Âge : $age ans", style: const TextStyle(fontSize: 18)),
          Text("Description : $description", style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}