import 'package:flutter/material.dart';
import 'package:max_ton_pote_2/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final SupabaseClient supabase = Supabase.instance.client; // ✅ Déclaration ici

  String? currentUserEmail;
  Map<String, bool> favoriteUsers = {};
  List<Map<String, dynamic>> users = [];
  final SupabaseService supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _initializeData();

    // 🔥 Ajout d'un écouteur pour détecter les changements d'authentification
    supabase.auth.onAuthStateChange.listen((event) async {
      if (event.session?.user != null) {
        print("✅ Changement détecté : Utilisateur connecté !");
        await _initializeData(); // 🔥 Recharge immédiatement les données
      } else {
        print("❌ Changement détecté : Utilisateur déconnecté !");
        setState(() {
          currentUserEmail = null;
          users.clear();
          favoriteUsers.clear();
        });
      }
    });
  }

  /// 📌 Fonction qui charge l'utilisateur et ses favoris
  Future<void> _initializeData() async {
    await _getCurrentUserEmail();
    if (currentUserEmail != null) {
      await _fetchUsers(); // 🔥 Charge les utilisateurs après connexion
      await _fetchFavoriteUsers();
    }
  }

  /// 📌 Récupérer l'email de l'utilisateur connecté
  Future<void> _getCurrentUserEmail() async {
    try {
      final response = await supabaseService.getCurrentUser();
      if (response != null) {
        setState(() {
          currentUserEmail = response['email'];
        });
        print("✅ Utilisateur connecté détecté automatiquement : $currentUserEmail");

        // 🔥 Charger les utilisateurs et favoris immédiatement
        await _fetchUsers();
        await _fetchFavoriteUsers();
      } else {
        print("❌ Aucun utilisateur connecté !");
      }
    } catch (e) {
      print("❌ Erreur lors de la récupération de l'utilisateur connecté : $e");
    }
  }

  /// 📌 Récupérer la liste des favoris de l'utilisateur connecté
  Future<void> _fetchFavoriteUsers() async {
    if (currentUserEmail == null) return;

    try {
      // 🔥 Vérification après connexion pour s'assurer qu'on récupère le bon utilisateur
      final loggedInUser = await supabaseService.getCurrentUser();
      if (loggedInUser != null && loggedInUser['email'] != currentUserEmail) {
        print("⚠️ Changement d'utilisateur détecté : ${loggedInUser['email']} (ancien: $currentUserEmail)");
        setState(() {
          currentUserEmail = loggedInUser['email'];
        });
      }

      final userResponse = await supabaseService.getUserByEmail(currentUserEmail!);

      print("🔍 Données récupérées pour $currentUserEmail : $userResponse");

      List<String> favorites = userResponse?['favorites'] != null
          ? List<String>.from(userResponse?['favorites'])
          : [];

      print("📥 Liste brute des favoris récupérés : $favorites");

      setState(() {
        favoriteUsers.clear();
        for (var email in favorites) {
          favoriteUsers[email] = true;
        }
      });

      print("✅ Favoris mis à jour pour $currentUserEmail : $favoriteUsers");
    } catch (e) {
      print("❌ Erreur lors de la récupération des favoris : $e");
    }
  }

  /// 📌 Basculer l'état du bouton cœur et mettre à jour Supabase
  void _toggleFavorite(String targetUserEmail) async {
    if (currentUserEmail == null) return;

    try {
      // 🔹 Mise à jour locale immédiate
      setState(() {
        favoriteUsers[targetUserEmail] = !(favoriteUsers[targetUserEmail] ?? false);
      });

      // 🔹 Récupérer les favoris actuels
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
      print("🛠️ Mise à jour des favoris pour $currentUserEmail : $favorites");

      // 🔥 Rafraîchir les favoris après mise à jour
      await Future.delayed(Duration(milliseconds: 300)); // 🔥 Attendre un peu pour s’assurer que Supabase met bien à jour
      await _fetchFavoriteUsers();
    } catch (e) {
      print("❌ Erreur lors de la mise à jour des favoris : $e");
    }
  }

  /// 📌 Récupérer la liste des utilisateurs
  Future<void> _fetchUsers() async {
    if (currentUserEmail == null) return;

    try {
      print("🔹 Chargement des utilisateurs...");
      final fetchedUsers = await supabaseService.getAllUsers();

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

  /// 📌 Afficher les détails d'un utilisateur
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Liste des Utilisateurs"),
        backgroundColor: Colors.red,
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
          print("🔄 Rafraîchissement en cours...");
          await _initializeData();
          print("✅ Rafraîchissement terminé !");
        },
        child: users.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
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
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
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