import 'package:flutter/material.dart';
import 'package:max_ton_pote_2/services/supabase_service.dart';

class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<Map<String, dynamic>> users = [];
  final SupabaseService supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  /// 📌 Récupérer tous les utilisateurs de Supabase
  Future<void> _fetchUsers() async {
    try {
      print("🔹 Chargement des utilisateurs...");
      final service = SupabaseService();
      List<Map<String, dynamic>> fetchedUsers = await service.getAllUsers();

      if (mounted) {
        setState(() {
          users = fetchedUsers;
        });
      }

      if (users.isEmpty) {
        print("⚠️ Aucun utilisateur trouvé !");
      }
    } catch (e) {
      print("❌ Erreur lors du chargement des utilisateurs : $e");
    }
  }

  /// 📌 Fonction pour afficher les détails d'un utilisateur
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
                    : AssetImage("assets/default_avatar.png") as ImageProvider, // 🔥 Avatar par défaut si absent
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
    return Scaffold(
      appBar: AppBar(title: Text("Liste des Utilisateurs")),
      body: RefreshIndicator(
        onRefresh: _fetchUsers, // 🔥 Rafraîchir la liste après connexion
        child: users.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user['avatar_url'] != null && user['avatar_url'].isNotEmpty
                    ? NetworkImage(user['avatar_url'])
                    : AssetImage("assets/default_avatar.png") as ImageProvider,
              ),
              title: Text(user['name'] ?? 'Utilisateur inconnu'),
              subtitle: Text(user['email'] ?? 'Email inconnu'),
              onTap: () => _showUserDetails(context, user),
            );
          },
        ),
      ),
    );
  }
}