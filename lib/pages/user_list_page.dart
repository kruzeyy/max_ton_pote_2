import 'package:flutter/material.dart';
import 'package:max_ton_pote_2/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  String? currentUserEmail;
  Map<String, bool> favoriteUsers = {};
  List<Map<String, dynamic>> users = [];
  bool showFavoritesOnly = false; // ✅ Nouvel état pour basculer entre tous les users et les favoris
  final SupabaseService supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _initializeData();

    supabase.auth.onAuthStateChange.listen((event) async {
      final session = event.session;
      if (session?.user != null) {
        setState(() {
          currentUserEmail = session!.user!.email;
        });
        await _initializeData();
      } else {
        setState(() {
          currentUserEmail = null;
          users.clear();
          favoriteUsers.clear();
        });
      }
    });
  }

  Future<void> _initializeData() async {
    await _getCurrentUserEmail();
    if (currentUserEmail != null) {
      await _fetchUsers();
      await _fetchFavoriteUsers();
    }
  }

  Future<void> _getCurrentUserEmail() async {
    try {
      final response = await supabaseService.getCurrentUser();
      if (response != null) {
        setState(() {
          currentUserEmail = response['email'];
        });
        await _fetchUsers();
        await _fetchFavoriteUsers();
      }
    } catch (e) {
      print("❌ Erreur lors de la récupération de l'utilisateur connecté : $e");
    }
  }

  Future<void> _fetchFavoriteUsers() async {
    if (currentUserEmail == null) return;

    try {
      final userResponse = await supabaseService.getUserByEmail(currentUserEmail!);
      List<String> favorites = userResponse?['favorites'] != null
          ? List<String>.from(userResponse?['favorites'])
          : [];

      setState(() {
        favoriteUsers.clear();
        for (var email in favorites) {
          favoriteUsers[email] = true;
        }
      });
    } catch (e) {
      print("❌ Erreur lors de la récupération des favoris : $e");
    }
  }

  void _toggleFavorite(String targetUserEmail) async {
    if (currentUserEmail == null) return;

    try {
      setState(() {
        favoriteUsers[targetUserEmail] = !(favoriteUsers[targetUserEmail] ?? false);
      });

      final userResponse = await supabaseService.getUserByEmail(currentUserEmail!);
      List<String> favorites = userResponse?['favorites'] != null
          ? List<String>.from(userResponse?['favorites'])
          : [];

      if (favorites.contains(targetUserEmail)) {
        favorites.remove(targetUserEmail);
      } else {
        favorites.add(targetUserEmail);
      }

      await supabaseService.updateFavorites(currentUserEmail!, favorites);
      await Future.delayed(Duration(milliseconds: 300));
      await _fetchFavoriteUsers();
    } catch (e) {
      print("❌ Erreur lors de la mise à jour des favoris : $e");
    }
  }

  Future<void> _fetchUsers() async {
    if (currentUserEmail == null) return;

    try {
      final fetchedUsers = await supabaseService.getAllUsers();
      if (mounted) {
        setState(() {
          users = fetchedUsers;
        });
      }
    } catch (e) {
      print("❌ Erreur lors du chargement des utilisateurs : $e");
    }
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
                backgroundImage: user['avatar_url'] != null && user['avatar_url'].isNotEmpty
                    ? NetworkImage(user['avatar_url'])
                    : AssetImage("assets/default_avatar.png") as ImageProvider,
              ),
              const SizedBox(height: 10),
              Text(
                user['name'] ?? 'Utilisateur inconnu',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                user['email'] ?? 'Email inconnu',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 15),
              Text(
                user['description'] ?? "Aucune description",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayedUsers = showFavoritesOnly
        ? users.where((user) => favoriteUsers[user['email']] == true).toList()
        : users;

    return Scaffold(
      appBar: AppBar(
        title: Text("Liste des Utilisateurs"),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: Icon(
              showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                showFavoritesOnly = !showFavoritesOnly;
              });
            },
          ),
        ],
      ),
      body: currentUserEmail == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 50, color: Colors.red),
            SizedBox(height: 16),
            Text(
              "Vous n'êtes pas connecté",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Connectez-vous avec votre compte Google",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () async {
          await _initializeData();
        },
        child: displayedUsers.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: displayedUsers.length,
          itemBuilder: (context, index) {
            final user = displayedUsers[index];
            final isFavorite = favoriteUsers.containsKey(user['email']) &&
                favoriteUsers[user['email']] == true;

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user['avatar_url'] != null &&
                    user['avatar_url'].isNotEmpty
                    ? NetworkImage(user['avatar_url'])
                    : AssetImage("assets/default_avatar.png") as ImageProvider,
              ),
              title: Text(user['name'] ?? 'Utilisateur inconnu'),
              subtitle: Text(user['email'] ?? 'Email inconnu'),
              trailing: GestureDetector(
                onTap: () => _toggleFavorite(user['email']),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                  size: 30,
                ),
              ),
              onTap: () => _showUserDetails(context, user),
            );
          },
        ),
      ),
    );
  }
}