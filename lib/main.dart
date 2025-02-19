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

class ProfileScreen extends StatefulWidget {
  final String username;
  final int age;
  final String description;
  final Function(String, int, String) onProfileChanged;

  const ProfileScreen({
    super.key,
    required this.username,
    required this.age,
    required this.description,
    required this.onProfileChanged,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _ageController;
  late TextEditingController _descriptionController;
  bool _isEditing = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _ageController = TextEditingController(text: widget.age.toString());
    _descriptionController = TextEditingController(text: widget.description);
    _loadEditingState(); // 🔥 Charger l'état du formulaire au démarrage
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// ✅ Charger l'état d'édition depuis `SharedPreferences`
  Future<void> _loadEditingState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEditing = prefs.getBool('isEditing') ?? true;
    });
  }

  /// ✅ Sauvegarder l'état d'édition
  Future<void> _saveEditingState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isEditing', value);
  }

  /// ✅ Sauvegarde le profil et l'état du formulaire
  Future<void> _saveProfile() async {
    final String username = _usernameController.text;
    final int? age = int.tryParse(_ageController.text);
    final String description = _descriptionController.text;

    if (username.isNotEmpty && age != null && description.isNotEmpty) {
      widget.onProfileChanged(username, age, description);

      await _saveEditingState(false); // 🔥 Sauvegarde que le formulaire est fermé

      setState(() {
        _isEditing = false;
      });
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
          child: _isEditing
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text("Pseudo :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(controller: _usernameController, decoration: const InputDecoration(border: OutlineInputBorder())),
              const SizedBox(height: 15),
              const Text("Âge :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(controller: _ageController, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder())),
              const SizedBox(height: 15),
              const Text("Description :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(controller: _descriptionController, decoration: const InputDecoration(border: OutlineInputBorder()), maxLines: 3),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Enregistrer", style: TextStyle(color: Colors.white)),
              ),
            ],
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Pseudo : ${widget.username}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Âge : ${widget.age} ans", style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Text("Description : ${widget.description}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await _saveEditingState(true); // 🔥 Sauvegarde que le formulaire doit s'afficher
                  setState(() => _isEditing = true);
                },
                child: const Text("Modifier le profil"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Map<String, dynamic>> users;
  int _selectedIndex = 0;
  String _username = "";
  int _age = 18;
  String _description = "";

  @override
  void initState() {
    List<Map<String, dynamic>> generateUsers() {
      const int imageLimit = 10;
      final randomNames = RandomNames();
      final random = Random();

      String generateDescription(String name, int age) {
        List<String> activities = [
          "passionné de voyages",
          "développeur Flutter",
          "amateur de cuisine",
          "fan de football",
          "adepte du yoga",
          "collectionneur de livres anciens",
          "explorateur urbain",
          "joueur d'échecs",
          "photographe en herbe",
          "musicien autodidacte"
        ];
        return "$name, $age ans, est ${activities[(name.length) % activities.length]} et aime découvrir de nouvelles expériences.";
      }

      return List.generate(50, (index) {
        String name = randomNames.fullName();
        int age = random.nextInt(43) + 18;
        double distance = random.nextDouble() * 99 + 1;

        return {
          'name': name,
          'age': age,
          'imageURL': 'https://picsum.photos/200/300?random=${(index % imageLimit) + 1}',
          'description': generateDescription(name, age),
          'distance': distance,
        };
      })..sort((a, b) => a['distance'].compareTo(b['distance']));
    }
    super.initState();
    users = generateUsers();
    _loadProfile(); // Charger les infos enregistrées
  }

  /// ✅ Charge les infos sauvegardées dans `SharedPreferences`
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? "";
      _age = prefs.getInt('age') ?? 18;
      _description = prefs.getString('description') ?? "";
    });
  }

  /// ✅ Sauvegarde les infos du profil dans `SharedPreferences`
  Future<void> _saveProfile(String username, int age, String description) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setInt('age', age);
    await prefs.setString('description', description);
  }

  void _updateProfile(String username, int age, String description) {
    setState(() {
      _username = username;
      _age = age;
      _description = description;
    });
    _saveProfile(username, age, description); // Sauvegarde après modification
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 0
          ? UserList(users: users)
          : ProfileScreen(
        username: _username,
        age: _age,
        description: _description,
        onProfileChanged: _updateProfile,
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

/// ✅ Classe `UserList` avec affichage de la description en modal
class UserList extends StatefulWidget {
  final List<Map<String, dynamic>> users;

  const UserList({super.key, required this.users});

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(user['imageURL']),
              ),
              const SizedBox(height: 10),
              Text(
                user['name'],
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                "${user['age']} ans",
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 15),
              Text(
                user['description'],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Text(
                "Distance : ${user['distance'].toStringAsFixed(1)} km",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      appBar: AppBar(
        title: const Text("Max ton pote"),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Rechercher un utilisateur",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(_filteredUsers[index]['imageURL']!),
                  ),
                  title: Text(
                    _filteredUsers[index]['name']!,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    "${_filteredUsers[index]['distance'].toStringAsFixed(1)} km",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  onTap: () => _showUserDetails(context, _filteredUsers[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}