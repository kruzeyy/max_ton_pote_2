import 'package:flutter/material.dart';
import 'package:max_ton_pote_2/services/supabase_service.dart';

class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  String? currentUserEmail; // Email de l'utilisateur connecté
  Map<String, bool> favoriteUsers = {}; //
  List<Map<String, dynamic>> users = [];
  final SupabaseService supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _getCurrentUserEmail();
  }

  /// 📌 Récupérer l'email de l'utilisateur connecté
  Future<void> _getCurrentUserEmail() async {
    try {
      final response = await supabaseService.getCurrentUser();
      if (response != null) {
        setState(() {
          currentUserEmail = response['email'];
        });
        print("✅ Utilisateur connecté : $currentUserEmail");
      } else {
        print("❌ Aucun utilisateur connecté !");
      }
    } catch (e) {
      print("❌ Erreur lors de la récupération de l'utilisateur connecté : $e");
    }
  }

  /// 📌 Basculer l'état du bouton cœur et mettre à jour Supabase
  void _toggleFavorite(String targetUserEmail) async {
    if (currentUserEmail == null) return;

    try {
      // 🔹 Récupérer la liste actuelle des favoris
      final userResponse = await supabaseService.getUserByEmail(currentUserEmail!);
      List<String> favorites = userResponse?['favorites'] != null
          ? List<String>.from(userResponse?['favorites'])
          : [];

      // 🔥 Ajouter ou supprimer l'utilisateur cible des favoris
      if (favorites.contains(targetUserEmail)) {
        favorites.remove(targetUserEmail);
      } else {
        favorites.add(targetUserEmail);
      }

      // 🔹 Mettre à jour la base de données Supabase
      await supabaseService.updateFavorites(currentUserEmail!, favorites);

      // 🔄 Mettre à jour l'état local pour l'affichage
      setState(() {
        favoriteUsers[targetUserEmail] = favorites.contains(targetUserEmail);
      });

      print("✅ Favoris mis à jour : $favorites");
    } catch (e) {
      print("❌ Erreur lors de la mise à jour des favoris : $e");
    }
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
              trailing: GestureDetector(
                onTap: () => _toggleFavorite(user['email']),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Icon(
                    favoriteUsers[user['email']] == true ? Icons.favorite : Icons.favorite_border,
                    color: favoriteUsers[user['email']] == true ? Colors.red : Colors.grey,
                    size: 30,
                  ),
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