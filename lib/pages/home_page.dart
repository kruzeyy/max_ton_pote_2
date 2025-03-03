import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:max_ton_pote_2/pages/profile_page.dart';
import 'package:max_ton_pote_2/pages/user_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'map_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> users = [];
  int _selectedIndex = 0;
  String _username = "";
  int _age = 18;
  String _description = "";
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadUsers();
  }

  /// ✅ Charger les informations du profil depuis SharedPreferences
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? "Utilisateur inconnu";
      _age = prefs.getInt('age') ?? 18;
      _description = prefs.getString('description') ?? "Aucune description disponible.";
    });
  }

  /// ✅ Charger les utilisateurs depuis Supabase
  Future<void> _loadUsers() async {
    final response = await supabase.from('User').select('id, name, email, longitude, latitude, avatar_url');

    if (response.isEmpty) {
      print("❌ Aucun utilisateur trouvé.");
      return;
    }

    setState(() {
      users = List<Map<String, dynamic>>.from(response);
    });

    print("✅ Utilisateurs chargés depuis la base !");
  }

  /// ✅ Liste des pages à afficher (SUPPRESSION DES FAVORIS)
  final List<Widget> _pages = [
    UserListPage(),
    const ProfileScreen(),
    const MapScreen(), // ✅ Map passe en index 2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
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
          Icon(Icons.map, size: 30, color: Colors.white), // ✅ Map est maintenant l'index 2
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